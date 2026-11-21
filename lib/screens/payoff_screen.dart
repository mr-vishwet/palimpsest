import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/memory_orb.dart';

/// The payoff (m20 / w20): every moment, one question away — 5,012
/// photos, 0 uploaded.
class PayoffScreen extends StatelessWidget {
  /// Creates the payoff screen.
  const PayoffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 40),
          const MemoryOrb(size: 140),
          const SizedBox(height: 32),
          Text(
            'Every moment, one question away',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '“Show me everything from the weekend when I first started working on that project” — and the weekend comes back, in order, with the reason each piece is there.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  value: Format.count(AppConstants.totalPhotos),
                  label: 'photos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  value: '${AppConstants.totalVideos}',
                  label: 'videos',
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: StatTile(value: '0', label: 'uploaded'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Continue',
            expanded: true,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.welcome),
          ),
          const SizedBox(height: 12),
          Text(
            'The demo library is seeded — the real archive starts when you import yours.',
            style: AppTheme.mono(size: 11),
            textAlign: TextAlign.center,
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
