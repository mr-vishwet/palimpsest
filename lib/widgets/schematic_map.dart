import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/place.dart';

/// The schematic map: places, not streets.
///
/// A dotted warm-charcoal field with one pin per place, positioned by
/// the place's schematic coordinates. Tapping a pin selects it; the
/// parent shows the place's stories.
class SchematicMap extends StatelessWidget {
  /// Creates the schematic map.
  const SchematicMap({
    required this.places,
    required this.selectedId,
    required this.onSelect,
    this.height = 280,
    super.key,
  });

  /// Places to pin.
  final List<Place> places;

  /// Selected place id, or null.
  final String? selectedId;

  /// Called with the place id when a pin is tapped.
  final void Function(String placeId) onSelect;

  /// Map height.
  final double height;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            // Dotted field.
            CustomPaint(
              size: Size.infinite,
              painter: _DotPainter(),
            ),
            // Faint arcs between places — the journeys, not the roads.
            CustomPaint(
              size: Size.infinite,
              painter: _ArcPainter(places),
            ),
            for (final place in places)
              _MapPin(
                place: place,
                selected: place.id == selectedId,
                onTap: () => onSelect(place.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    // Positioned via a LayoutBuilder-free trick: the parent Stack is
    // full-size, so we translate by fractions of an assumed box using
    // Align with fractional alignment.
    return Align(
      alignment: Alignment(place.x * 2 - 1, place.y * 2 - 1),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: selected ? 40 : 32,
              height: selected ? 40 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? palette.gold : palette.bg1,
                border: Border.all(
                  color: selected ? palette.dawn : palette.hairline,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: palette.gold.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.location_on,
                size: 18,
                color: selected ? palette.onGold : palette.parchment,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              place.name,
              style: AppTheme.mono(
                size: 11,
                color: selected ? palette.dawn : palette.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFA8A29E).withValues(alpha: 0.18);
    for (var x = 16.0; x < size.width; x += 28) {
      for (var y = 16.0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.places);

  final List<Place> places;

  @override
  void paint(Canvas canvas, Size size) {
    if (places.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xFFD4A853).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < places.length - 1; i++) {
      final a = Offset(places[i].x * size.width, places[i].y * size.height);
      final b = Offset(places[i + 1].x * size.width, places[i + 1].y * size.height);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 24);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.places != places;
}
