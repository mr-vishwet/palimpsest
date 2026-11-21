import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Welcome (m21 / w21): guest-first — the whole archive works
/// without an account.
class WelcomeScreen extends StatelessWidget {
  /// Creates the welcome screen.
  const WelcomeScreen({super.key});

  void _continueAsGuest(BuildContext context) {
    AppScope.of(context).archive.markOnboardingSeen();
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.home,
      (route) => false,
    );
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
            'assets/logos/icon.svg',
            width: 88,
            height: 88,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Palimpsest',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Guest-first: the whole archive works without an account. Import, search, stories, edits — all on this device, starting now.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Continue as guest',
            expanded: true,
            onPressed: () => _continueAsGuest(context),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.signIn),
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.createAccount),
            child: const Text('Create an account'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.guestMode),
            child: const Text('What works as a guest?'),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Welcome',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}
