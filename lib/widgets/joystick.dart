import 'package:flutter/material.dart';

import '../screens/scene.dart';
import '../theme/palette.dart';

/// The left-thumb stick. The world is a floor line, so only horizontal
/// motion counts: [onChanged] gets -1 (left) to 1 (right), 0 at rest.
///
/// The whole 280×104 left end of the control band takes the touch, and the
/// knob follows the finger from wherever it landed.
class Joystick extends StatefulWidget {
  const Joystick({super.key, required this.onChanged});

  final ValueChanged<double> onChanged;

  static const knobKey = Key('joystick-knob');

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  static const _travel = 24.0;
  static const _deadZone = 0.15;
  static const _rest = Offset(54, 28);

  int? _pointer;
  double _downX = 0;
  double _offset = 0;
  double _dir = 0;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _downX = e.localPosition.dx;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _set((e.localPosition.dx - _downX).clamp(-_travel, _travel));
  }

  void _end(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _set(0);
  }

  void _set(double offset) {
    setState(() => _offset = offset);
    final raw = offset / _travel;
    final dir = raw.abs() < _deadZone ? 0.0 : raw;
    if (dir == _dir) return;
    _dir = dir;
    widget.onChanged(dir);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _end,
      onPointerCancel: _end,
      child: SizedBox(
        width: 280,
        height: 104,
        child: Stack(
          children: [
            box(30, 4, 94, 94, Palette.midnight, border: 3, borderColor: Palette.slate, oval: true),
            at(
              30,
              4,
              const InlineSvg(
                '<path d="M14 47 L20 42 L20 52 Z M80 47 L74 42 L74 52 Z M47 14 L42 20 L52 20 Z M47 80 L42 74 L52 74 Z" fill="#9FB4E8" opacity="0.7"/>',
                width: 94,
                height: 94,
              ),
            ),
            Positioned(
              key: Joystick.knobKey,
              left: _rest.dx + _offset,
              top: _rest.dy,
              width: 46,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.gooseWhite,
                  shape: BoxShape.circle,
                  border: inkBorder(),
                  boxShadow: const [BoxShadow(color: Palette.ink, offset: Offset(0, 3))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
