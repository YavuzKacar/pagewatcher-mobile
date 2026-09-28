# PageWatcher Mobile

The Flutter (Android + iOS) client for the PageWatcher REST API. Read `docs/PLAN.md` for scope, decisions, milestone status and the API mapping. Update its Status table when a milestone is finished.

## Commands
```bash
flutter pub get                                   # also runs gen-l10n (lib/l10n/gen/)
flutter analyze
flutter test
flutter run --dart-define-from-file=env/dev.json  # local backend via emulator (10.0.2.2:8000)
node tool/convert_i18n.mjs                        # regenerate ARB from ../pagewatcher web locales + i18n/mobile/
```

## Conventions
- Feature-first layout: `lib/features/<feature>/{data,application,ui}`. Shared code goes in `lib/core/`.
- Riverpod 3 with hand-written providers; **no code generation** (no freezed, json_serializable or riverpod_generator). Models have a hand-written `fromJson`.
- All HTTP goes through `apiClientProvider` (dio). Wrap repository calls in `guardApi(...)` so errors become `ApiException`. Show errors with `showErrorSnackBar(context, e)`.
- Endpoints that take credentials use `Options(extra: {AuthExtra.skipAuth: true})`, so their 401 means "wrong credentials", not "refresh the token".
- Never hardcode UI strings. Use `context.l10n.<key>`.
  - Web strings are keyed by namespace + camelCase path, e.g. `auth.modal.signIn` becomes `authModalSignIn`.
  - Mobile-only strings go in `i18n/mobile/en.json` and `tr.json` (prefix `mobile…`). Re-run the converter afterwards.
- Navigation: `Routes` constants plus `context.go/push`. The auth redirect lives in `lib/core/router/app_router.dart`.
- Colors come from `AppColors`, and the primary CTA is `GradientButton`.

## Related repo
The web app and backend live in `../pagewatcher` (`github.com/YavuzKacar/changeradar`). Use it as the reference for API shapes (`frontend/src/services/api.ts`, `backend/app/schemas/`) and for behaviour to port. Backend changes are deployed on the owner's Windows server, so **ask before modifying the backend**.
