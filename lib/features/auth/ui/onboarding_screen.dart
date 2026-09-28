import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/gradient_button.dart';

/// First-launch intro carousel (port of components/onboarding/OnboardingIntro.tsx).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await ref.read(preferencesProvider).setOnboardingSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (Icons.chat_bubble_outline, l10n.authOnboardingStepsChatTitle, l10n.authOnboardingStepsChatDescription),
      (Icons.auto_awesome_outlined, l10n.authOnboardingStepsAiTitle, l10n.authOnboardingStepsAiDescription),
      (
        Icons.notifications_active_outlined,
        l10n.authOnboardingStepsNotifyTitle,
        l10n.authOnboardingStepsNotifyDescription,
      ),
    ];
    final isLast = _index == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish(Routes.login),
                child: Text(l10n.authOnboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (icon, title, description) = steps[i];
                  return _Step(icon: icon, title: title, description: description);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary600 : AppColors.gray300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: GradientButton(
                label: isLast ? l10n.authOnboardingGetStarted : l10n.authOnboardingNext,
                onPressed: isLast
                    ? () => _finish(Routes.register)
                    : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.gray600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
