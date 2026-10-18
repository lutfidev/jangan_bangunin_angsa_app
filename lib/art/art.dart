import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'burglar_svgs.dart';
part 'goose_svgs.dart';
part 'prop_svgs.dart';

enum GooseMood { sleep, suspicious, investigate, awake, chase }

enum BurglarPose { sneak, carry, panic, caught, crawl }

enum PropKind {
  glass,
  pot,
  robot,
  clock,
  board,
  toaster,
  chicken,
  gnome,
  toilet,
  duck,
  sock,
  egg,
  mouse,
  marbles,
  kazoo,
  locked,
}

/// Gertrude, the goose. Height is 0.8 × width.
class Goose extends StatelessWidget {
  const Goose({
    super.key,
    this.mood = GooseMood.sleep,
    this.width = 200,
    this.flip = false,
  });

  final GooseMood mood;
  final double width;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final art = _gooseSvgs[mood]!;
    return _Art(
      svg: art.svg,
      label: art.label,
      width: width,
      height: (width * 0.8).roundToDouble(),
      flip: flip,
    );
  }
}

/// Milo Muffle, the burglar. Height is 1.25 × width.
class Burglar extends StatelessWidget {
  const Burglar({
    super.key,
    this.pose = BurglarPose.sneak,
    this.width = 120,
    this.flip = false,
  });

  final BurglarPose pose;
  final double width;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final art = _burglarSvgs[pose]!;
    return _Art(
      svg: art.svg,
      label: art.label,
      width: width,
      height: (width * 1.25).roundToDouble(),
      flip: flip,
    );
  }
}

/// A square noise-maker or loot prop. [silhouette] greys it out for
/// missing loot slots.
class Prop extends StatelessWidget {
  const Prop(
    this.kind, {
    super.key,
    this.size = 100,
    this.flip = false,
    this.silhouette = false,
  });

  final PropKind kind;
  final double size;
  final bool flip;
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final art = _propSvgs[kind]!;
    Widget child = _Art(
      svg: art.svg,
      label: art.label,
      width: size,
      height: size,
      flip: flip,
      tint: silhouette ? const Color(0xFFBFBFBF) : null,
    );
    if (silhouette) child = Opacity(opacity: 0.35, child: child);
    return child;
  }
}

class _Art extends StatelessWidget {
  const _Art({
    required this.svg,
    required this.label,
    required this.width,
    required this.height,
    required this.flip,
    this.tint,
  });

  final String svg;
  final String label;
  final double width;
  final double height;
  final bool flip;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    Widget picture = SvgPicture.string(
      svg,
      width: width,
      height: height,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
      semanticsLabel: label,
    );
    if (flip) {
      picture = Transform.flip(flipX: true, child: picture);
    }
    return SizedBox(width: width, height: height, child: picture);
  }
}
