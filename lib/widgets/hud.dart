import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'dashed_outline.dart';

/// A small rounded badge: HUD chips, tags, captions.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = Palette.gooseWhite,
    this.textStyle,
    this.borderColor = Palette.ink,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.radius = 999,
    this.leading,
  });

  final String text;
  final Color color;
  final TextStyle? textStyle;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final double radius;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: textStyle ?? ui(11, weight: FontWeight.w800),
    );
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: borderWidth == 0
            ? null
            : Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: leading == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [leading!, label],
            ),
    );
  }
}

/// Numbered chain-link badge.
class LinkBadge extends StatelessWidget {
  const LinkBadge(
    this.number, {
    super.key,
    required this.color,
    this.size = 22,
    this.textColor = Palette.ink,
  });

  final int number;
  final Color color;
  final Color textColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.ink, width: 2),
      ),
      child: Text(
        '$number',
        style: ui(size / 2, weight: FontWeight.w800, color: textColor),
      ),
    );
  }
}

/// Mint tick badge for stolen loot.
class CheckBadge extends StatelessWidget {
  const CheckBadge({super.key, this.size = 18, this.border = 2});

  final double size;
  final double border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.calmMint,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.ink, width: border),
      ),
      child: Glyph(GameIcon.check, size: size * 0.55, strokeWidth: 4),
    );
  }
}

enum LootState { stolen, missing, nearby }

/// A loot slot in the HUD: stolen, missing, or nearby (dashed).
class LootSlot extends StatelessWidget {
  const LootSlot({
    super.key,
    required this.kind,
    required this.state,
    this.size = 40,
  });

  final PropKind kind;
  final LootState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;
    final prop = Prop(
      kind,
      size: size * 0.7,
      silhouette: state != LootState.stolen,
    );
    final slot = switch (state) {
      LootState.stolen => Container(
        decoration: BoxDecoration(
          color: Palette.gooseWhite,
          border: Border.all(color: Palette.ink, width: 3),
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: prop,
      ),
      LootState.missing => Container(
        decoration: BoxDecoration(
          color: Palette.duskWall,
          border: Border.all(color: Palette.slate, width: 3),
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: prop,
      ),
      LootState.nearby => DashedOutline(
        color: Palette.lamp,
        strokeWidth: 3,
        radius: radius,
        fill: Palette.duskWall,
        child: Center(child: prop),
      ),
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: slot),
          if (state == LootState.stolen)
            const Positioned(right: -6, bottom: -6, child: CheckBadge()),
        ],
      ),
    );
  }
}

enum AlertLevel {
  snoozing('SNOOZING', Palette.calmMint),
  stirring('STIRRING', Palette.lamp),
  suspicious('SUSPICIOUS', Palette.beakOrange),
  danger('DANGER', Palette.alarmTomato),
  awake('AWAKE', Palette.alarmTomato);

  const AlertLevel(this.label, this.color);

  final String label;
  final Color color;

  /// Snoozing 0–24 · Stirring 25–49 · Suspicious 50–79 · Danger 80–99 ·
  /// Awake 100.
  static AlertLevel of(double value) => switch (value) {
    < 25 => snoozing,
    < 50 => stirring,
    < 80 => suspicious,
    < 100 => danger,
    _ => awake,
  };
}

/// Goose alert meter: four segments filling 0–100, coloured by threat.
class AlertMeter extends StatelessWidget {
  const AlertMeter({super.key, required this.value, this.width = 260});

  final double value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final level = AlertLevel.of(value);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: Palette.night,
        border: Border.all(color: Palette.ink, width: 3),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Palette.ink, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.gooseWhite,
              shape: BoxShape.circle,
              border: Border.all(color: Palette.ink, width: 3),
            ),
            child: CustomPaint(
              size: const Size(18, 18),
              painter: _SleepyFacePainter(),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GOOSE ALERT', style: hudLabel(size: 10, spacing: 1.2)),
                    Text(
                      level.label,
                      style: hudLabel(color: level.color, size: 10, spacing: 1.2),
                    ),
                  ],
                ),
                Row(
                  spacing: 3,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: _Segment(
                          fill: ((value - i * 25) / 25).clamp(0, 1).toDouble(),
                          color: level.color,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 10,
        color: Palette.slate,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fill,
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _SleepyFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink;
    canvas.drawPath(
      Path()
        ..moveTo(6, 11)
        ..quadraticBezierTo(9, 14, 12, 11),
      eye,
    );
    canvas.drawLine(
      const Offset(14, 13),
      const Offset(21, 15),
      eye
        ..strokeWidth = 3.5
        ..color = Palette.beakOrange,
    );
  }

  @override
  bool shouldRepaint(_SleepyFacePainter oldDelegate) => false;
}

/// Contextual prompt above an object, e.g. "Grab".
class PromptBubble extends StatelessWidget {
  const PromptBubble(this.label, {super.key, this.icon = GameIcon.grab});

  final String label;
  final GameIcon? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: EdgeInsets.only(left: icon == null ? 10 : 6, right: 10),
      decoration: BoxDecoration(
        color: Palette.gooseWhite,
        border: Border.all(color: Palette.ink, width: 3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          if (icon != null) Glyph(icon!, size: 14),
          Text(label, style: ui(12, weight: FontWeight.w800, height: 1)),
        ],
      ),
    );
  }
}

/// Goose White card with a heavy ink outline and drop.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.borderWidth = 4,
    this.depth = 6,
    this.color = Palette.gooseWhite,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final double radius;
  final double borderWidth;
  final double depth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Palette.ink, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (depth > 0)
            BoxShadow(color: Palette.ink, offset: Offset(0, depth)),
        ],
      ),
      child: child,
    );
  }
}

/// Dark HUD plate, e.g. the loot counter and info boxes.
class NightPlate extends StatelessWidget {
  const NightPlate({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.radius = 14,
    this.borderColor = Palette.ink,
    this.borderWidth = 3,
    this.depth = 0,
  });

  final Widget child;
  final double? width;
  final EdgeInsets padding;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.night,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (depth > 0)
            BoxShadow(color: Palette.ink, offset: Offset(0, depth)),
        ],
      ),
      child: child,
    );
  }
}

/// Rising "z z Z" over a sleeping goose.
class Snores extends StatelessWidget {
  const Snores({super.key, this.scale = 1, this.reversed = false});

  final double scale;

  /// The design draws them rising left in the HUD and right on the menu.
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final style = display(1, color: Palette.moonlight, height: 1);
    final letters = reversed
        ? const [(22.0, 42.0, 14.0, 'z'), (8.0, 22.0, 18.0, 'z'), (-10.0, 0.0, 24.0, 'Z')]
        : const [(0.0, 34.0, 18.0, 'z'), (18.0, 14.0, 24.0, 'z'), (40.0, -12.0, 32.0, 'Z')];
    return SizedBox(
      width: 0,
      height: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (x, y, size, ch) in letters)
            Positioned(
              left: x * scale,
              top: y * scale,
              child: Text(ch, style: style.copyWith(fontSize: size * scale)),
            ),
        ],
      ),
    );
  }
}
