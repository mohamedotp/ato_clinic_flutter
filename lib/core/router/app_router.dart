import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';

import '../../screens/patients/patients_list_screen.dart';
import '../../screens/services/services_list_screen.dart';
import '../../screens/appointments/appointments_list_screen.dart';
import '../../screens/visits/visits_list_screen.dart';
import '../../screens/workspace/workspace_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/users_list_screen.dart';
import '../../screens/clinic/ai_dashboard_screen.dart'; // Future-proofing

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
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesListScreen(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsListScreen(),
      ),
      GoRoute(
        path: '/visits',
        builder: (context, state) => const VisitsListScreen(),
      ),
      GoRoute(
        path: '/workspace/:patientId',
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return WorkspaceScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UsersListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiDashboardScreen(),
      ),
    ],
  );
});
