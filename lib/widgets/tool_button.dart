import 'package:flutter/widgets.dart';

import '../art/art.dart';
import '../art/icons.dart';
import '../game/tools.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'chunky_button.dart';

/// The 54dp Tool button. Socks are held and dragged to aim (Plan View);
/// the other tools go off with a tap.
class ToolButton extends StatefulWidget {
  const ToolButton({
    super.key,
    required this.tool,
    required this.left,
    required this.ready,
    this.aiming = false,
    this.onTap,
    this.onAimStart,
    this.onAim,
    this.onRelease,
    this.onCancel,
  });

  final Tool tool;

  /// Uses left tonight, shown as the ×N badge.
  final int left;

  /// False draws it dim and ignores touches (used up, marbles while she
  /// sleeps, hidden).
  final bool ready;

  /// A sock is being aimed: the button lights up.
  final bool aiming;

  /// Tap tools: mouse, marbles, kazoo.
  final VoidCallback? onTap;

  /// Socks: a finger went down on the button.
  final VoidCallback? onAimStart;

  /// Socks: horizontal drag since the finger went down, in artboard px.
  final ValueChanged<double>? onAim;

  /// Socks: the finger lifted, wherever it is now.
  final VoidCallback? onRelease;

  /// Socks: the system took the touch away (shade pulled, a call). Drops
  /// the aim without throwing.
  final VoidCallback? onCancel;

  static String nameOf(Tool tool) => switch (tool) {
    Tool.socks => 'spare sock',
    Tool.mouse => 'wind-up mouse',
    Tool.marbles => 'bag of marbles',
    Tool.kazoo => 'kazoo',
  };

  /// The prop that draws [tool].
  static PropKind propOf(Tool tool) => switch (tool) {
    Tool.socks => PropKind.sock,
    Tool.mouse => PropKind.mouse,
    Tool.marbles => PropKind.marbles,
    Tool.kazoo => PropKind.kazoo,
  };

  @override
  State<ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<ToolButton> {
  int? _pointer;
  double _startX = 0;

  bool get _throws => widget.tool == Tool.socks;

  void _down(PointerDownEvent e) {
    if (!_throws || !widget.ready || _pointer != null) return;
    _pointer = e.pointer;
    _startX = e.localPosition.dx;
    widget.onAimStart?.call();
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer == _pointer) widget.onAim?.call(e.localPosition.dx - _startX);
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.onRelease?.call();
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final aiming = widget.aiming;
    final name = ToolButton.nameOf(widget.tool);
    final button = ChunkyButton(
      onPressed: !_throws && widget.ready ? widget.onTap : null,
      semanticLabel: _throws
          ? 'Tool: $name, ${widget.left} left. Hold to aim and throw'
          : 'Tool: $name, ${widget.left} left',
      color: aiming
          ? Palette.lamp
          : widget.ready
          ? Palette.gooseWhite
          : Palette.slate,
      width: 54,
      height: 54,
      depth: aiming ? 0 : 3,
      shadows: aiming ? ringShadows(color: Palette.gooseWhite, width: 4, outline: 3, drop: 0) : null,
      child: aiming
          ? const SockGlyph(fill: Palette.gooseWhite, size: 24)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_throws)
                  const SockGlyph(fill: Palette.lamp)
                else
                  Prop(ToolButton.propOf(widget.tool), size: 28),
                Text('TOOL', style: ui(9, weight: FontWeight.w800, letterSpacing: 1, height: 1.1)),
              ],
            ),
    );

    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: Opacity(
        opacity: widget.ready || aiming ? 1 : 0.6,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(offset: Offset(0, aiming ? 2 : 0), child: button),
              if (!aiming)
                Positioned(
                  right: -6,
                  top: -6,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Palette.ink, borderRadius: BorderRadius.circular(999)),
                      child: Text('×${widget.left}', style: ui(11, weight: FontWeight.w800, color: Palette.lamp)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
