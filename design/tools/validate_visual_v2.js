#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { PNG } = require('pngjs');
const ROOT = path.resolve(__dirname,'..');
const checks=[]; const errors=[];
const ok=(name,detail='')=>checks.push({name,detail,status:'PASS'});
const fail=(name,detail)=>{checks.push({name,detail,status:'FAIL'});errors.push(`${name}: ${detail}`);};
const readJson=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p),'utf8'));
const exists=(p,name=p)=>fs.existsSync(path.join(ROOT,p))?ok(name,p):fail(name,`missing ${p}`);

function validatePng(rel,w,h,allowAlpha=true){
  const abs=path.join(ROOT,rel);
  if(!fs.existsSync(abs)){fail(`PNG ${rel}`,'missing');return;}
  let png;try{png=PNG.sync.read(fs.readFileSync(abs));}catch(e){fail(`PNG ${rel}`,`decode: ${e.message}`);return;}
  if(png.width!==w||png.height!==h){fail(`PNG ${rel}`,`expected ${w}x${h}, got ${png.width}x${png.height}`);return;}
  const colors=new Set();let badAlpha=0,badRgb=0;
  for(let i=0;i<png.data.length;i+=4){const r=png.data[i],g=png.data[i+1],b=png.data[i+2],a=png.data[i+3];
    if(a!==0&&a!==255)badAlpha++;
    if(a){colors.add(`${r},${g},${b}`);if(!((r===0&&g===0&&b===0)||(r===255&&g===255&&b===255)))badRgb++;}
    if(!allowAlpha&&a!==255)badAlpha++;
  }
  if(badRgb||badAlpha)fail(`PNG ${rel}`,`bad RGB pixels=${badRgb}, bad alpha=${badAlpha}`);
  else ok(`PNG ${rel}`,`${w}x${h}; colors=${[...colors].join('|')}`);
}

let ui,components,characters,regions;
try{ui=readJson('05_ui_ux/screen_inventory.json');components=readJson('05_ui_ux/component_catalog.json').components;characters=readJson('06_art/characters/character_model_catalog.json').characters;regions=readJson('06_art/regions/location_visual_catalog.json').entries;ok('core JSON parse','UI/components/characters/regions');}catch(e){fail('core JSON parse',e.message);}

if(ui&&components){
  ui.count===40&&ui.screens.length===40?ok('screen count','40'):fail('screen count',`${ui.count}/${ui.screens.length}`);
  components.length===30?ok('component count','30'):fail('component count',`${components.length}`);
  const ids=new Set(components.map(x=>x.id));const unknown=ui.screens.flatMap(s=>s.components.filter(x=>!ids.has(x)).map(x=>`${s.id}:${x}`));
  unknown.length?fail('screen component refs',unknown.join(',')):ok('screen component refs',`${ui.screens.reduce((n,s)=>n+s.components.length,0)} refs`);
  new Set(ui.screens.map(s=>s.id)).size===40?ok('unique screen ids','40'):fail('unique screen ids','duplicates');
  new Set(ui.screens.map(s=>s.godot_scene)).size===40?ok('unique screen scenes','40'):fail('unique screen scenes','duplicates');
  for(const s of ui.screens){if(!s.states.length||!s.input||!s.localization||!s.acceptance)fail(`screen contract ${s.id}`,'incomplete');}
  if(!checks.some(x=>x.name.startsWith('screen contract')&&x.status==='FAIL'))ok('screen contracts complete','states/input/localization/acceptance');
}

const roster=readJson('04_characters/roster.json').characters;
if(characters){
  characters.length===71?ok('character catalog count','71'):fail('character catalog count',`${characters.length}`);
  const tier=Object.fromEntries(['A','B','C'].map(t=>[t,characters.filter(x=>x.production_tier===t).length]));
  tier.A===12&&tier.B===22&&tier.C===37?ok('character tier split',JSON.stringify(tier)):fail('character tier split',JSON.stringify(tier));
  const a=new Set(roster.map(x=>x.id)),b=new Set(characters.map(x=>x.id));const diff=[...a].filter(x=>!b.has(x)).concat([...b].filter(x=>!a.has(x)));
  diff.length?fail('roster/catalog ids',diff.join(',')):ok('roster/catalog ids','71 exact');
  for(const ch of characters){
    exists(`06_art/characters/briefs/${ch.id}.md`, `brief ${ch.id}`);
    validatePng(`06_art/characters/silhouette_tokens/${ch.id}_s_token.png`,16,24,true);
  }
}

const locationIds=fs.readdirSync(path.join(ROOT,'03_locations')).filter(x=>x.endsWith('.md')&&x!=='README.md').map(x=>path.basename(x,'.md')).sort();
if(regions){
  regions.length===19?ok('region catalog count','19'):fail('region catalog count',`${regions.length}`);
  const ids=regions.map(x=>x.id).sort();JSON.stringify(ids)===JSON.stringify(locationIds)?ok('region/location ids','19 exact'):fail('region/location ids','mismatch');
  for(const r of regions){exists(`06_art/regions/briefs/${r.id}.md`,`region brief ${r.id}`);validatePng(`06_art/regions/stamps/${r.id}_12.png`,12,12,true);}
}

const sampleManifest=readJson('05_ui_ux/samples/manifest.json');
sampleManifest.count===24&&sampleManifest.images.length===24?ok('UI sample count','24'):fail('UI sample count',`${sampleManifest.count}/${sampleManifest.images.length}`);
for(const s of sampleManifest.images){validatePng(`05_ui_ux/samples/${s.raw}`,320,180,false);validatePng(`05_ui_ux/samples/${s.preview}`,1280,720,false);}
validatePng('05_ui_ux/samples/complete_ui_sample_atlas_raw.png',660,612,false);
validatePng('05_ui_ux/samples/complete_ui_sample_atlas_2x.png',1320,1224,false);

const mockups=readJson('06_art/mockups/manifest.json').files;
mockups.length===7?ok('primary mockup count','7'):fail('primary mockup count',`${mockups.length}`);
for(const m of mockups)validatePng(`06_art/mockups/${m.file}`,m.size_px[0],m.size_px[1],false);

for(const n of ['reimu','marisa','sakuya']){
  validatePng(`06_art/visual_system_v2/assets/sprites/${n}_m_sheet.png`,384,32,true);
  validatePng(`06_art/visual_system_v2/assets/sprites/${n}_m_sheet_inverted.png`,384,32,true);
}
for(const n of ['shrine','mansion','eientei'])validatePng(`06_art/visual_system_v2/assets/tiles/${n}_tiles_16.png`,128,64,false);
for(const p of ['A','B','C','D'])exists(`06_art/visual_system_v2/assets/concepts/${p}_${{A:'pocket_shrine',B:'pc98_dither',C:'woodblock_adventure',D:'midnight_lcd'}[p]}.png`,`concept ${p}`);
exists('06_art/visual_system_v2/assets/fonts/DotGothic16-Japanese.woff2','Japanese font');
exists('06_art/visual_system_v2/assets/fonts/DotGothic16-Latin.woff2','Latin font');

const requiredDocs=['UI_ART_V2_HANDOFF.md','PACKAGE_V2_CHANGE_AUDIT.md','05_ui_ux/ui_system_v2.md','06_art/character_asset_contract_v2.md','06_art/region_asset_contract_v2.md','10_codex/UI_ART_IMPLEMENTATION_TASKBOOK_V2.md','10_codex/CODEX_UI_ART_BOOTSTRAP_PROMPT_V2.md'];
for(const d of requiredDocs)exists(d,`handoff ${d}`);

const files=[];function walk(dir){for(const name of fs.readdirSync(dir)){const p=path.join(dir,name),st=fs.statSync(p);if(st.isDirectory())walk(p);else files.push(p);}}walk(ROOT);
const empty=files.filter(p=>fs.statSync(p).size===0);empty.length?fail('non-empty package files',empty.map(p=>path.relative(ROOT,p)).join(',')):ok('non-empty package files',`${files.length}`);
const digest=crypto.createHash('sha256').update(checks.map(x=>`${x.status}:${x.name}:${x.detail}`).join('\n')).digest('hex');
const report={schema:'gensokyo-monochrome-visual-validation-v2',generated_utc:new Date().toISOString(),checks:checks.length,passed:checks.filter(x=>x.status==='PASS').length,failed:errors.length,digest,errors,results:checks};
fs.writeFileSync(path.join(ROOT,'VISUAL_V2_VALIDATION_REPORT.json'),JSON.stringify(report,null,2)+'\n');
let md=`# Visual v2 Validation Report\n\n- Checks: **${report.checks}**\n- Passed: **${report.passed}**\n- Failed: **${report.failed}**\n- Digest: \`${digest}\`\n\n`;
md+=errors.length?`## Errors\n\n${errors.map(x=>`- ${x}`).join('\n')}\n`:`## Result\n\n**PASS — all visual, catalog, palette, dimension and coverage checks passed.**\n`;
fs.writeFileSync(path.join(ROOT,'VISUAL_V2_VALIDATION_REPORT.md'),md);
console.log(`Visual v2 checks=${report.checks} passed=${report.passed} failed=${report.failed}`);
if(errors.length){for(const e of errors)console.error(`ERROR ${e}`);process.exit(1);}
