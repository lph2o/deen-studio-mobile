import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/presentation/onboarding_features_screen.dart';
import 'features/onboarding/presentation/onboarding_get_started_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/otp_verification_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/projects/presentation/select_surah_screen.dart';
import 'features/projects/presentation/select_verses_screen.dart';
import 'features/projects/presentation/select_reciter_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/editor/presentation/editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: DeenStudioApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      if (authState.isLoading) return null;

      final isLoggedIn = authState.user != null;
      final isVerified = authState.user?.emailConfirmedAt != null;
      final matchedLocation = state.matchedLocation;
      
      debugPrint('Router Redirect: location=${state.uri}, matched=$matchedLocation, loggedIn=$isLoggedIn, verified=$isVerified');

      final isPublicRoute = matchedLocation == '/login' || 
                            matchedLocation == '/signup' || 
                            matchedLocation == '/forgot-password' || 
                            matchedLocation == '/verify-otp' ||
                            matchedLocation == '/onboarding-features' ||
                            matchedLocation == '/onboarding-get-started' ||
                            matchedLocation == '/';

      if (!isLoggedIn && !isPublicRoute) {
        debugPrint('Redirecting to /login');
        return '/login';
      }

      // If logged in but unverified, they MUST go to verify-otp
      // Exception: allow them to stay on /login to show the OtpModal
      if (isLoggedIn && !isVerified && 
          matchedLocation != '/verify-otp' && 
          matchedLocation != '/login') {
        final email = authState.user?.email ?? authState.tempEmail ?? '';
        debugPrint('Redirecting unverified user to /verify-otp with email: $email');
        return '/verify-otp?email=$email';
      }

      // If verified and on a public route, go to dashboard
      if (isLoggedIn && isVerified && isPublicRoute && matchedLocation != '/dashboard') {
        debugPrint('Redirecting verified user to /dashboard');
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding-features',
        builder: (context, state) => const OnboardingFeaturesScreen(),
      ),
      GoRoute(
        path: '/select-surah',
        builder: (context, state) => const SelectSurahScreen(),
      ),
      GoRoute(
        path: '/select-verses',
        builder: (context, state) => const SelectVersesScreen(),
      ),
      GoRoute(
        path: '/select-reciter',
        builder: (context, state) => const SelectReciterScreen(),
      ),
      GoRoute(
        path: '/onboarding-get-started',
        builder: (context, state) => const OnboardingGetStartedScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/editor/:projectId',
        builder: (context, state) => EditorScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
    ],
  );
});

class DeenStudioApp extends ConsumerWidget {
  const DeenStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Deen Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
