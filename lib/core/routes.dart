/// Named routes for all 30 screens.
///
/// Each route serves both layouts: the screen builds its mobile layout
/// below [AppConstants.wideBreakpoint] and its wide (web) layout at or
/// above it, so the 30 routes cover the 60 designed screens (m01–m30 +
/// w01–w30).
///
/// Arguments are passed via [RouteSettings.arguments]:
/// - [story], [compose], [share]: a story id ([String]).
/// - [reconstructing]: the question ([String]).
/// - [moment]: a reconstructed-moment id ([String]).
/// - [media]: a memory-item id ([String]).
/// - [chapterEdit]: a `Map<String, String>` with `storyId` and
///   `chapterId`.
/// - [voiceNote]: a voice-note id ([String]).
/// - [verify]: the email being verified ([String]).
/// - [upgrade]: the story id the share was requested from ([String?]).
/// - all others: no arguments.
abstract final class Routes {
  /// Home tab — the ask flow and stories.
  static const String home = '/';

  /// Story detail. Argument: a story id.
  static const String story = '/story';

  /// Ask tab — the question field and orb.
  static const String ask = '/ask';

  /// Reconstructing — the staged reveal. Argument: the question.
  static const String reconstructing = '/ask/reconstructing';

  /// Reconstructed moment. Argument: a moment id.
  static const String moment = '/moment';

  /// Media library tab — the cutting-room grid.
  static const String library = '/library';

  /// Media detail. Argument: a memory-item id.
  static const String media = '/media';

  /// Story compose. Argument: a story id.
  static const String compose = '/compose';

  /// Chapter edit. Argument: a map with storyId and chapterId.
  static const String chapterEdit = '/chapter-edit';

  /// Timeline tab.
  static const String timeline = '/timeline';

  /// People — on-device face groups.
  static const String people = '/people';

  /// Places — the schematic map.
  static const String places = '/places';

  /// Voice note. Argument: a voice-note id.
  static const String voiceNote = '/voice';

  /// Import queue.
  static const String import = '/import';

  /// Offline mode and storage.
  static const String offline = '/offline';

  /// Share a story. Argument: a story id.
  static const String share = '/share';

  /// Settings — archive rules and storage.
  static const String settings = '/settings';

  /// Resurfaced moment — this week in past years.
  static const String resurface = '/resurface';

  /// First-launch flow (initial route on a first run).
  static const String firstLaunch = '/first-launch';

  /// The payoff — every moment, one question away.
  static const String payoff = '/payoff';

  /// Welcome — guest-first entry.
  static const String welcome = '/welcome';

  /// Guest mode — what works without an account.
  static const String guestMode = '/guest-mode';

  /// Sign in with an email code.
  static const String signIn = '/sign-in';

  /// Create an account.
  static const String createAccount = '/create-account';

  /// Verify the email code. Argument: the email.
  static const String verify = '/verify';

  /// Upgrade prompt — sharing needs an account. Argument: a story id, if any.
  static const String upgrade = '/upgrade';

  /// Migration — guest archive into the account.
  static const String migrate = '/migrate';

  /// Account home tab.
  static const String account = '/account';

  /// Connected import sources.
  static const String connected = '/connected';

  /// Sign out.
  static const String signOut = '/sign-out';
}
