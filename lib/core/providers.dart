import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import 'network/dio_client.dart';
import 'storage/preferences.dart';
import 'storage/token_storage.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final preferencesProvider = Provider<AppPreferences>(
  (ref) => throw UnimplementedError('preferencesProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

/// Fires when the API rejects our refresh token. The auth controller listens
/// to this and flips to signed-out, which the router turns into /login.
final sessionExpiredEventsProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

final apiClientProvider = Provider<Dio>((ref) {
  final events = ref.watch(sessionExpiredEventsProvider);
  return createApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: () => events.add(null),
  );
});

/// App language chosen in settings; null follows the device.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(preferencesProvider).languageCode;
    return code == null ? null : Locale(code);
  }

  Future<void> setLanguage(String? code) async {
    await ref.read(preferencesProvider).setLanguageCode(code);
    state = code == null ? null : Locale(code);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Language code to send to the backend (e.g. chat replies), resolved against
/// the languages the app supports.
String effectiveLanguageCode(Locale? chosen) {
  final code = (chosen ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == code) ? code : 'en';
}
