import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/archive_controller.dart';
import '../state/ask_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';
import '../widgets/memory_orb.dart';

/// Reconstructing (m04 / w04): the orb mid-bob, the ring mid-fill —
/// the archive shows its working as it goes, then lands on the
/// reconstructed moment.
class ReconstructingScreen extends StatefulWidget {
  /// Creates the reconstructing screen.
  const ReconstructingScreen({required this.query, super.key});

  /// The question being answered.
  final String query;

  @override
  State<ReconstructingScreen> createState() => _ReconstructingScreenState();
}

class _ReconstructingScreenState extends State<ReconstructingScreen> {
  bool _navigated = false;
  AskController? _ask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The controller is captured here (not looked up in dispose,
      // where depending on an InheritedWidget is illegal).
      final ask = AppScope.of(context).ask;
      _ask = ask;
      ask.addListener(_onAskChanged);
      // Deep link safety: if nothing is in flight, start it now.
      if (ask.phase == AskPhase.idle) {
        ask.start(widget.query);
      }
    });
  }

  @override
  void dispose() {
    _ask?.removeListener(_onAskChanged);
    super.dispose();
  }

  void _onAskChanged() {
    final ask = _ask;
    if (ask == null || !mounted) {
      return;
    }
    if (ask.phase == AskPhase.done && !_navigated && ask.result != null) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(
        Routes.moment,
        arguments: ask.result!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ask = AppScope.of(context).ask;
    final archive = AppScope.of(context).archive;
    return ResponsiveScaffold(
      title: 'Ask',
      tabIndex: 1,
      showNav: false,
      mobile: _body(context, ask, archive, wide: false),
      wide: _body(context, ask, archive, wide: true),
    );
  }

  Widget _body(
    BuildContext context,
    AskController ask,
    ArchiveController archive, {
    required bool wide,
  }) {
    return ListenableBuilder(
      listenable: ask,
      builder: (context, _) {
        final total = ask.total;
        final found = ask.revealedAnchors;
        final rising = <Widget>[
          for (final anchor in found.take(3))
            if (archive.itemById(anchor.itemId) != null)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: FrameTile(
                    item: archive.itemById(anchor.itemId)!,
                    onTap: () {},
                  ),
                ),
              ),
        ];
        final content = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('The question, being answered', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Reconstructing\nthe moment…',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '“${widget.query}”',
                style: AppTheme.mono(size: 12, color: Palette.v7.parchment),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const MemoryOrb(size: 110),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ProgressRing(
                      progress: ask.progress,
                      label: '${ask.gathered}',
                      subLabel: 'of $total items',
                      size: 120,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Found so far', style: AppTheme.kicker()),
                    const SizedBox(height: 8),
                    if (found.isEmpty)
                      Text(
                        'Searching the index…',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      for (final anchor in found)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Palette.v7.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(anchor.label)),
                            ],
                          ),
                        ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Palette.v7.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ask.progress < 1
                                ? 'Gathering the last ${total - ask.gathered} items…'
                                : 'Putting the moment together…',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: ask.progress,
                      color: Palette.v7.gold,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ask.gathered} of $total items gathered · ${(ask.progress * 100).round()}%',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
              if (rising.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < rising.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 8),
                      rising[i],
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Rebuilding on-device · typically under a second · nothing leaves the phone',
                  style: AppTheme.mono(size: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
        return content;
      },
    );
  }
}
