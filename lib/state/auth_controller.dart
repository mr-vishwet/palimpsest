import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/account.dart';
import 'archive_controller.dart';

/// Account flow state: guest-first sign-in, verification, migration,
/// backup/sync toggles and connected sources.
///
/// v0.1 has no backend, so the account is recorded locally and the
/// flows are simulated on-device: any 6-digit code verifies, backup
/// progress advances locally, and sync lists the devices this archive
/// knows about. The UI and README say so plainly; the account state
/// shape is the one a real backend will fill in.
class AuthController extends ChangeNotifier {
  /// Creates the auth controller over the archive.
  AuthController({required this.archive});

  /// The archive holding the account state.
  final ArchiveController archive;

  /// Email waiting for verification, if any.
  String? pendingEmail;

  /// Whether the pending sign-in is a new account (vs returning).
  bool pendingIsNewAccount = false;

  /// Migration progress, 0–1, while the migration screen runs.
  double migrationProgress = 0;

  /// Whether a migration is running.
  bool migrationRunning = false;

  Timer? _migrationTimer;

  /// True when signed in.
  bool get isSignedIn => archive.account.isSignedIn;

  /// True when the guest archive has been migrated into the account.
  bool get migrated => archive.account.migrated;

  /// Begins sign-in (or account creation) for [email]: no email is
  /// sent in v0.1 — the verify screen collects any 6-digit code and
  /// verifies it locally.
  void beginSignIn(String email, {bool isNewAccount = false}) {
    pendingEmail = email.trim();
    pendingIsNewAccount = isNewAccount;
    notifyListeners();
  }

  /// Verifies a 6-digit code. In v0.1 any 6-digit code verifies — the
  /// demo code from the spec is [AppConstants.demoVerifyCode].
  /// Returns true on success.
  bool verifyCode(String code) {
    final clean = code.trim();
    if (clean.length != 6 || int.tryParse(clean) == null) {
      return false;
    }
    final email = pendingEmail;
    if (email == null || email.isEmpty) {
      return false;
    }
    archive.updateAccount(
      archive.account.copyWith(
        status: AccountStatus.signedIn,
        email: email,
      ),
    );
    pendingEmail = null;
    notifyListeners();
    return true;
  }

  /// Starts the guest → account migration: the archive is checked
  /// item by item, then the first backup begins.
  void beginMigration() {
    if (migrationRunning || !isSignedIn) {
      return;
    }
    migrationRunning = true;
    migrationProgress = 0;
    notifyListeners();
    var tick = 0;
    _migrationTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      tick++;
      migrationProgress = (tick / 28).clamp(0, 1).toDouble();
      if (tick >= 28) {
        timer.cancel();
        _finishMigration();
      }
      notifyListeners();
    });
  }

  void _finishMigration() {
    migrationRunning = false;
    migrationProgress = 1;
    archive.updateAccount(
      archive.account.copyWith(
        migrated: true,
        // No backend in this build: migration records the account
        // locally and unlocks nothing yet — backup and sync stay
        // off, no bytes are uploaded, and this device is the only
        // one. (lastBackupAt stays null: there has been no backup.)
        backupEnabled: false,
        syncEnabled: false,
        devices: 1,
        backupUploadedGb: 0,
        backupTotalGb: 0,
      ),
    );
    notifyListeners();
  }

  /// Switches encrypted cloud backup on or off.
  void setBackup(bool enabled) {
    archive.updateAccount(archive.account.copyWith(backupEnabled: enabled));
    notifyListeners();
  }

  /// Switches sync on or off.
  void setSync(bool enabled) {
    archive.updateAccount(archive.account.copyWith(syncEnabled: enabled));
    notifyListeners();
  }

  /// Connects an import source (Photos, Google Photos, iCloud).
  /// Connections pull media in, never push the archive out.
  void connectSource(String name) {
    final sources = archive.account.connectedSources;
    if (sources.contains(name)) {
      return;
    }
    archive.updateAccount(
      archive.account.copyWith(
        connectedSources: <String>[...sources, name],
      ),
    );
    notifyListeners();
  }

  /// Disconnects an import source.
  void disconnectSource(String name) {
    archive.updateAccount(
      archive.account.copyWith(
        connectedSources: archive.account.connectedSources
            .where((s) => s != name)
            .toList(growable: false),
      ),
    );
    notifyListeners();
  }

  /// Signs out. The local archive stays — signing out never deletes
  /// local data. [deleteCloudCopy] also clears the recorded
  /// connected sources; there is no cloud copy in this build, so
  /// nothing is deleted from any server.
  void signOut({bool deleteCloudCopy = false}) {
    archive.updateAccount(
      AccountState(
        status: AccountStatus.guest,
        connectedSources: deleteCloudCopy
            ? const <String>[]
            : archive.account.connectedSources,
      ),
    );
    pendingEmail = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _migrationTimer?.cancel();
    super.dispose();
  }
}
