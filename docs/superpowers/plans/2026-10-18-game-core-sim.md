# Game Core Simulation (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A headless, fully unit-tested Dart simulation of one night: noise and the alert meter, the Noise Chain Reaction graph, Goose brain v2 (9 states), and the burglar's movement, loot, hiding, getting caught and escaping. Night 3 (The Midnight Kitchen) can be solved Ghost, Trickster or Chaos style from scripted inputs.

**Architecture:** Pure Dart under `lib/game/`, with no Flutter imports. Time advances only through `NightSim.tick(dt)`, so tests drive it deterministically. The level is a small graph loaded from JSON. Chain links connect *spots*, not objects, so moving a portable object to a snap spot changes the chain without editing the graph (this is what Rearrange needs in Phase 3). The UI is untouched in this phase. Phase 2 reads `NightSim` state and events to draw the scene.

**Tech Stack:** Dart 3.13 / Flutter 3 (`flutter_test` for tests). No new dependencies.

**Spec:** Claude Design canvas "Don't Wake the Goose" (https://claude.ai/artifact/9zNwUS2eKMXA5kUguG48w5), boards **"Gameplay 2.0 · Chaos is a tool"** (`project/GameplayLoop.dc.html`) and **"C · Noise Chain Reaction states"** (`project/NoiseStates.dc.html`). Values below marked *(tuning)* are not in the design. They are first guesses, all in `Tuning`, and get adjusted in playtesting.

## Roadmap (separate plans, written when the previous phase lands)

1. **Phase 1, this plan:** game core simulation, headless.
2. **Phase 2:** wire `NightSim` into `GameplayScreen`: joystick, sneak, live `AlertMeter`, noise rings, numbered link badges at 0.4s, goose poses per state, HONK freeze (0.3s, 4px nudge), chase frame, real Caught recap and Victory loot.
3. **Phase 3:** verbs and tools: Throw (one parabola, hold-and-drag aim), Rearrange (carry portable objects to glowing snap spots), hide spots, cabinet-top crawlway, briefing tool pick wired to the 4 tools.
4. **Phase 4:** replay: 3 heist goals per night, style badge, chaos combo multiplier, night modifiers, date-seeded Nightly Remix, saved socks and trophies.

## Global Constraints

- `lib/game/**` imports only `dart:*` and other `lib/game/` files (no `package:flutter`).
- World units: artboard px along the floor line, `0..844`. The goose and the burglar move on x only ("walking on the floor line only").
- Time: seconds, advanced only by `tick(dt)`. No `DateTime.now`, timers or `Future.delayed` in `lib/game/`.
- No physics: "Chains feel physical because of timing and animation, not simulation."
- Meter bands, verbatim: "Snoozing 0–24 · Stirring 25–49 · Suspicious 50–79 · Danger 80–99 · Awake 100. Drains 10/s after 2s of quiet."
- Ring count = loudness: "1 small · 2 medium · 3 loud". Footsteps are loudness 0 ("one tiny ring per step"). Sneaking makes no footstep noise.
- "Only rings that touch the dashed ear zone raise the meter."
- Chain links fire at 0.4s intervals by default (the `delay` on a link).
- Goose timings, verbatim: rolls over every 8s with a 2s roll-over window; sleepwalk sniffs 4s; drowsy "wakes 2× easier for 6s"; distracted 4s by a 2+ link chain; lost you after hiding 3s; CHASE 12s; caught animation 1.2s; awake freeze 0.3s.
- Out of scope, verbatim: "Real-time physics, free placement anywhere, a second goose, procedural houses, online leaderboards or anything server-side."
- Run tests with `flutter test test/game/`. Run `flutter analyze` clean before each commit.

## Review Focus

1. **Big frame gaps** (app resumed after 2s in the background, `tick(2.0)`). Chain links, chimer delays and the goose's timers must fire in order, as if ticked in small steps. Test in Task 6.
2. **Poking a one-shot object that already fired** (the glass already fell). Nothing happens, no noise, no crash. Test in Task 4.
3. **A cycle in the level graph** (plank → clock → plank with reusable objects). Each spot fires at most once per chain, so the chain ends. Test in Task 4.
4. **A hidden burglar touched by a chasing goose** is not caught. Test in Task 6.
5. **Broken level JSON** (a link to an unknown spot, two objects on one spot). Load throws `FormatException` naming the bad id. Test in Task 3.

## File Structure

| File | Responsibility |
|---|---|
| `lib/game/tuning.dart` | `Tuning`: every number the design doesn't pin, as const fields |
| `lib/game/noise.dart` | `Noise`, ring radius, ear-zone touch test |
| `lib/game/noise_meter.dart` | `NoiseMeter`: raise, 2s-quiet drain, bands, drowsy ×2 |
| `lib/game/level.dart` | `Level` model + `Level.fromJson` with validation |
| `assets/levels/night3.json` | Night 3, The Midnight Kitchen |
| `lib/game/chain.dart` | `ChainRunner`: object behaviours, ordered links, delays, link numbering |
| `lib/game/goose_brain.dart` | `GooseBrain`: 9-state machine, goose x, timers |
| `lib/game/night_sim.dart` | `NightSim`: player, inputs, fixed-step tick, events, outcome |
| `test/game/*_test.dart` | One test file per `lib/game` file |

---

### Task 1: Tuning and the noise model

**Files:**
- Create: `lib/game/tuning.dart`, `lib/game/noise.dart`
- Test: `test/game/noise_test.dart`

**Interfaces:**
- Produces:
  - `class Tuning` (const constructor, all fields `final double`) with defaults: `ringRadius = 36` per ring *(tuning)*, `footstepRadius = 18` *(tuning)*, `earHalfWidth = 172` (half the design's 344px ear zone), `walkSpeed = 120`, `sneakSpeed = 60`, `sleepwalkSpeed = 50`, `chaseSpeed = 110`, `patrolSpeed = 60` *(tuning)*, `footstepEvery = 0.4`, `squeakCarryEvery = 0.8` *(tuning)*, `meterStep = 4`, `meterSmall = 25`, `meterMedium = 50`, `meterLoud = 100` *(tuning)*, `quietBeforeDrain = 2`, `drainPerSecond = 10`, `rollOverEvery = 8`, `rollOverWindow = 2`, `sniffTime = 4`, `drowsyTime = 6`, `drowsyGain = 2`, `awakeFreeze = 0.3`, `chaseTime = 12`, `distractTime = 4`, `hideToLose = 3`, `patrolTime = 5` *(tuning)*, `caughtDistance = 20`, `reach = 30` (grab / hide-spot distance) *(tuning)*, `caughtAnim = 1.2`, `chimerDelay = 1`, `maxStep = 1 / 60`.
  - `class Noise { final double x; final int loudness; /* 0..3 */ }` with `double radius(Tuning t)` (`loudness == 0 ? t.footstepRadius : loudness * t.ringRadius`) and `bool touchesEar(double gooseX, Tuning t)`: true when the ring reaches the interval `[gooseX - earHalfWidth, gooseX + earHalfWidth]`.

- [ ] **Step 1: Write the failing tests**

```dart
const t = Tuning();
test('ring radius grows with loudness', () {
  expect(const Noise(x: 0, loudness: 0).radius(t), 18);
  expect(const Noise(x: 0, loudness: 2).radius(t), 72);
});
test('ear zone touch is distance to the zone edge', () {
  // goose at 502 → zone 330..674
  expect(const Noise(x: 113, loudness: 2).touchesEar(502, t), isFalse); // 113+72=185
  expect(const Noise(x: 667, loudness: 3).touchesEar(502, t), isTrue);  // inside
  expect(const Noise(x: 250, loudness: 3).touchesEar(502, t), isTrue);  // 250+108=358
  expect(const Noise(x: 300, loudness: 0).touchesEar(502, t), isFalse); // 300+18=318
});
```

- [ ] **Step 2: Run** `flutter test test/game/noise_test.dart`. Expected: FAIL (files missing).
- [ ] **Step 3: Implement** `Tuning` and `Noise` as above.
- [ ] **Step 4: Run** the same command. Expected: PASS.
- [ ] **Step 5: Commit** `feat(game): add tuning and noise ring model`

---

### Task 2: Noise meter

**Files:**
- Create: `lib/game/noise_meter.dart`
- Test: `test/game/noise_meter_test.dart`

**Interfaces:**
- Consumes: `Tuning`, `Noise` (Task 1).
- Produces:
  - `enum MeterBand { snoozing, stirring, suspicious, danger, awake }`
  - `class NoiseMeter { NoiseMeter(this.tuning); double get value; MeterBand get band; double drowsyLeft; void hear(int loudness); void tick(double dt); void reset({double value = 0}); }`
  - `hear(loudness)` adds `meterStep/Small/Medium/Loud` for loudness 0/1/2/3, ×`drowsyGain` while `drowsyLeft > 0`, clamps to `0..100`, and resets the quiet timer. The *caller* decides whether the noise touched the ear zone.
  - `tick(dt)`: after `quietBeforeDrain` seconds without `hear`, drains `drainPerSecond`. Counts `drowsyLeft` down to 0.

- [ ] **Step 1: Write the failing tests**

```dart
test('bands match the design', () {
  final m = NoiseMeter(const Tuning());
  expect(m.band, MeterBand.snoozing);
  m.hear(1); expect(m.value, 25); expect(m.band, MeterBand.stirring);
  m.hear(1); expect(m.band, MeterBand.suspicious);           // 50
  m.reset(value: 80); expect(m.band, MeterBand.danger);
  m.hear(3); expect(m.value, 100); expect(m.band, MeterBand.awake);
});
test('drains 10/s only after 2s of quiet', () {
  final m = NoiseMeter(const Tuning())..hear(2);             // 50
  m.tick(2.0); expect(m.value, 50);
  m.tick(1.0); expect(m.value, 40);
  m.tick(10);  expect(m.value, 0);                           // clamps
});
test('drowsy doubles gain', () {
  final m = NoiseMeter(const Tuning())..drowsyLeft = 6;
  m.hear(1); expect(m.value, 50);
  m.tick(6);                       // 2s quiet, then 4s × 10 drained → 10; drowsy over
  m.hear(0); expect(m.value, 14);  // plain +4 again
});
```

- [ ] **Step 2: Run** `flutter test test/game/noise_meter_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `NoiseMeter`. `band` comes from `value` using the verbatim thresholds (`>= 100` awake, `>= 80` danger, `>= 50` suspicious, `>= 25` stirring).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(game): add noise meter with bands and drain`

---

### Task 3: Level model and Night 3 data

**Files:**
- Create: `lib/game/level.dart`, `assets/levels/night3.json`
- Modify: `pubspec.yaml` (add `assets/levels/` under `flutter: assets:`)
- Test: `test/game/level_test.dart`

**Interfaces:**
- Produces:
  - `enum ObjectType { tipper, amplifier, walker, roller, chimer, squeaker }` (the design's "chain kit").
  - `class Spot { String id; double x; bool snap; }`, `class LevelObject { String id; ObjectType type; String spot; bool portable; }`, `class Link { String from; String to; double delay; }` (`delay` defaults to `0.4`), `class Loot { String id; double x; bool guarded; bool squeaks; }`.
  - `class Level { String id; String name; double playerStart; double exitX; double bedX; List<double> hideSpots; Map<String, Spot> spots; List<LevelObject> objects; List<Link> links; List<Loot> loot; factory Level.fromJson(Map<String, Object?> json); static Level parse(String source); List<Link> linksFrom(String spotId); }`. `linksFrom` keeps file order, which is the poke priority.
  - Validation in `fromJson` throws `FormatException('<what>: <id>')` for: a link `from`/`to` or object `spot` that isn't a spot, two objects on one spot, more than one `guarded` loot, a duplicate id.

- [ ] **Step 1: Write `assets/levels/night3.json`** with these exact values. Positions come from the current `GameplayScreen` layout: kitchen 0–300, living room 310–690, hall 700–844.

```json
{
  "id": "night3", "name": "The Midnight Kitchen",
  "playerStart": 236, "exitX": 770, "bedX": 502, "hideSpots": [180, 720],
  "spots": [
    {"id": "counterLeft", "x": 62}, {"id": "counterPot", "x": 113, "snap": true},
    {"id": "shelfBooks", "x": 340}, {"id": "underShelf", "x": 372, "snap": true},
    {"id": "underSideTable", "x": 596, "snap": true}, {"id": "sideTable", "x": 614},
    {"id": "plank", "x": 640}, {"id": "clockStand", "x": 667}
  ],
  "objects": [
    {"id": "glass", "type": "tipper", "spot": "counterLeft"},
    {"id": "pot", "type": "amplifier", "spot": "counterPot", "portable": true},
    {"id": "books", "type": "tipper", "spot": "shelfBooks"},
    {"id": "robot", "type": "walker", "spot": "sideTable"},
    {"id": "plank", "type": "squeaker", "spot": "plank"},
    {"id": "clock", "type": "chimer", "spot": "clockStand"}
  ],
  "links": [
    {"from": "counterLeft", "to": "counterPot"},
    {"from": "shelfBooks", "to": "underShelf"},
    {"from": "sideTable", "to": "underSideTable", "delay": 0.8},
    {"from": "sideTable", "to": "clockStand", "delay": 1.2},
    {"from": "plank", "to": "clockStand"}
  ],
  "loot": [
    {"id": "toaster", "x": 218}, {"id": "chicken", "x": 353, "squeaks": true},
    {"id": "egg", "x": 561, "guarded": true}
  ]
}
```

- [ ] **Step 2: Write the failing tests.** Read the file with `File('assets/levels/night3.json').readAsStringSync()`.

```dart
test('night 3 parses', () {
  final l = Level.parse(File('assets/levels/night3.json').readAsStringSync());
  expect(l.spots, hasLength(8));
  expect(l.linksFrom('sideTable').map((k) => k.to), ['underSideTable', 'clockStand']);
  expect(l.links.first.delay, 0.4);
  expect(l.loot.singleWhere((x) => x.guarded).id, 'egg');
});
test('rejects a link to an unknown spot', () {
  expect(() => Level.parse(_minimal(links: '[{"from":"a","to":"nope"}]')),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('nope'))));
});
test('rejects two objects on one spot', () { /* same shape, message contains the spot id */ });
```

`_minimal` is a test helper. It builds a valid one-spot level JSON string and accepts overrides.

- [ ] **Step 3: Run** `flutter test test/game/level_test.dart`. Expected: FAIL.
- [ ] **Step 4: Implement** `level.dart` and add the asset folder to `pubspec.yaml`.
- [ ] **Step 5: Run.** Expected: PASS. Then run `flutter analyze`.
- [ ] **Step 6: Commit** `feat(game): add level model and Night 3 data`

---

### Task 4: Chain runner

**Files:**
- Create: `lib/game/chain.dart`
- Test: `test/game/chain_test.dart`

**Interfaces:**
- Consumes: `Level`, `ObjectType`, `Link` (Task 3), `Tuning` (Task 1).
- Produces:
  - `class LinkFired { int chainId; int link; String objectId; String spotId; Noise? noise; }`. `link` is 1-based within its chain.
  - `class ChainRunner { ChainRunner(Level level, Tuning tuning); void poke(String spotId); void tick(double dt); List<LinkFired> takeFired(); String? objectAt(String spotId); void move(String objectId, String toSpot); bool isSpent(String objectId); }`
  - A `poke` from outside starts a new chain (`chainId` increments). A poke on an empty spot or a spent one-shot does nothing.
  - Behaviours. `inL` is the loudness that arrived with the poke, `1` for an outside poke:
    - `tipper`: one-shot; noise loudness 1.
    - `amplifier`: reusable; noise `min(3, 2 * inL)`.
    - `walker`, `roller`: one-shot; noise loudness 1.
    - `chimer`: reusable; waits `chimerDelay` (1s), then noise loudness 3.
    - `squeaker`: reusable; noise loudness 1.
  - After its noise, an object pokes the **first** `linksFrom(spot)` whose target spot holds an object, after that link's `delay`, passing its own loudness as `inL`. Within one chain each spot fires at most once (cycle guard).
  - `move` is for Phase 3 Rearrange. It throws `StateError` if the object isn't `portable` or the spot isn't `snap` or is occupied.

- [ ] **Step 1: Write the failing tests** (against Night 3)

```dart
late ChainRunner c;
setUp(() => c = ChainRunner(night3(), const Tuning()));  // night3() helper reads the asset

test('glass into pot: CLANG ×2 at 0.4s', () {
  c.poke('counterLeft');
  c.tick(0.01);
  expect(c.takeFired().single, isA<LinkFired>()
      .having((f) => f.link, 'link', 1).having((f) => f.noise!.loudness, 'loud', 1));
  c.tick(0.38); expect(c.takeFired(), isEmpty);
  c.tick(0.03);
  final pot = c.takeFired().single;
  expect([pot.objectId, pot.link, pot.noise!.loudness, pot.noise!.x], ['pot', 2, 2, 113]);
});
test('robot marches into the clock when no pot is under the table', () {
  c.poke('sideTable');
  c.tick(0.01); c.takeFired();                  // robot, link 1
  c.tick(1.2);  expect(c.takeFired(), isEmpty); // clock is waiting its 1s
  c.tick(1.0);
  expect(c.takeFired().single.noise!.loudness, 3);
});
test('robot drops into the pot once the pot is moved under the table', () {
  c.move('pot', 'underSideTable');
  c.poke('sideTable'); c.tick(0.01); c.takeFired(); c.tick(0.8);
  expect(c.takeFired().single.objectId, 'pot');
});
test('a spent tipper ignores pokes', () {
  c.poke('counterLeft'); c.tick(1); c.takeFired();
  c.poke('counterLeft'); c.tick(1);
  expect(c.takeFired(), isEmpty);
  expect(c.isSpent('glass'), isTrue);
});
test('a cycle ends: each spot fires once per chain', () {
  final l = Level.parse(cycleJson);   // plank ⇄ clock, both reusable
  final r = ChainRunner(l, const Tuning())..poke('plank');
  for (var i = 0; i < 100; i++) { r.tick(0.1); }
  expect(r.takeFired().map((f) => f.spotId), ['plank', 'clockStand']);
});
test('two chains get separate ids', () { /* poke counterLeft and plank; chainIds differ, each starts at link 1 */ });
```

- [ ] **Step 2: Run** `flutter test test/game/chain_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `ChainRunner`. Keep a list of pending pokes `(fireAt, spotId, inL, chainId, link)`. `tick` advances the clock and fires pending pokes whose `fireAt <= now`, in time order.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(game): add chain runner for the noise chain kit`

---

### Task 5: Goose brain v2

**Files:**
- Create: `lib/game/goose_brain.dart`
- Test: `test/game/goose_brain_test.dart`

**Interfaces:**
- Consumes: `Tuning`, `Noise` (Task 1), `NoiseMeter`, `MeterBand` (Task 2).
- Produces:
  - `enum GooseState { asleep, stirring, suspicious, sleepwalk, drowsy, awake, chase, distracted, lostYou }`
  - `enum WakeCause { noise, footsteps, grabbedGuarded }`
  - `class GooseBrain { GooseBrain({required double bedX, required Tuning tuning}); GooseState get state; double get x; bool get inBed; bool get rollingOver; bool get sniffing; NoiseMeter get meter; void hear(Noise n, {int chainLinks = 0}); void wake(WakeCause cause); void tick(double dt, {required double playerX, required bool playerHidden}); WakeCause? get wakeCause; }`
- Rules, from the design:
  - **In bed** (`asleep/stirring/suspicious/drowsy`): the state comes from the meter: `>= 50` suspicious, `>= 25` stirring, else `drowsy` while `meter.drowsyLeft > 0`, else `asleep`. Meter 100 → `awake` (cause `noise`, or `footsteps` for loudness 0).
  - **Roll-over:** while `asleep`, every `rollOverEvery` (8s) she rolls over for `rollOverWindow` (2s). `rollingOver` is true during that window.
  - `hear` with an ear-touching noise raises the meter. A noise with loudness `>= 2` that does **not** touch the ear zone, while in bed → `sleepwalk` toward `n.x`. "a loud noise far from her bed doesn't wake her — it moves her."
  - **Sleepwalk:** walk to the source at `sleepwalkSpeed`, sniff `sniffTime` (4s), walk back to `bedX`. Then `drowsy` with `meter.drowsyLeft = 6`. While sleepwalking, a noise with loudness `>= 2` that touches the ear zone (measured from her current x), or any noise with loudness `>= 2` while `sniffing`, → `awake`. Footsteps and loudness 1 only raise the meter.
  - **Awake:** freeze `awakeFreeze` (0.3s), then `chase`.
  - **Chase:** move at `chaseSpeed` toward `playerX`, or toward the last heard noise x while `playerHidden`. Lasts `chaseTime` (12s); the timer pauses while distracted. A heard noise with `chainLinks >= 2` → `distracted`: walk to it, return to `chase` after `distractTime` (4s). If the player is hidden for `hideToLose` (3s) or the chase timer runs out → `lostYou`.
  - **Lost you:** patrol back to bed at `patrolSpeed`. Once she is in bed and at least `patrolTime` has passed: `meter.reset()`, `drowsyLeft = 6`, and the state follows the in-bed rules. If she has heard no noise yet, the "last noise" chase target is her own x (she holds still).
  - Arriving anywhere (source, bed) snaps `x` to the target exactly.
  - A `LinkFired` is reported when its noise happens. For a chimer, that is after its 1s wait, not when it was poked.

- [ ] **Step 1: Write the failing tests.** Use helper `run(GooseBrain g, double seconds, {double playerX = 236, bool hidden = false})`, which ticks in 0.05s steps.

```dart
test('far loud noise makes her sleepwalk, sniff 4s and come back drowsy', () {
  final g = GooseBrain(bedX: 502, tuning: const Tuning());
  g.hear(const Noise(x: 113, loudness: 2));
  expect(g.state, GooseState.sleepwalk);
  run(g, (502 - 113) / 50 + 0.1);        // walk there
  expect(g.sniffing, isTrue);
  run(g, 4 + (502 - 113) / 50 + 0.1);    // sniff + walk back
  expect([g.state, g.x], [GooseState.drowsy, 502]);
});
test('a second loud noise while sniffing wakes her', () { /* hear(113,2), walk there, hear(Noise(x: 62, loudness: 2)) → awake, wakeCause noise */ });
test('a small noise far away does nothing', () { /* hear(Noise(x: 62, loudness: 1)) → asleep, meter 0 */ });
test('loud noise in the ear zone wakes, then chase after 0.3s', () {
  final g = GooseBrain(bedX: 502, tuning: const Tuning())..hear(const Noise(x: 667, loudness: 3));
  expect(g.state, GooseState.awake);
  run(g, 0.35); expect(g.state, GooseState.chase);
});
test('rolls over every 8s for 2s', () { /* run 7.9 → !rollingOver; run 0.2 → rollingOver; run 2 → !rollingOver */ });
test('a 2+ link chain mid-chase distracts her for 4s', () { /* wake, run 0.35, hear(Noise(x: 640, loudness: 1), chainLinks: 2) → distracted; run 4.1 → chase */ });
test('hiding 3s loses her; patrol, then drowsy in bed', () { /* wake, run 0.35, run(3.1, hidden: true) → lostYou; run(6) → drowsy, inBed */ });
test('chase gives up after 12s', () { /* wake, run(0.35 + 12.1, playerX: 844) → lostYou */ });
test('suspicious settles: hold still and it drains back to asleep', () { /* hear(Noise(x: 502, loudness: 2)) → suspicious; run 7.1 → asleep */ });
```

- [ ] **Step 2: Run** `flutter test test/game/goose_brain_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `GooseBrain` as a `switch` on `state` in `tick`. Sleepwalk sub-phases are an enum `_Walk { out, sniff, back }`.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(game): add goose brain v2 state machine`

---

### Task 6: Night simulation and the three routes

**Files:**
- Create: `lib/game/night_sim.dart`
- Test: `test/game/night_sim_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `sealed class SimEvent` with `NoiseMade(Noise noise, bool touchedEar, LinkFired? link)`, `GooseChanged(GooseState from, GooseState to)`, `LootGrabbed(String id)`, `CaughtStarted()`, `Escaped(List<String> loot)`.
  - `enum Outcome { escaped, caught }`
  - `class NightSim { NightSim(Level level, {Tuning tuning = const Tuning()}); double get playerX; bool get sneaking; bool get hidden; GooseBrain get goose; ChainRunner get chain; List<String> get carried; Outcome? get outcome; List<LinkFired> get wakeChain; void setMove(double dir); void setSneak(bool on); void poke(String spotId); bool grab(String lootId); bool toggleHide(); void tick(double dt); List<SimEvent> takeEvents(); }`
- Rules:
  - `tick(dt)` splits `dt` into steps of at most `maxStep` (1/60s). Each step: move the player (`walkSpeed` or `sneakSpeed` × `dir`, clamped to `0..844`, frozen while hidden), tick the chain and feed each fired noise to `goose.hear` (`chainLinks` = that link number), then tick the goose.
  - Walking without sneak makes a loudness-0 footstep every `footstepEvery` (0.4s). Sneaking makes none.
  - Crossing a squeaker spot's x without sneaking calls `chain.poke` on it. Sneak skips it.
  - Carrying loot with `squeaks: true` while walking without sneak makes a loudness-1 noise every `squeakCarryEvery`.
  - `grab(id)` needs the player within `reach` of the loot x. For the guarded loot: allowed when `!goose.inBed`, or `goose.rollingOver`, or the goose is in `awake/chase/distracted`. Otherwise it calls `goose.wake(WakeCause.grabbedGuarded)` and returns `false`.
  - `toggleHide()` needs the player within `reach` of a hide spot.
  - Caught: in `chase` and not hidden, with the goose within `caughtDistance`. Emit `CaughtStarted`, then set `outcome = caught` after `caughtAnim` (1.2s).
  - Escaped: `playerX >= exitX` sets `outcome = escaped` and emits `Escaped(carried)`.
  - `wakeChain` holds the `LinkFired`s of the chain that woke her, so Phase 2's Caught screen can recap the chain.
  - After `outcome` is set, `tick` and all inputs are no-ops.

- [ ] **Step 1: Write the failing route tests.** Each one is a script of inputs and ticks. Helper `walkTo(sim, x)` sets the direction and ticks until the player reaches `x`.

```dart
test('Trickster: lure her with the glass, take the egg, walk out', () {
  final s = NightSim(night3())..setSneak(true);
  s.poke('counterLeft');                 // stands in for the Phase 3 sock throw
  s.tick(0.5);
  expect(s.goose.state, GooseState.sleepwalk);
  walkTo(s, 561);
  expect(s.grab('egg'), isTrue);
  walkTo(s, 770);
  expect(s.outcome, Outcome.escaped);
  expect(s.carried, contains('egg'));
});
test('Ghost: grab the egg during the roll-over window, never wake her', () { /* sneak to 561; tick until goose.rollingOver; grab → true; sneak out; outcome escaped; no GooseChanged to awake in events */ });
test('Chaos: robot into the clock wakes her, grab the egg, run out over the plank', () {
  /* sneak to 614; poke sideTable; walkTo 561 (sneaking); tick until goose.state == awake (~2.2s);
     grab('egg') → true (allowed while awake); setSneak(false); walkTo 770.
     Expect: outcome escaped; carried contains egg; events contain a NoiseMade whose link.objectId == 'plank'
     (running over the plank started the second chain). The plank→clock distraction itself is pinned in Task 5. */
});
test('grabbing the egg while she sleeps wakes her', () { /* sneak to 561 at t where !rollingOver; grab → false; goose awake; wakeCause grabbedGuarded */ });
test('caught: chase reaches the burglar, outcome after 1.2s', () { /* wake, stand still; CaughtStarted then outcome caught 1.2s later; wakeChain non-empty */ });
test('a hidden burglar is not caught', () { /* sneak to 720; toggleHide → true; poke sideTable; tick 6s → outcome null, goose.state lostYou */ });
test('one big tick equals many small ticks', () {
  final a = NightSim(night3())..poke('sideTable'); a.tick(2.0);
  final b = NightSim(night3())..poke('sideTable'); for (var i = 0; i < 200; i++) { b.tick(0.01); }
  expect(a.goose.state, b.goose.state);
  expect(a.takeEvents().map((e) => e.runtimeType), b.takeEvents().map((e) => e.runtimeType));
});
test('walking makes footsteps, sneaking does not', () { /* walk 1s near bed → meter > 0; reset; sneak 1s → meter 0 */ });
```

- [ ] **Step 2: Run** `flutter test test/game/night_sim_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `NightSim`.
- [ ] **Step 4: Run** `flutter test`. Expected: all tests PASS (the existing 16 plus `test/game/`). Run `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(game): add night simulation with Night 3 routes`

---

## Open design questions (for the user, not blockers)

- The "Noise Chain Reaction" board's scenario A (glass → pot → robot → HONK) predates Gameplay 2.0, where the same glass-into-pot CLANG is the Trickster *lure*. This plan follows Gameplay 2.0: the pot has no link to the robot.
- The design doesn't say where the loose plank and hide spots sit on Night 3. This plan uses plank x=640, hide spots x=180 (kitchen) and x=720 (hall coat rack).
- All *(tuning)* numbers are guesses to adjust once Phase 2 makes the game playable.
