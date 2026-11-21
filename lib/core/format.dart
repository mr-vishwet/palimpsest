/// Formatting helpers for counts, durations and dates.
///
/// Pure functions, no widget dependencies — covered by unit tests where
/// the formatting carries meaning (play-time sums, storage).
abstract final class Format {
  /// 5012 → "5,012".
  static String count(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Seconds → "4:52". Hours included when needed: 3723 → "1:02:03".
  static String duration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }

  /// "542 photos · 18 videos" — omits zero counts.
  static String mediaCounts({required int photos, required int videos}) {
    final parts = <String>[];
    if (photos > 0) {
      parts.add('$photos ${photos == 1 ? 'photo' : 'photos'}');
    }
    if (videos > 0) {
      parts.add('$videos ${videos == 1 ? 'video' : 'videos'}');
    }
    if (parts.isEmpty) {
      return 'No media yet';
    }
    return parts.join(' · ');
  }

  /// "18.4 GB of 128 GB".
  static String storage(double usedGb, double totalGb) =>
      '${usedGb.toStringAsFixed(1)} GB of ${totalGb.toStringAsFixed(0)} GB';

  /// "Sat 09:12" style short timestamp for frames and finds.
  static String shortTimestamp(DateTime at) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${weekdays[at.weekday - 1]} $hh:$mm';
  }

  /// "Day 1 · 19:04" for a moment inside a story.
  static String dayAndTime(int day, DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return 'Day $day · $hh:$mm';
  }
}
