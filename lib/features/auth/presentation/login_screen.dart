import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/toast_service.dart';
import 'auth_state.dart';
import 'widgets/otp_modal.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ToastService.showError(context, 'Please fill in all fields');
      return;
    }

    try {
      await ref.read(authProvider.notifier).signIn(email, password);
      
      if (!mounted) return;
      
      // If sign in succeeds without throwing an exception, check verification status!
      final user = ref.read(authProvider).user;
      if (user != null && user.emailConfirmedAt == null) {
        // User logged in successfully but is NOT verified. Force the modal.
        debugPrint('Login success but user is unverified. Showing OTP modal.');
        _showOtpModal(email);
        return;
      }

      // Successful and verified!
      ToastService.showSuccess(context, 'Welcome back!');
      context.go('/dashboard');
      
    } on AuthException catch (e) {
      if (!mounted) return;
      debugPrint('AuthException caught: message=${e.message}, code=${e.code}');
      if (e.message.toLowerCase().contains('email not confirmed') || 
          e.code == 'email_not_confirmed') {
        _showOtpModal(email);
      } else {
        _showDiagnosticDialog(email, 'AuthException:\nMessage: ${e.message}\nCode: ${e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('General Exception caught: $e');
      _showDiagnosticDialog(email, 'Exception:\n$e');
    }
  }

  void _showDiagnosticDialog(String email, String errorDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Diagnostic', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          'La connexion a échoué. Voici l\'erreur retournée par Supabase :\n\n$errorDetails\n\nSi vous pensez que votre compte n\'est pas encore vérifié (ou que Supabase masque l\'erreur), vous pouvez forcer la vérification locale.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showOtpModal(email);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('Forcer code OTP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOtpModal(String email) async {
    // Show info toast before the modal as requested
    ToastService.showInfo(
      context, 
      'Please verify your email to continue. We\'ve sent a code to $email',
    );
    
    // Wait a brief moment for the toast to be seen/start appearing
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Blocking modal
      builder: (context) => OtpModal(email: email),
    );

    if (verified == true && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(duration: 1200.ms),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _Logo(color: theme.colorScheme.primaryContainer),
                    const SizedBox(height: 48),
                    Text(
                      'السَّلَامُ عَلَيْكُمْ',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ).animate().fadeIn().moveY(begin: 10, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'As-salamu alaykum',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back to Deen Studio',
                      style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.normal),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 48),
                    
                    // Form
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 48,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                            icon: const Icon(LucideIcons.chrome, size: 18),
                            label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white12)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(fontSize: 10, color: Colors.white24, letterSpacing: 2)),
                              ),
                              Expanded(child: Divider(color: Colors.white12)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _TextField(
                            label: 'Email Address', 
                            hint: 'name@example.com',
                            controller: _emailController,
                          ),
                          const SizedBox(height: 20),
                          _TextField(
                            label: 'Password', 
                            hint: '••••••••', 
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot Password?', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleSubmit,
                            child: authState.isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Colors.white60)),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: Text('Create journey', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final Color? color;
  const _Logo({this.color});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: SvgPicture.asset(
        'assets/svg/Logo_Deen_sudio_sans_text.svg',
        height: 100,
        // No filter needed if file has correct colors, or use theme.colorScheme.primary
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextEditingController controller;

  const _TextField({
    required this.label, 
    required this.hint, 
    this.isPassword = false,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
