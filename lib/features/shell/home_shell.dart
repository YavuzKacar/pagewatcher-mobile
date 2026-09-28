import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';

/// Bottom navigation: Chat · Monitors · Changes · Settings.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Re-tapping the active tab pops it back to its root.
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.mobileTabsChat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_heart_outlined),
            selectedIcon: const Icon(Icons.monitor_heart),
            label: l10n.commonNavMonitors,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.mobileTabsChanges,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.commonNavSettings,
          ),
        ],
      ),
    );
  }
}
