// lib/screens/admin/claims_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class ClaimsManagementScreen extends StatefulWidget {
  const ClaimsManagementScreen({super.key});
  @override
  State<ClaimsManagementScreen> createState() => _ClaimsManagementScreenState();
}

class _ClaimsManagementScreenState extends State<ClaimsManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  List<AdminClaim> _claims = [];
  bool _loading = true;

  static const _statusOptions = [
    'All',
    'Submitted',
    'Under_Review',
    'Approved',
    'Rejected',
    'Settled'
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
      final claims = await AdminService.instance.getClaims(
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _claims = claims;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(AdminClaim claim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClaimDetailSheet(claim: claim, onUpdated: _load),
    );
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
                  title: 'Claims Management',
                  subtitle: '${_claims.length} claims',
                ),
                const SizedBox(height: 12),
                AdminSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search claim number, type…',
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
                : _claims.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No claims found',
                        subtitle: 'Claims will appear here once submitted.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _claims.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final c = _claims[i];
                            return _ClaimTile(
                                claim: c, onTap: () => _openDetail(c));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final AdminClaim claim;
  final VoidCallback onTap;
  const _ClaimTile({required this.claim, required this.onTap});

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
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor(claim.status).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _claimIcon(claim.claimType),
                color: statusColor(claim.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(claim.claimNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      StatusBadge(claim.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(claim.claimType,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(formatDate(claim.incidentDate),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const Spacer(),
                      if (claim.estimatedCost != null)
                        Text(
                          formatCurrency(claim.estimatedCost!),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _claimIcon(String type) {
    if (type.toLowerCase().contains('theft')) return Icons.lock_open_rounded;
    if (type.toLowerCase().contains('fire')) {
      return Icons.local_fire_department_rounded;
    }
    if (type.toLowerCase().contains('flood')) return Icons.water_rounded;
    return Icons.car_crash_rounded;
  }
}

class _ClaimDetailSheet extends StatefulWidget {
  final AdminClaim claim;
  final VoidCallback onUpdated;
  const _ClaimDetailSheet({required this.claim, required this.onUpdated});

  @override
  State<_ClaimDetailSheet> createState() => _ClaimDetailSheetState();
}

class _ClaimDetailSheetState extends State<_ClaimDetailSheet> {
  final _notesCtrl = TextEditingController();
  final _settlementCtrl = TextEditingController();
  bool _saving = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.claim.status;
    _notesCtrl.text = widget.claim.notes ?? '';
    _settlementCtrl.text =
        widget.claim.settlementAmount?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _settlementCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateClaim(String status) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Update Claim',
      message: 'Set claim to ${status.toUpperCase()}?',
      confirmLabel: 'Confirm',
      confirmColor: statusColor(status),
    );
    if (!confirm) return;

    setState(() => _saving = true);
    final settlement =
        double.tryParse(_settlementCtrl.text.replaceAll(',', ''));
    await AdminService.instance.updateClaimStatus(
      widget.claim.id,
      status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      settlementAmount: settlement,
    );
    if (!mounted) return;
    setState(() {
      _currentStatus = status;
      _saving = false;
    });
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Claim updated: $status'),
          backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.claim;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.97,
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
                  const Icon(Icons.assignment_rounded,
                      color: AppColors.warning, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.claimNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(c.claimType,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(_currentStatus),
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
                    // Incident info
                    _infoBlock('Incident', [
                      _infoRow('Date', formatDate(c.incidentDate)),
                      _infoRow('Location', c.incidentLocation ?? '—'),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text(c.description,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoBlock('Financials', [
                      _infoRow(
                          'Estimated Cost',
                          c.estimatedCost != null
                              ? formatCurrency(c.estimatedCost!)
                              : '—'),
                      _infoRow(
                          'Settlement',
                          c.settlementAmount != null
                              ? formatCurrency(c.settlementAmount!)
                              : 'Not set'),
                    ]),
                    const SizedBox(height: 12),

                    // Settlement amount input
                    AdminFormField(
                      label: 'Settlement Amount (£)',
                      controller: _settlementCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      hint: '0.00',
                    ),
                    const SizedBox(height: 12),
                    AdminFormField(
                      label: 'Admin Notes',
                      controller: _notesCtrl,
                      maxLines: 3,
                      hint: 'Add notes about this claim decision…',
                    ),
                    const SizedBox(height: 16),

                    const Text('Update Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            'Approve',
                            Icons.check_circle_outline_rounded,
                            AppColors.success,
                            () => _updateClaim('approved'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            'Reject',
                            Icons.cancel_outlined,
                            AppColors.error,
                            () => _updateClaim('rejected'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            'Mark Pending',
                            Icons.hourglass_empty_rounded,
                            AppColors.warning,
                            () => _updateClaim('submitted'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            'Mark Settled',
                            Icons.monetization_on_outlined,
                            AppColors.purple,
                            () => _updateClaim('settled'),
                          ),
                        ),
                      ],
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

  Widget _infoBlock(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
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

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _saving ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
