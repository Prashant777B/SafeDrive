// lib/screens/admin/dashboard_screen.dart
// ────────────────────────────────────────────────────────────
// Admin Dashboard – summary cards, recent activity, mini charts.
// ────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats _stats = DashboardStats.empty();
  List<Map<String, dynamic>> _revenue = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await AdminService.instance.getDashboardStats();
      final revenue = await AdminService.instance.getMonthlyRevenue();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _revenue = revenue;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              floating: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary),
                  onPressed: _load,
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome banner
                    _WelcomeBanner(
                        adminName:
                            AdminService.instance.currentAdmin?.fullName ??
                                'Admin'),
                    const SizedBox(height: 20),

                    // Stat cards grid
                    const _SectionLabel('Overview'),
                    const SizedBox(height: 12),
                    _StatsGrid(stats: _stats),
                    const SizedBox(height: 24),

                    // Revenue chart
                    const _SectionLabel('Monthly Revenue'),
                    const SizedBox(height: 12),
                    _RevenueChart(data: _revenue),
                    const SizedBox(height: 24),

                    // Claims breakdown
                    const _SectionLabel('Claims Breakdown'),
                    const SizedBox(height: 12),
                    _ClaimsBreakdown(stats: _stats),
                    const SizedBox(height: 24),

                    // Quick actions
                    const _SectionLabel('Quick Actions'),
                    const SizedBox(height: 12),
                    const _QuickActions(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String adminName;
  const _WelcomeBanner({required this.adminName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  adminName.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s what\'s happening at SafeDrive today.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.shield_outlined,
            size: 52,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatDef('Total Users', '${stats.totalUsers}', Icons.people_rounded,
          AppColors.primary),
      _StatDef('Active Policies', '${stats.activePolicies}',
          Icons.policy_rounded, AppColors.success),
      _StatDef('Pending Claims', '${stats.pendingClaims}',
          Icons.assignment_late_rounded, AppColors.warning),
      _StatDef('Approved Claims', '${stats.approvedClaims}',
          Icons.check_circle_outline_rounded, AppColors.success),
      _StatDef('Rejected Claims', '${stats.rejectedClaims}',
          Icons.cancel_outlined, AppColors.error),
      _StatDef('Revenue', formatCurrency(stats.totalRevenue),
          Icons.currency_pound_rounded, AppColors.success),
      _StatDef('Open Tickets', '${stats.openTickets}',
          Icons.headset_mic_rounded, AppColors.purple),
      _StatDef('Pending Docs', '${stats.pendingDocuments}',
          Icons.folder_open_rounded, AppColors.orange),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 140,           // ← Increased to prevent overflow
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (ctx, i) {
        final c = cards[i];
        return AdminStatCard(
          title: c.title,
          value: c.value,
          icon: c.icon,
          color: c.color,
        );
      },
    );
  }
}

class _StatDef {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatDef(this.title, this.value, this.icon, this.color);
}

// ... Rest of your file remains unchanged
class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No revenue data available yet.\nPayments will appear here once recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    // ... (rest of _RevenueChart remains the same)
    final maxVal = data
        .map((e) => (e['revenue'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 6 Months',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final val = (item['revenue'] as num).toDouble();
                final frac = maxVal > 0 ? val / maxVal : 0.0;
                final label = (item['month'] as String).split('-').last;
                final months = [
                  '',
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];
                final monthName = months[int.tryParse(label) ?? 0];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '£${(val / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: (100 * frac).clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primary
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          monthName,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Rest of the file (_ClaimsBreakdown, _QuickActions, etc.) remains the same
class _ClaimsBreakdown extends StatelessWidget {
  final DashboardStats stats;
  const _ClaimsBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total =
        stats.pendingClaims + stats.approvedClaims + stats.rejectedClaims;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _ClaimsBar(
              label: 'Pending',
              value: stats.pendingClaims,
              total: total,
              color: AppColors.warning),
          const SizedBox(height: 10),
          _ClaimsBar(
              label: 'Approved',
              value: stats.approvedClaims,
              total: total,
              color: AppColors.success),
          const SizedBox(height: 10),
          _ClaimsBar(
              label: 'Rejected',
              value: stats.rejectedClaims,
              total: total,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _ClaimsBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ClaimsBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? value / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      const _QA('Add User', Icons.person_add_rounded, AppColors.primary),
      const _QA(
          'New Policy', Icons.add_circle_outline_rounded, AppColors.success),
      const _QA('Review Claim', Icons.assignment_turned_in_rounded,
          AppColors.warning),
      const _QA('Send Notice', Icons.send_rounded, AppColors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) {
        final a = actions[i];
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: a.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(a.icon, color: a.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  a.label,
                  style: TextStyle(
                    color: a.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color);
}