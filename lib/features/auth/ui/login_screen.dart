import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/password_field.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/social_sign_in_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(authControllerProvider);
      if (state is SignedOut && state.sessionExpired && mounted) {
        showInfoSnackBar(context, context.l10n.mobileErrorsSessionExpired);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.authModalWelcomeBack,
      subtitle: l10n.authModalSignInSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.authModalEmail),
                validator: (v) => validateEmail(v, l10n.mobileErrorsInvalidEmail),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: l10n.authModalPassword,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.isEmpty) ? l10n.authModalErrorsGeneric : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: Text(l10n.authModalForgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              GradientButton(
                label: l10n.authModalSignIn,
                loadingLabel: l10n.authModalSigningIn,
                loading: _submitting,
                onPressed: _submit,
              ),
              OrDivider(label: l10n.authModalOrContinueWith),
              SocialSignInButtons(enabled: !_submitting),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.authModalNoAccount, style: const TextStyle(color: AppColors.gray600)),
                  TextButton(
                    onPressed: () => context.go(Routes.register),
                    child: Text(l10n.authModalSignUp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
