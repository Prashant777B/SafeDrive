// lib/screens/admin/agent_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({super.key});
  @override
  State<AgentManagementScreen> createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  List<Agent> _agents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final agents = await AdminService.instance.getAgents();
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AgentFormDialog(onSaved: _load),
    );
  }

  void _showEditDialog(Agent a) {
    showDialog(
      context: context,
      builder: (_) => _AgentFormDialog(agent: a, onSaved: _load),
    );
  }

  Future<void> _deleteAgent(Agent a) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Agent',
      message: 'Delete ${a.fullName}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await AdminService.instance.deleteAgent(a.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _agents.where((a) => a.isActive).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: SectionHeader(
              title: 'Agent / Staff Management',
              subtitle: '${_agents.length} agents · $active active',
              action: AdminActionButton(
                label: 'Add Agent',
                icon: Icons.person_add_rounded,
                onTap: _showAddDialog,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _agents.isEmpty
                    ? AdminEmptyState(
                        icon: Icons.support_agent_outlined,
                        title: 'No agents yet',
                        subtitle:
                            'Add agents to assign policies and customers.',
                        action: AdminActionButton(
                          label: 'Add First Agent',
                          icon: Icons.add_rounded,
                          onTap: _showAddDialog,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _agents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final a = _agents[i];
                            return _AgentTile(
                              agent: a,
                              onEdit: () => _showEditDialog(a),
                              onDelete: () => _deleteAgent(a),
                              onToggle: (val) async {
                                await AdminService.instance
                                    .updateAgent(a.id, {'is_active': val});
                                _load();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  final Agent agent;
  final VoidCallback onEdit, onDelete;
  final ValueChanged<bool> onToggle;
  const _AgentTile(
      {required this.agent,
      required this.onEdit,
      required this.onDelete,
      required this.onToggle});

  static const _deptColors = {
    'sales': AppColors.primary,
    'claims': AppColors.warning,
    'support': AppColors.success,
    'renewals': AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final deptColor =
        _deptColors[agent.department?.toLowerCase()] ?? AppColors.textSecondary;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAvatar(initials: agent.initials, color: deptColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(agent.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(agent.agentCode,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Text(agent.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                  value: agent.isActive,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.success),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (agent.department != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: deptColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(agent.department!.toUpperCase(),
                      style: TextStyle(
                          color: deptColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
              ],
              Text('${agent.commissionRate}% commission',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(40, 28)),
                child: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(40, 28)),
                child: const Text('Delete', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentFormDialog extends StatefulWidget {
  final Agent? agent;
  final VoidCallback onSaved;
  const _AgentFormDialog({this.agent, required this.onSaved});

  @override
  State<_AgentFormDialog> createState() => _AgentFormDialogState();
}

class _AgentFormDialogState extends State<_AgentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _commCtrl = TextEditingController(text: '5.00');
  String? _dept;
  bool _loading = false;

  static const _departments = ['Sales', 'Claims', 'Support', 'Renewals'];

  @override
  void initState() {
    super.initState();
    if (widget.agent != null) {
      final a = widget.agent!;
      _nameCtrl.text = a.fullName;
      _emailCtrl.text = a.email;
      _phoneCtrl.text = a.phone ?? '';
      _commCtrl.text = a.commissionRate.toStringAsFixed(2);
      _dept = a.department != null
          ? a.department![0].toUpperCase() + a.department!.substring(1)
          : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _commCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final rate = double.tryParse(_commCtrl.text) ?? 5.0;
      if (widget.agent == null) {
        await AdminService.instance.createAgent(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          department: _dept?.toLowerCase(),
          commissionRate: rate,
        );
      } else {
        await AdminService.instance.updateAgent(widget.agent!.id, {
          'full_name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone':
              _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          'department': _dept?.toLowerCase(),
          'commission_rate': rate,
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
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
      title: Text(widget.agent == null ? 'Add Agent' : 'Edit Agent'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                AdminFormField(
                    label: 'Phone (optional)', controller: _phoneCtrl),
                const SizedBox(height: 12),
                AdminDropdown<String>(
                  label: 'Department',
                  value: _dept,
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _dept = v),
                ),
                const SizedBox(height: 12),
                AdminFormField(
                  label: 'Commission Rate (%)',
                  controller: _commCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
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
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(widget.agent == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
