import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'screens/account_home_screen.dart';
import 'screens/ask_screen.dart';
import 'screens/chapter_edit_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/connected_accounts_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/first_launch_screen.dart';
import 'screens/guest_mode_screen.dart';
import 'screens/home_screen.dart';
import 'screens/import_screen.dart';
import 'screens/library_screen.dart';
import 'screens/media_detail_screen.dart';
import 'screens/migrate_screen.dart';
import 'screens/moment_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/payoff_screen.dart';
import 'screens/people_screen.dart';
import 'screens/places_screen.dart';
import 'screens/reconstructing_screen.dart';
import 'screens/resurface_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/share_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_out_screen.dart';
import 'screens/story_detail_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/upgrade_prompt_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/voice_note_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/archive_controller.dart';
import 'state/ask_controller.dart';
import 'state/auth_controller.dart';
import 'widgets/app_shell.dart';

/// PALIMPSEST app shell.
///
/// Single V7 theme in phase 1 ([AppTheme.current]); the palette is
/// isolated so phase 2 can add a light theme and a toggle without
/// touching screens. All 30 routes live here — each screen builds its
/// mobile layout below the wide breakpoint and its wide (web) layout
/// at or above it, covering the 60 designed screens.
class PalimpsestApp extends StatelessWidget {
  /// Creates the app.
  const PalimpsestApp({
    required this.archive,
    required this.ask,
    required this.auth,
    required this.showFirstLaunch,
    super.key,
  });

  /// The archive controller.
  final ArchiveController archive;

  /// The ask-flow controller.
  final AskController ask;

  /// The auth controller.
  final AuthController auth;

  /// True on a first run — the first-launch flow is the initial route.
  final bool showFirstLaunch;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      archive: archive,
      ask: ask,
      auth: auth,
      child: MaterialApp(
        title: 'Palimpsest',
        theme: AppTheme.current,
        initialRoute: showFirstLaunch ? Routes.firstLaunch : Routes.home,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    late final Widget screen;
    switch (settings.name) {
      case Routes.home:
        screen = const HomeScreen();
      case Routes.story:
        screen = StoryDetailScreen(storyId: args as String);
      case Routes.ask:
        screen = const AskScreen();
      case Routes.reconstructing:
        screen = ReconstructingScreen(query: args as String);
      case Routes.moment:
        screen = MomentScreen(momentId: args as String);
      case Routes.library:
        screen = const LibraryScreen();
      case Routes.media:
        screen = MediaDetailScreen(itemId: args as String);
      case Routes.compose:
        screen = ComposeScreen(storyId: args as String);
      case Routes.chapterEdit:
        final map = args as Map<String, String>;
        screen = ChapterEditScreen(
          storyId: map['storyId']!,
          chapterId: map['chapterId']!,
        );
      case Routes.timeline:
        screen = const TimelineScreen();
      case Routes.people:
        screen = const PeopleScreen();
      case Routes.places:
        screen = const PlacesScreen();
      case Routes.voiceNote:
        screen = VoiceNoteScreen(noteId: args as String);
      case Routes.import:
        screen = const ImportScreen();
      case Routes.offline:
        screen = const OfflineScreen();
      case Routes.share:
        screen = ShareScreen(storyId: args as String);
      case Routes.settings:
        screen = const SettingsScreen();
      case Routes.resurface:
        screen = const ResurfaceScreen();
      case Routes.firstLaunch:
        screen = const FirstLaunchScreen();
      case Routes.payoff:
        screen = const PayoffScreen();
      case Routes.welcome:
        screen = const WelcomeScreen();
      case Routes.guestMode:
        screen = const GuestModeScreen();
      case Routes.signIn:
        screen = const SignInScreen();
      case Routes.createAccount:
        screen = const CreateAccountScreen();
      case Routes.verify:
        screen = VerifyScreen(email: args as String);
      case Routes.upgrade:
        screen = UpgradePromptScreen(storyId: args as String?);
      case Routes.migrate:
        screen = const MigrateScreen();
      case Routes.account:
        screen = const AccountHomeScreen();
      case Routes.connected:
        screen = const ConnectedAccountsScreen();
      case Routes.signOut:
        screen = const SignOutScreen();
      default:
        screen = const HomeScreen();
    }
    return MaterialPageRoute<void>(
      builder: (_) => screen,
      settings: settings,
    );
  }
}
