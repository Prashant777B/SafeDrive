import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reverse().then((_) {
      setState(() => _isLogin = !_isLogin);
      _animController.forward();
    });
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    if (!_isLogin) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty) {
        _showSnack('Please enter your first and last name');
        return;
      }
      if (password != _confirmPasswordController.text.trim()) {
        _showSnack('Passwords do not match');
        return;
      }
      if (password.length < 6) {
        _showSnack('Password must be at least 6 characters');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await supabase.auth
            .signInWithPassword(email: email, password: password);
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
          },
        );
        _showSnack('Account created! Please check your email to verify.');
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we\'ll send you a reset link.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Color(0xFF1A73E8)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              try {
                await supabase.auth.resetPasswordForEmail(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Password reset email sent! Check your inbox.'),
                      backgroundColor: Color(0xFF34A853),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } on AuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message),
                        behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blue gradient background top half
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Light grey bottom half
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.58,
              color: const Color(0xFFF5F7FA),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero top section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/app_logo.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'SafeDrive',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Car Insurance Made Simple',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),

                  // Main card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sign In / Sign Up tab switcher
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _tabButton('Sign In', _isLogin),
                                _tabButton('Sign Up', !_isLogin),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign Up only: first + last name
                          if (!_isLogin) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(_firstNameController,
                                      'First Name', Icons.person_outline),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(_lastNameController,
                                      'Last Name', Icons.badge_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email
                          _buildField(_emailController, 'Email Address',
                              Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),

                          // Password
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),

                          // Sign In: forgot password link
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPassword,
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6)),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                      color: Color(0xFF1A73E8), fontSize: 13),
                                ),
                              ),
                            ),

                          // Sign Up: confirm password + hint
                          if (!_isLogin) ...[
                            const SizedBox(height: 14),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'At least 6 characters',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A73E8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            _isLogin
                                                ? Icons.login
                                                : Icons.person_add_outlined,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Text(
                            _isLogin ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFF1A73E8),
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
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if ((label == 'Sign In') != _isLogin) _toggleMode();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A73E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration(
        label,
        Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5)),
    );
  }
}
