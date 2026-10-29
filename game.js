import { clamp, faceHit, blocked, uniqueSpots } from './lib/logic.mjs';
import { PERSONALITY, chooseCoverRoute, chooseFlankRoute, chooseNoiseSpot, canRehide } from './lib/npc-ai.mjs';
import { drawFloorDetail, drawSetDressing } from './scenery.js';
import { createTelegramGameBridge } from './telegram-game.js';

const $ = id => document.getElementById(id);
const canvas = $('world'), ctx = canvas.getContext('2d', { alpha: false });
const root = $('gameRoot');
const characterInfo = [
  { id: 'ramin', name: 'رامین', width: 210, height: 362, lip: 136, color: '#f5838f' },
  { id: 'borhan', name: 'برهان', width: 210, height: 362, lip: 125, color: '#a2d6e0' },
  { id: 'mammad', name: 'ممد', width: 87, height: 150, lip: 136, color: '#f5ce7c' },
];
const spriteImages = {};
for (const info of characterInfo) {
  const img = new Image();
  img.src = './assets/' + info.id + '.png';
  img.onload = () => spriteImages[info.id] = img;
}
const walls = [
  { x: 73, y: 73, w: 1370, h: 22 }, { x: 73, y: 932, w: 1370, h: 22 },
  { x: 73, y: 73, w: 22, h: 880 }, { x: 1421, y: 73, w: 22, h: 880 },
  { x: 516, y: 82, w: 23, h: 250 }, { x: 516, y: 434, w: 23, h: 265 }, { x: 516, y: 807, w: 23, h: 136 },
  { x: 991, y: 82, w: 23, h: 192 }, { x: 991, y: 378, w: 23, h: 246 }, { x: 991, y: 715, w: 23, h: 228 },
  { x: 82, y: 517, w: 196, h: 23 }, { x: 395, y: 517, w: 301, h: 23 },
  { x: 847, y: 517, w: 290, h: 23 }, { x: 1257, y: 517, w: 170, h: 23 }
];
const furniture = [
  { x: 143, y: 205, w: 135, h: 70, type: 'sofa', label: 'SOFA', color: '#9276ba' },
  { x: 383, y: 144, w: 68, h: 98, type: 'closet', label: 'CLOSET', color: '#b17858' },
  { x: 317, y: 369, w: 102, h: 64, type: 'table', label: 'TABLE', color: '#b98c63' },
  { x: 650, y: 193, w: 114, h: 75, type: 'bed', label: 'BED', color: '#809bc8' },
  { x: 825, y: 367, w: 104, h: 69, type: 'desk', label: 'DESK', color: '#b6a076' },
  { x: 1129, y: 175, w: 158, h: 83, type: 'table', label: 'DINING', color: '#b89063' },
  { x: 1286, y: 356, w: 83, h: 73, type: 'closet', label: 'SHELF', color: '#a4795b' },
  { x: 176, y: 693, w: 140, h: 81, type: 'sofa', label: 'SOFA', color: '#75a19a' },
  { x: 357, y: 821, w: 93, h: 61, type: 'table', label: 'TABLE', color: '#ad7d6a' },
  { x: 653, y: 690, w: 131, h: 80, type: 'bed', label: 'BED', color: '#ba89a6' },
  { x: 854, y: 830, w: 91, h: 71, type: 'closet', label: 'SHELF', color: '#8e6a4f' },
  { x: 1110, y: 682, w: 145, h: 75, type: 'sofa', label: 'SOFA', color: '#ba9179' },
  { x: 1323, y: 830, w: 72, h: 69, type: 'desk', label: 'DESK', color: '#a7856a' }
];
const obstacles = [...walls, ...furniture];
// Hiding points are reachable at furniture edges; NPCs never walk through solid tables.
const spots = [
  { x: 384, y: 299, name: 'کمد اتاق نشیمن', cover: 'closet' },
  { x: 735, y: 337, name: 'تخت اتاق خواب', cover: 'bed' },
  { x: 1225, y: 319, name: 'میز آشپزخانه', cover: 'table' },
  { x: 261, y: 835, name: 'مبل پذیرایی', cover: 'sofa' },
  { x: 881, y: 792, name: 'کتابخانه', cover: 'closet' },
  { x: 1264, y: 834, name: 'صندلی اتاق', cover: 'desk' },
  { x: 367, y: 459, name: 'زیر میز نشیمن', cover: 'table' },
  { x: 1217, y: 288, name: 'زیر میز آشپزخانه', cover: 'table' },
  { x: 397, y: 902, name: 'زیر میز پذیرایی', cover: 'table' },
];
const rooms = [
  { x: 95, y: 95, w: 421, h: 422, name: 'اتاق نشیمن', c: '#393c58' },
  { x: 539, y: 95, w: 452, h: 422, name: 'اتاق خواب', c: '#3d465d' },
  { x: 1014, y: 95, w: 407, h: 422, name: 'آشپزخانه', c: '#454251' },
  { x: 95, y: 540, w: 421, h: 392, name: 'پذیرایی', c: '#405157' },
  { x: 539, y: 540, w: 452, h: 392, name: 'اتاق مطالعه', c: '#453c54' },
  { x: 1014, y: 540, w: 407, h: 392, name: 'انباری', c: '#484453' }
];
const number = value => new Intl.NumberFormat('fa-IR').format(value);
const telegramBridge = createTelegramGameBridge({
  onStatus: text => { $('telegramStatus').textContent = text; },
  onLeaderboard: data => {
    const list = $('telegramLeaderboard');
    list.replaceChildren();
    for (const player of (data?.top || []).slice(0, 10)) {
      const item = document.createElement('li');
      item.textContent = number(player.rank) + '. ' + player.name + ' — ' + number(player.score);
      list.append(item);
    }
    if (data?.me) $('telegramStatus').textContent += ' رتبه شما: ' + number(data.me.rank);
  },
});
$('telegramPanel').hidden = !telegramBridge.enabled;
$('telegramShare').addEventListener('click', () => telegramBridge.shareScore());
$('telegramRank').addEventListener('click', () => { void telegramBridge.leaderboard(); });
let phase = 'menu', player = { x: 260, y: 435, vx: 0, vy: 0, angle: 0 };
let actors = [], projectiles = [], effects = [], decoys = [], clock = 180, score = 0, fired = 0, caught = 0, lastShot = 0;
let w = innerWidth, h = innerHeight, pixelRatio = 1, lastFrame = 0, now = 0, camera = { x: 0, y: 0 };
let pointer = { x: w / 2, y: h / 2, active: false };
let toast = '', toastUntil = 0, audio = null, mute = false;
let nextHudAt = 0;
const pressed = new Set();
const joystick = { id: null, x: 0, y: 0 };
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const rand = (a, b) => a + Math.random() * (b - a);
function resize() {
  const rect = canvas.getBoundingClientRect();
  w = rect.width; h = rect.height; pixelRatio = Math.min(devicePixelRatio || 1, 2);
  canvas.width = Math.max(1, Math.round(w * pixelRatio));
  canvas.height = Math.max(1, Math.round(h * pixelRatio));
}
new ResizeObserver(resize).observe(root);
resize();
function sound(frequency = 300, length = .11, shape = 'triangle', volume = .035) {
  if (mute) return;
  try {
    audio = audio || new (window.AudioContext || window.webkitAudioContext)();
    if (audio.state === 'suspended') audio.resume();
    const osc = audio.createOscillator(), gain = audio.createGain(), start = audio.currentTime;
    osc.type = shape; osc.frequency.setValueAtTime(frequency, start);
    osc.frequency.exponentialRampToValueAtTime(Math.max(60, frequency * .55), start + length);
    gain.gain.setValueAtTime(volume, start);
    gain.gain.exponentialRampToValueAtTime(.0001, start + length);
    osc.connect(gain).connect(audio.destination); osc.start(start); osc.stop(start + length);
  } catch {}
}
function message(text, duration = 3) { toast = text; toastUntil = now + duration; $('hintText').textContent = text; $('hint').style.opacity = 1; }
/** Start a new round with separated, reachable initial hideouts and reset decoys. */
function reset() {
  player = { x: 320, y: 452, vx: 0, vy: 0, angle: 0 };
  // Ramin begins at one of the under-table spots; the other two start apart.
  const tableStart = uniqueSpots(spots.filter(s => s.cover === 'table' && dist(s, player) > 200), 1)[0];
  const remaining = uniqueSpots(spots.filter(s => s !== tableStart && dist(s, tableStart) > 120 && dist(s, player) > 140), 2);
  const starts = [tableStart, ...remaining];
  actors = characterInfo.map((info, i) => ({
    ...info, behavior: PERSONALITY[info.id],
    x: starts[i].x, y: starts[i].y, home: starts[i], state: 'hidden',
    speed: [160, 178, 145][i], dir: 1, path: [], target: null, refresh: 0,
    wave: rand(0, Math.PI * 2), chaseTime: 0, orbitDirection: 1,
    noiseCountdown: rand(6, 9), lastNoiseSpot: null,
  }));
  clock = 180; score = 0; fired = 0; caught = 0; projectiles = []; effects = []; decoys = []; lastShot = 0;
  document.querySelectorAll('.roster-person').forEach(row => { row.dataset.state = ''; });
  telegramBridge.startRound();
  phase = 'playing'; nextHudAt = 0; $('overlay').classList.add('hidden'); message('سه نفر داخل خانه مخفی‌اند؛ نزدیک وسایل بگرد!', 6);
  renderHud(); canvas.focus();
}
/** Refresh game timer, search hints and personality-specific NPC statuses. */
function renderHud() {
  $('caught').textContent = number(caught) + ' / ۳';
  const pct = Math.max(0, Math.min(100, clock / 180 * 100));
  $('timerFill').style.width = pct + '%';
  $('timerFill').style.background = pct < 22 ? '#ff676e' : '';
  const room = rooms.find(r => player.x >= r.x && player.x < r.x + r.w &&
                               player.y >= r.y && player.y < r.y + r.h);
  $('roomName').textContent = room?.name || 'راهرو';
  const nearHidden = actors.some(a => a.state === 'hidden' && dist(a, player) < 155);
  const nearNoise = decoys.some(d => dist(d, player) < 140);
  $('inspectPrompt').classList.toggle('active', phase === 'playing' && (nearHidden || nearNoise));
  for (const actor of actors) {
    const row = document.querySelector('.roster-person[data-character="' + actor.id + '"]');
    if (!row) continue;
    const fleeingLabel = actor.behavior === 'cover' ? 'به سمت میز فرار می‌کند!' :
                         actor.behavior === 'flank' ? 'دورت می‌زند!' : 'حواست را پرت می‌کند!';
    const status = actor.state === 'captured' ? ['گرفته شد', '✓'] :
                   actor.state === 'fleeing' ? [fleeingLabel, '!'] :
                   [actor.behavior === 'cover' ? 'زیر وسایل پنهان است' : 'پنهان شده', '؟'];
    if (row.dataset.state === actor.state) continue;
    row.dataset.state = actor.state;
    row.querySelector('.person-info small').textContent = status[0];
    row.querySelector('.person-status').textContent = status[1];
  }
  const seconds = Math.ceil(Math.max(0, clock));
  $('time').textContent = String(Math.floor(seconds / 60)).padStart(2, '0') + ':' + String(seconds % 60).padStart(2, '0');
  $('score').textContent = number(score);
  $('accuracy').textContent = fired ? 'دقت: ' + number(Math.round(caught / fired * 100)) + '٪' : 'دقت: —';
  $('pause').textContent = phase === 'paused' ? '▶' : 'Ⅱ';
  $('pause').setAttribute('aria-label', phase === 'paused' ? 'ادامه بازی' : 'توقف بازی');
}
function showOverlay(title, description, eyebrow, action) {
  try {
    const best = Number(localStorage.getItem('mustache2-best') || 0);
    $('bestScore').textContent = best ? 'بهترین رکورد شما: ' + number(best) : '';
  } catch { $('bestScore').textContent = ''; }
  $('overlayEyebrow').textContent = eyebrow;
  $('overlayTitle').textContent = title; $('overlayDesc').textContent = description;
  $('start').innerHTML = action + ' <span>←</span>'; $('overlay').classList.remove('hidden');
}
function finish(victory) {
  phase = victory ? 'won' : 'lost';
  const final = Math.round(score + (victory ? Math.max(0, clock) * 10 : 0));
  score = final; renderHud();
  void telegramBridge.finishRound({
    score: final, caught, shots: fired, elapsedSeconds: Math.round(180 - clock),
  });
  if (victory) {
    try { const record = Number(localStorage.getItem('mustache2-best') || 0); if (final > record) localStorage.setItem('mustache2-best', final); } catch {}
    sound(750, .4, 'sine', .06);
    showOverlay('هر سه نفر سیبیل‌دار شدند!', 'هر سه شخصیت را گرفتی! امتیاز نهایی: ' + number(final) + '. آماده‌ای یک بار دیگر دنبالشـان بگردی؟', 'ALL THREE CAPTURED', 'دوباره بازی کن');
  } else {
    sound(140, .5, 'sawtooth', .025);
    showOverlay('وقت تمام شد!', 'توانستی ' + number(caught) + ' نفر از ۳ نفر را بگیری. امتیاز: ' + number(final) + '. در دور بعدی جای مخفی‌شدن‌ها عوض می‌شود.', 'TIME IS UP', 'یک فرصت دیگر');
  }
}
function pauseGame() {
  if (phase === 'playing') {
    phase = 'paused'; showOverlay('یه لحظه استراحت!', 'شکار هنوز تمام نشده. هر وقت آماده بودی ادامه بده.', 'GAME PAUSED', 'ادامه بازی');
  } else if (phase === 'paused') {
    phase = 'playing'; $('overlay').classList.add('hidden'); canvas.focus();
  }
  renderHud();
}
$('start').addEventListener('click', () => { sound(500, .1); if (phase === 'paused') pauseGame(); else reset(); });
$('pause').addEventListener('click', pauseGame);
$('sound').addEventListener('click', () => { mute = !mute; $('sound').textContent = 'صدا: ' + (mute ? 'خاموش' : 'روشن'); if (!mute) sound(); });
window.addEventListener('keydown', e => {
  const key = e.key.toLowerCase();
  if (['arrowup','arrowdown','arrowleft','arrowright',' '].includes(key)) e.preventDefault();
  if (e.repeat && ['e','p','escape',' '].includes(key)) return;
  pressed.add(key);
  if (key === 'p' || key === 'escape') pauseGame();
  else if (phase === 'playing' && key === 'e') inspect();
  else if (phase === 'playing' && key === ' ') shoot();
});
window.addEventListener('keyup', e => pressed.delete(e.key.toLowerCase()));
window.addEventListener('blur', () => { pressed.clear(); joystick.x = joystick.y = 0; if (phase === 'playing') pauseGame(); });
function updateCamera() {
  camera.x = clamp(player.x, w / 2, 1516 - w / 2);
  camera.y = clamp(player.y, h / 2, 1026 - h / 2);
  if (w > 1516) camera.x = 758;
  if (h > 1026) camera.y = 513;
}
function screenToWorld(x, y) { return { x: x + camera.x - w / 2, y: y + camera.y - h / 2 }; }
function updatePointer(e) { const r = canvas.getBoundingClientRect(); pointer.x = e.clientX - r.left; pointer.y = e.clientY - r.top; pointer.active = true; }
canvas.addEventListener('pointermove', updatePointer);
canvas.addEventListener('pointerdown', e => { if (phase !== 'playing') return; updatePointer(e); shoot(screenToWorld(pointer.x, pointer.y)); });
/** Reveal the nearest real hider or dispel Mammad's nearby fake clue. */
function inspect() {
  if (phase !== 'playing') return;
  const hidden = actors.filter(a => a.state === 'hidden' && dist(a, player) < 155)
    .sort((a,b) => dist(a,player) - dist(b,player));
  const noises = decoys.filter(d => dist(d, player) < 140)
    .sort((a,b) => dist(a,player) - dist(b,player));
  if (hidden.length && (!noises.length || dist(hidden[0], player) < dist(noises[0], player))) {
    reveal(hidden[0]);
  } else if (noises.length) {
    const noise = noises[0];
    decoys.splice(decoys.indexOf(noise), 1);
    spawnEffect(noise.x, noise.y, '#f8bb7b', 12);
    message('این صدا ساختگی بود! ممد گولت زد؛ جای دیگری را بگرد.', 3.2);
    sound(135, .2, 'triangle');
  } else {
    message('اینجا کسی نیست؛ سراغ مبل‌ها و کمدهای دیگر برو.', 2); sound(180,.08);
  }
}
$('inspect').addEventListener('click', inspect);
/** Transition a hidden NPC into pursuit when the player finds it. */
function reveal(actor) {
  if (actor.state !== 'hidden') return;
  actor.state = 'fleeing'; actor.refresh = 0; actor.chaseTime = 0;
  actor.target = null; actor.path = [];
  message(actor.name + ' را پیدا کردی! قبل از فرار روی لبش شلیک کن!', 4);
  spawnEffect(actor.x, actor.y - 55, '#ffe599', 16); sound(540, .22);
}
function lip(actor) {
  return { x: actor.x, y: actor.y - 84 + 84 * actor.lip / 362 };
}
function shoot(target) {
  if (phase !== 'playing' || now - lastShot < .2) return;
  if (!target) {
    const exposed = actors.filter(a => a.state === 'fleeing').sort((a,b) => dist(a,player) - dist(b,player));
    target = exposed.length ? lip(exposed[0]) : screenToWorld(pointer.x, pointer.y);
  }
  const angle = Math.atan2(target.y - player.y, target.x - player.x);
  const origin = { x: player.x + Math.cos(angle) * 27, y: player.y + Math.sin(angle) * 27 };
  projectiles.push({ ...origin, vx: Math.cos(angle) * 780, vy: Math.sin(angle) * 780, ttl: .85, trail: [] });
  player.angle = angle; lastShot = now; fired++; spawnEffect(origin.x, origin.y, '#ff84b0', 4);
  sound(440, .12, 'square', .018); renderHud();
}
$('fire').addEventListener('click', () => shoot());
function spawnEffect(x, y, color, count = 10) {
  for (let i = 0; i < count; i++) {
    const angle = rand(0, Math.PI * 2), speed = rand(40, 170);
    effects.push({ x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed - 30, ttl: rand(.25, .65), life: .65, color, size: rand(2, 6) });
  }
}
function isSolid(x, y, radius = 16) { return blocked(x, y, radius, obstacles); }
function slide(entity, dx, dy, radius = 16) {
  if (!isSolid(entity.x + dx, entity.y, radius)) entity.x += dx;
  if (!isSolid(entity.x, entity.y + dy, radius)) entity.y += dy;
}
/** Assign a navigable cover/flank route according to the NPC personality. */
function chooseEscape(a) {
  const route = a.behavior === 'flank'
    ? (chooseFlankRoute(a, player, obstacles) || chooseCoverRoute(a, player, spots, obstacles))
    : chooseCoverRoute(a, player, spots, obstacles);
  if (route) {
    a.target = route.target;
    a.path = route.path;
    if (route.orbitDirection) a.orbitDirection = route.orbitDirection;
  } else {
    // Retry shortly rather than walking through furniture or a wall.
    a.target = null; a.path = [];
  }
  a.refresh = a.behavior === 'flank' ? 1.4 : 2.5;
}

/** Spawn a time-limited sound lure away from uncaught NPCs and nearby player. */
function makeFalseNoise(actor) {
  if (decoys.length >= 2) return;
  const others = actors.filter(a => a !== actor && a.state === 'hidden');
  const spot = chooseNoiseSpot(actor, player, spots, others);
  if (!spot) return;
  actor.lastNoiseSpot = spot;
  decoys.push({ x: spot.x, y: spot.y, ttl: 8, life: 8, wave: rand(0, 6) });
  const room = rooms.find(r => spot.x >= r.x && spot.x < r.x + r.w &&
    spot.y >= r.y && spot.y < r.y + r.h);
  message('تق تق! صدای مشکوکی از ' + (room?.name || 'راهرو') + ' می‌آید…', 3.5);
  sound(260, .14, 'triangle', .025);
}
/** Advance one gameplay tick, including player movement, AI, scoring and decoys. */
function simulate(dt) {
  clock -= dt; if (clock <= 0) { clock = 0; finish(false); return; }
  let mx = (pressed.has('d') || pressed.has('arrowright') ? 1 : 0) - (pressed.has('a') || pressed.has('arrowleft') ? 1 : 0) + joystick.x;
  let my = (pressed.has('s') || pressed.has('arrowdown') ? 1 : 0) - (pressed.has('w') || pressed.has('arrowup') ? 1 : 0) + joystick.y;
  const mag = Math.hypot(mx, my);
  if (mag > 0) {
    mx /= Math.max(1,mag); my /= Math.max(1,mag);
    const speed = pressed.has('shift') ? 295 : 218;
    slide(player, mx * speed * dt, my * speed * dt, 19);
  }
  if (pointer.active) {
    const aim = screenToWorld(pointer.x, pointer.y);
    player.angle = Math.atan2(aim.y - player.y, aim.x - player.x);
  } else if (mag > .2) player.angle = Math.atan2(my, mx);
  for (let i = decoys.length - 1; i >= 0; i--) {
    decoys[i].ttl -= dt;
    if (decoys[i].ttl <= 0) decoys.splice(i, 1);
  }
  for (const actor of actors) {
    actor.wave += dt * 5;
    if (actor.id === 'mammad' && actor.state !== 'captured') {
      actor.noiseCountdown -= dt;
      if (actor.noiseCountdown <= 0) {
        makeFalseNoise(actor);
        actor.noiseCountdown = rand(9, 13);
      }
    }
    if (actor.state === 'hidden') {
      if (dist(actor, player) < 78) reveal(actor);
      continue;
    }
    if (actor.state !== 'fleeing') continue;
    actor.chaseTime += dt;
    if (canRehide(actor, player)) {
      actor.state = 'hidden'; actor.home = actor.target;
      actor.path = []; actor.target = null;
      message(actor.name + ' پشت وسایل دوباره قایم شد! پیدایش کن.', 2.5);
      continue;
    }
    actor.refresh -= dt;
    // Keep path searches time-bounded even when furniture blocks every candidate.
    // Re-evaluate at a short interval instead of recalculating BFS each frame.
    if (actor.refresh <= 0) chooseEscape(actor);
    let waypoint = actor.path[0];
    if (!waypoint) waypoint = actor.target;
    if (!waypoint) continue;
    if (dist(actor, waypoint) < 16 && actor.path.length) {
      actor.path.shift(); waypoint = actor.path[0] || actor.target;
    }
    if (!waypoint) continue;
    const dx = waypoint.x - actor.x, dy = waypoint.y - actor.y, length = Math.hypot(dx,dy) || 1;
    const moveX = dx / length * actor.speed * dt, moveY = dy / length * actor.speed * dt;
    slide(actor, moveX, moveY, 15);
    if (Math.abs(moveX) > .1) actor.dir = moveX < 0 ? -1 : 1;
  }
  for (let i = projectiles.length - 1; i >= 0; i--) {
    const p = projectiles[i]; p.ttl -= dt;
    let destroyed = p.ttl <= 0;
    const dx = p.vx * dt, dy = p.vy * dt, steps = Math.max(1, Math.ceil(Math.hypot(dx,dy) / 7));
    for (let s = 0; s < steps && !destroyed; s++) {
      p.x += dx / steps; p.y += dy / steps;
      if (isSolid(p.x, p.y, 5)) { destroyed = true; spawnEffect(p.x,p.y,'#e0bc9f',4); break; }
      for (const a of actors) {
        if (a.state !== 'fleeing') continue;
        const face = lip(a);
        if (faceHit(p.x, p.y, face.x, face.y, 17, 12)) {
          a.state = 'captured'; a.path = []; caught++; score += 1000 + Math.round(clock * 3);
          if (a.id === 'mammad') decoys = [];
          destroyed = true; spawnEffect(face.x,face.y,'#ffdd80',26);
          message('عالی! ' + a.name + ' سیبیل‌دار شد! ' + number(3 - caught) + ' نفر مانده.', 4);
          sound(830,.3,'sine',.055); renderHud();
          if (caught === 3) finish(true);
          break;
        }
        if (Math.abs(p.x - a.x) < 24 && p.y > face.y + 18 && p.y < a.y + 7) {
          destroyed = true; spawnEffect(p.x,p.y,'#ff8ca5',6);
          message('نزدیک بود! باید دقیق روی لبش بخورد.', 1.8);
          break;
        }
      }
    }
    if (destroyed) projectiles.splice(i,1);
  }
  for (let i = effects.length - 1; i >= 0; i--) {
    const p = effects[i]; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 110 * dt; p.ttl -= dt;
    if (p.ttl <= 0) effects.splice(i,1);
  }
  if (now > toastUntil) $('hint').style.opacity = 0;
  if (now >= nextHudAt) { renderHud(); nextHudAt = now + .12; }
}
function roundedRect(x, y, width, height, radius, color) {
  ctx.beginPath(); ctx.roundRect(x,y,width,height,radius); ctx.fillStyle = color; ctx.fill();
}
function renderHouse() {
  ctx.fillStyle = '#141b28'; ctx.fillRect(-2000,-2000,5600,5000);
  ctx.shadowBlur = 35; ctx.shadowColor = '#0008'; roundedRect(63,62,1390,900,8,'#262637'); ctx.shadowBlur=0;
  for (const [index, room] of rooms.entries()) {
    ctx.fillStyle = room.c; ctx.fillRect(room.x,room.y,room.w,room.h);
    drawFloorDetail(ctx, room, index);
    ctx.strokeStyle = '#ffffff08'; ctx.lineWidth = 1;
    for (let x=room.x+25;x<room.x+room.w;x+=36) {ctx.beginPath();ctx.moveTo(x,room.y);ctx.lineTo(x,room.y+room.h);ctx.stroke();}
    for (let y=room.y+22;y<room.y+room.h;y+=36) {ctx.beginPath();ctx.moveTo(room.x,y);ctx.lineTo(room.x+room.w,y);ctx.stroke();}
    ctx.save();ctx.fillStyle='#ffffff2d';ctx.font='800 16px "Noto Sans Arabic",Tahoma,sans-serif';ctx.textAlign='center';ctx.fillText(room.name,room.x+room.w/2,room.y+33);ctx.restore();
  }
  for (const wall of walls) {
    ctx.fillStyle = '#141b26'; ctx.fillRect(wall.x+3,wall.y+8,wall.w,wall.h);
    roundedRect(wall.x,wall.y,wall.w,wall.h,3,'#c4a888');
    ctx.fillStyle='#e1c49d'; ctx.fillRect(wall.x+3,wall.y+2,Math.max(0,wall.w-6),Math.max(0,wall.h-7));
  }
  // Rugs and floor motifs
  for (const [x,y,ww,hh,color] of [[293,339,150,122,'#745466'],[796,334,122,125,'#5c6678'],[1203,323,158,138,'#817067'],[330,786,178,109,'#5a7472'],[776,811,150,105,'#777083']]) {
    ctx.globalAlpha=.36; roundedRect(x-ww/2,y-hh/2,ww,hh,13,color);ctx.globalAlpha=1;
    ctx.strokeStyle='#ffffff2d';ctx.lineWidth=2;ctx.strokeRect(x-ww/2+8,y-hh/2+8,ww-16,hh-16);
  }
  for(const obj of furniture) renderFurniture(obj);
  drawSetDressing(ctx, now);
  // doors have striped thresholds
  ctx.fillStyle = '#f3d7a055';
  for (const [x,y,v] of [[525,382,'v'],[525,752,'v'],[1002,320,'v'],[1002,669,'v'],[338,528,'h'],[773,528,'h'],[1197,528,'h']]) {
    if (v==='v') ctx.fillRect(x-7,y-40,14,80);
    else ctx.fillRect(x-42,y-6,84,12);
  }
}
function renderFurniture(o) {
  ctx.shadowColor='#0006';ctx.shadowBlur=10;ctx.shadowOffsetY=8;
  roundedRect(o.x,o.y,o.w,o.h,8,'#242a38');
  ctx.shadowBlur=0;ctx.shadowOffsetY=0;
  roundedRect(o.x+3,o.y+3,o.w-6,o.h-10,6,o.color);
  ctx.strokeStyle='#201c2980';ctx.lineWidth=3;
  if (o.type==='sofa') {
    roundedRect(o.x+9,o.y+8,o.w-18,19,6,'#ffffff50');
    ctx.beginPath();ctx.moveTo(o.x+o.w/2,o.y+30);ctx.lineTo(o.x+o.w/2,o.y+o.h-14);ctx.stroke();
  } else if(o.type==='bed') {
    roundedRect(o.x+9,o.y+9,o.w-18,23,5,'#e7e4d8');
    roundedRect(o.x+9,o.y+36,o.w-18,o.h-48,5,'#f4f0da55');
  } else if(o.type==='closet') {
    ctx.beginPath();ctx.moveTo(o.x+o.w/2,o.y+7);ctx.lineTo(o.x+o.w/2,o.y+o.h-13);ctx.stroke();
    ctx.fillStyle='#ffdd88';ctx.fillRect(o.x+o.w/2-9,o.y+o.h/2,5,5);ctx.fillRect(o.x+o.w/2+6,o.y+o.h/2,5,5);
  } else if(o.type==='table') {
    roundedRect(o.x+17,o.y+10,o.w-34,o.h-30,5,'#f9daa740');
    ctx.fillStyle='#f5e8c4';ctx.beginPath();ctx.arc(o.x+o.w/2,o.y+o.h/2,10,0,Math.PI*2);ctx.fill();
  } else {
    ctx.fillStyle='#272332';ctx.fillRect(o.x+10,o.y+12,o.w-20,8);
    ctx.fillStyle='#d3bea0';ctx.fillRect(o.x+15,o.y+27,o.w-30,12);
  }
}
function drawMustache(x,y,scale=1,rotation=0,color='#211b2b') {
  ctx.save();ctx.translate(x,y);ctx.rotate(rotation);ctx.scale(scale,scale);
  ctx.fillStyle=color;ctx.beginPath();
  ctx.moveTo(0,3);ctx.bezierCurveTo(-8,-6,-16,-8,-22,0);ctx.bezierCurveTo(-15,-2,-11,12,-3,7);
  ctx.quadraticCurveTo(0,5,0,5);ctx.quadraticCurveTo(3,5,3,7);
  ctx.bezierCurveTo(11,12,15,-2,22,0);ctx.bezierCurveTo(16,-8,8,-6,0,3);ctx.closePath();ctx.fill();
  ctx.restore();
}
/** Draw animated visual sound clues without turning them into capture targets. */
function renderFalseNoises() {
  for (const d of decoys) {
    const strength = clamp(d.ttl / 2, 0, 1);
    const pulse = (now + d.wave) % 1.5 / 1.5;
    ctx.save();
    ctx.globalAlpha = strength * (1 - pulse * .75);
    ctx.strokeStyle = '#ffd685';
    ctx.lineWidth = 3;
    ctx.beginPath(); ctx.arc(d.x, d.y, 17 + pulse * 46, 0, Math.PI * 2); ctx.stroke();
    ctx.globalAlpha = strength * .85;
    ctx.fillStyle = '#ffe5a8';
    ctx.font = '800 19px "Noto Sans Arabic", Tahoma, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('تق!', d.x, d.y - 24);
    ctx.restore();
  }
}

/** Render a captured or fleeing character, hiding undiscovered NPCs. */
function renderActor(a) {
  if(a.state === 'hidden') {
    if (dist(player,a)<205) {
      const alpha = clamp((205-dist(player,a))/150,0,.75);
      ctx.save(); ctx.globalAlpha=alpha; ctx.fillStyle='#ffdd84';ctx.font='bold 30px Arial';ctx.textAlign='center';ctx.fillText('?',a.x,a.y-36);ctx.restore();
    }
    return;
  }
  ctx.save();
  ctx.fillStyle='#0005';ctx.beginPath();ctx.ellipse(a.x,a.y+3,27,10,0,0,Math.PI*2);ctx.fill();
  const img=spriteImages[a.id];
  if (img && img.complete && img.naturalWidth) {
    const displayH=86, displayW=displayH*a.width/a.height;
    const frame=a.state==='captured'?3:a.state==='fleeing'&&Math.sin(a.wave*2)>.85?2:0;
    ctx.save(); ctx.translate(a.x,a.y);
    if(a.dir===-1) ctx.scale(-1,1);
    ctx.drawImage(img,frame*a.width,0,a.width,a.height,-displayW/2,-displayH,displayW,displayH);
    ctx.restore();
  } else {
    roundedRect(a.x-19,a.y-72,38,67,12,a.color);
    ctx.fillStyle='#151826';ctx.fillRect(a.x-13,a.y-60,26,6);
  }
  if(a.state==='captured') {
    const face=lip(a);drawMustache(face.x,face.y, .75, 0, '#1c1326');
    ctx.fillStyle='#ffe78a';ctx.font='900 19px Arial';ctx.textAlign='center';ctx.fillText('✓',a.x+26,a.y-83);
  } else {
    ctx.fillStyle='#ffdf89';ctx.textAlign='center';ctx.font='900 20px Arial';
    ctx.fillText('!',a.x,a.y-99+Math.sin(a.wave)*3);
  }
  ctx.restore();
}
function renderPlayer() {
  ctx.save(); ctx.translate(player.x, player.y);
  ctx.fillStyle = '#0008'; ctx.beginPath(); ctx.ellipse(4,9,29,13,0,0,Math.PI*2); ctx.fill();
  ctx.rotate(player.angle);
  // Cartoon boots, layered suit and a pink mustache launcher.
  ctx.fillStyle='#181b2e';ctx.beginPath();ctx.ellipse(-16,-12,9,6,-.2,0,Math.PI*2);
  ctx.ellipse(-16,12,9,6,.2,0,Math.PI*2);ctx.fill();
  ctx.fillStyle='#56718b';ctx.beginPath();ctx.arc(0,0,23,0,Math.PI*2);ctx.fill();
  ctx.strokeStyle='#adc6c2';ctx.lineWidth=3;ctx.beginPath();ctx.arc(0,0,18,0,Math.PI*2);ctx.stroke();
  ctx.fillStyle='#f1d09f';ctx.beginPath();ctx.arc(2,0,14,0,Math.PI*2);ctx.fill();
  ctx.fillStyle='#2b293b';ctx.beginPath();ctx.arc(-1,-6,2.5,0,Math.PI*2);
  ctx.arc(-1,6,2.5,0,Math.PI*2);ctx.fill();
  ctx.fillStyle='#edb8a3';ctx.beginPath();ctx.arc(7,0,3,0,Math.PI*2);ctx.fill();
  ctx.shadowBlur=10;ctx.shadowColor='#ff7fa7a0';
  roundedRect(11,-11,33,22,7,'#f46eab'); ctx.shadowBlur=0;
  roundedRect(18,-7,16,14,5,'#ffb4d2');
  roundedRect(40,-5,16,10,4,'#f5cf96');
  ctx.fillStyle='#f8e8cc';ctx.fillRect(50,-2,7,4);
  ctx.restore();
}
function renderLight() {
  const radius=250, x=player.x, y=player.y;
  const g=ctx.createRadialGradient(x,y,25,x,y,radius);
  g.addColorStop(0,'#ffe9b41a');g.addColorStop(1,'#ffe9b400');
  ctx.fillStyle=g;ctx.fillRect(x-radius,y-radius,radius*2,radius*2);
}
/** Draw the scene in world and screen space, including decoy effects. */
function renderFrame() {
  updateCamera();
  ctx.setTransform(pixelRatio,0,0,pixelRatio,0,0);ctx.clearRect(0,0,w,h);
  ctx.translate(w/2-camera.x,h/2-camera.y);
  renderHouse();
  renderLight();
  renderFalseNoises();
  const sorted=actors.slice().sort((a,b)=>a.y-b.y);
  for (const a of sorted) renderActor(a);
  renderPlayer();
  for(const p of projectiles) {ctx.fillStyle='#ffaccc';ctx.beginPath();ctx.arc(p.x,p.y,6,0,Math.PI*2);ctx.fill();drawMustache(p.x,p.y, .55,Math.atan2(p.vy,p.vx),'#251728');}
  for (const p of effects) {ctx.globalAlpha=clamp(p.ttl/.65,0,1);ctx.fillStyle=p.color;ctx.fillRect(p.x,p.y,p.size,p.size);}ctx.globalAlpha=1;
  if(pointer.active && phase==='playing' && matchMedia('(pointer:fine)').matches) {
    const target=screenToWorld(pointer.x,pointer.y);
    ctx.strokeStyle='#ffe6a9';ctx.lineWidth=2;ctx.beginPath();
    ctx.arc(target.x,target.y,13,0,Math.PI*2);
    ctx.moveTo(target.x-20,target.y);ctx.lineTo(target.x-8,target.y);
    ctx.moveTo(target.x+8,target.y);ctx.lineTo(target.x+20,target.y);
    ctx.moveTo(target.x,target.y-20);ctx.lineTo(target.x,target.y-8);
    ctx.moveTo(target.x,target.y+8);ctx.lineTo(target.x,target.y+20);ctx.stroke();
  }
  // Fixed-camera vignette is drawn in screen space rather than world coordinates.
  ctx.setTransform(pixelRatio,0,0,pixelRatio,0,0);
  const shade=ctx.createRadialGradient(w/2,h/2,Math.min(w,h)*.15,w/2,h/2,Math.max(w,h)*.75);
  shade.addColorStop(0,'#10132000');shade.addColorStop(1,'#090c1b7f');
  ctx.fillStyle=shade;ctx.fillRect(0,0,w,h);
}
function frame(timestamp) {
  const dt=Math.min((timestamp-lastFrame)/1000 || 0,.045); lastFrame=timestamp; now=timestamp/1000;
  if(phase==='playing') simulate(dt);
  renderFrame();
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

const joyZone=$('joyZone'), joyKnob=$('joyKnob');
function setJoy(e) {
  const rect=joyZone.getBoundingClientRect();
  const dx=e.clientX-(rect.left+rect.width/2),dy=e.clientY-(rect.top+rect.height/2), len=Math.max(1,Math.hypot(dx,dy));
  const scale=Math.min(1, len/42), nx=dx/len*scale, ny=dy/len*scale;
  joystick.x=nx;joystick.y=ny;
  joyKnob.style.transform='translate('+(nx*31)+'px,'+(ny*31)+'px)';
}
joyZone.addEventListener('pointerdown',e=>{e.preventDefault();joystick.id=e.pointerId;joyZone.setPointerCapture(e.pointerId);setJoy(e);});
joyZone.addEventListener('pointermove',e=>{if(e.pointerId===joystick.id)setJoy(e);});
function stopJoy(e){if(e.pointerId!==joystick.id)return;joystick.id=null;joystick.x=joystick.y=0;joyKnob.style.transform='translate(0,0)';}
joyZone.addEventListener('pointerup',stopJoy);joyZone.addEventListener('pointercancel',stopJoy);
