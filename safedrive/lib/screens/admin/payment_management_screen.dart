// lib/screens/admin/payment_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});
  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  List<AdminPayment> _payments = [];
  bool _loading = true;
  double _totalRevenue = 0;

  static const _statusOptions = [
    'All',
    'Pending',
    'Paid',
    'Failed',
    'Refunded',
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
      final payments = await AdminService.instance.getPayments(
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      final rev = payments
          .where((p) => p.status == 'paid')
          .fold<double>(0, (sum, p) => sum + p.amount);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _totalRevenue = rev;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(AdminPayment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentDetailSheet(payment: payment, onUpdated: _load),
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
                  title: 'Payment Management',
                  subtitle:
                      '${_payments.length} records · Revenue: ${formatCurrency(_totalRevenue)}',
                ),
                const SizedBox(height: 12),
                AdminSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search reference, method…',
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
                : _payments.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.payments_outlined,
                        title: 'No payments found',
                        subtitle: 'Payments will appear here once recorded.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final p = _payments[i];
                            return _PaymentTile(
                                payment: p, onTap: () => _showDetail(p));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final AdminPayment payment;
  final VoidCallback onTap;
  const _PaymentTile({required this.payment, required this.onTap});

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
                color: statusColor(payment.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.payments_rounded,
                  color: statusColor(payment.status), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(payment.paymentReference,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      StatusBadge(payment.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    payment.paymentMethod ?? payment.paymentType,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(formatDate(payment.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(
                        formatCurrency(payment.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
}

class _PaymentDetailSheet extends StatefulWidget {
  final AdminPayment payment;
  final VoidCallback onUpdated;
  const _PaymentDetailSheet({required this.payment, required this.onUpdated});

  @override
  State<_PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends State<_PaymentDetailSheet> {
  bool _saving = false;

  Future<void> _updateStatus(String status) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Update Payment',
      message: 'Mark payment as $status?',
      confirmLabel: 'Confirm',
      confirmColor: statusColor(status),
    );
    if (!confirm) return;
    setState(() => _saving = true);
    await AdminService.instance.updatePaymentStatus(widget.payment.id, status);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onUpdated();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Payment status: $status'),
          backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
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
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.success, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.paymentReference,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(formatCurrency(p.amount),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                  StatusBadge(p.status),
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
                    _detail('Payment Method', p.paymentMethod ?? '—'),
                    _detail('Payment Type', p.paymentType),
                    _detail('Currency', p.currency),
                    _detail('Created', formatDateTime(p.createdAt)),
                    if (p.paidAt != null)
                      _detail('Paid At', formatDateTime(p.paidAt!)),
                    if (p.failureReason != null)
                      _detail('Failure Reason', p.failureReason!),
                    if (p.refundAmount != null)
                      _detail('Refund Amount', formatCurrency(p.refundAmount!)),
                    if (p.notes != null) _detail('Notes', p.notes!),
                    const SizedBox(height: 16),
                    const Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['paid', 'failed', 'refunded', 'cancelled']
                          .where((s) => s != p.status)
                          .map((s) => OutlinedButton(
                                onPressed:
                                    _saving ? null : () => _updateStatus(s),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor(s),
                                  side: BorderSide(color: statusColor(s)),
                                ),
                                child: Text(s.toUpperCase(),
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
