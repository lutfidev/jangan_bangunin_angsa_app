import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type.dart';

/// Ink-outlined on/off switch. [compact] is the small briefing variant.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    this.compact = false,
    this.offColor = Palette.toggleOff,
  });

  final bool value;
  final bool compact;
  final Color offColor;

  @override
  Widget build(BuildContext context) {
    final (w, h, border, knob, inset) = compact
        ? (36.0, 22.0, 2.0, 14.0, 2.0)
        : (60.0, 34.0, 3.0, 22.0, 3.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: value ? Palette.calmMint : offColor,
        border: Border.all(color: Palette.ink, width: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knob,
          height: knob,
          margin: EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: Palette.gooseWhite,
            shape: BoxShape.circle,
            border: compact
                ? null
                : Border.all(color: Palette.ink, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A settings row: label, hint and a [ToggleSwitch].
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.divider = true,
  });

  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return _Row(
      divider: divider,
      child: Semantics(
        toggled: value,
        label: label,
        hint: hint,
        excludeSemantics: true,
        onTap: () => onChanged(!value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ui(15, weight: FontWeight.w800, height: 1.2)),
                    Text(
                      hint,
                      style: ui(12, weight: FontWeight.w600, color: Palette.mutedInk, height: 1.2),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings row: label, chunky 0–100 slider and the value in percent.
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.divider = true,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return _Row(
      divider: divider,
      child: Row(
        spacing: 16,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: ui(15, weight: FontWeight.w800)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: Palette.hoodieTeal,
                inactiveTrackColor: Palette.rule,
                thumbColor: Palette.gooseWhite,
                overlayColor: Palette.lamp.withValues(alpha: 0.3),
                thumbShape: const _InkThumb(),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value.toDouble(),
                max: 100,
                label: label,
                semanticFormatterCallback: (v) => '${v.round()}%',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: ui(
                14,
                weight: FontWeight.w800,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child, required this.divider});

  final Widget child;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: Palette.rule, width: 2))
            : null,
      ),
      child: child,
    );
  }
}

class _InkThumb extends SliderComponentShape {
  const _InkThumb();

  static const _radius = 11.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 2),
      _radius,
      Paint()..color = Palette.ink,
    );
    canvas.drawCircle(center, _radius, Paint()..color = Palette.gooseWhite);
    canvas.drawCircle(
      center,
      _radius - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Palette.ink,
    );
  }
}
