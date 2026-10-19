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
