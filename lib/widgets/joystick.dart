import 'package:flutter/material.dart';

import '../screens/scene.dart';
import '../theme/palette.dart';

/// The left-thumb stick. Left and right walk: [onChanged] gets x from -1
/// (left) to 1 (right), 0 at rest. Up and down climb and drop: y is -1 or
/// +1 only past half the knob's travel, so walking on a slant never climbs.
///
/// The whole 280×104 left end of the control band takes the touch, and the
/// knob follows the finger from wherever it landed. [hintUp] and [hintDown]
/// light the arrows that would do something right now.
class Joystick extends StatefulWidget {
  const Joystick({super.key, required this.onChanged, this.hintUp = false, this.hintDown = false});

  final void Function(double x, int y) onChanged;
  final bool hintUp;
  final bool hintDown;

  static const knobKey = Key('joystick-knob');
  static const hintUpKey = Key('joystick-hint-up');
  static const hintDownKey = Key('joystick-hint-down');

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  static const _travel = 24.0;
  static const _deadZone = 0.15;
  static const _rest = Offset(54, 28);

  int? _pointer;
  Offset _down = Offset.zero;
  Offset _offset = Offset.zero;
  double _x = 0;
  int _y = 0;

  void _start(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _down = e.localPosition;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final d = e.localPosition - _down;
    _set(d.distance > _travel ? d / d.distance * _travel : d);
  }

  void _end(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _set(Offset.zero);
  }

  void _set(Offset offset) {
    setState(() => _offset = offset);
    final raw = offset.dx / _travel;
    final x = raw.abs() < _deadZone ? 0.0 : raw;
    final y = offset.dy < -_travel / 2 ? -1 : (offset.dy > _travel / 2 ? 1 : 0);
    if (x == _x && y == _y) return;
    _x = x;
    _y = y;
    widget.onChanged(x, y);
  }

  @override
  Widget build(BuildContext context) {
    // The four arrows; a lit one is drawn bigger and yellow instead.
    final dim = [
      'M14 47 L20 42 L20 52 Z',
      'M80 47 L74 42 L74 52 Z',
      if (!widget.hintUp) 'M47 14 L42 20 L52 20 Z',
      if (!widget.hintDown) 'M47 80 L42 74 L52 74 Z',
    ].join(' ');
    Widget lit(String path, Key key) => at(
      30,
      4,
      InlineSvg(
        '<path d="$path" fill="#FFC14D" stroke="#1C1A2B" stroke-width="2" stroke-linejoin="round"/>',
        key: key,
        width: 94,
        height: 94,
      ),
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _start,
      onPointerMove: _move,
      onPointerUp: _end,
      onPointerCancel: _end,
      child: SizedBox(
        width: 280,
        height: 104,
        child: Stack(
          children: [
            box(30, 4, 94, 94, Palette.midnight, border: 3, borderColor: Palette.slate, oval: true),
            at(30, 4, InlineSvg('<path d="$dim" fill="#9FB4E8" opacity="0.7"/>', width: 94, height: 94)),
            if (widget.hintUp) lit('M47 8 L39 19 L55 19 Z', Joystick.hintUpKey),
            if (widget.hintDown) lit('M47 86 L39 75 L55 75 Z', Joystick.hintDownKey),
            Positioned(
              key: Joystick.knobKey,
              left: _rest.dx + _offset.dx,
              top: _rest.dy + _offset.dy,
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
