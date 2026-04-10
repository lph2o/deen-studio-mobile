import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deen_studio_01/features/auth/presentation/auth_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    
    // Setup initial auth listener mock to avoid errors
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => Stream.fromIterable([]));
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockAuth.currentUser).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier OTP Tests', () {
    test('verifyOtp updates state correctly on success', () async {
      final notifier = container.read(authProvider.notifier);
      
      when(() => mockAuth.verifyOTP(
        email: 'test@example.com',
        token: '123456',
        type: OtpType.signup,
      )).thenAnswer((_) async => AuthResponse());

      await notifier.verifyOtp('test@example.com', '123456');

      verify(() => mockAuth.verifyOTP(
        email: 'test@example.com',
        token: '123456',
        type: OtpType.signup,
      )).called(1);
      
      expect(container.read(authProvider).isLoading, false);
    });

    test('resendOtp calls supabase resend', () async {
      final notifier = container.read(authProvider.notifier);
      
      when(() => mockAuth.resend(
        type: OtpType.signup,
        email: 'test@example.com',
      )).thenAnswer((_) async => ResendResponse());

      await notifier.resendOtp('test@example.com');

      verify(() => mockAuth.resend(
        type: OtpType.signup,
        email: 'test@example.com',
      )).called(1);
      
      expect(container.read(authProvider).isLoading, false);
    });

    test('verifyOtp propagates errors', () async {
      final notifier = container.read(authProvider.notifier);
      
      when(() => mockAuth.verifyOTP(
        email: 'test@example.com',
        token: '000000',
        type: OtpType.signup,
      )).thenThrow(AuthException('Invalid code'));

      expect(
        () => notifier.verifyOtp('test@example.com', '000000'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Full flow: signUp sets tempEmail and verifyOtp uses it', () async {
      final notifier = container.read(authProvider.notifier);

      // 1. SignUp
      when(() => mockAuth.signUp(
        email: 'newuser@example.com',
        password: 'password123',
        data: any(named: 'data'),
      )).thenAnswer((_) async => AuthResponse(user: User(
        id: 'new-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'newuser@example.com',
      )));

      await notifier.signUp('newuser@example.com', 'password123');
      
      expect(container.read(authProvider).tempEmail, 'newuser@example.com');

      // 2. Verify OTP
      when(() => mockAuth.verifyOTP(
        email: 'newuser@example.com',
        token: '123456',
        type: OtpType.signup,
      )).thenAnswer((_) async => AuthResponse());

      await notifier.verifyOtp('newuser@example.com', '123456');

      verify(() => mockAuth.verifyOTP(
        email: 'newuser@example.com',
        token: '123456',
        type: OtpType.signup,
      )).called(1);
    });
  group('Login Screen Integration Tests (Conceptual)', () {
    // Note: Screen-level widget tests would use pumpWidget 
    // and finder to check for OtpModal presence.
  });
});
}
