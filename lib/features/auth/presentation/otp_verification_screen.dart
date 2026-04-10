import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/toast_service.dart';
import 'auth_state.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      ToastService.showError(context, 'Please enter the code');
      return;
    }

    try {
      final email = widget.email.isNotEmpty ? widget.email : ref.read(authProvider).tempEmail;
      if (email == null || email.isEmpty) {
        ToastService.showError(context, 'Email not found. Please try logging in again.');
        return;
      }
      await ref.read(authProvider.notifier).verifyOtp(email, token);
      if (!mounted) return;
      ToastService.showSuccess(context, 'Account verified successfully!');
      context.go('/dashboard');
    } catch (e) {
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
                    const _Logo(),
                    const SizedBox(height: 32),
                    Text(
                      'Verify Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().moveY(begin: 10, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      "We've sent a code to ${widget.email.isNotEmpty ? widget.email : authState.tempEmail ?? 'your email'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
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
                          _TextField(
                            label: 'Verification Code', 
                            hint: '123456',
                            controller: _otpController,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleVerify,
                            child: authState.isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('VERIFY ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                    
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Did not receive code? Change email', style: TextStyle(color: Colors.white38)),
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
  final TextEditingController controller;

  const _TextField({
    required this.label, 
    required this.hint, 
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
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12),
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
