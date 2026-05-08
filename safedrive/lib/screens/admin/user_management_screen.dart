// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  List<CustomerProfile> _customers = [];
  List<AdminUser> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final customers = await AdminService.instance.getCustomers();
      final admins = await AdminService.instance.getAdminUsers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _admins = admins;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(String q) async {
    final customers = await AdminService.instance.getCustomers(search: q);
    if (!mounted) return;
    setState(() => _customers = customers);
  }

  void _showCustomerDetail(CustomerProfile c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CustomerDetailSheet(customer: c, onUpdated: _load),
    );
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddAdminDialog(onCreated: _load),
    );
  }

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
                SectionHeader(
                  title: 'User Management',
                  subtitle:
                      '${_customers.length} customers · ${_admins.length} admin users',
                  action: AdminActionButton(
                    label: 'Add Admin',
                    icon: Icons.person_add_rounded,
                    onTap: _showAddAdminDialog,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Customers'),
                    Tab(text: 'Admin / Staff'),
                  ],
                ),
              ],
            ),
          ),

          // Search (customers tab only)
          AnimatedBuilder(
            animation: _tabs,
            builder: (_, __) => _tabs.index == 0
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AdminSearchBar(
                      controller: _searchCtrl,
                      hint: 'Search by name or phone…',
                      onChanged: () => _search(_searchCtrl.text),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      // ── Customers ──
                      _customers.isEmpty
                          ? const AdminEmptyState(
                              icon: Icons.people_outline_rounded,
                              title: 'No customers found',
                              subtitle:
                                  'Customers who sign up will appear here.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _customers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final c = _customers[i];
                                  return _CustomerTile(
                                    customer: c,
                                    onTap: () => _showCustomerDetail(c),
                                  );
                                },
                              ),
                            ),

                      // ── Admins ──
                      _admins.isEmpty
                          ? const AdminEmptyState(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'No admin users',
                              subtitle: 'Add admins using the button above.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _admins.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final a = _admins[i];
                                  return _AdminUserTile(
                                    admin: a,
                                    onToggle: (val) async {
                                      await AdminService.instance
                                          .toggleAdminStatus(a.id, val);
                                      _load();
                                    },
                                    onEdit: () => showDialog(
                                      context: context,
                                      builder: (_) => _EditAdminDialog(
                                          admin: a, onUpdated: _load),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Tile ────────────────────────────────────────────
class _CustomerTile extends StatelessWidget {
  final CustomerProfile customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            AdminAvatar(initials: customer.initials, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(customer.phone ?? 'No phone',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (customer.postcode != null)
                    Text(customer.postcode!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(customer.isActive ? 'active' : 'disabled'),
                const SizedBox(height: 4),
                Text(
                  formatDate(customer.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin User Tile ──────────────────────────────────────────
class _AdminUserTile extends StatelessWidget {
  final AdminUser admin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  const _AdminUserTile(
      {required this.admin, required this.onToggle, required this.onEdit});

  Color get _roleColor {
    switch (admin.roleName) {
      case 'super_admin':
        return AppColors.error;
      case 'admin':
        return AppColors.primary;
      case 'agent':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          AdminAvatar(initials: admin.initials, color: _roleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(admin.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin.roleName.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: _roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: admin.isActive,
                onChanged: onToggle,
                activeThumbColor: AppColors.success,
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24)),
                child: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer Detail Bottom Sheet ─────────────────────────────
class _CustomerDetailSheet extends StatefulWidget {
  final CustomerProfile customer;
  final VoidCallback onUpdated;
  const _CustomerDetailSheet({required this.customer, required this.onUpdated});

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl =
        TextEditingController(text: widget.customer.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.customer.lastName ?? '');
    _phoneCtrl = TextEditingController(text: widget.customer.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.customer.address ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AdminService.instance.updateCustomer(widget.customer.id, {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onUpdated();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AdminAvatar(
                      initials: widget.customer.initials,
                      color: AppColors.primary,
                      size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('ID: ${widget.customer.id.substring(0, 8)}…',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(widget.customer.isActive ? 'active' : 'disabled'),
                ],
              ),
            ),
            const Divider(height: 24),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AdminFormField(
                            label: 'First Name',
                            controller: _firstNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminFormField(
                            label: 'Last Name',
                            controller: _lastNameCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AdminFormField(label: 'Phone', controller: _phoneCtrl),
                    const SizedBox(height: 14),
                    AdminFormField(
                        label: 'Address',
                        controller: _addressCtrl,
                        maxLines: 2),
                    const SizedBox(height: 14),
                    // Read-only info
                    _InfoRow('Date of Birth',
                        widget.customer.dateOfBirth ?? 'Not set'),
                    _InfoRow('Licence Type',
                        widget.customer.licenceType ?? 'Not set'),
                    _InfoRow('Postcode', widget.customer.postcode ?? 'Not set'),
                    _InfoRow('Joined', formatDate(widget.customer.createdAt)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Add Admin Dialog ─────────────────────────────────────────
class _AddAdminDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddAdminDialog({required this.onCreated});

  @override
  State<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<_AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<AdminRole> _roles = [];
  int? _selectedRoleId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdminService.instance.getRoles().then((roles) {
      if (mounted) setState(() => _roles = roles);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate() || _selectedRoleId == null) return;
    setState(() => _loading = true);
    try {
      await AdminService.instance.createAdminUser(
        email: _emailCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        roleId: _selectedRoleId!,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admin user created'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Admin User'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminFormField(
                label: 'Full Name',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AdminFormField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 12),
              AdminFormField(label: 'Phone (optional)', controller: _phoneCtrl),
              const SizedBox(height: 12),
              AdminDropdown<int>(
                label: 'Role',
                value: _selectedRoleId,
                items: _roles
                    .map((r) => DropdownMenuItem(
                        value: r.id, child: Text(r.name.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoleId = v),
                validator: (v) => v == null ? 'Select a role' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Default password will be Admin@123 — the user must change it on first login.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _create,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─── Edit Admin Dialog ────────────────────────────────────────
class _EditAdminDialog extends StatefulWidget {
  final AdminUser admin;
  final VoidCallback onUpdated;
  const _EditAdminDialog({required this.admin, required this.onUpdated});

  @override
  State<_EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<_EditAdminDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<AdminRole> _roles = [];
  int? _selectedRoleId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.admin.fullName;
    _phoneCtrl.text = widget.admin.phone ?? '';
    _selectedRoleId = widget.admin.roleId;
    AdminService.instance.getRoles().then((roles) {
      if (mounted) setState(() => _roles = roles);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await AdminService.instance.updateAdminUser(widget.admin.id, {
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'role_id': _selectedRoleId,
    });
    if (!mounted) return;
    Navigator.pop(context);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Admin User'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminFormField(label: 'Full Name', controller: _nameCtrl),
            const SizedBox(height: 12),
            AdminFormField(label: 'Phone (optional)', controller: _phoneCtrl),
            const SizedBox(height: 12),
            AdminDropdown<int>(
              label: 'Role',
              value: _selectedRoleId,
              items: _roles
                  .map((r) => DropdownMenuItem(
                      value: r.id, child: Text(r.name.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoleId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
