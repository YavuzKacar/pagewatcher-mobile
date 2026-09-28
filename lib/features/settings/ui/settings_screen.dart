import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/colors.dart';
import '../../auth/application/auth_controller.dart';

/// Milestone-2 settings: account summary, plan, language and log out.
/// Profile editing, password, channels and account deletion come in milestone 6.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(l10n.mobileSettingsAccount),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary100,
                foregroundColor: AppColors.primary700,
                child: Text(user.label.characters.first.toUpperCase()),
              ),
              title: Text(user.label),
              subtitle: user.displayName != null ? Text(user.email) : null,
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.mobileSettingsPlan),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(_planName(l10n, user.plan)),
                  trailing: user.isTrialing
                      ? Chip(
                          label: Text(l10n.appSettingsSubscriptionTrialBadge),
                          backgroundColor: AppColors.primary50,
                          side: BorderSide.none,
                        )
                      : null,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(l10n.mobileSettingsManagePlanOnWeb),
                  onTap: () => launchUrl(
                    Uri.parse('${Env.webBaseUrl}/pricing'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.commonLanguageLabel),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(_languageName(l10n, locale?.languageCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, ref, locale?.languageCode),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: Text(l10n.commonNavLogout, style: const TextStyle(color: AppColors.danger)),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String? current) async {
    final l10n = context.l10n;
    const deviceSentinel = '';
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current ?? deviceSentinel,
          onChanged: (value) => Navigator.pop(context, value),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final code in [deviceSentinel, ..._languageCodes])
                RadioListTile<String>(
                  value: code,
                  title: Text(_languageName(l10n, code.isEmpty ? null : code)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await ref.read(localeProvider.notifier).setLanguage(picked.isEmpty ? null : picked);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.mobileSettingsLogoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonActionsCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonNavLogout)),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authControllerProvider.notifier).signOut();
  }
}

const _languageCodes = ['en', 'de', 'fr', 'tr', 'ko', 'ja'];

String _languageName(AppLocalizations l10n, String? code) => switch (code) {
      'en' => l10n.commonLanguageEn,
      'de' => l10n.commonLanguageDe,
      'fr' => l10n.commonLanguageFr,
      'tr' => l10n.commonLanguageTr,
      'ko' => l10n.commonLanguageKo,
      'ja' => l10n.commonLanguageJa,
      _ => l10n.mobileSettingsDeviceLanguage,
    };

String _planName(AppLocalizations l10n, String plan) => switch (plan) {
      'pro' => l10n.mobilePlansPro,
      'individual' => l10n.mobilePlansIndividual,
      _ => l10n.mobilePlansFree,
    };

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.gray500,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}
