abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  // Same path as the web app, so emailed links map 1:1 once app links are set up.
  static const resetPassword = '/reset-password';
  static const trial = '/trial';

  static const chat = '/chat';
  static const monitors = '/monitors';
  static const changes = '/changes';
  static const settings = '/settings';

  /// Reachable while signed out.
  static const public = {welcome, login, register, forgotPassword, resetPassword};
}
