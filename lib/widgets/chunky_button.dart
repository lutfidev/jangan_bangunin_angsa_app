import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/icons.dart';
import '../state/game_settings.dart';
import '../theme/palette.dart';
import '../theme/type.dart';

/// The selection ring drawn around a picked tile: a coloured halo inside an
/// ink outline that keeps the hard drop.
List<BoxShadow> ringShadows({
  Color color = Palette.lamp,
  double width = 4,
  double outline = 2,
  double drop = 4,
}) => [
  BoxShadow(color: Palette.ink, offset: Offset(0, drop), spreadRadius: width + outline),
  BoxShadow(color: color, spreadRadius: width),
];

/// Chunky, tactile button: ink outline, hard ink drop shadow, and a press
/// that drops it into its shadow (80ms) with a light haptic.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = Palette.gooseWhite,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.radius,
    this.borderWidth = 3,
    this.borderColor = Palette.ink,
    this.depth = 4,
    this.shadows,
    this.semanticLabel,
    this.selected,
  });

  /// Primary call to action: Lamp pill with display lettering.
  factory ChunkyButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    GameIcon? icon,
    GameIcon? trailingIcon,
    double height = 64,
    double fontSize = 24,
    double? width,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 30),
    double depth = 5,
    double iconSize = 20,
  }) => ChunkyButton(
    key: key,
    onPressed: onPressed,
    color: Palette.lamp,
    height: height,
    width: width,
    padding: padding,
    depth: depth,
    child: _Label(
      label: label,
      style: display(fontSize),
      icon: icon,
      trailingIcon: trailingIcon,
      iconSize: iconSize,
      iconStroke: 3.5,
      gap: 10,
    ),
  );

  /// Secondary action: Goose White pill with a bold UI label.
  factory ChunkyButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    GameIcon? icon,
    double height = 56,
    double fontSize = 16,
    double? width,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 22),
    double depth = 4,
    double iconSize = 18,
    double iconStroke = 2.6,
  }) => ChunkyButton(
    key: key,
    onPressed: onPressed,
    height: height,
    width: width,
    padding: padding,
    depth: depth,
    child: _Label(
      label: label,
      style: ui(fontSize, weight: FontWeight.w800),
      icon: icon,
      iconSize: iconSize,
      iconStroke: iconStroke,
      gap: 8,
    ),
  );

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  /// Corner radius; null draws a pill (or a circle when square).
  final double? radius;
  final double borderWidth;
  final Color borderColor;
  final double depth;

  /// Overrides the default drop shadow, e.g. with [ringShadows].
  final List<BoxShadow>? shadows;
  final String? semanticLabel;

  /// Non-null for toggle-style buttons; exposed to assistive tech.
  final bool? selected;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _setDown(bool down) {
    if (widget.onPressed == null || down == _down) return;
    if (down && GameSettings.instance.haptics) HapticFeedback.lightImpact();
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final sink = _down ? widget.depth - 1 : 0.0;
    final shadows =
        widget.shadows ??
        [
          BoxShadow(
            color: Palette.ink,
            offset: Offset(0, _down ? 1 : widget.depth),
          ),
        ];
    final shape = widget.radius == null
        ? BorderRadius.circular(999)
        : BorderRadius.circular(widget.radius!);

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, sink, 0),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: shape,
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            boxShadow: shadows,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.style,
    required this.iconSize,
    required this.iconStroke,
    required this.gap,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final TextStyle style;
  final GameIcon? icon;
  final GameIcon? trailingIcon;
  final double iconSize;
  final double iconStroke;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        if (icon != null)
          Glyph(icon!, size: iconSize, strokeWidth: iconStroke),
        Text(label, style: style),
        if (trailingIcon != null)
          Glyph(trailingIcon!, size: iconSize, strokeWidth: iconStroke),
      ],
    );
  }
}

/// Round Goose White icon button (back, pause, settings). 48dp default.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.icon,
    this.child,
    this.size = 48,
    this.depth = 3,
    this.iconSize = 20,
    this.iconStroke = 3,
  }) : assert(icon != null || child != null);

  final VoidCallback? onPressed;
  final String semanticLabel;
  final GameIcon? icon;
  final Widget? child;
  final double size;
  final double depth;
  final double iconSize;
  final double iconStroke;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      width: size,
      height: size,
      depth: depth,
      child:
          child ?? Glyph(icon!, size: iconSize, strokeWidth: iconStroke),
    );
  }
}

/// The two-bar pause glyph.
class PauseBars extends StatelessWidget {
  const PauseBars({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
      width: 6,
      height: 18,
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [bar(), bar()],
    );
  }
}
