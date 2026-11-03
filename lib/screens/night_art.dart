import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art.dart';
import '../art/motion.dart';
import '../art/rig.dart';
import '../game/goose_brain.dart';
import '../game/level.dart';
import '../game/night_sim.dart';
import '../game/tools.dart';
import '../theme/palette.dart';
import 'scene.dart';

/// How Night 3's simulation ids are drawn: art, positions on the artboard,
/// SFX words and the Caught tips.

/// A square piece of art on the artboard.
class ArtBox {
  const ArtBox(this.left, this.top, this.size);

  final double left;
  final double top;
  final double size;

  double get centerX => left + size / 2;
}

/// Loot art, drawn centred on its sim x.
const lootArt = <String, ({PropKind kind, String name, double size})>{
  'toaster': (kind: PropKind.toaster, name: 'Mega Toaster', size: 64),
  'chicken': (kind: PropKind.chicken, name: 'Rubber Chicken', size: 46),
  'egg': (kind: PropKind.egg, name: 'Golden Egg', size: 34),
  'duck': (kind: PropKind.duck, name: 'Rubber Duck', size: 40),
  'gnome': (kind: PropKind.gnome, name: 'Garden Gnome', size: 44),
};

/// Every x a loot may stand at (its own and its Nightly Remix spots), and
/// the top of its art there: on the counter, the floor or the plank.
final lootTops = <String, Map<double, double>>{
  'toaster': {218: 146, 60: 206},
  'chicken': {353: 70, 300: 70},
  'egg': {561: 206},
};

/// Where [loot] is drawn.
ArtBox lootBox(Loot loot) {
  final size = lootArt[loot.id]!.size;
  return ArtBox(loot.x - size / 2, lootTops[loot.id]![loot.x]!, size);
}

/// Chain objects drawn as props. Books and the plank belong to the set.
const objectArt = <String, ({PropKind kind, ArtBox box})>{
  'glass': (kind: PropKind.glass, box: ArtBox(44, 170, 36)),
  'pot': (kind: PropKind.pot, box: ArtBox(88, 162, 50)),
  'robot': (kind: PropKind.robot, box: ArtBox(594, 200, 40)),
  'clock': (kind: PropKind.clock, box: ArtBox(612, 168, 110)),
};

/// Centres of the glowing snap-spot circles: on the counter, or just
/// above the floor.
const snapAnchors = <String, Offset>{
  'counterPot': Offset(113, 185),
  'underShelf': Offset(372, 252),
  'underSideTable': Offset(596, 252),
};

/// Where the pot stands on [spotId]: up on the counter, else on the floor.
ArtBox potBoxAt(String spotId) =>
    spotId == 'counterPot' ? objectArt['pot']!.box : ArtBox(spotAnchors[spotId]!.dx - 25, 232, 50);

/// The crawlway plank's top surface; Milo crawls with his feet on it.
const crawlwayTop = 106.0;

/// Per hide spot x: where its HIDE tag goes, where Milo peeks out, and the
/// gap a cabinet door leaves open while he is inside.
final hideArt = <double, ({Offset tag, Offset peek, Rect? crack})>{
  148: (tag: Offset(129, 222), peek: Offset(152, 228), crack: Rect.fromLTWH(146, 215, 43, 48)),
  703: (tag: Offset(684, 146), peek: Offset(706, 188), crack: null),
};

/// Where a spot's rings and badges are drawn; x matches the level.
const spotAnchors = <String, Offset>{
  'counterLeft': Offset(62, 188),
  'counterPot': Offset(113, 187),
  'shelfBooks': Offset(340, 150),
  'underShelf': Offset(372, 250),
  'underSideTable': Offset(596, 250),
  'sideTable': Offset(614, 220),
  'plank': Offset(640, 274),
  'clockStand': Offset(667, 223),
};

GooseMood moodFor(GooseState s) => switch (s) {
  GooseState.asleep || GooseState.stirring || GooseState.drowsy => GooseMood.sleep,
  GooseState.suspicious || GooseState.lostYou => GooseMood.suspicious,
  GooseState.sleepwalk => GooseMood.investigate,
  GooseState.awake || GooseState.distracted => GooseMood.awake,
  GooseState.chase => GooseMood.chase,
};

/// How Gertrude moves in each state: the slow breathing of sleep, a twitch
/// when stirring, a listening sway, a drowsy waddle when sleepwalking, a
/// fuming shake when awake and a hurried waddle in the chase. [phase] and
/// [speed] come from her [FigureMotion]; [dir] is +1 walking right, -1 left.
Gait gooseGait(GooseState s, {required double phase, required double speed, required double time, required double dir}) {
  final sway = math.sin(phase);
  final hop = sway.abs();
  final moving = (speed / 20).clamp(0.0, 1.0);
  return switch (s) {
    GooseState.asleep || GooseState.drowsy => Gait.breathe(time, period: 3.2, depth: 0.03),
    GooseState.stirring => Gait(
      tilt: 0.04 * math.sin(time * 17) * math.max(0, math.sin(time * 2.1)),
      stretchY: 1 + 0.03 * math.sin(2 * math.pi * time / 2.4),
    ),
    GooseState.suspicious || GooseState.lostYou => Gait(
      tilt: 0.05 * math.sin(time * 2.6),
      stretchY: 1.03 + 0.01 * math.sin(time * 5),
    ),
    GooseState.sleepwalk => Gait.lerp(
      Gait.breathe(time, period: 3.2, depth: 0.03),
      Gait(lift: 1 * hop, tilt: 0.05 * sway),
      moving,
    ),
    GooseState.awake => Gait(tilt: 0.03 * math.sin(time * 40), stretchY: 1.06),
    GooseState.distracted => Gait(tilt: 0.06 * math.sin(time * 8), stretchY: 1.02),
    GooseState.chase => Gait.lerp(
      Gait(tilt: 0.03 * math.sin(time * 40), stretchY: 1.06),
      Gait(lift: 3.5 * hop, tilt: dir * 0.08 + 0.08 * sway, stretchY: 1 + 0.04 * hop),
      moving,
    ),
  };
}

/// Gertrude's parts for one frame. Her art faces left, so forward is -x.
/// Walking, her legs swing and lift in turn, her body rolls and her head
/// thrusts forward on each step, as a goose's does. In the chase her wings
/// beat. Asleep her head rises and falls with her breath; stirring, it
/// twitches; suspicious, it sweeps from side to side; awake, it shakes with
/// fury. [phase] and [speed] come from her [FigureMotion].
Map<String, Bend> gooseBends(GooseState s, {required double phase, required double speed, required double time}) {
  final move = (speed / 20).clamp(0.0, 1.0);
  final sn = math.sin(phase);
  final cs = math.cos(phase);

  Map<String, Bend> legs(double swing, double lift) => {
    'legA': Bend(angle: swing * sn * move, dy: -math.max(0.0, cs) * lift * move),
    'legB': Bend(angle: -swing * sn * move, dy: -math.max(0.0, -cs) * lift * move),
  };

  final breath = math.sin(2 * math.pi * time / 3.2);
  return switch (s) {
    GooseState.asleep || GooseState.drowsy => {'head': Bend(angle: 0.015 * breath, dy: 1.6 * breath)},
    GooseState.stirring => {
      'head': Bend(
        angle: 0.09 * math.sin(time * 17) * math.max(0.0, math.sin(time * 2.1)),
        dy: 1.6 * math.sin(2 * math.pi * time / 2.4),
      ),
    },
    GooseState.suspicious || GooseState.lostYou => {
      'head': Bend(angle: 0.14 * math.sin(time * 1.7), dx: 2.5 * math.sin(time * 1.7 + 1), dy: -1 + math.sin(time * 5)),
    },
    GooseState.sleepwalk => {
      ...legs(0.35, 3),
      'body': Bend(angle: 0.03 * sn * move, dy: -1.2 * sn.abs() * move),
      // Nose down, sniffing the floor as she goes.
      'head': Bend(angle: 0.06 * sn * move, dx: -2 * sn * move, dy: 2 * math.sin(time * 9)),
    },
    GooseState.awake => {
      'body': Bend(dy: 0.8 * math.sin(time * 40)),
      'head': Bend(angle: 0.05 * math.sin(time * 38), dx: -2),
    },
    GooseState.distracted => {
      ...legs(0.4, 3),
      'head': Bend(angle: 0.22 * math.sin(time * 5), dx: -1),
    },
    GooseState.chase => {
      ...legs(0.8, 7),
      'wingFar': Bend(angle: 0.4 * math.sin(time * 20 + 2)),
      'wingNear': Bend(angle: 0.45 * math.sin(time * 20)),
      'body': Bend(angle: 0.04 * sn * move, dy: -1.5 * sn.abs() * move),
      // The head leads each stride and bobs back.
      'head': Bend(angle: 0.07 * cs * move, dx: -4 * sn * move + (1 - move) * -2, dy: 1.5 * sn.abs() * move),
    },
  };
}

/// Colour = threat: ring colour by loudness.
Color threatColor(int loudness) => switch (loudness) {
  <= 0 => Palette.calmMint,
  1 => Palette.lamp,
  2 => Palette.beakOrange,
  _ => Palette.alarmTomato,
};

/// Badge and arc colour by link number; links redden as the chain grows.
Color linkColor(int link) => switch (link) {
  <= 1 => Palette.lamp,
  2 => Palette.beakOrange,
  _ => Palette.alarmTomato,
};

Color linkTextColor(int link) => link >= 3 ? Palette.gooseWhite : Palette.ink;

String sfxWord(ObjectType t) => switch (t) {
  ObjectType.tipper => 'tink!',
  ObjectType.amplifier => 'CLANG!',
  ObjectType.walker => 'BEEP-BOOP',
  ObjectType.roller => 'rattle!',
  ObjectType.chimer => 'DONG ×3',
  ObjectType.squeaker => 'creak!',
};

/// A chain object as a small icon, for the Caught recap.
Widget objectIcon(String objectId, {double size = 32}) {
  final art = objectArt[objectId];
  if (art != null) return Prop(art.kind, size: size);
  return switch (objectId) {
    'plank' => Prop(PropKind.board, size: size),
    'books' => SizedBox.square(
      dimension: size,
      child: const FittedBox(child: Books(bookIcon)),
    ),
    _ => SizedBox.square(dimension: size),
  };
}

/// Three spines from the shelf, as the books' icon.
const bookIcon = [
  (Palette.alarmTomato, 32.0, 0.0),
  (Palette.calmMint, 28.0, 0.0),
  (Palette.moonlight, 34.0, 0.0),
];

/// A row of book spines standing on a shelf.
class Books extends StatelessWidget {
  const Books(this.books, {super.key});

  /// Colour, height and lean (degrees) per spine.
  final List<(Color, double, double)> books;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 3,
      children: [
        for (final (color, height, lean) in books)
          Transform.rotate(
            angle: deg(lean),
            child: Container(
              width: 13,
              height: height + 4,
              decoration: BoxDecoration(color: color, border: inkBorder(2)),
            ),
          ),
      ],
    );
  }
}

/// One line of advice on the Caught screen, from what woke her.
String wakeTip(NightResult r) {
  if (r.wakeChain.isNotEmpty) {
    final last = r.wakeChain.last.objectId;
    final type = r.level.objects.firstWhere((o) => o.id == last).type;
    return switch (type) {
      ObjectType.amplifier => 'Tip: the pot doubles any noise that lands in it. Move the glass first.',
      ObjectType.chimer =>
        'Tip: the clock waits 1s, then rings three times. Best lure in the house, if she is far away.',
      ObjectType.walker => 'Tip: a wound-up robot marches until it hits something.',
      ObjectType.squeaker => 'Tip: the loose plank is a lighter colour. Hold Sneak to step over it.',
      ObjectType.tipper => 'Tip: a nudged glass makes a small noise. Keep it out of her ear zone.',
      ObjectType.roller => 'Tip: marbles roll to the next object, then poke it.',
    };
  }
  return switch (r.wakeCause) {
    WakeCause.footsteps => 'Tip: walking is loud. Sneak inside her ear zone.',
    WakeCause.grabbedGuarded => 'Tip: she sleeps on the egg. Wait for her roll-over, or lure her away first.',
    WakeCause.tool when r.tool == Tool.kazoo => 'Tip: the kazoo is loud. Toot it far from her bed and she only sleepwalks.',
    WakeCause.tool => 'Tip: a sock that misses still flops. Aim it at something outside her ear zone.',
    _ => 'Tip: the rubber chicken squeaks when you walk with it. Sneak.',
  };
}
