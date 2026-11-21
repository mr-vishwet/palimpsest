/// A view-only share link for a story.
///
/// Sharing needs an account: the link has to live somewhere. Links are
/// view-only with downloads off by default, and expire after 30 days.
/// In v0.1 links are recorded locally (no backend); the URL shape is
/// the one the hosted service will use.
class ShareLink {
  /// Creates a share link.
  const ShareLink({
    required this.id,
    required this.storyId,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.downloadsAllowed,
    this.viewCount = 0,
  });

  /// Rebuilds a share link from stored JSON.
  factory ShareLink.fromJson(Map<String, Object?> json) => ShareLink(
        id: json['id'] as String,
        storyId: json['storyId'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        downloadsAllowed: json['downloadsAllowed'] as bool,
        viewCount: json['viewCount'] as int? ?? 0,
      );

  /// Stable id.
  final String id;

  /// The shared story.
  final String storyId;

  /// Short code forming the link URL.
  final String code;

  /// When the link was created.
  final DateTime createdAt;

  /// When the link stops working.
  final DateTime expiresAt;

  /// Whether recipients may download (off by default).
  final bool downloadsAllowed;

  /// Recorded views (0 in v0.1 — no backend counts them yet).
  final int viewCount;

  /// The shareable URL.
  String get url => 'https://palimpsest.app/s/$code';

  /// True when the link has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whole days left until expiry (0 when expired).
  int get daysLeft {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Serializes the link for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'storyId': storyId,
        'code': code,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'downloadsAllowed': downloadsAllowed,
        'viewCount': viewCount,
      };

  /// Returns a copy with the given fields replaced.
  ShareLink copyWith({bool? downloadsAllowed}) => ShareLink(
        id: id,
        storyId: storyId,
        code: code,
        createdAt: createdAt,
        expiresAt: expiresAt,
        downloadsAllowed: downloadsAllowed ?? this.downloadsAllowed,
        viewCount: viewCount,
      );
}
