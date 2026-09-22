const IN_FIVEM = typeof GetParentResourceName === 'function';

const CHECK_SVG = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.8"><path d="M5 12.5 10 17.5 19 7"/></svg>`;
const LOCK_SVG = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 10V8a4 4 0 1 1 8 0v2h1.5A1.5 1.5 0 0 1 19 11.5v8A1.5 1.5 0 0 1 17.5 21h-11A1.5 1.5 0 0 1 5 19.5v-8A1.5 1.5 0 0 1 6.5 10H8zm2 0h4V8a2 2 0 1 0-4 0v2z"/></svg>`;

let state = null;
let selectedTier = 1;
let endsAt = 0;
let uiOpen = false;
let trackBuilt = false;
let claimedCache = new Set();
let nextClaimableTier = 0;
const imageCache = new Map();
const imgToken = new WeakMap();

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

function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function refreshClaimed() {
  const set = new Set();
  (state && state.claimed ? state.claimed : []).forEach((n) => {
    const tier = Number(n);
    if (Number.isFinite(tier)) set.add(tier);
  });
  claimedCache = set;
  return set;
}

function isUnlocked(tier) {
  return (state && state.unlocked || 0) >= tier;
}

function isClaimed(tier) {
  return claimedCache.has(tier);
}

function isLocked(tier) {
  return !isUnlocked(tier);
}

function allFree() {
  return !!(state && state.allFree);
}

function needsPremium(t) {
  if (!t || allFree()) return false;
  return !!(t.premium && state && !state.premium);
}

function canClaimTier(t) {
  if (!t || isClaimed(t.tier) || isLocked(t.tier) || needsPremium(t)) return false;
  return (state.remainingSeconds || 0) > 0;
}

function claimableCount() {
  if (!state) return 0;
  return (state.tiers || []).reduce((n, t) => n + (canClaimTier(t) ? 1 : 0), 0);
}

function firstClaimableTier() {
  if (!state) return 0;
  for (const t of state.tiers || []) {
    if (canClaimTier(t)) return t.tier;
  }
  return 0;
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

function fallbackIcon(t) {
  const icon = (t && t.icon) || (`tier_${String((t && t.tier) || 1).padStart(2, '0')}.svg`);
  return `icons/${icon}`;
}

function pushUnique(list, seen, value) {
  if (!value || seen.has(value)) return;
  seen.add(value);
  list.push(value);
}

function oxFileNames(t) {
  const names = [];
  const seen = new Set();
  const add = (name) => {
    if (!name) return;
    const raw = String(name).trim();
    if (!raw) return;
    pushUnique(names, seen, raw);
    const base = raw.replace(/\.(png|webp|jpe?g)$/i, '');
    if (base !== raw) pushUnique(names, seen, base);
  };

  if (t.oxImage && !/^(https?:|nui:)/i.test(t.oxImage)) add(t.oxImage);
  add(t.imageName);
  add(t.item);
  if (t.item) {
    const item = String(t.item);
    add(item.toLowerCase());
    add(item.toUpperCase());
    const lower = item.toLowerCase();
    if (lower.startsWith('weapon_')) {
      add(item.slice(7));
      add(lower.slice(7));
    }
  }
  return names;
}

function inventoryImageUrls(t) {
  if (!t) return [];
  const urls = [];
  const seen = new Set();
  const resource = (state && state.imageResource) || 'ox_inventory';
  const folder = String((state && state.imageFolder) || 'web/images').replace(/^\/+|\/+$/g, '');
  const exts = (state && state.imageExts && state.imageExts.length)
    ? state.imageExts
    : ['png', 'webp'];
  const bases = [
    `https://cfx-nui-${resource}/${folder}`,
    `nui://${resource}/${folder}`
  ];

  if (t.oxImage && /^(https?:|nui:)/i.test(t.oxImage)) {
    pushUnique(urls, seen, t.oxImage);
  }

  const names = oxFileNames(t);
  names.forEach((name) => {
    if (/\.(png|webp|jpe?g)$/i.test(name)) {
      bases.forEach((base) => pushUnique(urls, seen, `${base}/${name}`));
    }
  });
  names.forEach((name) => {
    const stem = name.replace(/\.(png|webp|jpe?g)$/i, '');
    exts.forEach((ext) => {
      bases.forEach((base) => pushUnique(urls, seen, `${base}/${stem}.${ext}`));
    });
  });
  return urls;
}

function cacheKey(t) {
  return String((t && (t.item || t.imageName || t.icon || t.tier)) || '');
}

function setItemImage(img, t) {
  if (!img || !t) return;
  const fallback = fallbackIcon(t);
  const key = cacheKey(t);
  const token = (imgToken.get(img) || 0) + 1;
  imgToken.set(img, token);
  img.onerror = null;
  img.onload = null;

  if (imageCache.has(key)) {
    img.src = imageCache.get(key);
    return;
  }

  // In FiveM every reward icon is resolved from ox_inventory/web/images.
  // Browser preview cannot reach nui:// so it uses the local SVG fallback.
  const queue = IN_FIVEM ? inventoryImageUrls(t) : [];
  if (!queue.length) {
    imageCache.set(key, fallback);
    img.src = fallback;
    return;
  }

  let i = 0;
  const next = () => {
    if (imgToken.get(img) !== token) return;
    if (i >= queue.length) {
      img.onerror = null;
      img.onload = null;
      imageCache.set(key, fallback);
      img.src = fallback;
      return;
    }
    img.src = queue[i++];
  };

  img.onload = () => {
    if (imgToken.get(img) !== token) return;
    img.onload = null;
    img.onerror = null;
    imageCache.set(key, img.currentSrc || img.src);
  };
  img.onerror = next;
  next();
}

function bindItemImages(root) {
  const tiers = state && state.tiers ? state.tiers : [];
  (root || document).querySelectorAll('img[data-item-tier]').forEach((img) => {
    const tier = Number(img.dataset.itemTier);
    const t = tiers.find((row) => row.tier === tier);
    setItemImage(img, t);
  });
}

function currentReward() {
  const tiers = (state && state.tiers) || [];
  return tiers.find((t) => t.tier === selectedTier) || tiers[0] || null;
}

function toast(msg) {
  const el = $('toast');
  if (!el) return;
  el.textContent = msg;
  el.classList.remove('hidden');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.add('hidden'), 2200);
}

function renderHeader() {
  const total = state.totalTiers || 28;
  const claimed = state.claimedCount || claimedCache.size;
  const pct = total ? Math.round((claimed / total) * 100) : 0;
  $('seasonLabel').textContent = state.seasonLabel || `CHAPTER ${state.chapter}  ·  SEASON ${state.season}`;
  $('pctComplete').textContent = `${pct}% COMPLETE`;
  $('claimedHeader').textContent = `${claimed} / ${total} CLAIMED`;
  if ($('pctFill')) $('pctFill').style.width = `${Math.min(100, pct)}%`;
  if ($('claimedFill')) $('claimedFill').style.width = `${Math.min(100, total ? (claimed / total) * 100 : 0)}%`;
  if ($('closeKey') && state.closeKey) $('closeKey').textContent = state.closeKey;
}

function renderLeft() {
  const total = state.totalTiers || 28;
  const unlocked = state.unlocked || 0;
  const claimed = state.claimedCount || claimedCache.size;
  const level = unlocked >= total ? total : Math.max(1, unlocked + 1);
  $('levelValue').textContent = `LEVEL ${level}`;
  $('tierLine').textContent = `Tier ${unlocked} / ${total}`;
  const into = state.xpIntoTier || 0;
  const per = state.xpPerTier || 2000;
  $('xpFill').style.width = `${Math.min(100, per ? (into / per) * 100 : 0)}%`;
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
  const preview = $('previewImage');
  preview.dataset.itemTier = String(t.tier);
  setItemImage(preview, t);
  const rarity = rarityClass(t.rarity);
  const frame = $('previewFrame');
  if (frame) frame.className = `preview-frame ${rarity}`;
  $('previewName').textContent = String(t.name || '').toUpperCase();
  $('previewDesc').textContent = t.description || '';
  const qty = Number(t.amount) > 1 ? `  ·  x${t.amount}` : '';
  $('previewType').textContent = `TYPE: ${typeLabel(t)}${qty}`;
  $('previewTags').innerHTML = [
    `<span class="tag ${rarity}">${escapeHtml((t.rarity || 'common').toUpperCase())}</span>`,
    `<span class="tag tier">TIER ${escapeHtml(t.tier)}</span>`,
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
    btn.textContent = 'CLAIM REWARD';
  }
}

function updateClaimAll() {
  const n = claimableCount();
  const all = $('claimAllBtn');
  all.textContent = n > 0 ? `CLAIM ALL (${n})` : 'CLAIM ALL';
  all.disabled = n === 0;
}

function patchTrackClasses() {
  nextClaimableTier = firstClaimableTier();
  document.querySelectorAll('#track .card').forEach((card) => {
    const tier = Number(card.dataset.tier);
    card.classList.toggle('locked', isLocked(tier));
    card.classList.toggle('claimed', claimedCache.has(tier));
    card.classList.toggle('selected', tier === selectedTier);
    card.classList.toggle('claimable', canClaimTier({ tier, premium: card.dataset.premium === '1' }));
    card.classList.toggle('next-up', tier === nextClaimableTier && tier !== selectedTier);
  });
  const total = state.totalTiers || 28;
  const unlocked = state.unlocked || 0;
  const fill = total <= 1 ? 0 : (unlocked / (total - 1)) * 100;
  const bar = document.querySelector('#timeline .timeline-fill');
  if (bar) bar.style.width = `${Math.min(100, fill)}%`;
  document.querySelectorAll('#timeline .node').forEach((node) => {
    const tier = Number(node.dataset.tier);
    node.classList.toggle('on', Number.isFinite(tier) ? tier <= unlocked : false);
  });
  updateClaimAll();
}

function renderTrack(force) {
  const track = $('track');
  if (trackBuilt && !force && track.children.length) {
    patchTrackClasses();
    return;
  }
  const keepScroll = track.scrollLeft;
  nextClaimableTier = firstClaimableTier();
  track.innerHTML = (state.tiers || []).map((t) => {
    const locked = isLocked(t.tier);
    const done = claimedCache.has(t.tier);
    const selected = t.tier === selectedTier ? ' selected' : '';
    const claimable = canClaimTier(t) ? ' claimable' : '';
    const nextUp = t.tier === nextClaimableTier && t.tier !== selectedTier ? ' next-up' : '';
    const rarity = ` rarity-${rarityClass(t.rarity)}`;
    const qty = Number(t.amount) > 1 ? `<div class="card-qty">x${escapeHtml(t.amount)}</div>` : '';
    return `
      <article class="card${selected}${locked ? ' locked' : ''}${done ? ' claimed' : ''}${claimable}${nextUp}${rarity}" data-tier="${t.tier}" data-premium="${t.premium ? '1' : '0'}">
        <div class="card-next">NEXT</div>
        <div class="card-check">${CHECK_SVG}</div>
        ${qty}
        <div class="card-tier">${escapeHtml(t.tier)}</div>
        <div class="card-art"><img data-item-tier="${t.tier}" alt="${escapeHtml(t.name)}" /></div>
        <div class="card-name">${escapeHtml(t.name)}</div>
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
      ${(state.tiers || []).map((t) => `<span class="node${t.tier <= unlocked ? ' on' : ''}" data-tier="${t.tier}"></span>`).join('')}
    </div>
  `;

  updateClaimAll();
  track.scrollLeft = keepScroll;
  bindItemImages(track);
  trackBuilt = true;
}

function render(forceTrack) {
  if (!state) return;
  refreshClaimed();
  renderHeader();
  renderLeft();
  renderTrack(forceTrack);
  renderPreview();
}

function selectTier(tier, scroll) {
  selectedTier = Number(tier);
  patchTrackClasses();
  renderPreview();
  if (scroll) {
    const el = document.querySelector(`.card[data-tier="${selectedTier}"]`);
    if (el) el.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' });
  }
}

function pickDefaultTier(data) {
  const claimed = new Set((data.claimed || []).map(Number));
  const unlocked = data.unlocked || 0;
  for (const t of data.tiers || []) {
    if (t.tier <= unlocked && !claimed.has(t.tier) && !(t.premium && !data.premium && !data.allFree)) {
      return t.tier;
    }
  }
  return Math.max(1, unlocked || 1);
}

function hideOverlay() {
  uiOpen = false;
  $('app').classList.add('hidden');
}

function openUi(data, preferTier) {
  if (!data) return;
  state = data;
  refreshClaimed();
  endsAt = Date.now() + (data.remainingSeconds || 0) * 1000;
  selectedTier = preferTier || pickDefaultTier(data);
  if (selectedTier > (data.totalTiers || 28)) selectedTier = data.totalTiers || selectedTier;
  uiOpen = true;
  $('app').classList.remove('hidden');
  render(true);
  const current = document.querySelector(`.card[data-tier="${selectedTier}"]`);
  if (current) current.scrollIntoView({ inline: 'center', block: 'nearest' });
}

function closeUi() {
  hideOverlay();
  if (IN_FIVEM) post('close');
}

function applyUpdate(data) {
  if (!data) return;
  state = data;
  refreshClaimed();
  endsAt = Date.now() + (data.remainingSeconds || 0) * 1000;
  if (!uiOpen) return;
  render(false);
}

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'open') {
    if (msg.data) openUi(msg.data);
    else if (state) {
      uiOpen = true;
      $('app').classList.remove('hidden');
    }
  } else if (msg.action === 'close') {
    hideOverlay();
  } else if (msg.action === 'update' || msg.action === 'hydrate') {
    applyUpdate(msg.data);
  } else if (msg.action === 'tierUp') {
    if (uiOpen) toast(`TIER ${msg.tier} UNLOCKED  ·  ${msg.name || ''}`);
  }
});

document.addEventListener('keydown', (e) => {
  if ($('app').classList.contains('hidden') || !state) return;
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
  if (!t || !canClaimTier(t)) return;
  post('claim', { tier: t.tier });
  if (!IN_FIVEM && !isClaimed(t.tier) && isUnlocked(t.tier) && !needsPremium(t)) {
    state.claimed = [...(state.claimed || []), t.tier];
    state.claimedCount = state.claimed.length;
    render();
  }
});

$('claimAllBtn').addEventListener('click', () => {
  if (!claimableCount()) return;
  post('claimAll');
  if (!IN_FIVEM) {
    (state.tiers || []).forEach((t) => {
      if (canClaimTier(t)) state.claimed.push(t.tier);
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

  const end = (e) => {
    if (!active) return;
    active = false;
    el.classList.remove('dragging');
    try { el.releasePointerCapture(e.pointerId); } catch (_) {}
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
  if (!uiOpen || !state) return;
  const left = Math.max(0, Math.round((endsAt - Date.now()) / 1000));
  state.remainingSeconds = left;
  const el = $('seasonTimer');
  if (el) el.textContent = formatTimer(left);
  if (left === 0) {
    renderPreview();
    updateClaimAll();
  }
}, 1000);

function mockState(tiers) {
  const unlocked = 11;
  const claimed = [1, 2, 3, 4, 5, 7, 8, 10];
  return {
    title: 'DJFIVEM-Battlepass',
    chapter: 1,
    season: 1,
    seasonLabel: 'CHAPTER 1  ·  SEASON 1',
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
    imageResource: 'ox_inventory',
    imageFolder: 'web/images',
    imageExts: ['png', 'webp'],
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
  hideOverlay();
  post('ready');
}
