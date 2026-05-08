// lib/screens/admin/audit_logs_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});
  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  String _actionFilter = 'all';
  String _tableFilter = 'all';
  DateTimeRange? _dateRange;

  static const _actionTypes = [
    'All',
    'create',
    'update',
    'delete',
    'approve',
    'reject',
    'login',
    'logout'
  ];

  static const _tables = [
    'All',
    'admin_users',
    'user_profiles',
    'policies',
    'claims',
    'payments',
    'documents',
    'agents',
    'notifications',
    'support_tickets',
    'system_settings'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await AdminService.instance.getAuditLogs(
        actionType: _actionFilter == 'all' ? null : _actionFilter,
        affectedTable: _tableFilter == 'all' ? null : _tableFilter,
        fromDate: _dateRange?.start,
        toDate: _dateRange?.end,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _load();
    }
  }

  void _viewDetail(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AuditDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Audit Logs',
                  subtitle: '${_logs.length} entries',
                  action: AdminActionButton(
                    label: 'Filter Date',
                    icon: Icons.calendar_today_rounded,
                    outlined: true,
                    onTap: _pickDateRange,
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${formatDate(_dateRange!.start)} → ${formatDate(_dateRange!.end)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _dateRange = null);
                          _load();
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                FilterChipRow(
                  options: _actionTypes,
                  selected: _actionFilter,
                  onSelected: (v) {
                    setState(() => _actionFilter = v);
                    _load();
                  },
                ),
                const SizedBox(height: 6),
                FilterChipRow(
                  options: _tables,
                  selected: _tableFilter,
                  onSelected: (v) {
                    setState(() => _tableFilter = v);
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
                : _logs.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No audit logs found',
                        subtitle:
                            'Admin actions are recorded here automatically.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final log = _logs[i];
                            return _AuditTile(
                              log: log,
                              onTap: () => _viewDetail(log),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── colour + icon per action ────────────────────────────────
Color _actionColor(String action) {
  switch (action) {
    case 'create':
      return AppColors.success;
    case 'update':
      return AppColors.primary;
    case 'delete':
      return AppColors.error;
    case 'approve':
      return AppColors.success;
    case 'reject':
      return AppColors.error;
    case 'login':
    case 'logout':
      return AppColors.purple;
    default:
      return AppColors.textSecondary;
  }
}

IconData _actionIcon(String action) {
  switch (action) {
    case 'create':
      return Icons.add_circle_outline_rounded;
    case 'update':
      return Icons.edit_outlined;
    case 'delete':
      return Icons.delete_outline_rounded;
    case 'approve':
      return Icons.check_circle_outline_rounded;
    case 'reject':
      return Icons.cancel_outlined;
    case 'login':
      return Icons.login_rounded;
    case 'logout':
      return Icons.logout_rounded;
    default:
      return Icons.history_rounded;
  }
}

class _AuditTile extends StatelessWidget {
  final AuditLog log;
  final VoidCallback onTap;
  const _AuditTile({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.actionType);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_actionIcon(log.actionType), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.actionType.toUpperCase(),
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (log.affectedTable != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          log.affectedTable!,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        formatDateTime(log.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(log.description,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (log.adminEmail != null)
                    Text(
                      'By: ${log.adminEmail}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AuditDetailSheet extends StatelessWidget {
  final AuditLog log;
  const _AuditDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.actionType);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_actionIcon(log.actionType),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.actionType.toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color),
                        ),
                        Text(
                          log.affectedTable ?? 'System',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Description', log.description),
                    if (log.adminEmail != null)
                      _detailRow('Admin', log.adminEmail!),
                    if (log.affectedId != null)
                      _detailRow('Record ID', log.affectedId!),
                    _detailRow('Timestamp', formatDateTime(log.createdAt)),
                    if (log.ipAddress != null)
                      _detailRow('IP Address', log.ipAddress!),
                    if (log.oldValues != null) ...[
                      const SizedBox(height: 12),
                      const Text('Previous Values',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          log.oldValues.toString(),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                    if (log.newValues != null) ...[
                      const SizedBox(height: 12),
                      const Text('New Values',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          log.newValues.toString(),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
