const fs = require('fs');
const { PNG } = require('pngjs');

const BLACK = [0, 0, 0, 255];
const WHITE = [255, 255, 255, 255];
const CLEAR = [0, 0, 0, 0];

const FONT_5X7 = {
  ' ': ['00000','00000','00000','00000','00000','00000','00000'],
  'A': ['01110','10001','10001','11111','10001','10001','10001'],
  'B': ['11110','10001','10001','11110','10001','10001','11110'],
  'C': ['01111','10000','10000','10000','10000','10000','01111'],
  'D': ['11110','10001','10001','10001','10001','10001','11110'],
  'E': ['11111','10000','10000','11110','10000','10000','11111'],
  'F': ['11111','10000','10000','11110','10000','10000','10000'],
  'G': ['01111','10000','10000','10111','10001','10001','01111'],
  'H': ['10001','10001','10001','11111','10001','10001','10001'],
  'I': ['11111','00100','00100','00100','00100','00100','11111'],
  'J': ['00111','00010','00010','00010','10010','10010','01100'],
  'K': ['10001','10010','10100','11000','10100','10010','10001'],
  'L': ['10000','10000','10000','10000','10000','10000','11111'],
  'M': ['10001','11011','10101','10101','10001','10001','10001'],
  'N': ['10001','11001','10101','10011','10001','10001','10001'],
  'O': ['01110','10001','10001','10001','10001','10001','01110'],
  'P': ['11110','10001','10001','11110','10000','10000','10000'],
  'Q': ['01110','10001','10001','10001','10101','10010','01101'],
  'R': ['11110','10001','10001','11110','10100','10010','10001'],
  'S': ['01111','10000','10000','01110','00001','00001','11110'],
  'T': ['11111','00100','00100','00100','00100','00100','00100'],
  'U': ['10001','10001','10001','10001','10001','10001','01110'],
  'V': ['10001','10001','10001','10001','10001','01010','00100'],
  'W': ['10001','10001','10001','10101','10101','11011','10001'],
  'X': ['10001','10001','01010','00100','01010','10001','10001'],
  'Y': ['10001','10001','01010','00100','00100','00100','00100'],
  'Z': ['11111','00001','00010','00100','01000','10000','11111'],
  '0': ['01110','10001','10011','10101','11001','10001','01110'],
  '1': ['00100','01100','00100','00100','00100','00100','01110'],
  '2': ['01110','10001','00001','00010','00100','01000','11111'],
  '3': ['11110','00001','00001','01110','00001','00001','11110'],
  '4': ['00010','00110','01010','10010','11111','00010','00010'],
  '5': ['11111','10000','10000','11110','00001','00001','11110'],
  '6': ['01110','10000','10000','11110','10001','10001','01110'],
  '7': ['11111','00001','00010','00100','01000','01000','01000'],
  '8': ['01110','10001','10001','01110','10001','10001','01110'],
  '9': ['01110','10001','10001','01111','00001','00001','01110'],
  ':': ['00000','00100','00100','00000','00100','00100','00000'],
  '.': ['00000','00000','00000','00000','00000','00110','00110'],
  ',': ['00000','00000','00000','00000','00110','00100','01000'],
  '-': ['00000','00000','00000','11111','00000','00000','00000'],
  '/': ['00001','00010','00010','00100','01000','01000','10000'],
  '+': ['00000','00100','00100','11111','00100','00100','00000'],
  '!': ['00100','00100','00100','00100','00100','00000','00100'],
  '?': ['01110','10001','00001','00010','00100','00000','00100'],
  '[': ['01110','01000','01000','01000','01000','01000','01110'],
  ']': ['01110','00010','00010','00010','00010','00010','01110'],
  '<': ['00010','00100','01000','10000','01000','00100','00010'],
  '>': ['01000','00100','00010','00001','00010','00100','01000'],
  '_': ['00000','00000','00000','00000','00000','00000','11111'],
  '=': ['00000','11111','00000','11111','00000','00000','00000'],
  '%': ['11001','11010','00100','01000','10110','00110','00000'],
  '(': ['00010','00100','01000','01000','01000','00100','00010'],
  ')': ['01000','00100','00010','00010','00010','00100','01000'],
  "'": ['00100','00100','00000','00000','00000','00000','00000'],
};

class PixelCanvas {
  constructor(width, height, background = CLEAR) {
    this.width = width;
    this.height = height;
    this.png = new PNG({ width, height, colorType: 6 });
    this.fill(background);
  }

  fill(color) {
    for (let y = 0; y < this.height; y += 1) {
      for (let x = 0; x < this.width; x += 1) this.set(x, y, color);
    }
  }

  set(x, y, color = BLACK) {
    x = Math.round(x);
    y = Math.round(y);
    if (x < 0 || y < 0 || x >= this.width || y >= this.height) return;
    const i = (y * this.width + x) * 4;
    this.png.data[i] = color[0];
    this.png.data[i + 1] = color[1];
    this.png.data[i + 2] = color[2];
    this.png.data[i + 3] = color[3];
  }

  get(x, y) {
    if (x < 0 || y < 0 || x >= this.width || y >= this.height) return CLEAR;
    const i = (y * this.width + x) * 4;
    return [this.png.data[i], this.png.data[i + 1], this.png.data[i + 2], this.png.data[i + 3]];
  }

  rect(x, y, w, h, color = BLACK) {
    for (let yy = y; yy < y + h; yy += 1) {
      for (let xx = x; xx < x + w; xx += 1) this.set(xx, yy, color);
    }
  }

  strokeRect(x, y, w, h, color = BLACK, thickness = 1) {
    this.rect(x, y, w, thickness, color);
    this.rect(x, y + h - thickness, w, thickness, color);
    this.rect(x, y, thickness, h, color);
    this.rect(x + w - thickness, y, thickness, h, color);
  }

  line(x0, y0, x1, y1, color = BLACK, thickness = 1) {
    x0 = Math.round(x0); y0 = Math.round(y0); x1 = Math.round(x1); y1 = Math.round(y1);
    const dx = Math.abs(x1 - x0);
    const sx = x0 < x1 ? 1 : -1;
    const dy = -Math.abs(y1 - y0);
    const sy = y0 < y1 ? 1 : -1;
    let err = dx + dy;
    while (true) {
      this.rect(x0 - Math.floor((thickness - 1) / 2), y0 - Math.floor((thickness - 1) / 2), thickness, thickness, color);
      if (x0 === x1 && y0 === y1) break;
      const e2 = 2 * err;
      if (e2 >= dy) { err += dy; x0 += sx; }
      if (e2 <= dx) { err += dx; y0 += sy; }
    }
  }

  poly(points, color = BLACK) {
    const ys = points.map((p) => p[1]);
    const minY = Math.floor(Math.min(...ys));
    const maxY = Math.ceil(Math.max(...ys));
    for (let y = minY; y <= maxY; y += 1) {
      const nodes = [];
      let j = points.length - 1;
      for (let i = 0; i < points.length; i += 1) {
        const pi = points[i]; const pj = points[j];
        if ((pi[1] < y && pj[1] >= y) || (pj[1] < y && pi[1] >= y)) {
          nodes.push(Math.round(pi[0] + ((y - pi[1]) / (pj[1] - pi[1])) * (pj[0] - pi[0])));
        }
        j = i;
      }
      nodes.sort((a, b) => a - b);
      for (let k = 0; k + 1 < nodes.length; k += 2) {
        this.rect(nodes[k], y, nodes[k + 1] - nodes[k] + 1, 1, color);
      }
    }
  }

  circle(cx, cy, radius, color = BLACK, fill = true) {
    for (let y = -radius; y <= radius; y += 1) {
      for (let x = -radius; x <= radius; x += 1) {
        const d = x * x + y * y;
        if ((fill && d <= radius * radius) || (!fill && d <= radius * radius && d >= (radius - 1) * (radius - 1))) {
          this.set(cx + x, cy + y, color);
        }
      }
    }
  }

  patternRect(x, y, w, h, level = 1, color = BLACK) {
    const bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];
    const thresholds = { 1: 4, 2: 8, 3: 12 };
    const limit = thresholds[level] || 8;
    for (let yy = y; yy < y + h; yy += 1) {
      for (let xx = x; xx < x + w; xx += 1) {
        if (bayer[((yy % 4) + 4) % 4][((xx % 4) + 4) % 4] < limit) this.set(xx, yy, color);
      }
    }
  }

  blit(source, dx, dy, sx = 0, sy = 0, sw = source.width, sh = source.height, invert = false) {
    for (let y = 0; y < sh; y += 1) {
      for (let x = 0; x < sw; x += 1) {
        const c = source.get(sx + x, sy + y);
        if (c[3] === 0) continue;
        const out = invert ? [255 - c[0], 255 - c[1], 255 - c[2], c[3]] : c;
        this.set(dx + x, dy + y, out);
      }
    }
  }

  drawText(text, x, y, scale = 1, color = BLACK, spacing = 1) {
    let cursor = x;
    for (const raw of String(text)) {
      const ch = raw.toUpperCase();
      const glyph = FONT_5X7[ch] || FONT_5X7['?'];
      for (let gy = 0; gy < 7; gy += 1) {
        for (let gx = 0; gx < 5; gx += 1) {
          if (glyph[gy][gx] === '1') this.rect(cursor + gx * scale, y + gy * scale, scale, scale, color);
        }
      }
      cursor += (5 + spacing) * scale;
    }
    return cursor;
  }

  write(filePath) {
    fs.mkdirSync(require('path').dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, PNG.sync.write(this.png, { colorType: 6 }));
  }

  writeScaled(filePath, scale) {
    const out = new PixelCanvas(this.width * scale, this.height * scale, CLEAR);
    for (let y = 0; y < this.height; y += 1) {
      for (let x = 0; x < this.width; x += 1) {
        const c = this.get(x, y);
        if (c[3] === 0) continue;
        out.rect(x * scale, y * scale, scale, scale, c);
      }
    }
    out.write(filePath);
  }
}

function outlinedRect(c, x, y, w, h, fill = WHITE, outline = BLACK, thickness = 1) {
  c.rect(x, y, w, h, outline);
  if (w > thickness * 2 && h > thickness * 2) c.rect(x + thickness, y + thickness, w - thickness * 2, h - thickness * 2, fill);
}

module.exports = { PixelCanvas, BLACK, WHITE, CLEAR, FONT_5X7, outlinedRect };
