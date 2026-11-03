// The canvas art of Milo and Gertrude, cut into parts that can move on their
// own. Every element is copied from burglar_svgs.dart and goose_svgs.dart;
// only the grouping is new, and each limb that was drawn as one path with
// two subpaths is split into one path per limb. Drawn with no bends, a rig
// makes the same picture as the whole pose.
import 'dart:ui' show Offset;

import 'art.dart' show BurglarPose, GooseMood;
import 'rig.dart';

const Map<BurglarPose, RigSpec> miloRigs = {
  BurglarPose.sneak: RigSpec(
    label: 'Milo Muffle tiptoeing',
    width: 120,
    height: 150,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="62" cy="144" rx="34" ry="5" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M50 112 L44 134" fill="none" stroke-width="13"/>'
        r'<path d="M50 112 L44 134" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="42" cy="139" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>',
        pivot: Offset(50, 112),
      ),
      RigLayer(
        'legB',
        r'<path d="M72 112 L80 130" fill="none" stroke-width="13"/>'
        r'<path d="M72 112 L80 130" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="84" cy="134" rx="11" ry="6" fill="#FFC14D" stroke-width="3" transform="rotate(-20 84 134)"/>',
        pivot: Offset(72, 112),
      ),
      RigLayer(
        'body',
        r'<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>'
        r'<path d="M48 104 Q62 110 76 104" fill="none" stroke-width="2.5"/>'
        r'<path d="M56 72 L54 82 M70 72 L72 82" fill="none" stroke="#FFC14D" stroke-width="2.5"/>',
        pivot: Offset(62, 112),
      ),
      RigLayer(
        'head',
        r'<circle cx="62" cy="44" r="28" fill="#2F6F73"/>'
        r'<circle cx="66" cy="48" r="19" fill="#F2B48A" stroke-width="3"/>'
        r'<path d="M45 42 Q66 34 87 42 L87 52 Q66 46 45 52 Z" fill="#F0533B" stroke-width="3"/>'
        r'<circle cx="59" cy="46" r="5.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="75" cy="46" r="5.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="61" cy="45" r="2.6" fill="#1C1A2B" stroke="none"/>'
        r'<circle cx="77" cy="45" r="2.6" fill="#1C1A2B" stroke="none"/>'
        r'<circle cx="74" cy="55" r="3" fill="#E39A70" stroke="none"/>'
        r'<path d="M64 61 Q68 59 72 61" fill="none" stroke-width="2.5"/>',
        pivot: Offset(62, 68),
      ),
      RigLayer(
        'armA',
        r'<path d="M40 88 Q30 74 42 63" fill="none" stroke-width="14"/>'
        r'<path d="M40 88 Q30 74 42 63" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="42" cy="61" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(40, 88),
      ),
      RigLayer(
        'armB',
        r'<path d="M84 88 Q98 78 92 63" fill="none" stroke-width="14"/>'
        r'<path d="M84 88 Q98 78 92 63" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="92" cy="61" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(84, 88),
      ),
    ],
  ),
  BurglarPose.carry: RigSpec(
    label: 'Milo Muffle straining to carry loot overhead',
    width: 120,
    height: 150,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="62" cy="144" rx="38" ry="5" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M48 112 L38 134" fill="none" stroke-width="13"/>'
        r'<path d="M48 112 L38 134" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="34" cy="139" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>',
        pivot: Offset(48, 112),
      ),
      RigLayer(
        'legB',
        r'<path d="M76 112 L86 134" fill="none" stroke-width="13"/>'
        r'<path d="M76 112 L86 134" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="90" cy="139" rx="11" ry="6" fill="#FFC14D" stroke-width="3"/>',
        pivot: Offset(76, 112),
      ),
      RigLayer(
        'body',
        r'<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>'
        r'<path d="M48 104 Q62 110 76 104" fill="none" stroke-width="2.5"/>',
        pivot: Offset(62, 112),
      ),
      RigLayer(
        'armA',
        r'<path d="M40 82 Q26 50 36 14" fill="none" stroke-width="14"/>'
        r'<path d="M40 82 Q26 50 36 14" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="36" cy="12" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(40, 82),
      ),
      RigLayer(
        'armB',
        r'<path d="M84 82 Q98 50 88 14" fill="none" stroke-width="14"/>'
        r'<path d="M84 82 Q98 50 88 14" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="88" cy="12" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(84, 82),
      ),
      RigLayer(
        'head',
        r'<circle cx="62" cy="46" r="28" fill="#2F6F73"/>'
        r'<circle cx="64" cy="50" r="19" fill="#F2B48A" stroke-width="3"/>'
        r'<path d="M43 44 Q64 36 85 44 L85 54 Q64 48 43 54 Z" fill="#F0533B" stroke-width="3"/>'
        r'<path d="M52 45 L59 48.5 L52 52 M76 45 L69 48.5 L76 52" fill="none" stroke-width="3"/>'
        r'<rect x="57" y="57" width="14" height="7" rx="2" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<path d="M57 60.5 L71 60.5" fill="none" stroke-width="1.5"/>'
        r'<path d="M96 30 Q101 39 96 42 Q91 39 96 30 Z" fill="#9FD3F0" stroke-width="2.5"/>',
        pivot: Offset(62, 70),
      ),
    ],
  ),
  BurglarPose.panic: RigSpec(
    label: 'Milo Muffle running in panic',
    width: 120,
    height: 150,
    leanAngle: 10 * 3.141592653589793 / 180,
    leanPivot: Offset(60, 100),
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="62" cy="144" rx="36" ry="5" fill="#000000" opacity="0.2" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M50 112 L34 124 L28 136" fill="none" stroke-width="13"/>'
        r'<path d="M50 112 L34 124 L28 136" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="26" cy="140" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>',
        pivot: Offset(50, 112),
      ),
      RigLayer(
        'legB',
        r'<path d="M72 112 L88 120 L100 112" fill="none" stroke-width="13"/>'
        r'<path d="M72 112 L88 120 L100 112" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="104" cy="110" rx="11" ry="6" fill="#FFC14D" stroke-width="3" transform="rotate(-30 104 110)"/>',
        pivot: Offset(72, 112),
      ),
      RigLayer(
        'body',
        r'<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>',
        pivot: Offset(62, 112),
      ),
      RigLayer(
        'head',
        r'<circle cx="62" cy="44" r="28" fill="#2F6F73"/>'
        r'<circle cx="67" cy="48" r="19" fill="#F2B48A" stroke-width="3"/>'
        r'<path d="M46 42 Q67 34 88 42 L88 52 Q67 46 46 52 Z" fill="#F0533B" stroke-width="3"/>'
        r'<circle cx="60" cy="46" r="6.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="77" cy="46" r="6.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="61" cy="46" r="1.8" fill="#1C1A2B" stroke="none"/>'
        r'<circle cx="78" cy="46" r="1.8" fill="#1C1A2B" stroke="none"/>'
        r'<ellipse cx="72" cy="60" rx="5" ry="6" fill="#1C1A2B" stroke="none"/>',
        pivot: Offset(62, 68),
      ),
      RigLayer(
        'armA',
        r'<path d="M38 86 Q22 78 14 62" fill="none" stroke-width="14"/>'
        r'<path d="M38 86 Q22 78 14 62" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="14" cy="60" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(38, 86),
      ),
      RigLayer(
        'armB',
        r'<path d="M86 86 Q104 90 112 78" fill="none" stroke-width="14"/>'
        r'<path d="M86 86 Q104 90 112 78" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="112" cy="76" r="6.5" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(86, 86),
      ),
      RigLayer(
        'sweat',
        r'<path d="M30 20 Q34 28 30 31 Q26 28 30 20 Z M100 28 Q104 36 100 39 Q96 36 100 28 Z" fill="#9FD3F0" stroke-width="2.5"/>',
        wrapped: false,
      ),
    ],
  ),
  BurglarPose.crawl: RigSpec(
    label: 'Milo Muffle crawling on all fours',
    width: 120,
    height: 150,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="62" cy="144" rx="46" ry="5" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M86 116 L98 138" fill="none" stroke-width="13"/>'
        r'<path d="M86 116 L98 138" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="104" cy="139" rx="11" ry="6" fill="#FFC14D" stroke-width="3"/>',
        pivot: Offset(86, 116),
      ),
      RigLayer(
        'legB',
        r'<path d="M72 118 L78 138" fill="none" stroke-width="13"/>'
        r'<path d="M72 118 L78 138" fill="none" stroke="#2A2840" stroke-width="6"/>'
        r'<ellipse cx="82" cy="140" rx="10" ry="5.5" fill="#5CC9A7" stroke-width="3"/>',
        pivot: Offset(72, 118),
      ),
      RigLayer(
        'body',
        r'<path d="M30 112 C30 92 48 84 70 84 C94 84 108 94 106 112 C104 124 90 128 70 128 C48 128 30 124 30 112 Z" fill="#2F6F73"/>'
        r'<path d="M60 118 Q74 124 88 118" fill="none" stroke-width="2.5"/>',
        pivot: Offset(70, 110),
      ),
      RigLayer(
        'armA',
        r'<path d="M40 112 L30 136" fill="none" stroke-width="14"/>'
        r'<path d="M40 112 L30 136" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="29" cy="138" r="6" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(40, 112),
      ),
      RigLayer(
        'armB',
        r'<path d="M56 116 L52 136" fill="none" stroke-width="14"/>'
        r'<path d="M56 116 L52 136" fill="none" stroke="#2F6F73" stroke-width="7"/>'
        r'<circle cx="52" cy="138" r="6" fill="#F2B48A" stroke-width="3"/>',
        pivot: Offset(56, 116),
      ),
      RigLayer(
        'head',
        r'<circle cx="32" cy="94" r="24" fill="#2F6F73"/>'
        r'<circle cx="28" cy="98" r="16" fill="#F2B48A" stroke-width="3"/>'
        r'<path d="M12 92 Q28 85 44 92 L44 101 Q28 95 12 101 Z" fill="#F0533B" stroke-width="3"/>'
        r'<circle cx="22" cy="96" r="4.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="35" cy="96" r="4.5" fill="#FFFFFF" stroke-width="2.5"/>'
        r'<circle cx="21" cy="95" r="2.2" fill="#1C1A2B" stroke="none"/>'
        r'<circle cx="34" cy="95" r="2.2" fill="#1C1A2B" stroke="none"/>'
        r'<path d="M22 108 Q26 106 30 108" fill="none" stroke-width="2.5"/>',
        pivot: Offset(48, 100),
      ),
    ],
  ),
};

/// Gertrude's art faces left; "forward" for her is -x.
const Map<GooseMood, RigSpec> gooseRigs = {
  GooseMood.sleep: RigSpec(
    label: 'Gertrude the goose, asleep in her nightcap',
    width: 200,
    height: 160,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="108" cy="148" rx="74" ry="7" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'body',
        r'<path d="M150 96 L190 80 L182 104 L170 114 Z" fill="#FBF8F1"/>'
        r'<path d="M38 112 C38 80 78 68 118 72 C156 75 178 92 178 114 C178 134 152 144 110 144 C68 144 38 136 38 112 Z" fill="#FBF8F1"/>'
        r'<path d="M84 100 C108 84 150 88 166 106 C150 122 112 124 90 114 Z" fill="#E4DCCB" stroke-width="3.5"/>'
        r'<path d="M112 104 C126 100 140 102 150 108 M106 112 C120 110 134 112 144 116" fill="none" stroke-width="2.5" opacity="0.45"/>',
        pivot: Offset(110, 140),
      ),
      RigLayer(
        'head',
        r'<circle cx="60" cy="98" r="23" fill="#FBF8F1"/>'
        r'<path d="M40 100 C30 100 20 104 15 111 C26 115 36 113 43 108 Z" fill="#FF8A2A"/>'
        r'<path d="M52 95 Q58 101 65 95" fill="none" stroke-width="3.5"/>'
        r'<ellipse cx="68" cy="107" rx="5" ry="3" fill="#F7A6A0" stroke="none" opacity="0.85"/>'
        r'<path d="M40 86 Q60 66 86 80 L124 98 Z" fill="#4C5BA8"/>'
        r'<path d="M37 88 Q58 72 87 82" fill="none" stroke-width="12"/>'
        r'<path d="M37 88 Q58 72 87 82" fill="none" stroke="#FBF8F1" stroke-width="5"/>'
        r'<circle cx="126" cy="99" r="7.5" fill="#FFC14D" stroke-width="3"/>',
        pivot: Offset(80, 110),
      ),
    ],
  ),
  GooseMood.suspicious: RigSpec(
    label: 'Gertrude the goose, suspicious, one eye open',
    width: 200,
    height: 160,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="108" cy="148" rx="74" ry="7" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'body',
        r'<path d="M150 96 L190 80 L182 104 L170 114 Z" fill="#FBF8F1"/>'
        r'<path d="M38 112 C38 80 78 68 118 72 C156 75 178 92 178 114 C178 134 152 144 110 144 C68 144 38 136 38 112 Z" fill="#FBF8F1"/>'
        r'<path d="M84 100 C108 84 150 88 166 106 C150 122 112 124 90 114 Z" fill="#E4DCCB" stroke-width="3.5"/>',
        pivot: Offset(110, 140),
      ),
      RigLayer(
        'head',
        r'<path d="M72 110 C56 92 54 70 62 48" fill="none" stroke-width="27"/>'
        r'<path d="M72 110 C56 92 54 70 62 48" fill="none" stroke="#FBF8F1" stroke-width="19"/>'
        r'<circle cx="62" cy="42" r="19" fill="#FBF8F1"/>'
        r'<path d="M44 44 C34 44 24 47 18 52 C28 56 38 54 46 50 Z" fill="#FF8A2A"/>'
        r'<circle cx="59" cy="38" r="6.5" fill="#FFFFFF" stroke-width="3"/>'
        r'<circle cx="57" cy="39.5" r="3" fill="#1C1A2B" stroke="none"/>'
        r'<path d="M52.5 38 A6.5 6.5 0 0 1 65.5 38 Z" fill="#E4DCCB" stroke-width="3"/>'
        r'<path d="M50 28 L66 31" fill="none" stroke-width="4"/>'
        r'<path d="M48 30 Q60 6 94 14 Q84 20 80 30 Z" fill="#4C5BA8"/>'
        r'<path d="M46 31 Q62 22 81 31" fill="none" stroke-width="11"/>'
        r'<path d="M46 31 Q62 22 81 31" fill="none" stroke="#FBF8F1" stroke-width="5"/>'
        r'<circle cx="96" cy="14" r="6.5" fill="#FFC14D" stroke-width="3"/>',
        pivot: Offset(74, 108),
      ),
    ],
  ),
  GooseMood.awake: RigSpec(
    label: 'Gertrude the goose, wide awake and furious',
    width: 200,
    height: 160,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="108" cy="150" rx="70" ry="7" fill="#000000" opacity="0.22" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M98 126 L94 148 L80 150" fill="none" stroke-width="9"/>'
        r'<path d="M98 126 L94 148 L80 150" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(98, 126),
      ),
      RigLayer(
        'legB',
        r'<path d="M120 126 L124 148 L138 150" fill="none" stroke-width="9"/>'
        r'<path d="M120 126 L124 148 L138 150" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(120, 126),
      ),
      RigLayer(
        'body',
        r'<g transform="translate(0 -14)">'
        r'<path d="M150 96 L192 74 L184 102 L170 114 Z" fill="#FBF8F1"/>'
        r'<path d="M38 112 C38 80 78 68 118 72 C156 75 178 92 178 114 C178 134 152 144 110 144 C68 144 38 136 38 112 Z" fill="#FBF8F1"/>'
        r'<path d="M96 90 C100 54 136 34 170 40 C160 60 142 80 116 98 Z" fill="#E4DCCB" stroke-width="3.5"/>'
        r'<path d="M118 70 L150 50 M112 82 L146 66" fill="none" stroke-width="2.5" opacity="0.45"/>'
        r'</g>',
        pivot: Offset(110, 120),
      ),
      RigLayer(
        'head',
        r'<path d="M70 98 C54 80 50 54 58 32" fill="none" stroke-width="27"/>'
        r'<path d="M70 98 C54 80 50 54 58 32" fill="none" stroke="#FBF8F1" stroke-width="19"/>'
        r'<circle cx="58" cy="26" r="19" fill="#FBF8F1"/>'
        r'<path d="M30 30 L44 30 L40 38 Z" fill="#7A2E3A" stroke-width="3"/>'
        r'<path d="M42 22 C30 20 18 22 9 28 C21 31 33 31 43 28 Z" fill="#FF8A2A"/>'
        r'<path d="M42 32 C32 36 22 42 15 47 C27 47 37 43 44 37 Z" fill="#FF8A2A"/>'
        r'<circle cx="57" cy="22" r="7.5" fill="#FFFFFF" stroke-width="3"/>'
        r'<circle cx="54" cy="23" r="3.5" fill="#1C1A2B" stroke="none"/>'
        r'<path d="M46 11 L68 18" fill="none" stroke-width="5.5"/>'
        r'<g transform="rotate(24 140 18)">'
        r'<path d="M120 26 Q132 6 156 12 Q148 18 144 28 Z" fill="#4C5BA8"/>'
        r'<path d="M118 27 Q131 21 146 28" fill="none" stroke-width="10"/>'
        r'<path d="M118 27 Q131 21 146 28" fill="none" stroke="#FBF8F1" stroke-width="4"/>'
        r'<circle cx="158" cy="12" r="6" fill="#FFC14D" stroke-width="3"/>'
        r'</g>',
        pivot: Offset(70, 98),
      ),
    ],
  ),
  GooseMood.chase: RigSpec(
    label: 'Gertrude the goose, sprinting with wings up',
    width: 200,
    height: 160,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="120" cy="150" rx="62" ry="6" fill="#000000" opacity="0.2" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M112 118 L98 138 L84 138" fill="none" stroke-width="9"/>'
        r'<path d="M112 118 L98 138 L84 138" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(112, 118),
      ),
      RigLayer(
        'legB',
        r'<path d="M134 118 L148 134 L162 130" fill="none" stroke-width="9"/>'
        r'<path d="M134 118 L148 134 L162 130" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(134, 118),
      ),
      RigLayer(
        'wingFar',
        r'<path d="M96 80 C88 50 104 26 124 18 C126 42 118 62 108 82 Z" fill="#D9D0BE" stroke-width="3.5"/>',
        pivot: Offset(108, 82),
      ),
      RigLayer(
        'body',
        r'<path d="M178 86 L198 70 L194 98 Z" fill="#FBF8F1"/>'
        r'<path d="M60 92 C70 70 120 64 156 74 C180 80 190 96 182 110 C172 124 132 126 96 120 C70 116 54 108 60 92 Z" fill="#FBF8F1"/>',
        pivot: Offset(120, 110),
      ),
      RigLayer(
        'wingNear',
        r'<path d="M110 80 C110 42 140 24 172 26 C166 48 148 68 128 82 Z" fill="#E4DCCB" stroke-width="3.5"/>',
        pivot: Offset(120, 82),
      ),
      RigLayer(
        'head',
        r'<path d="M74 96 C56 92 44 84 36 72" fill="none" stroke-width="27"/>'
        r'<path d="M74 96 C56 92 44 84 36 72" fill="none" stroke="#FBF8F1" stroke-width="19"/>'
        r'<circle cx="36" cy="64" r="17" fill="#FBF8F1"/>'
        r'<path d="M22 60 C14 58 6 60 2 64 C10 67 18 67 24 65 Z" fill="#FF8A2A"/>'
        r'<path d="M22 70 C14 74 8 78 3 81 C11 81 19 79 25 73 Z" fill="#FF8A2A"/>'
        r'<circle cx="37" cy="59" r="6.5" fill="#FFFFFF" stroke-width="3"/>'
        r'<circle cx="34" cy="60" r="3" fill="#1C1A2B" stroke="none"/>'
        r'<path d="M28 49 L46 55" fill="none" stroke-width="5"/>',
        pivot: Offset(76, 96),
      ),
    ],
  ),
  GooseMood.investigate: RigSpec(
    label: 'Gertrude the goose sleepwalking, sniffing toward a noise',
    width: 200,
    height: 160,
    layers: [
      RigLayer(
        'shadow',
        r'<ellipse cx="112" cy="150" rx="66" ry="7" fill="#000000" opacity="0.2" stroke="none"/>',
        wrapped: false,
      ),
      RigLayer(
        'legA',
        r'<path d="M104 120 L98 146 L84 148" fill="none" stroke-width="9"/>'
        r'<path d="M104 120 L98 146 L84 148" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(104, 120),
      ),
      RigLayer(
        'legB',
        r'<path d="M128 120 L134 144 L148 146" fill="none" stroke-width="9"/>'
        r'<path d="M128 120 L134 144 L148 146" fill="none" stroke="#FF8A2A" stroke-width="4.5"/>',
        pivot: Offset(128, 120),
      ),
      RigLayer(
        'body',
        r'<g transform="translate(0 -18) rotate(-6 110 100)">'
        r'<path d="M150 96 L190 80 L182 104 L170 114 Z" fill="#FBF8F1"/>'
        r'<path d="M38 112 C38 80 78 68 118 72 C156 75 178 92 178 114 C178 134 152 144 110 144 C68 144 38 136 38 112 Z" fill="#FBF8F1"/>'
        r'<path d="M84 100 C108 84 150 88 166 106 C150 122 112 124 90 114 Z" fill="#E4DCCB" stroke-width="3.5"/>'
        r'</g>',
        pivot: Offset(110, 120),
      ),
      RigLayer(
        'head',
        r'<path d="M66 90 C48 98 36 110 30 120" fill="none" stroke-width="27"/>'
        r'<path d="M66 90 C48 98 36 110 30 120" fill="none" stroke="#FBF8F1" stroke-width="19"/>'
        r'<circle cx="28" cy="122" r="17" fill="#FBF8F1"/>'
        r'<path d="M14 126 C6 130 2 136 2 143 C10 141 16 137 20 132 Z" fill="#FF8A2A"/>'
        r'<path d="M21 117 Q27 121 33 117" fill="none" stroke-width="3.5"/>'
        r'<path d="M14 110 Q28 96 44 108 L58 134 Z" fill="#4C5BA8"/>'
        r'<path d="M12 112 Q28 100 46 109" fill="none" stroke-width="10"/>'
        r'<path d="M12 112 Q28 100 46 109" fill="none" stroke="#FBF8F1" stroke-width="4"/>'
        r'<circle cx="59" cy="137" r="6" fill="#FFC14D" stroke-width="3"/>',
        pivot: Offset(68, 90),
      ),
    ],
  ),
};
