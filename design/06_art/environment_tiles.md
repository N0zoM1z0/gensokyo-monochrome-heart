# Environment Tile and Region Grammar

## 1. Tile standards

Base tile: 16 × 16 px.
- collision tiles use a solid 2 px top edge;
- decorative seams must not resemble collision edges;
- one-way platforms use broken 2-1 rhythm;
- interactable objects have a 1 px “paper glint” on the camera-facing side;
- ladders, doors, and exits receive unique negative-space shapes.

Each region ships:
- terrain atlas;
- architecture atlas;
- prop atlas;
- foreground mask atlas;
- weather overlay;
- memory-corruption overlay;
- at least one calm and one incident palette-polarity composition.

## 2. Headline regions

### Hakurei Shrine
Visual nouns: long horizontal veranda, worn wood, donation-box slats, rope zigzags, empty sky, old tree. Negative space is essential. The shrine should feel poor in possessions but rich in breathing room.

### Scarlet Devil Mansion
Visual nouns: tall doors, repeating clocks, checker floors, arched windows, dense library shelves, hard kitchen geometry. Repetition can become uncanny by changing one tile per loop.

### Youkai Mountain
Visual nouns: diagonal wind strokes, layered waterfalls, rope bridges, leaf triangles, machinery pipes, newspaper scraps. Paths should visibly cross but remain socially gated.

### Eientei / Bamboo Forest
Visual nouns: vertical bamboo bars, moon circles, corridor grids, paper screens, medicine drawers. Direction is difficult because similar tiles shift one or two pixels between loops.

### Hakugyokurou
Visual nouns: immense stairs, white petal particles, clipped garden curves, open black sky, translucent soul trails. The garden is orderly but never sterile.

## 3. Secondary region hooks

- Human Village: awning rhythms, notice boards, changing crowd silhouettes.
- Forest of Magic: mushroom caps, crooked trunks, clutter silhouettes, fog dithers.
- Misty Lake: horizontal water breaks and giant empty reflection zones.
- Former Hell: brick arches, pipes, furnace circles, cart rails.
- Myouren Temple: ship curves, bells, wooden columns, communal clutter.
- Senkai: impossible perspective doors, plate motifs, clean cloud fields.
- Heaven: broad cloud platforms, peaches, floating keystone shadows.
- Higan: river horizon, coin/ferry motifs, flower bands, judgment desk geometry.
- Lunar Capital: clinical circles, repeating flawless tiles, almost no texture until “impurity” appears.
- Animal Realm: harsh vertical megastructures, haniwa formations, faction emblems.
- Hidden Back Doors: ordinary backgrounds with rectangular absences and reversed depth.

## 4. Interactive readability

Every interactive class has a shape language:
- `Observe`: single 2 × 2 sparkle and slight outline break;
- `Carry`: double lower handle marks;
- `Repair`: diagonal crack with three segments;
- `Danger`: alternating inverted edge;
- `Rumor`: paper scrap with folded corner;
- `Memory`: incomplete rectangular frame;
- `Companion skill`: icon matching that character's stamp.

## 5. Environmental storytelling budget

Each spot requires:
- one object that changes across chapters;
- one relationship-specific prop;
- one mundane maintenance detail;
- one incident contradiction;
- one quiet afterbeat composition;
- no more than three simultaneous particle systems.

## 6. Export

Tiles export as lossless PNG with no embedded scaling. Atlas metadata records region, collision layer, occlusion, material SFX, and polarity compatibility. Source files remain in the art repository; only exports enter the game repository.
