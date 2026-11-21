import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_field.dart';
import '../widgets/common.dart';
import '../widgets/memory_orb.dart';

/// Ask (m03 / w03): the question in plain words, the memory orb, and
/// four questions that work.
class AskScreen extends StatelessWidget {
  /// Creates the ask screen.
  const AskScreen({super.key});

  void _ask(BuildContext context, String question) {
    final scope = AppScope.of(context);
    scope.ask.start(question);
    Navigator.of(context).pushNamed(
      Routes.reconstructing,
      arguments: question,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('The question rebuilds the moment', style: AppTheme.kicker()),
          const SizedBox(height: 6),
          Text(
            'Ask the archive',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Plain words. The archive answers with the collection — nothing leaves the device.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Palette.v7.parchment),
          ),
          const SizedBox(height: 20),
          const Center(child: MemoryOrb(size: 110)),
          const SizedBox(height: 20),
          AskField(
            initialValue: AppConstants.canonicalAsk,
            onAsk: (q) => _ask(context, q),
          ),
          const SizedBox(height: 20),
          Text('Questions that work', style: AppTheme.kicker()),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: <Widget>[
                for (final suggestion in AppConstants.suggestedQuestions)
                  InkWell(
                    onTap: () => _ask(context, suggestion.question),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: V7Colors.parchment,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  suggestion.question,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  suggestion.hint,
                                  style: AppTheme.mono(size: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: V7Colors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Search runs on the device index — titles, tags, captions, people, places and voice-note transcripts. No account, no upload, no waiting on a server. The median rebuild is under a second.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Palette.v7.muted),
          ),
        ],
      ),
    );

    final wideBody = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('The question rebuilds the moment', style: AppTheme.kicker()),
                const SizedBox(height: 6),
                Text(
                  'Ask the archive',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                const Center(child: MemoryOrb(size: 130)),
                const SizedBox(height: 20),
                AskField(
                  initialValue: AppConstants.canonicalAsk,
                  onAsk: (q) => _ask(context, q),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Questions that work', style: AppTheme.kicker()),
                const SizedBox(height: 8),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: <Widget>[
                      for (final suggestion in AppConstants.suggestedQuestions)
                        InkWell(
                          onTap: () => _ask(context, suggestion.question),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: V7Colors.parchment,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        suggestion.question,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      Text(
                                        suggestion.hint,
                                        style: AppTheme.mono(size: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: V7Colors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'How the archive answers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Every item in the library is indexed on-device by title, tag, caption, person, place and — for voice notes — transcript. A question is matched against that index, the hits are ordered chronologically, and each one carries the reason it is there. No mystery, no magic.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return ResponsiveScaffold(
      title: 'Ask',
      tabIndex: 1,
      mobile: body,
      wide: wideBody,
    );
  }
}
