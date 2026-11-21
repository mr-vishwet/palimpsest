/// Whether the archive is being used as a guest or with an account.
///
/// Guest-first: the whole archive works without an account. An account
/// unlocks three things — share links, encrypted cloud backup (your key,
/// your copy) and sync.
enum AccountStatus {
  /// No account; everything local.
  guest,

  /// Signed in; backup, sync and sharing available.
  signedIn,
}

/// The account state: guest or signed in, plus backup/sync status.
///
/// In v0.1 there is no backend, so sign-in, backup and sync are
/// recorded locally and simulated: backup progress advances on-device
/// and sync lists the devices this archive knows about. The README
/// says so plainly.
class AccountState {
  /// Creates an account state.
  const AccountState({
    required this.status,
    this.email,
    this.backupEnabled = false,
    this.syncEnabled = false,
    this.devices = 1,
    this.backupUploadedGb = 0,
    this.backupTotalGb = 0,
    this.lastBackupAt,
    this.connectedSources = const <String>[],
    this.migrated = false,
  });

  /// The guest default: no account, everything local.
  factory AccountState.guest() => const AccountState(status: AccountStatus.guest);

  /// Rebuilds an account state from stored JSON.
  factory AccountState.fromJson(Map<String, Object?> json) => AccountState(
        status: AccountStatus.values.byName(json['status'] as String),
        email: json['email'] as String?,
        backupEnabled: json['backupEnabled'] as bool? ?? false,
        syncEnabled: json['syncEnabled'] as bool? ?? false,
        devices: json['devices'] as int? ?? 1,
        backupUploadedGb: (json['backupUploadedGb'] as num?)?.toDouble() ?? 0,
        backupTotalGb: (json['backupTotalGb'] as num?)?.toDouble() ?? 0,
        lastBackupAt: json['lastBackupAt'] == null
            ? null
            : DateTime.parse(json['lastBackupAt'] as String),
        connectedSources:
            (json['connectedSources'] as List<dynamic>?)?.cast<String>() ??
                const <String>[],
        migrated: json['migrated'] as bool? ?? false,
      );

  /// Guest or signed in.
  final AccountStatus status;

  /// Account email when signed in.
  final String? email;

  /// Encrypted cloud backup switched on.
  final bool backupEnabled;

  /// Sync across devices switched on.
  final bool syncEnabled;

  /// Devices syncing this archive.
  final int devices;

  /// GB uploaded in the current/last backup.
  final double backupUploadedGb;

  /// Total GB the backup covers.
  final double backupTotalGb;

  /// When the last backup finished.
  final DateTime? lastBackupAt;

  /// Connected import sources, e.g. `Photos`, `Google Photos`.
  /// Connections pull media in, never push the archive out.
  final List<String> connectedSources;

  /// True once the guest archive has been migrated into the account.
  final bool migrated;

  /// True when signed in.
  bool get isSignedIn => status == AccountStatus.signedIn;

  /// Backup progress 0–1 (1 when nothing to back up).
  double get backupProgress =>
      backupTotalGb <= 0 ? 1 : (backupUploadedGb / backupTotalGb).clamp(0, 1);

  /// Serializes the account state for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'status': status.name,
        'email': email,
        'backupEnabled': backupEnabled,
        'syncEnabled': syncEnabled,
        'devices': devices,
        'backupUploadedGb': backupUploadedGb,
        'backupTotalGb': backupTotalGb,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
        'connectedSources': connectedSources,
        'migrated': migrated,
      };

  /// Returns a copy with the given fields replaced.
  AccountState copyWith({
    AccountStatus? status,
    String? email,
    bool? backupEnabled,
    bool? syncEnabled,
    int? devices,
    double? backupUploadedGb,
    double? backupTotalGb,
    DateTime? lastBackupAt,
    List<String>? connectedSources,
    bool? migrated,
  }) =>
      AccountState(
        status: status ?? this.status,
        email: email ?? this.email,
        backupEnabled: backupEnabled ?? this.backupEnabled,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        devices: devices ?? this.devices,
        backupUploadedGb: backupUploadedGb ?? this.backupUploadedGb,
        backupTotalGb: backupTotalGb ?? this.backupTotalGb,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        connectedSources: connectedSources ?? this.connectedSources,
        migrated: migrated ?? this.migrated,
      );
}

/// Archive rules and data controls (Settings screen).
class ArchiveSettings {
  /// Creates archive settings.
  const ArchiveSettings({
    this.fullQuality = true,
    this.onDeviceGrouping = true,
    this.localTranscription = true,
    this.groupingOnlyWhenCharging = true,
    this.resurfaceEnabled = true,
    this.offlineMode = false,
  });

  /// Rebuilds settings from stored JSON.
  factory ArchiveSettings.fromJson(Map<String, Object?> json) =>
      ArchiveSettings(
        fullQuality: json['fullQuality'] as bool? ?? true,
        onDeviceGrouping: json['onDeviceGrouping'] as bool? ?? true,
        localTranscription: json['localTranscription'] as bool? ?? true,
        groupingOnlyWhenCharging:
            json['groupingOnlyWhenCharging'] as bool? ?? true,
        resurfaceEnabled: json['resurfaceEnabled'] as bool? ?? true,
        offlineMode: json['offlineMode'] as bool? ?? false,
      );

  /// Keep originals at full quality (never recompress on import).
  final bool fullQuality;

  /// Group faces on-device (never on a server).
  final bool onDeviceGrouping;

  /// Transcribe voice notes locally.
  final bool localTranscription;

  /// Run face grouping only while charging.
  final bool groupingOnlyWhenCharging;

  /// Show "this week in past years" resurfaced moments.
  final bool resurfaceEnabled;

  /// Offline mode: cloud actions (share, backup, sync) are disabled
  /// and the archive works entirely on-device.
  final bool offlineMode;

  /// Serializes the settings for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'fullQuality': fullQuality,
        'onDeviceGrouping': onDeviceGrouping,
        'localTranscription': localTranscription,
        'groupingOnlyWhenCharging': groupingOnlyWhenCharging,
        'resurfaceEnabled': resurfaceEnabled,
        'offlineMode': offlineMode,
      };

  /// Returns a copy with the given fields replaced.
  ArchiveSettings copyWith({
    bool? fullQuality,
    bool? onDeviceGrouping,
    bool? localTranscription,
    bool? groupingOnlyWhenCharging,
    bool? resurfaceEnabled,
    bool? offlineMode,
  }) =>
      ArchiveSettings(
        fullQuality: fullQuality ?? this.fullQuality,
        onDeviceGrouping: onDeviceGrouping ?? this.onDeviceGrouping,
        localTranscription: localTranscription ?? this.localTranscription,
        groupingOnlyWhenCharging:
            groupingOnlyWhenCharging ?? this.groupingOnlyWhenCharging,
        resurfaceEnabled: resurfaceEnabled ?? this.resurfaceEnabled,
        offlineMode: offlineMode ?? this.offlineMode,
      );
}
