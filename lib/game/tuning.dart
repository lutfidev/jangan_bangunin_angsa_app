/// Every number the night simulation runs on. Values the design pins are
/// noted with their board; the rest are first guesses for playtesting.
///
/// Distances are artboard px along the floor line, times are seconds.
class Tuning {
  const Tuning({
    this.worldWidth = 844,
    this.ringRadius = 36,
    this.footstepRadius = 18,
    this.earHalfWidth = 172,
    this.walkSpeed = 120,
    this.sneakSpeed = 60,
    this.sleepwalkSpeed = 50,
    this.chaseSpeed = 110,
    this.patrolSpeed = 60,
    this.footstepEvery = 0.4,
    this.squeakCarryEvery = 0.8,
    this.meterStep = 4,
    this.meterSmall = 25,
    this.meterMedium = 50,
    this.meterLoud = 100,
    this.quietBeforeDrain = 2,
    this.drainPerSecond = 10,
    this.rollOverEvery = 8,
    this.rollOverWindow = 2,
    this.sniffTime = 4,
    this.drowsyTime = 6,
    this.drowsyGain = 2,
    this.awakeFreeze = 0.3,
    this.chaseTime = 12,
    this.distractTime = 4,
    this.hideToLose = 3,
    this.patrolTime = 5,
    this.caughtDistance = 20,
    this.reach = 30,
    this.caughtAnim = 1.2,
    this.chimerDelay = 1,
    this.sockCount = 3,
    this.throwRange = 360,
    this.throwHitRadius = 24,
    this.throwFlightTime = 0.5,
    this.mouseSpeed = 70,
    this.spillBehind = 24,
    this.slipRadius = 16,
    this.slipTime = 2,
    this.maxStep = 1 / 60,
  });

  /// Length of the floor line: the 844px width of the gameplay board.
  final double worldWidth;

  /// Radius per ring; a noise draws one ring per loudness step.
  final double ringRadius;

  /// The single tiny ring a footstep draws.
  final double footstepRadius;

  /// Half the dashed ear zone (344px wide on the gameplay board).
  final double earHalfWidth;

  final double walkSpeed;
  final double sneakSpeed;
  final double sleepwalkSpeed;
  final double chaseSpeed;
  final double patrolSpeed;

  /// One footstep ring per this many seconds of walking.
  final double footstepEvery;

  /// A carried squeaky loot squeaks this often while walking.
  final double squeakCarryEvery;

  /// Meter gain for a noise of loudness 0 (footstep), 1, 2 and 3.
  final double meterStep;
  final double meterSmall;
  final double meterMedium;
  final double meterLoud;

  /// Noise Chain Reaction: "Drains 10/s after 2s of quiet."
  final double quietBeforeDrain;
  final double drainPerSecond;

  /// Goose brain v2: "rolls over every 8s", a 2s roll-over window.
  final double rollOverEvery;
  final double rollOverWindow;

  /// Sleepwalk: "sniffs for 4s".
  final double sniffTime;

  /// Drowsy: "wakes 2× easier for 6s".
  final double drowsyTime;
  final double drowsyGain;

  /// "A 0.3s freeze-frame" when she wakes.
  final double awakeFreeze;

  /// "CHASE · 12s".
  final double chaseTime;

  /// A 2+ link chain pulls her away "for 4s".
  final double distractTime;

  /// "You hid 3s".
  final double hideToLose;

  /// Grumpy patrol before she settles back into bed.
  final double patrolTime;

  /// How close the chasing goose must get to catch the burglar.
  final double caughtDistance;

  /// How close the burglar must be to grab loot or use a hide spot.
  final double reach;

  /// Caught: "1.2s total, then the Caught screen".
  final double caughtAnim;

  /// Chimer: "1s delay, then 3 loud rings".
  final double chimerDelay;

  /// "Spare Socks ×3". Every other tool has one use.
  final int sockCount;

  /// How far either side of the burglar a sock can land.
  final double throwRange;

  /// A sock hits an object whose spot is this close to where it lands.
  final double throwHitRadius;

  /// Seconds a sock spends in the air.
  final double throwFlightTime;

  /// Wind-up mouse walking speed.
  final double mouseSpeed;

  /// Marbles land this far behind the burglar.
  final double spillBehind;

  /// She slips when she runs this close to spilled marbles.
  final double slipRadius;

  /// Bag of Marbles: "Gertrude slips and loses 2 seconds."
  final double slipTime;

  /// Longest simulation step; bigger ticks are split.
  final double maxStep;
}
