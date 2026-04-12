import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';

import '../../screens/patients/patients_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final bool isAuthenticated = authState is AuthAuthenticated;
      final bool isUnauthenticated = authState is AuthUnauthenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (isUnauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isAuthenticated) {
        return isLoggingIn ? '/' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/patients',
        builder: (context, state) => const PatientsListScreen(),
      ),
    ],
  );
});
