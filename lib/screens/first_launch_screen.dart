import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// First launch (m19 / w19): your life, as an editable memory —
/// import, scan, or ask. No account needed.
class FirstLaunchScreen extends StatelessWidget {
  /// Creates the first-launch screen.
  const FirstLaunchScreen({super.key});

  void _enter(BuildContext context, String route) {
    AppScope.of(context).archive.markOnboardingSeen();
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 32),
          SvgPicture.asset(
            'assets/logos/stacked.svg',
            width: 220,
          ),
          const SizedBox(height: 24),
          Text(
            'Your life, as an editable memory',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Import a library, scan the photo box, or just ask for a moment. No account needed — the archive lives on this device.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _LaunchAction(
            icon: Icons.photo_library_outlined,
            title: 'Import photos',
            subtitle: 'Everything lands in the import queue first',
            onTap: () => _enter(context, Routes.import),
          ),
          const SizedBox(height: 10),
          _LaunchAction(
            icon: Icons.scanner_outlined,
            title: 'Scan prints',
            subtitle: 'The photo box, one scan at a time',
            onTap: () => _enter(context, Routes.import),
          ),
          const SizedBox(height: 10),
          _LaunchAction(
            icon: Icons.search,
            title: 'Ask for a moment',
            subtitle: 'Try the demo library — no import needed',
            onTap: () => _enter(context, Routes.ask),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.payoff),
            child: const Text('Tell me more first'),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Palimpsest',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}

class _LaunchAction extends StatelessWidget {
  const _LaunchAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, color: Palette.v7.gold, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: AppTheme.mono(size: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: V7Colors.muted),
        ],
      ),
    );
  }
}
