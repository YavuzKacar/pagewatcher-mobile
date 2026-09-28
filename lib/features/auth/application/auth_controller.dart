import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../data/social_auth.dart';
import '../data/user.dart';

sealed class AuthState {
  const AuthState();
}

/// Restoring a stored session at startup.
final class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// A stored session exists but `/auth/me` couldn't be reached (offline).
final class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed();
}

final class SignedOut extends AuthState {
  const SignedOut({this.sessionExpired = false});

  /// True when the API revoked the session, so the UI can explain why.
  final bool sessionExpired;
}

final class SignedIn extends AuthState {
  const SignedIn(this.user, {this.isNewUser = false});

  final User user;

  /// Just registered — show the trial/plan screen once.
  final bool isNewUser;
}

/// Session state for the whole app (port of frontend/src/contexts/AuthContext.tsx).
/// Sign-in methods throw [ApiException] for the calling screen to display, and
/// return false if the user cancelled a native sign-in sheet.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final sub = ref.read(sessionExpiredEventsProvider).stream.listen((_) {
      if (state is SignedIn) state = const SignedOut(sessionExpired: true);
    });
    ref.onDispose(sub.cancel);
    unawaited(Future.microtask(restore));
    return const AuthRestoring();
  }

  Future<void> restore() async {
    state = const AuthRestoring();
    if (!await _repo.hasStoredSession()) {
      state = const SignedOut();
      return;
    }
    try {
      state = SignedIn(await _repo.me());
    } on ApiException catch (e) {
      if (e.isNetworkError || (e.statusCode ?? 0) >= 500) {
        state = const AuthRestoreFailed();
      } else {
        await _repo.logout();
        state = const SignedOut();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    final isNew = await _repo.login(email.trim(), password);
    await _completeSignIn(isNewUser: isNew);
  }

  /// Registers, then signs straight in (the web app sends users back to the
  /// login form instead; there's no reason to make mobile users retype).
  Future<void> register(String email, String password) async {
    await _repo.register(email.trim(), password);
    await _repo.login(email.trim(), password);
    await _completeSignIn(isNewUser: true);
  }

  Future<bool> signInWithGoogle() async {
    final idToken = await ref.read(socialAuthProvider).googleIdToken();
    if (idToken == null) return false;
    final isNew = await _repo.loginWithGoogle(idToken);
    await _completeSignIn(isNewUser: isNew);
    return true;
  }

  Future<bool> signInWithApple() async {
    final credential = await ref.read(socialAuthProvider).appleCredential();
    if (credential == null) return false;
    final isNew = await _repo.loginWithApple(credential.idToken, name: credential.name);
    await _completeSignIn(isNewUser: isNew);
    return true;
  }

  Future<void> refreshUser() async {
    final current = state;
    if (current is! SignedIn) return;
    state = SignedIn(await _repo.me(), isNewUser: current.isNewUser);
  }

  void acknowledgeNewUser() {
    final current = state;
    if (current is SignedIn && current.isNewUser) state = SignedIn(current.user);
  }

  Future<void> signOut() async {
    await _repo.logout();
    await ref.read(socialAuthProvider).signOut();
    state = const SignedOut();
  }

  Future<void> _completeSignIn({required bool isNewUser}) async {
    state = SignedIn(await _repo.me(), isNewUser: isNewUser);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user. Null only briefly, while signed-in screens are still
/// mounted during a sign-out redirect.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is SignedIn ? state.user : null;
});
