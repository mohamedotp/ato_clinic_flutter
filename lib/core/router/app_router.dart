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
import 'package:ato_clinic_flutter/screens/handoff/handoff_screen.dart';
import 'package:ato_clinic_flutter/models/profile.dart';
// Super Admin screens
import 'package:ato_clinic_flutter/screens/super_admin/super_admin_dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/clinic_management_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/global_settings_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/subscriptions_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/reports_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/store_management_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/service_activation_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/support_tickets_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/system_admins_screen.dart';
import 'package:ato_clinic_flutter/screens/super_admin/clinic_selector_screen.dart';

/// A listenable that triggers GoRouter to re-evaluate the redirect logic
/// whenever the auth state changes, without recreating the entire GoRouter instance.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    _subscription = ref.listen(authProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final bool isAuthenticated = authState is AuthAuthenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        final profile = (authState).profile;
        return profile?.role == UserRole.super_admin ? '/super-admin' : '/';
      }

      final profile = (authState).profile;
      final role = profile?.role;
      final isSuperAdmin = role == UserRole.super_admin;
      final isReceptionist = role == UserRole.receptionist;

      // Guard super-admin routes
      if (state.matchedLocation.startsWith('/super-admin') && !isSuperAdmin) {
        return '/';
      }

      // Guard receptionist from sensitive pages
      if (isReceptionist &&
          (state.matchedLocation.startsWith('/visits') ||
              state.matchedLocation.startsWith('/workspace') ||
              state.matchedLocation.startsWith('/settings/users') ||
              state.matchedLocation.startsWith('/ai'))) {
        return '/';
      }

      // Doctor can't access user management
      if (role == UserRole.doctor && state.matchedLocation.startsWith('/settings')) {
        if (state.matchedLocation.startsWith('/settings/users')) {
          return '/settings';
        }
      }

      return null;
    },
    routes: [
      // ── Clinic routes ──────────────────────────────────────
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
        path: '/handoff',
        builder: (context, state) => const HandoffScreen(),
      ),

      // ── Super Admin routes ─────────────────────────────────
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin/clinics',
        builder: (context, state) => const ClinicManagementScreen(),
      ),
      GoRoute(
        path: '/super-admin/subscriptions',
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/super-admin/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/super-admin/stores',
        builder: (context, state) => const StoreManagementScreen(),
      ),
      GoRoute(
        path: '/super-admin/services',
        builder: (context, state) => const ServiceActivationScreen(),
      ),
      GoRoute(
        path: '/super-admin/support',
        builder: (context, state) => const SupportTicketsScreen(),
      ),
      GoRoute(
        path: '/super-admin/admins',
        builder: (context, state) => const SystemAdminsScreen(),
      ),
      GoRoute(
        path: '/super-admin/settings',
        builder: (context, state) => const GlobalSettingsScreen(),
      ),
      GoRoute(
        path: '/super-admin/select-clinic',
        builder: (context, state) => const ClinicSelectorScreen(),
      ),
    ],
  );
});
