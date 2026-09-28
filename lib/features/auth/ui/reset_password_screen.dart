import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/password_field.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

/// Target of the emailed link `https://pagewatcher.app/reset-password?token=…`
/// (opened in-app once universal/app links are configured).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(widget.token!, _password.text);
      if (!mounted) return;
      showInfoSnackBar(context, context.l10n.mobileResetSuccess);
      context.go(Routes.login);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final token = widget.token;

    if (token == null || token.isEmpty) {
      return AuthScaffold(
        title: l10n.mobileResetTitle,
        subtitle: l10n.mobileResetInvalidLink,
        child: OutlinedButton(
          onPressed: () => context.go(Routes.forgotPassword),
          child: Text(l10n.mobileForgotSubmit),
        ),
      );
    }

    return AuthScaffold(
      title: l10n.mobileResetTitle,
      subtitle: l10n.mobileResetSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(
              controller: _password,
              label: l10n.mobileResetNewPassword,
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
              label: l10n.mobileResetSubmit,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
