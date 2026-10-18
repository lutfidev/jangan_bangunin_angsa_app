import 'package:flutter/widgets.dart';

import '../theme/palette.dart';

/// Display type on dark grounds: an ink stroke behind the fill plus a hard
/// ink drop.
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.stroke = 3,
    this.drop = 0,
  });

  final String text;
  final TextStyle style;
  final double stroke;
  final double drop;

  @override
  Widget build(BuildContext context) {
    final outline = style.copyWith(
      color: null,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.ink,
    );
    return Stack(
      children: [
        if (drop > 0)
          Transform.translate(
            offset: Offset(0, drop),
            child: Stack(
              children: [
                Text(text, style: outline),
                Text(text, style: style.copyWith(color: Palette.ink)),
              ],
            ),
          ),
        Text(text, style: outline),
        Text(text, style: style),
      ],
    );
  }
}
