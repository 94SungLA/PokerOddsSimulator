import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/models/auth_user.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Synchronously check if there is an active user (e.g. Firebase auto-login)
    if (AuthService.currentUser != null) {
      state = AsyncValue.data(AuthService.currentUser);
    } else {
      state = const AsyncValue.data(null);
    }

    // Subscribe to auth state updates (both Firebase and Guest sessions)
    AuthService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    }, onError: (err, stack) {
      state = AsyncValue.error(err, stack);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e) {
      // Revert loading state to previous user session state
      state = AsyncValue.data(AuthService.currentUser);
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthService.loginAsGuest();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier();
});
