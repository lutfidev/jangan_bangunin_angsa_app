import 'dart:math' as math;

import 'level.dart';
import 'noise.dart';
import 'tuning.dart';

/// One link of a chain going off: the object at [spotId] made [noise].
class LinkFired {
  const LinkFired({
    required this.chainId,
    required this.link,
    required this.objectId,
    required this.spotId,
    required this.noise,
  });

  final int chainId;

  /// 1-based position in its chain; the numbered badge the player sees.
  final int link;
  final String objectId;
  final String spotId;
  final Noise noise;

  @override
  String toString() => 'LinkFired(#$chainId.$link $objectId @$spotId, $noise)';
}

/// Runs the Noise Chain Reaction over a level's graph. Links join spots, so
/// moving a portable object to a snap spot rewires the chain.
class ChainRunner {
  ChainRunner(this.level, this.tuning)
    : _objectAt = {for (final o in level.objects) o.spot: o.id},
      _objects = {for (final o in level.objects) o.id: o};

  final Level level;
  final Tuning tuning;

  final Map<String, String> _objectAt;
  final Map<String, LevelObject> _objects;
  final Set<String> _spent = {};
  final Map<int, Set<String>> _visited = {};
  final List<_Pending> _pending = [];
  final List<LinkFired> _fired = [];

  double _now = 0;
  int _chains = 0;
  int _seq = 0;

  String? objectAt(String spotId) => _objectAt[spotId];

  bool isSpent(String objectId) => _spent.contains(objectId);

  /// Something outside the chain (a bump, a throw, a step) sets off [spotId].
  void poke(String spotId) {
    final chainId = ++_chains;
    _visited[chainId] = {};
    _schedule(_now, spotId, inLoudness: 1, chainId: chainId, link: 1);
  }

  /// Rearrange: carry a portable object to a free snap spot.
  void move(String objectId, String toSpot) {
    final object = _objects[objectId];
    final spot = level.spots[toSpot];
    if (object == null || !object.portable) throw StateError('$objectId is not portable');
    if (spot == null || !spot.snap) throw StateError('$toSpot is not a snap spot');
    final from = _spotOf(objectId);
    if (from == toSpot) return;
    if (_objectAt.containsKey(toSpot)) throw StateError('$toSpot is taken');
    _objectAt
      ..remove(from)
      ..[toSpot] = objectId;
  }

  void tick(double dt) {
    _now += dt;
    while (true) {
      _Pending? next;
      for (final p in _pending) {
        if (p.at <= _now && (next == null || p.at < next.at || (p.at == next.at && p.seq < next.seq))) {
          next = p;
        }
      }
      if (next == null) break;
      _pending.remove(next);
      final ringing = next.ringing;
      if (ringing == null) {
        _hit(next);
      } else {
        // The chimer may have been carried off while it waited.
        final spotId = _spotOf(ringing);
        _visited[next.chainId]!.add(spotId);
        _sound(next, ringing, spotId);
      }
    }
  }

  List<LinkFired> takeFired() {
    final fired = List.of(_fired);
    _fired.clear();
    return fired;
  }

  void _hit(_Pending p) {
    final objectId = _objectAt[p.spotId];
    if (objectId == null || _spent.contains(objectId)) return;
    if (!_visited[p.chainId]!.add(p.spotId)) return;
    if (_objects[objectId]!.type == ObjectType.chimer) {
      _schedule(p.at + tuning.chimerDelay, p.spotId,
          inLoudness: p.inLoudness, chainId: p.chainId, link: p.link, ringing: objectId);
    } else {
      _sound(p, objectId, p.spotId);
    }
  }

  void _sound(_Pending p, String objectId, String spotId) {
    final object = _objects[objectId]!;
    final loudness = switch (object.type) {
      ObjectType.amplifier => math.min(3, 2 * p.inLoudness),
      ObjectType.chimer => 3,
      _ => 1,
    };
    if (_isOneShot(object.type)) _spent.add(object.id);
    _fired.add(LinkFired(
      chainId: p.chainId,
      link: p.link,
      objectId: object.id,
      spotId: spotId,
      noise: Noise(x: level.spots[spotId]!.x, loudness: loudness),
    ));

    // It pokes whatever sits in its reach: the first linked spot holding an object.
    for (final link in level.linksFrom(spotId)) {
      if (_objectAt.containsKey(link.to)) {
        _schedule(p.at + link.delay, link.to, inLoudness: loudness, chainId: p.chainId, link: p.link + 1);
        break;
      }
    }
  }

  void _schedule(double at, String spotId,
      {required int inLoudness, required int chainId, required int link, String? ringing}) {
    _pending.add(_Pending(at, _seq++, spotId, inLoudness, chainId, link, ringing));
  }

  String _spotOf(String objectId) => _objectAt.entries.firstWhere((e) => e.value == objectId).key;

  static bool _isOneShot(ObjectType type) =>
      type == ObjectType.tipper || type == ObjectType.walker || type == ObjectType.roller;
}

class _Pending {
  _Pending(this.at, this.seq, this.spotId, this.inLoudness, this.chainId, this.link, this.ringing);

  final double at;
  final int seq;
  final String spotId;
  final int inLoudness;
  final int chainId;
  final int link;

  /// The chimer that was hit and is waiting to ring. [spotId] is only where
  /// it was hit; it rings wherever it stands by then.
  final String? ringing;
}
