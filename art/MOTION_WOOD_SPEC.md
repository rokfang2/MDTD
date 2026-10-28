# Wooden root hero — material edit v1

## Delivered files

- `assets/motion_wood_v1.png`: built-in image_gen EDIT of accepted `motion_a_v1.png`, original1402×1122 layout retained. Prompt `art/motion_wood_v1_prompt.txt`.
- `assets/motion_wood_native_v1.png`: runtime atlas256×160,4×4 cells of64×40. Uniform nearest1/8 sampling, same anatomical anchors and frame order as approved moveset.
- `assets/prayer_wood_v1.png`: separate built-in image_gen material edit of the existing kneeling prayer,1265×1244. Prompt `art/prayer_wood_v1_prompt.txt`. Input crop saved as `art/prayer_a_reference.png`.
- `assets/prayer_wood_native_v1.png`: one64×40 runtime canvas; opaque25×25 character at(19,11), already normalized facingRIGHT. No additional flip_x at load time.
- `art/prepare_motion_wood_v1.py`: reproducible isolation, uniform crop/nearest preparation, binary alpha threshold128 and previews. This script does no visual recoloring and invents no poses.
- `art/motion_wood_native_preview.png`, `art/motion_wood_run_preview.gif`, `art/prayer_wood_native_preview.png`: raster inspection previews; not engine evidence.

## Unchanged runtime contract

All runtime frames including prayer: fixed anchor **(32,36)**, facingRIGHT, SCALE4, centered Sprite2D position **(0,-64)**. Always use the full64×40 cell and fixed baseline36. Do not center on opaque bounds or resize each pose. Eight run phases, attack/dash/rise/fall/land/idle body gestures and cape gestures preserve the approved set. Old assets remain untouched and backup is managed by coordinator.

Rows0/1: run0–7. Row2: attack_windup,attack_active,attack_recover,dash. Row3: rise,fall,land/crouch,idle. Same frame indices0–15 as prior atlas. All arms/legs now green; formerly silver near leg is bright yellow-green, far leg dark forest green. This keeps the near/far alternation legible without metal.

## Weapon behavior in the raster

All8run, dash,rise,fall,land,idle: empty green fists, absolutely no hilt, scabbard or blade. Windup8: raised fist with small brown bud, no long raised sword. Active9: organic golden-brown pointed wooden root grows from extended fist, horizontal right, no separate hilt or metal guard. Recovery10: short retracting root protrusion extends horizontally from fist. No prepainted arc, trail or effect in any frame.

Active opaque end is x60exclusive; farthest visible pixel x59 =>(59-32)*4=108gamepixels from pivot, compatible with world.gd common-enemy reach115. The old spec's104 damage range was incorrect. Boss reach180 accommodates larger boss silhouette and is gameplay separate from art. Do not change approved timing or moveset to fit the art; integrator synchronizes growth/retraction with current windup/active/recovery.

Prayer is the requested exception: summoned wooden root remains vertically planted under both hands during one-knee prayer. Pose and left/right knee arrangement match original. The material changed to wood and all leg armor to green; planted wood is not carried outside prayer/attack.

## Measured native bounds

Bounds are(x,y,width,height), relative to cell. Informational only; use fullcell and fixedanchor.

|Index/state|Bounds|
|---|---|
|0 run0|(17,10,29,26)|
|1 run1|(18,11,28,25)|
|2 run2|(18,9,28,27)|
|3 run3|(17,10,29,26)|
|4 run4|(18,10,28,26)|
|5 run5|(18,10,28,26)|
|6 run6|(18,9,28,27)|
|7 run7|(18,9,28,26)|
|8 windup|(18,11,29,25)|
|9 active|(16,14,44,22)|
|10 recover|(19,11,26,25)|
|11 dash|(20,16,30,19)|
|12 rise|(17,6,26,25)|
|13 fall|(16,6,27,28)|
|14 land/crouch|(18,16,29,20)|
|15 idle|(17,8,23,28)|
|prayer|(19,11,25,25)|

Source anchors retained exactly from approved preparation: [(175,296),(525,296),(869,296),(1227,296),(175,558),(522,562),(869,562),(1227,570),(180,806),(512,806),(868,806),(1216,806),(193,1078),(543,1078),(875,1078),(1231,1078)]. New true alpha source regions are in prepare_motion_wood_v1.py, measured from generated pixels rather than assumed regular cells. Source edit perturbs some edges by1–3sourcepixels; shared1/8nearest sampling can shift occasional outlinepixel by1nativepixel. No anatomy was deliberately restaged, and no per-frame fit scaling was used.

## Inspection and palette limits

Inspected raw output and native4× preview: alternating legs remain readable, all poses preserved, root only on attack/prayer, no metal limbs, cape/head identity intact. Native prayer remains recognizable as the original kneel at the original25×25 size. Human feel and actual transitions require independent engine review.

`art/inspect_wood_palette.py` checks the existing Atlas.simplify nearest-palette behavior without modifying art. Prayer maps to zero metallic grays. Motion maps10pixels to metallic-gray palette entries:8 warm cream-cape edge pixels and2 cyan-eye highlights. There are no gray limb clusters. An unconditional zero-gray assertion would reject legitimate cape/eye samples; assess limb regions or cluster counts. Pixel coordinates and RGB samples were communicated to integrator. No palette remapping has been applied to the files; runtime can apply its established shared simplify step.
