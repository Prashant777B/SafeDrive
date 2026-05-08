// lib/screens/admin/document_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});
  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  List<AdminDocument> _docs = [];
  bool _loading = true;

  static const _statuses = ['All', 'Pending', 'Verified', 'Rejected'];
  static const _types = [
    'All',
    'kyc_id',
    'kyc_address',
    'licence',
    'claim_evidence',
    'policy_doc',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final docs = await AdminService.instance.getDocuments(
        status: _statusFilter == 'all' ? null : _statusFilter,
        documentType: _typeFilter == 'all' ? null : _typeFilter,
      );
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(AdminDocument doc, bool approved) async {
    String? reason;
    if (!approved) {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Rejection Reason'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Enter reason…'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );
      if (reason == null || reason.isEmpty) return;
    }
    await AdminService.instance.verifyDocument(
      doc.id,
      approved: approved,
      rejectionReason: reason,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Document Management',
                  subtitle: '${_docs.length} documents',
                ),
                const SizedBox(height: 10),
                FilterChipRow(
                  options: _statuses,
                  selected: _statusFilter,
                  onSelected: (s) {
                    setState(() => _statusFilter = s);
                    _load();
                  },
                ),
                const SizedBox(height: 6),
                FilterChipRow(
                  options: _types,
                  selected: _typeFilter,
                  onSelected: (t) {
                    setState(() => _typeFilter = t);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _docs.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.folder_outlined,
                        title: 'No documents found',
                        subtitle: 'Customer documents will appear here.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final d = _docs[i];
                            return _DocTile(
                                doc: d,
                                onApprove: () => _verify(d, true),
                                onReject: () => _verify(d, false));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final AdminDocument doc;
  final VoidCallback onApprove, onReject;
  const _DocTile(
      {required this.doc, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.fileName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      doc.documentType.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(doc.verificationStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Uploaded ${formatDate(doc.uploadedAt)}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (doc.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reason: ${doc.rejectionReason}',
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          if (doc.verificationStatus == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Verify', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
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
