import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagewatcher_mobile/app.dart';
import 'package:pagewatcher_mobile/core/providers.dart';
import 'package:pagewatcher_mobile/core/storage/preferences.dart';
import 'package:pagewatcher_mobile/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, {required Map<String, Object> prefs}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(AppPreferences(sharedPrefs)),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      ],
      child: const PageWatcherApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch without a session shows onboarding', (tester) async {
    await _pumpApp(tester, prefs: {'pw_language': 'en'});
    expect(find.text('Watch any page — just by chatting'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('returning signed-out user lands on sign in', (tester) async {
    await _pumpApp(tester, prefs: {'pw_language': 'en', 'onboarding_seen': true});
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
  });

  testWidgets('sign-in form validates before calling the API', (tester) async {
    await _pumpApp(tester, prefs: {'pw_language': 'en', 'onboarding_seen': true});
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
