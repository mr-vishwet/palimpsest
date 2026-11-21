/// App-wide constants: the demo archive's headline numbers and the
/// canonical content carried forward from the V7 design spec.
///
/// Everything here is demo-seed data for the v0.1 build — the seeded
/// library is a curated subset of a life archive, and the headline totals
/// are the demo archive's numbers, labelled as such in the UI.
abstract final class AppConstants {
  /// Demo archive headline totals (the seeded library's story).
  static const int totalPhotos = 5012;

  /// Videos in the demo archive.
  static const int totalVideos = 143;

  /// Voice notes in the demo archive.
  static const int totalVoiceNotes = 9;

  /// Stories in the demo archive.
  static const int totalStories = 4;

  /// Storage used by the demo archive, in GB.
  static const double storageUsedGb = 18.4;

  /// Total device storage, in GB.
  static const double storageTotalGb = 128;

  /// Storage used by thumbnails and the search index, in GB.
  static const double thumbnailsAndIndexGb = 1.2;

  /// Bytes uploaded to any server — always zero; the archive is local-first.
  static const int uploadedBytes = 0;

  /// The canonical ask — the hero question from the V7 spec.
  static const String canonicalAsk =
      'Show me everything from the weekend when I first started '
      'working on that project';

  /// Questions that work, shown on the Ask screen.
  static const List<({String question, String hint})> suggestedQuestions = [
    (
      question: 'The weekend the project started',
      hint: 'First sketch, first voice note, first cut',
    ),
    (
      question: 'Every birthday with Dad in it',
      hint: 'Childhood · moments with Dad',
    ),
    (
      question: 'The last day of the cruise',
      hint: 'Wedding Cruise · day 14',
    ),
    (
      question: 'Rain, anywhere, any year',
      hint: 'All stories · tagged rain',
    ),
  ];

  /// Aspect ratios tracked by the cutting-room library.
  static const List<String> aspectRatios = ['1.85:1', '2.39:1', '4:3', '1:1'];

  /// Share links expire after this many days.
  static const int shareLinkExpiryDays = 30;

  /// Verification codes are simulated locally in v0.1 (no backend):
  /// any 6-digit code verifies. The demo code from the spec is 428195.
  static const String demoVerifyCode = '428195';

  /// How long a verification code stays valid, in minutes.
  static const int verifyCodeValidityMinutes = 10;

  /// Import batch size for the demo import queue.
  static const int importBatchSize = 1204;

  /// Items already indexed in the seeded import queue.
  static const int importSeededIndexed = 842;

  /// Breakpoint: at or above this width a screen uses its wide (web)
  /// layout; below it, the mobile layout.
  static const double wideBreakpoint = 900;

  /// Max content width for wide layouts.
  static const double wideMaxWidth = 1100;
}
