// lib/models/admin_models.dart
// ────────────────────────────────────────────────────────────
// Data models for the SafeDrive Admin Panel.
// Each class maps 1:1 to a Supabase table.
// ────────────────────────────────────────────────────────────

// ─── Admin Role ───────────────────────────────────────────────
class AdminRole {
  final int id;
  final String name;
  final Map<String, dynamic> permissions;

  const AdminRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory AdminRole.fromMap(Map<String, dynamic> m) => AdminRole(
        id: m['id'] as int,
        name: m['name'] as String,
        permissions: Map<String, dynamic>.from(m['permissions'] as Map? ?? {}),
      );

  bool can(String action) =>
      permissions['all'] == true || permissions[action] == true;
}

// ─── Admin User ───────────────────────────────────────────────
class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final int roleId;
  final String roleName;
  final bool isActive;
  final DateTime? lastLogin;
  final String? avatarUrl;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roleId,
    required this.roleName,
    required this.isActive,
    this.lastLogin,
    this.avatarUrl,
    required this.createdAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> m) => AdminUser(
        id: m['id'] as String,
        email: m['email'] as String,
        fullName: m['full_name'] as String,
        phone: m['phone'] as String?,
        roleId: m['role_id'] as int,
        roleName: (m['admin_roles'] as Map?)?['name'] as String? ?? 'staff',
        isActive: m['is_active'] as bool? ?? true,
        lastLogin: m['last_login'] != null
            ? DateTime.parse(m['last_login'] as String)
            : null,
        avatarUrl: m['avatar_url'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─── User Profile (customer) ──────────────────────────────────
class CustomerProfile {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? postcode;
  final String? dateOfBirth;
  final String? licenceType;
  final DateTime createdAt;
  final bool isActive;

  const CustomerProfile({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.postcode,
    this.dateOfBirth,
    this.licenceType,
    required this.createdAt,
    this.isActive = true,
  });

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    final full = '$f $l'.trim();
    return full.isEmpty ? 'Unknown User' : full;
  }

  String get initials {
    final f = firstName?.isNotEmpty == true ? firstName![0] : '';
    final l = lastName?.isNotEmpty == true ? lastName![0] : '';
    return '$f$l'.toUpperCase().isEmpty ? '?' : '$f$l'.toUpperCase();
  }

  factory CustomerProfile.fromMap(Map<String, dynamic> m) => CustomerProfile(
        id: m['id'] as String,
        email: m['email'] as String?,
        firstName: m['first_name'] as String?,
        lastName: m['last_name'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        postcode: m['postcode'] as String?,
        dateOfBirth: m['date_of_birth'] as String?,
        licenceType: m['licence_type'] as String?,
        createdAt: DateTime.parse(
            m['created_at'] as String? ?? DateTime.now().toIso8601String()),
        isActive: m['is_active'] as bool? ?? true,
      );
}

// ─── Policy ───────────────────────────────────────────────────
class AdminPolicy {
  final String id;
  final String userId;
  final String? quoteId;
  final String policyNumber;
  final String coverType;
  final String? carRegistration;
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? insuredName;
  final String? postcode;
  final String? licenceType;
  final double? annualPremium;
  final double? monthlyPremium;
  final String paymentFrequency;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  // Optional joined customer email
  final String? customerEmail;

  const AdminPolicy({
    required this.id,
    required this.userId,
    this.quoteId,
    required this.policyNumber,
    required this.coverType,
    this.carRegistration,
    this.carMake,
    this.carModel,
    this.carYear,
    this.insuredName,
    this.postcode,
    this.licenceType,
    this.annualPremium,
    this.monthlyPremium,
    required this.paymentFrequency,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.customerEmail,
  });

  factory AdminPolicy.fromMap(Map<String, dynamic> m) => AdminPolicy(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        quoteId: m['quote_id'] as String?,
        policyNumber: m['policy_number'] as String,
        coverType: m['cover_type'] as String,
        carRegistration: m['car_registration'] as String?,
        carMake: m['car_make'] as String?,
        carModel: m['car_model'] as String?,
        carYear: m['car_year'] as String?,
        insuredName: m['insured_name'] as String?,
        postcode: m['postcode'] as String?,
        licenceType: m['licence_type'] as String?,
        annualPremium: (m['annual_premium'] as num?)?.toDouble(),
        monthlyPremium: (m['monthly_premium'] as num?)?.toDouble(),
        paymentFrequency: m['payment_frequency'] as String? ?? 'annual',
        status: m['status'] as String? ?? 'pending',
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: DateTime.parse(m['end_date'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
        customerEmail: m['customer_email'] as String?,
      );

  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get isDueForRenewal =>
      endDate.difference(DateTime.now()).inDays <= 30 && !isExpired;
}

// ─── Claim ────────────────────────────────────────────────────
class AdminClaim {
  final String id;
  final String userId;
  final String? policyId;
  final String claimNumber;
  final String claimType;
  final DateTime incidentDate;
  final String? incidentLocation;
  final String description;
  final double? estimatedCost;
  final double? settlementAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined
  final String? customerName;
  final String? policyNumber;

  const AdminClaim({
    required this.id,
    required this.userId,
    this.policyId,
    required this.claimNumber,
    required this.claimType,
    required this.incidentDate,
    this.incidentLocation,
    required this.description,
    this.estimatedCost,
    this.settlementAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.policyNumber,
  });

  factory AdminClaim.fromMap(Map<String, dynamic> m) => AdminClaim(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        policyId: m['policy_id'] as String?,
        claimNumber: m['claim_number'] as String,
        claimType: m['claim_type'] as String,
        incidentDate: DateTime.parse(m['incident_date'] as String),
        incidentLocation: m['incident_location'] as String?,
        description: m['description'] as String,
        estimatedCost: (m['estimated_cost'] as num?)?.toDouble(),
        settlementAmount: (m['settlement_amount'] as num?)?.toDouble(),
        status: m['status'] as String? ?? 'submitted',
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        customerName: m['customer_name'] as String?,
        policyNumber: m['policy_number'] as String?,
      );
}

// ─── Payment ──────────────────────────────────────────────────
class AdminPayment {
  final String id;
  final String userId;
  final String? policyId;
  final String paymentReference;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String paymentType;
  final String status;
  final DateTime? paidAt;
  final String? failureReason;
  final double? refundAmount;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;
  // Joined
  final String? customerName;
  final String? policyNumber;

  const AdminPayment({
    required this.id,
    required this.userId,
    this.policyId,
    required this.paymentReference,
    required this.amount,
    required this.currency,
    this.paymentMethod,
    required this.paymentType,
    required this.status,
    this.paidAt,
    this.failureReason,
    this.refundAmount,
    this.receiptUrl,
    this.notes,
    required this.createdAt,
    this.customerName,
    this.policyNumber,
  });

  factory AdminPayment.fromMap(Map<String, dynamic> m) => AdminPayment(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        policyId: m['policy_id'] as String?,
        paymentReference: m['payment_reference'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String? ?? 'GBP',
        paymentMethod: m['payment_method'] as String?,
        paymentType: m['payment_type'] as String? ?? 'premium',
        status: m['status'] as String? ?? 'pending',
        paidAt: m['paid_at'] != null
            ? DateTime.parse(m['paid_at'] as String)
            : null,
        failureReason: m['failure_reason'] as String?,
        refundAmount: (m['refund_amount'] as num?)?.toDouble(),
        receiptUrl: m['receipt_url'] as String?,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        customerName: m['customer_name'] as String?,
        policyNumber: m['policy_number'] as String?,
      );
}

// ─── Document ─────────────────────────────────────────────────
class AdminDocument {
  final String id;
  final String userId;
  final String? claimId;
  final String? policyId;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime uploadedAt;
  // Joined
  final String? customerName;

  const AdminDocument({
    required this.id,
    required this.userId,
    this.claimId,
    this.policyId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.notes,
    required this.uploadedAt,
    this.customerName,
  });

  factory AdminDocument.fromMap(Map<String, dynamic> m) => AdminDocument(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        claimId: m['claim_id'] as String?,
        policyId: m['policy_id'] as String?,
        documentType: m['document_type'] as String,
        fileName: m['file_name'] as String,
        fileUrl: m['file_url'] as String,
        fileSize: m['file_size'] as int?,
        mimeType: m['mime_type'] as String?,
        verificationStatus: m['verification_status'] as String? ?? 'pending',
        verifiedBy: m['verified_by'] as String?,
        verifiedAt: m['verified_at'] != null
            ? DateTime.parse(m['verified_at'] as String)
            : null,
        rejectionReason: m['rejection_reason'] as String?,
        notes: m['notes'] as String?,
        uploadedAt: DateTime.parse(m['uploaded_at'] as String),
        customerName: m['customer_name'] as String?,
      );
}

// ─── Agent ────────────────────────────────────────────────────
class Agent {
  final String id;
  final String? adminUserId;
  final String agentCode;
  final String fullName;
  final String email;
  final String? phone;
  final String? department;
  final double commissionRate;
  final bool isActive;
  final DateTime? hiredDate;
  final String? notes;
  final DateTime createdAt;
  // Performance (computed)
  final int? totalPolicies;
  final int? totalClaims;
  final double? totalCommission;

  const Agent({
    required this.id,
    this.adminUserId,
    required this.agentCode,
    required this.fullName,
    required this.email,
    this.phone,
    this.department,
    required this.commissionRate,
    required this.isActive,
    this.hiredDate,
    this.notes,
    required this.createdAt,
    this.totalPolicies,
    this.totalClaims,
    this.totalCommission,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory Agent.fromMap(Map<String, dynamic> m) => Agent(
        id: m['id'] as String,
        adminUserId: m['admin_user_id'] as String?,
        agentCode: m['agent_code'] as String,
        fullName: m['full_name'] as String,
        email: m['email'] as String,
        phone: m['phone'] as String?,
        department: m['department'] as String?,
        commissionRate: (m['commission_rate'] as num?)?.toDouble() ?? 5.0,
        isActive: m['is_active'] as bool? ?? true,
        hiredDate: m['hired_date'] != null
            ? DateTime.parse(m['hired_date'] as String)
            : null,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        totalPolicies: m['total_policies'] as int?,
        totalClaims: m['total_claims'] as int?,
        totalCommission: (m['total_commission'] as num?)?.toDouble(),
      );
}

// ─── Notification ─────────────────────────────────────────────
class AdminNotification {
  final String id;
  final String? userId;
  final String? sentBy;
  final String title;
  final String message;
  final String type;
  final String channel;
  final bool isRead;
  final DateTime? readAt;
  final DateTime sentAt;

  const AdminNotification({
    required this.id,
    this.userId,
    this.sentBy,
    required this.title,
    required this.message,
    required this.type,
    required this.channel,
    required this.isRead,
    this.readAt,
    required this.sentAt,
  });

  factory AdminNotification.fromMap(Map<String, dynamic> m) =>
      AdminNotification(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        sentBy: m['sent_by'] as String?,
        title: m['title'] as String,
        message: m['message'] as String,
        type: m['type'] as String? ?? 'info',
        channel: m['channel'] as String? ?? 'in_app',
        isRead: m['is_read'] as bool? ?? false,
        readAt: m['read_at'] != null
            ? DateTime.parse(m['read_at'] as String)
            : null,
        sentAt: DateTime.parse(m['sent_at'] as String),
      );
}

// ─── Support Ticket ───────────────────────────────────────────
class SupportTicket {
  final String id;
  final String ticketNumber;
  final String userId;
  final String? assignedTo;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined
  final String? customerName;
  final String? assigneeName;
  final List<TicketReply> replies;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    this.assignedTo,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.assigneeName,
    this.replies = const [],
  });

  factory SupportTicket.fromMap(Map<String, dynamic> m) => SupportTicket(
        id: m['id'] as String,
        ticketNumber: m['ticket_number'] as String,
        userId: m['user_id'] as String,
        assignedTo: m['assigned_to'] as String?,
        subject: m['subject'] as String,
        description: m['description'] as String,
        category: m['category'] as String? ?? 'general',
        priority: m['priority'] as String? ?? 'medium',
        status: m['status'] as String? ?? 'open',
        closedAt: m['closed_at'] != null
            ? DateTime.parse(m['closed_at'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        customerName: m['customer_name'] as String?,
        assigneeName: m['assignee_name'] as String?,
        replies: (m['ticket_replies'] as List<dynamic>? ?? [])
            .map((r) => TicketReply.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
}

class TicketReply {
  final String id;
  final String ticketId;
  final String? senderId;
  final String message;
  final bool isInternal;
  final DateTime createdAt;
  // Joined
  final String? senderName;

  const TicketReply({
    required this.id,
    required this.ticketId,
    this.senderId,
    required this.message,
    required this.isInternal,
    required this.createdAt,
    this.senderName,
  });

  factory TicketReply.fromMap(Map<String, dynamic> m) => TicketReply(
        id: m['id'] as String,
        ticketId: m['ticket_id'] as String,
        senderId: m['sender_id'] as String?,
        message: m['message'] as String,
        isInternal: m['is_internal'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
        senderName: m['sender_name'] as String?,
      );
}

// ─── Audit Log ────────────────────────────────────────────────
class AuditLog {
  final String id;
  final String? adminId;
  final String? adminEmail;
  final String actionType;
  final String? affectedTable;
  final String? affectedId;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    this.adminId,
    this.adminEmail,
    required this.actionType,
    this.affectedTable,
    this.affectedId,
    required this.description,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'] as String,
        adminId: m['admin_id'] as String?,
        adminEmail: m['admin_email'] as String?,
        actionType: m['action_type'] as String,
        affectedTable: m['affected_table'] as String?,
        affectedId: m['affected_id'] as String?,
        description: m['description'] as String,
        oldValues: m['old_values'] as Map<String, dynamic>?,
        newValues: m['new_values'] as Map<String, dynamic>?,
        ipAddress: m['ip_address'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

// ─── Dashboard Stats ──────────────────────────────────────────
class DashboardStats {
  final int totalUsers;
  final int activePolicies;
  final int pendingClaims;
  final int approvedClaims;
  final int rejectedClaims;
  final int totalPayments;
  final double totalRevenue;
  final int openTickets;
  final int pendingDocuments;

  const DashboardStats({
    required this.totalUsers,
    required this.activePolicies,
    required this.pendingClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.totalPayments,
    required this.totalRevenue,
    required this.openTickets,
    required this.pendingDocuments,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> m) => DashboardStats(
        totalUsers: (m['total_users'] as num?)?.toInt() ?? 0,
        activePolicies: (m['active_policies'] as num?)?.toInt() ?? 0,
        pendingClaims: (m['pending_claims'] as num?)?.toInt() ?? 0,
        approvedClaims: (m['approved_claims'] as num?)?.toInt() ?? 0,
        rejectedClaims: (m['rejected_claims'] as num?)?.toInt() ?? 0,
        totalPayments: (m['total_payments'] as num?)?.toInt() ?? 0,
        totalRevenue: (m['total_revenue'] as num?)?.toDouble() ?? 0.0,
        openTickets: (m['open_tickets'] as num?)?.toInt() ?? 0,
        pendingDocuments: (m['pending_documents'] as num?)?.toInt() ?? 0,
      );

  static DashboardStats empty() => const DashboardStats(
        totalUsers: 0,
        activePolicies: 0,
        pendingClaims: 0,
        approvedClaims: 0,
        rejectedClaims: 0,
        totalPayments: 0,
        totalRevenue: 0,
        openTickets: 0,
        pendingDocuments: 0,
      );
}
