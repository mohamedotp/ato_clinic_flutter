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
        final profile = (authState as AuthAuthenticated).profile;
        final role = profile?.role;
        final isSuperAdmin = role == UserRole.super_admin;
        final isReceptionist = role == UserRole.receptionist;
        
        if (isLoggingIn) {
          return isSuperAdmin ? '/super-admin' : '/';
        }
        
        // Prevent ordinary users from entering super admin paths
        if (state.matchedLocation.startsWith('/super-admin') && !isSuperAdmin) {
          return '/';
        }

        // RBAC: Block Receptionist from restricted medical/admin zones
        if (isReceptionist && 
           (state.matchedLocation.startsWith('/visits') || 
            state.matchedLocation.startsWith('/workspace') ||
            state.matchedLocation.startsWith('/settings') ||
            state.matchedLocation.startsWith('/ai'))) {
          return '/';
        }

        // RBAC: Block Doctors from managing Users/Settings
        if (role == UserRole.doctor && state.matchedLocation.startsWith('/settings')) {
            // Depending on the logic, maybe doctors can see basic settings but not users? 
            // In a strict clinic, we block doctors from /settings/users.
            if (state.matchedLocation.startsWith('/settings/users')) {
              return '/settings';
            }
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
