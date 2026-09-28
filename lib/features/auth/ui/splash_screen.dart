import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/placeholders.dart';
import '../application/auth_controller.dart';

/// Shown while the stored session is being restored, or if that failed
/// because the API was unreachable.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(authControllerProvider) is AuthRestoreFailed;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 88),
              const SizedBox(height: 32),
              if (!failed)
                const CircularProgressIndicator()
              else ...[
                Text(
                  l10n.mobileErrorsNetwork,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gray600),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.read(authControllerProvider.notifier).restore(),
                  child: Text(l10n.appMonitorDetailSnapshotsRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
