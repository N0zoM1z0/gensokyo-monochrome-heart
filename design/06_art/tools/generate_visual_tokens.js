#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { PixelCanvas, BLACK, WHITE, CLEAR } = require('../visual_system_v2/source/pixel_core');

const ROOT = path.resolve(__dirname, '../..');
const catalog = JSON.parse(fs.readFileSync(path.join(ROOT,'06_art','characters','character_model_catalog.json'),'utf8')).characters;
const regionCatalog = JSON.parse(fs.readFileSync(path.join(ROOT,'06_art','regions','location_visual_catalog.json'),'utf8')).entries;
const TOKEN_DIR = path.join(ROOT,'06_art','characters','silhouette_tokens');
const STAMP_DIR = path.join(ROOT,'06_art','regions','stamps');
fs.mkdirSync(TOKEN_DIR,{recursive:true}); fs.mkdirSync(STAMP_DIR,{recursive:true});

function lineCurve(c,pts,color=BLACK){for(let i=0;i<pts.length-1;i++)c.line(pts[i][0],pts[i][1],pts[i+1][0],pts[i+1][1],color);}

function characterToken(ch){
  const c=new PixelCanvas(16,24,CLEAR);
  const text=`${ch.silhouette_lock} ${ch.primary_prop} ${ch.companion_or_fx_layer}`.toLowerCase();
  const longHair=/long hair|very long|vast hair|hair column|hair mass/.test(text);
  const small=/tiny body|small body|compact/.test(text);
  const dress=/dress|robe|kimono|skirt|apron/.test(text);
  const wide=/broad sleeve|wide sleeve|detached sleeve|layered robe/.test(text);
  // Companion/wing shapes go down first so the body remains the recognition center.
  if(/bat wing|wings|wing wedge|one heavy wing|single wing/.test(text)){c.poly([[4,9],[0,6],[1,14],[4,12]],BLACK);c.poly([[11,9],[15,6],[14,14],[11,12]],BLACK);}
  if(/crystal/.test(text)){for(const [x,y] of [[1,7],[0,12],[2,16],[14,7],[15,12],[13,16]])c.poly([[x,y-1],[Math.min(15,x+1),y],[x,y+2],[Math.max(0,x-1),y]],BLACK);}
  if(/nine.tail|tails|tail fan/.test(text)){for(let i=0;i<4;i++){c.line(4-i,13,Math.max(0,1-i%2),20-i,BLACK);c.line(11+i,13,Math.min(15,14+i%2),20-i,BLACK);}}
  if(/third.eye|cord/.test(text)){lineCurve(c,[[3,12],[1,15],[3,18]],BLACK);lineCurve(c,[[12,12],[14,15],[12,19]],BLACK);c.circle(8,13,1,BLACK);}
  if(/orb|planet|world layer|sun layer/.test(text)){c.circle(1,5,1,BLACK);c.circle(14,4,1,BLACK);}
  // Body and head.
  c.circle(8,6,small?2:3,BLACK,true);
  if(longHair){c.rect(4,6,8,10,BLACK);c.rect(3,11,2,8,BLACK);c.rect(11,11,2,8,BLACK);}
  if(dress)c.poly([[5,9],[11,9],[13,20],[3,20]],BLACK); else {c.rect(5,9,7,8,BLACK);c.rect(5,17,3,5,BLACK);c.rect(10,17,3,5,BLACK);}
  if(wide){c.poly([[5,10],[1,12],[2,16],[6,14]],BLACK);c.poly([[11,10],[15,12],[14,16],[10,14]],BLACK);} else {c.line(5,11,2,16,BLACK,2);c.line(11,11,14,16,BLACK,2);}
  // Head silhouette identifiers.
  if(/witch hat/.test(text)){c.poly([[2,5],[13,5],[8,0]],BLACK);c.rect(1,5,14,2,BLACK);}
  else if(/parasol/.test(text)){c.poly([[1,4],[8,0],[15,4]],BLACK);c.line(8,4,8,22,BLACK);}
  else if(/mob cap|cap|hat|tokin|nightcap|helmet|hood/.test(text)){c.poly([[4,5],[5,2],[11,2],[13,5]],BLACK);c.rect(3,5,10,2,BLACK);}
  if(/bow|ribbon/.test(text)){c.poly([[6,4],[1,1],[1,7]],BLACK);c.poly([[10,4],[15,1],[15,7]],BLACK);}
  if(/cat ears|wolf ears|rabbit ears|horse ears|komainu ears|fox ears|mouse ears/.test(text)){
    if(/rabbit ears/.test(text)){c.poly([[5,4],[4,0],[6,0],[7,4]],BLACK);c.poly([[9,4],[10,0],[12,0],[11,4]],BLACK);} else {c.poly([[4,4],[4,0],[7,3]],BLACK);c.poly([[10,3],[13,0],[13,5]],BLACK);}
  }
  if(/horn|antler/.test(text)){c.line(5,3,3,0,BLACK);c.line(11,3,13,0,BLACK);if(/single horn/.test(text))c.line(5,3,5,0,CLEAR);}
  if(/jester/.test(text)){c.line(5,3,2,0,BLACK);c.circle(2,0,1,BLACK);c.line(11,3,14,0,BLACK);c.circle(14,0,1,BLACK);}
  if(/frog.eye hat/.test(text)){c.circle(4,2,2,BLACK);c.circle(12,2,2,BLACK);c.rect(3,3,10,3,BLACK);}
  if(/halo|crown/.test(text)){c.line(4,2,12,2,BLACK);c.set(4,1,BLACK);c.set(8,0,BLACK);c.set(12,1,BLACK);}
  // Props are intentionally exaggerated at S scale.
  if(/broom/.test(text))c.line(1,22,15,7,BLACK,2);
  if(/gohei/.test(text)){c.line(14,8,14,21,BLACK);c.line(14,9,11,11,BLACK);c.line(14,13,11,15,BLACK);}
  if(/sword|blade|knife/.test(text)){c.line(14,8,14,22,BLACK);c.line(12,11,15,11,BLACK);}
  if(/scythe/.test(text)){c.line(14,7,14,22,BLACK);c.line(14,7,9,4,BLACK,2);}
  if(/staff|rod|onbashira|control rod/.test(text))c.rect(14,6,2,17,BLACK);
  if(/fan/.test(text))c.poly([[13,11],[15,7],[15,14]],BLACK);
  if(/book|grimoire|chronicle/.test(text)){c.strokeRect(0,11,5,6,BLACK);c.line(2,11,2,16,BLACK);}
  if(/camera|phone/.test(text)){c.strokeRect(12,10,4,5,BLACK);c.set(13,11,BLACK);}
  if(/vial|medicine/.test(text)){c.strokeRect(13,14,3,7,BLACK);c.rect(14,12,1,2,BLACK);}
  if(/umbrella/.test(text)){c.poly([[10,8],[15,8],[13,5]],BLACK);c.line(13,8,13,21,BLACK);}
  if(/anchor/.test(text)){c.line(14,8,14,20,BLACK);c.line(11,17,14,21,BLACK);c.line(14,21,15,17,BLACK);}
  if(/torch/.test(text)){c.line(14,8,14,21,BLACK);c.poly([[14,7],[12,4],[14,1],[15,5]],BLACK);}
  if(/gourd|sake bowl/.test(text))c.circle(1,15,2,BLACK);
  if(/mask/.test(text)){c.circle(1,5,2,BLACK,false);c.circle(15,9,2,BLACK,false);}
  if(/doll/.test(text)){c.circle(1,13,1,BLACK);c.rect(0,15,3,5,BLACK);}
  // White facial notch and feet separation preserve readability on black masses.
  c.rect(6,6,1,1,WHITE); c.rect(10,6,1,1,WHITE); c.set(8,8,WHITE);
  if(dress)c.rect(7,19,2,3,WHITE);
  return c;
}

function regionStamp(id){
  const c=new PixelCanvas(12,12,CLEAR); const I=BLACK,W=WHITE;
  const ring=()=>{c.circle(6,6,5,I,false);c.circle(6,6,1,I);};
  switch(id){
    case 'animal_realm_primate_garden': c.strokeRect(2,2,8,9,I);c.rect(3,1,6,2,I);c.set(4,5,I);c.set(8,5,I);c.line(4,8,8,8,I);break;
    case 'eientei_bamboo_forest': c.poly([[3,5],[2,0],[4,0],[5,5]],I);c.poly([[7,5],[8,0],[10,0],[9,5]],I);c.strokeRect(4,6,5,6,I);break;
    case 'forest_of_magic_kourindou': c.poly([[1,5],[6,1],[11,5]],I);c.rect(5,5,3,5,I);c.strokeRect(8,7,4,4,I);break;
    case 'former_hell_chireiden': ring();c.poly([[1,6],[6,3],[11,6],[6,9]],I);c.circle(6,6,1,W);break;
    case 'garden_sun_nameless_hill': for(let i=0;i<8;i++){const a=i*Math.PI/4;c.circle(Math.round(6+Math.cos(a)*4),Math.round(5+Math.sin(a)*4),1,I);}c.circle(6,5,2,I);c.line(6,7,6,11,I);break;
    case 'hakugyokurou': c.circle(4,5,3,I,false);c.rect(1,5,3,3,W);c.poly([[7,10],[11,3],[11,10]],I);break;
    case 'hakurei_shrine': c.rect(1,2,10,2,I);c.rect(2,4,2,7,I);c.rect(8,4,2,7,I);c.circle(6,7,2,I,false);break;
    case 'heaven': c.circle(6,4,3,I);c.rect(2,8,8,3,I);c.line(3,9,9,9,W);break;
    case 'hidden_back_doors': c.strokeRect(1,1,8,10,I,2);c.poly([[7,6],[11,2],[11,10]],I);break;
    case 'human_village': c.strokeRect(1,3,10,8,I);c.line(6,3,6,11,I);c.line(2,1,10,1,I,2);break;
    case 'lunar_capital_dream_world': c.circle(5,5,4,I);c.circle(7,4,3,W);c.line(1,10,11,10,I);c.set(4,8,I);c.set(8,8,I);break;
    case 'misty_lake': c.poly([[6,0],[8,4],[12,5],[8,7],[6,11],[4,7],[0,5],[4,4]],I);c.line(0,10,11,10,I);break;
    case 'moriya_shrine': c.circle(3,3,2,I,false);c.circle(9,3,2,I,false);c.rect(5,1,2,10,I);break;
    case 'myouren_temple': c.poly([[6,1],[8,5],[11,6],[8,7],[6,11],[4,7],[1,6],[4,5]],I);c.line(6,6,6,11,W);break;
    case 'outside_world_dream_theatre': c.strokeRect(2,1,8,10,I);c.circle(6,4,2,I);c.rect(4,8,4,1,I);break;
    case 'sanzu_higan': c.circle(3,6,3,I,false);c.rect(7,1,2,10,I);c.rect(6,2,4,1,I);break;
    case 'scarlet_devil_mansion': c.circle(4,6,3,I,false);c.line(4,6,4,4,I);c.line(4,6,6,7,I);c.poly([[7,5],[11,2],[10,6],[11,10],[7,7]],I);break;
    case 'senkai_mausoleum': c.circle(3,3,2,I,false);c.circle(9,3,2,I,false);c.circle(6,8,3,I,false);c.line(3,5,5,7,I);c.line(9,5,7,7,I);break;
    case 'youkai_mountain': c.poly([[1,11],[5,3],[7,8],[9,1],[11,11]],I);c.line(7,0,7,11,W);break;
    default:ring();
  }
  return c;
}

const tokenManifest=[];
for(const ch of catalog){const t=characterToken(ch);t.write(path.join(TOKEN_DIR,`${ch.id}_s_token.png`));tokenManifest.push({id:ch.id,tier:ch.production_tier,size:[16,24],status:'silhouette blockout; not final sprite'});}
const board=new PixelCanvas(768,360,WHITE);
catalog.forEach((ch,i)=>{const x=(i%8)*96,y=Math.floor(i/8)*40;const t=characterToken(ch);for(let py=0;py<24;py++)for(let px=0;px<16;px++){const p=t.get(px,py);if(p[3])board.rect(x+3+px*2,y+3+py*1,2,1,p);}board.drawText(ch.id.replace(/_.*/,'').slice(0,8),x+39,y+7,1,BLACK);board.drawText(`TIER ${ch.production_tier}`,x+39,y+19,1,BLACK);board.rect(x,y+31,92,1,BLACK);});
board.write(path.join(ROOT,'06_art','characters','silhouette_token_board_raw.png'));board.writeScaled(path.join(ROOT,'06_art','characters','silhouette_token_board_2x.png'),2);

const stampManifest=[]; const atlas=new PixelCanvas(12*8,12*3,CLEAR); const stampBoard=new PixelCanvas(640,150,WHITE);
regionCatalog.forEach((r,i)=>{const s=regionStamp(r.id);s.write(path.join(STAMP_DIR,`${r.id}_12.png`));atlas.blit(s,(i%8)*12,Math.floor(i/8)*12);const x=(i%5)*128,y=Math.floor(i/5)*36;stampBoard.strokeRect(x+2,y+2,28,28,BLACK);for(let py=0;py<12;py++)for(let px=0;px<12;px++){const p=s.get(px,py);if(p[3])stampBoard.rect(x+4+px*2,y+4+py*2,2,2,p);}stampBoard.drawText(r.id.split('_').slice(0,2).join('_').slice(0,14),x+34,y+9,1,BLACK);stampManifest.push({id:r.id,size:[12,12],description:r.stamp});});
atlas.write(path.join(ROOT,'06_art','regions','region_stamp_atlas_12.png'));stampBoard.write(path.join(ROOT,'06_art','regions','region_stamp_board_raw.png'));stampBoard.writeScaled(path.join(ROOT,'06_art','regions','region_stamp_board_2x.png'),2);
fs.writeFileSync(path.join(ROOT,'06_art','visual_token_manifest.json'),JSON.stringify({character_tokens:tokenManifest,region_stamps:stampManifest,warning:'Character tokens are recognition blockouts. Reimu/Marisa/Sakuya animation sheets are the production model reference.'},null,2)+'\n');
console.log(`Generated ${tokenManifest.length} character blockout tokens and ${stampManifest.length} region stamps.`);
