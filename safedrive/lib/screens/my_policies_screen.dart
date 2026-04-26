import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'policy_details_screen.dart';
import 'personal_details_screen.dart';

class MyPoliciesScreen extends StatefulWidget {
  const MyPoliciesScreen({super.key});

  @override
  State<MyPoliciesScreen> createState() => _MyPoliciesScreenState();
}

class _MyPoliciesScreenState extends State<MyPoliciesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPolicies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from(SupabaseTables.policies)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() => _policies = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = 'Could not load policies. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _activePolicies => _policies
      .where((p) => p['status'] == PolicyStatus.active || p['status'] == PolicyStatus.pending)
      .toList();

  List<Map<String, dynamic>> get _inactivePolicies => _policies
      .where((p) =>
          p['status'] == PolicyStatus.expired ||
          p['status'] == PolicyStatus.cancelled)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title:
            const Text('My Policies', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPolicies,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Active (${_activePolicies.length})'),
            Tab(text: 'Past (${_inactivePolicies.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPolicyList(_activePolicies, isActive: true),
                    _buildPolicyList(_inactivePolicies, isActive: false),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPolicies,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyList(List<Map<String, dynamic>> policies,
      {required bool isActive}) {
    if (policies.isEmpty) {
      return _EmptyPolicies(
        isActive: isActive,
        onGetQuote: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const PersonalDetailsScreen()),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPolicies,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: policies.length,
        itemBuilder: (context, i) => _PolicyCard(
          policy: policies[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PolicyDetailsScreen(policy: policies[i])),
          ).then((_) => _loadPolicies()),
        ),
      ),
    );
  }
}

// ── Policy Card ─────────────────────────────────────────────

class _PolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final VoidCallback onTap;
  const _PolicyCard({required this.policy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = policy['status'] as String? ?? PolicyStatus.active;
    final coverType = policy['cover_type'] as String? ?? 'Comprehensive';
    final policyNumber = policy['policy_number'] as String? ?? '';
    final annual =
        (policy['annual_premium'] as num?)?.toDouble() ?? 0.0;
    final endDate = policy['end_date'] as String? ?? '';
    final make = policy['car_make'] as String? ?? '';
    final model = policy['car_model'] as String? ?? '';
    final year = policy['car_year'] as String? ?? '';
    final reg = policy['car_registration'] as String? ?? '';

    final statusColor = PolicyStatus.colorFor(status);
    final statusIcon = PolicyStatus.iconFor(status);
    final coverColor = CoverTypes.colors[coverType] ?? AppColors.primary;

    String formattedEnd = '';
    if (endDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(endDate);
        formattedEnd =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // Top bar with cover colour
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: coverColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Icon(CoverTypes.icons[coverType] ?? Icons.verified_user_outlined,
                      color: coverColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    coverType,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: coverColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$year $make $model',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              reg.toUpperCase(),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '£${annual.toStringAsFixed(0)}/yr',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: coverColor,
                            ),
                          ),
                          if (formattedEnd.isNotEmpty)
                            Text(
                              'Expires $formattedEnd',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Tag(Icons.numbers_outlined, policyNumber,
                          Colors.grey.shade600),
                      const Spacer(),
                      Text(
                        'View Details →',
                        style: TextStyle(
                            color: coverColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
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

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Tag(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────

class _EmptyPolicies extends StatelessWidget {
  final bool isActive;
  final VoidCallback onGetQuote;
  const _EmptyPolicies({required this.isActive, required this.onGetQuote});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.policy_outlined : Icons.history_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isActive ? 'No Active Policies' : 'No Past Policies',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isActive
                  ? 'You don\'t have any active policies yet.\nGet a quote and activate your first policy!'
                  : 'No expired or cancelled policies found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 14, height: 1.55),
            ),
            if (isActive) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onGetQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Get a Quote',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
