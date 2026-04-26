import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'my_policies_screen.dart';

class PolicyConfirmationScreen extends StatefulWidget {
  final Map<String, String> personalDetails;
  final Map<String, String> carDetails;
  final double annualPremium;
  final double monthlyPremium;

  const PolicyConfirmationScreen({
    super.key,
    required this.personalDetails,
    required this.carDetails,
    required this.annualPremium,
    required this.monthlyPremium,
  });

  @override
  State<PolicyConfirmationScreen> createState() =>
      _PolicyConfirmationScreenState();
}

class _PolicyConfirmationScreenState extends State<PolicyConfirmationScreen>
    with SingleTickerProviderStateMixin {
  bool _isPurchasing = false;
  bool _purchased = false;
  String _policyNumber = '';
  String _paymentFrequency = 'annual';

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _coverType => widget.carDetails['coverType'] ?? 'Comprehensive';

  Color get _coverColor {
    switch (_coverType) {
      case 'Third Party':
        return AppColors.orange;
      case 'TP Fire & Theft':
        return AppColors.amber;
      default:
        return AppColors.primary;
    }
  }

  double get _selectedPremium => _paymentFrequency == 'annual'
      ? widget.annualPremium
      : widget.monthlyPremium;

  String get _premiumLabel =>
      _paymentFrequency == 'annual' ? '/year' : '/month';

  Future<void> _purchasePolicy() async {
    setState(() => _isPurchasing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Generate a policy number client-side
      final ts = DateTime.now()
          .millisecondsSinceEpoch
          .toRadixString(36)
          .toUpperCase()
          .padLeft(6, '0')
          .substring(0, 6);
      final policyNo = 'SD-${DateTime.now().year}-$ts';

      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 365));

      await Supabase.instance.client.from(SupabaseTables.policies).insert({
        'user_id': user.id,
        'policy_number': policyNo,
        'cover_type': widget.carDetails['coverType'],
        'car_registration': widget.carDetails['registration'],
        'car_make': widget.carDetails['make'],
        'car_model': widget.carDetails['model'],
        'car_year': widget.carDetails['year'],
        'car_category': widget.carDetails['carCategory'],
        'voluntary_excess': widget.carDetails['excess'],
        'insured_name':
            '${widget.personalDetails['firstName']} ${widget.personalDetails['lastName']}',
        'postcode': widget.personalDetails['postcode'],
        'licence_type': widget.personalDetails['licenceType'],
        'annual_premium': widget.annualPremium,
        'monthly_premium': widget.monthlyPremium,
        'payment_frequency': _paymentFrequency,
        'status': PolicyStatus.active,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _policyNumber = policyNo;
        _purchased = true;
      });
      _animController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not purchase policy: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _coverColor,
        foregroundColor: Colors.white,
        title: Text(
          _purchased ? 'Policy Confirmed!' : 'Purchase Policy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: !_purchased,
      ),
      body: SafeArea(
        child: _purchased ? _buildSuccessView() : _buildConfirmView(),
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────
  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'You\'re Covered!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your policy has been activated. Drive safely!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 28),

          // Policy number card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_coverColor, _coverColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                const Text('Policy Number',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  _policyNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _coverType,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coverage summary
          _buildInfoCard('Coverage Summary', AppColors.primary, [
            _InfoRow('Vehicle',
                '${widget.carDetails['year']} ${widget.carDetails['make']} ${widget.carDetails['model']}'),
            _InfoRow('Registration', widget.carDetails['registration'] ?? ''),
            _InfoRow('Cover Type', _coverType),
            _InfoRow('Annual Premium',
                '£${widget.annualPremium.toStringAsFixed(2)}'),
            _InfoRow('Monthly Option',
                '£${widget.monthlyPremium.toStringAsFixed(2)}/mo'),
            _InfoRow('Voluntary Excess', widget.carDetails['excess'] ?? 'N/A'),
            _InfoRow('Valid From', _formatDate(DateTime.now())),
            _InfoRow('Expiry Date',
                _formatDate(DateTime.now().add(const Duration(days: 365)))),
          ]),
          const SizedBox(height: 20),

          // What's covered
          _buildInclusionsCard(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MyPoliciesScreen()),
                (route) => route.isFirst,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.policy_outlined),
              label: const Text('View My Policies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _coverColor, width: 1.5),
                foregroundColor: _coverColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Confirm / purchase state ───────────────────────────────
  Widget _buildConfirmView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_coverColor, _coverColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _coverColor.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(_coverType,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '£${_selectedPremium.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      height: 1.0),
                ),
                Text(_premiumLabel,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 18),

                // Payment frequency toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _payToggle('Pay Annually', 'annual'),
                      _payToggle('Pay Monthly', 'monthly'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // What's included
          _buildInclusionsCard(),
          const SizedBox(height: 16),

          // Policy details
          _buildInfoCard('Policy Details', AppColors.purple, [
            _InfoRow('Vehicle',
                '${widget.carDetails['year']} ${widget.carDetails['make']} ${widget.carDetails['model']}'),
            _InfoRow('Registration', widget.carDetails['registration'] ?? ''),
            _InfoRow('Category', widget.carDetails['carCategory'] ?? ''),
            _InfoRow('Fuel Type', widget.carDetails['fuelType'] ?? ''),
            _InfoRow('Usage', widget.carDetails['usage'] ?? ''),
            _InfoRow('Voluntary Excess', widget.carDetails['excess'] ?? 'N/A'),
            _InfoRow(
                'No Claims Bonus', widget.carDetails['noClaims'] ?? '0 years'),
          ]),
          const SizedBox(height: 16),

          _buildInfoCard('Policyholder', AppColors.success, [
            _InfoRow('Name',
                '${widget.personalDetails['firstName']} ${widget.personalDetails['lastName']}'),
            _InfoRow(
                'Licence Type', widget.personalDetails['licenceType'] ?? ''),
            _InfoRow('Postcode', widget.personalDetails['postcode'] ?? ''),
            _InfoRow('Cover Starts', _formatDate(DateTime.now())),
            _InfoRow('Cover Ends',
                _formatDate(DateTime.now().add(const Duration(days: 365)))),
          ]),
          const SizedBox(height: 16),

          // Terms notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a demonstration policy for illustrative purposes. By proceeding you acknowledge that SafeDrive is a university project and no real insurance is provided.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _purchasePolicy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Confirm & Activate Policy',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _payToggle(String label, String value) {
    final isSelected = _paymentFrequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentFrequency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? _coverColor : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInclusionsCard() {
    final inclusions = CoverTypes.inclusions[_coverType] ??
        CoverTypes.inclusions['Comprehensive']!;
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
                  color: _coverColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.shield_outlined, color: _coverColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text("What's Included",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _coverColor)),
            ],
          ),
          const Divider(height: 20),
          ...inclusions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            Text(item, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Color color, List<Widget> rows) {
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
                child: Icon(Icons.description_outlined, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            ],
          ),
          const Divider(height: 20),
          ...rows,
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Reusable row widget ─────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
