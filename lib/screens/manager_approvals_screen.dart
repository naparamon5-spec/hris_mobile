import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

/// Manager / head / executive inbox backed by the HRIS API. Lists pending
/// approvals and posts approve / reject decisions to the backend
/// (`/auth/approvals`, `/auth/approvals/:id/approve|reject`).
class ManagerApprovalsScreen extends StatefulWidget {
  const ManagerApprovalsScreen({super.key});

  @override
  State<ManagerApprovalsScreen> createState() => _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<ManagerApprovalsScreen> {
  final _reload = AsyncViewController();
  final _filters = const ['Pending', 'Approved', 'Rejected'];
  int _selected = 0;
  int? _actingOn; // id currently being decided

  @override
  void dispose() {
    _reload.dispose();
    super.dispose();
  }

  Future<void> _decide(Approval a, bool approve) async {
    if (_actingOn != null) return;
    setState(() => _actingOn = a.id);
    try {
      if (approve) {
        await HrisApi.instance.approve(a.id);
      } else {
        await HrisApi.instance.reject(a.id);
      }
      if (mounted) {
        showToast(context,
            '${a.employee}\'s request ${approve ? 'approved' : 'rejected'}');
      }
      _reload.reload();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    } finally {
      if (mounted) setState(() => _actingOn = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Approvals')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final sel = i == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.brandRed : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: sel ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AsyncView<List<Approval>>(
                controller: _reload,
                // Reloads whenever the filter changes because the whole widget
                // rebuilds; we filter client-side from the full list.
                load: () => HrisApi.instance.approvals(),
                useGlobalLoader: true,
                builder: (context, all) {
                  final visible = all
                      .where((a) => a.status == _filters[_selected])
                      .toList();
                  return RefreshIndicator(
                    color: AppColors.brandRed,
                    onRefresh: () async => _reload.reload(),
                    child: visible.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 90),
                              Icon(Icons.inbox_rounded,
                                  size: 56, color: AppColors.inkFaint),
                              SizedBox(height: 12),
                              Center(
                                child: Text('Nothing here',
                                    style: TextStyle(
                                        color: AppColors.inkSoft,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ApprovalCard(
                              approval: visible[i],
                              busy: _actingOn == visible[i].id,
                              onApprove: () => _decide(visible[i], true),
                              onReject: () => _decide(visible[i], false),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.approval,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Approval approval;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (approval.status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.brandRed;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = approval.status == 'Pending';
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: approval.employee, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(approval.employee,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${approval.type} • ${approval.filed}',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusPill(label: approval.status, color: _statusColor),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.inkFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(approval.detail,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.ink)),
              ),
              Text(approval.days,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft)),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandRed,
                      side: BorderSide(color: AppColors.brandRed),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(42),
                      elevation: 0,
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
