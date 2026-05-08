// lib/services/admin_service.dart
// ────────────────────────────────────────────────────────────
// Centralised data-access layer for the SafeDrive Admin Panel.
// All Supabase queries live here; screens call these methods.
// ────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── Current session ─────────────────────────────────────────
  /// Logged-in admin stored in memory for this session.
  AdminUser? currentAdmin;

  bool get isLoggedIn => currentAdmin != null;

  bool can(String action) => currentAdmin != null
      ? (currentAdmin!.roleName == 'super_admin' ||
          currentAdmin!.roleName == 'admin')
      : false;

  // ────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────

  /// Validate admin credentials (email + plain password).
  /// NOTE: In production use Supabase Auth or a proper auth endpoint.
  /// Here we do a simple lookup and compare the stored hash stub.
  Future<AdminUser?> login(String email, String password) async {
    // Fetch admin record
    final res = await _db
        .from('admin_users')
        .select('*, admin_roles(name)')
        .eq('email', email.toLowerCase().trim())
        .eq('is_active', true)
        .maybeSingle();

    if (res == null) return null;

    // ⚠️ IMPORTANT: In production, use bcrypt.checkpw(password, res['password_hash'])
    // For development we accept the hard-coded test password.
    // Replace this with a real bcrypt comparison before going live.
    final validPassword =
        (res['password_hash'] as String).startsWith('\$2b\$') &&
            password == 'Admin@123';

    if (!validPassword) return null;

    final admin = AdminUser.fromMap(res);
    currentAdmin = admin;

    // Update last_login
    await _db.from('admin_users').update(
        {'last_login': DateTime.now().toIso8601String()}).eq('id', admin.id);

    // Write audit log
    await _writeLog(
      admin: admin,
      actionType: 'login',
      description: 'Admin logged in',
    );

    return admin;
  }

  Future<void> logout() async {
    if (currentAdmin != null) {
      await _writeLog(
        admin: currentAdmin,
        actionType: 'logout',
        description: 'Admin logged out',
      );
    }
    currentAdmin = null;
  }

  // ────────────────────────────────────────────────────────────
  // DASHBOARD
  // ────────────────────────────────────────────────────────────

  Future<DashboardStats> getDashboardStats() async {
    final res = await _db.from('admin_dashboard_stats').select().maybeSingle();
    if (res == null) return DashboardStats.empty();
    return DashboardStats.fromMap(res);
  }

  /// Monthly revenue for the last 6 months.
  Future<List<Map<String, dynamic>>> getMonthlyRevenue() async {
    final res = await _db.rpc('admin_monthly_revenue');
    final rows = List<Map<String, dynamic>>.from(res as List);
    // Fallback: compute from payments if RPC not available
    if (rows.isEmpty) {
      return _fallbackMonthlyRevenue();
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _fallbackMonthlyRevenue() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final payments = await _db
        .from('payments')
        .select('amount, paid_at')
        .eq('status', 'paid')
        .gte('paid_at', sixMonthsAgo.toIso8601String())
        .order('paid_at');

    // Group by month
    final Map<String, double> grouped = {};
    for (final p in payments) {
      if (p['paid_at'] == null) continue;
      final dt = DateTime.parse(p['paid_at'] as String);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      grouped[key] = (grouped[key] ?? 0) + (p['amount'] as num).toDouble();
    }
    return grouped.entries
        .map((e) => {'month': e.key, 'revenue': e.value})
        .toList();
  }

  // ────────────────────────────────────────────────────────────
  // USERS (customers)
  // ────────────────────────────────────────────────────────────

  Future<List<CustomerProfile>> getCustomers({
    String? search,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db
        .from('user_profiles')
        .select('*, auth_email:id'); // Note: email lives in auth.users

    if (search != null && search.isNotEmpty) {
      query = query.or(
          'first_name.ilike.%$search%,last_name.ilike.%$search%,phone.ilike.%$search%');
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => CustomerProfile.fromMap(r)).toList();
  }

  Future<CustomerProfile?> getCustomer(String userId) async {
    final res =
        await _db.from('user_profiles').select().eq('id', userId).maybeSingle();
    return res == null ? null : CustomerProfile.fromMap(res);
  }

  Future<void> updateCustomer(
      String userId, Map<String, dynamic> updates) async {
    await _db.from('user_profiles').update(updates).eq('id', userId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'user_profiles',
      affectedId: userId,
      description: 'Updated customer profile',
      newValues: updates,
    );
  }

  // ────────────────────────────────────────────────────────────
  // ADMIN USERS
  // ────────────────────────────────────────────────────────────

  Future<List<AdminUser>> getAdminUsers() async {
    final res = await _db
        .from('admin_users')
        .select('*, admin_roles(name)')
        .order('created_at', ascending: false);
    return res.map((r) => AdminUser.fromMap(r)).toList();
  }

  Future<AdminUser?> createAdminUser({
    required String email,
    required String fullName,
    required int roleId,
    String? phone,
  }) async {
    // In production hash the password properly
    final res = await _db
        .from('admin_users')
        .insert({
          'email': email.toLowerCase().trim(),
          'password_hash': r'$2b$12$placeholder_change_me',
          'full_name': fullName,
          'phone': phone,
          'role_id': roleId,
        })
        .select('*, admin_roles(name)')
        .single();

    final admin = AdminUser.fromMap(res);
    await _writeLog(
      actionType: 'create',
      affectedTable: 'admin_users',
      affectedId: admin.id,
      description: 'Created admin user: $email',
    );
    return admin;
  }

  Future<void> updateAdminUser(
      String adminId, Map<String, dynamic> updates) async {
    await _db.from('admin_users').update(updates).eq('id', adminId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'admin_users',
      affectedId: adminId,
      description: 'Updated admin user',
      newValues: updates,
    );
  }

  Future<void> toggleAdminStatus(String adminId, bool isActive) async {
    await _db
        .from('admin_users')
        .update({'is_active': isActive}).eq('id', adminId);
    await _writeLog(
      actionType: isActive ? 'update' : 'update',
      affectedTable: 'admin_users',
      affectedId: adminId,
      description:
          isActive ? 'Enabled admin account' : 'Disabled admin account',
    );
  }

  Future<List<AdminRole>> getRoles() async {
    final res = await _db.from('admin_roles').select().order('id');
    return res.map((r) => AdminRole.fromMap(r)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // POLICIES
  // ────────────────────────────────────────────────────────────

  Future<List<AdminPolicy>> getPolicies({
    String? search,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db.from('policies').select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
          'policy_number.ilike.%$search%,car_registration.ilike.%$search%,insured_name.ilike.%$search%');
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => AdminPolicy.fromMap(r)).toList();
  }

  Future<AdminPolicy?> getPolicy(String policyId) async {
    final res =
        await _db.from('policies').select().eq('id', policyId).maybeSingle();
    return res == null ? null : AdminPolicy.fromMap(res);
  }

  Future<void> updatePolicyStatus(String policyId, String status) async {
    final old = await getPolicy(policyId);
    await _db.from('policies').update({'status': status}).eq('id', policyId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'policies',
      affectedId: policyId,
      description: 'Policy status changed to $status',
      oldValues: {'status': old?.status},
      newValues: {'status': status},
    );
  }

  Future<void> updatePolicy(
      String policyId, Map<String, dynamic> updates) async {
    await _db.from('policies').update(updates).eq('id', policyId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'policies',
      affectedId: policyId,
      description: 'Policy updated',
      newValues: updates,
    );
  }

  Future<void> deletePolicy(String policyId) async {
    await _db.from('policies').delete().eq('id', policyId);
    await _writeLog(
      actionType: 'delete',
      affectedTable: 'policies',
      affectedId: policyId,
      description: 'Policy deleted',
    );
  }

  // ────────────────────────────────────────────────────────────
  // CLAIMS
  // ────────────────────────────────────────────────────────────

  Future<List<AdminClaim>> getClaims({
    String? search,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db.from('claims').select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
          'claim_number.ilike.%$search%,claim_type.ilike.%$search%,description.ilike.%$search%');
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => AdminClaim.fromMap(r)).toList();
  }

  Future<AdminClaim?> getClaim(String claimId) async {
    final res =
        await _db.from('claims').select().eq('id', claimId).maybeSingle();
    return res == null ? null : AdminClaim.fromMap(res);
  }

  Future<void> updateClaimStatus(String claimId, String status,
      {String? notes, double? settlementAmount}) async {
    final updates = <String, dynamic>{'status': status};
    if (notes != null) updates['notes'] = notes;
    if (settlementAmount != null) {
      updates['settlement_amount'] = settlementAmount;
    }

    await _db.from('claims').update(updates).eq('id', claimId);
    await _writeLog(
      actionType: status == 'approved'
          ? 'approve'
          : status == 'rejected'
              ? 'reject'
              : 'update',
      affectedTable: 'claims',
      affectedId: claimId,
      description: 'Claim status changed to $status',
      newValues: updates,
    );
  }

  // ────────────────────────────────────────────────────────────
  // PAYMENTS
  // ────────────────────────────────────────────────────────────

  Future<List<AdminPayment>> getPayments({
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db.from('payments').select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
          'payment_reference.ilike.%$search%,payment_method.ilike.%$search%');
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => AdminPayment.fromMap(r)).toList();
  }

  Future<void> updatePaymentStatus(String paymentId, String status,
      {String? notes}) async {
    final updates = <String, dynamic>{'status': status};
    if (notes != null) updates['notes'] = notes;
    if (status == 'paid') updates['paid_at'] = DateTime.now().toIso8601String();

    await _db.from('payments').update(updates).eq('id', paymentId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'payments',
      affectedId: paymentId,
      description: 'Payment status changed to $status',
      newValues: updates,
    );
  }

  Future<AdminPayment?> createPayment({
    required String userId,
    String? policyId,
    required double amount,
    required String paymentType,
    String? paymentMethod,
    String? notes,
  }) async {
    final ref = await _db.rpc('generate_payment_reference') as String;
    final res = await _db
        .from('payments')
        .insert({
          'user_id': userId,
          'policy_id': policyId,
          'payment_reference': ref,
          'amount': amount,
          'payment_type': paymentType,
          'payment_method': paymentMethod,
          'notes': notes,
          'status': 'pending',
        })
        .select()
        .single();

    await _writeLog(
      actionType: 'create',
      affectedTable: 'payments',
      affectedId: res['id'] as String,
      description: 'Payment record created: $ref (£$amount)',
    );

    return AdminPayment.fromMap(res);
  }

  // ────────────────────────────────────────────────────────────
  // DOCUMENTS
  // ────────────────────────────────────────────────────────────

  Future<List<AdminDocument>> getDocuments({
    String? userId,
    String? status,
    String? documentType,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db.from('documents').select();

    if (userId != null) query = query.eq('user_id', userId);
    if (status != null && status != 'all') {
      query = query.eq('verification_status', status);
    }
    if (documentType != null && documentType != 'all') {
      query = query.eq('document_type', documentType);
    }

    final res = await query
        .order('uploaded_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => AdminDocument.fromMap(r)).toList();
  }

  Future<void> verifyDocument(String docId,
      {bool approved = true, String? rejectionReason}) async {
    if (currentAdmin == null) return;
    await _db.from('documents').update({
      'verification_status': approved ? 'verified' : 'rejected',
      'verified_by': currentAdmin!.id,
      'verified_at': DateTime.now().toIso8601String(),
      if (!approved) 'rejection_reason': rejectionReason,
    }).eq('id', docId);

    await _writeLog(
      actionType: approved ? 'approve' : 'reject',
      affectedTable: 'documents',
      affectedId: docId,
      description: approved
          ? 'Document verified'
          : 'Document rejected: $rejectionReason',
    );
  }

  // ────────────────────────────────────────────────────────────
  // AGENTS
  // ────────────────────────────────────────────────────────────

  Future<List<Agent>> getAgents({bool? activeOnly}) async {
    var query = _db.from('agents').select();
    if (activeOnly == true) query = query.eq('is_active', true);
    final res = await query.order('created_at', ascending: false);
    return res.map((r) => Agent.fromMap(r)).toList();
  }

  Future<Agent?> createAgent({
    required String fullName,
    required String email,
    String? phone,
    String? department,
    double commissionRate = 5.0,
    DateTime? hiredDate,
    String? notes,
  }) async {
    // Generate agent code
    final count = await _db.from('agents').select('id');
    final code = 'AGT-${(count.length + 1).toString().padLeft(3, '0')}';

    final res = await _db
        .from('agents')
        .insert({
          'agent_code': code,
          'full_name': fullName,
          'email': email.toLowerCase().trim(),
          'phone': phone,
          'department': department,
          'commission_rate': commissionRate,
          'hired_date': hiredDate?.toIso8601String().split('T').first,
          'notes': notes,
        })
        .select()
        .single();

    await _writeLog(
      actionType: 'create',
      affectedTable: 'agents',
      affectedId: res['id'] as String,
      description: 'Agent created: $email ($code)',
    );
    return Agent.fromMap(res);
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> updates) async {
    await _db.from('agents').update(updates).eq('id', agentId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'agents',
      affectedId: agentId,
      description: 'Agent updated',
      newValues: updates,
    );
  }

  Future<void> deleteAgent(String agentId) async {
    await _db.from('agents').delete().eq('id', agentId);
    await _writeLog(
      actionType: 'delete',
      affectedTable: 'agents',
      affectedId: agentId,
      description: 'Agent deleted',
    );
  }

  Future<List<Map<String, dynamic>>> getAgentCommissions(String agentId) async {
    final res = await _db
        .from('commissions')
        .select()
        .eq('agent_id', agentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ────────────────────────────────────────────────────────────

  Future<List<AdminNotification>> getNotifications({int limit = 50}) async {
    final res = await _db
        .from('notifications')
        .select()
        .order('sent_at', ascending: false)
        .limit(limit);
    return res.map((r) => AdminNotification.fromMap(r)).toList();
  }

  Future<void> sendNotification({
    String? userId, // null = broadcast
    required String title,
    required String message,
    required String type,
    String channel = 'in_app',
  }) async {
    if (currentAdmin == null) return;
    await _db.from('notifications').insert({
      'user_id': userId,
      'sent_by': currentAdmin!.id,
      'title': title,
      'message': message,
      'type': type,
      'channel': channel,
    });

    await _writeLog(
      actionType: 'create',
      affectedTable: 'notifications',
      description: userId != null
          ? 'Notification sent to user $userId: $title'
          : 'Broadcast notification sent: $title',
    );
  }

  // ────────────────────────────────────────────────────────────
  // SUPPORT TICKETS
  // ────────────────────────────────────────────────────────────

  Future<List<SupportTicket>> getSupportTickets({
    String? status,
    String? priority,
    String? search,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _db.from('support_tickets').select('*, ticket_replies(*)');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (priority != null && priority != 'all') {
      query = query.eq('priority', priority);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('subject.ilike.%$search%,ticket_number.ilike.%$search%');
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => SupportTicket.fromMap(r)).toList();
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'closed' || status == 'resolved') {
      updates['closed_at'] = DateTime.now().toIso8601String();
    }
    await _db.from('support_tickets').update(updates).eq('id', ticketId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'support_tickets',
      affectedId: ticketId,
      description: 'Ticket status changed to $status',
    );
  }

  Future<void> replyToTicket(String ticketId, String message,
      {bool isInternal = false}) async {
    await _db.from('ticket_replies').insert({
      'ticket_id': ticketId,
      'sender_id': currentAdmin?.id,
      'message': message,
      'is_internal': isInternal,
    });
    await _writeLog(
      actionType: 'update',
      affectedTable: 'ticket_replies',
      affectedId: ticketId,
      description: isInternal
          ? 'Internal note added to ticket'
          : 'Reply sent to customer',
    );
  }

  Future<void> assignTicket(String ticketId, String adminId) async {
    await _db
        .from('support_tickets')
        .update({'assigned_to': adminId}).eq('id', ticketId);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'support_tickets',
      affectedId: ticketId,
      description: 'Ticket assigned to admin $adminId',
    );
  }

  // ────────────────────────────────────────────────────────────
  // AUDIT LOGS
  // ────────────────────────────────────────────────────────────

  Future<List<AuditLog>> getAuditLogs({
    String? adminId,
    String? actionType,
    String? affectedTable,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 50,
  }) async {
    var query = _db.from('audit_logs').select();

    if (adminId != null) query = query.eq('admin_id', adminId);
    if (actionType != null && actionType != 'all') {
      query = query.eq('action_type', actionType);
    }
    if (affectedTable != null && affectedTable != 'all') {
      query = query.eq('affected_table', affectedTable);
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return res.map((r) => AuditLog.fromMap(r)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // SYSTEM SETTINGS
  // ────────────────────────────────────────────────────────────

  Future<Map<String, String>> getSettings({String? category}) async {
    var query = _db.from('system_settings').select('key, value');
    if (category != null) query = query.eq('category', category);
    final res = await query;
    return {
      for (final r in res) r['key'] as String: r['value'] as String? ?? ''
    };
  }

  Future<List<Map<String, dynamic>>> getSettingsWithMeta(
      {String? category}) async {
    var query = _db.from('system_settings').select();
    if (category != null) query = query.eq('category', category);
    final res = await query.order('category').order('key');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateSetting(String key, String value) async {
    if (currentAdmin == null) return;
    await _db.from('system_settings').update({
      'value': value,
      'updated_by': currentAdmin!.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('key', key);
    await _writeLog(
      actionType: 'update',
      affectedTable: 'system_settings',
      affectedId: key,
      description: 'Setting updated: $key = $value',
    );
  }

  // ────────────────────────────────────────────────────────────
  // INTERNAL AUDIT LOG WRITER
  // ────────────────────────────────────────────────────────────

  Future<void> _writeLog({
    AdminUser? admin,
    required String actionType,
    String? affectedTable,
    String? affectedId,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final who = admin ?? currentAdmin;
    try {
      await _db.from('audit_logs').insert({
        'admin_id': who?.id,
        'admin_email': who?.email,
        'action_type': actionType,
        'affected_table': affectedTable,
        'affected_id': affectedId,
        'description': description,
        'old_values': oldValues,
        'new_values': newValues,
      });
    } catch (_) {
      // Audit log failures should never crash the app
    }
  }

  // Public audit log writer for screens to use directly
  Future<void> logAction({
    required String actionType,
    required String description,
    String? affectedTable,
    String? affectedId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    await _writeLog(
      actionType: actionType,
      description: description,
      affectedTable: affectedTable,
      affectedId: affectedId,
      oldValues: oldValues,
      newValues: newValues,
    );
  }
}
