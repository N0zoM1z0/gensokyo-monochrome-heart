const canvas = document.querySelector('#game');
const ctx = canvas.getContext('2d', { alpha: false });
ctx.imageSmoothingEnabled = false;

const state = { profile: 'A', region: 'shrine', actor: 'reimu', action: 'idle', language: 'en', anchors: false };
const defaults = { A: 'shrine', B: 'mansion', C: 'shrine', D: 'eientei' };
const baseline = { shrine: 140, mansion: 120, eientei: 143 };
const images = {};
let startedAt = performance.now();

const sources = {
  shrine: 'background_shrine.png', mansion: 'background_mansion.png', eientei: 'background_eientei.png',
  reimu: '../assets/sprites/reimu_m_sheet.png', marisa: '../assets/sprites/marisa_m_sheet.png', sakuya: '../assets/sprites/sakuya_m_sheet.png',
  reimuInv: '../assets/sprites/reimu_m_sheet_inverted.png', marisaInv: '../assets/sprites/marisa_m_sheet_inverted.png', sakuyaInv: '../assets/sprites/sakuya_m_sheet_inverted.png',
};

function loadImages() {
  return Promise.all(Object.entries(sources).map(([key, src]) => new Promise((resolve, reject) => {
    const image = new Image(); image.onload = () => { images[key] = image; resolve(); }; image.onerror = reject; image.src = src;
  })));
}

function colors() {
  const dark = state.profile === 'D';
  return { fg: dark ? '#fff' : '#000', bg: dark ? '#000' : '#fff' };
}

function panel(x, y, w, h, profile = state.profile) {
  const { fg, bg } = colors();
  ctx.fillStyle = bg; ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = fg; ctx.lineWidth = (profile === 'A' || profile === 'D') ? 2 : 1; ctx.strokeRect(x + .5, y + .5, w - 1, h - 1);
  if (profile === 'B') {
    ctx.strokeRect(x + 3.5, y + 3.5, w - 7, h - 7);
    ctx.fillStyle = fg; ctx.fillRect(x, y, 4, 4); ctx.fillRect(x + w - 4, y, 4, 4); ctx.fillRect(x, y + h - 4, 4, 4); ctx.fillRect(x + w - 4, y + h - 4, 4, 4);
  }
  if (profile === 'C') {
    ctx.fillStyle = bg; ctx.fillRect(x + w - 8, y, 8, 2); ctx.strokeStyle = fg; ctx.beginPath(); ctx.moveTo(x + w - 8, y); ctx.lineTo(x + w - 1, y + 7); ctx.lineTo(x + w - 1, y); ctx.stroke();
  }
}

function text(value, x, y, size = 8, inverse = false) {
  const { fg, bg } = colors();
  ctx.font = `${size}px DotGothic, monospace`;
  ctx.textBaseline = 'top';
  ctx.fillStyle = inverse ? bg : fg;
  ctx.fillText(value, x, y);
}

function pseudoLines(x, y, widths, step = 7) {
  const { fg } = colors(); ctx.fillStyle = fg;
  widths.forEach((w, i) => ctx.fillRect(x, y + i * step, w, 2));
}

function drawUi() {
  const { fg, bg } = colors();
  const en = state.language === 'en';
  if (state.profile === 'A') {
    panel(4, 4, 312, 16);
    text(en ? `${state.region.toUpperCase()} / DUSK` : state.region === 'shrine' ? '博麗神社・夕暮' : state.region === 'mansion' ? '紅魔館・夜' : '永遠亭・月夜', 9, 7, en ? 7 : 9);
    panel(4, 124, 312, 52);
    text(state.actor.toUpperCase(), 12, 130, 7);
    text(en ? 'THE EMPTY PLACE IS STILL WARM.' : state.actor === 'reimu' ? 'まだ、あたたかいわ。' : state.actor === 'marisa' ? '証拠ってやつだぜ。' : '一分だけ、残しました。', 12, 140, en ? 7 : 9);
    panel(171, 150, 136, 18); text(en ? '> PATIENT  LEAVE IT OPEN' : '> 待つ　席を空けておく', 177, 154, en ? 6 : 8);
  } else if (state.profile === 'B') {
    panel(3, 3, 314, 23);
    text(en ? 'THREAD / CLOCK / MEMORY' : '糸・時計・記憶', 10, 8, en ? 7 : 9);
    for (let i = 0; i < 8; i += 1) { ctx.strokeStyle = fg; ctx.strokeRect(182 + i * 13, 9, 8, 8); }
    panel(4, 124, 312, 52);
    panel(8, 128, 52, 44); pseudoLines(68, 132, [126, 109, 142], 8);
    panel(201, 130, 106, 37); pseudoLines(210, 137, [82, 73, 61], 8);
    text(en ? state.actor.toUpperCase() : state.actor === 'reimu' ? '霊夢' : state.actor === 'marisa' ? '魔理沙' : '咲夜', 12, 132, en ? 7 : 10);
  } else if (state.profile === 'C') {
    ctx.fillStyle = fg; for (let i = 0; i < 34; i += 1) if (i % 3 === 0) ctx.fillRect(6 + i * 9, 6 + (i % 5), 5, 1);
    panel(4, 113, 194, 63);
    text(en ? state.actor.toUpperCase() : state.actor === 'reimu' ? '霊夢' : state.actor === 'marisa' ? '魔理沙' : '咲夜', 12, 120, en ? 7 : 10);
    text(en ? 'LET ONE PETAL LAND.' : '花びらを一枚、待つ。', 12, 133, en ? 7 : 9);
    pseudoLines(12, 149, [155, 126], 7);
    ['DIRECT', 'PLAYFUL', 'PATIENT'].forEach((label, i) => { panel(205, 112 + i * 21, 111, 18); text(en ? label : ['直截','戯れ','静観'][i], 212, 117 + i * 21, en ? 6 : 8); });
  } else {
    panel(3, 3, 314, 17);
    for (let i = 0; i < 5; i += 1) { ctx.fillStyle = fg; ctx.beginPath(); ctx.arc(12 + i * 10, 11, 3, 0, Math.PI * 2); ctx.fill(); }
    ctx.strokeStyle = fg; ctx.strokeRect(74, 7, 53, 9); ctx.fillStyle = fg; ctx.fillRect(77, 9, 31, 5);
    panel(234, 28, 82, 66);
    text(en ? state.actor.toUpperCase() : state.actor === 'reimu' ? '霊夢' : state.actor === 'marisa' ? '魔理沙' : '咲夜', 241, 34, en ? 7 : 9);
    pseudoLines(241, 47, [60, 53, 61, 40], 8);
    panel(3, 157, 314, 19); text(en ? 'HOLD FOCUS / SHOT / BOMB' : '低速・射撃・ボム', 11, 162, en ? 7 : 9);
    for (let i = 0; i < 6; i += 1) { ctx.strokeStyle = fg; ctx.strokeRect(184 + i * 20, 162, 9, 9); }
  }
}

function spriteFrame(now) {
  const actionStart = state.action === 'idle' ? 0 : state.action === 'walk' ? 4 : 12;
  const count = state.action === 'walk' ? 8 : 4;
  const duration = state.action === 'walk' ? 90 : state.action === 'idle' ? 160 : 140;
  return actionStart + (Math.floor((now - startedAt) / duration) % count);
}

function drawActor(now) {
  const dark = state.profile === 'D' || state.region !== 'shrine';
  const key = dark ? `${state.actor}Inv` : state.actor;
  const frame = spriteFrame(now);
  const x = state.profile === 'D' ? 72 : 83;
  const y = baseline[state.region] - 32;
  ctx.drawImage(images[key], frame * 24, 0, 24, 32, x, y, 24, 32);
  const companion = state.actor === 'reimu' ? 'marisa' : 'reimu';
  const companionKey = dark ? `${companion}Inv` : companion;
  ctx.drawImage(images[companionKey], 0, 0, 24, 32, 205, y, 24, 32);

  if (state.action === 'walk') {
    const drift = ((now - startedAt) / 1000) % 2;
    // A tiny dotted travel line confirms that the 8-frame loop is locomotion.
    const { fg } = colors(); ctx.fillStyle = fg;
    for (let i = 0; i < 5; i += 1) ctx.fillRect(116 + i * 10 + (drift > 1 ? 2 : 0), baseline[state.region] - 2, 4, 1);
  }

  if (state.anchors) {
    const { fg, bg } = colors();
    [[x + 12, y + 31], [x + 12, y + 22], [x + 19, y + 16]].forEach(([ax, ay], index) => {
      ctx.fillStyle = bg; ctx.fillRect(ax - 2, ay - 2, 5, 5); ctx.strokeStyle = fg; ctx.strokeRect(ax - 1.5, ay - 1.5, 4, 4); text(String(index + 1), ax + 4, ay - 3, 5);
    });
  }
}

function threshold() {
  const data = ctx.getImageData(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < data.data.length; i += 4) {
    const lum = data.data[i] * .299 + data.data[i + 1] * .587 + data.data[i + 2] * .114;
    const value = lum >= 128 ? 255 : 0;
    data.data[i] = value; data.data[i + 1] = value; data.data[i + 2] = value; data.data[i + 3] = 255;
  }
  ctx.putImageData(data, 0, 0);
}

function render(now) {
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(images[state.region], 0, 0);
  drawActor(now);
  drawUi();
  threshold();
  document.querySelector('#readout').textContent = `${state.profile} / ${state.region.toUpperCase()} / ${state.actor.toUpperCase()} / ${state.action.toUpperCase()} / ${state.language.toUpperCase()}`;
  requestAnimationFrame(render);
}

document.querySelectorAll('button[data-group]').forEach((button) => {
  button.addEventListener('click', () => {
    const group = button.dataset.group;
    state[group] = button.dataset.value;
    if (group === 'profile') {
      state.region = defaults[state.profile];
      document.querySelectorAll('button[data-group="region"]').forEach((b) => b.classList.toggle('active', b.dataset.value === state.region));
    }
    document.querySelectorAll(`button[data-group="${group}"]`).forEach((b) => b.classList.toggle('active', b === button));
    startedAt = performance.now();
  });
});
document.querySelector('#anchors').addEventListener('change', (event) => { state.anchors = event.target.checked; });

Promise.all([loadImages(), document.fonts.ready]).then(() => {
  window.demoReady = true;
  requestAnimationFrame(render);
});
