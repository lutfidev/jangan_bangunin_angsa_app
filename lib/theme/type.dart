import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Bagel Fat One: logo, headings, comic SFX words. Never body text.
TextStyle display(double size, {Color color = Palette.ink, double? height}) =>
    GoogleFonts.bagelFatOne(fontSize: size, color: color, height: height);

/// Bricolage Grotesque: UI labels, body, numbers.
TextStyle ui(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color color = Palette.ink,
  double? height,
  double? letterSpacing,
}) => GoogleFonts.bricolageGrotesque(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// HUD label: 11 / 800 caps with tracking.
TextStyle hudLabel({
  Color color = Palette.moonlight,
  double size = 11,
  double spacing = 1.5,
}) => ui(size, weight: FontWeight.w800, color: color, letterSpacing: spacing);
