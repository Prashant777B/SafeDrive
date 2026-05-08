// lib/screens/admin/admin_shell.dart
// ────────────────────────────────────────────────────────────
// Main admin navigation shell.  Shows a left-hand sidebar on
// wide screens and a bottom/drawer nav on mobile.
// ────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_login_screen.dart';
import 'dashboard_screen.dart';
import 'user_management_screen.dart';
import 'policy_management_screen.dart';
import 'claims_management_screen.dart';
import 'payment_management_screen.dart';
import 'document_management_screen.dart';
import 'agent_management_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';
import 'audit_logs_screen.dart';
import 'settings_screen.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final String permission;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    required this.permission,
  });
}

final List<_NavItem> _navItems = [
  const _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    screen: DashboardScreen(),
    permission: 'all',
  ),
  const _NavItem(
    label: 'Users',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    screen: UserManagementScreen(),
    permission: 'users',
  ),
  const _NavItem(
    label: 'Policies',
    icon: Icons.policy_outlined,
    selectedIcon: Icons.policy_rounded,
    screen: PolicyManagementScreen(),
    permission: 'policies',
  ),
  const _NavItem(
    label: 'Claims',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_rounded,
    screen: ClaimsManagementScreen(),
    permission: 'claims',
  ),
  const _NavItem(
    label: 'Payments',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    screen: PaymentManagementScreen(),
    permission: 'payments',
  ),
  const _NavItem(
    label: 'Documents',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    screen: DocumentManagementScreen(),
    permission: 'documents',
  ),
  const _NavItem(
    label: 'Agents',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    screen: AgentManagementScreen(),
    permission: 'agents',
  ),
  const _NavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    screen: ReportsScreen(),
    permission: 'reports',
  ),
  const _NavItem(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    screen: NotificationsScreen(),
    permission: 'notifications',
  ),
  const _NavItem(
    label: 'Support',
    icon: Icons.headset_mic_outlined,
    selectedIcon: Icons.headset_mic_rounded,
    screen: SupportScreen(),
    permission: 'support',
  ),
  const _NavItem(
    label: 'Audit Logs',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history_rounded,
    screen: AuditLogsScreen(),
    permission: 'all',
  ),
  const _NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    screen: SettingsScreen(),
    permission: 'settings',
  ),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  List<_NavItem> get _accessibleItems {
    final admin = AdminService.instance.currentAdmin;
    if (admin == null) return [];
    if (admin.roleName == 'super_admin') return _navItems;
    return _navItems
        .where((item) =>
            item.permission == 'all' ||
            AdminService.instance.can(item.permission))
        .toList();
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AdminService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminService.instance.currentAdmin;
    if (admin == null) {
      return const AdminLoginScreen();
    }

    final items = _accessibleItems;
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            _AdminSidebar(
              items: items,
              selectedIndex: _selectedIndex,
              admin: admin,
              onItemTap: (i) => setState(() => _selectedIndex = i),
              onLogout: _logout,
            ),
            // Main content
            Expanded(
              child: items.isEmpty
                  ? const _NoAccessView()
                  : items[_selectedIndex].screen,
            ),
          ],
        ),
      );
    }

    // Mobile: drawer + bottom bar (show first 5 items in bottom nav)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          items.isEmpty ? 'Admin' : items[_selectedIndex].label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: Drawer(
        child: _AdminDrawerContent(
          items: items,
          selectedIndex: _selectedIndex,
          admin: admin,
          onItemTap: (i) {
            setState(() => _selectedIndex = i);
            Navigator.pop(context);
          },
          onLogout: _logout,
        ),
      ),
      body:
          items.isEmpty ? const _NoAccessView() : items[_selectedIndex].screen,
    );
  }
}

// ─── Desktop Sidebar ──────────────────────────────────────────
class _AdminSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final dynamic admin;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.admin,
    required this.onItemTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1624),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SafeDrive',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1F2937), height: 1),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final selected = i == selectedIndex;
                return _SidebarItem(
                  item: item,
                  selected: selected,
                  onTap: () => onItemTap(i),
                );
              },
            ),
          ),

          const Divider(color: Color(0xFF1F2937), height: 1),

          // Admin info + logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      admin.initials,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.fullName.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        admin.roleName.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFF6B7280), size: 18),
                  onPressed: onLogout,
                  tooltip: 'Sign Out',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 18,
                color:
                    selected ? AppColors.primaryLight : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile Drawer Content ────────────────────────────────────
class _AdminDrawerContent extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final dynamic admin;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const _AdminDrawerContent({
    required this.items,
    required this.selectedIndex,
    required this.admin,
    required this.onItemTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1624),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F1624)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                const Text('SafeDrive Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(admin.email,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return ListTile(
                  leading: Icon(
                    i == selectedIndex ? item.selectedIcon : item.icon,
                    color: i == selectedIndex
                        ? AppColors.primaryLight
                        : const Color(0xFF9CA3AF),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: i == selectedIndex
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      fontWeight: i == selectedIndex
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: i == selectedIndex,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                  onTap: () => onItemTap(i),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFF9CA3AF)),
            title: const Text('Sign Out',
                style: TextStyle(color: Color(0xFF9CA3AF))),
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  const _NoAccessView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Access Restricted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('You do not have permission to access any admin sections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
