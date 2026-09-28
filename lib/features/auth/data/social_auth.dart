import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/env.dart';

typedef AppleCredential = ({String idToken, String? name});

/// Native Google / Apple sign-in. Each method returns the provider's ID token
/// for the backend to verify, or null if the user cancelled.
class SocialAuth {
  Future<void>? _googleInit;

  /// Apple sign-in is offered on iOS only. (It's mandatory there whenever
  /// Google sign-in is offered; on Android it would need a web redirect flow.)
  bool get appleAvailable => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<String?> googleIdToken() async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS && Env.googleIosClientId.isNotEmpty
          ? Env.googleIosClientId
          : null,
      // Makes the ID token's audience the web client ID the backend verifies.
      serverClientId: Env.googleServerClientId,
    ));
    try {
      final account = await google.authenticate(scopeHint: const ['email', 'profile']);
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<AppleCredential?> appleCredential() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final idToken = credential.identityToken;
      if (idToken == null) return null;
      // Apple only sends the name on the very first authorization.
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ');
      return (idToken: idToken, name: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_googleInit == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google — nothing to do.
    }
  }
}

final socialAuthProvider = Provider<SocialAuth>((ref) => SocialAuth());
