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
    this.crawlSpeed = 90,
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
    this.comboWindow = 3,
    this.linkScore = 120,
    this.comboMaxMultiplier = 10,
    this.lootScore = 1000,
    this.guardedLootScore = 2500,
    this.goalScore = 1000,
    this.lightSleeperGain = 1.5,
    this.maxStep = 1 / 60,
    this.gravity = 1800,
    this.jumpSpeed = 550,
    this.maxFallSpeed = 900,
    this.coyoteTime = 0.10,
    this.jumpBuffer = 0.12,
    this.mantleTime = 0.4,
    this.mantleReach = 100,
    this.bodyWidth = 28,
    this.bodyHeight = 64,
    this.landQuiet = 40,
    this.landMedium = 120,
    this.landLoud = 200,
    this.gooseReach = 80,
    this.armReach = 80,
    this.handHeight = 58,
    this.earHalfHeight = 38,
    this.verticalThreshold = 0.5,
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

  /// Crawling along the cabinet tops; always silent.
  final double crawlSpeed;

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

  /// Chaos combo: "Every link fired within 3s adds ×1 to your score multiplier."
  final double comboWindow;

  /// Points per link, times the combo multiplier. 120 makes a 4-link combo
  /// "+1,200", as on the Chaos escape board.
  final int linkScore;

  /// The multiplier stops growing here, so pacing a reusable squeaker can't
  /// run the score away.
  final int comboMaxMultiplier;

  /// Points per loot carried out; the guarded one is worth more.
  final int lootScore;
  final int guardedLootScore;

  /// Points per heist goal met on a getaway.
  final int goalScore;

  /// Light Sleeper: every noise raises her meter this many times more.
  final double lightSleeperGain;

  /// Longest simulation step; bigger ticks are split.
  final double maxStep;

  /// Px/s² pulling Milo down.
  final double gravity;

  /// Take-off speed of a jump: tops out about 84 px up, onto the counter
  /// (70) but not the crawl plank (164).
  final double jumpSpeed;
  final double maxFallSpeed;

  /// A jump still works this long after walking off an edge.
  final double coyoteTime;

  /// A jump pressed this long before landing goes off on landing.
  final double jumpBuffer;

  /// House spec: "mantle diam 0.4s".
  final double mantleTime;

  /// The highest furniture top above his feet he can mantle onto.
  final double mantleReach;

  /// Milo's collision box, feet at its bottom centre.
  final double bodyWidth;
  final double bodyHeight;

  /// Landing loudness by fall height: under [landQuiet] silent, then 1,
  /// from [landMedium] 2, from [landLoud] 3; before surface and Sneak.
  final double landQuiet;
  final double landMedium;
  final double landLoud;

  /// How high above the floor her neck reaches: higher up he is out of her
  /// reach, as if hidden.
  final double gooseReach;

  /// How far above his feet he can reach to grab, lift or wind something.
  final double armReach;

  /// His throwing hand above his feet: 212 on the 270 floor (Plan View).
  final double handHeight;

  /// Half the dashed ear zone's height (76 px tall on the gameplay board).
  final double earHalfHeight;

  /// The stick counts up or down past this fraction of its travel.
  final double verticalThreshold;
}
