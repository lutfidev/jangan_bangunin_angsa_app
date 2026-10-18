import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/palette.dart';

/// Ink stroke icons on a 24×24 grid, as drawn in the design.
enum GameIcon {
  play('<path d="M6 3 L21 12 L6 21 Z" fill="{c}" stroke="{c}" stroke-width="2"/>'),
  moon('<path d="M20 14 A8 8 0 1 1 10 4 A6 6 0 0 0 20 14 Z"/>'),
  trophy(
    '<path d="M7 4 H17 V9 A5 5 0 0 1 7 9 Z M7 6 H4 A3 3 0 0 0 7 11 M17 6 H20 A3 3 0 0 1 17 11 M12 14 V18 M8 20 H16"/>',
  ),
  gear(
    '<circle cx="12" cy="12" r="3"/><path d="M12 2 V5 M12 19 V22 M2 12 H5 M19 12 H22 M4.9 4.9 L7 7 M17 17 L19.1 19.1 M4.9 19.1 L7 17 M17 7 L19.1 4.9"/>',
  ),
  back('<path d="M15 5 L8 12 L15 19"/>'),
  arrow('<path d="M4 12 H20 M14 6 L20 12 L14 18"/>'),
  retry('<path d="M4 12 A8 8 0 1 0 7 5.7 M4 3 V8 H9"/>'),
  home('<path d="M3 11 L12 4 L21 11 M6 9 V20 H18 V9"/>'),
  check('<path d="M4 12 L10 18 L20 6"/>'),
  eye('<circle cx="12" cy="12" r="3"/><path d="M2 12 Q12 3 22 12 Q12 21 2 12 Z"/>'),
  grab(
    '<path d="M8 13 V5 A1.5 1.5 0 0 1 11 5 V11 M11 10 V3.5 A1.5 1.5 0 0 1 14 3.5 V11 M14 10 V5 A1.5 1.5 0 0 1 17 5 V12 M17 9 A1.5 1.5 0 0 1 20 9 V14 A7 7 0 0 1 13 21 H12 A6 6 0 0 1 6.5 17.5 L4 13 A1.5 1.5 0 0 1 6.5 11.5 L8 13"/>',
  );

  const GameIcon(this.body);

  final String body;
}

class Glyph extends StatelessWidget {
  const Glyph(
    this.icon, {
    super.key,
    this.size = 18,
    this.strokeWidth = 2.6,
    this.color = Palette.ink,
  });

  final GameIcon icon;
  final double size;
  final double strokeWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = _hex(color);
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="$hex" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">${icon.body.replaceAll('{c}', hex)}</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// The sock mark used for heist goals and the tool button.
class SockGlyph extends StatelessWidget {
  const SockGlyph({
    super.key,
    required this.fill,
    this.size = 22,
    this.stroke = Palette.ink,
  });

  final Color fill;
  final Color stroke;
  final double size;

  @override
  Widget build(BuildContext context) {
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
        '<path d="M40 14 L64 14 L64 58 Q64 80 44 84 L24 86 Q12 86 12 74 Q12 64 24 62 L40 60 Z" '
        'fill="${_hex(fill)}" stroke="${_hex(stroke)}" stroke-width="7" stroke-linejoin="round"/></svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
