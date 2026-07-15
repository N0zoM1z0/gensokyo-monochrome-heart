const fs = require('fs');
const path = require('path');
const { PixelCanvas, BLACK, WHITE, CLEAR } = require('./pixel_core');
const { CHARACTER_META, FRAME_ORDER, makeFrame } = require('./characters');

const ROOT = path.resolve(__dirname, '..');
const TMP = '/tmp/gensokyo_monochrome_demo_frames';

function p(...parts) { return path.join(ROOT, ...parts); }
function ensure(filePath) { fs.mkdirSync(path.dirname(filePath), { recursive: true }); }
function saveJson(filePath, value) { ensure(filePath); fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`); }

function invertCanvas(source) {
  const out = new PixelCanvas(source.width, source.height, CLEAR);
  for (let y = 0; y < source.height; y += 1) {
    for (let x = 0; x < source.width; x += 1) {
      const c = source.get(x, y);
      if (!c[3]) continue;
      out.set(x, y, [255 - c[0], 255 - c[1], 255 - c[2], c[3]]);
    }
  }
  return out;
}

function saveSprites() {
  const spriteManifest = {
    format: 'RGBA PNG; visible pixels are #000000 or #FFFFFF; transparent background',
    model_s: { frame_size: [16, 24], purpose: 'map markers and crowds' },
    model_m: { frame_size: [24, 32], purpose: 'exploration and minigames' },
    model_l: { frame_size: [32, 48], purpose: 'dramatic and fighter prototype' },
    sheet_order: FRAME_ORDER,
    characters: CHARACTER_META,
  };

  for (const name of Object.keys(CHARACTER_META)) {
    const sheet = new PixelCanvas(24 * FRAME_ORDER.length, 32, CLEAR);
    FRAME_ORDER.forEach((entry, index) => sheet.blit(makeFrame(name, entry.action, entry.index, 'M'), index * 24, 0));
    sheet.write(p('assets', 'sprites', `${name}_m_sheet.png`));
    invertCanvas(sheet).write(p('assets', 'sprites', `${name}_m_sheet_inverted.png`));

    const sizeSheet = new PixelCanvas(16 + 8 + 24 + 8 + 32, 48, CLEAR);
    sizeSheet.blit(makeFrame(name, 'idle', 0, 'S'), 0, 24);
    sizeSheet.blit(makeFrame(name, 'idle', 0, 'M'), 24, 16);
    sizeSheet.blit(makeFrame(name, 'idle', 0, 'L'), 56, 0);
    sizeSheet.write(p('assets', 'sprites', `${name}_sml.png`));

    for (const action of ['idle', 'walk', 'talk']) {
      const count = action === 'walk' ? 8 : 4;
      for (let i = 0; i < count; i += 1) {
        const logical = new PixelCanvas(48, 48, WHITE);
        logical.patternRect(0, 36, 48, 12, 1, BLACK);
        logical.rect(0, 36, 48, 1, BLACK);
        logical.blit(makeFrame(name, action, i, 'M'), 12, 4);
        logical.drawText(action, 2, 1, 1, BLACK);
        logical.writeScaled(path.join(TMP, name, action, `${String(i).padStart(2, '0')}.png`), 4);
      }
    }
  }

  saveJson(p('assets', 'sprites', 'animation_manifest.json'), spriteManifest);
}

function modelSheet() {
  const c = new PixelCanvas(320, 180, WHITE);
  c.rect(0, 0, 320, 14, BLACK);
  c.drawText('CHARACTER MODEL LOCK / S M L + KEY POSES', 5, 4, 1, WHITE);
  const names = ['reimu', 'marisa', 'sakuya'];
  names.forEach((name, row) => {
    const y = 22 + row * 50;
    c.drawText(CHARACTER_META[name].label, 5, y + 4, 1, BLACK);
    c.drawText('S', 64, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'idle', 0, 'S'), 61, y + 17);
    c.drawText('M', 91, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'idle', 0, 'M'), 86, y + 9);
    c.drawText('L', 127, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'idle', 0, 'L'), 118, y - 1);
    c.drawText('IDLE', 160, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'idle', 2, 'M'), 165, y + 9);
    c.drawText('WALK', 204, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'walk', 2, 'M'), 210, y + 9);
    c.drawText('TALK', 250, y + 4, 1, BLACK);
    c.blit(makeFrame(name, 'talk', 2, 'M'), 256, y + 9);
    c.rect(0, y + 47, 320, 1, BLACK);
  });
  c.drawText('M FEET 12,31 / FOCUS 12,22 / GRID 24X32', 5, 174, 1, BLACK);
  c.write(p('assets', 'sprites', 'character_model_lock_raw.png'));
  c.writeScaled(p('preview', 'character_model_lock.png'), 4);
}

function animationOverview() {
  const c = new PixelCanvas(416, 128, WHITE);
  c.rect(0, 0, 416, 14, BLACK);
  c.drawText('4 IDLE / 8 WALK / 4 TALK / SHARED 24X32 FRAME', 5, 4, 1, WHITE);
  ['reimu', 'marisa', 'sakuya'].forEach((name, row) => {
    const y = 20 + row * 35;
    c.drawText(CHARACTER_META[name].label, 3, y + 12, 1, BLACK);
    FRAME_ORDER.forEach((entry, index) => {
      c.blit(makeFrame(name, entry.action, entry.index, 'M'), 70 + index * 21, y);
      if (index === 3 || index === 11) c.rect(70 + index * 21 + 20, y, 1, 32, BLACK);
    });
  });
  c.write(p('assets', 'sprites', 'animation_overview_raw.png'));
  c.writeScaled(p('preview', 'animation_overview.png'), 3);
}

function trioAnimationFrames() {
  for (const action of ['idle', 'walk', 'talk']) {
    const count = action === 'walk' ? 8 : 4;
    for (let i = 0; i < count; i += 1) {
      const c = new PixelCanvas(128, 48, WHITE);
      c.patternRect(0, 38, 128, 10, 1, BLACK);
      c.rect(0, 38, 128, 1, BLACK);
      c.drawText(action.toUpperCase(), 2, 2, 1, BLACK);
      ['reimu', 'marisa', 'sakuya'].forEach((name, index) => {
        c.blit(makeFrame(name, action, i, 'M'), 18 + index * 38, 6);
      });
      c.writeScaled(path.join(TMP, 'trio', action, `${String(i).padStart(2, '0')}.png`), 4);
    }
  }
}

function drawTile(region, index) {
  const c = new PixelCanvas(16, 16, WHITE);
  if (index === 0) return c;
  if (index === 1) { c.rect(0, 0, 16, 2, BLACK); c.patternRect(0, 3, 16, 13, 1, BLACK); return c; }
  if (index === 2) { c.rect(0, 0, 16, 2, BLACK); for (let y = 5; y < 16; y += 5) c.rect(0, y, 16, 1, BLACK); for (let x = 3; x < 16; x += 6) c.rect(x, 2, 1, 14, BLACK); return c; }
  if (index === 3) { c.rect(0, 0, 16, 2, BLACK); for (let y = 4; y < 16; y += 4) { c.rect(0, y, 16, 1, BLACK); for (let x = (y % 8 ? 2 : 0); x < 16; x += 6) c.rect(x, y, 1, 4, BLACK); } return c; }
  if (index === 4) { c.rect(0, 0, 2, 16, BLACK); c.rect(14, 0, 2, 16, BLACK); c.rect(0, 7, 16, 2, BLACK); return c; }
  if (index === 5) { for (let y = 0; y < 16; y += 4) { c.line(0, y + 3, 8, y, BLACK); c.line(8, y, 15, y + 3, BLACK); } return c; }
  if (index === 6) { c.strokeRect(1, 1, 14, 14, BLACK, 2); c.line(8, 2, 8, 13, BLACK); c.line(2, 8, 13, 8, BLACK); return c; }
  if (index === 7) { for (let y = 2; y < 16; y += 3) c.rect(2 + Math.floor(y / 3), y, 14 - Math.floor(y / 3), 2, BLACK); return c; }
  if (index === 8) { c.rect(5, 0, 6, 16, BLACK); c.rect(3, 0, 10, 2, BLACK); c.rect(3, 14, 10, 2, BLACK); c.rect(7, 2, 2, 12, WHITE); return c; }
  if (index === 9) { for (let x = 1; x < 16; x += 5) { c.rect(x, 0, 2, 16, BLACK); c.rect(x - 1, 5, 4, 1, BLACK); c.rect(x - 1, 11, 4, 1, BLACK); } return c; }
  if (index === 10) { c.circle(8, 8, 6, BLACK, false); c.circle(8, 8, 2, BLACK, true); return c; }
  if (index === 11) { c.rect(7, 2, 2, 12, BLACK); c.rect(2, 7, 12, 2, BLACK); c.rect(4, 4, 2, 2, BLACK); c.rect(10, 10, 2, 2, BLACK); return c; }
  if (index === 12) { c.strokeRect(2, 5, 12, 10, BLACK, 2); c.rect(2, 7, 12, 2, BLACK); c.rect(7, 9, 2, 2, BLACK); return c; }
  if (index === 13) { c.poly([[8, 1], [13, 8], [10, 14], [6, 14], [3, 8]], BLACK); c.poly([[8, 4], [10, 8], [8, 11], [6, 8]], WHITE); return c; }
  if (index === 14) { c.strokeRect(3, 2, 10, 13, BLACK); c.poly([[9, 2], [13, 2], [13, 6]], BLACK); c.rect(5, 7, 6, 1, BLACK); c.rect(5, 10, 5, 1, BLACK); return c; }
  if (index === 15) { c.circle(6, 8, 4, BLACK, false); c.circle(10, 8, 4, BLACK, false); c.rect(7, 7, 3, 3, WHITE); return c; }
  if (index === 16) { c.patternRect(0, 0, 16, 16, 1, BLACK); return c; }
  if (index === 17) { c.patternRect(0, 0, 16, 16, 2, BLACK); return c; }
  if (index === 18) { c.patternRect(0, 0, 16, 16, 3, BLACK); return c; }
  if (index === 19) { for (let x = -8; x < 20; x += 5) c.line(x, 0, x + 8, 15, BLACK); return c; }
  if (index === 20) { c.strokeRect(2, 2, 12, 12, BLACK); c.rect(8, 2, 6, 1, WHITE); c.rect(2, 8, 1, 6, WHITE); return c; }
  if (index === 21) { c.poly([[0, 16], [0, 8], [4, 5], [7, 10], [11, 4], [16, 7], [16, 16]], BLACK); return c; }
  if (index === 22) { c.poly([[1, 14], [4, 5], [7, 14], [10, 3], [15, 14]], BLACK); return c; }
  if (index === 23) { c.strokeRect(3, 1, 10, 15, BLACK, 2); c.rect(9, 8, 2, 2, BLACK); return c; }

  if (region === 'shrine') {
    if (index === 24) { c.rect(2, 1, 12, 14, BLACK); for (let x = 4; x < 13; x += 3) c.rect(x, 3, 1, 10, WHITE); c.circle(8, 8, 2, WHITE); return c; }
    if (index === 25) { c.rect(2, 2, 12, 3, BLACK); c.rect(4, 5, 3, 11, BLACK); c.rect(10, 5, 3, 11, BLACK); c.rect(1, 1, 14, 2, BLACK); return c; }
    if (index === 26) { c.line(0, 8, 15, 8, BLACK, 2); for (let x = 2; x < 15; x += 4) c.poly([[x, 9], [x + 2, 12], [x, 15]], BLACK); return c; }
    if (index === 27) { c.rect(6, 0, 5, 16, BLACK); c.line(6, 3, 2, 0, BLACK); c.line(10, 5, 15, 1, BLACK); c.line(6, 10, 1, 14, BLACK); c.rect(8, 0, 1, 16, WHITE); return c; }
    if (index === 28) { c.poly([[0, 6], [8, 0], [16, 6], [16, 10], [0, 10]], BLACK); c.rect(4, 10, 2, 6, BLACK); c.rect(10, 10, 2, 6, BLACK); return c; }
  }
  if (region === 'mansion') {
    if (index === 24) { c.rect(0, 0, 16, 16, BLACK); for (let y = 2; y < 15; y += 4) { c.rect(1, y, 14, 1, WHITE); for (let x = 2; x < 14; x += 3) c.rect(x, y + 1, 1, 3, WHITE); } return c; }
    if (index === 25) { c.strokeRect(2, 1, 12, 15, BLACK, 2); c.circle(8, 8, 4, BLACK, false); c.line(8, 8, 8, 4, BLACK); c.line(8, 8, 11, 9, BLACK); return c; }
    if (index === 26) { for (let y = 0; y < 16; y += 8) for (let x = 0; x < 16; x += 8) if ((x + y) % 16 === 0) c.rect(x, y, 8, 8, BLACK); return c; }
    if (index === 27) { c.poly([[2, 16], [2, 7], [8, 1], [14, 7], [14, 16]], BLACK); c.poly([[5, 16], [5, 8], [8, 5], [11, 8], [11, 16]], WHITE); return c; }
    if (index === 28) { c.rect(7, 6, 2, 10, BLACK); c.circle(8, 5, 3, BLACK, false); c.line(8, 2, 8, 0, BLACK); return c; }
  }
  if (region === 'eientei') {
    if (index === 24) { c.rect(6, 0, 4, 16, BLACK); c.rect(5, 4, 6, 1, WHITE); c.rect(5, 10, 6, 1, WHITE); c.line(5, 5, 1, 2, BLACK); c.line(10, 9, 15, 6, BLACK); return c; }
    if (index === 25) { c.circle(8, 8, 7, BLACK); c.circle(10, 6, 6, WHITE); return c; }
    if (index === 26) { for (let y = 0; y < 16; y += 4) c.rect(0, y, 16, 1, BLACK); for (let x = 0; x < 16; x += 8) c.rect(x, 0, 1, 16, BLACK); return c; }
    if (index === 27) { c.strokeRect(1, 1, 14, 14, BLACK, 2); for (let y = 4; y < 14; y += 4) c.rect(3, y, 10, 1, BLACK); for (let x = 5; x < 12; x += 4) c.rect(x, 2, 1, 12, BLACK); return c; }
    if (index === 28) { c.strokeRect(1, 1, 14, 14, BLACK); for (let y = 4; y < 14; y += 4) { c.rect(2, y, 12, 1, BLACK); c.rect(7, y + 1, 2, 2, BLACK); } return c; }
  }
  c.drawText(String(index % 10), 5, 5, 1, BLACK);
  return c;
}

function saveTiles() {
  const regions = ['shrine', 'mansion', 'eientei'];
  const overview = new PixelCanvas(432, 90, WHITE);
  regions.forEach((region, ri) => {
    const atlas = new PixelCanvas(128, 64, WHITE);
    for (let index = 0; index < 32; index += 1) atlas.blit(drawTile(region, index), (index % 8) * 16, Math.floor(index / 8) * 16);
    atlas.write(p('assets', 'tiles', `${region}_tiles_16.png`));
    overview.drawText(region.toUpperCase(), 8 + ri * 144, 2, 1, BLACK);
    overview.blit(atlas, 8 + ri * 144, 18);
  });
  overview.write(p('assets', 'tiles', 'tile_atlas_overview_raw.png'));
  overview.writeScaled(p('preview', 'tile_atlas_overview.png'), 3);
  saveJson(p('assets', 'tiles', 'tiles_manifest.json'), {
    tile_size: [16, 16], atlas_grid: [8, 4], format: '1-bit visible palette',
    rows: ['terrain and collision', 'architecture and structures', 'props and interaction', 'tone / weather / memory / region signatures'],
    regions,
    interactive_shape_language: { observe: '2x2 sparkle', carry: 'double lower handle', repair: 'three-segment crack', danger: 'alternating edge', memory: 'incomplete rectangle' },
  });
}

function drawBackground(region) {
  const c = new PixelCanvas(320, 180, WHITE);
  if (region === 'shrine') {
    c.patternRect(0, 18, 320, 55, 1, BLACK);
    for (let x = 0; x < 320; x += 32) c.line(x, 72, x + 24, 63, BLACK);
    c.poly([[46, 82], [160, 31], [274, 82], [260, 94], [60, 94]], BLACK);
    c.poly([[78, 78], [160, 44], [242, 78], [230, 82], [90, 82]], WHITE);
    c.rect(69, 82, 182, 57, BLACK);
    for (let x = 82; x < 244; x += 27) { c.rect(x, 91, 20, 43, WHITE); c.strokeRect(x, 91, 20, 43, BLACK); c.line(x + 10, 92, x + 10, 133, BLACK); c.line(x + 1, 112, x + 18, 112, BLACK); }
    c.rect(0, 139, 320, 3, BLACK);
    c.patternRect(0, 143, 320, 37, 1, BLACK);
    c.rect(145, 119, 30, 22, WHITE); c.strokeRect(145, 119, 30, 22, BLACK, 2); for (let x = 149; x < 173; x += 4) c.rect(x, 122, 2, 14, BLACK);
    c.rect(274, 54, 9, 87, BLACK); c.rect(278, 54, 2, 87, WHITE); c.line(278, 70, 301, 48, BLACK, 3); c.line(278, 84, 307, 72, BLACK, 3); c.line(278, 103, 301, 115, BLACK, 3);
    c.line(75, 101, 245, 101, BLACK, 2); for (let x = 90; x < 240; x += 19) c.poly([[x, 102], [x + 4, 108], [x, 113]], BLACK);
  } else if (region === 'mansion') {
    c.rect(0, 0, 320, 180, BLACK);
    for (let x = 5; x < 315; x += 48) {
      c.strokeRect(x, 12, 42, 108, WHITE, 2);
      for (let y = 20; y < 116; y += 13) { c.rect(x + 3, y, 36, 1, WHITE); for (let b = 0; b < 34; b += 5) c.rect(x + 4 + b, y + 2, 2 + (b % 3), 9, WHITE); }
    }
    c.poly([[118, 117], [118, 45], [160, 15], [202, 45], [202, 117]], WHITE);
    c.poly([[124, 117], [124, 49], [160, 23], [196, 49], [196, 117]], BLACK);
    c.line(160, 24, 160, 116, WHITE); c.line(125, 71, 195, 71, WHITE);
    c.circle(160, 54, 11, WHITE, false); c.line(160, 54, 160, 47, WHITE); c.line(160, 54, 166, 57, WHITE);
    for (let y = 121; y < 180; y += 12) for (let x = 0; x < 320; x += 12) if (((x + y) / 12) % 2 === 0) c.rect(x, y, 12, 12, WHITE);
    c.rect(0, 119, 320, 3, WHITE);
  } else {
    c.rect(0, 0, 320, 180, BLACK);
    c.circle(236, 48, 31, WHITE);
    c.circle(248, 40, 26, BLACK);
    for (let x = 8; x < 320; x += 24) {
      c.rect(x, 0, 7, 142, WHITE); c.rect(x + 2, 0, 2, 142, BLACK);
      for (let y = 18; y < 138; y += 25) c.rect(x - 2, y, 11, 2, BLACK);
      c.line(x, 32, x - 13, 24, WHITE); c.line(x + 6, 65, x + 19, 54, WHITE); c.line(x, 98, x - 15, 109, WHITE);
    }
    c.rect(0, 142, 320, 3, WHITE);
    for (let x = 0; x < 320; x += 5) c.line(x, 179, x + 6, 145, WHITE);
    c.strokeRect(35, 82, 76, 60, WHITE, 2); c.line(73, 84, 73, 140, WHITE); c.line(37, 112, 109, 112, WHITE);
  }
  return c;
}

function saveBackgrounds() {
  for (const region of ['shrine', 'mansion', 'eientei']) {
    const bg = drawBackground(region);
    bg.write(p('demo', `background_${region}.png`));
    bg.writeScaled(p('preview', `background_${region}.png`), 4);
  }
}

function drawDemoScreen(profile) {
  const region = profile === 'A' || profile === 'C' ? 'shrine' : profile === 'B' ? 'mansion' : 'eientei';
  const c = drawBackground(region);
  const dark = region !== 'shrine' || profile === 'D';
  const fg = dark ? WHITE : BLACK;
  const bg = dark ? BLACK : WHITE;
  const base = { shrine: 140, mansion: 120, eientei: 143 }[region];
  const lead = profile === 'B' ? 'sakuya' : profile === 'C' ? 'reimu' : profile === 'D' ? 'marisa' : 'reimu';
  const partner = lead === 'reimu' ? 'marisa' : 'reimu';
  c.blit(dark ? invertCanvas(makeFrame(lead, profile === 'D' ? 'walk' : 'talk', 2, 'M')) : makeFrame(lead, 'talk', 2, 'M'), 79, base - 32);
  c.blit(dark ? invertCanvas(makeFrame(partner, 'idle', 0, 'M')) : makeFrame(partner, 'idle', 0, 'M'), 211, base - 32);

  if (profile === 'A') {
    uiPanel(c, 4, 4, 312, 16, fg, bg, profile);
    c.drawText('HAKUREI SHRINE / DUSK', 9, 8, 1, fg);
    uiPanel(c, 4, 124, 312, 52, fg, bg, profile);
    c.drawText('REIMU', 12, 130, 1, fg);
    c.drawText('THE EMPTY PLACE IS STILL WARM.', 12, 141, 1, fg);
    uiPanel(c, 170, 151, 137, 17, fg, bg, profile);
    c.drawText('> PATIENT / KEEP OPEN', 176, 156, 1, fg);
  } else if (profile === 'B') {
    uiPanel(c, 3, 3, 314, 23, fg, bg, profile);
    c.drawText('THREAD / CLOCK / MEMORY', 10, 10, 1, fg);
    for (let i = 0; i < 8; i += 1) c.strokeRect(183 + i * 13, 9, 8, 8, fg);
    uiPanel(c, 4, 124, 312, 52, fg, bg, profile);
    c.drawText('SAKUYA', 12, 132, 1, fg);
    for (let y = 133; y < 158; y += 8) c.rect(68, y, 120 - ((y / 8) % 2) * 15, 2, fg);
    uiPanel(c, 202, 130, 105, 37, fg, bg, profile);
    for (let y = 138; y < 159; y += 8) c.rect(211, y, 80 - ((y / 8) % 2) * 12, 2, fg);
  } else if (profile === 'C') {
    uiPanel(c, 4, 112, 194, 64, fg, bg, profile);
    c.drawText('REIMU', 12, 120, 1, fg);
    c.drawText('LET ONE PETAL LAND.', 12, 134, 1, fg);
    for (let y = 149; y < 164; y += 7) c.rect(12, y, 155 - ((y / 7) % 2) * 28, 2, fg);
    for (let i = 0; i < 3; i += 1) {
      uiPanel(c, 205, 112 + i * 21, 111, 18, fg, bg, profile);
      c.drawText(['DIRECT', 'PLAYFUL', 'PATIENT'][i], 212, 118 + i * 21, 1, fg);
    }
  } else {
    uiPanel(c, 3, 3, 314, 17, fg, bg, profile);
    for (let i = 0; i < 5; i += 1) c.circle(12 + i * 10, 11, 3, fg);
    c.strokeRect(74, 7, 53, 9, fg); c.rect(77, 9, 31, 5, fg);
    uiPanel(c, 234, 28, 82, 66, fg, bg, profile);
    c.drawText('MARISA', 241, 35, 1, fg);
    for (let y = 49; y < 82; y += 8) c.rect(241, y, 60 - ((y / 8) % 2) * 10, 2, fg);
    uiPanel(c, 3, 157, 314, 19, fg, bg, profile);
    c.drawText('HOLD FOCUS / SHOT / BOMB', 11, 163, 1, fg);
    for (let i = 0; i < 6; i += 1) c.strokeRect(184 + i * 20, 162, 9, 9, fg);
  }
  return c;
}

function saveDemoScreens() {
  for (const profile of ['A', 'B', 'C', 'D']) {
    const c = drawDemoScreen(profile);
    c.write(p('preview', `demo_${profile}_raw.png`));
    c.writeScaled(p('preview', `demo_${profile}.png`), 4);
  }
}

function drawStamp(c, x, y, kind, fg, bg) {
  c.strokeRect(x, y, 13, 13, fg);
  if (kind === 0) { c.circle(x + 6, y + 6, 4, fg, false); c.circle(x + 6, y + 6, 1, fg); }
  if (kind === 1) { c.line(x + 3, y + 9, x + 9, y + 3, fg); c.line(x + 3, y + 3, x + 9, y + 9, fg); c.rect(x + 5, y + 5, 3, 3, bg); }
  if (kind === 2) { c.rect(x + 5, y + 2, 3, 9, fg); c.rect(x + 2, y + 5, 9, 3, fg); }
}

function uiPanel(c, x, y, w, h, fg, bg, profile) {
  c.rect(x, y, w, h, bg);
  const t = profile === 'A' || profile === 'D' ? 2 : 1;
  c.strokeRect(x, y, w, h, fg, t);
  if (profile === 'B') {
    c.strokeRect(x + 3, y + 3, w - 6, h - 6, fg);
    c.rect(x, y, 5, 5, fg); c.rect(x + w - 5, y, 5, 5, fg); c.rect(x, y + h - 5, 5, 5, fg); c.rect(x + w - 5, y + h - 5, 5, 5, fg);
  }
  if (profile === 'C') {
    c.rect(x + w - 8, y, 8, 1, bg); c.line(x + w - 8, y, x + w - 1, y + 7, fg); c.line(x + w - 1, y + 7, x + w - 1, y, fg);
  }
}

function drawUiSkin(c, ox, oy, profile) {
  const inverted = profile === 'D';
  const fg = inverted ? WHITE : BLACK;
  const bg = inverted ? BLACK : WHITE;
  c.rect(ox, oy, 320, 180, bg);
  c.drawText(profile, ox + 5, oy + 5, 2, fg);
  c.drawText(profile === 'A' ? 'POCKET SHRINE' : profile === 'B' ? 'PC98 DITHER' : profile === 'C' ? 'WOODBLOCK' : 'MIDNIGHT LCD', ox + 23, oy + 5, 1, fg);

  if (profile === 'D') {
    uiPanel(c, ox + 4, oy + 20, 312, 20, fg, bg, profile);
    for (let i = 0; i < 5; i += 1) c.circle(ox + 15 + i * 10, oy + 30, 3, fg);
    c.strokeRect(ox + 73, oy + 25, 50, 9, fg); c.rect(ox + 75, oy + 27, 31, 5, fg);
    uiPanel(c, ox + 230, oy + 48, 86, 83, fg, bg, profile);
    drawStamp(c, ox + 238, oy + 56, 0, fg, bg);
    for (let y = 58; y < 93; y += 10) c.rect(ox + 257, oy + y, 48 - ((y / 10) % 2) * 8, 2, fg);
    uiPanel(c, ox + 4, oy + 137, 312, 36, fg, bg, profile);
    for (let i = 0; i < 7; i += 1) drawStamp(c, ox + 12 + i * 43, oy + 148, i % 3, fg, bg);
  } else if (profile === 'C') {
    c.patternRect(ox + 4, oy + 21, 312, 72, 1, fg);
    uiPanel(c, ox + 4, oy + 96, 196, 77, fg, bg, profile);
    c.strokeRect(ox + 12, oy + 105, 52, 58, fg, 2);
    c.circle(ox + 38, oy + 129, 15, fg, false); c.rect(ox + 23, oy + 140, 30, 17, fg);
    for (let y = 108; y < 151; y += 10) c.rect(ox + 75, oy + y, 104 - ((y / 10) % 2) * 20, 2, fg);
    for (let i = 0; i < 3; i += 1) { uiPanel(c, ox + 206, oy + 96 + i * 26, 110, 22, fg, bg, profile); drawStamp(c, ox + 211, oy + 100 + i * 26, i, fg, bg); c.rect(ox + 230, oy + 105 + i * 26, 68, 2, fg); }
  } else {
    uiPanel(c, ox + 4, oy + 20, 312, 23, fg, bg, profile);
    c.drawText('TIME WEATHER', ox + 10, oy + 28, 1, fg);
    c.rect(ox + 104, oy + 29, 52, 3, fg);
    c.drawText('THREAD', ox + 206, oy + 28, 1, fg);
    c.patternRect(ox + 4, oy + 48, 312, 57, profile === 'B' ? 2 : 1, fg);
    uiPanel(c, ox + 4, oy + 110, 312, 63, fg, bg, profile);
    c.strokeRect(ox + 12, oy + 118, 44, 45, fg, 2);
    c.rect(ox + 19, oy + 128, 30, 28, fg);
    for (let y = 120; y < 148; y += 9) c.rect(ox + 66, oy + y, 108 - ((y / 9) % 2) * 20, 2, fg);
    uiPanel(c, ox + 184, oy + 118, 124, 45, fg, bg, profile);
    for (let i = 0; i < 3; i += 1) { c.rect(ox + 192, oy + 124 + i * 11, 4, 4, fg); c.rect(ox + 201, oy + 125 + i * 11, 86 - i * 9, 2, fg); }
  }
}

function saveUi() {
  const sheet = new PixelCanvas(640, 360, WHITE);
  drawUiSkin(sheet, 0, 0, 'A');
  drawUiSkin(sheet, 320, 0, 'B');
  drawUiSkin(sheet, 0, 180, 'C');
  drawUiSkin(sheet, 320, 180, 'D');
  sheet.write(p('assets', 'ui', 'ui_components_4skins_raw.png'));
  sheet.writeScaled(p('preview', 'ui_components_4skins.png'), 2);

  const tokens = {
    internal_resolution: [320, 180], safe_frame: 4, ui_grid: 4, tile_grid: 16,
    colors: ['#000000', '#FFFFFF'],
    components: {
      PaperPanel: { border: [1, 2], padding: 8 }, CharacterTag: { min: [44, 12], max_name_width: 72 },
      ToneChoice: { row_height: 12, min_target: 12 }, TimeWeatherChip: { height: 12 }, ObjectiveThread: { height: 12 },
      StampIcon: { sizes: [[9, 9], [13, 13]] }, Gauge: { min_height: 5 }, ContextPrompt: { height: 12 },
    },
    skins: {
      A: { usage: 'default exploration and ordinary dialogue', border: 2, dither: '0-25%', black_coverage: '25-35%' },
      B: { usage: 'dense interiors and key portraits', border: 1, dither: '25/50/75%', black_coverage: '40-50%' },
      C: { usage: 'chapter cards, intimacy, memory', border: 'irregular 1-3', portrait_overflow: 8, black_coverage: 'large alternating masses' },
      D: { usage: 'night combat, danmaku, dreams', polarity: 'inverted', dither: 'none behind bullets', black_coverage: '70-85%' },
    },
  };
  saveJson(p('assets', 'ui', 'ui_tokens.json'), tokens);
}

function latinFontSpecimen() {
  const c = new PixelCanvas(320, 180, WHITE);
  c.rect(0, 0, 320, 18, BLACK);
  c.drawText('KIRI 8 / LATIN 5X7 IN 8X8 CELL', 7, 6, 1, WHITE);
  c.drawText('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 7, 28, 1, BLACK);
  c.drawText('0123456789  : ! ? / + -', 7, 42, 1, BLACK);
  c.drawText('HAKUREI SHRINE / SCARLET MANSION', 7, 62, 1, BLACK);
  c.drawText('REIMU: THE SECOND CUP IS STILL WARM.', 7, 78, 1, BLACK);
  c.drawText('MARISA: THAT IS CALLED EVIDENCE.', 7, 92, 1, BLACK);
  c.strokeRect(6, 112, 308, 58, BLACK, 2);
  c.drawText('RULES', 14, 120, 1, BLACK);
  c.drawText('1 PX TRACKING / NO FAUX BOLD', 14, 134, 1, BLACK);
  c.drawText('EN 3 LINES / JP 12 PX CELL', 14, 148, 1, BLACK);
  c.write(p('assets', 'fonts', 'kiri8_latin_raw.png'));
  c.writeScaled(p('preview', 'kiri8_latin.png'), 4);

  const mix = new PixelCanvas(320, 180, WHITE);
  mix.rect(0, 0, 320, 20, BLACK);
  mix.drawText('FONT LOCK / KIRI 8 + JP 12', 7, 6, 1, WHITE);
  mix.drawText('HAKUREI SHRINE / SCARLET MANSION', 7, 28, 1, BLACK);
  mix.drawText('REIMU: THE SECOND CUP IS STILL WARM.', 7, 42, 1, BLACK);
  mix.rect(0, 148, 320, 32, BLACK);
  mix.drawText('NO FAUX BOLD / THRESHOLD TO 1 BIT', 7, 155, 1, WHITE);
  mix.drawText('EN 8 PX CELL / JP 12 PX CELL', 7, 168, 1, WHITE);
  mix.write(p('assets', 'fonts', 'font_specimen_base.png'));
}

function writeManifest() {
  const files = [];
  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else files.push(path.relative(ROOT, full).replaceAll(path.sep, '/'));
    }
  }
  walk(ROOT);
  saveJson(p('manifest.json'), { package: 'gensokyo_monochrome_visual_demo', version: '0.1.0', generated_at: new Date().toISOString(), files: files.sort() });
}

saveSprites();
modelSheet();
animationOverview();
trioAnimationFrames();
saveTiles();
saveBackgrounds();
saveDemoScreens();
saveUi();
latinFontSpecimen();
writeManifest();
console.log(`Generated ${ROOT}`);
