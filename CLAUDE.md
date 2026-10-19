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
- Edge standard, for everything we make from now on (characters, weapons, props, plants, critters, code-drawn things):
  - In game, every sprite's white edge and black outline match Todd's, the tree's and the berry bush's. On the 1440x860 computer view that is about 2 to 3 px of white and 4 to 5 px of black.
  - A sprite's edge depends on how big it's drawn, not its file size, so cut with DRAWN=<largest side in game units> (art/cut.py) and let EDGE (default 1.6 game units) set the white. Thin a too-heavy black outline in the source before cutting.
  - Before showing anything new, screenshot it in the game and put it beside Todd and the berry bush at the same zoom. If its edges look thicker or thinner, fix it first.
  - art/cut.py with DRAWN set also measures the outer black outline and tops it up to INK (default 2.6 game units). For frame pairs, thicken the sources the same way before art/cut_pair.py (BORDER env sets its white).
- Design for the outline: the thick outline is part of the style, so things must be simple enough to carry it at their in-game size. Use a few big, bold shapes and a chunky silhouette, with no thin spindly parts, tiny details or busy interior lines. Plan this in the prompt (the SIMPLICITY line in audit/obj_spec.txt, with the in-game size filled in), not after. The cricket was dropped because its thin antennae and legs turned into black blobs.
- Anything worn must match the wearer's facing and head angle. Near ear in front, far ear hidden. Handles go somewhere sensible.
- Sticker look: the white sticker edge marks game pieces: characters, weapons, items, drops, and the opening picnic's props (shade tree, blanket, waffle stacks, berry bush). Backdrops have black outlines only, and gameplay levels have no extra scenery, so nothing else carries a white edge.
- Greens on any sprite placed over a backdrop match the backdrop's fresh, muted greens (about hue 0.26, saturation 0.46, value 0.68), never neon. art/orig_green holds the pre-match originals.
- Review every group in the art review page before anything ships. Never deploy unapproved art.

## Screen scale
- One scale for every screen, touch or not: S = min(H/640, W/1384). Wide computer windows show the same amount of scene around the characters as a phone held sideways. Grumble's size is GK (0.82 of the original); everything placed around him scales with it.
- Check "phone" views with real touch emulation (audit/bg_shots_t.py with TOUCH=1), not just a phone-sized window.

## Waffles
- Every waffle is the original square waffle (w_plain: golden, square, 3 by 3 grid of square pockets, thick side edge, butter pat). Never round or oval, anywhere: stacks, held waffles, thrown waffles, icons, story art. Pass w_plain (Canva media MAHYTKCJelU) as a reference for any art that shows a waffle.
- The picnic spread is Canva art in the same style: pr_blanket (gingham blanket with the empty plate and syrup bottle) plus one stack sprite per count (pr_stack1 to pr_stack4, one outline around the whole stack). Never stack separate outlined waffle sprites; four outlines read badly. Todd's eating and startled poses hold a square waffle.

## Setting checklist: every new setting, before showing it

1. **One painted backdrop per setting, made in Gemini.** The user runs the prompt in Gemini (no Canva credits). The style matches the approved mountain backdrop (art/src_bd_mountain.png, attach it to every prompt):
   - bold, even black outlines on every shape in every layer; flat colors with one darker shade; no texture or gradients;
   - bright cyan sky with puffy cartoon clouds and soft light rays;
   - far layers paler and slightly blue; fresh, muted greens;
   - big shapes may frame the left and right edges, but the center stays open for play;
   - a flat, level ground strip across the full width with a solid black top line at 85% of the height, in that setting's own color;
   - no characters, animals, text, white sticker edge or objects standing on the ground strip.
   2400x1200 (2:1). Save the source as art/src_bd_<name>, write art/review/r_bd_<name>.webp at 2048 wide.
2. **Its own world.** The backdrop is filled by that world and its own ground strip (meadow: orange dirt; forest: dark brown earth under moss; mountain: orange dirt). Never reuse another setting's look.
3. **Names match.** Every level name matches what the backdrop shows. Nothing from the Nibbles cast, the Barn-zooka animals or the item list appears in it.
4. **Backdrop only in play.** Gameplay levels show the backdrop with no extra scenery or wildlife: added props read as items because of their white edge. Only the opening picnic keeps props.
5. **Ground line.** In BGART, set the ground fraction so Todd's feet sit just under the black top line, on the strip (about the line's fraction plus 0.02; for a thick grass or moss band, where it meets the dirt). Approved: meadow .875, forest .895, mountain .872. Alternate levels mirror the backdrop.
6. **Check before showing.** Computer and real touch phone, zoomed on the ground line, mirrored and unmirrored.

## World building
- Todd's home is Maple Meadow, named for his love of waffles and maple syrup, not for maple trees. No maple trees or maple leaves anywhere; trees are the round, lobed kind. The opening picnic takes place there.
- The world blends Nibbles critter country (homes built into nature: hollow logs, stump mailboxes, mushroom porches, clotheslines, beehives) with breakfast country (syrup, waffle and pancake shapes in plants, berry bushes, butter-pat mushrooms). This flavors backdrop prompts and story scenes.
- The Nibbles cast never appears as scenery or wildlife: bear, cock (chicken), raccoon, beaver, gnome, ghost, wolf, gecko. The Barn-zooka keeps its chicken.
- Setting animals and objects must never repeat something that already exists as a power-up, item or weapon (no snails because of the SLOWMO Snail). Check the item list in the source first. Current clashes to avoid: snail, porcupine, cow, pig, sheep, rooster or chicken, poison ivy, waffle tree, banana, coconut, peach, pie, skillet, bucket, magnet, brick, bowling ball, ping pong paddle, beans, oatmeal, shoe or boot, tuba, bubblegum or gumball, waffles as loose objects, laser or halo. Whenever the user brainstorms a new item, remind them to check it against the settings' backdrops, and the reverse.
- Levels: the opening picnic is the story, then six settings of five levels, all five sharing one backdrop:
  1. Meadow (bd_meadow): Maple Meadow, Clover Hill, Ladybug Lane, Daisy Dell, Shady Grove.
  2. Forest (bd_woods): Piney Woods, Hoot Owl Hideout, Foxglove Bend, Mossy Hollow, Conifer Corner.
  3. Mountain (bd_mountain): Biscuit Bluff, Switchback Summit, Eagle's Perch, Thunderhead Peak, Avalanche Alley.
  4. River canyon: Muddy River Crossing, Echo Canyon, Coyote Crag, Red Rock Rapids, Cattail Creek.
  5. Desert: Tumbleweed Trail, Rattlesnake Ridge, Cactus Flats, Dusty Dunes, Sidewinder Sands.
  6. Harvest, heading home: Pickleberry Pasture, Corny Maze, Hayride Hill, Pumpkin Patch, Home Sweet Home.
- The opening picnic uses bd_meadow plus its props through the scenery planner (planSetting, SETTING.meadow): the shade tree (pr_tree), pr_blanket with pr_stack1 to 4, the U-Pick berry bush (picnic only), a few plants, butterflies (Canva bf_* frames that steer clear of Todd, Grumble and the speech line) and the ladybug. Layering is by size: taller things behind shorter ones. Plants never overlap each other, props or Todd.
- The gameplay profiles (SETTING.meadow1, forest, mountain) are zeroed in the source, so the planner places nothing there. The forest and meadow scenery sprites stay in art/review in case a piece is ever wanted back.

## Lives and continues
- Everyone starts a run with 3 lives. A wallet connected on nibblethis.wtf adds 1 life per Nibble held, up to 25 more. The host page sends the count with postMessage({type:'bonkd:wallet',nibbles:N}) (only nibblethis.wtf origins are accepted) or window.bonkdSetNibbles(N).
- The HUD shows Todd's head × lives where the score used to be. The score is still kept for the leaderboard but not shown during play.
- After getting BONKD, a life continues the run from that point (bonks reset, junk cleared). Free lives are used before bought ones.
- Extra lives cost 1,000 waffles, at most 10 per rolling 24 hours, and are banked on the profile (Supabase buy_life / use_life; waffle_board.lives, life_buys).

## Chapter scenes and unlocks
- After levels 5, 10, 15, 20 and 25 a skippable scene plays (CHAPTERS in the source): Grumble flies over and drops the new thing on the bandana parachute, Todd grabs it and uses it, an info card explains it, Todd celebrates (c_todd_cheer), then runs off after Grumble.
  - 5: LUMPY OATMEAL: plain, gloppy, grayish oatmeal, no spoon, no toppings. Doubles how many bonks Todd can take; each meter icon gets a rainbow outline that the first bonk removes, then the icon fills.
  - 10: SHOE HORN (weapon): an old boot that's also a tuba, 2 hands, 5 honks of gold music notes; Grumble gets a headache (c_grum_headache, notes circling).
  - 15: BEAR HANDED (power-up): double damage for 20 s, red glow on Todd and a countdown chip.
  - 20: GARGANTU-GUM (weapon): Todd eats it (c_todd_eat_gum), blows bubbles (c_todd_blow, 3 per gumball) that float up and pop on Grumble (c_grum_gum), who peels it off.
  - 25: WAFFLICIOUS (power-up): for 10 s Grumble throws waffles (mostly plain) instead of junk.
- Each unlock joins Booster's random pool only after its chapter level (PW[k].unlock).
- BOOSTER BEAM is a store power-up (5,000 waffles): Booster flies in and blasts Grumble with the Canva gold laser (fx_beam, tiled and scrolling, with glow and sparkles) and a spinning starburst blast (fx_burst) on the side of Grumble facing Booster, so his face stays visible. Booster pose: c_boost_beam. Drop look: Booster's halo, drawn in code.
- Booster always has a soft golden glow behind him and a trail of twinkles (boosterGlow) so he stands out on every backdrop.
- Todd pose prompts use the locked block in scratchpad audit/todd_spec.txt (references: h_zooka/w_zooka for 2-hand holds, beans_eat for eating, todd_full for others).

## The boss: Grumble's Hideout (after level 30)
- Backdrop bd_hideout (Gemini): cave lair, far golden waffle heap, syrup cauldron over green ghost fire, no furniture (ghosts don't sit).
- Intro (skippable): Grumble floats to the cauldron, tosses in 3 normal waffles, the cauldron spits out the magic waffle (w_magic: glowing mint-green waffle with goopy glowing green butter), he eats it (c_grum_eatmagic), swells into GRUMBLEMAX and roars.
- GRUMBLEMAX art is built on the user's Oswald mega-ghost sheet with Grumble's face: huge saggy body, meaty sagging underside, NO tail. Poses: c_mega_float, throw, hit (dazed and angry, never worried), roar, deflate (waffles bursting out). Hitboxes x2.1.
- Fight: 180 HP (lowered from 220 after the playtest; a fight runs about 2 to 2.5 minutes). Phase 1 fast junk; under 2/3 he roars, "SYRUP STORM": syrup drips fall with ground warning shadows; under 1/3 "GRUMBLE RAGE": more junk plus lightning. Hits sometimes burp out waffles; Booster comes more often. Defeat: KA-POP, waffles rain, then the ending.
- Ending (tap to skip): back at the Maple Meadow picnic, waffles back on the plate, Todd eating (sit_eat) with lots of butterflies (SETTING.ending), two quips, THE END, then the win card "GRUMBLEMAX is DEFEATED!" over the picnic.
- Harvest level 29 is Pumpkin Patch (the user swapped the moon for a sun).
- After beating GRUMBLEMAX once (saved on the device as localStorage bonkd-cleared AND on the profile as waffle_board.cleared_at via mark_cleared; isCleared() checks both, and a device flag syncs up to the profile), every new run keeps the unlocks: Lumpy Oatmeal from the start, all chapter items in Booster's pool from level 1, and the chapter scenes are skipped. The win card's button reads "Play again".
- Store: a "Quests: Coming soon!" section with blurred teaser cards: Space Quest (bd_space, moon surface) and Underwater Quest (bd_sea, sandy sea floor), both Gemini backdrops made to gameplay spec (ground line at 85%) so they can become real levels, plus a "More Quests" card. Quests will be new places to fight Grumble in new ways.

## Title, lettering and music
- The title is the real logo lettering (logo_text_only: "Don't get BONKD!" cut from the approved sticker logo, finished in ChatGPT; scratchpad sprites/logo.webp, embedded as __LOGO__). The menu shows it pinned near the top; the run start pops the same image sized to stay between the HUD and Todd's head. Never retype the title in a font.
- Menu: title, Play, then Leaderboard and Waffle Store spaced evenly between the bottom of Play and the backdrop's grass strip (layoutMenuLinks, GRASS_FRAC .833). No controls text on the menu.
- After the story, a one-line how-to shows for about 4 s (keys or touch wording), centred on the dirt strip under Todd so it never covers him or Grumble.
- Todd's lump and dizzy stars sit on CROWN[key] (the top of his head between the ears, measured per pose), so they stay on his head in every pose. Steps follow distance: one foot swap per TODD_STEP (46) game units; the run hop follows the same phase.
- No sprint pose in play: Todd only walks, faster the harder he's dragged. The run art is for the story and chapter scenes only (b.pose==='run').
- Plain Todd walks with a 6-frame Canva walk cycle (c_todd_wk0 to wk5, one Canva generation from todd_full + h_walk refs, split and cut STRIP=1 SIZE=640 DRAWN=200), one frame per WK_D/6 (118/6) game units walked (bear.wd). Held items, weapons and the bucket still use their two-drawing stand/step pairs; a cycle for each would cost one Canva credit apiece.
- Lettering: Lilita One for the display font. Headings, labels and buttons are built per letter by glossify(): gold or red two-tone fill, a white streak-and-dot shine, a thin round black outline and a hard shadow. Words on red buttons are white. Level names stay plain dark text (bigger), the number a little smaller.
- Music: one recorded track ("The Fun Starts Here", Pixabay/mmaudio) makes the set: menu = the song from the top at .82; gameplay = its main section looping (24.87 s to 98.41 s); boss = that loop at 1.12x; win = the song's ending sting. Mega Beans keeps its synth tune.
