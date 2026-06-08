import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:ato_clinic_flutter/core/theme/app_colors.dart';
import 'package:ato_clinic_flutter/screens/auth/login_screen.dart';
import 'package:ato_clinic_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/patients/patients_list_screen.dart';
import 'package:ato_clinic_flutter/screens/services/services_list_screen.dart';
import 'package:ato_clinic_flutter/screens/appointments/appointments_list_screen.dart';
import 'package:ato_clinic_flutter/screens/visits/visits_list_screen.dart';
import 'package:ato_clinic_flutter/screens/workspace/workspace_screen.dart';
import 'package:ato_clinic_flutter/screens/settings/settings_screen.dart';
import 'package:ato_clinic_flutter/screens/settings/users_list_screen.dart';
import 'package:ato_clinic_flutter/screens/settings/audit_logs_screen.dart';
import 'package:ato_clinic_flutter/screens/clinic/ai_dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/handoff/handoff_screen.dart';
import 'package:ato_clinic_flutter/screens/notifications/notifications_screen.dart';
import 'package:ato_clinic_flutter/models/profile.dart';
// Patient Screens
import 'package:ato_clinic_flutter/screens/patient_portal/patient_dashboard_screen.dart';
import 'package:ato_clinic_flutter/screens/patient_portal/patient_chat_screen.dart';
import 'package:ato_clinic_flutter/screens/patient_portal/patient_booking_screen.dart';
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
import 'package:ato_clinic_flutter/screens/materials/materials_screen.dart';
// Basic Modules
import 'package:ato_clinic_flutter/screens/finance/finance_screen.dart';
import 'package:ato_clinic_flutter/screens/finance/doctor_percentage_screen.dart';
import 'package:ato_clinic_flutter/screens/lab/lab_orders_screen.dart';
import 'package:ato_clinic_flutter/screens/treatment/treatment_plans_screen.dart';
import 'package:ato_clinic_flutter/screens/procedures/procedure_steps_screen.dart';
import 'package:ato_clinic_flutter/screens/insurance/insurance_screen.dart';
import 'package:ato_clinic_flutter/screens/reports/reports_screen.dart' as clinic_reports;
import 'package:ato_clinic_flutter/screens/staff/staff_attendance_screen.dart';
import 'package:ato_clinic_flutter/screens/staff/staff_tasks_screen.dart';
import 'package:ato_clinic_flutter/screens/staff/staff_training_screen.dart';

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
      final bool isSplash = state.matchedLocation == '/splash';

      if (authState is AuthInitial || authState is AuthLoading) {
        // If the user is explicitly logging in, keep them on the login screen
        if (isLoggingIn) return null;
        // Otherwise, show splash screen while loading session/profile
        return isSplash ? null : '/splash';
      }

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn || isSplash) {
        final profile = (authState as AuthAuthenticated).profile;
        if (profile?.role == UserRole.super_admin) return '/super-admin';
        if (profile?.role == UserRole.patient) return '/patient-dashboard';
        return '/';
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

      // Guard patient routes
      final isPatient = role == UserRole.patient;
      if (isPatient && !state.matchedLocation.startsWith('/patient-')) {
        return '/patient-dashboard';
      }
      if (!isPatient && state.matchedLocation.startsWith('/patient-')) {
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
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
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
          GoRoute(
            path: 'audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiDashboardScreen(),
      ),
      GoRoute(
        path: '/materials',
        builder: (context, state) => const MaterialsScreen(),
      ),
      GoRoute(
        path: '/handoff',
        builder: (context, state) => const HandoffScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinanceScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const clinic_reports.ReportsScreen(),
      ),
      GoRoute(
        path: '/doctor-percentage',
        builder: (context, state) => const DoctorPercentageScreen(),
      ),
      GoRoute(
        path: '/lab-orders',
        builder: (context, state) => const LabOrdersScreen(),
      ),
      GoRoute(
        path: '/treatment-plans',
        builder: (context, state) => const TreatmentPlansScreen(),
      ),
      GoRoute(
        path: '/procedures',
        builder: (context, state) => const ProcedureStepsScreen(),
      ),
      GoRoute(
        path: '/insurance',
        builder: (context, state) => const InsuranceScreen(),
      ),
      GoRoute(
        path: '/staff/attendance',
        builder: (context, state) => const StaffAttendanceScreen(),
      ),
      GoRoute(
        path: '/staff/tasks',
        builder: (context, state) => const StaffTasksScreen(),
      ),
      GoRoute(
        path: '/staff/training',
        builder: (context, state) => const StaffTrainingScreen(),
      ),

      // ── Patient routes ──────────────────────────────────────
      GoRoute(
        path: '/patient-dashboard',
        builder: (context, state) => const PatientDashboardScreen(),
      ),
      GoRoute(
        path: '/patient-chat/:doctorId',
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId']!;
          return PatientChatScreen(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: '/patient-booking',
        builder: (context, state) => const PatientBookingScreen(),
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
