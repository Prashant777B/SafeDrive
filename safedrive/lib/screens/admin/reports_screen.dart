// lib/screens/admin/reports_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  String _reportType = 'overview';
  bool _loading = false;
  Map<String, dynamic> _data = {};

  static const _reportTypes = {
    'overview': 'Overview',
    'users': 'Users',
    'policies': 'Policies',
    'claims': 'Claims',
    'payments': 'Payments / Revenue',
    'agents': 'Agents',
  };

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _generate();
    }
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final stats = await AdminService.instance.getDashboardStats();
      final payments = await AdminService.instance.getPayments(
        fromDate: _dateRange?.start,
        toDate: _dateRange?.end,
        status: 'paid',
      );
      final claims = await AdminService.instance.getClaims();
      final agents = await AdminService.instance.getAgents();

      if (!mounted) return;
      setState(() {
        _data = {
          'stats': stats,
          'payments': payments,
          'claims': claims,
          'agents': agents,
        };
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _generate();
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
                  title: 'Reports & Analytics',
                  subtitle: 'Generate and export reports',
                  action: AdminActionButton(
                    label: 'Date Range',
                    icon: Icons.date_range_rounded,
                    onTap: _pickDateRange,
                    outlined: true,
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${formatDate(_dateRange!.start)} → ${formatDate(_dateRange!.end)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _dateRange = null);
                          _generate();
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _reportTypes.entries.map((e) {
                      final selected = _reportType == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(e.value,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _reportType = e.key);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildReport(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    if (_data.isEmpty) return const SizedBox.shrink();
    final stats = _data['stats'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Export buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showExportSnack('PDF'),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text('PDF', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showExportSnack('Excel'),
              icon: const Icon(Icons.table_chart_rounded, size: 16),
              label: const Text('Excel', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showExportSnack('CSV'),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('CSV', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary cards
        if (stats != null) ...[
          const Text('Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              AdminStatCard(
                title: 'Total Users',
                value: '${stats.totalUsers}',
                icon: Icons.people_rounded,
                color: AppColors.primary,
              ),
              AdminStatCard(
                title: 'Active Policies',
                value: '${stats.activePolicies}',
                icon: Icons.policy_rounded,
                color: AppColors.success,
              ),
              AdminStatCard(
                title: 'Total Revenue',
                value: formatCurrency(stats.totalRevenue),
                icon: Icons.currency_pound_rounded,
                color: AppColors.success,
              ),
              AdminStatCard(
                title: 'Total Claims',
                value:
                    '${stats.pendingClaims + stats.approvedClaims + stats.rejectedClaims}',
                icon: Icons.assignment_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Payments table
        if (_data['payments'] != null &&
            (_data['payments'] as List).isNotEmpty) ...[
          const Text('Recent Paid Transactions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _SimpleTable(
            columns: const ['Reference', 'Amount', 'Date'],
            rows: (_data['payments'] as List)
                .take(10)
                .map((p) => [
                      p.paymentReference as String,
                      formatCurrency(p.amount as double),
                      formatDate(p.createdAt as DateTime),
                    ])
                .toList(),
          ),
        ],

        // Claims summary
        if (_data['claims'] != null) ...[
          const SizedBox(height: 20),
          const Text('Claims Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _ClaimsSummaryTable(claims: _data['claims'] as List),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  void _showExportSnack(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Export to $format — connect your export library to implement this.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _SimpleTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  const _SimpleTable({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Table(
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
            children: columns
                .map((c) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          // Data
          ...rows.map(
            (row) => TableRow(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(cell, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimsSummaryTable extends StatelessWidget {
  final List claims;
  const _ClaimsSummaryTable({required this.claims});

  @override
  Widget build(BuildContext context) {
    final statusCounts = <String, int>{};
    for (final c in claims) {
      final s = c.status as String;
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: statusCounts.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 110, child: StatusBadge(e.key)),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: claims.isNotEmpty ? e.value / claims.length : 0,
                    backgroundColor: statusColor(e.key).withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(statusColor(e.key)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.value}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
