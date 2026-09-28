import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/widgets/placeholders.dart';

// Temporary tab bodies; replaced by the real features in milestones 3–5.

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.mobileTabsChat)),
        body: const ComingSoonView(icon: Icons.chat_bubble_outline),
      );
}

class MonitorsTab extends StatelessWidget {
  const MonitorsTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.commonNavMonitors)),
        body: const ComingSoonView(icon: Icons.monitor_heart_outlined),
      );
}

class ChangesTab extends StatelessWidget {
  const ChangesTab({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.mobileTabsChanges)),
        body: const ComingSoonView(icon: Icons.history),
      );
}
