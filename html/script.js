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

function allFree() {
  return !!(state && (state.allFree || ConfigAllFree));
}

const ConfigAllFree = true;

function needsPremium(t) {
  if (!t || allFree()) return false;
  return !!(t.premium && state && !state.premium);
}

function claimableCount() {
  if (!state) return 0;
  return (state.tiers || []).filter((t) => {
    if (isClaimed(t.tier) || isLocked(t.tier)) return false;
    if (needsPremium(t)) return false;
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
  mult.classList.add('on');
  if (state.premium && !allFree()) {
    mult.textContent = `${Number(state.premiumMultiplier || 2)}X XP`;
  } else {
    mult.textContent = 'CITY XP';
  }
  const card = $('premiumCard');
  card.classList.add('active');
  if (allFree()) {
    $('premiumTitle').textContent = 'ALL TIERS FREE';
    $('premiumSub').textContent = 'Every unlocked reward is claimable. Earn XP by staying in the city.';
  } else if (state.premium) {
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
  const qty = Number(t.amount) > 1 ? `  ·  x${t.amount}` : '';
  $('previewType').textContent = `${typeLabel(t)}${qty}`;
  $('previewTags').innerHTML = [
    `<span class="tag ${rarityClass(t.rarity)}">${(t.rarity || 'common').toUpperCase()}</span>`,
    `<span class="tag tier">TIER ${t.tier}</span>`,
    `<span class="tag free">FREE</span>`
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
  } else if (needsPremium(t)) {
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
    const qty = Number(t.amount) > 1 ? `<div class="card-qty">x${t.amount}</div>` : '';
    return `
      <article class="card${selected}${locked ? ' locked' : ''}${done ? ' claimed' : ''}" data-tier="${t.tier}">
        <div class="card-next">NEXT</div>
        <div class="card-check">${CHECK_SVG}</div>
        ${qty}
        <div class="card-tier">${t.tier}</div>
        <div class="card-art"><img src="${iconSrc(t)}" alt="" /></div>
        <div class="card-name">${t.name}</div>
        <div class="card-lock">${LOCK_SVG}</div>
        <div class="card-flag free">FREE</div>
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
    if (t.tier <= unlocked && !claimed.has(t.tier) && !(t.premium && !data.premium && !data.allFree && !ConfigAllFree)) {
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
  if (!IN_FIVEM && !isClaimed(t.tier) && isUnlocked(t.tier) && !needsPremium(t)) {
    state.claimed = [...(state.claimed || []), t.tier];
    state.claimedCount = state.claimed.length;
    render();
  }
});

$('claimAllBtn').addEventListener('click', () => {
  post('claimAll');
  if (!IN_FIVEM) {
    state.tiers.forEach((t) => {
      if (isUnlocked(t.tier) && !needsPremium(t) && !isClaimed(t.tier)) {
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

function mockState(tiers) {
  const unlocked = 11;
  const claimed = [1, 2, 3, 4, 5, 7, 8, 10];
  return {
    title: 'DJFIVEM-Battlepass',
    chapter: 1,
    season: 1,
    seasonLabel: 'BATTLE PASS C1S1',
    allFree: true,
    xp: 11 * 2000 + 100,
    xpPerTier: 2000,
    xpIntoTier: 100,
    maxXp: 28 * 2000,
    level: 12,
    unlocked,
    claimed,
    claimedCount: claimed.length,
    premium: false,
    premiumMultiplier: 2,
    remainingSeconds: 30 * 24 * 60 * 60 - 3600,
    totalTiers: tiers.length || 28,
    closeKey: 'ESC',
    openKey: 'F12',
    tiers
  };
}

if (!IN_FIVEM) {
  document.body.classList.add('preview');
  fetch('tiers.json')
    .then((r) => r.json())
    .then((tiers) => openUi(mockState(tiers), 11))
    .catch(() => openUi(mockState([]), 1));
} else {
  post('ready');
}
