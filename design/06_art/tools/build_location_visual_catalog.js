#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const LOCATION_DIR = path.join(ROOT, '03_locations');
const OUT_DIR = path.join(ROOT, '06_art', 'regions');
const BRIEF_DIR = path.join(OUT_DIR, 'briefs');

const V = {
  animal_realm_primate_garden: {
    tier: 'B', profiles: ['D', 'B'], stamp: 'broken haniwa face inside a square seal',
    thesis: 'Military geometry tries to contain souls that refuse to become identical.',
    silhouette: 'stacked black towers, assembly lines, regimented haniwa ranks, enormous beast-shadow cutouts',
    layers: ['white void with sparse descending soul commas', 'factory terraces and distant regiment silhouettes', 'hard-edged platforms, clay ramps and conveyor seams', 'passing haniwa shields and beast claws'],
    tiles: ['clay brick', 'kiln grate', 'conveyor teeth', 'haniwa face', 'spirit pool', 'beast claw mark', 'garden plinth', 'command banner'],
    landmark: 'Keiki atelier: a white goddess-shaped gap surrounded by dense black scaffolding',
    texture: 'orthogonal 50% ordered dither interrupted by organic soul curves',
    ambience: 'kiln pulse, marching dust, soul commas and one-frame forge sparks',
    transition: 'a haniwa stamp strikes; the screen breaks into four disciplined panels',
    states: ['CALM: orderly ranks with one figure subtly misaligned', 'INCIDENT: command banners double and corridors narrow', 'ROUTE: one handmade figure appears beside the chosen character', 'SEASON: kiln steam and clay moisture change the floor pattern', 'AFTER: regiment gaps become gardens without losing the industrial skeleton'],
    combat: 'reserve a clean 208x128 arena; hazards move on visible 16-pixel lanes; soul bullets never share the clay dither frequency'
  },
  eientei_bamboo_forest: {
    tier: 'A', profiles: ['C', 'D'], stamp: 'rabbit ears crossing a medicine vial',
    thesis: 'Repeated corridors become intimate only through tiny, remembered differences.',
    silhouette: 'vertical bamboo bars, long rabbit ears, low tiled roofs and an impossible moon disc',
    layers: ['moon and sparse bamboo ghosts', 'two scrolling bamboo bands at unequal speed', 'root paths, clinic floor and sliding-door thresholds', 'near bamboo wipes, drifting leaves and rabbit-ear peeks'],
    tiles: ['bamboo stalk', 'split root', 'lost-path fork', 'moonlit puddle', 'tatami', 'medicine shelf', 'rabbit burrow', 'sealed corridor'],
    landmark: 'Eientei gate appears as a white horizontal cut through a forest of black verticals',
    texture: 'low-frequency vertical hatch; interiors return to broad white tatami fields',
    ambience: 'bamboo sway, ear silhouettes, vial glints and moon phase wipes',
    transition: 'three bamboo trunks pass foreground; the middle trunk becomes a door frame',
    states: ['CALM: readable leaf notches identify loops', 'INCIDENT: notches migrate and the moon repeats', 'ROUTE: a private shortcut gains a character-specific charm', 'SEASON: snow, rain and fireflies alter only the far/mid bands', 'AFTER: wrong turns retain small gifts instead of punishment'],
    combat: 'use black stalk columns only at arena edges; lunatic wavelength effects are 2-pixel dashed contours, distinct from collision bullets'
  },
  forest_of_magic_kourindou: {
    tier: 'A', profiles: ['A', 'D'], stamp: 'mushroom cap over a price tag',
    thesis: 'Curiosity makes a home from clutter, but every object keeps an unknown past.',
    silhouette: 'leaning trees, mushroom shelves, broom diagonals, shop roof and outside-world rectangles',
    layers: ['white mist with crooked canopy islands', 'tree arches and distant object piles', 'soft root ground, shop floorboards and mushroom rings', 'hanging herbs, close branches and unlabeled junk'],
    tiles: ['root bridge', 'mushroom cluster', 'spark moss', 'herb hook', 'shop shelf', 'radio rectangle', 'broom rack', 'price tag'],
    landmark: 'Kourindou window: a bright display grid of objects whose silhouettes never quite match their labels',
    texture: 'organic stipple in forest; clean parallel hatching on shop wood; no checker noise',
    ambience: 'spore drift, hanging herb swing, mini-hakkero spark and radio scan line',
    transition: 'a found object rotates as a black silhouette and becomes the next scene aperture',
    states: ['CALM: paths curve around useful clutter', 'INCIDENT: object labels detach and float to wrong items', 'ROUTE: the companion leaves a persistent object on one shelf', 'SEASON: fungi and canopy density swap by tile overlay', 'AFTER: a repaired object hums imperfectly in the shop'],
    combat: 'forest hazards use slow root telegraphs; sparks and bullets use hollow/solid polarity pairs; shop duels protect shelf silhouettes from visual overlap'
  },
  former_hell_chireiden: {
    tier: 'A', profiles: ['D', 'C'], stamp: 'third eye above a reactor ring',
    thesis: 'What is buried remains warm, social and capable of answering back.',
    silhouette: 'cavern vaults, palace arches, cat cart, raven wing, reactor circles and third-eye cords',
    layers: ['black cavern with white heat cracks', 'old city bridges and palace facade', 'basalt ledges, tiled corridors and reactor catwalks', 'steam plumes, chains, pipes and passing spirits'],
    tiles: ['basalt crack', 'hot spring edge', 'old city lantern', 'palace eye door', 'cat-cart rail', 'reactor grate', 'control rod socket', 'spirit flame niche'],
    landmark: 'subterranean sun: concentric white rings held inside a nearly solid black reactor hall',
    texture: '75% rock masses, 25% steam, broad white safety lanes around interactables',
    ambience: 'heat shimmer as alternating contour, cat-tail flame, cable pulse and slow spirit ascent',
    transition: 'a third-eye cord draws a circle; the circle becomes a tunnel or reactor iris',
    states: ['CALM: warm windows dot the black city', 'INCIDENT: heat cracks connect into an accusing eye', 'ROUTE: one sealed palace room opens into a quiet domestic vignette', 'SEASON: surface weather appears only as pipe condensation', 'AFTER: safety markings remain hand-painted and slightly uneven'],
    combat: 'reactor pulses occur behind the playfield at 2 Hz maximum; bullets use white cores with black safety rims; camera shake is optional and disabled by default'
  },
  garden_sun_nameless_hill: {
    tier: 'C', profiles: ['C', 'A'], stamp: 'sunflower split by a lily-of-the-valley bell',
    thesis: 'Beauty and poison share a border that must be approached, not erased.',
    silhouette: 'sunflower walls, parasol circle, low poisonous bells and abandoned doll shapes',
    layers: ['white sun disc and distant flower horizon', 'alternating tall sunflower and low hill bands', 'soil rows, narrow safe paths and petal clearings', 'petals, parasol edge and close swaying stems'],
    tiles: ['sunflower stem', 'turning flower head', 'lily bell', 'poison soil', 'safe stepping stone', 'doll scrap', 'parasol shade', 'wind furrow'],
    landmark: 'one enormous sunflower turns away from the player while every small flower faces them',
    texture: 'parallel soil hatch; flower heads are solid black disks with white seed notches',
    ambience: 'petal drift, flower turns, poison motes and abrupt wind silence',
    transition: 'a parasol closes to a vertical line, then opens onto the next field',
    states: ['CALM: tall and low fields remain clearly distinct', 'INCIDENT: flower heads track contradictory targets', 'ROUTE: a safe picnic shade appears without cleansing the hill', 'SEASON: bloom density changes through sparse overlays', 'AFTER: warning markers become handmade and cared for'],
    combat: 'poison zones use perimeter animation, never noisy fill; flower bullets remain circular while harmful pollen uses tiny crosses'
  },
  hakugyokurou: {
    tier: 'A', profiles: ['C', 'A'], stamp: 'half-phantom curling around a fan',
    thesis: 'Care for the dead is expressed through chores, appetite and disciplined incompleteness.',
    silhouette: 'endless stair, cherry boughs, broad ghost sleeves, twin swords and drifting soul commas',
    layers: ['white heaven with faint petal diagonals', 'stair terraces and Saigyou Ayakashi crown', 'garden paths, veranda boards and grave edges', 'petal veils, close branches and passing phantoms'],
    tiles: ['white stone stair', 'cherry root', 'petal mound', 'spirit lantern', 'garden rake line', 'meal tray', 'sword stand', 'sealed tree bark'],
    landmark: 'the staircase rises through three depth bands toward a tree too large to fit the frame',
    texture: 'very sparse 25% petal fields; black reserved for trunks, roofs and emotional beats',
    ambience: 'petal parallax, phantom breathing, fan flick and food steam',
    transition: 'petals gather into a butterfly; its wings open as the next scene',
    states: ['CALM: spirits drift in slow readable lanes', 'INCIDENT: stairs repeat one landing and petals fall upward', 'ROUTE: one shared meal setting persists on the veranda', 'SEASON: blossoms, bare branches and snow use the same collision map', 'AFTER: repaired garden lines include one playful detour'],
    combat: 'ghost bullets use hollow comma silhouettes; petals are non-colliding and dim to 25% behind combat; sword trails occupy one frame only'
  },
  hakurei_shrine: {
    tier: 'A', profiles: ['A', 'C'], stamp: 'yin-yang orb beneath a torii',
    thesis: 'A home is recognizable by the work that resumes after every incident.',
    silhouette: 'torii, low shrine eaves, donation box, bell rope, gohei zigzags and broad sky',
    layers: ['mostly white sky with one weather band', 'mountain line, distant torii and tree masses', 'stone path, veranda, yard and shrine interior', 'leaves, rope, eave edge and boundary tear'],
    tiles: ['stone step', 'weathered plank', 'tatami edge', 'donation box', 'paper charm', 'bell rope', 'leaf pile', 'boundary seam'],
    landmark: 'torii and donation box align for one instant when the boundary is stable',
    texture: 'white breathing room; black eaves; 25% stone and cloud dither only',
    ambience: 'leaf loops, charm flutter, kettle steam, bell tail and one-pixel boundary crawl',
    transition: 'a gohei swipe wipes a paper-white strip across the frame',
    states: ['CALM: chores and guest shoes create readable micro-state', 'INCIDENT: boundary seams cross ordinary objects', 'ROUTE: a chosen cushion and cup placement persist', 'SEASON: tree/leaf/weather overlays change independently', 'AFTER: patched wood and uneven new charms remain visible'],
    combat: 'protect a wide white center; boundary hazards use thick frame lines; leaves disappear in focus mode; donation box collision is outlined before impact'
  },
  heaven: {
    tier: 'C', profiles: ['C', 'D'], stamp: 'peach resting on a keystone',
    thesis: 'Perfect scenery becomes alive only when someone is allowed to disturb it.',
    silhouette: 'cloud shelves, peach trees, keystone blocks, celestial ribbons and weather sword',
    layers: ['pure white void with thin weather contours', 'floating islands and palace rails', 'cloud roads, peach terraces and keystone platforms', 'ribbon wipes, close cloud curls and falling peach leaves'],
    tiles: ['cloud curl', 'cloud stair', 'keystone face', 'peach branch', 'celestial railing', 'weather vein', 'banquet mat', 'island edge'],
    landmark: 'a black keystone floats below a white garden whose roots never touch it',
    texture: 'almost no dither; weight is communicated by solid keystones against blank cloud',
    ambience: 'cloud scroll, peach drop, ribbon wave and weather line travelling along edges',
    transition: 'a keystone falls toward camera and becomes a black full-screen card',
    states: ['CALM: immaculate repeated cloud curls', 'INCIDENT: one cloud layer moves against the others', 'ROUTE: an untidy picnic interrupts a perfect terrace', 'SEASON: weather changes by outline symbols, not fill', 'AFTER: a repaired railing keeps one visible dent'],
    combat: 'maximum negative space; weather telegraphs trace arena border first; keystones cast solid predictable rectangles with reduced-motion option'
  },
  hidden_back_doors: {
    tier: 'B', profiles: ['B', 'D'], stamp: 'open rectangle behind a folding fan',
    thesis: 'Every backstage entrance reveals an author, but never the entire production.',
    silhouette: 'freestanding doors, fan arcs, seated deity triangle, season emblems and impossible frame overlaps',
    layers: ['blank field with off-grid door specks', 'repeating stages seen through mismatched apertures', 'temporary platforms and threshold strips', 'door slabs crossing every UI-safe margin except the text zone'],
    tiles: ['door face', 'threshold', 'season crest', 'dancer footprint', 'backstage rope', 'empty frame', 'stage brace', 'boundary hinge'],
    landmark: 'four doors show four seasons while casting one shared black shadow',
    texture: 'profile shifts per doorway; threshold areas stay pure white for state readability',
    ambience: 'hinge tick, season particle swap, dancer shadow and fan-snap inversion',
    transition: 'the current background closes like a door, revealing the next scene already behind it',
    states: ['CALM: doors obey a visible seasonal grammar', 'INCIDENT: destinations and shadows disagree', 'ROUTE: one door gains a private hand-painted mark', 'SEASON: all four are present; active season controls only particles', 'AFTER: backstage braces remain visible and proudly functional'],
    combat: 'door teleports show destination outline for 12 frames; profile inversions never occur during dense volleys; screen border is gameplay geometry only when double-lined'
  },
  human_village: {
    tier: 'A', profiles: ['A', 'B'], stamp: 'open book behind a shop curtain',
    thesis: 'Ordinary routines are the infrastructure that makes extraordinary lives possible.',
    silhouette: 'layered tiled roofs, shop curtains, carts, books, school boards and crowded human-scale doors',
    layers: ['white sky, smoke lines and distant roof rhythm', 'alley roofs, market banners and school facade', 'stone drains, packed-earth streets and shop interiors', 'passing carts, curtains, signboards and crowd silhouettes'],
    tiles: ['roof cap', 'plaster wall', 'street drain', 'shop curtain', 'book shelf', 'school slate', 'market crate', 'rumor notice'],
    landmark: 'main crossing: four readable shop signs and one rumor board fit a 320-pixel frame without text collision',
    texture: 'low-frequency plaster speckle and wood hatch; crowds remain uncluttered solid shapes',
    ambience: 'curtain lift, cooking steam, page flip, cart wheel and changing notice slips',
    transition: 'a shop curtain sweeps sideways; its crest identifies the destination category',
    states: ['CALM: schedules visible through shutters and stall props', 'INCIDENT: rumor slips multiply faster than shops open', 'ROUTE: one shared routine alters a storefront at a fixed hour', 'SEASON: awnings, produce and street wetness use overlays', 'AFTER: residents reuse incident debris in repairs'],
    combat: 'civilian silhouettes vacate before arena lock; shop signs dim behind bullets; no random crowd motion during choice or combat focus'
  },
  lunar_capital_dream_world: {
    tier: 'B', profiles: ['B', 'D'], stamp: 'crescent inside a sleeping eye',
    thesis: 'Sterile certainty and unruly dreams become frightening when each impersonates the other.',
    silhouette: 'clean lunar spires, rabbit antennae, fan and sword lines, soft dream bubbles and three-world orbs',
    layers: ['white vacuum or black dream field', 'precise capital terraces / soft impossible horizons', 'geometric bridges / deforming dream floors', 'scan frames, bubbles and foreground moon gates'],
    tiles: ['lunar panel', 'purity seal', 'moon gate', 'rabbit terminal', 'dream pillow', 'bubble floor', 'impossible stair', 'waking crack'],
    landmark: 'a perfect moon gate casts a soft, anatomically impossible sleeping shadow',
    texture: 'capital uses sparse exact line grids; dream world uses slow large dither blobs, never pixel noise',
    ambience: 'terminal scan, distant rabbit signal, dream bubble reshape and polarity breathing',
    transition: 'an eyelid-shaped iris closes; on opening, grid and dream profiles swap',
    states: ['CALM: capital symmetry and dream asymmetry remain separate', 'INCIDENT: each leaks one texture into the other', 'ROUTE: a personal object survives the waking cut', 'SEASON: Gensokyo weather appears as archived screen icons', 'AFTER: one lunar panel bears a repaired, visibly handmade seam'],
    combat: 'grid lines fade to 25% under bullets; dream deformation never moves collision geometry without a 20-frame outline preview; polarity label remains textual'
  },
  misty_lake: {
    tier: 'B', profiles: ['A', 'D'], stamp: 'ice crystal reflected in a wave',
    thesis: 'Playful mistakes become landmarks when friends remember them together.',
    silhouette: 'flat waterline, reed clusters, ice-crystal wings, umbrella arc and mansion shadow',
    layers: ['white fog field with mansion pinprick', 'two reed/island bands dissolving into mist', 'shore stones, docks, ice floes and shallow water', 'fog curtains, close reeds, umbrella pop and splash arcs'],
    tiles: ['shore pebble', 'reed base', 'dock plank', 'water ripple', 'ice edge', 'fog pocket', 'umbrella puddle', 'fairy marker'],
    landmark: 'the mansion silhouette appears only through a narrow clear slit in three moving fog bands',
    texture: 'horizontal 25% ripple lines; fog stays white; ice uses black edge with white interior',
    ambience: 'fog drift, ripple ring, uneven ice-wing twitch and surprise umbrella blink',
    transition: 'fog fills the frame; a ripple opens a circular view onto the next spot',
    states: ['CALM: fog lanes loop predictably', 'INCIDENT: reflections lead one tile away from bodies', 'ROUTE: a ridiculous handmade marker persists on one island', 'SEASON: ice/fog/rain alter traversal overlays', 'AFTER: repaired dock boards retain mismatched widths'],
    combat: 'water reflection is disabled in focus mode; ice hazards telegraph with a thick crack outline; fog never lowers bullet contrast below AA target'
  },
  moriya_shrine: {
    tier: 'B', profiles: ['B', 'A'], stamp: 'frog eye and snake curve around an onbashira',
    thesis: 'Faith is maintained through engineering, hospitality and arguments about what counts as progress.',
    silhouette: 'mountain shrine roof, enormous rope loop, onbashira columns, frog hat and wind turbines/waterworks',
    layers: ['white mountain sky with wind contours', 'lake, shrine roof and rope ring', 'stone terrace, plank routes and device platforms', 'prayer slips, turbine blades, rope tassels and frog ripples'],
    tiles: ['mountain stone', 'shrine plank', 'onbashira socket', 'rope knot', 'frog pond edge', 'miracle charm', 'water pipe', 'wind rotor'],
    landmark: 'shimenawa ring frames a practical waterwheel rather than hiding it',
    texture: 'strong vertical pillars, circular rope/frog forms and clean mechanical hatch',
    ambience: 'wind sock, rope tassel, frog ripple, rotor step and miracle glyph',
    transition: 'a wind gust turns prayer slips into a wipe; one slip carries the next spot name',
    states: ['CALM: sacred and mechanical props share the terrace', 'INCIDENT: devices produce faith-shaped side effects', 'ROUTE: one jointly maintained machine gains a personal modification', 'SEASON: water level, snow and wind direction alter overlays', 'AFTER: signs explain repairs with conflicting divine annotations'],
    combat: 'rotors lock before combat; wind force uses arrows plus particles; onbashira lanes are 16-pixel aligned and preview impact footprints'
  },
  myouren_temple: {
    tier: 'B', profiles: ['B', 'C'], stamp: 'lotus above a ship anchor',
    thesis: 'A community is not harmony; it is the repeated practice of making room for difference.',
    silhouette: 'temple roof, lotus arches, ship ribs, cloud giant, anchor and cemetery markers',
    layers: ['white sky and distant pagoda', 'temple/ship structure and cemetery tree line', 'courtyard gravel, tatami, grave paths and hold decks', 'incense smoke, prayer flags, cloud fists and close grave stones'],
    tiles: ['temple gravel', 'lotus floor', 'ship rib', 'prayer bell', 'incense stand', 'grave marker', 'cloud step', 'anchor groove'],
    landmark: 'temple facade and ship hull share one contour, readable differently from each side',
    texture: 'gravel uses sparse fixed dots; robes/lotus spaces remain broad white; cemetery black is clustered low',
    ambience: 'incense curl, prayer flag, mouse pendulum, umbrella blink and restrained cloud breath',
    transition: 'a struck bell emits concentric outlines; the third ring becomes the next frame border',
    states: ['CALM: incompatible routines overlap without collision', 'INCIDENT: one rule is copied everywhere and stops fitting', 'ROUTE: a shared duty leaves a named object in the common hall', 'SEASON: incense, rain and cemetery foliage use overlays', 'AFTER: multiple repair styles remain side by side'],
    combat: 'cemetery markers are outside central arena; Unzan telegraphs with cloud outline before solid fist; incense disappears in focus mode'
  },
  outside_world_dream_theatre: {
    tier: 'C', profiles: ['B', 'C'], stamp: 'smartphone rectangle behind a stage moon',
    thesis: 'A memory of the outside world is a performance with visible missing scenery.',
    silhouette: 'rail platform, classroom window, city antennae, smartphone, occult cape and exposed theatre braces',
    layers: ['black auditorium void with white city pinpoints', 'flat scenery cards: train, school, rooftop', 'stage floor, taped marks and dream platforms', 'curtain edge, phone screen, dangling cable and audience shadow'],
    tiles: ['stage board', 'gaffer mark', 'train door', 'school desk', 'rooftop fence', 'phone icon', 'occult card', 'missing-set void'],
    landmark: 'a city skyline is visibly held up by two backstage braces and one dream thread',
    texture: 'screen-tone blocks imitate print/phone capture; stage remains clean enough to reveal artifice',
    ambience: 'phone scroll, train light pass, curtain breath and set-card wobble',
    transition: 'a phone camera shutter freezes the set; the frozen image slides aside',
    states: ['CALM: sets change on visible cues', 'INCIDENT: cues fire without performers', 'ROUTE: one prop gains a Gensokyo repair and survives scene changes', 'SEASON: city weather is a projected icon layer', 'AFTER: missing scenery is labeled instead of concealed'],
    combat: 'stage marks telegraph spawn positions; phone overlays sit outside playfield; photosensitivity mode replaces shutter flashes with border ticks'
  },
  sanzu_higan: {
    tier: 'C', profiles: ['C', 'A'], stamp: 'coin balanced on a judge rod',
    thesis: 'Judgment gains meaning only after someone listens to the journey that produced the evidence.',
    silhouette: 'wide river bands, low ferry, scythe crescent, flower plain, judge dais and rod vertical',
    layers: ['blank far shore with one dark tree', 'river strips and flower horizon', 'ferry deck, bank stones and court path', 'close reeds, drifting coins, sleeves and flower heads'],
    tiles: ['river ripple', 'bank stone', 'ferry plank', 'oar lock', 'coin eddy', 'higan flower', 'court stair', 'verdict tablet'],
    landmark: 'one coin remains perfectly still on the river while every bank line scrolls',
    texture: 'long horizontal 25% bands; court uses vertical black/white authority blocks',
    ambience: 'coin drift, oar drip, flower lean, page turn and single rod tap',
    transition: 'the ferry crosses a black river strip; arrival reveals the next scene above it',
    states: ['CALM: current and ferry schedules are legible', 'INCIDENT: memories arrive without matching owners', 'ROUTE: a privately heard testimony changes one flower marker', 'SEASON: river height and flower density use overlays', 'AFTER: queue markers allow pauses and conversation'],
    combat: 'river current arrows appear on floor and HUD; verdict text never overlaps bullets; scythe arcs are thick telegraphs followed by thin active edge'
  },
  scarlet_devil_mansion: {
    tier: 'A', profiles: ['B', 'D'], stamp: 'clock hand crossing a bat wing',
    thesis: 'Perfection is a performance built from labor, hierarchy and chosen loyalty.',
    silhouette: 'gothic roof, tall windows, clock hands, maid geometry, bat wings, library stacks and crystal prisms',
    layers: ['black night or white mist behind roofline', 'tower windows and long corridor vanishing points', 'checker-reduced floors, service passages and library platforms', 'curtains, chandelier edge, knife glints and crystal silhouettes'],
    tiles: ['gothic brick', 'tall window', 'clock gear', 'service door', 'library shelf', 'tea cart rail', 'basement lock', 'crystal play mark'],
    landmark: 'the great clock shows three readable times at three depths, only one belonging to the current room',
    texture: 'large 4x4 checker groups on floors, vertical book rhythm, solid curtain masses; never 1-pixel checker',
    ambience: 'clock tick, curtain shift, page drift, tea steam and crystal quarter-turn',
    transition: 'clock hands meet; the black wedge between them expands into the next room',
    states: ['CALM: servant routes and room clocks agree', 'INCIDENT: one minute is missing from every corridor', 'ROUTE: a private cup/book/knife placement persists by character', 'SEASON: exterior mist and interior drapery overlays change', 'AFTER: repaired furniture keeps small mismatched joins'],
    combat: 'floor pattern drops to 25% during combat; knives are thin black shapes with white rim; crystal break points use diamonds, never bullet circles'
  },
  senkai_mausoleum: {
    tier: 'B', profiles: ['B', 'D'], stamp: 'earmuff arc above a ritual plate',
    thesis: 'Revival turns old certainty into a conversation with a present that did not wait.',
    silhouette: 'mausoleum stairs, Taoist arches, cape triangle, ritual plates, wall passages and jiang-shi talisman',
    layers: ['white hermit sky with floating architecture traces', 'mausoleum roofs and Senkai islands', 'stone court, ritual floor and wall-crossing passages', 'plate arcs, cape edge, talisman strips and listening waves'],
    tiles: ['mausoleum stone', 'Tao seal', 'ritual plate', 'incense square', 'wall passage', 'speech wave', 'talisman door', 'Senkai cloud edge'],
    landmark: 'a formal stair ascends into a doorway whose back is visibly a floating island',
    texture: 'concentric ritual lines and broad stone fields; speech waves are sparse dashed outlines',
    ambience: 'plate orbit, cape settle, wall ripple, talisman flap and multi-voice wave',
    transition: 'a wall outline slides across the player; the reverse side is the destination',
    states: ['CALM: rituals map cleanly to doors', 'INCIDENT: old labels summon modern side effects', 'ROUTE: a jointly translated sign remains installed', 'SEASON: cloud island vegetation uses overlays', 'AFTER: new wiring/signage sits visibly beside ancient stone'],
    combat: 'plates orbit on fixed readable radii; wall-pass silhouettes are previewed on both surfaces; voice waves remain HUD cues, not collision objects'
  },
  youkai_mountain: {
    tier: 'A', profiles: ['A', 'D'], stamp: 'tengu feather over a waterfall notch',
    thesis: 'Every view is political: who can see, report, patrol, build and pass through.',
    silhouette: 'steep switchbacks, waterfall columns, tengu wings/cameras, kappa pipes, wolf shield and cable structures',
    layers: ['white sky with distant summit and cloud shelf', 'waterfalls, ropeways and settlement terraces', 'rock paths, bridges, workshops and patrol gates', 'spray curtains, leaves, camera frame and close pipework'],
    tiles: ['mountain ledge', 'waterfall lip', 'rope bridge', 'tengu notice', 'patrol marker', 'kappa pipe', 'workshop plate', 'camera perch'],
    landmark: 'one waterfall crosses all three depth bands but breaks into different pixel rhythms at each',
    texture: 'diagonal rock hatch, vertical water stripes and clean white spray gaps',
    ambience: 'spray step, leaf gust, camera shutter, valve spin and patrol ear twitch',
    transition: 'a newspaper page flips; its photo window expands into the destination view',
    states: ['CALM: patrol, press and workshop routes are separately legible', 'INCIDENT: reports redraw access before terrain changes', 'ROUTE: a shared lookout gains a private annotation', 'SEASON: waterfall volume, leaves and snow use overlays', 'AFTER: temporary bridges become accepted shortcuts without looking official'],
    combat: 'waterfall animation slows under dense bullets; wind arrows and patrol cones use different outlines; camera shutter uses no full-screen flash in safe mode'
  }
};

function extractList(text, heading) {
  const start = text.indexOf(`## ${heading}`);
  if (start < 0) return [];
  const body = text.slice(start + heading.length + 3);
  const end = body.search(/\n## /);
  const section = end < 0 ? body : body.slice(0, end);
  return section.split(/\r?\n/).filter(line => /^- /.test(line)).map(line => line.slice(2).trim());
}

function extractParagraph(text, heading) {
  const start = text.indexOf(`## ${heading}`);
  if (start < 0) return '';
  const body = text.slice(start + heading.length + 3).trimStart();
  const end = body.search(/\n## /);
  return (end < 0 ? body : body.slice(0, end)).trim().replace(/\n+/g, ' ');
}

function csvCell(v) {
  const s = String(v == null ? '' : v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function safeMkdir(p) { fs.mkdirSync(p, { recursive: true }); }

const files = fs.readdirSync(LOCATION_DIR).filter(f => f.endsWith('.md') && f !== 'README.md').sort();
const ids = files.map(f => path.basename(f, '.md'));
const missing = ids.filter(id => !V[id]);
const extra = Object.keys(V).filter(id => !ids.includes(id));
if (missing.length || extra.length) throw new Error(`Location visual map mismatch. Missing=${missing.join(',')} Extra=${extra.join(',')}`);

const entries = ids.map(id => {
  const source = fs.readFileSync(path.join(LOCATION_DIR, `${id}.md`), 'utf8');
  const title = (source.match(/^# (.+)$/m) || [null, id])[1];
  const v = V[id];
  const spots = extractList(source, 'Spots');
  const cast = extractList(source, 'Primary cast');
  const minigames = extractList(source, 'Signature minigames');
  return {
    id, title, tier: v.tier, profiles: v.profiles, stamp: v.stamp, thesis: v.thesis,
    silhouette: v.silhouette, layers: v.layers, signature_tiles: v.tiles, landmark: v.landmark,
    texture: v.texture, ambience: v.ambience, transition: v.transition, world_states: v.states,
    combat_readability: v.combat, spots, primary_cast: cast, minigames,
    art_anchor: extractParagraph(source, '1-bit art direction'),
    budgets: {
      base_tiles_16x16: v.tier === 'A' ? 64 : v.tier === 'B' ? 48 : 36,
      macro_tiles_32x32: v.tier === 'A' ? 18 : v.tier === 'B' ? 14 : 10,
      animated_props: v.tier === 'A' ? 12 : v.tier === 'B' ? 9 : 6,
      background_strips_320x180: v.tier === 'A' ? 8 : v.tier === 'B' ? 6 : 4,
      foreground_masks: v.tier === 'A' ? 6 : v.tier === 'B' ? 4 : 3,
      landmark_sets: v.tier === 'A' ? 3 : 2,
      state_overlays: 5
    }
  };
});

safeMkdir(BRIEF_DIR);
fs.writeFileSync(path.join(OUT_DIR, 'location_visual_catalog.json'), JSON.stringify({
  schema: 'gensokyo-monochrome-location-visual-v2',
  resolution: [320, 180], tile: [16, 16], profiles: ['A', 'B', 'C', 'D'], entries
}, null, 2) + '\n');

const csvHeader = ['id','title','tier','profiles','stamp','silhouette','landmark','tiles','ambience','transition','base_tiles','animated_props'];
const csvRows = entries.map(e => [e.id,e.title,e.tier,e.profiles.join('/'),e.stamp,e.silhouette,e.landmark,e.signature_tiles.join(' | '),e.ambience,e.transition,e.budgets.base_tiles_16x16,e.budgets.animated_props]);
fs.writeFileSync(path.join(OUT_DIR, 'location_visual_catalog.csv'), [csvHeader, ...csvRows].map(r => r.map(csvCell).join(',')).join('\n') + '\n');

const tierCounts = entries.reduce((a,e) => (a[e.tier]++, a), {A:0,B:0,C:0});
let catalog = `# Complete Location Visual Catalog\n\nAll ${entries.length} authored locations now have a production profile. Tier changes asset volume, never story importance. Every region is built at 320×180 from 16×16 tiles and four separable depth bands.\n\n| Tier | Regions | Base tiles | Animated props | Background strips |\n|---|---:|---:|---:|---:|\n| A | ${tierCounts.A} | 64 | 12 | 8 |\n| B | ${tierCounts.B} | 48 | 9 | 6 |\n| C | ${tierCounts.C} | 36 | 6 | 4 |\n\n| Region | Tier | Profiles | UI stamp | Landmark lock |\n|---|---:|---|---|---|\n`;
for (const e of entries) catalog += `| ${e.title} | ${e.tier} | ${e.profiles.join('/')} | ${e.stamp} | ${e.landmark} |\n`;
catalog += `\n## Universal region contract\n\n1. Keep far, middle, play, and foreground bands on separate layers.\n2. Place no high-frequency dither behind dialogue, choices, bullets, interact prompts, or focus reticles.\n3. Ship CALM, INCIDENT, ROUTE, SEASON, and AFTER overlays without duplicating collision maps unless the design explicitly changes traversal.\n4. The region stamp appears on entry cards, map detail, journal tabs, and save thumbnails. It must remain recognizable at 12×12.\n5. Every landmark must pass a filled-silhouette recognition test at 80×45 and a gameplay test at 320×180.\n`;
fs.writeFileSync(path.join(OUT_DIR, 'location_visual_catalog.md'), catalog);

for (const e of entries) {
  const b = e.budgets;
  const brief = `# ${e.title} — Visual Production Brief\n\n`+
`Source narrative bible: \`03_locations/${e.id}.md\`  \nProduction tier: **${e.tier}**  \nProfile family: **${e.profiles.join(' → ')}**  \nRegion stamp: **${e.stamp}**\n\n`+
`## Visual thesis\n\n${e.thesis}\n\n`+
`## Recognition lock\n\n- Silhouette vocabulary: ${e.silhouette}.\n- Landmark: ${e.landmark}.\n- Texture rule: ${e.texture}.\n- Entry transition: ${e.transition}.\n\n`+
`## Four depth bands\n\n${e.layers.map((x,i)=>`${i+1}. **${['FAR','MID','PLAY','FRONT'][i]}:** ${x}.`).join('\n')}\n\n`+
`## Signature 16×16 tile families\n\n${e.signature_tiles.map(x=>`- ${x}`).join('\n')}\n\n`+
`## Authored spot coverage\n\n${e.spots.map(x=>`- ${x}: make one 320×180 establishing plate, one exploration crop, and one state-overlay proof.`).join('\n')}\n\n`+
`## Ambient motion\n\n${e.ambience}. All loops are 4/6/8/12 frames at 8 fps and must be individually disableable.\n\n`+
`## World-state set\n\n${e.world_states.map(x=>`- ${x}`).join('\n')}\n\n`+
`## Combat and interaction readability\n\n${e.combat_readability}. Dialogue-safe zone is x=8–311, y=108–171; keep active faces and landmark pivots outside it during conversations.\n\n`+
`## Primary cast hooks\n\n${e.primary_cast.map(x=>`- ${x}: reserve one prop socket and one character-specific ambient reaction in at least one spot.`).join('\n')}\n\n`+
`## Minigame shell coverage\n\n${e.minigames.map(x=>`- ${x}: use the region stamp, one signature tile family, and a dedicated 12×12 state icon.`).join('\n')}\n\n`+
`## Asset budget\n\n| Asset | Count |\n|---|---:|\n| 16×16 base tiles | ${b.base_tiles_16x16} |\n| 32×32 macro tiles | ${b.macro_tiles_32x32} |\n| Animated props | ${b.animated_props} |\n| 320×180 background strips | ${b.background_strips_320x180} |\n| Foreground masks | ${b.foreground_masks} |\n| Landmark sets | ${b.landmark_sets} |\n| World-state overlays | ${b.state_overlays} |\n\n`+
`## Acceptance\n\n- [ ] Region identified from stamp at 12×12 and landmark at 80×45.\n- [ ] Four depth bands can be disabled independently.\n- [ ] All authored spots have at least one matching tile/prop family.\n- [ ] Five world states read without color.\n- [ ] UI, dialogue, danmaku and fighter visibility tests pass.\n- [ ] Reduced-motion mode removes foreground wipes and keeps navigation cues.\n- [ ] Japanese and English signs fit their measured boxes.\n`;
  fs.writeFileSync(path.join(BRIEF_DIR, `${e.id}.md`), brief);
}

let queue = `# Region Art Production Queue\n\nBuild shared tile primitives first, then prove one A region from each dominant profile before filling out variants. A tier is not a priority ranking for narrative implementation.\n\n`;
for (const tier of ['A','B','C']) {
  queue += `## Tier ${tier}\n\n`;
  for (const e of entries.filter(x=>x.tier===tier)) queue += `- [ ] **${e.title}** — stamp → landmark → 8 signature tiles → four depth bands → five states → combat proof\n`;
  queue += '\n';
}
fs.writeFileSync(path.join(OUT_DIR, 'production_queue.md'), queue);

console.log(`Built ${entries.length} location visual briefs: A=${tierCounts.A}, B=${tierCounts.B}, C=${tierCounts.C}`);
