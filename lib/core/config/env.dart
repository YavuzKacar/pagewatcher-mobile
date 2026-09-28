/// Build-time configuration, supplied with `--dart-define` (or
/// `--dart-define-from-file=env/dev.json`). Defaults point at production.
abstract final class Env {
  /// Backend API root, including the `/api/v1` prefix.
  /// Android emulator → local backend: `http://10.0.2.2:8000/api/v1`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.pagewatcher.app/api/v1',
  );

  /// Public website, used for plan management and legal links.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://pagewatcher.app',
  );

  /// The *web* OAuth client ID. Passed to google_sign_in as `serverClientId`
  /// so the ID token's audience matches what `/auth/google` verifies.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '1042316623614-tlm4qt6tqa31stcho9t9v6eu71rl1cq2.apps.googleusercontent.com',
  );

  /// iOS OAuth client ID (from the Google Cloud console). Android needs none;
  /// it is matched by package name + SHA-1 instead.
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
