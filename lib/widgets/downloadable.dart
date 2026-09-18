import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ui.dart';

/// Renders the widget behind [boundaryKey] to a high-resolution PNG and opens
/// the native share/save sheet so the user can save it to Photos/Files or send
/// it on. Returns false if capture failed. Wrap the content you want captured in
/// a `RepaintBoundary(key: boundaryKey)`.
Future<bool> captureAndShare(
  BuildContext context,
  GlobalKey boundaryKey,
  String fileName, {
  String? shareText,
}) async {
  // Read everything that needs `context` up front, before any await.
  final dpr = MediaQuery.of(context).devicePixelRatio;
  final pixelRatio = (dpr > 0 ? dpr.clamp(1.0, 3.0) : 2.0).toDouble();
  Rect origin = const Rect.fromLTWH(0, 0, 1, 1); // iPad share-popover anchor
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }

  try {
    // Make sure the boundary has painted before we grab it.
    var obj = boundaryKey.currentContext?.findRenderObject();
    if (obj is RenderRepaintBoundary && obj.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await SchedulerBinding.instance.endOfFrame;
      obj = boundaryKey.currentContext?.findRenderObject();
    }
    if (obj is! RenderRepaintBoundary) {
      throw StateError('The content is not ready yet.');
    }

    final image = await obj.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) throw StateError('Could not encode the image.');
    final bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/$safeName.png');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png', name: '$safeName.png')],
      text: shareText,
      sharePositionOrigin: origin,
    );
    return true;
  } catch (e) {
    if (context.mounted) {
      await showToast(
          context,
          "We couldn't prepare the file. If this keeps happening, fully "
          "reopen the app and try again.\n($e)",
          isSuccess: false,
          title: 'Download Failed');
    }
    return false;
  }
}
