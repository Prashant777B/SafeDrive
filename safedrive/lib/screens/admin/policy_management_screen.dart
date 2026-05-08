// lib/screens/admin/policy_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class PolicyManagementScreen extends StatefulWidget {
  const PolicyManagementScreen({super.key});
  @override
  State<PolicyManagementScreen> createState() => _PolicyManagementScreenState();
}

class _PolicyManagementScreenState extends State<PolicyManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  List<AdminPolicy> _policies = [];
  bool _loading = true;

  static const _statusOptions = [
    'All',
    'Active',
    'Pending',
    'Expired',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final policies = await AdminService.instance.getPolicies(
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _policies = policies;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(AdminPolicy policy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PolicyDetailSheet(policy: policy, onUpdated: _load),
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
                  title: 'Policy Management',
                  subtitle: '${_policies.length} policies found',
                ),
                const SizedBox(height: 12),
                AdminSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search policy number, reg, name…',
                  onChanged: _load,
                ),
                const SizedBox(height: 10),
                FilterChipRow(
                  options: _statusOptions,
                  selected: _statusFilter,
                  onSelected: (s) {
                    setState(() => _statusFilter = s);
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
                : _policies.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.policy_outlined,
                        title: 'No policies found',
                        subtitle: 'Try a different filter or search term.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _policies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final p = _policies[i];
                            return _PolicyTile(
                                policy: p, onTap: () => _showDetail(p));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final AdminPolicy policy;
  final VoidCallback onTap;
  const _PolicyTile({required this.policy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                Expanded(
                  child: Text(
                    policy.policyNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                ),
                StatusBadge(policy.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  [
                    policy.carRegistration,
                    policy.carMake,
                    policy.carModel,
                    policy.carYear
                  ].where((e) => e != null).join(' '),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  policy.insuredName ?? 'Unknown',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  policy.coverType,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _dateChip(Icons.event_available_rounded,
                    formatDate(policy.startDate), AppColors.success),
                const SizedBox(width: 8),
                _dateChip(Icons.event_busy_rounded, formatDate(policy.endDate),
                    AppColors.error),
                const Spacer(),
                if (policy.annualPremium != null)
                  Text(
                    '${formatCurrency(policy.annualPremium!)}/yr',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PolicyDetailSheet extends StatefulWidget {
  final AdminPolicy policy;
  final VoidCallback onUpdated;
  const _PolicyDetailSheet({required this.policy, required this.onUpdated});

  @override
  State<_PolicyDetailSheet> createState() => _PolicyDetailSheetState();
}

class _PolicyDetailSheetState extends State<_PolicyDetailSheet> {
  String _status = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.policy.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Update Policy Status',
      message: 'Change status to "${newStatus.toUpperCase()}"?',
      confirmLabel: 'Update',
      confirmColor: AppColors.primary,
    );
    if (!confirmed) return;
    setState(() => _saving = true);
    await AdminService.instance.updatePolicyStatus(widget.policy.id, newStatus);
    if (!mounted) return;
    setState(() {
      _status = newStatus;
      _saving = false;
    });
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Policy status updated to $newStatus'),
          backgroundColor: AppColors.success),
    );
  }

  Future<void> _deletePolicy() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Policy',
      message:
          'Delete policy ${widget.policy.policyNumber}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await AdminService.instance.deletePolicy(widget.policy.id);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.policy;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.policy_rounded,
                      color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.policyNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(p.coverType,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(_status),
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
                    _Section('Vehicle Details', [
                      _Row('Registration', p.carRegistration ?? '—'),
                      _Row(
                          'Make / Model',
                          '${p.carMake ?? ''} ${p.carModel ?? ''} ${p.carYear ?? ''}'
                              .trim()),
                    ]),
                    _Section('Insured', [
                      _Row('Name', p.insuredName ?? '—'),
                      _Row('Postcode', p.postcode ?? '—'),
                      _Row('Licence', p.licenceType ?? '—'),
                    ]),
                    _Section('Financials', [
                      _Row(
                          'Annual Premium',
                          p.annualPremium != null
                              ? formatCurrency(p.annualPremium!)
                              : '—'),
                      _Row(
                          'Monthly Premium',
                          p.monthlyPremium != null
                              ? formatCurrency(p.monthlyPremium!)
                              : '—'),
                      _Row('Payment Frequency', p.paymentFrequency),
                    ]),
                    _Section('Dates', [
                      _Row('Start Date', formatDate(p.startDate)),
                      _Row('End Date', formatDate(p.endDate)),
                      _Row('Created', formatDate(p.createdAt)),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Update Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['active', 'pending', 'expired', 'cancelled']
                          .map((s) => OutlinedButton(
                                onPressed: _saving || _status == s
                                    ? null
                                    : () => _updateStatus(s),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor(s),
                                  side: BorderSide(color: statusColor(s)),
                                ),
                                child: Text(s.toUpperCase(),
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deletePolicy,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete Policy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
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
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary)),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
