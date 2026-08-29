#!/usr/bin/env python3
"""Build Season 1 icons + html/tiers.json from the locked randomized track."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "html" / "icons"
ICON_DIR.mkdir(parents=True, exist_ok=True)

# Randomized order. pet_pug sits late (26). WEAPON_4THARP is last (28).
TIERS = [
    {"tier": 1, "name": "Black Silver Crown", "description": "A black and silver crown. Wear it like you own the block.", "type": "item", "item": "black_silver_crown", "amount": 1, "rarity": "epic"},
    {"tier": 2, "name": "Capybara Plushie", "description": "A shop capybara plush. Chill energy only.", "type": "item", "item": "capivara_plushie_shop", "amount": 1, "rarity": "rare"},
    {"tier": 3, "name": ".44 Ammo", "description": "75x .44 caliber rounds. Heavy hitters.", "type": "item", "item": "ammo-44", "amount": 75, "rarity": "rare"},
    {"tier": 4, "name": "Silver Black Crown", "description": "The silver-black twin crown. Matching flex.", "type": "item", "item": "silver_black_crown", "amount": 1, "rarity": "epic"},
    {"tier": 5, "name": "Chameleon 215", "description": "Chameleon paint 215. Color shift on the ride.", "type": "item", "item": "chameleonpaint_215", "amount": 1, "rarity": "epic"},
    {"tier": 6, "name": "Crayon Bat", "description": "WEAPON_CRAYONBAT. Soft colors, hard swing.", "type": "weapon", "item": "WEAPON_CRAYONBAT", "amount": 1, "rarity": "epic"},
    {"tier": 7, "name": "Crayon AP", "description": "WEAPON_CRAYONAP. A colorful armor-piercing sidearm.", "type": "weapon", "item": "WEAPON_CRAYONAP", "amount": 1, "rarity": "epic"},
    {"tier": 8, "name": "Rebel Rolls", "description": "50x rebel rolls. Snack the night away.", "type": "item", "item": "rebel_rolls", "amount": 50, "rarity": "rare"},
    {"tier": 9, "name": "Multitail Fox", "description": "did_multitail_fox. A rare multi-tail fox piece.", "type": "item", "item": "did_multitail_fox", "amount": 1, "rarity": "epic"},
    {"tier": 10, "name": "Bear Plushie", "description": "bear_04 shop plush. Soft, but you earned it.", "type": "item", "item": "bear_04_plushie_shop", "amount": 1, "rarity": "rare"},
    {"tier": 11, "name": "Red Karambit", "description": "WEAPON_REDKARAMBIT. A red curve blade.", "type": "weapon", "item": "WEAPON_REDKARAMBIT", "amount": 1, "rarity": "epic"},
    {"tier": 12, "name": "Elfbar Grape", "description": "10x grape Elfbars. Cloud up.", "type": "item", "item": "vape_elfbar_grape", "amount": 10, "rarity": "rare"},
    {"tier": 13, "name": "Lava Skeleton", "description": "did_lava_skeleton. Molten bones, season drip.", "type": "item", "item": "did_lava_skeleton", "amount": 1, "rarity": "epic"},
    {"tier": 14, "name": "Chameleon 198", "description": "Chameleon paint 198. Another shift for the garage.", "type": "item", "item": "chameleonpaint_198", "amount": 1, "rarity": "epic"},
    {"tier": 15, "name": "Chameleon 169", "description": "Chameleon paint 169. Rare flip finish.", "type": "item", "item": "chameleonpaint_169", "amount": 1, "rarity": "epic"},
    {"tier": 16, "name": "Island Pills", "description": "50x island pills. Pack them tight.", "type": "item", "item": "island_pills", "amount": 50, "rarity": "rare"},
    {"tier": 17, "name": "Sandwiches", "description": "5x sandwiches. Eat, then get back to the grind.", "type": "item", "item": "sandwich", "amount": 5, "rarity": "common"},
    {"tier": 18, "name": "Rifle Ammo", "description": "100x rifle rounds. Stay loaded.", "type": "item", "item": "ammo-rifle", "amount": 100, "rarity": "rare"},
    {"tier": 19, "name": "Girly CX", "description": "WEAPON_GIRLYCX. Pretty hardware.", "type": "weapon", "item": "WEAPON_GIRLYCX", "amount": 1, "rarity": "epic"},
    {"tier": 20, "name": "Water", "description": "5x water. Stay hydrated in the city.", "type": "item", "item": "water", "amount": 5, "rarity": "common"},
    {"tier": 21, "name": "9mm Ammo", "description": "50x 9mm rounds for the sidearm.", "type": "item", "item": "ammo-9", "amount": 50, "rarity": "rare"},
    {"tier": 22, "name": "Apple Refill", "description": "5x apple vape refill. Keep the tank wet.", "type": "item", "item": "vape_refill_apple", "amount": 5, "rarity": "common"},
    {"tier": 23, "name": "Vape", "description": "A vape. Simple, ready to use.", "type": "item", "item": "vape", "amount": 1, "rarity": "common"},
    {"tier": 24, "name": "Pink Halo", "description": "halo_pink. A glowing pink halo.", "type": "item", "item": "halo_pink", "amount": 1, "rarity": "epic"},
    {"tier": 25, "name": "Mushroom Plushie", "description": "mushroom_01 shop plush. Cute and rare.", "type": "item", "item": "mushroom_01_plushie_shop", "amount": 1, "rarity": "rare"},
    {"tier": 26, "name": "Pet Pug", "description": "A pet pug. Late-track companion.", "type": "item", "item": "pet_pug", "amount": 1, "rarity": "legendary"},
    {"tier": 27, "name": "Pink Energy", "description": "50x pink energy. Stay up for the finale.", "type": "item", "item": "pink_energy", "amount": 50, "rarity": "rare"},
    {"tier": 28, "name": "4th ARP", "description": "WEAPON_4THARP. Season 1 closer. The last claim.", "type": "weapon", "item": "WEAPON_4THARP", "amount": 1, "rarity": "legendary"},
]

for t in TIERS:
    t["premium"] = False
    t["icon"] = f"tier_{t['tier']:02d}.svg"


FRAME = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{bg1}"/>
      <stop offset="1" stop-color="{bg2}"/>
    </linearGradient>
    <radialGradient id="spot" cx="50%" cy="28%" r="62%">
      <stop offset="0" stop-color="{spot}" stop-opacity="0.5"/>
      <stop offset="1" stop-color="#000" stop-opacity="0"/>
    </radialGradient>
    <filter id="glow" x="-40%" y="-40%" width="180%" height="180%">
      <feGaussianBlur stdDeviation="3.2" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="256" height="256" rx="32" fill="url(#bg)"/>
  <rect width="256" height="256" rx="32" fill="url(#spot)"/>
  <rect x="10" y="10" width="236" height="236" rx="24" fill="none" stroke="{edge}" stroke-opacity="0.38" stroke-width="2"/>
  {art}
</svg>
'''


def wrap(art, bg1="#1a1028", bg2="#0b0812", spot="#ff2d6a", edge="#ff6b9d"):
    return FRAME.format(art=art, bg1=bg1, bg2=bg2, spot=spot, edge=edge)


def crown(fill, accent):
    return f'''
  <g filter="url(#glow)" transform="translate(38,62)">
    <path d="M20 128 L28 52 L70 92 L90 28 L130 92 L172 52 L180 128 Z" fill="{fill}"/>
    <path d="M20 128 L28 52 L70 92 L90 28 L130 92 L172 52 L180 128 Z" fill="none" stroke="{accent}" stroke-width="8"/>
    <circle cx="90" cy="28" r="10" fill="{accent}"/>
    <rect x="20" y="120" width="160" height="22" rx="4" fill="{accent}"/>
  </g>'''


def ammo(c1, c2):
    return f'''
  <g filter="url(#glow)" transform="translate(58,54)">
    <g transform="rotate(-18 40 80)">
      <rect x="18" y="30" width="28" height="110" rx="8" fill="{c1}"/>
      <rect x="18" y="30" width="28" height="36" rx="8" fill="{c2}"/>
    </g>
    <g transform="rotate(6 90 80)">
      <rect x="70" y="22" width="28" height="118" rx="8" fill="{c1}"/>
      <rect x="70" y="22" width="28" height="36" rx="8" fill="{c2}"/>
    </g>
    <g transform="rotate(28 130 80)">
      <rect x="118" y="34" width="28" height="110" rx="8" fill="{c1}"/>
      <rect x="118" y="34" width="28" height="36" rx="8" fill="{c2}"/>
    </g>
  </g>'''


def paint(a, b, c):
    return f'''
  <g filter="url(#glow)" transform="translate(58,50)">
    <path d="M70 20 L110 20 L150 70 L150 170 L30 170 L30 70 Z" fill="{a}"/>
    <path d="M70 20 L110 20 L110 70 L70 70 Z" fill="{b}"/>
    <path d="M40 88 H140" stroke="{c}" stroke-width="14" stroke-linecap="round"/>
    <circle cx="90" cy="128" r="18" fill="{c}"/>
  </g>'''


def pistol(body, accent):
    return f'''
  <g filter="url(#glow)" transform="translate(36,86)">
    <rect x="10" y="28" width="150" height="20" rx="4" fill="{body}"/>
    <rect x="140" y="20" width="44" height="16" rx="3" fill="{accent}"/>
    <rect x="46" y="46" width="16" height="44" rx="3" fill="{accent}"/>
    <rect x="22" y="18" width="24" height="40" rx="3" fill="{accent}"/>
  </g>'''


def vape_pen(body, tip):
    return f'''
  <g filter="url(#glow)" transform="translate(108,36) rotate(18)">
    <rect x="0" y="10" width="28" height="170" rx="10" fill="{body}"/>
    <rect x="4" y="18" width="20" height="36" rx="4" fill="#fff" opacity=".25"/>
    <rect x="6" y="0" width="16" height="16" rx="3" fill="{tip}"/>
    <rect x="8" y="160" width="12" height="22" rx="2" fill="#111"/>
  </g>'''


ICONS = {
    1: wrap(crown("#111827", "#d1d5db"), spot="#d1d5db", edge="#d1d5db"),
    2: wrap('''
  <g filter="url(#glow)" transform="translate(48,70)">
    <ellipse cx="80" cy="70" rx="70" ry="48" fill="#c4a574"/>
    <ellipse cx="48" cy="36" rx="18" ry="22" fill="#c4a574"/>
    <ellipse cx="112" cy="36" rx="18" ry="22" fill="#c4a574"/>
    <circle cx="58" cy="66" r="6" fill="#3b2a16"/>
    <circle cx="102" cy="66" r="6" fill="#3b2a16"/>
    <ellipse cx="80" cy="86" rx="14" ry="8" fill="#8b5e34"/>
  </g>''', spot="#c4a574", edge="#c4a574"),
    3: wrap(ammo("#d97706", "#fbbf24"), spot="#f59e0b", edge="#f59e0b"),
    4: wrap(crown("#e5e7eb", "#111827"), spot="#e5e7eb", edge="#9ca3af"),
    5: wrap(paint("#22d3ee", "#a78bfa", "#f472b6"), spot="#22d3ee", edge="#a78bfa"),
    6: wrap('''
  <g filter="url(#glow)" transform="translate(40,40) rotate(28 88 88)">
    <rect x="96" y="20" width="22" height="130" rx="6" fill="#f9a8d4"/>
    <rect x="88" y="140" width="38" height="48" rx="8" fill="#67e8f9"/>
    <rect x="94" y="28" width="26" height="18" fill="#fde047"/>
  </g>''', spot="#f9a8d4", edge="#67e8f9"),
    7: wrap(pistol("#f9a8d4", "#67e8f9"), spot="#f9a8d4", edge="#67e8f9"),
    8: wrap('''
  <g filter="url(#glow)" transform="translate(58,68)">
    <ellipse cx="70" cy="70" rx="62" ry="40" fill="#f5d0a9"/>
    <path d="M20 70 Q70 20 120 70 Q70 110 20 70" fill="#e8b86d"/>
    <path d="M30 62 H110 M30 78 H110" stroke="#7c4a12" stroke-width="4"/>
  </g>''', spot="#f5d0a9", edge="#e8b86d"),
    9: wrap('''
  <g filter="url(#glow)" transform="translate(46,58)">
    <ellipse cx="86" cy="88" rx="46" ry="36" fill="#f97316"/>
    <circle cx="118" cy="70" r="22" fill="#fb923c"/>
    <circle cx="126" cy="64" r="4" fill="#111"/>
    <path d="M40 40 Q20 90 48 120" fill="none" stroke="#fdba74" stroke-width="10"/>
    <path d="M28 48 Q8 100 40 128" fill="none" stroke="#fb923c" stroke-width="8"/>
    <path d="M52 36 Q36 88 58 118" fill="none" stroke="#fed7aa" stroke-width="8"/>
  </g>''', spot="#fb923c", edge="#fb923c"),
    10: wrap('''
  <g filter="url(#glow)" transform="translate(58,58)">
    <ellipse cx="70" cy="90" rx="54" ry="50" fill="#8b5e34"/>
    <circle cx="44" cy="44" r="20" fill="#8b5e34"/>
    <circle cx="96" cy="44" r="20" fill="#8b5e34"/>
    <circle cx="54" cy="88" r="6" fill="#1c1008"/>
    <circle cx="86" cy="88" r="6" fill="#1c1008"/>
    <ellipse cx="70" cy="108" rx="10" ry="7" fill="#3b2a16"/>
  </g>''', spot="#8b5e34", edge="#d6b08a"),
    11: wrap('''
  <g filter="url(#glow)" transform="translate(48,48)">
    <path d="M40 150 C70 130 90 90 150 40 C130 70 150 90 120 130 C90 160 60 170 40 150 Z" fill="#ef4444"/>
    <path d="M40 150 C55 148 62 160 58 172" fill="none" stroke="#7f1d1d" stroke-width="10"/>
    <circle cx="52" cy="168" r="8" fill="#111"/>
  </g>''', spot="#ef4444", edge="#ef4444"),
    12: wrap(vape_pen("#7c3aed", "#86efac"), spot="#a78bfa", edge="#86efac"),
    13: wrap('''
  <g filter="url(#glow)" transform="translate(64,48)">
    <circle cx="64" cy="48" r="28" fill="#111"/>
    <rect x="42" y="76" width="44" height="70" rx="8" fill="#111"/>
    <path d="M42 90 H86 M50 110 H78" stroke="#fb7185" stroke-width="4"/>
    <circle cx="54" cy="44" r="4" fill="#fb7185"/>
    <circle cx="74" cy="44" r="4" fill="#fb7185"/>
    <path d="M30 40 Q18 10 40 8" stroke="#f97316" stroke-width="6" fill="none"/>
    <path d="M98 40 Q110 8 88 10" stroke="#f97316" stroke-width="6" fill="none"/>
  </g>''', spot="#f97316", edge="#fb7185"),
    14: wrap(paint("#34d399", "#60a5fa", "#f472b6"), spot="#34d399", edge="#60a5fa"),
    15: wrap(paint("#f59e0b", "#8b5cf6", "#22d3ee"), spot="#f59e0b", edge="#8b5cf6"),
    16: wrap('''
  <g filter="url(#glow)" transform="translate(78,48)">
    <rect x="28" y="20" width="52" height="160" rx="18" fill="#67e8f9"/>
    <rect x="34" y="32" width="40" height="50" rx="10" fill="#ecfeff" opacity=".45"/>
    <circle cx="54" cy="150" r="10" fill="#0891b2"/>
  </g>''', spot="#67e8f9", edge="#67e8f9"),
    17: wrap('''
  <g filter="url(#glow)" transform="translate(48,78)">
    <rect x="16" y="40" width="160" height="70" rx="16" fill="#f5d0a9"/>
    <rect x="24" y="52" width="144" height="18" rx="6" fill="#86efac"/>
    <rect x="24" y="76" width="144" height="14" rx="6" fill="#fca5a5"/>
    <path d="M16 70 Q96 20 176 70" fill="#e8b86d"/>
  </g>''', spot="#f5d0a9", edge="#e8b86d"),
    18: wrap(ammo("#4b5563", "#22c55e"), spot="#22c55e", edge="#22c55e"),
    19: wrap(pistol("#f472b6", "#f9a8d4"), spot="#f472b6", edge="#f9a8d4"),
    20: wrap('''
  <g filter="url(#glow)" transform="translate(88,48)">
    <rect x="20" y="56" width="52" height="120" rx="12" fill="#38bdf8"/>
    <rect x="26" y="66" width="40" height="36" rx="6" fill="#e0f2fe" opacity=".45"/>
    <rect x="32" y="36" width="28" height="24" rx="4" fill="#7dd3fc"/>
    <ellipse cx="46" cy="36" rx="10" ry="8" fill="#bae6fd"/>
  </g>''', spot="#38bdf8", edge="#38bdf8"),
    21: wrap(ammo("#ca8a04", "#fde047"), spot="#facc15", edge="#facc15"),
    22: wrap('''
  <g filter="url(#glow)" transform="translate(78,58)">
    <rect x="30" y="36" width="56" height="130" rx="12" fill="#86efac"/>
    <rect x="36" y="48" width="44" height="40" rx="6" fill="#bbf7d0"/>
    <circle cx="58" cy="28" r="16" fill="#4ade80"/>
    <text x="58" y="128" text-anchor="middle" font-size="18" font-family="Arial" fill="#14532d" font-weight="700">5x</text>
  </g>''', spot="#86efac", edge="#4ade80"),
    23: wrap(vape_pen("#111827", "#f472b6"), spot="#f472b6", edge="#f472b6"),
    24: wrap('''
  <g filter="url(#glow)" transform="translate(48,48)">
    <ellipse cx="80" cy="88" rx="70" ry="28" fill="none" stroke="#f9a8d4" stroke-width="12"/>
    <path d="M80 40 L88 72 L122 72 L94 92 L104 124 L80 104 L56 124 L66 92 L38 72 L72 72 Z" fill="#f472b6"/>
  </g>''', spot="#f9a8d4", edge="#f9a8d4"),
    25: wrap('''
  <g filter="url(#glow)" transform="translate(64,40)">
    <ellipse cx="64" cy="58" rx="48" ry="36" fill="#f87171"/>
    <ellipse cx="64" cy="50" rx="28" ry="16" fill="#fecaca"/>
    <rect x="52" y="88" width="24" height="70" rx="8" fill="#fde68a"/>
    <circle cx="40" cy="54" r="7" fill="#fff" opacity=".7"/>
  </g>''', spot="#f87171", edge="#fde68a"),
    26: wrap('''
  <g filter="url(#glow)" transform="translate(58,58)">
    <ellipse cx="70" cy="92" rx="58" ry="46" fill="#c4a574"/>
    <circle cx="36" cy="58" r="18" fill="#c4a574"/>
    <circle cx="104" cy="58" r="18" fill="#c4a574"/>
    <circle cx="32" cy="52" r="7" fill="#1c1008"/>
    <circle cx="56" cy="86" r="6" fill="#1c1008"/>
    <circle cx="84" cy="86" r="6" fill="#1c1008"/>
    <ellipse cx="70" cy="104" rx="10" ry="6" fill="#3b2a16"/>
    <circle cx="118" cy="108" r="10" fill="#f9a8d4"/>
  </g>''', spot="#c4a574", edge="#f9a8d4"),
    27: wrap('''
  <g filter="url(#glow)" transform="translate(88,46)">
    <rect x="18" y="48" width="48" height="132" rx="12" fill="#ec4899"/>
    <rect x="24" y="58" width="36" height="34" rx="6" fill="#f9a8d4" opacity=".55"/>
    <rect x="28" y="28" width="28" height="24" rx="4" fill="#f472b6"/>
    <text x="42" y="150" text-anchor="middle" font-size="13" font-family="Arial" fill="#fff" font-weight="700">50</text>
  </g>''', spot="#ec4899", edge="#f9a8d4"),
    28: wrap('''
  <g filter="url(#glow)" transform="translate(28,78)">
    <rect x="16" y="36" width="188" height="22" rx="5" fill="#e5e7eb"/>
    <rect x="168" y="20" width="56" height="20" rx="3" fill="#fbbf24"/>
    <rect x="72" y="56" width="20" height="52" rx="3" fill="#9ca3af"/>
    <rect x="96" y="56" width="54" height="70" rx="5" fill="#111827"/>
    <rect x="36" y="18" width="44" height="26" rx="3" fill="#f59e0b"/>
    <text x="128" y="34" text-anchor="middle" font-size="14" font-family="Arial" fill="#fbbf24" font-weight="700">4TH</text>
  </g>''', spot="#fbbf24", edge="#fbbf24"),
}


def lua_escape(s):
    return s.replace("\\", "\\\\").replace("'", "\\'")


def emit_lua():
    lines = ["Config.Tiers = {"]
    for t in TIERS:
        lines.append("    {")
        lines.append(f"        tier = {t['tier']},")
        lines.append(f"        name = '{lua_escape(t['name'])}',")
        lines.append(f"        description = '{lua_escape(t['description'])}',")
        lines.append(f"        type = '{t['type']}',")
        lines.append(f"        item = '{lua_escape(t['item'])}',")
        lines.append(f"        amount = {t['amount']},")
        lines.append(f"        rarity = '{t['rarity']}',")
        lines.append("        premium = false,")
        lines.append(f"        icon = '{t['icon']}'")
        lines.append("    },")
    lines.append("}")
    return "\n".join(lines)


def main():
    public = []
    for t in TIERS:
        public.append({
            "tier": t["tier"],
            "name": t["name"],
            "description": t["description"],
            "type": t["type"],
            "item": t["item"],
            "amount": t["amount"],
            "rarity": t["rarity"],
            "premium": False,
            "icon": t["icon"],
        })
        (ICON_DIR / t["icon"]).write_text(ICONS[t["tier"]], encoding="utf-8")

    (ROOT / "html" / "tiers.json").write_text(json.dumps(public, indent=2) + "\n", encoding="utf-8")
    (ROOT / "tools" / "tiers.generated.lua").write_text(emit_lua() + "\n", encoding="utf-8")
    print("wrote", len(TIERS), "tiers and icons")


if __name__ == "__main__":
    main()
