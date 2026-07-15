const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');
const { PNG } = require('pngjs');

const ROOT = path.resolve(__dirname, '..');
const checks = [];

function record(name, ok, detail) { checks.push({ name, ok, detail }); }
function full(relative) { return path.join(ROOT, relative); }

function checkFile(relative) {
  const ok = fs.existsSync(full(relative));
  record(`exists:${relative}`, ok, ok ? 'present' : 'missing');
  return ok;
}

function checkPng(relative, expectedSize, palette = true) {
  if (!checkFile(relative)) return;
  const png = PNG.sync.read(fs.readFileSync(full(relative)));
  const sizeOk = png.width === expectedSize[0] && png.height === expectedSize[1];
  record(`size:${relative}`, sizeOk, `${png.width}x${png.height}; expected ${expectedSize.join('x')}`);
  if (!palette) return;
  let badRgb = 0;
  let badAlpha = 0;
  for (let i = 0; i < png.data.length; i += 4) {
    const a = png.data[i + 3];
    if (a !== 0 && a !== 255) badAlpha += 1;
    if (a !== 0) {
      for (let k = 0; k < 3; k += 1) if (png.data[i + k] !== 0 && png.data[i + k] !== 255) badRgb += 1;
    }
  }
  record(`palette:${relative}`, badRgb === 0 && badAlpha === 0, `bad_rgb_channels=${badRgb}; bad_alpha_pixels=${badAlpha}`);
}

for (const name of ['reimu', 'marisa', 'sakuya']) {
  checkPng(`assets/sprites/${name}_m_sheet.png`, [384, 32]);
  checkPng(`assets/sprites/${name}_m_sheet_inverted.png`, [384, 32]);
  checkPng(`assets/sprites/${name}_sml.png`, [88, 48]);
}

for (const region of ['shrine', 'mansion', 'eientei']) {
  checkPng(`assets/tiles/${region}_tiles_16.png`, [128, 64]);
  checkPng(`demo/background_${region}.png`, [320, 180]);
}

checkPng('assets/ui/ui_components_4skins_raw.png', [640, 360]);
checkPng('assets/fonts/kiri8_latin_raw.png', [320, 180]);
checkPng('assets/fonts/font_specimen_raw.png', [320, 180]);
for (const profile of ['A', 'B', 'C', 'D']) checkPng(`preview/demo_${profile}_raw.png`, [320, 180]);

for (const relative of [
  'demo/index.html', 'demo/style.css', 'demo/demo.js',
  'assets/sprites/animation_manifest.json', 'assets/tiles/tiles_manifest.json', 'assets/ui/ui_tokens.json',
  'assets/fonts/DotGothic16-Japanese.woff2', 'assets/fonts/DotGothic16-Latin.woff2', 'assets/fonts/DotGothic16-LICENSE.txt',
  'README.md', 'ARTIFACT_INDEX.md', 'manifest.json',
]) checkFile(relative);

function checkGif(relative, expectedFrames) {
  if (!checkFile(relative)) return;
  try {
    const result = childProcess.execFileSync('identify', ['-format', '%n\n', full(relative)], { encoding: 'utf8' });
    const frames = Number.parseInt(result.trim().split(/\s+/)[0], 10);
    record(`frames:${relative}`, frames === expectedFrames, `${frames}; expected ${expectedFrames}`);
  } catch (error) {
    record(`frames:${relative}`, false, error.message);
  }
}

for (const name of ['reimu', 'marisa', 'sakuya']) {
  checkGif(`preview/${name}_idle.gif`, 4);
  checkGif(`preview/${name}_walk.gif`, 8);
  checkGif(`preview/${name}_talk.gif`, 4);
}
checkGif('preview/trio_idle.gif', 4);
checkGif('preview/trio_walk.gif', 8);
checkGif('preview/trio_talk.gif', 4);

const failed = checks.filter((check) => !check.ok);
const result = { status: failed.length ? 'failed' : 'passed', checks: checks.length, failures: failed.length, details: checks };
fs.writeFileSync(full('VALIDATION_REPORT.json'), `${JSON.stringify(result, null, 2)}\n`);

const lines = [
  '# Validation Report', '',
  `- Status: **${result.status.toUpperCase()}**`,
  `- Checks: ${result.checks}`,
  `- Failures: ${result.failures}`, '',
  '| Check | Result | Detail |', '|---|---|---|',
  ...checks.map((check) => `| \`${check.name}\` | ${check.ok ? 'PASS' : 'FAIL'} | ${String(check.detail).replaceAll('|', '\\|')} |`),
  '',
];
fs.writeFileSync(full('VALIDATION_REPORT.md'), lines.join('\n'));
console.log(`${result.status.toUpperCase()}: ${result.checks} checks, ${result.failures} failures`);
if (failed.length) process.exitCode = 1;
