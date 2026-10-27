# Motion A v1 — delivered raster contract

Generated with the built-in image_gen tool, preserving the accepted simple A hero: green leaf hood/hair, cyan eye, cream petal cape, silver near leg and green far leg. Full prompt: `art/motion_a_v1_prompt.txt`. The raw generated source remains `assets/motion_a_v1.png` (1402 × 1122 RGBA). It is not a regular cell grid. Runtime MUST consume the prepared native atlas instead.

## Runtime contract

`assets/motion_a_native_v1.png`: **256 × 160 RGBA**, regular 4 columns × 4 rows. Each cell is **64 × 40 native pixels**. Source-to-native scale is uniformly 1/8, nearest neighbor. No pose-specific resizing. Transparent alpha is thresholded at128. No frame includes neighboring poses.

All frames face RIGHT. Fixed anatomical ground pivot **(32,36)** in every cell. At game SCALE4 and centered Sprite2D, use **position=(0,-64)** and ordinary flip_h. Ground baseline is y36, independent of nontransparent bounds. Do not call the old alpha-dependent offset_y for these frames. Prayer stays on its existing asset and baseline path.

Scale matches current A: ordinary running silhouette34×26native pixels, idle31×28native. The body/head retain one uniform sampling scale. Attack/dash/crouch alter posture rather than resize anatomy. Active attack extends to native x59, 27native pixels/108gamepixels right of anchor, close to the104gamepixel damage reach.

## Frame map and measured native opaque bounds

Coordinates below are (x,y,width,height), relative to the cell. Cell origin is ((index%4)*64, floor(index/4)*40). Bounds are informational only; use entire cell.

| Index | State | Cell origin | Opaque bounds | Interpretation |
|---|---|---|---|---|
|0|run0|(0,0)|(17,10,34,26)|Silver leg forward contact, green behind|
|1|run1|(64,0)|(18,11,34,25)|Silver leg down/support, green leg folding|
|2|run2|(128,0)|(18,10,33,26)|Passing, silver near vertical and green swinging|
|3|run3|(192,0)|(17,10,34,25)|Green extends forward, silver folds backward; airborne one nativepixel|
|4|run4|(0,40)|(18,10,34,26)|Opposite contact: green forward, silver backward|
|5|run5|(64,40)|(18,11,34,25)|Green support/down, silver recovering|
|6|run6|(128,40)|(18,9,34,27)|Passing with silver knee clearly raised forward|
|7|run7|(192,40)|(18,9,33,26)|Silver extends forward, green folds backward; airborne one nativepixel|
|8|attack_windup|(0,80)|(17,10,30,26)|Sword drawn upward behind head; hand attached|
|9|attack_active|(64,80)|(16,14,43,22)|Low forward lunge; sword horizontal right, connected extended arm|
|10|attack_recover|(128,80)|(19,12,33,24)|Sword lowers diagonally right; body rises|
|11|dash|(192,80)|(20,17,33,18)|Low horizontal body, cape streams left, feet tucked|
|12|rise|(0,120)|(17,6,33,24)|Knees tucked up, cape down-left; feet6nativepixels abovegroundpivot|
|13|fall|(64,120)|(16,6,34,27)|Legs hang downward separated, cape lifts; feet3nativepixels abovegroundpivot|
|14|land/crouch|(128,120)|(18,15,36,21)|Bent knees, lowered torso, sword forward/down|
|15|idle|(192,120)|(17,8,31,28)|Upright relaxed stance, sword down-right|

## Raw generation measurements and preparation

`art/prepare_motion_a_v1.py` reproduces nativeatlas and previews. Every isolated source region is pasted into a clear temporary canvas before fixed512×320 crop/downsample to64×40, preventing adjacent silhouettes from leaking into runtime. Source regions/anchors are recorded in that file. Anchors track body/hip position; they are not the center of sword+cape opaque bounds. Contact0/4 align to y36; flight3/7 one nativepixel higher; other leg movements retain authored variation. No assets of prayer, enemies, platforms, or scenery were modified.

Preview: `art/motion_a_native_preview.png` at4× nearest and `art/motion_a_run_preview.gif` eightframes,80ms/frame. The GIF is a raster pose preview, not evidence of engine integration or timing. Independent engine review remains required for actual transitions, foot contact, clipping, attack timing and apparent anatomy. Suggested integration uses distance-driven run at 8 distinct phases, attack windup45ms/active45–145ms/recovery145–230ms, short landing pose before returning to idle or run. Land doubles as crouch; do not use prayer to depict crouching.

## Inspection outcome and limits

Native preview shows alternating silver/green leading legs and changing knees, cape silhouette and body height. Jump,fall,dash andland are distinct. Attack preparation,extension,recovery are attached to the arm. Original generated art slightly varies head/hair outline between poses; use shared palette simplification as current A renderer does, without per-frame geometry normalization. This document asserts raster inspection only. Reviewer/fixer must assess engine sequence and can request a targeted art revision.
