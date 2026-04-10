import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/toast_service.dart';
import 'auth_state.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ToastService.showError(context, 'Please fill in all fields');
      return;
    }

    if (password != confirm) {
      ToastService.showError(context, 'Passwords do not match');
      return;
    }

    try {
      debugPrint('SignUp: Initiating signUp for $email');
      await ref.read(authProvider.notifier).signUp(
        email, 
        password, 
        data: {'full_name': fullName},
      );
      
      debugPrint('SignUp Success: Auth check...');
      final currentUser = ref.read(authProvider).user;
      debugPrint('Current User after SignUp: ${currentUser?.id}, confirmed: ${currentUser?.emailConfirmedAt}');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) {
        debugPrint('SignUp: Context no longer mounted, skipping navigation');
        return;
      }
      
      ToastService.showSuccess(context, 'Account created! Verification code sent.');
      debugPrint('SignUp: Navigating to verify-otp for $email');
      final encodedEmail = Uri.encodeComponent(email);
      context.go('/verify-otp?email=$encodedEmail');
    } catch (e) {
      debugPrint('SignUp Error: $e');
      if (!mounted) return;
      ToastService.showError(context, '$e');
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
            left: -100,
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
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      ),
                    ),
                    const _Logo(),
                    const SizedBox(height: 32),
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().moveY(begin: 10, end: 0),
                    const SizedBox(height: 8),
                    const Text(
                      'Start your journey with Deen Studio',
                      style: TextStyle(color: Colors.white60),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: 40),
                    
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
                          _TextField(
                            label: 'Full Name', 
                            hint: 'Jhon Doe',
                            controller: _fullNameController,
                          ),
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
                          _TextField(
                            label: 'Confirm Password', 
                            hint: '••••••••', 
                            isPassword: true,
                            controller: _confirmPasswordController,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleSignUp,
                            child: authState.isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 32),
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
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: SvgPicture.asset(
        'assets/svg/Logo_Deen_sudio_sans_text.svg',
        height: 80,
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
