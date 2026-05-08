// lib/screens/admin/support_screen.dart
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'admin_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  final _searchCtrl = TextEditingController();
  List<SupportTicket> _tickets = [];
  bool _loading = true;

  static const _statuses = ['All', 'Open', 'Pending', 'Resolved', 'Closed'];
  static const _priorities = ['All', 'Urgent', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tickets = await AdminService.instance.getSupportTickets(
        status: _statusFilter == 'all' ? null : _statusFilter,
        priority: _priorityFilter == 'all' ? null : _priorityFilter,
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTicket(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TicketDetailSheet(ticket: ticket, onUpdated: _load),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Support / Complaints',
                  subtitle: '${_tickets.length} tickets',
                ),
                const SizedBox(height: 12),
                AdminSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search subject, ticket number…',
                  onChanged: _load,
                ),
                const SizedBox(height: 8),
                FilterChipRow(
                  options: _statuses,
                  selected: _statusFilter,
                  onSelected: (s) {
                    setState(() => _statusFilter = s);
                    _load();
                  },
                ),
                const SizedBox(height: 6),
                FilterChipRow(
                  options: _priorities,
                  selected: _priorityFilter,
                  onSelected: (p) {
                    setState(() => _priorityFilter = p);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _tickets.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.headset_mic_outlined,
                        title: 'No support tickets',
                        subtitle: 'Customer support requests will appear here.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final t = _tickets[i];
                            return _TicketTile(
                                ticket: t, onTap: () => _openTicket(t));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  const _TicketTile({required this.ticket, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ticket.ticketNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ),
                StatusBadge(ticket.status),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        priorityColor(ticket.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.priority.toUpperCase(),
                    style: TextStyle(
                        color: priorityColor(ticket.priority),
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(ticket.subject,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(ticket.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const Spacer(),
                Text(formatDate(ticket.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailSheet extends StatefulWidget {
  final SupportTicket ticket;
  final VoidCallback onUpdated;
  const _TicketDetailSheet({required this.ticket, required this.onUpdated});

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  final _replyCtrl = TextEditingController();
  bool _internal = false;
  bool _sending = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await AdminService.instance.replyToTicket(
      widget.ticket.id,
      _replyCtrl.text.trim(),
      isInternal: _internal,
    );
    if (!mounted) return;
    _replyCtrl.clear();
    setState(() => _sending = false);
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reply sent'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _changeStatus(String newStatus) async {
    await AdminService.instance.updateTicketStatus(widget.ticket.id, newStatus);
    if (!mounted) return;
    setState(() => _status = newStatus);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.ticketNumber,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Text(t.subject,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  StatusBadge(_status),
                ],
              ),
            ),
            const Divider(height: 16),

            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t.description,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 12),

                    // Replies
                    if (t.replies.isNotEmpty) ...[
                      const Text('Conversation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...t.replies.map((r) => _ReplyBubble(reply: r)),
                      const SizedBox(height: 12),
                    ],

                    // Reply box
                    const Text('Reply',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _replyCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type your reply…',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _internal,
                          onChanged: (v) =>
                              setState(() => _internal = v ?? false),
                          activeColor: AppColors.warning,
                        ),
                        const Text('Internal note only',
                            style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _sending ? null : _reply,
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send Reply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text('Update Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['open', 'pending', 'resolved', 'closed']
                          .map((s) => OutlinedButton(
                                onPressed: _status == s
                                    ? null
                                    : () => _changeStatus(s),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor(s),
                                  side: BorderSide(color: statusColor(s)),
                                  backgroundColor: _status == s
                                      ? statusColor(s).withValues(alpha: 0.1)
                                      : null,
                                ),
                                child: Text(s.toUpperCase(),
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
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

class _ReplyBubble extends StatelessWidget {
  final TicketReply reply;
  const _ReplyBubble({required this.reply});

  @override
  Widget build(BuildContext context) {
    final isAdmin = reply.senderId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAdmin) const SizedBox(width: 0),
          if (isAdmin) const Spacer(),
          Flexible(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reply.isInternal
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : isAdmin
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: reply.isInternal
                    ? Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isAdmin
                            ? (reply.isInternal ? '🔒 Internal Note' : 'Admin')
                            : 'Customer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(formatDateTime(reply.createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reply.message, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          if (!isAdmin) const Spacer(),
        ],
      ),
    );
  }
}
