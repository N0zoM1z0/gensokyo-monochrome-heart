const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const roster = JSON.parse(fs.readFileSync(path.join(ROOT, '04_characters', 'roster.json'), 'utf8')).characters;
const OUT = path.join(ROOT, '06_art', 'characters');

// silhouette, prop, companion layer, idle signature, talk signature,
// preferred profiles, costume/event variants, portrait emphasis
const V = {
  alice_margatroid: ['hair ribbon, fitted dress, puppet strings and doll shapes', 'grimoire / control cross', 'Shanghai and Hourai doll anchors', 'fingers tighten one thread while a doll lags one frame', 'a doll mirrors or contradicts her restrained hand gesture', 'A,B,C', 'work apron; rain cloak; formal dollmaker', 'precision, guarded pride, private softness'],
  aunn_komano: ['komainu ears, curled tail, round chest gem, compact guardian stance', 'guardian orb / shrine charm', 'tail and ear child layers', 'ears scan first, tail follows, feet stay planted', 'both hands open as if welcoming, then return to guard', 'A,C', 'shrine work sash; rain guard; festival guardian', 'earnest vigilance and uncomplicated delight'],
  aya_shameimaru: ['tokin cap, wing wedge, camera and notebook, geta stance', 'camera / feather fan', 'wings, strap and newspaper layers', 'camera strap shifts while her eyes keep tracking', 'camera rises, shutter cuts one frame, then she lowers it only if sincere', 'A,B,D', 'press armband; mountain patrol coat; rain cape', 'professional smile, predatory curiosity, camera-lowered sincerity'],
  byakuren_hijiri: ['long two-tone-implied hair, layered monk robes, broad calm sleeves', 'scroll / lotus light', 'beads and lotus glyph layer', 'beads settle after the sleeve, never bouncy', 'open palm and level gaze; power is shown by stillness', 'B,C,D', 'temple work robe; travel mantle; formal sermon robe', 'compassion, resolve, restrained physical power'],
  chen: ['cat ears, two tails, short dress and quick low stance', 'claw swipe / charm', 'two independent tail layers', 'one tail notices first, the second catches up', 'leans forward, hands close to chest, tails reveal the real mood', 'A,D', 'Mayohiga errands; rain hood; festival ribbon', 'curiosity, loyalty, sudden embarrassment'],
  cirno: ['short hair bow, six ice-crystal wing points, wide boastful stance', 'ice shard', 'crystal wing layer', 'wing points jitter in an uneven 2-1 rhythm', 'hands on hips, then one emphatic point that overshoots', 'A,D', 'summer melt gag; winter crown; lake patrol', 'boast, confusion, stubborn courage'],
  clownpiece: ['jester cap, star-and-stripe geometry, torch and energetic legs', 'torch', 'flame and flag-pattern layer', 'flame changes while the body holds a coiled bounce', 'torch arcs wide; eyes and cap bells carry the chaos', 'B,D', 'Hell patrol; festival torch; moon-surface dust', 'mischief, bewilderment, dangerous excitement'],
  doremy_sweet: ['nightcap, soft robe, dream-tail curl and floating orb silhouette', 'dream orb / pillow', 'dream bubbles and tail layer', 'body barely moves while bubbles drift out of phase', 'reshapes one orb into the subject of the sentence', 'C,D', 'sleep-clinic wrap; dream librarian; nightmare inversion', 'gentle distance, clinical dream-reading, sly amusement'],
  eiki_shiki_yamaxanadu: ['judge cap, formal robe column and unmistakable rod', 'Rod of Remorse', 'verdict tablet layer', 'nearly motionless; rod angle changes one pixel', 'rod indicates the issue, not the person, until the final beat', 'B,C', 'court formal; field inspection cloak', 'measured concern, severity, reluctant warmth'],
  eirin_yagokoro: ['very long braid, large asymmetric bow, vertical physician posture', 'vial / bow / medicine case', 'braid and medicine-case layer', 'checks one vial label; braid settles late', 'small hand motion, exact eye line, no wasted flourish', 'B,D', 'clinic coat; lunar formal; forest travel mantle', 'diagnostic calm, dry wit, guarded responsibility'],
  flandre_scarlet: ['cap, small body and two crystal-laden wing rods', 'wand / crystal prism', 'eight crystal children with fixed spacing', 'crystals rotate one step while her body remains intent', 'crouches closer or tilts one prism; avoid generic manic bouncing', 'B,C,D', 'mansion daywear; supervised garden cape; dream silhouette', 'intense curiosity, isolation, careful trust'],
  fujiwara_no_mokou: ['long rough hair, trouser silhouette, paper charms and flame tails', 'fire / paper charm', 'flame and charm layer', 'ember rises from a still shoulder line', 'one hand stays in a pocket until the line matters', 'A,D', 'forest guide coat; rain poncho; scorched battle set', 'blunt help, old exhaustion, competitive spark'],
  hata_no_kokoro: ['bob hair, broad sleeves and a halo/fan of distinct masks', 'selected mask / fan', 'mask wheel companion layer', 'one mask changes while her face remains neutral', 'the chosen mask moves to the foreground and supplies the gesture', 'B,C,D', 'stage costume; rehearsal plainwear; festival mask set', 'literal focus, learned emotion, uncanny comedy'],
  hatate_himekaidou: ['tengu cap, twin hair masses, compact wings and phone-camera rectangle', 'spirit camera / phone', 'wings and developed-photo layer', 'thumb scrolls; wings react after she finds something', 'shows a photo rather than performing a grand reporter pose', 'A,B', 'newsroom vest; rain cover; mountain casual', 'skepticism, competitive interest, reluctant admiration'],
  hecatia_lapislazuli: ['collar and chain, casual dress, three unmistakable planet spheres', 'planet sphere', 'three orbiting world layers', 'worlds rotate at different periods while she slouches casually', 'one world replaces another at the point of emphasis', 'C,D', 'Earth casual; Moon formal; Otherworld inversion', 'casual cosmic authority, humor, sudden seriousness'],
  hieda_no_akyuu: ['short formal hair, flower ornament, kimono block and book/brush', 'chronicle / brush', 'page and ink-stamp layer', 'brush pauses above a page; breath is minimal', 'turns the book toward the listener, then withholds one line', 'A,B,C', 'archive work; village formal; winter writing layer', 'observant courtesy, mortality-aware resolve, quiet mischief'],
  hina_kagiyama: ['many ribbons, spiral skirt and circular misfortune silhouette', 'misfortune amulet', 'ribbon spiral layer', 'slow quarter-turn; ribbons lag in alternating directions', 'stops the spin for one direct sentence', 'A,D', 'forest work; festival purification; storm set', 'gentleness, ritual caution, lonely humor'],
  hong_meiling: ['star cap, braid, qipao mass and grounded martial stance', 'fists / gate staff', 'braid and leaf layer', 'weight shifts through the feet, braid follows', 'salute, open palm or compact martial explanation', 'A,B,D', 'gate uniform; garden work; formal guard coat', 'warm competence, sleepy humor without incompetence'],
  ichirin_kumoi: ['hooded short figure paired with an enormous cloud-fist silhouette', 'prayer ring', 'Unzan full companion layer', 'her sleeve moves first; Unzan answers a beat later', 'small gesture from Ichirin, huge restrained echo from Unzan', 'A,D', 'temple chores; sailor travel; storm battle', 'practical faith, partnership, competitive confidence'],
  iku_nagae: ['long sleeves, veil-like hat and flowing messenger silhouette', 'fan / lightning ribbon', 'electric scarf and cloud layer', 'sleeves drift on a slow wave independent of feet', 'fan opens once; weather line answers the cadence', 'C,D', 'messenger formal; storm gear; Heaven reception', 'polite distance, warning, subtle amusement'],
  joon_yorigami: ['fur collar, fashionable bow, handbag/fan and hip-forward stance', 'purse / fan / coins', 'coin sparkle and accessory layer', 'coin flips with practiced indifference', 'hand on hip, fan snap, then a glance at the cost', 'B,C', 'luxury set; stripped-down penance set; festival fashion', 'swagger, appraisal, flashes of insecurity'],
  junko: ['vast hair mass, crown/halo geometry, long purified robe and orbs', 'purification orb', 'aura and orb layer', 'everything holds except one perfectly regular orb', 'one hand rises; surrounding clutter disappears rather than explodes', 'C,D', 'lunar conflict robe; quiet post-conflict mantle', 'purity, grief held at distance, frightening clarity'],
  kaguya_houraisan: ['floor-length hair column, layered sleeves and absolute stillness', 'fan / impossible treasure', 'treasure and hair-end layer', 'only the clock/fan moves; body remains composed', 'fan opens by one step or a sleeve reveals a treasure cue', 'B,C,D', 'indoor loungewear; twelve-layer formal; moonlit game set', 'playful intellect, boredom, ageless vulnerability'],
  kanako_yasaka: ['huge shimenawa ring, broad sleeves and onbashira verticals', 'onbashira / sacred rope', 'rope ring and pillar layer', 'rope tassels settle while she holds a public pose', 'one pillar mark or broad sleeve gesture frames the argument', 'A,B,D', 'shrine work; summit storm coat; festival formal', 'executive confidence, strategic warmth, divine scale'],
  kasen_ibaraki: ['twin buns, one bandaged arm, fitted Chinese dress and animal accents', 'staff / bandaged arm', 'animal companion and bandage layer', 'bandage curl moves while posture stays corrective', 'an animal reacts to what she refuses to say directly', 'A,C', 'hermit workwear; shrine visit cloak; sealed-arm event set', 'admonition, care, concealed identity'],
  keiki_haniyasushin: ['sculptor-goddess crown, robe apron and haniwa ranks', 'chisel / clay figure', 'haniwa formation layer', 'one haniwa adjusts while she studies the silhouette', 'sculpts a tiny correction as the verbal emphasis', 'B,C,D', 'studio apron; Primate Garden formal; battle kiln set', 'creator pride, protection, artistic judgment'],
  keine_kamishirasawa: ['teacher cap or horned form, book and upright village-guardian stance', 'history book / chalk', 'page and horn-form layer', 'turns one page, pauses to listen outside', 'points to text or corrects a date with a small chalk gesture', 'A,B,C', 'school work; night guard; hakutaku event form', 'teacherly patience, vigilance, embarrassment'],
  koakuma: ['small bat wings, bob hair, pointed tail and book-carrying silhouette', 'book stack / library key', 'wings and tail layer', 'balances books; wing tips correct the weight', 'peeks around the stack, then offers the relevant volume', 'B', 'archive work; dust mask; formal library service', 'busy competence, curiosity, minor-devil mischief'],
  kogasa_tatara: ['asymmetric karakasa outfit dominated by one-eyed umbrella', 'karakasa umbrella', 'umbrella eye/tongue layer', 'umbrella blinks before she moves', 'sudden pop-in gesture followed by checking whether it worked', 'A,C,D', 'rain set; cemetery night; festival repair', 'eagerness to surprise, hurt pride, warmth'],
  koishi_komeiji: ['wide hat, closed third-eye cords and loose wandering dress', 'closed third eye / pebble', 'cord path and subconscious vignette layer', 'a step changes without a preparation frame', 'cords point toward the unspoken subject, not her face', 'C,D', 'surface wanderer; dream archive; quiet garden set', 'untrackable presence, sudden honesty, safety-sensitive distance'],
  komachi_onozuka: ['large scythe, loose uniform and relaxed ferryman lean', 'scythe / coin', 'coin and river-mist layer', 'leans on scythe; coin rolls across knuckles', 'scythe angle stays casual until the moral point lands', 'A,C,D', 'ferry work; Higan formal; rainy river coat', 'leisurely wit, practical mortality, buried diligence'],
  kosuzu_motoori: ['twin braids, bell-like ties, bookstore apron and oversized book', 'youma book / shop ledger', 'page and seal layer', 'book weight shifts; braid follows', 'hugs, opens or reluctantly closes the dangerous book', 'A,B', 'Suzunaan work; festival reader; incident gloves', 'bookish enthusiasm, risk blindness, friendship'],
  marisa_kirisame: ['witch hat, broom diagonal and white apron cut in a black dress mass', 'broom / mini-hakkero', 'hat ribbon, broom and spark layer', 'hat tips after the body; fingers tap the broom', 'forward hand gesture as if the conclusion is obvious', 'A,B,D', 'rain cape; soot-covered lab set; festival magician', 'confidence, caught-in-the-act humor, private quiet'],
  mayumi_joutouguu: ['haniwa armor, helmet crest and disciplined sword line', 'sword / bow', 'haniwa rank layer', 'military cadence and exact equipment check', 'salute or tactical point; no casual flailing', 'B,D', 'garden patrol; ceremonial armor; damaged haniwa set', 'loyalty, directness, learning individuality'],
  minamitsu_murasa: ['sailor cap, anchor line and water-broken lower silhouette', 'anchor / ladle', 'water trail and ghost wake layer', 'one drip falls from the anchor while she floats', 'anchor tilts like punctuation; grin stays restrained', 'A,D', 'temple chores; captain coat; stormwreck set', 'seamanship, dark humor, belonging'],
  momiji_inubashiri: ['wolf ears/tail, round shield and scimitar patrol silhouette', 'shield / blade', 'ear and tail layer', 'ears scan opposite directions before the shield shifts', 'shield tap or map-pointing gesture', 'A,D', 'mountain patrol coat; off-duty scarf; storm lookout', 'professional caution, territorial pride, dry camaraderie'],
  mononobe_no_futo: ['small cap, Taoist robe, plates and boat/fire geometry', 'plate / ritual vessel', 'plate orbit and flame layer', 'one plate spins with old-fashioned ceremony', 'broad archaic gesture that nearly loses a plate', 'A,B,D', 'mausoleum work; festival robe; fire ritual set', 'archaic confidence, literalism, competitive zeal'],
  nazrin: ['mouse ears/tail, dowsing rods and pendulum triangle', 'dowsing rods / pendulum', 'tail and pendulum layer', 'pendulum moves while eyes remain skeptical', 'rods cross or point to the actual evidence', 'A,B', 'temple errands; cave search coat; market disguise', 'pragmatism, appraisal, understated loyalty'],
  nitori_kawashiro: ['cap, large backpack, wrench and pipe/gadget silhouette', 'wrench / optical device', 'backpack valves and camouflage layer', 'one valve spins; backpack weight shifts', 'unfolds a schematic or demonstrates a mechanism too close', 'A,B,D', 'work overalls; rain gear; market sales set', 'engineering delight, sales instinct, social caution'],
  nue_houjuu: ['trident, asymmetrical wings and deliberately conflicting shape language', 'trident / unidentified seed', 'UFO/seed and shifting-wing layer', 'one side of the silhouette changes category', 'trident stays still while a companion shape lies about its form', 'C,D', 'temple casual; night scare; identified/quiet set', 'teasing ambiguity, loneliness, guarded affiliation'],
  okina_matara: ['seated divine silhouette, large fans and rectangular backdoor/mandala', 'fan / backdoor', 'door, dancers and seasonal aura layers', 'door aperture changes while she remains absolutely composed', 'fan snap changes the stage rather than her posture', 'B,C,D', 'sage formal; seasonal door sets; final-act stage', 'theatrical authority, testing, concealed care'],
  patchouli_knowledge: ['mob cap, crescent ornament, layered robe and book block', 'grimoire / elemental glyph', 'book and glyph layer', 'page turns while the body barely floats', 'one finger marks the relevant line; breath remains economical', 'B,C,D', 'reading glasses; blanket/library set; ritual robe', 'dry intellect, physical limitation, private sincerity'],
  ran_yakumo: ['fox ears, hat, nine-tail fan and formal shikigami posture', 'charm / calculation scroll', 'nine tail layers and formula glyph', 'tails move in a slow solved pattern', 'writes a formula in air or redirects one tail toward the task', 'A,B,C', 'household work; boundary patrol; formal shikigami', 'competence, calculation, household tenderness'],
  reimu_hakurei: ['oversized hair bow, detached sleeve masses, grounded skirt and gohei', 'gohei / yin-yang orb', 'bow, sleeves and orb layer', 'sleeve settles, then one bow lobe lags a pixel', 'small gohei lift; warmth remains logistical rather than performative', 'A,C,D', 'winter shrine coat; work apron; rain mantle', 'dry neutrality, irritation, restrained sincerity'],
  reisen_udongein_inaba: ['very long rabbit ears, blazer/skirt geometry and alert military posture', 'finger-gun / medicine case', 'independent ear and wavelength layer', 'ears disagree about the direction before she corrects them', 'one ear drops while the hand delivers a precise correction', 'B,D', 'clinic assistant; lunar uniform; forest patrol', 'discipline, anxiety, sharp humor, relief'],
  remilia_scarlet: ['tiny body, cap, bat wings and exaggerated authority/spear line', 'Gungnir / parasol', 'wing and fate-thread layer', 'wings hold a throne-like triangle while one foot hovers', 'spear or finger makes a grand claim; body remains small and certain', 'B,C,D', 'parasol day set; throne cape; night formal', 'command, theatricality, private dependence'],
  rin_kaenbyou: ['cat ears, twin braids/tails and wheelbarrow/ghost-fire shapes', 'wheelbarrow / corpse cart', 'two tails and spirit flame layer', 'tail flame lifts while hands stay on the cart', 'leans on the handle; spirits react to the joke', 'D', 'work dress; surface visit; furnace-rescue set', 'cheerful morbidity, loyalty, work pride'],
  rinnosuke_morichika: ['glasses, long shop coat/apron and rectangular outside-world object', 'unidentified tool / book', 'object label and lens-glint layer', 'adjusts glasses after examining the object, not before', 'turns the object to show one wrong-but-plausible function', 'A,B', 'shop work; field salvage coat; formal merchant', 'calm expertise, blind spots, gentle stubbornness'],
  sagume_kishin: ['single wing, short lunar silhouette and hand held near the mouth', 'tablet / arrow motif', 'single wing and reversal-text layer', 'wing freezes whenever she almost speaks', 'one minimal gesture replaces a sentence; text card may reverse after', 'B,C,D', 'lunar formal; battlefield cloak; dream interference', 'restraint, consequence-aware tension, oblique trust'],
  saki_kurokoma: ['horse ears/tail, broad athletic stance and coat/wing speed wedges', 'kick arc / reins motif', 'tail and dust layer', 'hoof tap and forward shoulder; no dainty bounce', 'wide grin, thumb toward the next challenge', 'A,D', 'Keiga patrol; racing scarf; formal faction coat', 'straightforward rivalry, speed, respect'],
  sakuya_izayoi: ['maid headpiece, triangular skirt, white apron axis and knife/watch lines', 'knife fan / pocket watch', 'headpiece, watch and knife layer', 'checks one minute with almost no body motion', 'precise hand rise; knife fan only when context warrants', 'A,B,D', 'rolled kitchen sleeves; formal tailcoat; rain service coat', 'professional neutrality, dry humor, private fatigue'],
  sanae_kochiya: ['long hair, frog/snake ornaments, open sleeves and gohei', 'gohei / miracle glyph', 'hair ornament and wind layer', 'ornaments move out of phase with a buoyant but controlled posture', 'open two-handed gesture, then earnest correction', 'A,B,D', 'Outside World casual; festival promoter; storm shrine coat', 'enthusiasm, cultural mismatch, sincere responsibility'],
  satori_komeiji: ['third-eye heart, looping cords and compact indoor posture', 'third eye / book', 'eye and cord path layer', 'third eye blinks before her own eyes react', 'cords lean toward the thought she chooses not to expose', 'B,C,D', 'palace work; animal-care apron; surface cloak', 'measured reading, loneliness, consent-aware restraint'],
  seiga_kaku: ['ornate hairpin, long dress and body partially crossing a wall/frame', 'hairpin / wall chisel', 'wall-cut and Yoshika link layer', 'one edge of her body ignores the frame boundary', 'fan/hairpin gesture invites trouble with immaculate calm', 'C,D', 'hermit formal; mausoleum work; wall-passage set', 'charm, moral slipperiness, amused manipulation'],
  shion_yorigami: ['tattered hood/dress, drooping cloth and empty negative-space aura', 'cracked charm / empty bowl', 'misfortune haze and torn-cloth layer', 'cloth sinks a pixel after the body already stopped', 'small hesitant hand; surrounding objects lose one decorative pixel', 'C,D', 'wandering rags; repaired festival set; Tenshi travel set', 'self-effacement, hunger, loyalty, fragile hope'],
  suika_ibuki: ['oni horns, gourd, chain arcs and compact powerful stance', 'gourd / chain', 'mist and density-clone layer', 'takes a sip without moving the gourd level incorrectly', 'chain clink or mist cluster punctuates a teasing line', 'A,C,D', 'shrine guest; festival coat; mist-body battle', 'boisterous perception, loneliness, honest challenge'],
  sumireko_usami: ['glasses, occult cape/hat and smartphone/card rectangles', 'smartphone / ESP card', 'psychic object and screen layer', 'phone scroll and floating card move independently', 'pushes glasses, presents evidence, then overcommits', 'A,B,C,D', 'school uniform; dream explorer; winter Outside World', 'modern sarcasm, excitement, outsider vulnerability'],
  suwako_moriya: ['frog-eye hat, compact crouch and iron ring circles', 'iron ring / frog glyph', 'hat-eye and water layer', 'hat eyes blink separately while she stays low', 'crouched hand gesture or one ring rolling into frame', 'A,C,D', 'shrine casual; ancient ritual; rainy field set', 'playful antiquity, local authority, elusive seriousness'],
  tenshi_hinanawi: ['peach hat, keystone block and long weather-sword line', 'Sword of Hisou / keystone', 'peach, stone and weather layer', 'hip/shoulder line boasts while the keystone stays heavy', 'sword points at the sky or self; one beat exposes insecurity', 'A,C,D', 'Heaven formal; street-food disguise; storm battle', 'arrogance, boredom, craving recognition'],
  tewi_inaba: ['rabbit ears, compact dress and trap/coin shapes hidden near the feet', 'luck charm / trap / coin', 'ear and hidden-trap layer', 'ears twitch toward opportunity, not sound', 'coin vanishes between hands while the smile stays innocent', 'A,B', 'Eientei errands; festival vendor; forest prank set', 'calculation, playfulness, community longevity'],
  toyostomimi_no_miko: ['earmuffs, cape triangle and ritual sword/tablet line', 'shaku / sword', 'voice-wave and cape layer', 'earpieces pulse as multiple voices arrive', 'one precise cape opening frames a public declaration', 'B,C,D', 'Senkai formal; public audience; battle regalia', 'charisma, listening overload, strategic compassion'],
  utsuho_reiuji: ['one heavy wing, control-rod arm, cape and miniature sun circle', 'control rod / sun', 'wing, reactor eye and sun layer', 'reactor pulse changes while stance remains proudly open', 'control rod sweeps too far, then corrects with earnest focus', 'D', 'furnace work; surface coat; full reactor battle', 'simple confidence, dangerous scale, loyalty'],
  watatsuki_no_toyohime: ['long lunar hair, broad refined robe and folding fan', 'fan / peach', 'spatial cut and wave layer', 'fan stays closed while a distant line of space shifts', 'fan opens one segment to end the discussion', 'B,C,D', 'lunar household formal; Earth visit; sea-parting set', 'courtesy, overwhelming capability, family authority'],
  watatsuki_no_yorihime: ['lunar military robe, tied hair and disciplined sword silhouette', 'sword / divine invocation', 'deity crest and blade layer', 'breath and sword hand move in exact cadence', 'one formal hand sign precedes any drawn blade', 'B,D', 'lunar command; Earth duel; shrine invocation set', 'discipline, certainty, respectful severity'],
  yachie_kicchou: ['antlers, turtle-dragon tail and elegant command posture', 'fan / command seal', 'tail and faction-emblem layer', 'tail curls while the upper body remains diplomatically still', 'one finger or fan edge redirects the room', 'B,D', 'Kiketsu formal; negotiation cloak; battlefield command', 'soft-spoken control, pressure, strategic courtesy'],
  yoshika_miyako: ['jiang-shi cap/talisman, stiff forward arms and heavy hopping feet', 'forehead talisman', 'talisman and hunger cue layer', 'small rigid sway, then one delayed jaw movement', 'simple hand/jaw motion; humor never erases dependence or safety', 'C,D', 'mausoleum guard; repaired talisman; rain-stiff set', 'literal hunger, loyalty, safety-sensitive comedy'],
  youmu_konpaku: ['short hair, twin sword lines and half-phantom comma', 'long and short swords', 'half-phantom companion layer', 'hand checks the sheath while phantom drifts late', 'disciplined bow or one sharp sheath tap', 'A,C,D', 'gardening sleeves; festival hakama; mourning formal', 'duty, earnest confusion, restrained feeling'],
  yukari_yakumo: ['mob cap/ribbons, parasol or fan and unmistakable gap rectangle', 'parasol / fan / gap', 'gap eyes and boundary layer', 'a gap opens before she visibly acknowledges it', 'fan closes or a border shifts instead of a large gesture', 'A,B,C,D', 'day parasol; sage formal; dream conductor set', 'playful distance, old responsibility, selective sincerity'],
  yuugi_hoshiguma: ['single horn, chains, sake bowl and broad grounded shoulders', 'sake bowl / fist', 'chain and impact layer', 'bowl remains perfectly level during a weight shift', 'open laugh, bowl offer or compact fist emphasis', 'A,D', 'Former Hell casual; feast formal; arena battle', 'honesty, strength, hospitality, testing respect'],
  yuuka_kazami: ['parasol, long hair, plaid/flower dress and sunflower vertical', 'parasol / flower', 'petal and stem layer', 'near-total stillness; nearby flower turns first', 'parasol angle changes by one step, making politeness feel dangerous', 'A,C,D', 'garden work; rain parasol; old-style dream silhouette', 'courtesy, menace, aesthetic patience'],
  yuyuko_saigyouji: ['mob cap, broad sleeve cloud, butterfly hem and folding fan', 'fan / meal tray', 'ghost, butterfly and sleeve layer', 'lower body drifts while fan stays almost still', 'fan arc hides a joke or briefly reveals mourning stillness', 'A,C,D', 'meal tray; deep-night mourning; festival formal', 'playful appetite, insight, grief beneath ease'],
};

function tierFor(character) {
  const scope = character.route_scope;
  if (/Deep route|launch fighter|danmaku lead/.test(scope)) return 'A';
  // fighter_system.md names Reisen in the first expansion even though roster.json
  // currently describes her narrative scope only as "Support route".
  if (character.id === 'reisen_udongein_inaba') return 'B';
  if (/Major support|fighter expansion|Late-game|late-game|romance-ready|duel/.test(scope)) return 'B';
  return 'C';
}

function budgetFor(tier, scope) {
  if (tier === 'A') return { S: '2 idle + 4 walk + 2 interact', M: '4 idle + 8 walk + 4 talk + 6 interact + 4 reaction', L: 'full fighter/danmaku key set', portraits: 9 };
  if (tier === 'B') return { S: '2 idle + 4 walk', M: '4 idle + 4 walk + 4 talk + 2 reaction', L: /fighter|duel|antagonist/.test(scope) ? '8–16 boss/fighter key poses' : '4–8 dramatic poses', portraits: 6 };
  return { S: '2 idle', M: '2 idle + 4 walk + 2 talk/gesture', L: /antagonist/.test(scope) ? '4 boss silhouettes' : 'not required at launch', portraits: 3 };
}

const missing = roster.filter((c) => !V[c.id]);
const extra = Object.keys(V).filter((id) => !roster.some((c) => c.id === id));
if (missing.length || extra.length) throw new Error(`visual map mismatch: missing=${missing.map((x) => x.id)} extra=${extra}`);

fs.mkdirSync(path.join(OUT, 'briefs'), { recursive: true });

const catalog = roster.map((character) => {
  const [silhouette, prop, companion, idle, talk, profiles, variants, portrait] = V[character.id];
  const tier = tierFor(character);
  return {
    ...character,
    production_tier: tier,
    silhouette_key: silhouette,
    primary_prop: prop,
    companion_or_fx_layer: companion,
    idle_signature: idle,
    talk_signature: talk,
    profile_affinity: profiles.split(','),
    costume_event_variants: variants,
    portrait_emphasis: portrait,
    animation_budget: budgetFor(tier, character.route_scope),
    shared_model: { S: [16, 24], M: [24, 32], L: [32, 48], portrait: [80, 104] },
    required_tests: ['solid silhouette', 'white field', 'inverted field', '1x peripheral read', 'anchor loop', 'no copied sprite geometry'],
  };
});

fs.writeFileSync(path.join(OUT, 'character_model_catalog.json'), `${JSON.stringify({ schema_version: 2, characters: catalog }, null, 2)}\n`);

const csvHeader = ['id','name_en','name_ja','production_tier','region','route_scope','silhouette_key','primary_prop','companion_or_fx_layer','idle_signature','talk_signature','profile_affinity','costume_event_variants','portrait_emphasis','model_s','model_m','model_l','portrait_count'];
function q(value) { return `"${String(value).replaceAll('"', '""')}"`; }
const csvRows = catalog.map((c) => [c.id,c.name_en,c.name_ja,c.production_tier,c.faction_region.trim(),c.route_scope.trim(),c.silhouette_key,c.primary_prop,c.companion_or_fx_layer,c.idle_signature,c.talk_signature,c.profile_affinity.join('/'),c.costume_event_variants,c.portrait_emphasis,c.animation_budget.S,c.animation_budget.M,c.animation_budget.L,c.animation_budget.portraits].map(q).join(','));
fs.writeFileSync(path.join(OUT, 'character_model_catalog.csv'), `${csvHeader.map(q).join(',')}\n${csvRows.join('\n')}\n`);

const md = ['# Complete Character Modeling Catalog', '', 'All 71 roster entries share S 16×24, M 24×32, L 32×48 and 80×104 portrait anchors. Tier controls production volume, not narrative importance.', '', '| Tier | Count | Launch budget |', '|---|---:|---|'];
for (const tier of ['A','B','C']) md.push(`| ${tier} | ${catalog.filter((c) => c.production_tier === tier).length} | ${tier === 'A' ? 'full route/playable set' : tier === 'B' ? 'regional/major set' : 'support/cameo set'} |`);
md.push('', '| Character | Tier | Silhouette | Prop / layer | Idle / talk | Profiles |', '|---|---:|---|---|---|---|');
for (const c of catalog) md.push(`| ${c.name_en}<br>${c.name_ja} | ${c.production_tier} | ${c.silhouette_key} | ${c.primary_prop}; ${c.companion_or_fx_layer} | ${c.idle_signature}; ${c.talk_signature} | ${c.profile_affinity.join('/')} |`);
md.push('');
fs.writeFileSync(path.join(OUT, 'character_model_catalog.md'), md.join('\n'));

for (const c of catalog) {
  const lines = [
    `# ${c.name_en} — Production Modeling Brief`, `## ${c.name_ja}`, '',
    `- **Production tier:** ${c.production_tier}`,
    `- **Region / faction:** ${c.faction_region.trim()}`,
    `- **Route scope:** ${c.route_scope.trim()}`,
    `- **Source character contract:** \`${c.skills_path}\``, '',
    '## Silhouette lock', '', c.silhouette_key, '',
    `- Primary prop: ${c.primary_prop}`,
    `- Separate child/FX layer: ${c.companion_or_fx_layer}`,
    `- Preferred presentation profiles: ${c.profile_affinity.join(', ')}`, '',
    '## Motion lock', '',
    `- Idle: ${c.idle_signature}.`,
    `- Talk/gesture: ${c.talk_signature}.`,
    '- Walk must return to the same feet anchor; accessory lag occurs after torso motion, not on every pixel.',
    '- Face detail is secondary to hat/head shape, sleeves, weapon, stance and companion object.', '',
    '## Asset budget', '',
    `- Model S 16×24: ${c.animation_budget.S}`,
    `- Model M 24×32: ${c.animation_budget.M}`,
    `- Model L 32×48: ${c.animation_budget.L}`,
    `- Portrait 80×104: ${c.animation_budget.portraits} expressions/working states`, '',
    '## Portrait direction', '', c.portrait_emphasis, '',
    'Portraits require at least one working neutral and one non-romantic positive state. Tier A adds amused, irritated, focused, startled, tired/private, sincere-restraint and route-specific vulnerability.', '',
    '## Costume / event variants', '', c.costume_event_variants, '',
    'Variants reuse anchors but may replace the silhouette. Never clip a long skirt or large sleeve onto an incompatible skeleton.', '',
    '## 1-bit rules', '',
    '- Visible pixels are #000000 or #FFFFFF; ordered dither is a material region, never facial antialiasing.',
    '- Validate on white and inverted fields. If inversion merges the prop into the body, author an inverted override.',
    '- Test at 1× in peripheral vision and as a solid silhouette.',
    '- Do not trace official or fan sprites; identity comes from original pixel construction around canonical accessories.', '',
    '## Acceptance', '', ...c.required_tests.map((test) => `- [ ] ${test}`), '',
  ];
  fs.writeFileSync(path.join(OUT, 'briefs', `${c.id}.md`), lines.join('\n'));
}

const coreOrder = [
  'reimu_hakurei', 'marisa_kirisame', 'sakuya_izayoi',
  'youmu_konpaku', 'yuyuko_saigyouji', 'patchouli_knowledge',
  'remilia_scarlet', 'eirin_yagokoro', 'kaguya_houraisan',
  'aya_shameimaru', 'sanae_kochiya', 'tenshi_hinanawi'
];
const coreRank = new Map(coreOrder.map((id, i) => [id, i]));
const queue = [...catalog].sort((a, b) => {
  const ar = coreRank.has(a.id) ? coreRank.get(a.id) : 999;
  const br = coreRank.has(b.id) ? coreRank.get(b.id) : 999;
  return ar - br || a.production_tier.localeCompare(b.production_tier) || a.name_en.localeCompare(b.name_en);
});
const queueMd = ['# Character Art Production Queue', '', 'Lock Reimu, Marisa and Sakuya through import and in-game QA first. Then complete the remaining Tier A route/playable set before regional Tier B and support Tier C. Tier is an asset budget, not a statement of story value.', '', '| Order | Character | Tier | First proof asset | Dependency |', '|---:|---|---:|---|---|'];
queue.forEach((c, i) => queueMd.push(`| ${i + 1} | ${c.name_en} | ${c.production_tier} | ${c.production_tier === 'A' ? 'M idle/walk/talk + portrait neutral' : c.production_tier === 'B' ? 'M idle + regional gesture' : 'S idle + one M gesture'} | ${c.companion_or_fx_layer} |`));
queueMd.push('');
fs.writeFileSync(path.join(OUT, 'production_queue.md'), queueMd.join('\n'));

console.log(`Built ${catalog.length} character modeling briefs: A=${catalog.filter((c)=>c.production_tier==='A').length}, B=${catalog.filter((c)=>c.production_tier==='B').length}, C=${catalog.filter((c)=>c.production_tier==='C').length}`);
