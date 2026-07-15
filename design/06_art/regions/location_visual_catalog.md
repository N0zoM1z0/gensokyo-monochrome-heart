# Complete Location Visual Catalog

All 19 authored locations now have a production profile. Tier changes asset volume, never story importance. Every region is built at 320×180 from 16×16 tiles and four separable depth bands.

| Tier | Regions | Base tiles | Animated props | Background strips |
|---|---:|---:|---:|---:|
| A | 8 | 64 | 12 | 8 |
| B | 7 | 48 | 9 | 6 |
| C | 4 | 36 | 6 | 4 |

| Region | Tier | Profiles | UI stamp | Landmark lock |
|---|---:|---|---|---|
| Animal Realm and Primate Spirit Garden | B | D/B | broken haniwa face inside a square seal | Keiki atelier: a white goddess-shaped gap surrounded by dense black scaffolding |
| Eientei and the Bamboo Forest of the Lost | A | C/D | rabbit ears crossing a medicine vial | Eientei gate appears as a white horizontal cut through a forest of black verticals |
| Forest of Magic and Kourindou | A | A/D | mushroom cap over a price tag | Kourindou window: a bright display grid of objects whose silhouettes never quite match their labels |
| Former Hell and the Palace of the Earth Spirits | A | D/C | third eye above a reactor ring | subterranean sun: concentric white rings held inside a nearly solid black reactor hall |
| Garden of the Sun and Nameless Hill | C | C/A | sunflower split by a lily-of-the-valley bell | one enormous sunflower turns away from the player while every small flower faces them |
| Hakugyokurou | A | C/A | half-phantom curling around a fan | the staircase rises through three depth bands toward a tree too large to fit the frame |
| Hakurei Shrine | A | A/C | yin-yang orb beneath a torii | torii and donation box align for one instant when the boundary is stable |
| Heaven | C | C/D | peach resting on a keystone | a black keystone floats below a white garden whose roots never touch it |
| Hidden Back Doors and Boundary Spaces | B | B/D | open rectangle behind a folding fan | four doors show four seasons while casting one shared black shadow |
| Human Village | A | A/B | open book behind a shop curtain | main crossing: four readable shop signs and one rumor board fit a 320-pixel frame without text collision |
| Lunar Capital and Dream World | B | B/D | crescent inside a sleeping eye | a perfect moon gate casts a soft, anatomically impossible sleeping shadow |
| Misty Lake | B | A/D | ice crystal reflected in a wave | the mansion silhouette appears only through a narrow clear slit in three moving fog bands |
| Moriya Shrine | B | B/A | frog eye and snake curve around an onbashira | shimenawa ring frames a practical waterwheel rather than hiding it |
| Myouren Temple and Cemetery | B | B/C | lotus above a ship anchor | temple facade and ship hull share one contour, readable differently from each side |
| Outside World Dream Theatre | C | B/C | smartphone rectangle behind a stage moon | a city skyline is visibly held up by two backstage braces and one dream thread |
| Sanzu River and Higan | C | C/A | coin balanced on a judge rod | one coin remains perfectly still on the river while every bank line scrolls |
| Scarlet Devil Mansion | A | B/D | clock hand crossing a bat wing | the great clock shows three readable times at three depths, only one belonging to the current room |
| Senkai and the Hall of Dreams' Great Mausoleum | B | B/D | earmuff arc above a ritual plate | a formal stair ascends into a doorway whose back is visibly a floating island |
| Youkai Mountain | A | A/D | tengu feather over a waterfall notch | one waterfall crosses all three depth bands but breaks into different pixel rhythms at each |

## Universal region contract

1. Keep far, middle, play, and foreground bands on separate layers.
2. Place no high-frequency dither behind dialogue, choices, bullets, interact prompts, or focus reticles.
3. Ship CALM, INCIDENT, ROUTE, SEASON, and AFTER overlays without duplicating collision maps unless the design explicitly changes traversal.
4. The region stamp appears on entry cards, map detail, journal tabs, and save thumbnails. It must remain recognizable at 12×12.
5. Every landmark must pass a filled-silhouette recognition test at 80×45 and a gameplay test at 320×180.
