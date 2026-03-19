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

  String? _selectedFuelType;
  String? _selectedUsage;
  String? _selectedNoClaims;

  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid'];
  final List<String> _usageTypes = [
    'Social only',
    'Social & commuting',
    'Business use'
  ];
  final List<String> _noClaimsYears = [
    '0 years',
    '1 year',
    '2 years',
    '3 years',
    '4 years',
    '5+ years'
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
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Car Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Step 2 of 2', 'Tell us about your car'),
                const SizedBox(height: 24),

                // Registration
                TextFormField(
                  controller: _regController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                      'Car Registration (e.g. AB12 CDE)', Icons.numbers),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Make & Model
                Row(
                  children: [
                    Expanded(
                        child: _buildField(_makeController, 'Make (e.g. Ford)',
                            Icons.directions_car_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildField(_modelController,
                            'Model (e.g. Focus)', Icons.car_repair)),
                  ],
                ),
                const SizedBox(height: 16),

                // Year & Mileage
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _yearController,
                        'Build Year',
                        Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        _mileageController,
                        'Annual Mileage',
                        Icons.speed_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fuel Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedFuelType,
                  decoration: _inputDecoration(
                      'Fuel Type', Icons.local_gas_station_outlined),
                  items: _fuelTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFuelType = val),
                  validator: (v) =>
                      v == null ? 'Please select fuel type' : null,
                ),
                const SizedBox(height: 16),

                // Usage
                DropdownButtonFormField<String>(
                  initialValue: _selectedUsage,
                  decoration:
                      _inputDecoration('Car Usage', Icons.route_outlined),
                  items: _usageTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedUsage = val),
                  validator: (v) =>
                      v == null ? 'Please select usage type' : null,
                ),
                const SizedBox(height: 16),

                // No Claims
                DropdownButtonFormField<String>(
                  initialValue: _selectedNoClaims,
                  decoration: _inputDecoration(
                      'No Claims Bonus', Icons.verified_outlined),
                  items: _noClaimsYears
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedNoClaims = val),
                  validator: (v) =>
                      v == null ? 'Please select no claims years' : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _getQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate_outlined),
                        SizedBox(width: 8),
                        Text('Get My Quote',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
      filled: true,
      fillColor: Colors.white,
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
    );
  }
}
