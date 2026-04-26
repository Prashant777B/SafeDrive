import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class ClaimsScreen extends StatefulWidget {
  /// Pass policyId + policyNumber to pre-link the claim.
  /// Leave both empty to show all claims without linking to a policy.
  final String policyId;
  final String policyNumber;
  final String coverType;

  const ClaimsScreen({
    super.key,
    this.policyId = '',
    this.policyNumber = '',
    this.coverType = 'Comprehensive',
  });

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _claims = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      var query = Supabase.instance.client
          .from(SupabaseTables.claims)
          .select()
          .eq('user_id', user.id);
      if (widget.policyId.isNotEmpty) {
        query = query.eq('policy_id', widget.policyId);
      }
      final data = await query.order('created_at', ascending: false);
      setState(() => _claims = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = 'Could not load claims.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        title: Text(
          widget.policyNumber.isNotEmpty
              ? 'Claims — ${widget.policyNumber}'
              : 'My Claims',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Submit a Claim'),
            Tab(text: 'Track Claims'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.warning))
          : TabBarView(
              controller: _tabController,
              children: [
                _SubmitClaimTab(
                  policyId: widget.policyId,
                  policyNumber: widget.policyNumber,
                  onSubmitted: () {
                    _loadClaims();
                    _tabController.animateTo(1);
                  },
                ),
                _TrackClaimsTab(
                  claims: _claims,
                  error: _error,
                  onRefresh: _loadClaims,
                ),
              ],
            ),
    );
  }
}

// ── Submit Claim Tab ─────────────────────────────────────────

class _SubmitClaimTab extends StatefulWidget {
  final String policyId;
  final String policyNumber;
  final VoidCallback onSubmitted;

  const _SubmitClaimTab({
    required this.policyId,
    required this.policyNumber,
    required this.onSubmitted,
  });

  @override
  State<_SubmitClaimTab> createState() => _SubmitClaimTabState();
}

class _SubmitClaimTabState extends State<_SubmitClaimTab> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  String? _selectedClaimType;
  DateTime? _incidentDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;
    if (_incidentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the incident date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final ts = DateTime.now()
          .millisecondsSinceEpoch
          .toRadixString(36)
          .toUpperCase()
          .padLeft(7, '0')
          .substring(0, 7);
      final claimNumber = 'CLM-${DateTime.now().year}-$ts';

      final payload = <String, dynamic>{
        'user_id': user.id,
        'claim_number': claimNumber,
        'claim_type': _selectedClaimType,
        'incident_date': _incidentDate!.toIso8601String().split('T')[0],
        'incident_location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': ClaimStatus.submitted,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (widget.policyId.isNotEmpty) {
        payload['policy_id'] = widget.policyId;
      }

      final costText = _estimatedCostController.text.trim();
      if (costText.isNotEmpty) {
        payload['estimated_cost'] = double.tryParse(costText);
      }

      await Supabase.instance.client
          .from(SupabaseTables.claims)
          .insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Claim $claimNumber submitted!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit claim: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.policyNumber.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.policy_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Policy: ${widget.policyNumber}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Claim type
            DropdownButtonFormField<String>(
              initialValue: _selectedClaimType,
              decoration: _dec('Type of Claim', Icons.category_outlined),
              items: ClaimTypes.all
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(ClaimTypes.icons[t],
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(t),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedClaimType = v),
              validator: (v) => v == null ? 'Please select a claim type' : null,
            ),
            const SizedBox(height: 16),

            // Incident date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _incidentDate == null
                          ? 'Select Incident Date *'
                          : 'Incident: ${_fmt(_incidentDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _incidentDate == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: _dec(
                  'Incident Location (optional)', Icons.location_on_outlined),
              validator: (v) => null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration:
                  _dec('Describe what happened *', Icons.description_outlined),
              validator: (v) => v == null || v.trim().length < 20
                  ? 'Please provide at least 20 characters'
                  : null,
            ),
            const SizedBox(height: 16),

            // Estimated cost
            TextFormField(
              controller: _estimatedCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  _dec('Estimated Cost £ (optional)', Icons.attach_money),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  if (double.tryParse(v) == null) {
                    return 'Enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Once submitted, a claims handler will review your case within 2–5 business days. You will be notified by email of any updates.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Submit Claim',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Track Claims Tab ─────────────────────────────────────────

class _TrackClaimsTab extends StatelessWidget {
  final List<Map<String, dynamic>> claims;
  final String? error;
  final VoidCallback onRefresh;

  const _TrackClaimsTab({
    required this.claims,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (claims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.report_problem_outlined,
                    size: 48, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              const Text('No Claims Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'You haven\'t submitted any claims yet.\nIf you need to make a claim, use the Submit tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.warning,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: claims.length,
        itemBuilder: (context, i) => _ClaimCard(claim: claims[i]),
      ),
    );
  }
}

// ── Claim card ───────────────────────────────────────────────

class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final claimNumber = claim['claim_number'] as String? ?? '';
    final claimType = claim['claim_type'] as String? ?? '';
    final status = claim['status'] as String? ?? ClaimStatus.submitted;
    final incidentDate = claim['incident_date'] as String? ?? '';
    final description = claim['description'] as String? ?? '';
    final estimatedCost = (claim['estimated_cost'] as num?)?.toDouble();

    final statusColor = ClaimStatus.colorFor(status);
    final statusLabel = ClaimStatus.label(status);
    final typeIcon = ClaimTypes.icons[claimType] ?? Icons.help_outline;

    String formattedDate = '';
    if (incidentDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(incidentDate);
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(claimType,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: statusColor)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(claimNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          if (formattedDate.isNotEmpty)
                            Text('Incident: $formattedDate',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (estimatedCost != null)
                      Text(
                        '£${estimatedCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.warning),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description.length > 120
                        ? '${description.substring(0, 120)}…'
                        : description,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.4),
                  ),
                ],

                // Progress stepper
                const SizedBox(height: 14),
                _ClaimProgress(currentStatus: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Claim progress stepper ───────────────────────────────────

class _ClaimProgress extends StatelessWidget {
  final String currentStatus;
  const _ClaimProgress({required this.currentStatus});

  static const _steps = [
    ClaimStatus.submitted,
    ClaimStatus.underReview,
    ClaimStatus.approved,
    ClaimStatus.settled,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(currentStatus);
    final isRejected = currentStatus == ClaimStatus.rejected;

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final completed = !isRejected && stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: completed ? AppColors.success : Colors.grey.shade300,
            ),
          );
        }

        final stepIdx = i ~/ 2;
        final isCompleted = !isRejected && stepIdx <= currentIdx;
        final stepColor = isRejected && stepIdx == 0
            ? AppColors.error
            : isCompleted
                ? AppColors.success
                : Colors.grey.shade300;

        return Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected && stepIdx == 0
                    ? Icons.close
                    : isCompleted
                        ? Icons.check
                        : null,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              ClaimStatus.label(_steps[stepIdx]).split(' ').first,
              style: TextStyle(
                  fontSize: 8,
                  color:
                      isCompleted ? AppColors.success : Colors.grey.shade500),
            ),
          ],
        );
      }),
    );
  }
}
