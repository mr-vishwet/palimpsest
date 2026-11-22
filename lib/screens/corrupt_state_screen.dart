import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../widgets/common.dart';

/// Recovery screen for an archive that exists on-device but cannot
/// be read (the database unreachable, or the stored document
/// corrupt). Shown instead of the app — starting the app on a failed
/// read would persist an empty archive over the user's data.
///
/// Retry re-attempts the load. Start fresh deletes the stored
/// archive and starts empty; it is the last resort, and the screen
/// says so plainly.
class CorruptStateScreen extends StatelessWidget {
  /// Creates the recovery screen.
  const CorruptStateScreen({
    required this.detail,
    required this.onRetry,
    required this.onStartFresh,
    super.key,
  });

  /// What went wrong, in user-facing words.
  final String detail;

  /// Re-attempts loading the archive.
  final VoidCallback onRetry;

  /// Deletes the stored archive and starts empty.
  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Your archive couldn’t be opened',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Text(
                      'Something is stored on this device, but it couldn’t be read. '
                      'Nothing has been deleted — the app stopped here rather than '
                      'starting empty over your archive.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: AppTheme.mono(size: 11),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Try again',
                      expanded: true,
                      onPressed: onRetry,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _confirmStartFresh(context),
                      child: const Text('Start fresh — delete the stored archive'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmStartFresh(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete the stored archive?'),
        content: const Text(
          'This deletes everything stored on this device — photos, videos, '
          'stories, voice notes and edits — and starts with an empty archive. '
          'There is no undo, and there is no cloud copy to restore from.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onStartFresh();
            },
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
  }
}
