import 'dart:math' as math;

import 'tuning.dart';

/// The three ways to win a night (Gameplay 2.0, "every night now has three
/// ways to win"). Each heist goal belongs to one; the Victory badge names one.
enum PlayStyle { ghost, trickster, chaos }

/// What a heist goal asks for.
enum GoalKind {
  /// She never turns suspicious (or worse) all night.
  neverSuspicious,

  /// She sleepwalks out of bed [HeistGoal.count] times.
  lure,

  /// A combo of [HeistGoal.count] links.
  chain,
}

/// One of a night's three heist goals, worth a sock on a getaway.
class HeistGoal {
  const HeistGoal({required this.style, required this.kind, this.count = 1});

  final PlayStyle style;
  final GoalKind kind;
  final int count;
}

/// Chaos combo: "Every link fired within 3s adds ×1 to your score
/// multiplier." Links from separate chains share one combo.
class Combo {
  Combo(this.tuning);

  final Tuning tuning;

  int _count = 0;
  int _points = 0;
  int _best = 0;
  int _total = 0;
  double? _last;

  /// Links in the current combo; also its multiplier.
  int get count => _count;

  /// Points the current combo has scored so far.
  int get points => _points;

  /// The longest combo tonight.
  int get best => _best;

  /// Points from every link tonight.
  int get total => _total;

  /// A link fired at [now]: it scores [Tuning.linkScore] times the multiplier.
  void link(double now) {
    final last = _last;
    if (last == null || now - last > tuning.comboWindow) {
      _count = 0;
      _points = 0;
    }
    _count++;
    final score = tuning.linkScore * _count;
    _points += score;
    _total += score;
    _best = math.max(_best, _count);
    _last = now;
  }

  /// Seconds until the current combo runs out; 0 once it has.
  double leftAt(double now) {
    final last = _last;
    return last == null ? 0 : math.max(0, tuning.comboWindow - (now - last));
  }
}
