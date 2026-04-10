import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/toast_service.dart';
import '../auth_state.dart';

class OtpModal extends ConsumerStatefulWidget {
  final String email;
  const OtpModal({super.key, required this.email});

  @override
  ConsumerState<OtpModal> createState() => _OtpModalState();
}

class _OtpModalState extends ConsumerState<OtpModal> {
  final _otpController = TextEditingController();
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      ToastService.showError(context, 'Please enter the 6-digit code');
      return;
    }

    try {
      await ref.read(authProvider.notifier).verifyOtp(widget.email, token);
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true on success
    } catch (e) {
      if (!mounted) return;
      ToastService.showError(context, '$e');
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    try {
      await ref.read(authProvider.notifier).resendOtp(widget.email);
      if (!mounted) return;
      ToastService.showSuccess(context, 'Verification code resent!');
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ToastService.showError(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.mail, color: theme.colorScheme.primary, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Verify Your Email',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 24, 
                letterSpacing: 12, 
                fontWeight: FontWeight.bold
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.white12),
                counterText: '',
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleVerify,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: authState.isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            
            const SizedBox(height: 24),
            
            TextButton(
              onPressed: _resendCooldown > 0 ? null : _handleResend,
              child: Text(
                _resendCooldown > 0 
                  ? 'Resend code in ${_resendCooldown}s' 
                  : 'Didn\'t receive the code? Resend',
                style: TextStyle(
                  color: _resendCooldown > 0 ? Colors.white24 : theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}
