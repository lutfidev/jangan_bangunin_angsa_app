/// Reading a save blob that may be any shape: each helper returns null (or
/// empty) for a value of the wrong type, so the caller keeps its default.
library;

Map<String, Object?> jsonMap(Object? value) => value is Map<String, Object?> ? value : const {};

bool? jsonBool(Map<String, Object?> json, String key) => switch (json[key]) {
  final bool b => b,
  _ => null,
};

/// An int (a whole double is fine), clamped to [min]..[max].
int? jsonInt(Map<String, Object?> json, String key, {required int min, required int max}) => switch (json[key]) {
  final num n when n.isFinite && n == n.roundToDouble() => n.toInt().clamp(min, max),
  _ => null,
};

/// The strings in a list; anything else in it is skipped.
List<String> jsonStrings(Object? value) => value is List ? [for (final e in value) if (e is String) e] : const [];

/// The value of [values] named [name], or null.
T? jsonEnum<T extends Enum>(List<T> values, Object? name) => values.where((v) => v.name == name).firstOrNull;
