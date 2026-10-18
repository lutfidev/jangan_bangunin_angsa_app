// Generated from the design canvas; edit the art there, not here. The crawl
// pose is the exception: the canvas has none (docs/DESIGN_NOTES.md, langkah 4).
part of 'art.dart';

const Map<BurglarPose, ({String label, String svg})> _burglarSvgs = {
  BurglarPose.sneak: (
    label: 'Milo Muffle tiptoeing',
    svg: r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150">
<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="62" cy="144" rx="34" ry="5" fill="#000000" opacity="0.22" stroke="none"/>
<path d="M50 112 L44 134 M72 112 L80 130" fill="none" stroke-width="13"/>
<path d="M50 112 L44 134 M72 112 L80 130" fill="none" stroke="#2A2840" stroke-width="6"/>
<ellipse cx="42" cy="139" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>
<ellipse cx="84" cy="134" rx="11" ry="6" fill="#FFC14D" stroke-width="3" transform="rotate(-20 84 134)"/>
<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>
<path d="M48 104 Q62 110 76 104" fill="none" stroke-width="2.5"/>
<circle cx="62" cy="44" r="28" fill="#2F6F73"/>
<circle cx="66" cy="48" r="19" fill="#F2B48A" stroke-width="3"/>
<path d="M45 42 Q66 34 87 42 L87 52 Q66 46 45 52 Z" fill="#F0533B" stroke-width="3"/>
<circle cx="59" cy="46" r="5.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="75" cy="46" r="5.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="61" cy="45" r="2.6" fill="#1C1A2B" stroke="none"/>
<circle cx="77" cy="45" r="2.6" fill="#1C1A2B" stroke="none"/>
<circle cx="74" cy="55" r="3" fill="#E39A70" stroke="none"/>
<path d="M64 61 Q68 59 72 61" fill="none" stroke-width="2.5"/>
<path d="M56 72 L54 82 M70 72 L72 82" fill="none" stroke="#FFC14D" stroke-width="2.5"/>
<path d="M40 88 Q30 74 42 63" fill="none" stroke-width="14"/>
<path d="M40 88 Q30 74 42 63" fill="none" stroke="#2F6F73" stroke-width="7"/>
<path d="M84 88 Q98 78 92 63" fill="none" stroke-width="14"/>
<path d="M84 88 Q98 78 92 63" fill="none" stroke="#2F6F73" stroke-width="7"/>
<circle cx="42" cy="61" r="6.5" fill="#F2B48A" stroke-width="3"/>
<circle cx="92" cy="61" r="6.5" fill="#F2B48A" stroke-width="3"/>
</g>
</svg>''',
  ),
  BurglarPose.carry: (
    label: 'Milo Muffle straining to carry loot overhead',
    svg: r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150">
<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="62" cy="144" rx="38" ry="5" fill="#000000" opacity="0.22" stroke="none"/>
<path d="M48 112 L38 134 M76 112 L86 134" fill="none" stroke-width="13"/>
<path d="M48 112 L38 134 M76 112 L86 134" fill="none" stroke="#2A2840" stroke-width="6"/>
<ellipse cx="34" cy="139" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>
<ellipse cx="90" cy="139" rx="11" ry="6" fill="#FFC14D" stroke-width="3"/>
<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>
<path d="M48 104 Q62 110 76 104" fill="none" stroke-width="2.5"/>
<path d="M40 82 Q26 50 36 14" fill="none" stroke-width="14"/>
<path d="M40 82 Q26 50 36 14" fill="none" stroke="#2F6F73" stroke-width="7"/>
<path d="M84 82 Q98 50 88 14" fill="none" stroke-width="14"/>
<path d="M84 82 Q98 50 88 14" fill="none" stroke="#2F6F73" stroke-width="7"/>
<circle cx="62" cy="46" r="28" fill="#2F6F73"/>
<circle cx="64" cy="50" r="19" fill="#F2B48A" stroke-width="3"/>
<path d="M43 44 Q64 36 85 44 L85 54 Q64 48 43 54 Z" fill="#F0533B" stroke-width="3"/>
<path d="M52 45 L59 48.5 L52 52 M76 45 L69 48.5 L76 52" fill="none" stroke-width="3"/>
<rect x="57" y="57" width="14" height="7" rx="2" fill="#FFFFFF" stroke-width="2.5"/>
<path d="M57 60.5 L71 60.5" fill="none" stroke-width="1.5"/>
<path d="M96 30 Q101 39 96 42 Q91 39 96 30 Z" fill="#9FD3F0" stroke-width="2.5"/>
<circle cx="36" cy="12" r="6.5" fill="#F2B48A" stroke-width="3"/>
<circle cx="88" cy="12" r="6.5" fill="#F2B48A" stroke-width="3"/>
</g>
</svg>''',
  ),
  BurglarPose.panic: (
    label: 'Milo Muffle running in panic',
    svg: r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150">
<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="62" cy="144" rx="36" ry="5" fill="#000000" opacity="0.2" stroke="none"/>
<g transform="rotate(10 60 100)">
<path d="M50 112 L34 124 L28 136 M72 112 L88 120 L100 112" fill="none" stroke-width="13"/>
<path d="M50 112 L34 124 L28 136 M72 112 L88 120 L100 112" fill="none" stroke="#2A2840" stroke-width="6"/>
<ellipse cx="26" cy="140" rx="11" ry="6" fill="#5CC9A7" stroke-width="3"/>
<ellipse cx="104" cy="110" rx="11" ry="6" fill="#FFC14D" stroke-width="3" transform="rotate(-30 104 110)"/>
<path d="M32 104 C30 76 44 62 62 62 C82 62 94 78 92 104 C90 118 76 122 62 122 C46 122 34 118 32 104 Z" fill="#2F6F73"/>
<circle cx="62" cy="44" r="28" fill="#2F6F73"/>
<circle cx="67" cy="48" r="19" fill="#F2B48A" stroke-width="3"/>
<path d="M46 42 Q67 34 88 42 L88 52 Q67 46 46 52 Z" fill="#F0533B" stroke-width="3"/>
<circle cx="60" cy="46" r="6.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="77" cy="46" r="6.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="61" cy="46" r="1.8" fill="#1C1A2B" stroke="none"/>
<circle cx="78" cy="46" r="1.8" fill="#1C1A2B" stroke="none"/>
<ellipse cx="72" cy="60" rx="5" ry="6" fill="#1C1A2B" stroke="none"/>
<path d="M38 86 Q22 78 14 62" fill="none" stroke-width="14"/>
<path d="M38 86 Q22 78 14 62" fill="none" stroke="#2F6F73" stroke-width="7"/>
<path d="M86 86 Q104 90 112 78" fill="none" stroke-width="14"/>
<path d="M86 86 Q104 90 112 78" fill="none" stroke="#2F6F73" stroke-width="7"/>
<circle cx="14" cy="60" r="6.5" fill="#F2B48A" stroke-width="3"/>
<circle cx="112" cy="76" r="6.5" fill="#F2B48A" stroke-width="3"/>
</g>
<path d="M30 20 Q34 28 30 31 Q26 28 30 20 Z M100 28 Q104 36 100 39 Q96 36 100 28 Z" fill="#9FD3F0" stroke-width="2.5"/>
</g>
</svg>''',
  ),
  BurglarPose.caught: (
    label: 'Milo Muffle flattened and seeing stars',
    svg: r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150">
<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="62" cy="145" rx="52" ry="5" fill="#000000" opacity="0.22" stroke="none"/>
<path d="M86 128 L100 104 M94 132 L112 116" fill="none" stroke-width="13"/>
<path d="M86 128 L100 104 M94 132 L112 116" fill="none" stroke="#2A2840" stroke-width="6"/>
<ellipse cx="101" cy="100" rx="10" ry="6" fill="#5CC9A7" stroke-width="3" transform="rotate(-60 101 100)"/>
<ellipse cx="114" cy="112" rx="10" ry="6" fill="#FFC14D" stroke-width="3" transform="rotate(-40 114 112)"/>
<ellipse cx="62" cy="131" rx="36" ry="13" fill="#2F6F73"/>
<path d="M50 126 L42 110" fill="none" stroke-width="13"/>
<path d="M50 126 L42 110" fill="none" stroke="#2F6F73" stroke-width="6"/>
<circle cx="41" cy="107" r="6" fill="#F2B48A" stroke-width="3"/>
<circle cx="26" cy="127" r="18" fill="#2F6F73"/>
<circle cx="24" cy="129" r="12.5" fill="#F2B48A" stroke-width="3"/>
<path d="M10 120 L38 116 L39 124 L11 128 Z" fill="#F0533B" stroke-width="3"/>
<path d="M15 119 L21 125 M21 119 L15 125 M27 117 L33 123 M33 117 L27 123" fill="none" stroke-width="2.5"/>
<path d="M20 136 Q24 133 28 136" fill="none" stroke-width="2.5"/>
<path d="M14 92 L16 98 L22 100 L16 102 L14 108 L12 102 L6 100 L12 98 Z M38 86 L39.5 90 L44 91.5 L39.5 93 L38 97 L36.5 93 L32 91.5 L36.5 90 Z" fill="#FFC14D" stroke-width="2.5"/>
</g>
</svg>''',
  ),
  BurglarPose.crawl: (
    label: 'Milo Muffle crawling on all fours',
    svg: r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 150">
<g stroke="#1C1A2B" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="62" cy="144" rx="46" ry="5" fill="#000000" opacity="0.22" stroke="none"/>
<path d="M86 116 L98 138 M72 118 L78 138" fill="none" stroke-width="13"/>
<path d="M86 116 L98 138 M72 118 L78 138" fill="none" stroke="#2A2840" stroke-width="6"/>
<ellipse cx="104" cy="139" rx="11" ry="6" fill="#FFC14D" stroke-width="3"/>
<ellipse cx="82" cy="140" rx="10" ry="5.5" fill="#5CC9A7" stroke-width="3"/>
<path d="M30 112 C30 92 48 84 70 84 C94 84 108 94 106 112 C104 124 90 128 70 128 C48 128 30 124 30 112 Z" fill="#2F6F73"/>
<path d="M60 118 Q74 124 88 118" fill="none" stroke-width="2.5"/>
<path d="M40 112 L30 136" fill="none" stroke-width="14"/>
<path d="M40 112 L30 136" fill="none" stroke="#2F6F73" stroke-width="7"/>
<path d="M56 116 L52 136" fill="none" stroke-width="14"/>
<path d="M56 116 L52 136" fill="none" stroke="#2F6F73" stroke-width="7"/>
<circle cx="29" cy="138" r="6" fill="#F2B48A" stroke-width="3"/>
<circle cx="52" cy="138" r="6" fill="#F2B48A" stroke-width="3"/>
<circle cx="32" cy="94" r="24" fill="#2F6F73"/>
<circle cx="28" cy="98" r="16" fill="#F2B48A" stroke-width="3"/>
<path d="M12 92 Q28 85 44 92 L44 101 Q28 95 12 101 Z" fill="#F0533B" stroke-width="3"/>
<circle cx="22" cy="96" r="4.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="35" cy="96" r="4.5" fill="#FFFFFF" stroke-width="2.5"/>
<circle cx="21" cy="95" r="2.2" fill="#1C1A2B" stroke="none"/>
<circle cx="34" cy="95" r="2.2" fill="#1C1A2B" stroke="none"/>
<path d="M22 108 Q26 106 30 108" fill="none" stroke-width="2.5"/>
</g>
</svg>''',
  ),
};
