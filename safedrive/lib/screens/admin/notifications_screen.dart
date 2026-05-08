// lib/screens/admin/notifications_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AdminNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifs = await AdminService.instance.getNotifications(limit: 100);
      if (!mounted) return;
      setState(() {
        _notifications = notifs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSendDialog() {
    showDialog(
      context: context,
      builder: (_) => _SendNotificationDialog(onSent: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: SectionHeader(
              title: 'Notifications',
              subtitle: '${_notifications.length} sent',
              action: AdminActionButton(
                label: 'Send Notification',
                icon: Icons.send_rounded,
                onTap: _showSendDialog,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _notifications.isEmpty
                    ? AdminEmptyState(
                        icon: Icons.notifications_outlined,
                        title: 'No notifications sent',
                        subtitle: 'Send your first notification to customers.',
                        action: AdminActionButton(
                          label: 'Send Now',
                          icon: Icons.send_rounded,
                          onTap: _showSendDialog,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final n = _notifications[i];
                            return _NotifTile(notif: n);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AdminNotification notif;
  const _NotifTile({required this.notif});

  static const _typeIcons = {
    'info': Icons.info_outline_rounded,
    'policy_approved': Icons.policy_rounded,
    'claim_update': Icons.assignment_rounded,
    'payment_reminder': Icons.payments_rounded,
    'renewal': Icons.autorenew_rounded,
    'custom': Icons.notifications_rounded,
  };

  static const _typeColors = {
    'info': AppColors.primary,
    'policy_approved': AppColors.success,
    'claim_update': AppColors.warning,
    'payment_reminder': AppColors.orange,
    'renewal': AppColors.purple,
    'custom': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[notif.type] ?? AppColors.primary;
    final icon = _typeIcons[notif.type] ?? Icons.notifications_rounded;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notif.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notif.channel.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notif.message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${notif.userId == null ? 'All users' : 'User'} · ${formatDateTime(notif.sentAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendNotificationDialog extends StatefulWidget {
  final VoidCallback onSent;
  const _SendNotificationDialog({required this.onSent});
  @override
  State<_SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<_SendNotificationDialog> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _type = 'info';
  String _channel = 'in_app';
  bool _broadcast = true;
  bool _sending = false;

  static const _types = [
    'info',
    'policy_approved',
    'claim_update',
    'payment_reminder',
    'renewal',
    'custom'
  ];
  static const _channels = ['in_app', 'email', 'sms', 'push'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _sending = true);
    await AdminService.instance.sendNotification(
      userId: _broadcast ? null : null, // extend for specific user
      title: _titleCtrl.text.trim(),
      message: _msgCtrl.text.trim(),
      type: _type,
      channel: _channel,
    );
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Notification sent'),
          backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Notification'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminFormField(
                label: 'Title',
                controller: _titleCtrl,
                hint: 'e.g. Policy Renewal Reminder',
              ),
              const SizedBox(height: 12),
              AdminFormField(
                label: 'Message',
                controller: _msgCtrl,
                maxLines: 4,
                hint: 'Notification message…',
              ),
              const SizedBox(height: 12),
              AdminDropdown<String>(
                label: 'Type',
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'info'),
              ),
              const SizedBox(height: 12),
              AdminDropdown<String>(
                label: 'Channel',
                value: _channel,
                items: _channels
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _channel = v ?? 'in_app'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Broadcast to all users',
                    style: TextStyle(fontSize: 13)),
                value: _broadcast,
                onChanged: (v) => setState(() => _broadcast = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
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
          onPressed: _sending ? null : _send,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Send'),
        ),
      ],
    );
  }
}
