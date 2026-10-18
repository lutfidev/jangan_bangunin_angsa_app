import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jangan_bangunin_angsa_app/theme/type.dart';

/// Runs before every test file. Tests use the bundled fonts, never HTTP, and
/// the fonts are loaded up front so layouts (and overflow checks) see the real
/// glyph metrics instead of the square test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  display(10);
  for (final weight in [FontWeight.w400, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
    ui(10, weight: weight);
  }
  // Throws if any of them is missing from assets/google_fonts/.
  await GoogleFonts.pendingFonts();

  await testMain();
}
