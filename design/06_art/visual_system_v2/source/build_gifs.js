const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const { GIFEncoder, applyPalette } = require('./vendor/gifenc');

const ROOT = path.resolve(__dirname, '..');
const FRAME_ROOT = '/tmp/gensokyo_monochrome_demo_frames';
const PALETTE = [[0, 0, 0], [255, 255, 255]];

function encodeDirectory(inputDirectory, outputFile, delay) {
  const names = fs.readdirSync(inputDirectory).filter((name) => name.endsWith('.png')).sort();
  if (!names.length) throw new Error(`No PNG frames in ${inputDirectory}`);
  const frames = names.map((name) => PNG.sync.read(fs.readFileSync(path.join(inputDirectory, name))));
  const width = frames[0].width;
  const height = frames[0].height;
  if (frames.some((frame) => frame.width !== width || frame.height !== height)) throw new Error(`Mismatched frame size in ${inputDirectory}`);

  const gif = GIFEncoder();
  frames.forEach((frame, index) => {
    const indexed = applyPalette(frame.data, PALETTE);
    gif.writeFrame(indexed, width, height, { palette: index === 0 ? PALETTE : undefined, delay, repeat: 0 });
  });
  gif.finish();
  fs.writeFileSync(outputFile, gif.bytes());
}

for (const name of ['reimu', 'marisa', 'sakuya']) {
  for (const action of ['idle', 'walk', 'talk']) {
    const delay = action === 'walk' ? 90 : action === 'idle' ? 160 : 140;
    encodeDirectory(path.join(FRAME_ROOT, name, action), path.join(ROOT, 'preview', `${name}_${action}.gif`), delay);
  }
}
for (const action of ['idle', 'walk', 'talk']) {
  const delay = action === 'walk' ? 90 : action === 'idle' ? 160 : 140;
  encodeDirectory(path.join(FRAME_ROOT, 'trio', action), path.join(ROOT, 'preview', `trio_${action}.gif`), delay);
}
console.log('Built 12 GIF previews with gifenc.');
