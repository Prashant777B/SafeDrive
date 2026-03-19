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

class _QuoteScreenState extends State<QuoteScreen> {
  late double _annualQuote;
  late double _monthlyQuote;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _calculateQuote();
  }

  void _calculateQuote() {
    double base = 500.0;

    // Age factor from DOB
    final dobParts = widget.personalDetails['dob']?.split('/');
    if (dobParts != null && dobParts.length == 3) {
      final birthYear = int.tryParse(dobParts[2]) ?? 1990;
      final age = DateTime.now().year - birthYear;
      if (age < 25)
        base += 400;
      else if (age < 30)
        base += 150;
      else if (age > 70)
        base += 200;
      else
        base += 50;
    }

    // Car age factor
    final carYear = int.tryParse(widget.carDetails['year'] ?? '2015') ?? 2015;
    final carAge = DateTime.now().year - carYear;
    if (carAge > 15)
      base += 200;
    else if (carAge > 10)
      base += 100;
    else if (carAge < 3) base += 150; // Newer = more expensive to repair

    // Fuel type
    final fuel = widget.carDetails['fuelType'] ?? '';
    if (fuel == 'Electric')
      base -= 80;
    else if (fuel == 'Diesel') base += 60;

    // Usage
    final usage = widget.carDetails['usage'] ?? '';
    if (usage == 'Business use')
      base += 250;
    else if (usage == 'Social & commuting') base += 100;

    // No claims bonus
    final noClaims = widget.carDetails['noClaims'] ?? '0 years';
    final claimsYears = int.tryParse(noClaims.split(' ')[0]) ?? 0;
    base -= (claimsYears * 60).toDouble();

    // Mileage
    final mileage =
        int.tryParse(widget.carDetails['mileage'] ?? '8000') ?? 8000;
    if (mileage > 20000)
      base += 200;
    else if (mileage > 15000)
      base += 100;
    else if (mileage < 5000) base -= 80;

    // Licence type
    final licence = widget.personalDetails['licenceType'] ?? '';
    if (licence == 'Provisional')
      base += 350;
    else if (licence == 'International') base += 120;

    _annualQuote = base.clamp(300, 5000);
    _monthlyQuote = _annualQuote / 12;
  }

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
        'annual_quote': _annualQuote,
        'monthly_quote': _monthlyQuote,
        'created_at': DateTime.now().toIso8601String(),
      });
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote saved successfully!'),
            backgroundColor: Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving quote: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Your Quote',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Quote banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34A853), Color(0xFF1E8E3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Estimated Quote',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '£${_annualQuote.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'per year',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:  0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'or £${_monthlyQuote.toStringAsFixed(2)}/month',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary card
              _SummaryCard(
                title: 'Your Details',
                items: [
                  _SummaryItem('Name',
                      '${widget.personalDetails['firstName']} ${widget.personalDetails['lastName']}'),
                  _SummaryItem(
                      'Date of Birth', widget.personalDetails['dob'] ?? ''),
                  _SummaryItem(
                      'Postcode', widget.personalDetails['postcode'] ?? ''),
                  _SummaryItem(
                      'Licence', widget.personalDetails['licenceType'] ?? ''),
                ],
              ),
              const SizedBox(height: 16),

              _SummaryCard(
                title: 'Car Details',
                items: [
                  _SummaryItem(
                      'Registration', widget.carDetails['registration'] ?? ''),
                  _SummaryItem('Vehicle',
                      '${widget.carDetails['year']} ${widget.carDetails['make']} ${widget.carDetails['model']}'),
                  _SummaryItem(
                      'Fuel Type', widget.carDetails['fuelType'] ?? ''),
                  _SummaryItem('Annual Mileage',
                      '${widget.carDetails['mileage']} miles'),
                  _SummaryItem(
                      'No Claims Bonus', widget.carDetails['noClaims'] ?? ''),
                ],
              ),
              const SizedBox(height: 24),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is an estimated quote for illustrative purposes only. Final premiums may vary based on a full underwriting assessment.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSaving || _saved) ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _saved ? Colors.grey : const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            Icon(_saved ? Icons.check : Icons.save_outlined),
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
              const SizedBox(height: 12),

              // Start over
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A73E8)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Get Another Quote',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<_SummaryItem> items;

  const _SummaryCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A73E8))),
          const Divider(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(item.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  const _SummaryItem(this.label, this.value);
}
