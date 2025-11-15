import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../screens/add_log_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/subusers_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = authState.token != null;
      final location = state.uri.path;
      const publicRoutes = {
        '/login',
        '/signup',
        '/verify-email',
        '/forgot-password',
        '/reset-password',
      };
      final isAuthRoute = publicRoutes.contains(location);
      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, _) => const SignupScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => EmailVerificationScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(path: '/home', builder: (context, _) => const HomeScreen()),
      GoRoute(
        path: '/subusers',
        builder: (context, _) => const SubUsersScreen(),
      ),
      GoRoute(path: '/add-log', builder: (context, _) => const AddLogScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => HistoryScreen(
          initialSubUserId: state.uri.queryParameters['subUserId'],
        ),
      ),
      GoRoute(path: '/profile', builder: (context, _) => const ProfileScreen()),
    ],
  );
});
