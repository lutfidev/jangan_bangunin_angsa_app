/// What socks pay for (Gameplay 2.0: "Earned with socks — never sold").
/// The canvas asks 6 socks for the kazoo and 9 for Mirror; with one night
/// of three socks those could never open, so the ladder fits one night.
/// Raise these as nights are added.
enum Unlock {
  lightSleeper(1),
  kazoo(2),
  mirror(3);

  const Unlock(this.socks);

  /// Socks, summed over every night, that open it.
  final int socks;

  bool openWith(int have) => have >= socks;
}
