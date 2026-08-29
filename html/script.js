const IN_FIVEM = typeof GetParentResourceName === 'function';

const CHECK_SVG = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.8"><path d="M5 12.5 10 17.5 19 7"/></svg>`;
const LOCK_SVG = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 10V8a4 4 0 1 1 8 0v2h1.5A1.5 1.5 0 0 1 19 11.5v8A1.5 1.5 0 0 1 17.5 21h-11A1.5 1.5 0 0 1 5 19.5v-8A1.5 1.5 0 0 1 6.5 10H8zm2 0h4V8a2 2 0 1 0-4 0v2z"/></svg>`;

let state = null;
let selectedTier = 1;
let endsAt = 0;

function resourceName() {
  try {
    return GetParentResourceName();
  } catch (_) {
    return 'djfivem-battlepass';
  }
}

function post(name, data) {
  if (!IN_FIVEM) return Promise.resolve({ ok: true });
  return fetch(`https://${resourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {})
  }).then((r) => r.json()).catch(() => ({ ok: false }));
}

function $(id) {
  return document.getElementById(id);
}

function claimedSet() {
  const set = new Set();
  (state.claimed || []).forEach((n) => set.add(Number(n)));
  return set;
}

function isUnlocked(tier) {
  return (state.unlocked || 0) >= tier;
}

function isClaimed(tier) {
  return claimedSet().has(tier);
}

function isLocked(tier) {
  return !isUnlocked(tier);
}

function claimableCount() {
  if (!state) return 0;
  return (state.tiers || []).filter((t) => {
    if (isClaimed(t.tier) || isLocked(t.tier)) return false;
    if (t.premium && !state.premium) return false;
    return true;
  }).length;
}

function formatTimer(total) {
  total = Math.max(0, Math.floor(total));
  const d = Math.floor(total / 86400);
  const h = Math.floor((total % 86400) / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const pad = (n) => String(n).padStart(2, '0');
  return `${d}d ${pad(h)}h ${pad(m)}m ${pad(s)}s`;
}

function rarityClass(rarity) {
  return ['legendary', 'epic', 'rare', 'common'].includes(rarity) ? rarity : 'common';
}

function typeLabel(t) {
  if (t.type === 'money') return 'Cash';
  if (t.type === 'weapon') return 'Weapon';
  if (t.type === 'vehicle') return 'Vehicle';
  return 'Item';
}

function iconSrc(t) {
  return `icons/${t.icon || ('tier_' + String(t.tier).padStart(2, '0') + '.svg')}`;
}

function currentReward() {
  return (state.tiers || []).find((t) => t.tier === selectedTier) || state.tiers[0];
}

function toast(msg) {
  const el = $('toast');
  el.textContent = msg;
  el.classList.remove('hidden');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.add('hidden'), 2200);
}

function renderHeader() {
  const total = state.totalTiers || 28;
  const claimed = state.claimedCount || claimedSet().size;
  const pct = Math.round((claimed / total) * 100);
  $('seasonLabel').textContent = state.seasonLabel || `BATTLE PASS C${state.chapter}S${state.season}`;
  $('pctComplete').textContent = `${pct}% COMPLETE`;
  $('claimedHeader').textContent = `${claimed} / ${total} CLAIMED`;
}

function renderLeft() {
  const total = state.totalTiers || 28;
  const unlocked = state.unlocked || 0;
  const claimed = state.claimedCount || claimedSet().size;
  const level = unlocked >= total ? total : Math.max(1, unlocked + 1);
  $('levelValue').textContent = `LEVEL ${level}`;
  $('tierLine').textContent = `Tier ${unlocked} / ${total}`;
  const into = state.xpIntoTier || 0;
  const per = state.xpPerTier || 2000;
  $('xpFill').style.width = `${Math.min(100, (into / per) * 100)}%`;
  $('xpMeta').textContent = `${into} / ${per} XP`;
  $('statUnlocked').textContent = unlocked;
  $('statClaimed').textContent = claimed;
  $('statRemain').textContent = Math.max(0, total - claimed);
  const mult = $('xpMult');
  if (state.premium) {
    mult.classList.add('on');
    mult.textContent = `${Number(state.premiumMultiplier || 2)}X XP`;
  } else {
    mult.classList.remove('on');
  }
  const card = $('premiumCard');
  if (state.premium) {
    card.classList.add('active');
    $('premiumTitle').textContent = 'PREMIUM ACTIVE';
    $('premiumSub').textContent = 'All premium benefits unlocked.';
  } else {
    card.classList.remove('active');
    $('premiumTitle').textContent = 'PREMIUM LOCKED';
    $('premiumSub').textContent = 'Buy premium to unlock 2x city XP and paid tiers.';
  }
}

function renderPreview() {
  const t = currentReward();
  if (!t) return;
  $('previewImage').src = iconSrc(t);
  $('previewName').textContent = t.name.toUpperCase();
  $('previewDesc').textContent = t.description || '';
  $('previewType').textContent = typeLabel(t);
  $('previewTags').innerHTML = [
    `<span class="tag ${rarityClass(t.rarity)}">${(t.rarity || 'common').toUpperCase()}</span>`,
    `<span class="tag tier">TIER ${t.tier}</span>`,
    t.premium
      ? `<span class="tag premium">PREMIUM</span>`
      : `<span class="tag free">FREE</span>`
  ].join('');

  const btn = $('claimBtn');
  btn.disabled = false;
  btn.className = 'claim-btn';
  if (isClaimed(t.tier)) {
    btn.textContent = 'CLAIMED';
    btn.classList.add('claimed');
    btn.disabled = true;
  } else if (isLocked(t.tier)) {
    btn.textContent = 'LOCKED';
    btn.classList.add('locked');
    btn.disabled = true;
  } else if (t.premium && !state.premium) {
    btn.textContent = 'PREMIUM REQUIRED';
    btn.classList.add('premium');
    btn.disabled = true;
  } else if ((state.remainingSeconds || 0) <= 0) {
    btn.textContent = 'SEASON ENDED';
    btn.classList.add('ended');
    btn.disabled = true;
  } else {
    btn.textContent = '✓  CLAIM REWARD';
  }
}

function renderTrack() {
  const track = $('track');
  const keepScroll = track.scrollLeft;
  const claimed = claimedSet();
  track.innerHTML = (state.tiers || []).map((t) => {
    const locked = isLocked(t.tier);
    const done = claimed.has(t.tier);
    const selected = t.tier === selectedTier ? ' selected' : '';
    const flag = t.premium
      ? `<div class="card-flag">${typeLabel(t).toUpperCase()}</div>`
      : `<div class="card-flag free">FREE</div>`;
    return `
      <article class="card${selected}${locked ? ' locked' : ''}${done ? ' claimed' : ''}" data-tier="${t.tier}">
        <div class="card-next">NEXT</div>
        <div class="card-check">${CHECK_SVG}</div>
        <div class="card-tier">${t.tier}</div>
        <div class="card-art"><img src="${iconSrc(t)}" alt="" /></div>
        <div class="card-name">${t.name}</div>
        <div class="card-lock">${LOCK_SVG}</div>
        ${flag}
      </article>
    `;
  }).join('');

  const total = state.totalTiers || 28;
  const unlocked = state.unlocked || 0;
  const fill = total <= 1 ? 0 : (unlocked / (total - 1)) * 100;
  $('timeline').innerHTML = `
    <div class="timeline-line"></div>
    <div class="timeline-fill" style="width:${Math.min(100, fill)}%"></div>
    <div class="timeline-nodes">
      ${(state.tiers || []).map((t) => `<span class="node${t.tier <= unlocked ? ' on' : ''}"></span>`).join('')}
    </div>
  `;

  const n = claimableCount();
  const all = $('claimAllBtn');
  all.textContent = n > 0 ? `CLAIM ALL (${n})` : 'CLAIM ALL';
  all.disabled = n === 0;
  track.scrollLeft = keepScroll;
}

function render() {
  if (!state) return;
  renderHeader();
  renderLeft();
  renderTrack();
  renderPreview();
}

function selectTier(tier, scroll) {
  selectedTier = Number(tier);
  render();
  if (scroll) {
    const el = document.querySelector(`.card[data-tier="${selectedTier}"]`);
    if (el) el.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' });
  }
}

function pickDefaultTier(data) {
  const claimed = new Set((data.claimed || []).map(Number));
  const unlocked = data.unlocked || 0;
  for (const t of data.tiers || []) {
    if (t.tier <= unlocked && !claimed.has(t.tier) && !(t.premium && !data.premium)) {
      return t.tier;
    }
  }
  return Math.max(1, unlocked || 1);
}

function openUi(data, preferTier) {
  state = data;
  endsAt = Date.now() + (data.remainingSeconds || 0) * 1000;
  selectedTier = preferTier || pickDefaultTier(data);
  if (selectedTier > (data.totalTiers || 28)) selectedTier = data.totalTiers;
  document.getElementById('app').classList.remove('hidden');
  render();
  const current = document.querySelector(`.card[data-tier="${selectedTier}"]`);
  if (current) current.scrollIntoView({ inline: 'center', block: 'nearest' });
}

function closeUi() {
  document.getElementById('app').classList.add('hidden');
  post('close');
}

function hydrate(data) {
  const wasOpen = !document.getElementById('app').classList.contains('hidden');
  state = data;
  endsAt = Date.now() + (data.remainingSeconds || 0) * 1000;
  if (wasOpen || !IN_FIVEM) {
    document.getElementById('app').classList.remove('hidden');
    render();
  }
}

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'open') {
    document.getElementById('app').classList.remove('hidden');
  } else if (msg.action === 'close') {
    document.getElementById('app').classList.add('hidden');
  } else if (msg.action === 'hydrate') {
    if (document.getElementById('app').classList.contains('hidden')) {
      openUi(msg.data);
    } else {
      hydrate(msg.data);
    }
  } else if (msg.action === 'tierUp') {
    toast(`TIER ${msg.tier} UNLOCKED  ·  ${msg.name || ''}`);
  }
});

document.addEventListener('keydown', (e) => {
  if (document.getElementById('app').classList.contains('hidden')) return;
  if (e.key === 'Escape') {
    closeUi();
  } else if (e.key === 'ArrowRight') {
    selectTier(Math.min((state.totalTiers || 28), selectedTier + 1), true);
  } else if (e.key === 'ArrowLeft') {
    selectTier(Math.max(1, selectedTier - 1), true);
  }
});

$('claimBtn').addEventListener('click', () => {
  const t = currentReward();
  if (!t) return;
  post('claim', { tier: t.tier });
  if (!IN_FIVEM) {
    state.claimed = [...(state.claimed || []), t.tier];
    state.claimedCount = state.claimed.length;
    render();
  }
});

$('claimAllBtn').addEventListener('click', () => {
  post('claimAll');
  if (!IN_FIVEM) {
    state.tiers.forEach((t) => {
      if (isUnlocked(t.tier) && !(t.premium && !state.premium) && !isClaimed(t.tier)) {
        state.claimed.push(t.tier);
      }
    });
    state.claimedCount = state.claimed.length;
    render();
  }
});

(function dragScroll() {
  const el = $('track');
  let startX = 0;
  let scroll = 0;
  let moved = false;
  let active = false;
  let pendingTier = null;

  el.addEventListener('pointerdown', (e) => {
    if (e.button !== 0) return;
    const card = e.target.closest('.card');
    pendingTier = card ? Number(card.dataset.tier) : null;
    active = true;
    moved = false;
    startX = e.clientX;
    scroll = el.scrollLeft;
    el.classList.add('dragging');
    el.setPointerCapture(e.pointerId);
  });

  el.addEventListener('pointermove', (e) => {
    if (!active) return;
    const dx = e.clientX - startX;
    if (Math.abs(dx) > 8) moved = true;
    if (moved) el.scrollLeft = scroll - dx;
  });

  const end = () => {
    if (!active) return;
    active = false;
    el.classList.remove('dragging');
    if (!moved && pendingTier) selectTier(pendingTier, false);
    pendingTier = null;
  };

  el.addEventListener('pointerup', end);
  el.addEventListener('pointercancel', () => {
    active = false;
    pendingTier = null;
    el.classList.remove('dragging');
  });
})();

setInterval(() => {
  if (!state) return;
  const left = Math.max(0, Math.round((endsAt - Date.now()) / 1000));
  state.remainingSeconds = left;
  $('seasonTimer').textContent = formatTimer(left);
}, 250);

const MOCK_TIERS = [
  ['Street Starter', 'A little cash to get you moving through the city.', 'money', 2500, 'common', false],
  ['Bandage Bundle', 'Ten field bandages. Patch up and keep grinding.', 'item', 10, 'common', true],
  ['Big Drinks', 'A fridge pack of cold drinks for long nights in the city.', 'item', 15, 'common', true],
  ['LSD', 'A small bag of tabs. Handle with care.', 'item', 5, 'rare', true],
  ['Knife', 'A sharp blade for when words stop working.', 'weapon', 1, 'common', false],
  ['Lockpick Kit', 'Eight lockpicks. Quiet hands, open doors.', 'item', 8, 'common', true],
  ['Adrenaline Shots', 'Five syringes. Get back on your feet fast.', 'item', 5, 'rare', true],
  ['Black and Cyan Crown', 'Season 1 flex piece. Wear it like you earned it.', 'item', 1, 'epic', true],
  ['44MM Ammo', '85x .44 caliber rounds, spend them wisely.', 'item', 85, 'rare', true],
  ['Bag of Money', 'A stuffed bag of dirty city cash.', 'money', 10000, 'rare', true],
  ['Tec-9', 'A compact machine pistol. Free track hardware.', 'weapon', 1, 'rare', false],
  ['10x Sprunks', 'Ten ice-cold Sprunks. Stay sharp.', 'item', 10, 'common', true],
  ['A Box of Money', 'A sealed box packed with city bills.', 'money', 20000, 'epic', true],
  ['Dino Plan', 'A rare collectible blueprint. Frame it or flip it.', 'item', 1, 'epic', true],
  ['Heavy Armor', 'Two heavy vests rated for a bad night.', 'item', 2, 'rare', true],
  ['Gold Chain', 'Thick gold. Let them know you are climbing the pass.', 'item', 1, 'rare', true],
  ['AP Pistol', 'Armor-piercing sidearm. Free track, high value.', 'weapon', 1, 'epic', false],
  ['Cash Drop', 'Twenty-five thousand, no questions asked.', 'money', 25000, 'rare', true],
  ['Encrypted Radio', 'A tuned radio for crews that do not like scanners.', 'item', 1, 'rare', true],
  ['SMG Ammo Crate', '200 rounds of SMG ammo, crate and all.', 'item', 200, 'rare', true],
  ['Thick Envelope', 'Forty thousand in a fat envelope. Free track payday.', 'money', 40000, 'epic', false],
  ['Drift Plate', 'A custom plate voucher for your next build.', 'item', 1, 'epic', true],
  ['Combat PDW', 'A compact PDW for close city work.', 'weapon', 1, 'epic', true],
  ['Season Crate', 'A sealed Chapter 1 crate. Open it when you are ready.', 'item', 1, 'legendary', true],
  ['Vault Stack', 'Seventy-five thousand. The free track does pay.', 'money', 75000, 'legendary', false],
  ['Garage Voucher', 'Priority garage slot voucher for your next ride.', 'item', 1, 'epic', true],
  ['Diamond Rolex', 'Iced out. Chapter 1 status on your wrist.', 'item', 1, 'legendary', true],
  ['Champion 1F', 'Season 1 champion vehicle. The city will see you coming.', 'vehicle', 1, 'legendary', true]
];

function mockState() {
  const tiers = MOCK_TIERS.map((row, i) => ({
    tier: i + 1,
    name: row[0],
    description: row[1],
    type: row[2],
    amount: row[3],
    rarity: row[4],
    premium: row[5],
    icon: `tier_${String(i + 1).padStart(2, '0')}.svg`
  }));
  const unlocked = 11;
  const claimed = [1, 2, 3, 4, 5, 6, 7, 8, 10];
  return {
    title: 'DJFIVEM-Battlepass',
    chapter: 1,
    season: 1,
    seasonLabel: 'BATTLE PASS C1S1',
    xp: 11 * 2000 + 100,
    xpPerTier: 2000,
    xpIntoTier: 100,
    maxXp: 28 * 2000,
    level: 12,
    unlocked,
    claimed,
    claimedCount: claimed.length,
    premium: true,
    premiumMultiplier: 2,
    remainingSeconds: 30 * 24 * 60 * 60 - 3600,
    totalTiers: 28,
    closeKey: 'ESC',
    openKey: 'F12',
    tiers
  };
}

if (!IN_FIVEM) {
  document.body.classList.add('preview');
  openUi(mockState(), 9);
} else {
  post('ready');
}
