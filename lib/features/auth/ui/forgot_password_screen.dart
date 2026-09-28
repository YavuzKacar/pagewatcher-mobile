import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) setState(() => _sentTo = email);
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
      showBack: true,
      title: l10n.mobileForgotTitle,
      subtitle: _sentTo == null ? l10n.mobileForgotSubtitle : null,
      child: _sentTo != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.activeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: AppColors.active),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.mobileForgotSent(_sentTo!))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.go(Routes.login),
                  child: Text(l10n.mobileForgotBackToSignIn),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(labelText: l10n.authModalEmail),
                    validator: (v) => validateEmail(v, l10n.mobileErrorsInvalidEmail),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: l10n.mobileForgotSubmit,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
