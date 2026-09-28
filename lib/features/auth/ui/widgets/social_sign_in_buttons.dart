import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/feedback.dart';
import '../../application/auth_controller.dart';
import '../../data/social_auth.dart';

enum _Provider { google, apple }

/// "Continue with Google / Apple". Navigation after success is handled by the
/// router reacting to the auth state.
class SocialSignInButtons extends ConsumerStatefulWidget {
  const SocialSignInButtons({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  _Provider? _busy;

  Future<void> _run(_Provider provider) async {
    setState(() => _busy = provider);
    final auth = ref.read(authControllerProvider.notifier);
    try {
      switch (provider) {
        case _Provider.google:
          await auth.signInWithGoogle();
        case _Provider.apple:
          await auth.signInWithApple();
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } catch (_) {
      // Platform errors from the native SDKs (misconfiguration, no Play Services, ...).
      if (mounted) {
        final l10n = context.l10n;
        showInfoSnackBar(
          context,
          provider == _Provider.google ? l10n.authModalGoogleSignInFailed : l10n.authModalAppleSignInFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = widget.enabled && _busy == null;
    final showApple = ref.watch(socialAuthProvider).appleAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: enabled ? () => _run(_Provider.google) : null,
          icon: _busy == _Provider.google
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const _GoogleMark(),
          label: Text(l10n.mobileSocialContinueWithGoogle),
        ),
        if (showApple) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: enabled ? () => _run(_Provider.apple) : null,
            icon: _busy == _Provider.apple
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.apple, size: 22),
            label: Text(l10n.authModalContinueWithApple),
          ),
        ],
      ],
    );
  }
}

/// Simple multi-color "G" so we don't ship Google's brand asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (bounds) => const SweepGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
        ).createShader(bounds),
        child: const Text(
          'G',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
}
