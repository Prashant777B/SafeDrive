import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteScreen extends StatefulWidget {
  final Map<String, String> personalDetails;
  final Map<String, String> carDetails;

  const QuoteScreen({
    super.key,
    required this.personalDetails,
    required this.carDetails,
  });

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  late double _annualQuote;
  late double _monthlyQuote;
  late String _coverType;
  late List<_PriceFactor> _factors;
  bool _isSaving = false;
  bool _saved = false;

  late AnimationController _animController;
  late Animation<double> _priceAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _priceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _calculateQuote();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── UK-realistic insurance pricing ────────────────────────
  void _calculateQuote() {
    _coverType = widget.carDetails['coverType'] ?? 'Comprehensive';
    _factors = [];

    // 1. Base price by cover type
    double base;
    switch (_coverType) {
      case 'Third Party':
        base = 500.0;
      case 'TP Fire & Theft':
        base = 600.0;
      default: // Comprehensive
        base = 720.0;
    }
    _factors.add(_PriceFactor('Base premium ($_coverType)', base, true));

    // 2. Car category multiplier
    final category = widget.carDetails['carCategory'] ?? 'Family Hatchback';
    final catMultiplier = _categoryMultiplier(category);
    final catAdj = base * (catMultiplier - 1.0);
    base *= catMultiplier;
    if (catAdj.abs() > 1) {
      _factors.add(_PriceFactor('Car type: $category', catAdj, catAdj >= 0));
    }

    // 3. Driver age factor
    final dobParts = widget.personalDetails['dob']?.split('/');
    int age = 35;
    if (dobParts != null && dobParts.length == 3) {
      final birthYear = int.tryParse(dobParts[2]) ?? 1990;
      age = DateTime.now().year - birthYear;
    }
    double ageAdj = _ageAdjustment(age);
    base += ageAdj;
    if (ageAdj != 0) {
      _factors.add(_PriceFactor('Driver age ($age yrs)', ageAdj, ageAdj >= 0));
    }

    // 4. Car age
    final carYear = int.tryParse(widget.carDetails['year'] ?? '2019') ?? 2019;
    final carAge = DateTime.now().year - carYear;
    double carAgeAdj = 0;
    if (carAge <= 2) {
      carAgeAdj = 200;
    } else if (carAge <= 5) {
      carAgeAdj = 80;
    } else if (carAge <= 10) {
      carAgeAdj = 0;
    } else if (carAge <= 15) {
      carAgeAdj = 100;
    } else {
      carAgeAdj = 180;
    }
    base += carAgeAdj;
    if (carAgeAdj != 0) {
      _factors.add(
          _PriceFactor('Car age ($carAge yrs old)', carAgeAdj, carAgeAdj >= 0));
    }

    // 5. Fuel type
    final fuel = widget.carDetails['fuelType'] ?? '';
    double fuelAdj = 0;
    if (fuel == 'Electric') {
      fuelAdj = -60;
    } else if (fuel == 'Hybrid') {
      fuelAdj = -30;
    } else if (fuel == 'Diesel') {
      fuelAdj = 45;
    }
    base += fuelAdj;
    if (fuelAdj != 0) {
      _factors.add(_PriceFactor('Fuel type: $fuel', fuelAdj, fuelAdj >= 0));
    }

    // 6. Usage
    final usage = widget.carDetails['usage'] ?? '';
    double usageAdj = 0;
    if (usage == 'Social & commuting') {
      usageAdj = 120;
    } else if (usage == 'Business use') {
      usageAdj = 280;
    }
    base += usageAdj;
    if (usageAdj != 0) {
      _factors.add(_PriceFactor('Usage: $usage', usageAdj, usageAdj >= 0));
    }

    // 7. Annual mileage
    final mileage =
        int.tryParse(widget.carDetails['mileage'] ?? '8000') ?? 8000;
    double mileAdj = 0;
    if (mileage < 5000) {
      mileAdj = -70;
    } else if (mileage > 20000) {
      mileAdj = 250;
    } else if (mileage > 15000) {
      mileAdj = 160;
    } else if (mileage > 10000) {
      mileAdj = 90;
    }
    base += mileAdj;
    if (mileAdj != 0) {
      _factors.add(_PriceFactor('Annual mileage (${_formatMileage(mileage)})',
          mileAdj, mileAdj >= 0));
    }

    // 8. Licence type
    final licence = widget.personalDetails['licenceType'] ?? '';
    double licAdj = 0;
    if (licence == 'Provisional') {
      licAdj = 380;
    } else if (licence == 'International') {
      licAdj = 140;
    } else if (licence == 'European') {
      licAdj = 80;
    }
    base += licAdj;
    if (licAdj != 0) {
      _factors.add(_PriceFactor('Licence type: $licence', licAdj, licAdj >= 0));
    }

    // 9. No Claims Discount (NCD) — applied to running total
    final noClaimsStr = widget.carDetails['noClaims'] ?? '0 years';
    final claimsYears = _parseNoClaimsYears(noClaimsStr);
    final ncdRate = _ncdDiscount(claimsYears);
    if (ncdRate > 0) {
      final ncdSaving = -(base * ncdRate);
      base += ncdSaving;
      _factors.add(_PriceFactor(
          'No claims bonus ($noClaimsStr, ${(ncdRate * 100).toInt()}% off)',
          ncdSaving,
          false));
    }

    // 10. Voluntary excess reduction
    final excessStr = widget.carDetails['excess'] ?? '£500 (Moderate)';
    final excessRate = _excessDiscount(excessStr);
    if (excessRate > 0) {
      final excessSaving = -(base * excessRate);
      base += excessSaving;
      _factors.add(
          _PriceFactor('Voluntary excess: $excessStr', excessSaving, false));
    }

    _annualQuote = base.clamp(150, 8000);
    _monthlyQuote = _annualQuote / 11.5; // slight finance charge for monthly
  }

  double _categoryMultiplier(String category) {
    switch (category) {
      case 'City Car':
        return 0.70;
      case 'Small Hatchback':
        return 0.85;
      case 'Family Hatchback':
        return 1.00;
      case 'Estate / Saloon':
        return 1.10;
      case 'SUV / Crossover':
        return 1.25;
      case 'Large SUV':
        return 1.45;
      case 'Sports / Performance':
        return 2.20;
      case 'Luxury Saloon':
        return 1.60;
      case 'Van / MPV':
        return 1.35;
      default:
        return 1.00;
    }
  }

  double _ageAdjustment(int age) {
    if (age < 19) return 2200;
    if (age < 21) return 1500;
    if (age < 23) return 900;
    if (age < 25) return 500;
    if (age < 30) return 180;
    if (age < 70) return 0;
    if (age < 75) return 200;
    return 400;
  }

  double _ncdDiscount(int years) {
    if (years == 0) return 0.0;
    if (years == 1) return 0.15;
    if (years == 2) return 0.25;
    if (years == 3) return 0.35;
    if (years == 4) return 0.45;
    return 0.55;
  }

  double _excessDiscount(String excess) {
    if (excess.contains('250')) return 0.0;
    if (excess.contains('500')) return 0.05;
    if (excess.contains('750')) return 0.10;
    if (excess.contains('1,000') || excess.contains('1000')) return 0.15;
    return 0.0;
  }

  int _parseNoClaimsYears(String s) {
    if (s.startsWith('5+')) return 5;
    return int.tryParse(s.split(' ')[0]) ?? 0;
  }

  String _formatMileage(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(0)}k miles';
    return '$m miles';
  }

  // ── Save quote to Supabase ────────────────────────────────
  Future<void> _saveQuote() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('quotes').insert({
        'user_id': user?.id,
        'first_name': widget.personalDetails['firstName'],
        'last_name': widget.personalDetails['lastName'],
        'dob': widget.personalDetails['dob'],
        'phone': widget.personalDetails['phone'],
        'address': widget.personalDetails['address'],
        'postcode': widget.personalDetails['postcode'],
        'licence_type': widget.personalDetails['licenceType'],
        'car_registration': widget.carDetails['registration'],
        'car_make': widget.carDetails['make'],
        'car_model': widget.carDetails['model'],
        'car_year': widget.carDetails['year'],
        'annual_mileage': widget.carDetails['mileage'],
        'fuel_type': widget.carDetails['fuelType'],
        'car_usage': widget.carDetails['usage'],
        'no_claims_years': widget.carDetails['noClaims'],
        'cover_type': widget.carDetails['coverType'],
        'car_category': widget.carDetails['carCategory'],
        'voluntary_excess': widget.carDetails['excess'],
        'annual_quote': _annualQuote,
        'monthly_quote': _monthlyQuote,
        'created_at': DateTime.now().toIso8601String(),
      });
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Quote saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save quote: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color get _coverColor {
    switch (_coverType) {
      case 'Third Party':
        return const Color(0xFFE65100);
      case 'TP Fire & Theft':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF1A73E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        backgroundColor: _coverColor,
        foregroundColor: Colors.white,
        title: const Text('Your Quote',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Quote hero card ───────────────────────────
              AnimatedBuilder(
                animation: _priceAnim,
                builder: (context, child) => Transform.scale(
                  scale: 0.85 + (_priceAnim.value * 0.15),
                  child: Opacity(opacity: _priceAnim.value, child: child),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _coverColor,
                        _coverColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _coverColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _coverType,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.verified_user,
                              color: Colors.white, size: 44),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Estimated Annual Premium',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '£${_annualQuote.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'per year',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '£${_monthlyQuote.toStringAsFixed(2)} / month',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Price breakdown ────────────────────────────
              _SummaryCard(
                title: 'Price Breakdown',
                headerIcon: Icons.bar_chart_outlined,
                color: const Color(0xFF1A73E8),
                child: Column(
                  children: _factors
                      .map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        f.isIncrease
                                            ? Icons.add_circle_outline
                                            : Icons.remove_circle_outline,
                                        size: 14,
                                        color: f.isIncrease
                                            ? const Color(0xFFE65100)
                                            : const Color(0xFF34A853),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          f.label,
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF444444)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${f.amount >= 0 ? '+' : ''}£${f.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: f.isIncrease
                                        ? const Color(0xFFE65100)
                                        : const Color(0xFF34A853),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList()
                    ..add(
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Annual Premium',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              '£${_annualQuote.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _coverColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Your details ──────────────────────────────
              _SummaryCard(
                title: 'Your Details',
                headerIcon: Icons.person_outline,
                color: const Color(0xFF34A853),
                child: Column(
                  children: [
                    _Row('Name',
                        '${widget.personalDetails['firstName']} ${widget.personalDetails['lastName']}'),
                    _Row('Date of Birth', widget.personalDetails['dob'] ?? ''),
                    _Row('Postcode', widget.personalDetails['postcode'] ?? ''),
                    _Row(
                        'Licence', widget.personalDetails['licenceType'] ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Car details ───────────────────────────────
              _SummaryCard(
                title: 'Car Details',
                headerIcon: Icons.directions_car_outlined,
                color: const Color(0xFF7B1FA2),
                child: Column(
                  children: [
                    _Row('Registration',
                        widget.carDetails['registration'] ?? ''),
                    _Row('Vehicle',
                        '${widget.carDetails['year']} ${widget.carDetails['make']} ${widget.carDetails['model']}'),
                    _Row('Category', widget.carDetails['carCategory'] ?? ''),
                    _Row('Fuel Type', widget.carDetails['fuelType'] ?? ''),
                    _Row('Annual Mileage',
                        '${widget.carDetails['mileage']} miles'),
                    _Row(
                        'No Claims Bonus', widget.carDetails['noClaims'] ?? ''),
                    _Row('Voluntary Excess',
                        widget.carDetails['excess'] ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Disclaimer ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is an estimated quote for illustrative purposes only. Final premiums are subject to full underwriting, credit checks, and acceptance criteria. Prices may vary.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black87, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Save button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isSaving || _saved) ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _saved ? Colors.grey.shade400 : _coverColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_saved
                                ? Icons.check_rounded
                                : Icons.save_outlined),
                            const SizedBox(width: 8),
                            Text(
                              _saved ? 'Quote Saved!' : 'Save This Quote',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Start over ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _coverColor, width: 1.5),
                    foregroundColor: _coverColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Get Another Quote',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget helpers ───────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData headerIcon;
  final Color color;
  final Widget child;

  const _SummaryCard({
    required this.title,
    required this.headerIcon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
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
                child: Icon(headerIcon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: color),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

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

class _PriceFactor {
  final String label;
  final double amount;
  final bool isIncrease;
  const _PriceFactor(this.label, this.amount, this.isIncrease);
}
