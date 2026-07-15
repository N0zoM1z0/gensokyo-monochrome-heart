#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { PixelCanvas, BLACK, WHITE, CLEAR } = require('../visual_system_v2/source/pixel_core');
const { makeFrame } = require('../visual_system_v2/source/characters');

const ROOT = path.resolve(__dirname, '../..');
const RAW = path.join(ROOT, '05_ui_ux', 'samples', 'raw_320x180');
const PREVIEW = path.join(ROOT, '05_ui_ux', 'samples', 'preview_4x');
fs.mkdirSync(RAW, { recursive: true });
fs.mkdirSync(PREVIEW, { recursive: true });

const profiles = {
  A: { fg: BLACK, bg: WHITE, name: 'POCKET SHRINE' },
  B: { fg: BLACK, bg: WHITE, name: 'PC98 DITHER' },
  C: { fg: BLACK, bg: WHITE, name: 'WOODBLOCK' },
  D: { fg: WHITE, bg: BLACK, name: 'MIDNIGHT LCD' }
};

function invert(src) {
  const out = new PixelCanvas(src.width, src.height, CLEAR);
  for (let y=0;y<src.height;y++) for (let x=0;x<src.width;x++) {
    const p=src.get(x,y); if (p[3]) out.set(x,y,[255-p[0],255-p[1],255-p[2],p[3]]);
  }
  return out;
}

function blitScale(c, src, dx, dy, scale=1, inv=false) {
  const s = inv ? invert(src) : src;
  for (let y=0;y<s.height;y++) for (let x=0;x<s.width;x++) {
    const p=s.get(x,y); if (p[3]) c.rect(dx+x*scale,dy+y*scale,scale,scale,p);
  }
}

function panel(c,x,y,w,h,p='A',filled=true) {
  const {fg,bg}=profiles[p];
  if (filled) c.rect(x,y,w,h,bg);
  const t=(p==='A'||p==='D')?2:1;
  c.strokeRect(x,y,w,h,fg,t);
  if (p==='B' && w>12 && h>12) {
    c.strokeRect(x+3,y+3,w-6,h-6,fg);
    c.rect(x,y,4,4,fg); c.rect(x+w-4,y,4,4,fg); c.rect(x,y+h-4,4,4,fg); c.rect(x+w-4,y+h-4,4,4,fg);
  }
  if (p==='C') {
    c.rect(x+w-8,y,8,1,bg); c.line(x+w-8,y,x+w-1,y+7,fg); c.line(x+w-1,y+7,x+w-1,y,fg);
  }
}

function label(c,text,x,y,p='A',scale=1) { c.drawText(text,x,y,scale,profiles[p].fg); }
function base(p='A') { return new PixelCanvas(320,180,profiles[p].bg); }
function header(c,title,p='A',right='') {
  panel(c,4,4,312,16,p);
  label(c,title,9,8,p);
  if (right) label(c,right,314-right.length*6,8,p);
}
function footer(c,text,p='A') { panel(c,4,160,312,16,p); label(c,text,9,164,p); }
function focus(c,x,y,w,h,p='A') { const f=profiles[p].fg; c.drawText('>',x,y+Math.max(0,Math.floor((h-7)/2)),1,f); c.strokeRect(x+8,y,w-8,h,f); }
function row(c,text,x,y,w,p='A',selected=false,tail='') {
  if (selected) { c.rect(x,y,w,14,profiles[p].fg); c.drawText('>'+text,x+3,y+4,1,profiles[p].bg); if(tail)c.drawText(tail,x+w-tail.length*6-3,y+4,1,profiles[p].bg); }
  else { c.drawText(text,x+11,y+4,1,profiles[p].fg); c.rect(x+3,y+6,3,3,profiles[p].fg); if(tail)c.drawText(tail,x+w-tail.length*6-3,y+4,1,profiles[p].fg); }
}
function tabs(c,items,active,p='A') {
  let x=5; for(const item of items){const w=Math.max(42,item.length*6+10); panel(c,x,22,w,14,p); if(item===active)c.rect(x+3,33,w-6,2,profiles[p].fg); label(c,item,x+5,26,p); x+=w+2;}
}
function stamp(c,x,y,kind=0,p='A',size=12) {
  const f=profiles[p].fg,b=profiles[p].bg; c.strokeRect(x,y,size,size,f);
  const m=Math.floor(size/2);
  if(kind%6===0){c.circle(x+m,y+m,Math.max(2,m-2),f,false);c.rect(x+m,y+2,1,size-4,f);}
  if(kind%6===1){c.line(x+2,y+size-3,x+size-3,y+2,f,2);c.line(x+2,y+2,x+size-3,y+size-3,f);c.rect(x+m-1,y+m-1,3,3,b);}
  if(kind%6===2){c.rect(x+m-1,y+2,3,size-4,f);c.rect(x+2,y+m-1,size-4,3,f);}
  if(kind%6===3){c.poly([[x+m,y+1],[x+size-2,y+m],[x+m,y+size-2],[x+1,y+m]],f);c.circle(x+m,y+m,2,b);}
  if(kind%6===4){c.line(x+1,y+m,x+size-2,y+m,f,2);c.circle(x+3,y+m,2,f);c.circle(x+size-4,y+m,2,f);}
  if(kind%6===5){c.rect(x+2,y+2,size-4,size-4,f);c.strokeRect(x+4,y+4,size-8,size-8,b);}
}
function bar(c,x,y,w,value,p='A'){const f=profiles[p].fg,b=profiles[p].bg;c.strokeRect(x,y,w,7,f);c.rect(x+2,y+2,Math.floor((w-4)*value),3,f);if(value<1)c.rect(x+2+Math.floor((w-4)*value),y+2,(w-4)-Math.floor((w-4)*value),3,b);}
function portrait(c,name,x,y,p='A',caption='') {
  panel(c,x,y,72,106,p); const inv=p==='D'; blitScale(c,makeFrame(name,'talk',2,'L'),x+4,y+5,2,inv); c.rect(x+3,y+90,66,13,profiles[p].bg); c.strokeRect(x+3,y+90,66,13,profiles[p].fg); label(c,caption||name.toUpperCase(),x+7,y+94,p);
}
function shrineBg(c,p='A') {
  const f=profiles[p].fg,b=profiles[p].bg;
  if(p!=='D') c.patternRect(0,18,320,44,1,f);
  c.poly([[40,92],[160,37],[280,92],[264,100],[56,100]],f);
  c.poly([[77,87],[160,51],[243,87],[231,92],[89,92]],b);
  c.rect(70,91,180,50,f); for(let x=82;x<240;x+=28){c.rect(x,99,20,37,b);c.strokeRect(x,99,20,37,f);c.line(x+10,100,x+10,135,f);}
  c.rect(0,140,320,3,f); if(p!=='D')c.patternRect(0,143,320,37,1,f);
  c.rect(146,120,28,21,b);c.strokeRect(146,120,28,21,f,2);for(let x=150;x<172;x+=4)c.rect(x,123,2,13,f);
}
function bambooBg(c,p='D') {
  const f=profiles[p].fg,b=profiles[p].bg;c.rect(0,0,320,180,b);c.circle(236,45,29,f);c.circle(247,38,24,b);
  for(let x=6;x<320;x+=23){c.rect(x,0,6,143,f);c.rect(x+2,0,2,143,b);for(let y=18;y<140;y+=25)c.rect(x-2,y,10,2,b);}
  c.rect(0,142,320,3,f);for(let x=0;x<320;x+=6)c.line(x,179,x+8,145,f);
}
function bulletFlower(c,cx,cy,p='D',rings=4){const f=profiles[p].fg;for(let r=1;r<=rings;r++){const n=8+r*2,rad=r*13;for(let i=0;i<n;i++){const a=i/n*Math.PI*2;c.circle(Math.round(cx+Math.cos(a)*rad),Math.round(cy+Math.sin(a)*rad),i%3===0?2:1,f,i%2===0);}}}

const draws = {
  title(){const c=base('A');c.patternRect(0,0,320,180,1,BLACK);c.rect(0,0,156,180,WHITE);c.poly([[4,127],[57,82],[121,116],[151,75],[151,180],[4,180]],BLACK);label(c,'GENSOKYO',14,20,'A',2);label(c,'MONOCHROME HEART',15,41,'A');panel(c,171,75,145,91,'A');['CONTINUE','NEW GAME','JOURNAL','OPTIONS','CREDITS'].forEach((x,i)=>row(c,x,180,82+i*15,126,'A',i===0));label(c,'EN / JA   V2 VISUAL',8,169,'A');return c;},
  language(){const c=base('A');header(c,'SELECT LANGUAGE','A','FIRST BOOT');panel(c,26,48,126,54,'A');stamp(c,37,61,0,'A',24);label(c,'ENGLISH',70,67,'A');focus(c,23,45,132,60,'A');panel(c,168,48,126,54,'A');stamp(c,179,61,3,'A',24);label(c,'JAPANESE',211,67,'A');panel(c,36,124,248,28,'A');label(c,'FONT PREVIEW / LANGUAGE IS REVERSIBLE',46,134,'A');footer(c,'CONFIRM  BACK  TEXT PREVIEW','A');return c;},
  save_load(){const c=base('A');header(c,'SAVE / LOAD','A','PAGE 1/3');tabs(c,['SAVE','LOAD','AUTO'],'LOAD','A');for(let i=0;i<3;i++){panel(c,10,42+i*38,300,34,'A');c.patternRect(15,47+i*38,58,24,i===1?2:1,BLACK);stamp(c,37,53+i*38,i,'A',12);label(c,i===0?'DAY 08 / SHRINE':i===1?'DAY 06 / MANSION':'EMPTY SLOT',82,48+i*38,'A');label(c,i===0?'THREAD: EMPTY CUP':i===1?'THREAD: LOST MINUTE':'-',82,59+i*38,'A');label(c,i===0?'02:14':'01:39',267,59+i*38,'A');if(i===0)focus(c,7,39,306,40,'A');}footer(c,'CONFIRM LOAD  DELETE  BACK','A');return c;},
  options_accessibility(){const c=base('A');header(c,'ACCESSIBILITY','A','PROFILE FORCE: A');tabs(c,['VISUAL','MOTION','COMBAT','TEXT'],'VISUAL','A');const labels=['FORCE PROFILE A','HIGH CONTRAST FOCUS','DITHER LEVEL','BULLET OUTLINE','SCREEN SHAKE'];labels.forEach((x,i)=>{row(c,x,13,43+i*19,190,'A',i===1);panel(c,224,45+i*19,76,12,'A');label(c,i===0?'OFF / ON':i===1?'ON':i===2?'25%':'ON',234,48+i*19,'A');});panel(c,12,141,296,15,'A');label(c,'PREVIEW: > FOCUS  O BULLET  X HAZARD',18,145,'A');footer(c,'ADJUST  HELP  RESET CATEGORY  BACK','A');return c;},
  world_map(){const c=base('A');header(c,'DAY 08 / DUSK / LIGHT RAIN','A','THREAD: EMPTY CUP');panel(c,4,24,228,132,'A');const n=[[32,52,'VILLAGE'],[94,38,'SHRINE'],[164,51,'LAKE'],[202,79,'MANSION'],[112,89,'FOREST'],[61,122,'HAKUGYO'],[158,126,'EIENTEI'],[197,112,'BAMBOO']];const links=[[0,1],[1,2],[2,3],[1,4],[4,6],[6,7],[4,5]];for(const [a,b] of links)c.line(n[a][0],n[a][1],n[b][0],n[b][1],BLACK);n.forEach((q,i)=>{c.circle(q[0],q[1],i===1?6:4,BLACK,false);if(i===1)c.circle(q[0],q[1],2,BLACK);label(c,q[2],q[0]-Math.min(18,q[2].length*3),q[1]+8,'A');});panel(c,236,24,80,132,'A');stamp(c,246,33,0,'A',16);label(c,'SHRINE',267,38,'A');label(c,'KNOWN 8/8',244,59,'A');label(c,'CHANGED',244,72,'A');bar(c,244,85,61,.7,'A');label(c,'REIMU',244,99,'A');label(c,'MARISA',244,112,'A');label(c,'TRAVEL',244,137,'A');footer(c,'MOVE  OPEN  JOURNAL  BACK','A');return c;},
  destination(){const c=base('A');header(c,'HAKUREI SHRINE','A','KNOWN / CHANGED');panel(c,8,28,132,78,'A');shrineBg(c,'A');c.rect(8,28,132,78,WHITE);c.strokeRect(8,28,132,78,BLACK,2);c.poly([[20,76],[74,45],[128,76],[120,82],[28,82]],BLACK);stamp(c,18,34,0,'A',16);panel(c,148,28,164,78,'A');['VERANDA *','DONATION BOX','STOREHOUSE ?','BOUNDARY EDGE'].forEach((x,i)=>row(c,x,154,34+i*16,150,'A',i===0));panel(c,8,112,304,42,'A');label(c,'COMPANION: REIMU / TEA SILENCE AVAILABLE',16,119,'A');label(c,'INCIDENT TRACE: WARM CUP / CUSHION MOVED',16,133,'A');footer(c,'TRAVEL  SPOTS  PEOPLE  BACK','A');return c;},
  exploration(){const c=base('A');shrineBg(c,'A');header(c,'SHRINE / VERANDA / DUSK','A','CUP 1/3');blitScale(c,makeFrame('reimu','idle',0,'M'),210,106,1,false);blitScale(c,makeFrame('marisa','walk',2,'M'),83,107,1,false);panel(c,184,93,72,13,'A');label(c,'TALK REIMU',190,97,'A');stamp(c,170,95,2,'A',10);footer(c,'MOVE  OBSERVE  TALK  JOURNAL','A');return c;},
  dialogue(){const c=base('A');shrineBg(c,'A');portrait(c,'reimu',8,48,'A','REIMU');panel(c,85,109,231,67,'A');panel(c,94,101,66,12,'A');label(c,'REIMU',102,104,'A');label(c,'I DID NOT WAIT.',94,120,'A');label(c,'THE SECOND CUP WAS',94,132,'A');label(c,'SIMPLY NOT PUT AWAY.',94,144,'A');label(c,'AUTO: OFF  LOG',208,164,'A');c.poly([[300,164],[306,164],[303,169]],BLACK);return c;},
  dialogue_choice(){const c=base('C');c.patternRect(0,0,320,108,1,BLACK);portrait(c,'reimu',8,41,'C','REIMU');panel(c,85,76,112,85,'C');label(c,'THE CUP',94,86,'C');label(c,'IS STILL',94,98,'C');label(c,'WARM.',94,110,'C');const a=['DIRECT / ASK WHY','PLAYFUL / CUP WAITS','PATIENT / POUR TEA'];a.forEach((x,i)=>{panel(c,202,76+i*28,114,24,'C');stamp(c,207,82+i*28,i,'C',12);label(c,x,223,84+i*28,'C');});focus(c,199,129,120,30,'C');footer(c,'CHOOSE INTENT  HELP  BACK','C');return c;},
  backlog(){const c=base('A');header(c,'BACKLOG','A','FILTER: ALL');panel(c,6,26,76,128,'A');['REIMU','YOU','MARISA','SYSTEM'].forEach((x,i)=>row(c,x,10,34+i*18,68,'A',i===0));panel(c,86,26,228,128,'A');const lines=['REIMU / I DID NOT WAIT.','YOU / THEN WHY TWO CUPS?','REIMU / ONE WAS NOT PUT AWAY.','> PATIENT / POUR THE TEA.','SYSTEM / MEMORY CHANGED.'];lines.forEach((x,i)=>{label(c,x,94,35+i*22,'A');c.rect(94,45+i*22,194-(i%2)*31,1,BLACK);});footer(c,'MOVE  FILTER  JUMP TO EVENT  BACK','A');return c;},
  journal_people(){const c=base('B');header(c,'MONOCHROME JOURNAL','B','PEOPLE');tabs(c,['SUMMARY','PEOPLE','PLACES','RUMORS'],'PEOPLE','B');panel(c,5,40,86,115,'B');['REIMU *','MARISA','SAKUYA','PATCHOULI','YOUMU'].forEach((x,i)=>row(c,x,9,47+i*18,78,'B',i===0));portrait(c,'reimu',96,44,'B','REIMU');panel(c,172,40,143,115,'B');label(c,'REIMU HAKUREI',181,48,'B');stamp(c,286,46,0,'B',16);label(c,'KNOWN / DEEP',181,63,'B');label(c,'SHRINE MAID',181,76,'B');label(c,'CURRENT:',181,94,'B');label(c,'QUIETLY OPEN',181,106,'B');bar(c,181,119,119,.72,'B');label(c,'2 NEW MEMORIES',181,136,'B');footer(c,'OPEN MEMORIES  PAGE  BACK','B');return c;},
  journal_rumors(){const c=base('B');header(c,'MONOCHROME JOURNAL','B','RUMORS');tabs(c,['ALL','OPEN','CHANGED','RESOLVED'],'CHANGED','B');const rs=[['WARM CUP BEFORE ARRIVAL','OBSERVED'],['NO GUEST WAS EXPECTED','CONTRADICTED'],['CUSHION LEFT THE CLOSET','CHANGED'],['BOUNDARY OPENS UNWATCHED','OPEN']];rs.forEach((r,i)=>{panel(c,8,43+i*27,304,23,'B');stamp(c,14,48+i*27,i,'B',12);label(c,r[0],32,49+i*27,'B');label(c,r[1],306-r[1].length*6,49+i*27,'B');});footer(c,'OPEN THREAD  FILTER  BACK','B');return c;},
  memory_thread(){const c=base('B');header(c,'MEMORY THREAD / EMPTY SECOND CUP','B','5 NODES');panel(c,7,26,306,91,'B');const xs=[28,85,143,202,275];for(let i=0;i<xs.length-1;i++){c.line(xs[i]+10,64,xs[i+1],64,BLACK);if(i===1)for(let x=xs[i]+13;x<xs[i+1];x+=5)c.rect(x,62,2,5,WHITE);}xs.forEach((x,i)=>{stamp(c,x,56,i,'B',16);label(c,['CHARM','CUP','TEA','RETURN','GUEST'][i],x-3,79,'B');});panel(c,7,122,306,34,'B');label(c,'CHANGED: THE CUSHION IS NO LONGER STORED.',15,129,'B');label(c,'SOURCE: SHRINE / VERANDA / DAY 08',15,142,'B');footer(c,'PAN  OPEN EVIDENCE  LINEAR VIEW  BACK','B');return c;},
  keepsakes(){const c=base('C');header(c,'KEEPSAKES','C','FOUND 07');for(let i=0;i<12;i++){panel(c,8+(i%4)*43,28+Math.floor(i/4)*43,38,38,'C');if(i<7)stamp(c,19+(i%4)*43,39+Math.floor(i/4)*43,i,'C',16);else label(c,'?',23+(i%4)*43,43+Math.floor(i/4)*43,'C',2);}focus(c,5,25,44,44,'C');panel(c,188,28,124,126,'C');stamp(c,217,38,0,'C',48);label(c,'WARM TEACUP',201,94,'C');label(c,'NOT A PROMISE.',201,109,'C');label(c,'A PLACE KEPT',201,121,'C');label(c,'OPEN ANYWAY.',201,133,'C');footer(c,'OPEN MEMORY  PAGE  BACK','C');return c;},
  character_profile(){const c=base('C');header(c,'CHARACTER PROFILE','C','REIMU');portrait(c,'reimu',9,38,'C','REIMU');panel(c,87,27,225,127,'C');stamp(c,266,38,0,'C',32);label(c,'REIMU HAKUREI',98,39,'C');label(c,'ROUTE: QUIETLY OPEN',98,55,'C');label(c,'SILHOUETTE',98,75,'C');label(c,'BOW / SLEEVES / GOHEI',98,87,'C');label(c,'SHARED MEMORY',98,105,'C');label(c,'THE EMPTY SECOND CUP',98,117,'C');label(c,'VOICE: PRACTICAL WARMTH',98,136,'C');footer(c,'MEMORIES  KEEPSAKES  BACK','C');return c;},
  route_threshold(){const c=base('C');c.patternRect(0,0,320,180,1,BLACK);panel(c,27,17,266,146,'C');stamp(c,136,29,0,'C',48);label(c,'QUIETLY OPEN',111,84,'C');label(c,'NO NUMBER CHANGED.',82,103,'C');label(c,'A PLACE WAS KEPT OPEN',70,116,'C');label(c,'AND SOMEONE RETURNED.',79,128,'C');panel(c,96,142,128,16,'C');label(c,'CONTINUE TO AFTERBEAT',103,147,'C');return c;},
  danmaku(){const c=base('D');bambooBg(c,'D');panel(c,4,4,224,152,'D');label(c,'SPELL / EMPTY MOON CUP',10,9,'D');bulletFlower(c,116,65,'D',4);blitScale(c,makeFrame('reimu','idle',0,'S'),108,126,1,true);c.strokeRect(112,143,8,8,WHITE);panel(c,232,4,84,152,'D');label(c,'REIMU',240,12,'D');bar(c,240,24,67,.66,'D');label(c,'LIFE',240,39,'D');for(let i=0;i<4;i++)c.circle(270+i*9,42,3,WHITE,i<3);label(c,'BOMB',240,54,'D');for(let i=0;i<4;i++)c.strokeRect(270+i*9,52,6,6,WHITE);label(c,'TIME 42',240,70,'D');label(c,'SCORE',240,89,'D');label(c,'0012840',240,101,'D');stamp(c,263,121,3,'D',24);footer(c,'FOCUS  SHOT  BOMB  PAUSE','D');return c;},
  danmaku_result(){const c=base('D');panel(c,24,18,272,144,'D');stamp(c,135,29,3,'D',48);label(c,'SPELL CAPTURED',102,84,'D');const rr=[['TIME','38.4'],['GRAZE','027'],['BOMBS','0'],['BONUS','012800']];rr.forEach((x,i)=>{label(c,x[0],58,103+i*11,'D');label(c,x[1],250-x[1].length*6,103+i*11,'D');});panel(c,52,147,98,12,'D');label(c,'CONTINUE',66,150,'D');focus(c,49,144,104,18,'D');panel(c,169,147,98,12,'D');label(c,'RETRY',194,150,'D');return c;},
  fighter(){const c=base('A');c.patternRect(0,46,320,94,1,BLACK);c.rect(0,140,320,3,BLACK);header(c,'REIMU','A','MARISA');bar(c,8,24,126,.73,'A');bar(c,186,24,126,.56,'A');label(c,'58',152,24,'A',2);for(let i=0;i<3;i++){stamp(c,9+i*17,35,i,'A',12);stamp(c,278+i*17,35,3+i,'A',12);}blitScale(c,makeFrame('reimu','walk',1,'L'),55,92,1,false);blitScale(c,makeFrame('marisa','talk',2,'L'),235,92,1,false);c.line(94,116,218,116,BLACK,2);for(let x=112;x<205;x+=19)c.rect(x,113,7,7,WHITE);footer(c,'LIGHT  HEAVY  SKILL  SPELL  COMPANION','A');return c;},
  fighter_result(){const c=base('C');c.patternRect(0,0,320,180,1,BLACK);panel(c,15,17,290,146,'C');blitScale(c,makeFrame('reimu','talk',2,'L'),38,54,2,false);label(c,'REIMU WINS',134,39,'C',2);label(c,'ROUND 2 / SPELL BREAK',135,63,'C');label(c,'THE YARD SURVIVED.',135,82,'C');label(c,'MOSTLY.',135,94,'C');panel(c,132,119,150,17,'C');label(c,'CONTINUE STORY',146,124,'C');focus(c,129,116,156,23,'C');panel(c,132,140,150,17,'C');label(c,'REMATCH',181,145,'C');return c;},
  minigame(){const c=base('A');header(c,'TEA AT THE RIGHT SILENCE','A','STEP 2/4');panel(c,9,28,302,98,'A');c.rect(43,94,234,3,BLACK);for(let i=0;i<3;i++){c.strokeRect(65+i*82,68,43,26,BLACK);c.line(105+i*82,76,117+i*82,71,BLACK);c.line(117+i*82,71,120+i*82,75,BLACK);c.patternRect(71+i*82,73,31,14,i+1,BLACK);}label(c,'WAIT FOR THE STEAM TO SETTLE.',57,39,'A');bar(c,50,111,220,.58,'A');label(c,'TOO SOON',29,113,'A');label(c,'RIGHT SILENCE',229,113,'A');footer(c,'HOLD PATIENCE  RELEASE TO POUR  PAUSE','A');return c;},
  photo_camera(){const c=base('D');bambooBg(c,'D');c.strokeRect(7,7,270,146,WHITE,2);for(const [x,y,sx,sy] of [[10,10,1,1],[274,10,-1,1],[10,150,1,-1],[274,150,-1,-1]]){c.line(x,y,x+sx*18,y,WHITE,2);c.line(x,y,x,y+sy*18,WHITE,2);}c.strokeRect(120,56,44,44,WHITE);stamp(c,134,70,1,'D',16);panel(c,282,7,34,146,'D');label(c,'ZOOM',284,14,'D');bar(c,289,31,20,.7,'D');label(c,'LOCK',284,50,'D');stamp(c,291,64,2,'D',16);label(c,'03',292,88,'D');label(c,'AYA',288,111,'D');footer(c,'MOVE  FOCUS  SHUTTER  BACK','D');return c;},
  trade_shop(){const c=base('A');header(c,'KOURINDOU / TRADE','A','COINS 024');tabs(c,['BUY','SELL','TRADE'],'TRADE','A');panel(c,6,40,126,114,'A');['RADIO ?','RED RIBBON','MOON VIAL','OLD CAMERA','BROKEN CUP'].forEach((x,i)=>row(c,x,10,47+i*19,118,'A',i===0,i===0?'12':''));panel(c,137,40,177,114,'A');stamp(c,202,48,5,'A',36);label(c,'OUTSIDE RADIO',153,93,'A');label(c,'FUNCTION: WEATHER?',153,106,'A');label(c,'RINNOSUKE IS 63%',153,120,'A');label(c,'CERTAIN. COST 12',153,132,'A');footer(c,'TRADE  DETAILS  PAGE  BACK','A');return c;},
  clinic(){const c=base('B');header(c,'EIENTEI CLINIC','B','CASE 03');panel(c,6,27,76,127,'B');['TEWI','REISEN','YOU'].forEach((x,i)=>row(c,x,10,37+i*20,68,'B',i===2));panel(c,87,27,103,127,'B');label(c,'SYMPTOMS',98,36,'B');['LOST TIME','MOON ECHO','WARM CUP'].forEach((x,i)=>{stamp(c,97,51+i*25,i,'B',12);label(c,x,114,54+i*25,'B');});panel(c,195,27,119,127,'B');label(c,'COMPOUND',207,36,'B');for(let i=0;i<6;i++){stamp(c,207+(i%3)*31,54+Math.floor(i/3)*31,i,'B',20);}bar(c,207,121,94,.67,'B');label(c,'DOSE 2 / 3',221,135,'B');footer(c,'OBSERVE  MIX  ADMINISTER  BACK','B');return c;}
};

const order = ['title','language','save_load','options_accessibility','world_map','destination','exploration','dialogue','dialogue_choice','backlog','journal_people','journal_rumors','memory_thread','keepsakes','character_profile','route_threshold','danmaku','danmaku_result','fighter','fighter_result','minigame','photo_camera','trade_shop','clinic'];
const images=[];
for(const id of order){
  const c=draws[id]();
  const raw=path.join(RAW,`${id}.png`),preview=path.join(PREVIEW,`${id}_4x.png`);
  c.write(raw);c.writeScaled(preview,4);images.push({id,raw:`raw_320x180/${id}.png`,preview:`preview_4x/${id}_4x.png`,size:[320,180]});
}

function down2(src){const out=new PixelCanvas(160,90,WHITE);for(let y=0;y<90;y++)for(let x=0;x<160;x++)out.set(x,y,src.get(x*2,y*2));return out;}
const sheet=new PixelCanvas(660,612,WHITE);
order.forEach((id,i)=>{const x=4+(i%4)*164,y=4+Math.floor(i/4)*101;sheet.drawText(id.slice(0,25),x,y,1,BLACK);sheet.blit(down2(draws[id]()),x,y+10);sheet.strokeRect(x,y+10,160,90,BLACK);});
sheet.write(path.join(ROOT,'05_ui_ux','samples','complete_ui_sample_atlas_raw.png'));
sheet.writeScaled(path.join(ROOT,'05_ui_ux','samples','complete_ui_sample_atlas_2x.png'),2);

fs.writeFileSync(path.join(ROOT,'05_ui_ux','samples','manifest.json'),JSON.stringify({schema:'gensokyo-monochrome-ui-samples-v2',count:images.length,coverage:'representative canonical screens; all 40 screen contracts are in screen_inventory.json',images,atlas:'complete_ui_sample_atlas_2x.png'},null,2)+'\n');
console.log(`Generated ${images.length} exact 1-bit UI samples plus atlas.`);
