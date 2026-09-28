import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo.png', width: size, height: size, semanticLabel: 'PageWatcher');
}

/// Centered icon + title + message, used for empty, error and not-yet-built states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.primary600),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => MessageView(
        icon: icon,
        title: context.l10n.mobileComingSoonTitle,
        message: context.l10n.mobileComingSoonDescription,
      );
}
