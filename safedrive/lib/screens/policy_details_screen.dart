import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'claims_screen.dart';

class PolicyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> policy;

  const PolicyDetailsScreen({super.key, required this.policy});

  @override
  State<PolicyDetailsScreen> createState() => _PolicyDetailsScreenState();
}

class _PolicyDetailsScreenState extends State<PolicyDetailsScreen> {
  bool _isCancelling = false;

  String get _coverType =>
      widget.policy['cover_type'] as String? ?? 'Comprehensive';
  String get _status =>
      widget.policy['status'] as String? ?? PolicyStatus.active;

  Color get _coverColor =>
      CoverTypes.colors[_coverType] ?? AppColors.primary;

  bool get _isActive => _status == PolicyStatus.active;

  Future<void> _cancelPolicy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Policy',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to cancel this policy? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Policy',
                style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Policy'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await Supabase.instance.client
          .from(SupabaseTables.policies)
          .update({'status': PolicyStatus.cancelled})
          .eq('id', widget.policy['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Policy cancelled successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not cancel policy: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    final policyNumber = policy['policy_number'] as String? ?? '';
    final annual = (policy['annual_premium'] as num?)?.toDouble() ?? 0.0;
    final monthly = (policy['monthly_premium'] as num?)?.toDouble() ?? 0.0;
    final startDate = policy['start_date'] as String? ?? '';
    final endDate = policy['end_date'] as String? ?? '';
    final make = policy['car_make'] as String? ?? '';
    final model = policy['car_model'] as String? ?? '';
    final year = policy['car_year'] as String? ?? '';
    final reg = policy['car_registration'] as String? ?? '';
    final category = policy['car_category'] as String? ?? '';
    final excess = policy['voluntary_excess'] as String? ?? 'N/A';
    final insuredName = policy['insured_name'] as String? ?? '';
    final postcode = policy['postcode'] as String? ?? '';
    final licenceType = policy['licence_type'] as String? ?? '';

    final statusColor = PolicyStatus.colorFor(_status);
    final statusIcon = PolicyStatus.iconFor(_status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _coverColor,
        foregroundColor: Colors.white,
        title: const Text('Policy Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Hero card ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _coverColor,
                      _coverColor.withValues(alpha: 0.75)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _coverColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: Colors.white70, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _status[0].toUpperCase() + _status.substring(1),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      policyNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _coverType,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HeroStat('Annual', '£${annual.toStringAsFixed(0)}'),
                        _vDivider(),
                        _HeroStat('Monthly', '£${monthly.toStringAsFixed(0)}'),
                        _vDivider(),
                        _HeroStat('Excess', excess.split(' ')[0]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Status banner ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Policy ${_status[0].toUpperCase()}${_status.substring(1)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor),
                          ),
                          if (startDate.isNotEmpty && endDate.isNotEmpty)
                            Text(
                              '${_fmt(startDate)} → ${_fmt(endDate)}',
                              style: TextStyle(
                                  fontSize: 12, color: statusColor.withValues(alpha: 0.8)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── What's covered ─────────────────────────────
              _InfoSection(
                title: "What's Covered",
                icon: Icons.shield_outlined,
                color: _coverColor,
                children: (CoverTypes.inclusions[_coverType] ??
                        CoverTypes.inclusions['Comprehensive']!)
                    .map((item) => _CheckRow(item))
                    .toList(),
              ),
              const SizedBox(height: 14),

              // ── Vehicle details ────────────────────────────
              _InfoSection(
                title: 'Insured Vehicle',
                icon: Icons.directions_car_outlined,
                color: AppColors.purple,
                children: [
                  _DetailRow('Vehicle', '$year $make $model'),
                  _DetailRow('Registration', reg.toUpperCase()),
                  _DetailRow('Category', category),
                  _DetailRow('Voluntary Excess', excess),
                ],
              ),
              const SizedBox(height: 14),

              // ── Policyholder ───────────────────────────────
              _InfoSection(
                title: 'Policyholder',
                icon: Icons.person_outline,
                color: AppColors.success,
                children: [
                  _DetailRow('Name', insuredName),
                  _DetailRow('Postcode', postcode.toUpperCase()),
                  _DetailRow('Licence Type', licenceType),
                ],
              ),
              const SizedBox(height: 20),

              // ── Actions ────────────────────────────────────
              if (_isActive) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClaimsScreen(
                          policyId: policy['id'] as String? ?? '',
                          policyNumber: policyNumber,
                          coverType: _coverType,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Make a Claim',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : _cancelPolicy,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.error, width: 1.5),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.error, strokeWidth: 2))
                        : const Icon(Icons.cancel_outlined),
                    label: Text(
                      _isCancelling ? 'Cancelling…' : 'Cancel Policy',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.3),
      );

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color)),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
