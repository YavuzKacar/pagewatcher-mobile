import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/ui/forgot_password_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/onboarding_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/auth/ui/reset_password_screen.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/trial_welcome_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/shell/tab_placeholders.dart';
import '../providers.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridges the auth state into a Listenable so GoRouter re-runs `redirect`.
  final authState = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => authState.value = next);
  ref.onDispose(authState.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authState,
    redirect: (context, state) {
      final auth = authState.value;
      final path = state.matchedLocation;

      switch (auth) {
        case AuthRestoring() || AuthRestoreFailed():
          return path == Routes.splash ? null : Routes.splash;

        case SignedOut():
          if (Routes.public.contains(path)) return null;
          return ref.read(preferencesProvider).onboardingSeen ? Routes.login : Routes.welcome;

        case SignedIn(:final isNewUser):
          // Let a signed-in user still open a password-reset link.
          if (path == Routes.resetPassword) return null;
          if (isNewUser && path != Routes.trial) return Routes.trial;
          if (path == Routes.splash || path == Routes.trial || Routes.public.contains(path)) {
            return isNewUser ? null : Routes.chat;
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) => ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: Routes.trial, builder: (_, _) => const TrialWelcomeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.chat, builder: (_, _) => const ChatTab())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.monitors, builder: (_, _) => const MonitorsTab())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.changes, builder: (_, _) => const ChangesTab())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
