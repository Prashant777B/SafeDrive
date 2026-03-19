import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'car_details_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();

  String? _selectedLicenceType;
  bool _isLookingUpPostcode = false;
  bool _postcodeFound = false;
  String? _postcodeError;

  final List<String> _licenceTypes = [
    'Full UK',
    'Provisional',
    'International',
    'European'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupPostcode() async {
    final postcode = _postcodeController.text.trim().replaceAll(' ', '');

    if (postcode.isEmpty) {
      setState(() => _postcodeError = 'Please enter a postcode');
      return;
    }

    setState(() {
      _isLookingUpPostcode = true;
      _postcodeError = null;
      _postcodeFound = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.postcodes.io/postcodes/$postcode'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        final result = data['result'];
        setState(() {
          _cityController.text =
              result['admin_district'] ?? result['parish'] ?? '';
          _addressLine2Controller.text = result['admin_ward'] ?? '';
          _postcodeFound = true;
          _postcodeError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Postcode found: ${result['admin_district']}'),
              ],
            ),
            backgroundColor: const Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _postcodeError = 'Postcode not found. Please check and try again.';
          _postcodeFound = false;
        });
      }
    } catch (e) {
      setState(() {
        _postcodeError = 'Could not look up postcode. Check your connection.';
        _postcodeFound = false;
      });
    } finally {
      setState(() => _isLookingUpPostcode = false);
    }
  }

  void _proceed() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarDetailsScreen(
            personalDetails: {
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'dob': _dobController.text.trim(),
              'phone': _phoneController.text.trim(),
              'address':
                  '\${_addressLine1Controller.text.trim()}, \${_addressLine2Controller.text.trim()}, \${_cityController.text.trim()}',
              'postcode': _postcodeController.text.trim().toUpperCase(),
              'licenceType': _selectedLicenceType ?? '',
            },
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 17)),
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      _dobController.text = '$day/$month/$year';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Personal Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.5,
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
                _sectionHeader('Step 1 of 2', 'Tell us about yourself'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildField(_firstNameController, 'First Name',
                            Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildField(_lastNameController, 'Last Name',
                            Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration:
                      _inputDecoration('Date of Birth', Icons.cake_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                    _phoneController, 'Phone Number', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                const Text('Address',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Enter your postcode to auto-fill your address',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postcodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          'Postcode (e.g. EH1 1YZ)',
                          Icons.location_on_outlined,
                          suffix: _postcodeFound
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF34A853))
                              : null,
                          errorText: _postcodeError,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isLookingUpPostcode ? null : _lookupPostcode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLookingUpPostcode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Find'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(_addressLine1Controller, 'House Number / Street',
                    Icons.home_outlined),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: _inputDecoration(
                      'Area / District', Icons.map_outlined,
                      helperText: 'Auto-filled from postcode'),
                  validator: (v) => null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: _inputDecoration(
                      'Town / City', Icons.location_city_outlined,
                      helperText: 'Auto-filled from postcode'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLicenceType,
                  decoration: _inputDecoration(
                      'Driving Licence Type', Icons.credit_card_outlined),
                  items: _licenceTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedLicenceType = val),
                  validator: (v) =>
                      v == null ? 'Please select a licence type' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next: Car Details',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
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
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix, String? errorText, String? helperText}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
      suffixIcon: suffix,
      errorText: errorText,
      helperText: helperText,
      helperStyle: const TextStyle(color: Color(0xFF34A853), fontSize: 11),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
    );
  }
}
