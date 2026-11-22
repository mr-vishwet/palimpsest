import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_field.dart';
import '../widgets/common.dart';
import '../widgets/memory_orb.dart';

/// Ask (m03 / w03): the question in plain words, the memory orb, and
/// suggestions derived from the real archive — the tags the library
/// actually has. The field starts empty; on an empty archive the
/// screen says to import first.
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

  /// The most-used tags in the archive, as askable suggestions:
  /// a tag asked as a question searches the index for it. At most
  /// four, most frequent first (ties alphabetical, so the order is
  /// stable).
  List<({String tag, int count})> _tagSuggestions(
    List<MemoryItem> items,
  ) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final tag in item.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList(growable: false)
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return ranked
        .take(4)
        .map((e) => (tag: e.key, count: e.value))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final isEmpty = archive.items.isEmpty;
        final suggestions = _tagSuggestions(archive.items);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('The question rebuilds the moment',
                  style: AppTheme.kicker()),
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
              AskField(onAsk: (q) => _ask(context, q)),
              const SizedBox(height: 20),
              if (isEmpty)
                _ImportFirstHint()
              else if (suggestions.isNotEmpty)
                _SuggestionsCard(
                  suggestions: suggestions,
                  onAsk: (q) => _ask(context, q),
                )
              else
                const _AskHint(),
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
                    Text('The question rebuilds the moment',
                        style: AppTheme.kicker()),
                    const SizedBox(height: 6),
                    Text(
                      'Ask the archive',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    const Center(child: MemoryOrb(size: 130)),
                    const SizedBox(height: 20),
                    AskField(onAsk: (q) => _ask(context, q)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (isEmpty)
                      _ImportFirstHint()
                    else if (suggestions.isNotEmpty)
                      _SuggestionsCard(
                        suggestions: suggestions,
                        onAsk: (q) => _ask(context, q),
                      )
                    else
                      const _AskHint(),
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
      },
    );
  }
}

/// The empty-archive hint: there is nothing to ask about yet, so the
/// honest next step is importing.
class _ImportFirstHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.v7.gold.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Nothing to ask about yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Your archive is empty — import photos first, then ask '
            'about them here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Import photos & videos',
            expanded: true,
            onPressed: () => Navigator.of(context).pushNamed(Routes.import),
          ),
        ],
      ),
    );
  }
}

/// Suggestions derived from the archive's own tags.
class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({
    required this.suggestions,
    required this.onAsk,
  });

  final List<({String tag, int count})> suggestions;
  final void Function(String question) onAsk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Questions that work', style: AppTheme.kicker()),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: <Widget>[
              for (final suggestion in suggestions)
                InkWell(
                  onTap: () => onAsk(suggestion.tag),
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
                                suggestion.tag,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${suggestion.count} '
                                '${suggestion.count == 1 ? 'item' : 'items'} tagged ${suggestion.tag}',
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
      ],
    );
  }
}

/// The hint shown when the archive has items but none carry tags:
/// suggestions need tags to derive from.
class _AskHint extends StatelessWidget {
  const _AskHint();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        'Ask about a person, a place, a date, or a word in a title or '
        'caption — the archive searches all of them.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
