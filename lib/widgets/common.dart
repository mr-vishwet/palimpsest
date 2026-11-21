import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// A glassmorphic card: translucent surface, hairline border, soft
/// radius — the V7 card language.
class GlassCard extends StatelessWidget {
  /// Creates a glass card.
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Tap handler, if the card is tappable.
  final VoidCallback? onTap;

  /// Border override (defaults to the hairline).
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? palette.hairline),
      ),
      child: child,
    );
    if (onTap == null) {
      return card;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

/// A kicker label above a section, with an optional trailing widget.
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader(this.label, {this.trailing, super.key});

  /// The label text.
  final String label;

  /// Optional trailing widget (e.g. a count or an action).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTheme.kicker()),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A big-number stat tile: "542" over "photos".
class StatTile extends StatelessWidget {
  /// Creates a stat tile.
  const StatTile({required this.value, required this.label, super.key});

  /// The big value.
  final String value;

  /// The small label beneath.
  final String label;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.mono(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

/// The gold → amber gradient primary button.
class GradientButton extends StatelessWidget {
  /// Creates a gradient button.
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    super.key,
  });

  /// Button label.
  final String label;

  /// Press handler.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the button stretches to fill its width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(
                  colors: <Color>[
                    palette.muted.withValues(alpha: 0.4),
                    palette.muted.withValues(alpha: 0.3),
                  ],
                )
              : palette.ctaGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: palette.onGold),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// A small rounded tag chip, optionally removable.
class TagChip extends StatelessWidget {
  /// Creates a tag chip.
  const TagChip(this.tag, {this.onRemove, super.key});

  /// The tag text.
  final String tag;

  /// Remove handler; when null the chip has no remove button.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.glassStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(tag, style: AppTheme.mono(size: 12, color: palette.parchment)),
          if (onRemove != null) ...<Widget>[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small "On-device" / "Demo library" pill.
class StatusPill extends StatelessWidget {
  /// Creates a status pill.
  const StatusPill({required this.label, this.dotColor, super.key});

  /// Pill text.
  final String label;

  /// Dot colour (defaults to green).
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor ?? palette.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.mono(size: 11, color: palette.parchment)),
        ],
      ),
    );
  }
}

/// An empty-state block: icon, title, explanation, optional action.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Icon shown above the title.
  final IconData icon;

  /// Title text.
  final String title;

  /// Explanation text.
  final String body;

  /// Optional action label.
  final String? actionLabel;

  /// Optional action handler.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: palette.muted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: palette.muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              GradientButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
