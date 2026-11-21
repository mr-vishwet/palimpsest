import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// The question field: a large glass input with an Ask action.
///
/// The primary action of the app — on Home and on the Ask screen.
/// Submitting calls [onAsk] with the trimmed question.
class AskField extends StatefulWidget {
  /// Creates the ask field.
  const AskField({
    required this.onAsk,
    this.initialValue = '',
    this.autofocus = false,
    super.key,
  });

  /// Called with the question when the user asks.
  final void Function(String question) onAsk;

  /// Initial text (e.g. the canonical question on the Ask screen).
  final String initialValue;

  /// Whether to focus the field on first build.
  final bool autofocus;

  @override
  State<AskField> createState() => _AskFieldState();
}

class _AskFieldState extends State<AskField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      return;
    }
    widget.onAsk(question);
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return Container(
      decoration: BoxDecoration(
        color: palette.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.gold.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.gold.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _ask(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Ask for a moment…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'On-device · nothing leaves the phone',
                  style: AppTheme.mono(size: 11),
                ),
                TextButton.icon(
                  onPressed: _ask,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ask'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
