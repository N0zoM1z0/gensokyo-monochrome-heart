const { PixelCanvas, BLACK, WHITE, CLEAR, outlinedRect } = require('./pixel_core');

const CHARACTER_META = {
  reimu: {
    label: 'REIMU',
    silhouette: 'oversized bow / detached sleeves / gohei',
    anchors: { feet_anchor: [12, 31], focus_anchor: [12, 22], hand_primary: [19, 16], hand_secondary: [5, 16], head_top: [12, 0] },
  },
  marisa: {
    label: 'MARISA',
    silhouette: 'witch hat / white apron cut / broom diagonal',
    anchors: { feet_anchor: [12, 31], focus_anchor: [12, 22], hand_primary: [18, 16], hand_secondary: [6, 16], head_top: [12, 0] },
  },
  sakuya: {
    label: 'SAKUYA',
    silhouette: 'maid headpiece / straight posture / knife or watch',
    anchors: { feet_anchor: [12, 31], focus_anchor: [12, 22], hand_primary: [18, 16], hand_secondary: [6, 16], head_top: [12, 1] },
  },
};

const FRAME_ORDER = [
  ...Array.from({ length: 4 }, (_, i) => ({ action: 'idle', index: i, duration: 160 })),
  ...Array.from({ length: 8 }, (_, i) => ({ action: 'walk', index: i, duration: 90 })),
  ...Array.from({ length: 4 }, (_, i) => ({ action: 'talk', index: i, duration: 140 })),
];

function pose(action, i) {
  if (action === 'idle') {
    return { bob: [0, 0, -1, 0][i % 4], stride: 0, arm: [0, 0, 1, 0][i % 4], mouth: 0 };
  }
  if (action === 'walk') {
    return {
      bob: [0, 1, 0, -1, 0, 1, 0, -1][i % 8],
      stride: [-2, -1, 0, 1, 2, 1, 0, -1][i % 8],
      arm: [1, 1, 0, -1, -1, -1, 0, 1][i % 8],
      mouth: 0,
    };
  }
  return { bob: 0, stride: 0, arm: [0, 1, 2, 1][i % 4], mouth: [0, 1, 1, 0][i % 4] };
}

function face(c, x, y, mouth = 0, eyeShift = 0) {
  c.set(x + 2 + eyeShift, y + 2, BLACK);
  c.set(x + 6 + eyeShift, y + 2, BLACK);
  c.set(x + 3, y + 5, BLACK);
  if (mouth) c.set(x + 4, y + 5, BLACK);
}

function drawReimuM(c, action, i) {
  const p = pose(action, i);
  const b = p.bob;
  const leftLeg = Math.max(-1, Math.min(1, p.stride));
  const rightLeg = -leftLeg;

  // Legs and shoes.
  outlinedRect(c, 7 + leftLeg, 26 + b, 4, 6, WHITE, BLACK);
  outlinedRect(c, 14 + rightLeg, 26 + b, 4, 6, WHITE, BLACK);
  c.rect(6 + leftLeg, 30 + b, 6, 2, BLACK);
  c.rect(13 + rightLeg, 30 + b, 6, 2, BLACK);

  // Skirt: black silhouette with a large white garment cut and patterned hem.
  c.poly([[5, 17 + b], [18, 17 + b], [22, 28 + b], [2, 28 + b]], BLACK);
  c.poly([[7, 19 + b], [16, 19 + b], [19, 26 + b], [5, 26 + b]], WHITE);
  for (let x = 5; x <= 18; x += 4) c.rect(x, 25 + b, 2, 1, BLACK);
  c.rect(9, 12 + b, 7, 8, BLACK);
  c.rect(11, 13 + b, 3, 3, WHITE);

  // Detached sleeves; talk pose lifts the primary hand.
  c.poly([[5, 12 + b], [8, 14 + b], [6, 22 + b], [1, 21 + b], [2, 14 + b]], BLACK);
  c.poly([[4, 14 + b], [6, 15 + b], [5, 20 + b], [3, 20 + b]], WHITE);
  const ry = action === 'talk' ? 12 + b - p.arm : 13 + b;
  c.poly([[16, 13 + b], [19, ry], [23, ry + 3], [21, ry + 8], [17, 20 + b]], BLACK);
  c.poly([[18, 14 + b], [20, ry + 2], [21, ry + 3], [20, ry + 6], [18, 18 + b]], WHITE);

  // Hair, face and bangs.
  c.poly([[6, 4 + b], [9, 2 + b], [16, 3 + b], [19, 6 + b], [18, 14 + b], [6, 14 + b]], BLACK);
  c.rect(8, 7 + b, 9, 6, WHITE);
  c.rect(8, 7 + b, 2, 2, BLACK);
  c.rect(12, 7 + b, 1, 2, BLACK);
  c.rect(16, 7 + b, 1, 2, BLACK);
  face(c, 8, 7 + b, p.mouth);

  // Oversized bow with negative-space cuts and one-frame accessory lag.
  const bowLag = action === 'idle' && i === 2 ? -1 : 0;
  c.poly([[8, 5 + b], [3, 1 + b + bowLag], [1, 2 + b + bowLag], [3, 8 + b], [8, 6 + b]], BLACK);
  c.poly([[15, 5 + b], [20, 1 + b - bowLag], [22, 2 + b - bowLag], [20, 8 + b], [15, 6 + b]], BLACK);
  c.rect(10, 2 + b, 4, 4, BLACK);
  c.set(4, 3 + b + bowLag, WHITE); c.set(19, 3 + b - bowLag, WHITE);

  // Gohei: strong vertical prop and three paper folds.
  const gx = action === 'talk' ? 22 : 21;
  c.line(gx, ry + 2, gx, 5 + b, BLACK);
  c.poly([[gx - 1, 7 + b], [gx - 4, 8 + b], [gx - 2, 10 + b], [gx - 5, 11 + b]], WHITE);
  c.line(gx - 1, 7 + b, gx - 4, 8 + b, BLACK);
  c.line(gx - 4, 8 + b, gx - 2, 10 + b, BLACK);
  c.line(gx - 2, 10 + b, gx - 5, 11 + b, BLACK);
}

function drawMarisaM(c, action, i) {
  const p = pose(action, i);
  const b = p.bob;
  const step = Math.max(-1, Math.min(1, p.stride));

  // Broom behind the body; diagonals identify her even at peripheral scale.
  const broomShift = action === 'walk' ? p.arm : 0;
  c.line(2, 30 + b, 22, 12 + b + broomShift, BLACK, 2);
  c.poly([[1, 26 + b], [5, 28 + b], [3, 32 + b], [0, 31 + b]], BLACK);

  outlinedRect(c, 7 + step, 26 + b, 4, 6, WHITE, BLACK);
  outlinedRect(c, 14 - step, 26 + b, 4, 6, WHITE, BLACK);
  c.rect(6 + step, 30 + b, 6, 2, BLACK);
  c.rect(13 - step, 30 + b, 6, 2, BLACK);

  // Black dress and strong white apron cut.
  c.poly([[6, 16 + b], [18, 16 + b], [21, 28 + b], [3, 28 + b]], BLACK);
  c.poly([[10, 17 + b], [15, 17 + b], [17, 26 + b], [7, 26 + b]], WHITE);
  c.rect(11, 18 + b, 3, 7, BLACK);
  c.rect(8, 12 + b, 9, 7, BLACK);
  c.rect(11, 13 + b, 3, 3, WHITE);

  // Arms and glove gesture.
  c.poly([[8, 13 + b], [5, 13 + b], [2, 19 + b], [5, 21 + b], [9, 17 + b]], BLACK);
  c.poly([[16, 13 + b], [19, 13 + b - p.arm], [22, 18 + b - p.arm], [19, 20 + b], [15, 17 + b]], BLACK);
  c.set(21, 17 + b - p.arm, WHITE);

  // Hair and face.
  c.poly([[7, 5 + b], [17, 5 + b], [19, 9 + b], [18, 15 + b], [6, 15 + b], [5, 9 + b]], BLACK);
  c.rect(8, 8 + b, 9, 6, WHITE);
  c.rect(8, 8 + b, 2, 2, BLACK); c.rect(12, 8 + b, 1, 2, BLACK); c.rect(16, 8 + b, 1, 2, BLACK);
  face(c, 8, 8 + b, p.mouth);
  c.set(6, 12 + b, WHITE); c.set(18, 12 + b, WHITE);

  // Hat with brim wider than the body, bent cone, and white band.
  const hatTilt = action === 'idle' && i === 2 ? 1 : 0;
  c.poly([[4, 6 + b], [8, 3 + b], [11, 0 + b], [14, 1 + b], [14, 3 + b], [20 + hatTilt, 4 + b], [18, 7 + b]], BLACK);
  c.poly([[8, 4 + b], [18, 4 + b], [17, 6 + b], [7, 6 + b]], WHITE);
  c.rect(2, 5 + b, 20, 3, BLACK);
  c.rect(6, 5 + b, 12, 1, WHITE);
}

function drawSakuyaM(c, action, i) {
  const p = pose(action, i);
  const b = p.bob;
  const step = Math.max(-1, Math.min(1, p.stride));

  outlinedRect(c, 8 + step, 26 + b, 3, 6, WHITE, BLACK);
  outlinedRect(c, 14 - step, 26 + b, 3, 6, WHITE, BLACK);
  c.rect(7 + step, 30 + b, 5, 2, BLACK);
  c.rect(13 - step, 30 + b, 5, 2, BLACK);

  // Precise triangular dress, apron, and straight center line.
  c.poly([[7, 16 + b], [17, 16 + b], [20, 28 + b], [4, 28 + b]], BLACK);
  c.poly([[10, 17 + b], [15, 17 + b], [16, 26 + b], [8, 26 + b]], WHITE);
  c.line(12, 17 + b, 12, 26 + b, BLACK);
  c.rect(8, 12 + b, 9, 6, BLACK);
  c.poly([[10, 12 + b], [14, 12 + b], [12, 15 + b]], WHITE);

  // Left arm checks the watch; right arm produces knives while talking.
  c.poly([[8, 13 + b], [5, 14 + b], [4, 19 + b], [7, 20 + b], [10, 16 + b]], BLACK);
  c.rect(5, 17 + b, 3, 2, WHITE);
  c.set(6, 17 + b, BLACK);
  const handY = 16 + b - (action === 'talk' ? p.arm : 0);
  c.poly([[16, 13 + b], [19, handY], [21, handY + 3], [19, handY + 5], [15, 17 + b]], BLACK);
  c.set(20, handY + 2, WHITE);
  if (action === 'talk' && p.arm > 0) {
    c.line(20, handY + 1, 23, handY - 2, BLACK);
    c.line(20, handY + 2, 23, handY + 1, BLACK);
    c.line(20, handY + 3, 23, handY + 4, BLACK);
  }

  // Short hair, white face, and symmetrical maid headpiece.
  c.poly([[6, 6 + b], [9, 3 + b], [16, 3 + b], [19, 7 + b], [18, 15 + b], [6, 15 + b]], BLACK);
  c.rect(8, 7 + b, 9, 6, WHITE);
  c.rect(8, 7 + b, 2, 2, BLACK); c.rect(12, 7 + b, 1, 2, BLACK); c.rect(16, 7 + b, 1, 2, BLACK);
  face(c, 8, 7 + b, p.mouth);
  c.rect(6, 2 + b, 13, 4, BLACK);
  c.rect(7, 3 + b, 11, 2, WHITE);
  c.set(7, 2 + b, WHITE); c.set(10, 1 + b, WHITE); c.set(13, 1 + b, WHITE); c.set(17, 2 + b, WHITE);
  c.set(9, 5 + b, WHITE); c.set(12, 5 + b, WHITE); c.set(15, 5 + b, WHITE);
}

function drawSmall(name, action, i) {
  const c = new PixelCanvas(16, 24, CLEAR);
  const p = pose(action, i);
  const b = p.bob;
  const step = action === 'walk' ? Math.sign(p.stride) : 0;
  c.rect(5 + step, 20 + b, 3, 4, BLACK);
  c.rect(10 - step, 20 + b, 3, 4, BLACK);
  c.poly([[4, 12 + b], [12, 12 + b], [15, 21 + b], [1, 21 + b]], BLACK);
  c.rect(6, 13 + b, 5, 6, WHITE);
  c.poly([[4, 4 + b], [6, 2 + b], [11, 2 + b], [13, 5 + b], [12, 12 + b], [4, 12 + b]], BLACK);
  c.rect(6, 6 + b, 5, 4, WHITE);
  c.set(7, 7 + b, BLACK); c.set(10, 7 + b, BLACK);
  if (name === 'reimu') {
    c.poly([[6, 4 + b], [1, 1 + b], [2, 7 + b]], BLACK);
    c.poly([[10, 4 + b], [15, 1 + b], [14, 7 + b]], BLACK);
    c.line(14, 14 + b, 15, 5 + b, BLACK);
  } else if (name === 'marisa') {
    c.poly([[4, 5 + b], [7, 0 + b], [12, 2 + b], [13, 5 + b]], BLACK);
    c.rect(1, 4 + b, 14, 2, BLACK);
    c.line(1, 23 + b, 15, 11 + b, BLACK);
    c.rect(7, 13 + b, 3, 6, WHITE);
  } else {
    c.poly([[4, 4 + b], [5, 1 + b], [7, 3 + b], [9, 0 + b], [11, 3 + b], [13, 1 + b], [13, 4 + b]], WHITE);
    c.line(4, 4 + b, 5, 1 + b, BLACK);
    c.line(5, 1 + b, 7, 3 + b, BLACK);
    c.line(7, 3 + b, 9, 0 + b, BLACK);
    c.line(9, 0 + b, 11, 3 + b, BLACK);
    c.line(11, 3 + b, 13, 1 + b, BLACK);
    c.line(13, 1 + b, 13, 4 + b, BLACK);
    c.line(13, 14 + b, 15, 11 + b, BLACK);
  }
  return c;
}

function scaleTo(source, width, height) {
  const out = new PixelCanvas(width, height, CLEAR);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const sx = Math.floor((x / width) * source.width);
      const sy = Math.floor((y / height) * source.height);
      const color = source.get(sx, sy);
      if (color[3]) out.set(x, y, color);
    }
  }
  return out;
}

function drawLarge(name, action, i) {
  // The dramatic-size prototype deliberately preserves anchors while adding
  // larger facial/hand clusters. Fighter production art will be hand-keyed.
  const base = makeFrame(name, action, i, 'M');
  const c = scaleTo(base, 32, 48);
  c.rect(13, 16, 2, 2, BLACK);
  c.rect(20, 16, 2, 2, BLACK);
  if (action === 'talk' && i % 4 > 0) c.rect(16, 21, 3, 1, BLACK);
  return c;
}

function makeFrame(name, action = 'idle', i = 0, size = 'M') {
  if (size === 'S') return drawSmall(name, action, i);
  if (size === 'L') return drawLarge(name, action, i);
  const c = new PixelCanvas(24, 32, CLEAR);
  if (name === 'reimu') drawReimuM(c, action, i);
  else if (name === 'marisa') drawMarisaM(c, action, i);
  else if (name === 'sakuya') drawSakuyaM(c, action, i);
  else throw new Error(`Unknown character: ${name}`);
  return c;
}

module.exports = { CHARACTER_META, FRAME_ORDER, makeFrame };
