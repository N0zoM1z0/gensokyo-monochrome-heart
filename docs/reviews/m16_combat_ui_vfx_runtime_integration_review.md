# M16 Production Combat, UI, and VFX Runtime Integration Review

Date: 2026-07-17
Decision: approved for the bullet, combat-marker, UI-export, and accessible VFX
runtime gate. Overall M16 acceptance still requires the final cross-system audit.

## Runtime contract

`ProductionCombatVisuals` is the common resolver for the reviewed combat
exports. It keeps the source atlases immutable, caches every derived texture,
and refuses unknown semantic IDs rather than silently substituting a shape.

- All twelve bullet families resolve from the reviewed 96×32 atlas to distinct
  9×9 ink masks and distinct paper-outline masks.
- The thin paper knife receives a source-faithful connected diagonal spine after
  reduction, so it cannot collapse into shot-stream or safe-lane dots.
- The eight Model M sheets resolve to distinct 18×24 combat markers with exact
  A/D polarity reciprocity. Boundary Stain, Missing Minute Knives, and Tomorrow's
  Headline now identify Reimu, Sakuya, and Aya as their production bosses.
- The eight character-specific VFX rows expose all four standard and reduced
  frames. Reduced-flash uses its own authored atlas, not a dimmed standard frame.

Packed simulation and collision data are unchanged. The danmaku renderer still
uses ten MultiMesh batches and never creates a Node per bullet. Its four authored
story families map to production amulet, orb, shard, and knife cells; fighter
projectiles map to production amulet, star, and needle cells. The remaining
families stay available through the shared semantic resolver for later authored
patterns.

Telegraphs are now 11×11 open corner brackets with no center point. The player
uses the production spirit silhouette, a unique diamond focus halo, and the same
existing 2×2 focus core. The photo interaction uses camera-corner brackets
instead of a complete rectangle. These presentation changes leave warning
ticks, hit radii, safe-lane positions, pool capacity, and replay snapshots intact.

## Fighter and accessibility composition

Fighter stress effects use a 15×15 production VFX mask, visually separating
non-colliding effects from 9×9 projectiles. A one-pixel paper knockout is derived
from the active Model L cell in dense scenes, keeping each fighter's head,
torso, and facing readable without changing projectile collision.

Impact composition now records both attacker and target sides. The target point
uses grounded body center plus a twelve-pixel facing-side offset; the earlier
prototype incorrectly treated airborne elevation as body height and could place
the mark at a fighter's feet. Standard impact animates through the standard
atlas and retains the short two-pixel arena stamp. No-flash mode instead holds a
single reduced frame for 0.35–0.40 seconds and never draws the arena stamp or a
full-screen inversion. Frozen screenshot fixtures also freeze this presentation
timer, making standard and safe evidence deterministic.

The reviewed UI export supplies reciprocal A/D textures, three four-pixel
nine-patch frame styles, and confirm/cancel/assist/status icons. Boundary
danmaku uses these frames for its field, title, status rail, and footer, while
result stamps use the semantic icons at their native aspect ratio. The fighter
arena's former empty rectangle was replaced by a non-colliding shrine offering
box with a raised lid, coin slot, timber slats, and boundary seal; dense combat
omits the landmark completely.

## Simulated-player review and corrections

Three independent player perspectives reviewed native 320×180 A/D,
English/Japanese, standard/safe-flash, normal-density, projectile-only, and
engineering-stress captures.

- `sanae_player_review` initially blocked the telegraph/focus look-alike, broken
  paper-knife diagonal, and bullet-sized stress effects. Open brackets, the
  spirit/diamond player grammar, connected knife mask, larger VFX, and a separate
  128-projectile readability fixture closed every blocker. Final decision: PASS.
- `eirin_consent_player_review` initially could not prove that standard and
  reduced hit VFX were present or distinct. Frozen timing, corrected body-center
  placement, a representative fixture frame, and static safe-flash behavior
  made both modes visible without unsafe border or full-screen flashes. Final
  decision: PASS.
- `remilia_player_review` initially blocked debug-like danmaku actors, dense
  fighter silhouette loss, and the empty fighter landmark. Production Model M
  bosses, the spirit player, paper knockout, camera brackets, refined result
  mark, and shrine offering box closed the remaining production-readiness
  issues. Final decision: PASS.

## Automated evidence

- Unit suite: 36 suites, 0 failures. Contracts cover twelve unique ink and paper
  masks, connected knife geometry, distinct telegraph/player centers, all
  8×4×2 VFX cells, eight reciprocal Model M markers, UI palette reciprocity,
  frame margins, icons, and unsupported-ID refusal.
- Content database: revision `2026.07.17.1`, hash
  `ee671b230f388763ab81de228f94714ccc0d3187ee94525c962d9e3684a5399e`;
  71 characters, 19 locations, 104 events, 713 beats, 2,065 strings, 89 cues,
  and 1,720 nodes; 0 errors and 0 warnings.
- M07 Boundary Stain, M08 fighter, M12 Scarlet Devil Mansion, and M13 Tomorrow's
  Headline integration flows: 0 failures each.
- Pixel alignment: 5 relevant scenes, 0 errors. Generated screenshot one-bit
  validation: 0 errors.
- Release validation: 1,084 files, 0 errors; provenance remains 63 registered /
  63 discovered. M16 coverage remains 33 visual and 27 audio assets, including
  all 8 fighters, 5 regions, and 12 bullet families.
- Fighter llvmpipe stress: 2 fighters, 128 projectiles, 40 production effects,
  p95 10.760 ms against 16.67 ms.
- Danmaku llvmpipe stress: 2,500 source and visible bullets with zero structural
  failure; three p95 samples were 29.595, 31.740, and 32.085 ms. This remains the
  documented software-rasterizer bottleneck, but improves on the recorded
  35.378–42.020 ms MultiMesh baseline. The fixture continues to report
  `within_budget: false` honestly pending target-GPU evidence.

## Remaining scope

This approval closes the production bullet, UI-export, and standard/reduced VFX
runtime composition gates. It does not by itself declare all of M16 complete;
the next phase is the final cross-system audit of release evidence, remaining
scope statements, credits/provenance, and the complete verification matrix.
