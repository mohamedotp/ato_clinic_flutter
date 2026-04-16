import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:ato_clinic_flutter/screens/auth/login_screen.dart';
import 'package:ato_clinic_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/patients/patients_list_screen.dart';
import 'package:ato_clinic_flutter/screens/services/services_list_screen.dart';
import 'package:ato_clinic_flutter/screens/appointments/appointments_list_screen.dart';
import 'package:ato_clinic_flutter/screens/visits/visits_list_screen.dart';
import 'package:ato_clinic_flutter/screens/workspace/workspace_screen.dart';
import 'package:ato_clinic_flutter/screens/settings/settings_screen.dart';
import 'package:ato_clinic_flutter/screens/settings/users_list_screen.dart';
import 'package:ato_clinic_flutter/screens/clinic/ai_dashboard_screen.dart';
import 'package:ato_clinic_flutter/models/profile.dart';
import 'package:ato_clinic_flutter/screens/super_admin/super_admin_dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/clinic_management_screen.dart';

/// A listenable that triggers GoRouter to re-evaluate the redirect logic 
/// whenever the auth state changes, without recreating the entire GoRouter instance.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    _subscription = ref.listen(authProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use ChangeNotifier to notify GoRouter about auth changes
  final refreshListenable = RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      // Use ref.read here because GoRouter will re-call this 
      // when refreshListenable notifies it.
      final authState = ref.read(authProvider);
      final bool isAuthenticated = authState is AuthAuthenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        final profile = (authState as AuthAuthenticated).profile;
        return profile?.role == UserRole.super_admin ? '/super-admin' : '/';
      }

      final profile = (authState as AuthAuthenticated).profile;
      final role = profile?.role;
      final isSuperAdmin = role == UserRole.super_admin;
      final isReceptionist = role == UserRole.receptionist;

      if (state.matchedLocation.startsWith('/super-admin') && !isSuperAdmin) {
        return '/';
      }

      if (isReceptionist && 
         (state.matchedLocation.startsWith('/visits') || 
          state.matchedLocation.startsWith('/workspace') ||
          state.matchedLocation.startsWith('/settings') ||
          state.matchedLocation.startsWith('/ai'))) {
        return '/';
      }

      if (role == UserRole.doctor && state.matchedLocation.startsWith('/settings')) {
          if (state.matchedLocation.startsWith('/settings/users')) {
            return '/settings';
          }
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
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin/clinics',
        builder: (context, state) => const ClinicManagementScreen(),
      ),
    ],
  );
});
