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
  static const String home = '/';
  static const String story = '/story';
  static const String ask = '/ask';
  static const String reconstructing = '/ask/reconstructing';
  static const String moment = '/moment';
  static const String library = '/library';
  static const String media = '/media';
  static const String compose = '/compose';
  static const String chapterEdit = '/chapter-edit';
  static const String timeline = '/timeline';
  static const String people = '/people';
  static const String places = '/places';
  static const String voiceNote = '/voice';
  static const String import = '/import';
  static const String offline = '/offline';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String resurface = '/resurface';
  static const String firstLaunch = '/first-launch';
  static const String payoff = '/payoff';
  static const String welcome = '/welcome';
  static const String guestMode = '/guest-mode';
  static const String signIn = '/sign-in';
  static const String createAccount = '/create-account';
  static const String verify = '/verify';
  static const String upgrade = '/upgrade';
  static const String migrate = '/migrate';
  static const String account = '/account';
  static const String connected = '/connected';
  static const String signOut = '/sign-out';
}
