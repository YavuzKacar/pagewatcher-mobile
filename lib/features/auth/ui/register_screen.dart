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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(_email.text, _password.text);
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
      title: l10n.authModalCreateAccount,
      subtitle: l10n.authModalSignUpSubtitle,
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
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.authModalEmail),
                validator: (v) => validateEmail(v, l10n.mobileErrorsInvalidEmail),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: l10n.authModalPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => (v ?? '').length < 8 ? l10n.authModalErrorsPasswordTooShort : null,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: l10n.authModalConfirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (v) => v != _password.text ? l10n.authModalErrorsPasswordsMismatch : null,
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: l10n.authModalCreateAccountButton,
                loadingLabel: l10n.authModalCreatingAccount,
                loading: _submitting,
                onPressed: _submit,
              ),
              OrDivider(label: l10n.authModalOrContinueWith),
              SocialSignInButtons(enabled: !_submitting),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.authModalHaveAccount, style: const TextStyle(color: AppColors.gray600)),
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(l10n.authModalSignIn),
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
