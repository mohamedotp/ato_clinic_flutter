import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

final authService = Provider((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authService));
});

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  final Profile? profile;
  AuthAuthenticated(this.user, this.profile);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user != null) {
      _loadProfile(user);
    } else {
      state = AuthUnauthenticated();
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadProfile(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthUnauthenticated();
      }
    });
  }

  Future<void> _loadProfile(User user) async {
    state = AuthLoading();
    try {
      final profile = await _authService.getProfile(user.id);
      
      // 1. Check if profile exists
      if (profile == null) {
        await _authService.signOut();
        state = AuthError('لم يتم العثور على ملف تعريف لهذا المستخدم. يرجى التواصل مع الإدارة.');
        return;
      }

      // 2. Check Role-based logic
      final isSuperAdmin = profile.role == UserRole.super_admin;
      
      if (!isSuperAdmin) {
        // Validation for regular users (Doctors/Receptionists/Admins)
        
        // Check if assigned to a clinic
        if (profile.clinicId == null) {
          await _authService.signOut();
          state = AuthError('هذا الحساب غير مربوط بأي عيادة حالياً.');
          return;
        }

        // Check if clinic is active
        final active = await _authService.isClinicActive(profile.clinicId!);
        if (!active) {
          await _authService.signOut();
          state = AuthError('عذراً، هذه العيادة متوقفة حالياً. يرجى مراجعة الإدارة.');
          return;
        }
      }

      // Everything is fine
      state = AuthAuthenticated(user, profile);
    } catch (e) {
      print('=== ERROR LOADING PROFILE ===');
      print(e);
      await _authService.signOut();
      state = AuthError('حدث خطأ أثناء تحميل بياناتك: ${e.toString()}');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = AuthLoading();
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      state = AuthError(_mapAuthError(e));
    }
  }

  String _mapAuthError(Object e) {
    if (e is AuthException) {
      final message = e.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else if (message.contains('email not confirmed')) {
        return 'يرجى تأكيد البريد الإلكتروني أولاً عبر الرابط المرسل لك.';
      } else if (message.contains('missing email') || message.contains('validation failed')) {
        return 'يرجى التأكد من إدخال البريد الإلكتروني وكلمة المرور بشكل صحيح.';
      } else if (message.contains('user not found')) {
        return 'عذراً، هذا المستخدم غير مسجل في النظام.';
      } else if (message.contains('too many requests')) {
        return 'لقد قمت بمحاولات كثيرة جداً. يرجى الانتظار دقيقة قبل المحاولة مرة أخرى.';
      } else if (message.contains('network') || message.contains('failed host lookup')) {
        return 'فشل الاتصال بالإنترنت. يرجى التأكد من اتصالك.';
      }
      return 'حدث خطأ في عملية الدخول: ${e.message}';
    }
    return 'حدث خطأ غير متوقع: ${e.toString()}';
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;
    
    try {
      await _authService.updateProfile(current.user.id, updates);
      await _loadProfile(current.user);
    } catch (e) {
      state = AuthError(_mapAuthError(e));
    }
  }
}
