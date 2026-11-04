import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'tenants.dart';

/// On-device copy of the last company list the backend returned.
///
/// The backend (`/public/tenants`) is the source of truth for which companies
/// exist. This cache lets the app keep working offline with an up-to-date
/// list, so adding/removing a company only needs a backend change — no new app
/// release. The bundled [kTenants] is only a last resort for a fresh install
/// that has never reached the server.
class TenantCache {
  TenantCache._();
  static final TenantCache instance = TenantCache._();

  static const _fileName = 'tenants_cache.json';

  List<Tenant>? _memory;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Saves the list fetched from the backend. Best-effort: never throws.
  Future<void> save(List<Tenant> tenants) async {
    if (tenants.isEmpty) return;
    _memory = tenants;
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(
        jsonEncode(tenants.map((t) => t.toJson()).toList()),
      );
    } catch (_) {/* cache is optional */}
  }

  /// The last list saved from the backend, or an empty list if none.
  Future<List<Tenant>> read() async {
    if (_memory != null) return _memory!;
    try {
      final f = await _file();
      if (!await f.exists()) return const [];
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return const [];
      final list = raw
          .whereType<Map>()
          .map((e) => Tenant.fromJson(e.cast<String, dynamic>()))
          .where((t) => t.id.isNotEmpty)
          .toList();
      _memory = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Best available offline list: cached backend list, else bundled fallback.
  Future<List<Tenant>> offlineList() async {
    final cached = await read();
    return cached.isNotEmpty ? cached : kTenants;
  }

  /// Looks up a company by id — cached backend list first, then the bundled
  /// fallback — so a company that exists only on the backend is still found.
  Future<Tenant?> findById(String id) async {
    for (final t in await read()) {
      if (t.id == id) return t;
    }
    for (final t in kTenants) {
      if (t.id == id) return t;
    }
    return null;
  }
}
