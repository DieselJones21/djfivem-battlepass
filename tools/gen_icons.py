#!/usr/bin/env python3
"""Generate 28 inventory-style SVG icons for DJFIVEM-Battlepass."""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "html" / "icons"
OUT.mkdir(parents=True, exist_ok=True)

FRAME = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{bg1}"/>
      <stop offset="1" stop-color="{bg2}"/>
    </linearGradient>
    <radialGradient id="spot" cx="50%" cy="30%" r="60%">
      <stop offset="0" stop-color="{spot}" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#000" stop-opacity="0"/>
    </radialGradient>
    <filter id="glow" x="-40%" y="-40%" width="180%" height="180%">
      <feGaussianBlur stdDeviation="3.5" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="256" height="256" rx="32" fill="url(#bg)"/>
  <rect width="256" height="256" rx="32" fill="url(#spot)"/>
  <rect x="10" y="10" width="236" height="236" rx="24" fill="none" stroke="{edge}" stroke-opacity="0.35" stroke-width="2"/>
  {art}
</svg>
'''

def wrap(art, bg1="#1a1028", bg2="#0b0812", spot="#ff2d6a", edge="#ff6b9d"):
    return FRAME.format(art=art, bg1=bg1, bg2=bg2, spot=spot, edge=edge)

ICONS = {}

# 01 cash stack
ICONS[1] = wrap('''
  <g filter="url(#glow)" transform="translate(48,70)">
    <rect x="8" y="36" width="144" height="52" rx="8" fill="#1d6b3a"/>
    <rect x="16" y="22" width="144" height="52" rx="8" fill="#2f9e56"/>
    <rect x="24" y="8" width="144" height="52" rx="8" fill="#3dff8a"/>
    <circle cx="96" cy="34" r="14" fill="#145c32"/>
    <text x="96" y="39" text-anchor="middle" font-size="16" font-family="Arial" fill="#3dff8a" font-weight="700">$</text>
  </g>''', spot="#3dff8a", edge="#3dff8a")

# 02 bandage
ICONS[2] = wrap('''
  <g filter="url(#glow)" transform="translate(48,78) rotate(-18 80 50)">
    <rect x="8" y="28" width="152" height="48" rx="12" fill="#f2efe6"/>
    <rect x="8" y="28" width="36" height="48" rx="12" fill="#d9d2c3"/>
    <rect x="124" y="28" width="36" height="48" rx="12" fill="#d9d2c3"/>
    <rect x="70" y="28" width="18" height="48" fill="#ff6b8a"/>
  </g>''', spot="#ffb3c7", edge="#ffb3c7")

# 03 drinks
ICONS[3] = wrap('''
  <g filter="url(#glow)">
    <rect x="70" y="70" width="42" height="118" rx="8" fill="#e11d48"/>
    <rect x="74" y="78" width="34" height="28" rx="4" fill="#fff" opacity=".25"/>
    <rect x="144" y="58" width="42" height="130" rx="8" fill="#16a34a"/>
    <rect x="148" y="66" width="34" height="28" rx="4" fill="#fff" opacity=".25"/>
    <rect x="78" y="58" width="26" height="14" rx="3" fill="#cbd5e1"/>
    <rect x="152" y="46" width="26" height="14" rx="3" fill="#cbd5e1"/>
  </g>''', spot="#ff4d6d", edge="#ff4d6d")

# 04 lsd blotter
ICONS[4] = wrap('''
  <g filter="url(#glow)" transform="translate(58,58)">
    <rect x="10" y="18" width="130" height="130" rx="10" fill="#f4e4ff"/>
    <g>
      <rect x="18" y="26" width="54" height="54" fill="#c084fc"/>
      <rect x="78" y="26" width="54" height="54" fill="#67e8f9"/>
      <rect x="18" y="86" width="54" height="54" fill="#86efac"/>
      <rect x="78" y="86" width="54" height="54" fill="#fda4af"/>
    </g>
  </g>''', spot="#c084fc", edge="#c084fc")

# 05 knife
ICONS[5] = wrap('''
  <g filter="url(#glow)" transform="translate(40,48) rotate(28 88 80)">
    <path d="M40 128 L40 86 L150 34 L162 46 L52 140 Z" fill="#e5e7eb"/>
    <rect x="28" y="118" width="70" height="18" rx="4" fill="#1f2937"/>
    <rect x="22" y="122" width="18" height="10" rx="2" fill="#ef4444"/>
  </g>''', spot="#e5e7eb", edge="#94a3b8")

# 06 lockpicks
ICONS[6] = wrap('''
  <g filter="url(#glow)" transform="translate(78,46)">
    <rect x="20" y="10" width="12" height="150" rx="4" fill="#cbd5e1"/>
    <circle cx="26" cy="18" r="14" fill="none" stroke="#cbd5e1" stroke-width="8"/>
    <rect x="52" y="24" width="12" height="150" rx="4" fill="#94a3b8" transform="rotate(12 58 99)"/>
    <circle cx="70" cy="36" r="14" fill="none" stroke="#94a3b8" stroke-width="8"/>
  </g>''', spot="#94a3b8", edge="#94a3b8")

# 07 syringe
ICONS[7] = wrap('''
  <g filter="url(#glow)" transform="translate(46,40) rotate(35 82 88)">
    <rect x="70" y="20" width="28" height="110" rx="6" fill="#7dd3fc"/>
    <rect x="70" y="20" width="28" height="50" fill="#38bdf8" opacity=".7"/>
    <rect x="76" y="130" width="16" height="36" fill="#e5e7eb"/>
    <rect x="62" y="164" width="44" height="10" rx="3" fill="#e5e7eb"/>
    <rect x="78" y="8" width="12" height="16" fill="#f87171"/>
  </g>''', spot="#38bdf8", edge="#38bdf8")

# 08 crown
ICONS[8] = wrap('''
  <g filter="url(#glow)" transform="translate(38,62)">
    <path d="M20 128 L28 52 L70 92 L90 28 L130 92 L172 52 L180 128 Z" fill="#111827"/>
    <path d="M20 128 L28 52 L70 92 L90 28 L130 92 L172 52 L180 128 Z" fill="none" stroke="#22d3ee" stroke-width="8"/>
    <circle cx="90" cy="28" r="10" fill="#22d3ee"/>
    <rect x="20" y="120" width="160" height="22" rx="4" fill="#22d3ee"/>
  </g>''', spot="#22d3ee", edge="#22d3ee")

# 09 ammo
ICONS[9] = wrap('''
  <g filter="url(#glow)" transform="translate(58,54)">
    <g transform="rotate(-18 40 80)">
      <rect x="18" y="30" width="28" height="110" rx="8" fill="#d97706"/>
      <rect x="18" y="30" width="28" height="36" rx="8" fill="#fbbf24"/>
    </g>
    <g transform="rotate(6 90 80)">
      <rect x="70" y="22" width="28" height="118" rx="8" fill="#b45309"/>
      <rect x="70" y="22" width="28" height="36" rx="8" fill="#f59e0b"/>
    </g>
    <g transform="rotate(28 130 80)">
      <rect x="118" y="34" width="28" height="110" rx="8" fill="#d97706"/>
      <rect x="118" y="34" width="28" height="36" rx="8" fill="#fbbf24"/>
    </g>
  </g>''', spot="#f59e0b", edge="#f59e0b")

# 10 money bag
ICONS[10] = wrap('''
  <g filter="url(#glow)" transform="translate(56,48)">
    <path d="M36 72 C36 160 144 160 144 72 C120 72 108 48 90 48 C72 48 60 72 36 72 Z" fill="#16a34a"/>
    <path d="M64 48 C76 28 104 28 116 48" fill="none" stroke="#4ade80" stroke-width="10"/>
    <text x="90" y="112" text-anchor="middle" font-size="42" font-family="Arial" fill="#052e16" font-weight="700">$</text>
  </g>''', spot="#4ade80", edge="#4ade80")

# 11 tec9
ICONS[11] = wrap('''
  <g filter="url(#glow)" transform="translate(28,78)">
    <rect x="18" y="38" width="170" height="22" rx="4" fill="#9ca3af"/>
    <rect x="150" y="28" width="50" height="18" rx="3" fill="#6b7280"/>
    <rect x="48" y="58" width="18" height="52" rx="3" fill="#6b7280"/>
    <rect x="70" y="58" width="36" height="70" rx="4" fill="#374151"/>
    <rect x="18" y="30" width="28" height="38" rx="3" fill="#d1d5db"/>
  </g>''', spot="#9ca3af", edge="#9ca3af")

# 12 sprunks
ICONS[12] = wrap('''
  <g filter="url(#glow)">
    <rect x="78" y="62" width="40" height="128" rx="8" fill="#16a34a"/>
    <rect x="82" y="72" width="32" height="24" fill="#bbf7d0" opacity=".5"/>
    <rect x="138" y="78" width="40" height="112" rx="8" fill="#22c55e"/>
    <text x="98" y="150" text-anchor="middle" font-size="11" font-family="Arial" fill="#052e16" font-weight="700">SP</text>
  </g>''', spot="#22c55e", edge="#22c55e")

# 13 money box
ICONS[13] = wrap('''
  <g filter="url(#glow)" transform="translate(48,68)">
    <rect x="8" y="40" width="152" height="96" rx="10" fill="#7c4a12"/>
    <rect x="8" y="40" width="152" height="28" rx="10" fill="#b45309"/>
    <rect x="20" y="22" width="128" height="28" rx="4" fill="#fbbf24"/>
    <text x="84" y="96" text-anchor="middle" font-size="36" font-family="Arial" fill="#fde68a" font-weight="700">$</text>
  </g>''', spot="#fbbf24", edge="#fbbf24")

# 14 dino plan
ICONS[14] = wrap('''
  <g filter="url(#glow)" transform="translate(52,48)">
    <rect x="16" y="16" width="132" height="168" rx="8" fill="#ecfccb"/>
    <path d="M40 130 C48 90 70 70 96 78 C120 86 128 70 138 62" fill="none" stroke="#365314" stroke-width="6"/>
    <circle cx="138" cy="58" r="8" fill="#365314"/>
    <path d="M70 128 L86 150 L64 148" fill="none" stroke="#365314" stroke-width="5"/>
    <path d="M36 48 H140 M36 64 H120" stroke="#84cc16" stroke-width="3" opacity=".5"/>
  </g>''', spot="#84cc16", edge="#84cc16")

# 15 armor
ICONS[15] = wrap('''
  <g filter="url(#glow)" transform="translate(58,46)">
    <path d="M70 20 L130 20 L150 48 L150 140 C150 168 70 168 70 140 L70 48 Z" fill="#1f2937"/>
    <path d="M70 20 L130 20 L150 48 L150 140 C150 168 70 168 70 140 L70 48 Z" fill="none" stroke="#60a5fa" stroke-width="7"/>
    <path d="M88 72 H132 V128 H88 Z" fill="#111827"/>
    <path d="M100 20 V8 H100" />
  </g>''', spot="#60a5fa", edge="#60a5fa")

# 16 gold chain
ICONS[16] = wrap('''
  <g filter="url(#glow)" fill="none" stroke="#fbbf24" stroke-width="10">
    <circle cx="128" cy="86" r="46"/>
    <circle cx="92" cy="150" r="16"/>
    <circle cx="128" cy="168" r="16"/>
    <circle cx="164" cy="150" r="16"/>
    <rect x="112" y="178" width="32" height="28" rx="4" fill="#f59e0b" stroke="none"/>
  </g>''', spot="#fbbf24", edge="#fbbf24")

# 17 ap pistol
ICONS[17] = wrap('''
  <g filter="url(#glow)" transform="translate(36,86)">
    <rect x="10" y="28" width="150" height="20" rx="4" fill="#d1d5db"/>
    <rect x="140" y="20" width="44" height="16" rx="3" fill="#9ca3af"/>
    <rect x="46" y="46" width="16" height="44" rx="3" fill="#6b7280"/>
    <rect x="22" y="18" width="24" height="40" rx="3" fill="#f43f5e"/>
  </g>''', spot="#f43f5e", edge="#f43f5e")

# 18 cash drop
ICONS[18] = wrap('''
  <g filter="url(#glow)" transform="translate(52,58)">
    <rect x="20" y="28" width="120" height="72" rx="8" fill="#22c55e"/>
    <rect x="32" y="52" width="120" height="72" rx="8" fill="#16a34a"/>
    <rect x="44" y="76" width="120" height="72" rx="8" fill="#4ade80"/>
    <text x="104" y="122" text-anchor="middle" font-size="34" font-family="Arial" fill="#052e16" font-weight="700">$</text>
  </g>''', spot="#4ade80", edge="#4ade80")

# 19 radio
ICONS[19] = wrap('''
  <g filter="url(#glow)" transform="translate(78,48)">
    <rect x="18" y="46" width="84" height="128" rx="12" fill="#111827"/>
    <rect x="18" y="46" width="84" height="128" rx="12" fill="none" stroke="#22d3ee" stroke-width="4"/>
    <rect x="30" y="62" width="60" height="36" rx="4" fill="#0f172a"/>
    <circle cx="60" cy="128" r="16" fill="#22d3ee"/>
    <rect x="72" y="16" width="8" height="36" fill="#94a3b8"/>
    <rect x="68" y="8" width="16" height="10" rx="2" fill="#22d3ee"/>
  </g>''', spot="#22d3ee", edge="#22d3ee")

# 20 ammo crate
ICONS[20] = wrap('''
  <g filter="url(#glow)" transform="translate(44,64)">
    <rect x="12" y="48" width="168" height="100" rx="8" fill="#854d0e"/>
    <rect x="12" y="48" width="168" height="28" fill="#a16207"/>
    <rect x="28" y="28" width="136" height="28" rx="4" fill="#ca8a04"/>
    <rect x="40" y="88" width="28" height="44" rx="4" fill="#fbbf24"/>
    <rect x="76" y="88" width="28" height="44" rx="4" fill="#f59e0b"/>
    <rect x="112" y="88" width="28" height="44" rx="4" fill="#fbbf24"/>
  </g>''', spot="#f59e0b", edge="#f59e0b")

# 21 envelope
ICONS[21] = wrap('''
  <g filter="url(#glow)" transform="translate(40,70)">
    <rect x="16" y="40" width="168" height="110" rx="8" fill="#f8fafc"/>
    <path d="M16 40 L100 108 L184 40" fill="none" stroke="#94a3b8" stroke-width="6"/>
    <rect x="58" y="24" width="84" height="28" rx="3" fill="#16a34a"/>
  </g>''', spot="#e2e8f0", edge="#e2e8f0")

# 22 plate
ICONS[22] = wrap('''
  <g filter="url(#glow)" transform="translate(28,88)">
    <rect x="8" y="28" width="192" height="72" rx="10" fill="#e5e7eb"/>
    <rect x="8" y="28" width="192" height="72" rx="10" fill="none" stroke="#22d3ee" stroke-width="6"/>
    <text x="104" y="76" text-anchor="middle" font-size="28" font-family="Arial" fill="#0f172a" font-weight="700">DJF 001</text>
  </g>''', spot="#22d3ee", edge="#22d3ee")

# 23 pdw
ICONS[23] = wrap('''
  <g filter="url(#glow)" transform="translate(24,80)">
    <rect x="12" y="36" width="188" height="20" rx="4" fill="#9ca3af"/>
    <rect x="168" y="24" width="52" height="18" rx="3" fill="#6b7280"/>
    <rect x="70" y="54" width="18" height="48" rx="3" fill="#4b5563"/>
    <rect x="92" y="54" width="50" height="64" rx="4" fill="#111827"/>
    <rect x="36" y="20" width="40" height="24" rx="3" fill="#64748b"/>
  </g>''', spot="#94a3b8", edge="#94a3b8")

# 24 crate
ICONS[24] = wrap('''
  <g filter="url(#glow)" transform="translate(48,58)">
    <rect x="20" y="48" width="152" height="116" rx="10" fill="#3b0764"/>
    <rect x="20" y="48" width="152" height="116" rx="10" fill="none" stroke="#e879f9" stroke-width="6"/>
    <path d="M20 96 H172 M96 48 V164" stroke="#e879f9" stroke-width="6"/>
    <polygon points="96,18 108,48 84,48" fill="#f0abfc"/>
  </g>''', spot="#e879f9", edge="#e879f9")

# 25 vault stack
ICONS[25] = wrap('''
  <g filter="url(#glow)" transform="translate(52,48)">
    <rect x="16" y="40" width="140" height="40" rx="6" fill="#22c55e"/>
    <rect x="8" y="78" width="140" height="40" rx="6" fill="#16a34a"/>
    <rect x="24" y="116" width="140" height="40" rx="6" fill="#4ade80"/>
    <rect x="48" y="20" width="72" height="28" rx="4" fill="#fbbf24"/>
    <text x="84" y="108" text-anchor="middle" font-size="22" font-family="Arial" fill="#052e16" font-weight="700">75K</text>
  </g>''', spot="#fbbf24", edge="#4ade80")

# 26 voucher / key
ICONS[26] = wrap('''
  <g filter="url(#glow)" transform="translate(48,70)">
    <circle cx="58" cy="58" r="36" fill="none" stroke="#fbbf24" stroke-width="12"/>
    <rect x="88" y="50" width="80" height="16" rx="4" fill="#fbbf24"/>
    <rect x="140" y="50" width="12" height="32" fill="#fbbf24"/>
    <rect x="158" y="50" width="12" height="24" fill="#fbbf24"/>
  </g>''', spot="#fbbf24", edge="#fbbf24")

# 27 rolex
ICONS[27] = wrap('''
  <g filter="url(#glow)" transform="translate(72,36)">
    <rect x="36" y="8" width="40" height="36" rx="8" fill="#67e8f9"/>
    <rect x="36" y="176" width="40" height="36" rx="8" fill="#67e8f9"/>
    <circle cx="56" cy="110" r="52" fill="#0f172a" stroke="#67e8f9" stroke-width="10"/>
    <circle cx="56" cy="110" r="8" fill="#67e8f9"/>
    <path d="M56 110 L56 78" stroke="#e2e8f0" stroke-width="6"/>
    <path d="M56 110 L80 110" stroke="#67e8f9" stroke-width="5"/>
  </g>''', spot="#67e8f9", edge="#67e8f9")

# 28 champion car
ICONS[28] = wrap('''
  <g filter="url(#glow)" transform="translate(24,78)">
    <path d="M28 92 L52 52 H140 L188 92 L200 120 H12 Z" fill="#fb7185"/>
    <path d="M60 56 H132 L154 92 H48 Z" fill="#0f172a" opacity=".55"/>
    <circle cx="58" cy="122" r="18" fill="#111827" stroke="#e2e8f0" stroke-width="5"/>
    <circle cx="162" cy="122" r="18" fill="#111827" stroke="#e2e8f0" stroke-width="5"/>
    <rect x="86" y="100" width="36" height="8" rx="2" fill="#fda4af"/>
  </g>''', spot="#fb7185", edge="#fb7185")

for i, svg in ICONS.items():
    path = OUT / f"tier_{i:02d}.svg"
    path.write_text(svg, encoding="utf-8")
    print("wrote", path.name)

print("done", len(ICONS))
