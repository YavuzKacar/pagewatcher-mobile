import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../application/auth_controller.dart';

/// Shown once after sign-up. Mobile replacement for the web's PlanPicker:
/// no purchases in-app, so it explains the trial and links to the website.
class TrialWelcomeScreen extends ConsumerWidget {
  const TrialWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.celebration_outlined, size: 48, color: AppColors.primary600),
            const SizedBox(height: 16),
            Text(
              l10n.authPlanPickerTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authPlanPickerSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray600),
            ),
            const SizedBox(height: 24),
            _PlanCard(
              name: l10n.authPlanPickerPlansIndividualName,
              price: l10n.authPlanPickerPlansIndividualPrice,
              features: [
                l10n.authPlanPickerPlansIndividualFeatures0,
                l10n.authPlanPickerPlansIndividualFeatures1,
                l10n.authPlanPickerPlansIndividualFeatures2,
              ],
              highlighted: true,
            ),
            const SizedBox(height: 12),
            _PlanCard(
              name: l10n.authPlanPickerPlansProName,
              price: l10n.authPlanPickerPlansProPrice,
              features: [
                l10n.authPlanPickerPlansProFeatures0,
                l10n.authPlanPickerPlansProFeatures1,
                l10n.authPlanPickerPlansProFeatures2,
              ],
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: l10n.authPlanPickerContinueWithTrial,
              onPressed: () {
                ref.read(authControllerProvider.notifier).acknowledgeNewUser();
                context.go(Routes.chat);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('${Env.webBaseUrl}/pricing'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(l10n.mobileTrialComparePlans),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.features,
    this.highlighted = false,
  });

  final String name;
  final String price;
  final List<String> features;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.primary400 : AppColors.gray200,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(price, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray600)),
          const SizedBox(height: 12),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.active),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
