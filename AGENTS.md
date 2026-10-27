# Mushrooms Deserve to Die

## Direction chosen by the user

Latest explicit user selection: **A — PIXEL SIMPLES**, the LEFT column of art/style_a_reference.png. The right B column is not selected. This overrides revision6's reference direction. Original art/style_reference.png is preserved as historical material. Current environment art uses assets/style_a_forest_candidate_v5.png, style_a_soil_candidate_v4.png and style_a_terrain_candidate_v4.png; actor atlas/motion assets remain approved. Earlier environment rasters are historical and must remain preserved. Use low native resolution, integer nearest4x enlargement, broad pixel clusters, limited shared shades, dark outlines, purple forest, lime moss and cyan/magenta fungi. Do not restore the more detailed earlier atlases or original menu scenery. Preserve larger enemies, differentiated magenta spitter stalks and half-kneeling prayer facing the lotus with both hands on a planted wooden root. A single atlas or passing engine tests is not visual approval. Preserve GDD v2 narrative and the current first-boss scope.

Latest material/combat direction: use run_native_v4.png (12 run poses), idle_native_v3.png (4), attack_native_v5.png (6), actions_native_v3.png (dash3/rise3/fall2/land3/hurt2/crouch2), prayer_native_v3.png (4). All cells96x40 pivot48,36, nearest4x. Run contacts0/6 must alternate the near bright and far dark leading legs, with opposite arm swing. One cycle is184worldpixels (speed310 unchanged; about20 texture changes/s). Preserve matte gray-brown bark with local hero palette, no bronze/gold attack trail, no carried weapon outside attack/prayer. Rigid broad wooden blade appears from the hand and performs a horizontal lateral CUT, not a thrust or vine whip. Poses0/1 windup45ms,2 sole forward active100ms,3/4/5 crossed follow-through recovery85ms. Recovery blade crosses left but causes no rear damage/trail. Neutral horizontal trail center-60 follows active blade. Reach160px and center limits166/236. Prayer has one knee grounded, other raised, hands on planted wood. Backup moveset_aprovado_20261025_001617 must remain untouched. Specs art/RUN_V4_SPEC.md, art/MOTION_CADENCE_V4_SPEC.md and art/ATTACK_V5_SPEC.md; real engine sequence review/sword_v5/. Never present distinct hashes as proof of good gait.

## Review workflow

The user explicitly requested three separate agents for art work: an artist to author raster assets, a reviewer to inspect the result against A in actual engine captures, and a fixer to integrate/correct it. Keep these roles distinct. Review findings must go back through correction and fresh capture/review; do not end the task merely reporting defects. The coordinator runs final checks, preserves saves, packages the result and shows the actual updated game. Report the result concisely rather than narrating each discovered problem to the user.

The user also requested a dedicated testing agent, separate from those three art roles. While the user is playing, run automated progression/save tests in an isolated project/user-data namespace. Never restore an earlier personal save over the user's live progress. Keep editor/game windows available and run the tester headless.

The user approved the current A style and requested a motion artist specifically for animation, fluidity, attack poses and transitions. Preserve that style while improving movement art. Route new motion assets through the separate integrator, visual reviewer and testing agent. Check actual engine sequences with timing/state evidence, not only sprite sheets. Keep anatomical anchors stable, drive running by actual travel, and synchronize sword poses with the existing damage event.

For gameplay or visual changes, apply the installed mushrooms-godot-review skill when available, and read review/REVIEW_GUIDE.md. The project guide is the portable fallback if the personal skill is absent. Record evidence and limits in review/LATEST_REVIEW.md before delivery.

Use the actual Godot engine for verification and captures. Do not treat a passing state-transition test as proof of responsive movement or consistent art. Preserve personal save data when testing. Do not replace the existing art reference or erase prior release ZIPs.

## Launch and prayer delivery requirements

User standing request: after finishing modifications, check whether the playable game for this project is running. If it is not, open it via Launch_Game.ps1/Jogar.cmd and verify the process remains alive for testing. Distinguish the playable window from the editor and isolated QA helpers. If already open, preserve the user's running game and progress; do not close or duplicate it. Mention when reopening is needed to load newer changes.

Always launch via Launch_Game.ps1/Jogar.cmd, which imports changed/new resources even if an older .godot/imported exists. Before delivery, run Launch_Game.ps1 -PrepareOnly on this REAL checkout and then the read-only tests/resource_visibility.gd here (with a dedicated log path). Successful isolated imports alone do not prove the actual user's project can load new PNGs. Never run save/progression tests on the user's active checkout; stationary_prayer.gd enforces MushroomsStationaryPrayerQA for its save tests. Do not close or overwrite the user's live game/save.

Crouching on the floor is stationary, cancels controlled dash and does not queue a refused dash for release. Damage knockback and down+jump platform dropping remain available. activate_lotus must never move player.position; turn facing toward the altar, preserve facing if horizontally aligned, then pray1.4s at the same support. The saved checkpoint remains the lotus position. Prayer artwork base faces RIGHT: keep flip_h=facing<0; use enlarged/pixel evidence, not an ambiguous tiny thumbnail. Both left/right approaches and prayer completion must be captured/tested.

## Current implementation

Main scene: scenes/main.tscn. Scripts build gameplay and HUD at runtime. Tests: tests/verify.gd (progression), tests/movement_review.gd (movement) and tests/review_regressions.gd (review findings). Configure tools through review/run_review.ps1.

Do not require user approval for routine local fixes or screenshots. Report provisional animation work and the need for human playtesting honestly.

## Expanded map contract (revision 14)

Level_data.gd owns WIDTH=13032, six REGIONS, 4 LOTUSES, 8 MEMORIES and 21 ENEMIES. Preserve the original first6516px, old spawn ordering and lotus coordinates for saves. PORTAL_X determines the only arena entrance. New upper/lower loops must remain traversable both ways. Do not reset vertical camera tracking each jump; lower floors650/610 need visibility. Map projection scales from WIDTH and has its own legend; suppress duplicate status text while open. Tests new_map_routes.gd require isolated namespace MushroomsNewMapRoutesQA; never run save tests on personal checkout. Full isolated 16-suite runner and evidence: review/large_map/tester/.

## Environmental cohesion (revision 15)

The approved hero remains the visual anchor. Use compact clusters, shared foreground material/outline, roots of comparable thickness on short and long supports, a quiet purple silhouette background without granular mottling. Artwork/prompt contracts: art/environment_v4/ENVIRONMENT_V4_SPEC.md and FOREST_V5_PROMPT.txt. style_environment.background_world() is320x240 (world960high); background() returns320x180 menu crop at4x. Soil256x128 mirrors at world1024x512 with Yorigin400 to avoid a seam under moss. Terrain root_art128x16 shares the new platform atlas; branch textures keep16rows plus transparent padding. Width710 uses140native source (threshold720); longer platforms use210native. Merge touching/overlapping same-height branches for drawing only; Level colliders stay intact. Review25actual images and motion, not just structure: original renderer passed most structural checks despite incohesive style. Latest separate tests397/397 and visual review in review/art_cohesion/.

## Borders and Cordyceps (revision16)

Ground/cliff edges use a4px stepped outline inset4–12px; retain Level colliders/top coordinates. Surface caps are complete15-native-pixel ends of the short platform, not8px slices through a root. Moss highlight aligns to the solid row and does not project beyond rounded caps. Review01/13actual captures before accepting a border change.

Boss has death_started (clear threats immediately), phase_changed (cancel old hazards), collapse_step, and defeated (after2.6s). Six death textures112x96 share pivot56,88 and uniform source1/5scale; rest pose5 stays visible after reward. Never hide boss merely becausehp<=0. Specs/prompts art/boss_death_v1/. Reward_position is beside corpse260px with wall fallback, never obscuring it; interaction/prayer uses this dynamic point. Keep prayer in place and facing altar, saves only after prayer.

Four existing patterns remain cyclic with distinct tell timings. Fan3/5 is symmetric and starts on target-facing side. Inversion requires grounded vulnerable player; jump/dash counter it, delayed roots remain announced. Phase shift0.9s clears old threats then0.45recovery; no contact damage during this breathing window. Recovery does not drag boss back990. Charge locked target/endpoint preserved. Tests boss_encounter.gd, full isolated runner and natural-input helpers in review/borders_boss/tester/;476checks do not certify human feel. Historical hero/guardian alive texture/pivot hashes must remain unchanged.
