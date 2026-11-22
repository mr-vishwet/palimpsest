/// App-wide constants: layout breakpoints, share-link expiry and the
/// local verification-code rules.
///
/// Headline totals (photo/video counts, storage figures) are NOT here:
/// they are derived from the real archive wherever they appear, so a
/// fresh archive honestly shows zero instead of a hardcoded number.
abstract final class AppConstants {
  /// Aspect ratios tracked by the cutting-room library.
  static const List<String> aspectRatios = ['1.85:1', '2.39:1', '4:3', '1:1'];

  /// Share links expire after this many days.
  static const int shareLinkExpiryDays = 30;

  /// Verification codes are simulated locally in v0.1 (no backend):
  /// any 6-digit code verifies. The demo code from the spec is 428195.
  static const String demoVerifyCode = '428195';

  /// How long a verification code stays valid, in minutes.
  static const int verifyCodeValidityMinutes = 10;

  /// Breakpoint: at or above this width a screen uses its wide (web)
  /// layout; below it, the mobile layout.
  static const double wideBreakpoint = 900;

  /// Max content width for wide layouts.
  static const double wideMaxWidth = 1100;
}
