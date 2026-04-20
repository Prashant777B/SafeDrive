import 'package:flutter/material.dart';
import 'quote_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Map<String, String> personalDetails;

  const CarDetailsScreen({super.key, required this.personalDetails});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  String _selectedCoverType = 'Comprehensive';
  String? _selectedFuelType;
  String? _selectedUsage;
  String? _selectedNoClaims;
  String? _selectedCarCategory;
  String? _selectedExcess;

  static const _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid'];
  static const _usageTypes = [
    'Social only',
    'Social & commuting',
    'Business use'
  ];
  static const _noClaimsYears = [
    '0 years',
    '1 year',
    '2 years',
    '3 years',
    '4 years',
    '5+ years',
  ];
  static const _carCategories = [
    'City Car',
    'Small Hatchback',
    'Family Hatchback',
    'Estate / Saloon',
    'SUV / Crossover',
    'Large SUV',
    'Sports / Performance',
    'Luxury Saloon',
    'Van / MPV',
  ];
  static const _excessOptions = [
    '£250 (Standard)',
    '£500 (Moderate)',
    '£750 (Higher)',
    '£1,000 (Maximum)',
  ];

  static const _coverTypes = [
    _CoverOption(
      name: 'Third Party',
      short: 'TP Only',
      icon: Icons.gavel_outlined,
      color: Color(0xFFE65100),
      desc: 'Legal minimum',
    ),
    _CoverOption(
      name: 'TP Fire & Theft',
      short: 'TPFT',
      icon: Icons.local_fire_department_outlined,
      color: Color(0xFFF9A825),
      desc: '+ fire & theft',
    ),
    _CoverOption(
      name: 'Comprehensive',
      short: 'Comprehensive',
      icon: Icons.verified_user_outlined,
      color: Color(0xFF1A73E8),
      desc: 'Most popular',
      isPopular: true,
    ),
  ];

  @override
  void dispose() {
    _regController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _getQuote() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuoteScreen(
            personalDetails: widget.personalDetails,
            carDetails: {
              'registration': _regController.text.trim().toUpperCase(),
              'make': _makeController.text.trim(),
              'model': _modelController.text.trim(),
              'year': _yearController.text.trim(),
              'mileage': _mileageController.text.trim(),
              'fuelType': _selectedFuelType ?? '',
              'usage': _selectedUsage ?? '',
              'noClaims': _selectedNoClaims ?? '0 years',
              'carCategory': _selectedCarCategory ?? 'Family Hatchback',
              'coverType': _selectedCoverType,
              'excess': _selectedExcess ?? '£500 (Moderate)',
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Car Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                _sectionHeader('Step 2 of 2', 'Tell us about your car'),
                const SizedBox(height: 22),

                // ── Cover type selection ──────────────────────
                const Text(
                  'Choose Your Cover Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the level of protection that suits you',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _coverTypes.map((ct) {
                    final isSelected = _selectedCoverType == ct.name;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCoverType = ct.name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? ct.color : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? ct.color
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: ct.color.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  ct.icon,
                                  size: 26,
                                  color: isSelected ? Colors.white : ct.color,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  ct.short,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ct.desc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (ct.isPopular && !isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ct.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Popular',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: ct.color,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.check_circle,
                                        color: Colors.white, size: 14),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Car details form ──────────────────────────
                _formCard([
                  TextFormField(
                    controller: _regController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dec('Registration (e.g. AB12 CDE)',
                        Icons.confirmation_number_outlined),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _field(_makeController, 'Make (e.g. Ford)',
                              Icons.directions_car_outlined)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _field(_modelController, 'Model (e.g. Focus)',
                              Icons.car_repair)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _yearController,
                          'Build Year',
                          Icons.calendar_month_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          _mileageController,
                          'Annual Mileage',
                          Icons.speed_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),

                _formCard([
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCarCategory,
                    decoration: _dec('Car Category', Icons.category_outlined),
                    items: _carCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCarCategory = v),
                    validator: (v) =>
                        v == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFuelType,
                    decoration:
                        _dec('Fuel Type', Icons.local_gas_station_outlined),
                    items: _fuelTypes
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFuelType = v),
                    validator: (v) =>
                        v == null ? 'Please select fuel type' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUsage,
                    decoration: _dec('Car Usage', Icons.route_outlined),
                    items: _usageTypes
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUsage = v),
                    validator: (v) =>
                        v == null ? 'Please select usage type' : null,
                  ),
                ]),
                const SizedBox(height: 16),

                _formCard([
                  DropdownButtonFormField<String>(
                    initialValue: _selectedNoClaims,
                    decoration:
                        _dec('No Claims Bonus (NCB)', Icons.verified_outlined),
                    items: _noClaimsYears
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedNoClaims = v),
                    validator: (v) =>
                        v == null ? 'Please select NCB years' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExcess,
                    decoration: _dec('Voluntary Excess', Icons.tune_outlined),
                    hint: const Text('Select voluntary excess'),
                    items: _excessOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedExcess = v),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF1A73E8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Higher voluntary excess = lower premium. NCB of 5+ years can save up to 55%.',
                            style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF1A73E8)
                                    .withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _getQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate_outlined, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Calculate My Quote',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionHeader(String step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step,
            style: const TextStyle(
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      decoration: _dec(label, icon),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF2F5FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class _CoverOption {
  final String name;
  final String short;
  final IconData icon;
  final Color color;
  final String desc;
  final bool isPopular;

  const _CoverOption({
    required this.name,
    required this.short,
    required this.icon,
    required this.color,
    required this.desc,
    this.isPopular = false,
  });
}
