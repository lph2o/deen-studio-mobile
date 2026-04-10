import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? tempEmail;

  AuthState({this.user, this.isLoading = false, this.tempEmail});

  AuthState copyWith({User? user, bool? isLoading, String? tempEmail}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      tempEmail: tempEmail ?? this.tempEmail,
    );
  }
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class AuthNotifier extends Notifier<AuthState> {
  SupabaseClient get _supabase => ref.read(supabaseProvider);

  @override
  AuthState build() {
    // Listen to auth state changes for future updates
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = _supabase.auth.currentUser;
      if (user != state.user) {
         state = state.copyWith(user: user, isLoading: false);
      }
    });

    // Synchronously return the initial state
    return AuthState(user: _supabase.auth.currentUser, isLoading: false);
  }

  Future<void> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    state = state.copyWith(isLoading: true, tempEmail: email);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      debugPrint('AuthNotifier: signUp response user=${response.user?.id}');
      state = state.copyWith(user: response.user, isLoading: false);
    } catch (e) {
      debugPrint('AuthNotifier: signUp error=$e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, tempEmail: email);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(user: response.user);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.signOut();
    } finally {
      state = AuthState(user: null, isLoading: false, tempEmail: state.tempEmail);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      if (response.user != null) {
        state = state.copyWith(user: response.user);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resendOtp(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
