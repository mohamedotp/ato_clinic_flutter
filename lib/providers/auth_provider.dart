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
      state = AuthAuthenticated(user, profile);
    } catch (e) {
      // In case profile is not yet created or error fetching
      state = AuthAuthenticated(user, null);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = AuthLoading();
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
