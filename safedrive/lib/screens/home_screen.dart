import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'personal_details_screen.dart';
import 'my_policies_screen.dart';
import 'claims_screen.dart';

// ROOT SHELL — bottom navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _MyQuotesTab(),
          MyPoliciesScreen(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        indicatorColor: const Color(0xFF1A73E8).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1A73E8)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1A73E8)),
            label: 'Quotes',
          ),
          NavigationDestination(
            icon: Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy, color: Color(0xFF1A73E8)),
            label: 'Policies',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1A73E8)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// TAB 1 — DASHBOARD

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = user?.userMetadata?['first_name'] as String? ??
        user?.email?.split('@')[0] ??
        'Driver';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/app_logo.png', height: 28, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text('SafeDrive',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA726),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -50,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName 👋',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Find the right cover\nfor your car today',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PersonalDetailsScreen(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1A73E8),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.calculate_outlined,
                                    size: 19),
                                label: const Text(
                                  'Get a Free Quote',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Quick Stats Bar ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const _StatChip(
                    icon: Icons.timer_outlined,
                    label: '3 min',
                    sub: 'Average quote time',
                    color: Color(0xFF1A73E8),
                  ),
                  _divider(),
                  const _StatChip(
                    icon: Icons.people_outline,
                    label: '50k+',
                    sub: 'UK drivers quoted',
                    color: Color(0xFF34A853),
                  ),
                  _divider(),
                  const _StatChip(
                    icon: Icons.star_outline,
                    label: '4.8★',
                    sub: 'Average rating',
                    color: Color(0xFFFFA726),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Actions ────────────────────────────
                  const _SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Manage your insurance in one tap',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.policy_outlined,
                          title: 'My Policies',
                          subtitle: 'View & manage active cover',
                          color: AppColors.primary,
                          onTap: () {
                            final shell = context
                                .findAncestorStateOfType<_HomeScreenState>();
                            shell?.switchTab(2);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Make a Claim',
                          subtitle: 'Submit & track your claims',
                          color: AppColors.warning,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ClaimsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover types ──────────────────────────────
                  const _SectionHeader(
                    title: 'Choose Your Cover',
                    subtitle: 'Three levels of protection for UK drivers',
                  ),
                  const SizedBox(height: 14),
                  const _CoverCard(
                    icon: Icons.gavel_outlined,
                    title: 'Third Party Only',
                    shortDesc:
                        'The legal minimum. Covers damage and injury you cause to others — not your own vehicle.',
                    price: 'From £180/yr*',
                    tag: 'Basic',
                    color: Color(0xFFE65100),
                    features: [
                      'Third party vehicle damage',
                      'Third party personal injury',
                      'Legal minimum requirement',
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CoverCard(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Third Party, Fire & Theft',
                    shortDesc:
                        'Everything in Third Party plus cover if your car is stolen or damaged by fire.',
                    price: 'From £220/yr*',
                    tag: 'Mid-Range',
                    color: Color(0xFFF9A825),
                    features: [
                      'All Third Party benefits',
                      'Fire damage protection',
                      'Theft & attempted theft',
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CoverCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Comprehensive',
                    shortDesc:
                        'Our most complete protection. Covers accidental damage to your own car — regardless of fault.',
                    price: 'From £350/yr*',
                    tag: 'Most Popular',
                    color: Color(0xFF1A73E8),
                    isPopular: true,
                    features: [
                      'Accidental damage cover',
                      'Windscreen replacement',
                      'Personal accident cover',
                      'Medical expense cover',
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── How it works ─────────────────────────────
                  const _SectionHeader(
                    title: 'How It Works',
                    subtitle: 'Get your quote in 3 simple steps',
                  ),
                  const SizedBox(height: 14),
                  const _StepCard(
                    step: '1',
                    title: 'Your Details',
                    subtitle:
                        'Tell us your name, date of birth, postcode, and driving licence type.',
                    icon: Icons.person_outline,
                    color: Color(0xFF1A73E8),
                  ),
                  const SizedBox(height: 10),
                  const _StepCard(
                    step: '2',
                    title: 'Your Car',
                    subtitle:
                        'Enter your registration, choose your cover type, and confirm your mileage.',
                    icon: Icons.directions_car_outlined,
                    color: Color(0xFF34A853),
                  ),
                  const SizedBox(height: 10),
                  const _StepCard(
                    step: '3',
                    title: 'Instant Quote',
                    subtitle:
                        'Receive a personalised UK insurance estimate, save it and compare options.',
                    icon: Icons.receipt_long_outlined,
                    color: Color(0xFF7B1FA2),
                  ),
                  const SizedBox(height: 28),

                  // ── Why SafeDrive ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D2E6B), Color(0xFF1A73E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/app_logo.png', height: 22, fit: BoxFit.contain),
                            const SizedBox(width: 8),
                            const Text(
                              'Why Choose SafeDrive?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _WhyItem(
                          icon: Icons.speed_outlined,
                          text: 'Instant quote in under 3 minutes',
                        ),
                        const _WhyItem(
                          icon: Icons.lock_outline,
                          text: 'Bank-grade encrypted data protection',
                        ),
                        const _WhyItem(
                          icon: Icons.thumb_up_alt_outlined,
                          text: 'No hidden fees — fully transparent pricing',
                        ),
                        const _WhyItem(
                          icon: Icons.support_agent_outlined,
                          text: 'UK-based customer support, 8am–8pm',
                        ),
                        const _WhyItem(
                          icon: Icons.savings_outlined,
                          text: 'No-claims discount up to 55% off',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Car types guide ──────────────────────────
                  const _SectionHeader(
                    title: 'Insurance by Car Type',
                    subtitle: 'Typical annual premiums for UK drivers (2024)',
                  ),
                  const SizedBox(height: 14),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CarTypeChip(
                            'City Car', '£280–£600', Icons.directions_car),
                        _CarTypeChip('Hatchback', '£380–£850',
                            Icons.directions_car_filled_outlined),
                        _CarTypeChip('Estate', '£450–£950',
                            Icons.airport_shuttle_outlined),
                        _CarTypeChip(
                            'SUV', '£550–£1,200', Icons.rv_hookup_outlined),
                        _CarTypeChip('Sports', '£900–£3,000', Icons.speed),
                        _CarTypeChip(
                            'Luxury', '£600–£1,800', Icons.star_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CTA repeat
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            size: 36, color: Color(0xFF1A73E8)),
                        const SizedBox(height: 10),
                        const Text(
                          'Ready for your quote?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Takes less than 3 minutes. No commitment required.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PersonalDetailsScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Start My Free Quote',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Disclaimer
                  Text(
                    '*Prices shown are indicative estimates for UK drivers. Actual premiums depend on individual risk factors and a full underwriting assessment. SafeDrive is for illustrative purposes only.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.grey.shade200,
      );
}

// TAB 2 — MY QUOTES

class _MyQuotesTab extends StatefulWidget {
  const _MyQuotesTab();

  @override
  State<_MyQuotesTab> createState() => _MyQuotesTabState();
}

class _MyQuotesTabState extends State<_MyQuotesTab> {
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from('quotes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() => _quotes = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = 'Could not load quotes. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('My Quotes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadQuotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _quotes.isEmpty
                  ? _EmptyQuotes(
                      onGetQuote: () {
                        final shell =
                            context.findAncestorStateOfType<_HomeScreenState>();
                        shell?.switchTab(0);
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQuotes,
                      color: const Color(0xFF1A73E8),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotes.length,
                        itemBuilder: (context, i) =>
                            _QuoteCard(quote: _quotes[i]),
                      ),
                    ),
    );
  }
}

// TAB 3 — PROFILE

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName =
        (user?.userMetadata?['first_name'] as String? ?? '').trim();
    final lastName = (user?.userMetadata?['last_name'] as String? ?? '').trim();
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : user?.email?.split('@')[0] ?? 'SafeDrive User';
    final initials = firstName.isNotEmpty
        ? (firstName[0] + (lastName.isNotEmpty ? lastName[0] : ''))
            .toUpperCase()
        : (user?.email?[0].toUpperCase() ?? 'S');
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0D2E6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34A853),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileBadge(Icons.verified_user, 'Verified Member'),
                      SizedBox(width: 10),
                      _ProfileBadge(Icons.shield, 'SafeDrive'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuSection('Account Settings', [
                    _MenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal Details',
                      subtitle: 'View or update your information',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PersonalDetailsScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'We\'ll send a reset link to your email',
                      onTap: () async {
                        if (email.isEmpty) return;
                        try {
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(email);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent!'),
                                backgroundColor: Color(0xFF34A853),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                    ),
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Insurance Quotes',
                      subtitle: 'View all saved quotes',
                      onTap: () {
                        final shell =
                            context.findAncestorStateOfType<_HomeScreenState>();
                        shell?.switchTab(1);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.policy_outlined,
                      title: 'My Policies',
                      subtitle: 'View active & past policies',
                      onTap: () {
                        final shell =
                            context.findAncestorStateOfType<_HomeScreenState>();
                        shell?.switchTab(2);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.report_problem_outlined,
                      title: 'Submit a Claim',
                      subtitle: 'Report an incident or track claims',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ClaimsScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _menuSection('Support & Legal', [
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & FAQs',
                      subtitle: 'Answers to common questions',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Our terms of service',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      title: 'About SafeDrive',
                      subtitle: 'Version 1.0.0',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'SafeDrive v1.0.0  •  For illustrative purposes only',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < items.length - 1)
                          Divider(
                              height: 1,
                              indent: 56,
                              color: Colors.grey.shade100),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 3),
        Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String shortDesc;
  final String price;
  final String tag;
  final Color color;
  final bool isPopular;
  final List<String> features;

  const _CoverCard({
    required this.icon,
    required this.title,
    required this.shortDesc,
    required this.price,
    required this.tag,
    required this.color,
    this.isPopular = false,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isPopular
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? color.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isPopular ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPopular ? color : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(shortDesc,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 15, color: color),
                    const SizedBox(width: 7),
                    Text(f, style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (isPopular)
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text('Best Value',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.35)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }
}

class _WhyItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WhyItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarTypeChip extends StatelessWidget {
  final String type;
  final String price;
  final IconData icon;
  const _CarTypeChip(this.type, this.price, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1A73E8), size: 26),
          const SizedBox(height: 6),
          Text(type,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(price,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── My Quotes helpers ────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final annual = (quote['annual_quote'] as num?)?.toDouble() ?? 0.0;
    final monthly = (quote['monthly_quote'] as num?)?.toDouble() ?? annual / 12;
    final make = quote['car_make'] as String? ?? 'Unknown';
    final model = quote['car_model'] as String? ?? '';
    final year = quote['car_year'] as String? ?? '';
    final reg = quote['car_registration'] as String? ?? '';
    final coverType = quote['cover_type'] as String? ?? 'Comprehensive';
    final createdAt = quote['created_at'] as String? ?? '';

    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: Color(0xFF1A73E8), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year $make $model',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reg.toUpperCase(),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '£${annual.toStringAsFixed(0)}/yr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  Text(
                    '£${monthly.toStringAsFixed(0)}/mo',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QTag(Icons.verified_user_outlined, coverType,
                  const Color(0xFF1A73E8)),
              const SizedBox(width: 8),
              if (formattedDate.isNotEmpty)
                _QTag(Icons.calendar_today_outlined, formattedDate,
                    Colors.grey.shade600),
            ],
          ),
        ],
      ),
    );
  }
}

class _QTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _QTag(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyQuotes extends StatelessWidget {
  final VoidCallback onGetQuote;
  const _EmptyQuotes({required this.onGetQuote});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 52, color: Color(0xFF1A73E8)),
            ),
            const SizedBox(height: 22),
            const Text('No Quotes Yet',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'You haven\'t saved any quotes yet.\nGet started by requesting your first quote — it only takes 3 minutes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 14, height: 1.55),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onGetQuote,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Get My First Quote',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile helpers ──────────────────────────────────────────

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing:
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
    );
  }
}
