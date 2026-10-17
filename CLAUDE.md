# Bonkd project notes

## Weapon checklist: every weapon, existing or new, needs ALL of these

1. **Drop look**: what hangs from the burlap bandana parachute. Use the simplest recognizable piece (the barn, the rolled blanket, the porcupine), not the whole gun. The strings must touch real points on the item's top edge.
2. **Equipped look**: how the character holds it at rest.
   - Decide one or two hands, and keep it the same in every pose (Ivy Launcher = 2 hands, Porcu-Popper = 1 hand).
   - Paws go on the actual grips or handles. Elbows bend naturally.
   - Arms must never cross the face. The weapon itself may.
   - Shoulder-fired weapons rest on the part built to sit on a shoulder (the Barn-zooka rests on its barn).
3. **In-use look**: the firing pose (recoil or kick), and the same hands and grips as the equipped look.
4. **Just-used look**: what the weapon looks like right after firing.
   - Loaded ammo disappears from the barrel while its shot is in the air.
   - It reappears only if there is ammo left.
5. **Ammo-in-barrel layering**: ammo sits INSIDE the barrel.
   - Draw order: gun, then ammo, then the gun's front layer.
   - The front layer is the body plus the lip nearest the player, so the barrel covers the back of the ammo.
   - Never paste ammo on top of a barrel.
6. **Trajectory**: the path the shot takes (arc, homing, spread), and that the art faces its direction of travel.
7. **Projectile look**: the projectile in the air, drawn in the same trinket art style (quills, blanket, animals, pie).
8. **Effect on Grumble**:
   - What he looks like while hit or affected (blanket draped over him, quills stuck in him, pie splat).
   - How it ends (he throws the blanket off, etc.).
   - Plan these with Grumble's sprite sheet. The same applies to anything worn (the bucket on each character's head and ears).
9. **Sounds**: its own fire sound and its own hit sound, recognizable and funny. Barn-zooka animals are the bar.
10. **Store icon** and **gift-drop art** checked at real size, in the game, on both phone and computer.

## Character anatomy rules
- Todd is a grown-up bear. Never make his head bigger or his arms and legs shorter than the approved art; that makes him look like a cub. Check every new pose against the approved body.
- Keep each character proportionate. Arms have fixed lengths (upper arm and forearm), and they bend only at the elbow. Never stretch an arm to reach a handle.
- If a weapon's handles are out of reach, change the weapon (its size, its handle spots, where it rests) to fit the character. Do not change the character to fit the weapon.
- Know which way the character faces before placing arms.
  - Facing right (3/4 view): his right arm is the near arm, on the viewer's left, drawn in front of the body. His left arm is the far arm, on the viewer's right, drawn behind the body.
  - Facing left: the drawing is mirrored.
  - A shoulder weapon rests on the near shoulder. The near hand takes the trigger and the far hand takes the front grip.

## Pose coverage
- Every character needs every pose the game AND the opening story use, not just gameplay. Check the story beats (storyUpdate in the source) before calling a character done.
- Todd: stand, walk, bonked, knocked out, bucket on, holding each weapon, throwing; story: sitting and eating, startled, angry, running.
- Grumble: float, throw, hit, poof, each weapon's effect on him; story: drifting down, beaming the waffles up, evil laugh, flying off.
- Every held item or weapon needs a standing hold AND a walking-while-holding pose, with arms and paws drawn in the Canva art (never game-drawn arms on Canva bodies).
- Anything Todd eats (Mega Beans and any future food item) gets an eating pose: Popeye-style, he squeezes the can and the food shoots into his mouth.
- Booster: fly, toss.
- The picnic setting (Settings round): hilltop, shade tree, gingham blanket, plate and waffle stack, syrup bottle, beam, butterflies.

## Art rules
- References: Franky's trinkets (object style), the Nibbles scene Todd (todd-body-ref.png: Todd's look), and Franky's bear branding sheet (Benny: turnaround, expressions, hanging arms, claws). The bear sheet guides poses and details only. Keep Todd's approved proportions; do not make him fatter like Benny.
- Todd's approved art is the Canva full-body set (plain, armless game body, bucket version). Don't redraw it; new poses must match it.
- Grumble is built on the Nibbles ghost turnaround (2 1/4 heads tall, bottom-heavy blob body, small mitten hands low at the sides). Front view: no tail, round bottom. 3/4 and side views: the body sweeps back into a long thin tail trailing low BEHIND him, away from where he faces. Never a curly tail hanging straight down. Hood, cloak and blue gem on top.
- Grumble always floats: the tail lifts and curls up behind him. Never a long tail lying flat or low (reads as a slug).
- Grumble's cloak always drapes softly over his shoulders and hangs in loose folds, as in the float pose. Never stiff or short.
- His arms are short and stubby and come from his sides under the cloak, never from the hood or above it.
- Expressions read as a grumpy grown-up villain, never childish: no wailing or crying faces. When bonked he gets dazed (stars circling, gritted-teeth grimace). No lump on his head.
- Canva credits cost money: every generation is built from the specs on Franky's sprite sheets so it comes out right the first time. For Grumble, paste the locked spec block (scratchpad audit/grum_spec.txt, mirrored here) verbatim and change only the pose line. Check the prompt against the sheet before generating, one generation per pose, no speculative extras.
- Grumble's face is identical in every pose:
  - Expressions come from the Nibbles ghost expression sheet (audit/ghost_expr.png; Canva media MAHYMfbn4KE). Pass it as a reference for any new expression.
  - Eyes are Grumble's own, copied from the float and head refs: two orange-amber eyes pressed together with no gap, each with a heavy flat upper lid across the top, a big black pupil and a small white glint. Never round rings without lids, never small pupils, never closed, crescent, winking or glowing eyes. Emotion comes from lid angle, brows and pupil direction.
  - Small round nose and a thin mouth line.
  - An open mouth has a black inside and a pink-red tongue, shaped like the sheet's mouths. No fangs, nothing yellow or orange in the mouth. Teeth only as the sheet's gritted zigzag line.
  - Body green is the Nibbles Grumble green (206,248,162). After cutting, run art/grumgreen.py on every Grumble sprite so the green matches exactly.
- Outline treatment must match Todd on every sprite: thick black outline on the character, then ONE plain white sticker border, with no black or gray line outside the white. Cut Canva art with STRIP=1 (art/cut.py drops Canva's own border), then cut.py adds the clean white border.
- Trinket style: thick even black outline, flat colors with one darker shade, small white glint, white sticker border.
- Big sprites need a thin border. Check the border at real in-game size.
- Anything worn must match the wearer's facing and head angle. Near ear in front, far ear hidden. Handles go somewhere sensible.
- Sticker look across the scene: characters and weapons have the white sticker edge. Don't leave them as the only stickered things, or they read as die-cut stickers on a storyboard. In the Settings round, give foreground props the same treatment: thick outline plus the white edge on things in the play layer (picnic tree, blanket, fences, crates, critters). Mid layers get the outline only. Far layers get no outline, paler and bluer. Then the stickers read as depth, not as pasted-on.
- Review every group in the art review page before anything ships. Never deploy unapproved art.

## World building
- Todd's home is Maple Meadow. The opening picnic takes place there.
- The world blends Nibbles critter country (lived-in homes built into nature: hollow logs, stump mailboxes, mushroom porches, clotheslines, beehives) with breakfast country (maple trees tapped for syrup, waffle and pancake shapes in plants, berry bushes, butter-pat mushrooms).
- Settings are built in two parts: a painted backdrop with only the sky, far layer, mid layer and flat ground line (no front-layer props), plus front-layer props as separate trinket-style sprites (thick outline, flat color with one shade, glint, white sticker edge) placed by the game.
