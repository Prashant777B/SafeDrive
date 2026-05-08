// lib/screens/admin/settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _settings = [];
  bool _loading = true;
  bool _saving = false;

  // Controllers for each editable setting (key → controller)
  final Map<String, TextEditingController> _controllers = {};

  static const _categories = [
    'company',
    'payment',
    'insurance',
    'notifications',
    'terms'
  ];
  static const _categoryLabels = {
    'company': 'Company',
    'payment': 'Payment',
    'insurance': 'Insurance',
    'notifications': 'Notifications',
    'terms': 'Terms & Conditions',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await AdminService.instance.getSettingsWithMeta();
      if (!mounted) return;

      // Build a controller for each setting
      for (final s in settings) {
        final key = s['key'] as String;
        _controllers.putIfAbsent(
          key,
          () => TextEditingController(text: s['value'] as String? ?? ''),
        );
        // If controller already exists, update its text
        _controllers[key]!.text = s['value'] as String? ?? '';
      }

      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCategory(String category) async {
    setState(() => _saving = true);
    try {
      final catSettings = _settings.where((s) => s['category'] == category);
      for (final s in catSettings) {
        final key = s['key'] as String;
        final value = _controllers[key]?.text.trim() ?? '';
        await AdminService.instance.updateSetting(key, value);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_categoryLabels[category]} settings saved'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _getForCategory(String cat) =>
      _settings.where((s) => s['category'] == cat).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'System Settings',
                  subtitle: 'Manage app configuration and company details',
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  isScrollable: true,
                  tabs: _categories
                      .map((c) => Tab(text: _categoryLabels[c] ?? c))
                      .toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabs,
                    children: _categories
                        .map((cat) => _SettingsCategoryView(
                              category: cat,
                              settings: _getForCategory(cat),
                              controllers: _controllers,
                              saving: _saving,
                              onSave: () => _saveCategory(cat),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCategoryView extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> settings;
  final Map<String, TextEditingController> controllers;
  final bool saving;
  final VoidCallback onSave;

  const _SettingsCategoryView({
    required this.category,
    required this.settings,
    required this.controllers,
    required this.saving,
    required this.onSave,
  });

  IconData _categoryIcon() {
    switch (category) {
      case 'company':
        return Icons.business_rounded;
      case 'payment':
        return Icons.credit_card_rounded;
      case 'insurance':
        return Icons.shield_rounded;
      case 'notifications':
        return Icons.notifications_rounded;
      case 'terms':
        return Icons.gavel_rounded;
      default:
        return Icons.settings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(_categoryIcon(), color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  '${category[0].toUpperCase()}${category.substring(1)} Settings',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (settings.isEmpty)
            const AdminEmptyState(
              icon: Icons.settings_outlined,
              title: 'No settings in this category',
            )
          else ...[
            // Settings fields
            ...settings.map((s) {
              final key = s['key'] as String;
              final label = (s['label'] as String?) ?? key.replaceAll('_', ' ');
              final description = s['description'] as String?;
              final ctrl = controllers[key];

              // Boolean settings → Switch
              if (s['value'] == 'true' || s['value'] == 'false') {
                return _BoolSetting(
                  label: label,
                  description: description,
                  controller: ctrl!,
                );
              }

              // Long text → multiline
              final isLong = key.contains('terms') ||
                  key.contains('text') ||
                  key.contains('address');
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AdminFormField(
                  label: label,
                  hint: description,
                  controller: ctrl,
                  maxLines: isLong ? 5 : 1,
                  keyboardType: key.contains('phone')
                      ? TextInputType.phone
                      : key.contains('email')
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                ),
              );
            }),
          ],

          const SizedBox(height: 8),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(saving ? 'Saving…' : 'Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security info box (show for all categories)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_rounded,
                    color: AppColors.warning, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Note',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.warning)),
                      SizedBox(height: 4),
                      Text(
                        'Changes to system settings are recorded in the Audit Log. '
                        'Sensitive keys (API keys, passwords) should be stored in '
                        'environment variables, not directly in this form.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BoolSetting extends StatefulWidget {
  final String label;
  final String? description;
  final TextEditingController controller;
  const _BoolSetting(
      {required this.label, this.description, required this.controller});

  @override
  State<_BoolSetting> createState() => _BoolSettingState();
}

class _BoolSettingState extends State<_BoolSetting> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.controller.text == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (widget.description != null)
                  Text(widget.description!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) {
              setState(() => _value = v);
              widget.controller.text = v.toString();
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
