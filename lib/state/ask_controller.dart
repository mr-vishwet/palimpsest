import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/reconstructor.dart';
import '../models/ask_result.dart';
import 'archive_controller.dart';

/// Where the ask flow is.
enum AskPhase {
  /// No question in flight.
  idle,

  /// Reconstructing — the staged reveal is playing.
  reconstructing,

  /// The moment is rebuilt and stored.
  done,
}

/// The ask flow: question → reconstructing → reconstructed moment.
///
/// The reconstruction itself is fast (a local index search, typically
/// a few milliseconds). The reconstructing screen stages the reveal —
/// anchors appear one by one, the ring fills — so the user sees the
/// archive working. The moment is only stored once the reveal
/// completes.
class AskController extends ChangeNotifier {
  /// Creates the ask controller over the archive.
  AskController({required this.archive});

  /// The archive the questions run against.
  final ArchiveController archive;

  /// Current phase.
  AskPhase phase = AskPhase.idle;

  /// The question in flight.
  String query = '';

  /// Reveal progress, 0–1.
  double progress = 0;

  /// Items gathered so far in the staged reveal.
  int gathered = 0;

  /// Total items in the rebuilt moment.
  int total = 0;

  /// Anchor finds revealed so far.
  List<AnchorFind> revealedAnchors = const <AnchorFind>[];

  /// The rebuilt moment, once the phase is [AskPhase.done].
  ReconstructedMoment? result;

  Timer? _timer;
  ReconstructedMoment? _pending;
  List<AnchorFind> _anchors = const <AnchorFind>[];

  /// Starts a reconstruction for [question].
  void start(String question) {
    _timer?.cancel();
    query = question;
    phase = AskPhase.reconstructing;
    progress = 0;
    gathered = 0;
    revealedAnchors = const <AnchorFind>[];
    result = null;

    _pending = Reconstructor.reconstruct(question, archive.data);
    total = _pending!.itemIds.length;
    _anchors = Reconstructor.anchorFinds(_pending!, archive.items);

    // Staged reveal: ~1.6s, anchors appearing as the ring fills.
    var tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      tick++;
      progress = (tick / 16).clamp(0, 1).toDouble();
      gathered = (total * progress).round().clamp(0, total).toInt();
      final anchorsToShow = (progress * _anchors.length).ceil().clamp(0, _anchors.length).toInt();
      revealedAnchors = _anchors.sublist(0, anchorsToShow);
      if (tick >= 16) {
        timer.cancel();
        _finish();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Resets the flow to idle.
  void reset() {
    _timer?.cancel();
    phase = AskPhase.idle;
    query = '';
    progress = 0;
    gathered = 0;
    total = 0;
    revealedAnchors = const <AnchorFind>[];
    result = null;
    _pending = null;
    notifyListeners();
  }

  void _finish() {
    final moment = _pending;
    if (moment == null) {
      phase = AskPhase.idle;
      notifyListeners();
      return;
    }
    archive.addMoment(moment);
    result = moment;
    phase = AskPhase.done;
    progress = 1;
    gathered = total;
    revealedAnchors = _anchors;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
