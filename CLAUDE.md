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

## Animation rule: no still image performs an action
- A single still drawing may only be shown while the character is holding still (standing, a held reaction). Anything that moves, throws, flies, walks, eats or recovers needs a sprite sheet (6 frames, 2 rows of 3, the pose art as a reference).
- Grumble is STUNNED during a reaction (ghostStunned: pie, soot, quills, zap, flat, headache, gum, blanket): no throwing and almost no drifting while its sheet plays. The code wobble only runs for a reaction that has no sheet.
- Sheets made (design DAHYMS6kGn0 pages 94-100 are reused as export slots; media ids in scratchpad sheets/media.txt, prompts in sheets/*.json and audit/*_spec.txt):
  - Grumble c_grum_<k>_a0..5 for throw, hit, pie, soot, quills, zap, flat, headache, gum, blanket (frames 0-2 trapped, 3-5 flinging it off), itch, slow, poof, eatmagic. grumFrame() picks the frame: one-shot reactions follow their own timer (fxT/fxD, splat, offT, koT), loops follow the clock, and the throw's wind-up plays as throwT runs out, the release while throwA runs. Face anchors in GPF (all lined up on the float pose's eyes).
  - GRUMBLEMAX c_mega_<k>_a0..5 for throw, hit, roar, deflate (deflate shrinks back to regular size in the art), anchors MEGA_F.
  - Todd c_todd_<k>_0..5: bonked, ko, th (throw), sit_eat, sit_huh, angry, cheer, eat_beans, eat_gum, eat_oat, blow, and walk cycles w_<item>_0..5. T2A/CROWN entries per frame (ears matched to todd_full). Every held item walks on its cycle (WALKSHEET). The ivy, porcu and zooka walk frames each have their own barrel masks (r_m_/r_n_w_<w>_<i>, T2HOLE, made by scratchpad sheets/walk_holes.py) so loaded ammo sits inside the barrel.
  - Booster: new fly (c_boost_fa), beam (c_boost_bf, 6 frames, mirrored to face Grumble) and toss (c_boost_ts) sheets drawn from the user's Booster portrait (Canva MAHYe0MMVis), all lined up on the halo of c_boost_fly. Booster has white eyes with big pupils and droopy lids, never sunglasses or an eye patch (spec: audit/boost_spec.txt).
- Frames are cut with art/cut.py (STRIP=1, DRAWN per character), saved at 512 px max.
- Weapon effects (Marvel vs. Capcom style, audit/fx_spec.txt, cut by sheets/fx_cut.py on fixed cells so frames share one frame of reference): hits fx_pie, fx_banana, fx_bun, fx_quill, fx_gum (bubble pop), fx_smash (Mega Beans ground shockwave at Grumble's feet); fire and swing fx_ivy, fx_shoe, fx_magnet (muzzle-anchored, ax), fx_paddle (every swing); fx_clonk on a bucket block, fx_jello on a jello bounce. Anything else keeps fx_spark.

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
- Base scale S = min(H/640, W/1384). Wide computer windows show the same amount of scene around the characters as a phone held sideways. Grumble's size is GK (0.82 of the original); everything placed around him scales with it.
- Phones (touch, short side under 520 px) draw the world at PHONE_Z (0.58) of that so Todd and Grumble have room between them; words use TS (0.85 of the base) so they stay readable. The phone dirt strip is 8.5% of the height (computer 12%).
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
4. **Backdrop only in play.** Exception the user asked for: Ladybug Lane has 4-5 happy ladybugs (cr_ladybug) crawling on the ground line (LEVELSET 'LADYBUG LANE':'ladybug'). Gameplay levels show the backdrop with no extra scenery or wildlife: added props read as items because of their white edge. Only the opening picnic keeps props.
5. **Ground line.** In BGART, set the ground fraction so Todd's feet sit just under the black top line, on the strip (about the line's fraction plus 0.02; for a thick grass or moss band, where it meets the dirt). Approved: meadow .875, forest .895, mountain .872. No mirrored levels (user read the flip as a bug), and painted settings get no code-drawn weather.
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
- Lives are DAILY: everyone gets 3 lives a day, shared by every run that day, and the day turns over at midnight GMT (utcDay, dailyUsed in the source; stored on the device as bonkd-lifeday). The count lives on the device AND on the server (Supabase table life_days, rpc daily_lives / use_daily_life); the game uses the larger, so clearing the browser doesn't refill them. Bought lives keep working after the daily ones run out. Getting BONKD with a life left spends one and continues; with none left the run ends. When the day's lives (and any bought lives) are gone, Play shows the OUT OF LIVES card with a countdown to midnight GMT and a buy-a-life button. A wallet connected on nibblethis.wtf adds 1 life per Nibble held, up to 25 more. The host page sends the count with postMessage({type:'bonkd:wallet',nibbles:N}) (only nibblethis.wtf origins are accepted) or window.bonkdSetNibbles(N).
- The HUD shows Todd's head × lives where the score used to be. The head is a sticker cut from the approved logo head WITH its lump and dizzy stars (white sticker edge, no circle behind it): art/todd_head.webp, made by scratchpad logo/head_icon3.py. The score is still kept for the leaderboard but not shown during play.
- After getting BONKD, a life continues the run from that point (bonks reset, junk cleared). Free lives are used before bought ones.
- The store can be opened from the level-clear card (Waffle Store link under Next level) without ending the run: waffles are banked at every level clear (bankLevel; Supabase bank_waffles adds them to the board and wallet without counting a run; submit_run at the end sends only the rest), so they can buy weapons or lives between levels.
- Extra lives cost 1,000 waffles, at most 10 per rolling 24 hours, and are banked on the profile (Supabase buy_life / use_life; waffle_board.lives, life_buys).

## Chapter scenes and unlocks
- After levels 5, 10, 15, 20 and 25 the new ability is something Grumble LOSES, never a gift: when he poofs, it falls out of the poof cloud (lostItem, "UH OH!"), bounces and lies on the ground through the level-up. After Next level a skippable scene plays (CHAPTERS in the source): Todd walks over, grabs it and uses it, an info card explains it, Todd celebrates (c_todd_cheer), then runs off after Grumble.
  - 5: LUMPY OATMEAL: plain, gloppy, grayish oatmeal, no spoon, no toppings. Doubles how many bonks Todd can take; each meter icon gets a rainbow outline that the first bonk removes, then the icon fills.
  - 10: SHOE HORN (weapon): an old boot that's also a tuba, 2 hands, 5 honks of gold music notes; Grumble gets a headache (c_grum_headache, notes circling).
  - 15: BEAR HANDED (power-up): double damage until Todd gets bonked (an oatmeal ring soaking the bonk still counts) or the level ends; it never carries into the next level. Red glow on Todd and a chip with no countdown.
  - 20: GARGANTU-GUM (weapon): Todd eats it (c_todd_eat_gum), blows bubbles (c_todd_blow, 3 per gumball) that float up and pop on Grumble (c_grum_gum), who peels it off.
  - 25: WAFFLICIOUS (power-up): for 10 s Grumble throws waffles (mostly plain) instead of junk.
- Each unlock joins Booster's random pool only after its chapter level (PW[k].unlock).
- BOOSTER BEAM is a store power-up (10,000 waffles): Booster flies in and blasts Grumble with the Canva gold laser (fx_beam, tiled and scrolling, with glow and sparkles) and a spinning starburst blast (fx_burst) on the side of Grumble facing Booster, so his face stays visible. Booster pose: c_boost_beam. Drop look: Booster's halo, drawn in code.
- Booster always has a soft golden glow behind him (boosterGlow), no trail of puffs. He flies with a 6-frame full-body flap cycle (c_boost_fa0..5, design page 91, lined up on his halo by BOOST_FA), swoops in on an arc over 1.3 s, hovers, tosses at 1.9 s and flies off climbing.
- Todd's size is consistent across poses (user caught jumps): the item walk frames (w_<item>_0..5) are scaled so Todd's height matches his standing hold for that item, and the story's sit_huh and shk sheets match sit_eat's head size. Check new Todd sheets the same way (audit/todd_head.py, todd_eyes.py, todd_belly.py; heights for standing poses, head size for sitting) before shipping.
- The ivy, porcu and zooka walk frames' barrel masks are the still's masks scaled onto each frame's barrel hole; on the ivy walk frames the rolled blanket sits deep in the barrel (T2AMMO.ivy_walk) like the loaded hold art.
- Todd pose prompts use the locked block in scratchpad audit/todd_spec.txt (references: h_zooka/w_zooka for 2-hand holds, beans_eat for eating, todd_full for others).

## The boss: Grumble's Hideout (after level 30)
- Backdrop bd_hideout (Gemini): cave lair, far golden waffle heap, syrup cauldron over green ghost fire, no furniture (ghosts don't sit).
- Intro (skippable): Grumble floats to the cauldron, tosses in 3 normal waffles, the cauldron spits out the magic waffle (w_magic: glowing mint-green waffle with goopy glowing green butter), he eats it (c_grum_eatmagic), swells into GRUMBLEMAX and roars.
- GRUMBLEMAX art is built on the user's Oswald mega-ghost sheet with Grumble's face: huge saggy body, meaty sagging underside, NO tail. Poses: c_mega_float, throw, hit (dazed and angry, never worried), roar, deflate (waffles bursting out). Hitboxes x2.1.
- Grumble's health (user: low to start, growing with each setting): GHP/grumHP in the source. Meadow 3,4,5,6,8; forest 10-18; mountain 20-28; canyon 34-46; desert 50-66; harvest 70-86. His side-to-side speed climbs slowly: frequency .55 + (level-1)*.03, capped at +.9.
- Lightning (from level 3): a long, readable build-up (2.3 s at level 3, never under 1.6 s; 1.7 s in the boss rage phase). Grumble casts (beam pose) inside the Canva charge ring (fx_charge0-5, design page 92) with a rising electric whine; the ground target follows Todd for the first 60%, then locks with a crackle and pulses faster; then the Canva bolt (fx_bolt0-5, design page 93) strikes.
- Fight: 180 HP (lowered from 220 after the playtest; a fight runs about 2 to 2.5 minutes). Phase 1 fast junk; under 2/3 he roars, "SYRUP STORM": syrup drips fall with ground warning shadows; under 1/3 "GRUMBLE RAGE": more junk plus lightning. Hits sometimes burp out waffles; Booster comes more often. Defeat: KA-POP, waffles rain, then the ending.
- Ending (tap to skip): back at the Maple Meadow picnic, waffles back on the plate, Todd eating (sit_eat) with lots of butterflies (SETTING.ending), two quips, THE END, then the win card "GRUMBLEMAX is DEFEATED!" over the picnic.
- Harvest level 29 is Pumpkin Patch (the user swapped the moon for a sun).
- After beating GRUMBLEMAX once (saved on the device as localStorage bonkd-cleared AND on the profile as waffle_board.cleared_at via mark_cleared; isCleared() checks both, and a device flag syncs up to the profile), every new run keeps the unlocks: Lumpy Oatmeal from the start, all chapter items in Booster's pool from level 1, and the chapter scenes are skipped. The win card's button reads "Play again".
- Special waffles show their name and value only; no quip lines after them.
- Booster is drawn at BOOSTW 185 (was 150) so his face reads on phones.
- Store sections: Super Duper Weapons, Quests (coming soon), New Heroes (coming soon: only the next hero's silhouette coin, art/st_carlito.webp, nothing that gives him away) and Tournaments (coming soon, waffle prizes only). Buddies and Legends are gone for good.
- Store: a "Quests: Coming soon!" section with blurred teaser cards: Space Quest (bd_space, moon surface) and Underwater Quest (bd_sea, sandy sea floor), both Gemini backdrops made to gameplay spec (ground line at 85%) so they can become real levels, plus a "More Quests" card. Quests will be new places to fight Grumble in new ways.

## Supers (Marvel vs. Capcom hyper-combo moments)
- Rule: only Waffle Store items get the full MvC super (backdrop swap). Today: Booster Beam, Mega Beans, Porcu-Popper, Ivy Launcher.
- Signature non-store moves get extra special effects but NOT the backdrop swap: the Barn-zooka, the Shoe Horn's last honk and Bear Handed.
- A super: everything freezes for a beat, the hero cut-in slides across, the level backdrop fades out and that super's own painted, animated super backdrop fades in behind the characters and effects (which stay fully lit), with its own sound set, a big lettering word from the letter sheet and a lore or joke line. When the move ends the level backdrop fades back.
- Super backdrops are Gemini paintings (the user runs the prompts, no Canva credits), two per super: the plate (2400x1200) and a pieces sheet (6 loose pieces on white, cut and flown around by code). Code only places, spins, pulses, scrolls and flies the real art; nothing is code-drawn. They're meant to be wild.
- Built (scratchpad supers/cut.py, sources in supers/src): sb_<k> plates (cropped 2:1, gnd = ground-line fraction), sp_<k>N loose pieces, ss_<k> anime shouts ("BOOSTER BEAM!!", "MEGA BEANS!!", "PORCU-POPPER!!", "GET A RASH!!"). startSuper(k,cutInImg) in the source: freeze and cut-in, plate fades in, pieces fly (wind, erupt or radial), shout slams in when the freeze ends, plate fades back. Triggers: Booster Beam at the beam, Mega Beans on eating, Porcu-Popper and Ivy Launcher on the first shot of each pickup. No spoken callouts; the shout is the move name. Ivy pieces are the user's 5 (leaf, fluff, twine spool, sprig, printed patch).
- Camera and barrage (from the user's Marvel vs. Capcom Infinite reference): after the slam each super lands its own barrage of strikes (SUPERS[k].bar: pieces flung from Todd at Grumble, a hit effect each, small damage, a bigger last hit; Booster Beam uses the beam's own hits). Every second strike hard-cuts the camera to the next angle in SHOTS (wide and dead centre, close on Grumble with a dutch tilt, reverse angle mirrored, low on the hero...), the last strike cuts back wide, and the camera eases home as the super ends. The plate is drawn 1.4x the screen on its ground line so close shots stay inside it; Grumble is never framed under the HUD. A gold "N HITS" counter (letter sheet) counts every hit; the shout sits on the side of the screen away from Grumble.
- Super tiers (user): price and damage rise together, and a purchase lasts forever. Blanket 2,500 waffles, Porcu-Popper 5,000, Booster Beam 10,000, Mega Beans 25,000 (SUPER prices in the source AND buy_item on the server, both live). Damage is SET numbers, never a share of Grumble's health, so later levels (more health) need Todd to survive longer and use more weapons: the super itself deals SHIT (ivy 15, porcu 22, beam 30, beans 40); the weapons' ordinary shots use SUPER_FIX per tier (12, 18, 24, 30). One shot per special: the super IS the shot (no ordinary porcupine or blanket fired alongside it); the barrage's last strike lands the weapon's own effect (quills stuck in him, blanket draped, smash). The pickup's remaining ammo fires normally.
- Super pacing (user: at least twice as slow): hold beam 3.1 s, beans 5.2, porcu 5, ivy 4; strikes .42 s apart, pieces at half speed, shout holds 2.5 s, the Booster Beam fires for 2.8 s (7 hits .4 s apart). Cues are 7.5 s. If the level ends mid-super, the super stops and the camera snaps home.
- Signature effects (no backdrop): the Barn-zooka's last load is a STAMPEDE (two extra animals fan out), the Shoe Horn's last honk is BWAAAAMP!! (more damage, three rings), Bear Handed flashes its word on pickup and every hit lands heavier.
- Haptics: buzz on bonks, KO, supers and big hits, with a settings toggle. Android browsers support it; iPhone Safari doesn't allow web vibration. Inside nibblethis.wtf (a cross-origin frame) Chrome blocks it, so the game also posts {type:'bonkd:haptic',pattern} for the host page to vibrate (needs CD). Settings has a Vibration on/off row (bonkd-vib), shown only where vibration can work.
- Every hero world gets its own version of all of this (Carlito's supers, backdrops, sounds, lettering words and jokes); nothing is shared between heroes.

## Controls
- Booster's drops are caught by any part of Todd (giftTouch): from the tip of his lump to his feet, his body width plus the front where his arms and weapon are.
- Touch: drag anywhere to move Todd, tap anywhere to use the weapon (a quick touch under 350 ms that doesn't move). The red badge only shows the weapon and ammo; it isn't a button. Two thumbs work: the newest finger steers, and the one still down takes over when it lifts.
- Keys: arrows or A/D move, Space uses weapons, P pauses.
- Pie (2) and Boomer-nana (1) are held and thrown with the weapon control. The Junk Magnet (12 s) only grabs metal junk that comes near Todd, holds up to 3, and fires them back with the weapon control.

## Title, lettering and music
- The title is the real logo lettering (logo_text_only: "Don't get BONKD!" cut from the approved sticker logo, finished in ChatGPT; scratchpad sprites/logo.webp, embedded as __LOGO__). The menu shows it pinned near the top; the run start pops the same image sized to stay between the HUD and Todd's head. Never retype the title in a font.
- Menu: centred, in front of everything. Behind it Todd strolls the whole width left to right (off the right edge, back in on the left) while waffles drift down across the whole screen.
- Menu order: title, Play, then Leaderboard and Waffle Store spaced evenly between the bottom of Play and the backdrop's grass strip (layoutMenuLinks, GRASS_FRAC .833). No controls text on the menu. No waffle total or best score on the menu either (user); they live on the leaderboard and the store.
- After the story, a one-line how-to shows for about 4 s (keys or touch wording), centred on the dirt strip under Todd so it never covers him or Grumble.
- Todd's lump and dizzy stars sit on CROWN[key] (the top of his head between the ears, measured per pose), so they stay on his head in every pose. Steps follow distance: one foot swap per TODD_STEP (46) game units; the run hop follows the same phase.
- Story animation (Canva sheets, 6 frames each, 2 rows of 3, design DAHYMS6kGn0 pages 84-88): Grumble descend, beam, laugh and flee play c_grum_<pose>_a0..5, face-anchored by GPF in the source; Todd's run is the third run sheet (design page 89; made from todd_full plus two approved walk frames as the leg reference, because a long-legged sprint read too tall and skinny and the first sheet too chunky), c_todd_rn0..5 at k .42. Sheet prompts: the locked spec block plus an ANIMATION SHEET line and the pose line; the single pose art is passed as the 4th reference.
- The opening story and the ending use Todd's original single drawings for sitting/eating, "Huh?" and angry (the user preferred them to the 6-frame sheets, which looked shaky): todd2Key0 skips todd2Pose in state story/ending. The trembling shk sheet and the run sheet stay.
- Opening story beats (ST in the source): munching, "Huh?" (sit_huh), "Nooo! My waffles!" with the trembling oh-no sheet (c_todd_shk0..5, design page 90) while the waffles ride the beam up (.3 s apart, .42 s each), "HEH HEH HEH!", "Hey! Come back here!" (angry), then the run. Todd's lines sit above his real head top for the pose (bear.topY), with a clear gap.
- Parachute drops flutter (canopy breathes, leans and ripples; strings stay tied). No white puffs trail them.
- Pop words are rendered at screen resolution (glossWord at DPR*1.3) so they stay crisp.
- No sprint pose in play: Todd only walks, faster the harder he's dragged. The run art is for the story and chapter scenes only (b.pose==='run').
- Plain Todd walks with a 6-frame Canva walk cycle (c_todd_wk0 to wk5, one Canva generation from todd_full + h_walk refs, split and cut STRIP=1 SIZE=640 DRAWN=200), one frame per WK_D/6 (118/6) game units walked (bear.wd). Held items, weapons and the bucket still use their two-drawing stand/step pairs; a cycle for each would cost one Canva credit apiece.
- Lettering: headings (.logo, .pre) and in-game pop words are built from the user's letter sheet in the title style (scratchpad font/sheet.jpg, sliced by font/build.py into art/font_atlas.webp + FONTM metrics; '-' '.' ':' are made from the sheet's own plus sign and dots). Other colours (red, green, white) recolour the gold fill and keep the outline, shadow and shine. Lilita One remains the fallback for anything not on the sheet. Headings written as one span per letter are merged into words first. Button words are plain text: white on red buttons, red on the other pills.
- Loading screen (#boot): the approved logo with Todd's head (sprites/logo_full.webp) held still in the middle on the label blue, with 16 real w_plain waffles tumbling down behind it, until the menu art, font and letter atlas are in. Never code-drawn art on anything players look at; code only places and animates real art.
- The how-to line after the story is outlined text that pops in (no pill).
- The leaderboard handle box is a contenteditable field (#pfName, not an <input>), so iPhone Safari never shows AutoFill Contact; it caps at 14 characters, Enter saves, and game keys ignore it while typing.
- Bounced and swatted junk (Peach Wobbler, paddle) hits anywhere on Grumble's body: ghostBodyHit, an ellipse from the hood to the bottom of his body (not the tail).
- Booster's flight and beam frames carry the approved head pasted from c_boost_fly / c_boost_beam (anim/boost_head.py, lined up on the halo), because the Canva frames' faces came out muddy.
- No falling waffles on the menu; they're on the loading screen.
- The picnic spot is a fraction of the screen width (picnic.x getter), so resizes and restarts can't move it.
- Card lettering: glImg measures the empty rows above and below each lettering image and pulls its margins in by that much, so headings sit tight in every card (user: too much space). The chapter card's art uses #chImg (a bare .chap img rule once blew the lettering images up). BONKD on the continue card is bigger; on short screens the continue card compacts so the Buy a life button isn't cut off.
- Level names stay plain dark text (bigger), the number a little smaller. The level card is tight (user: too much white space): the lettering images' built-in padding is trimmed (#lvlCard .gwi margins).
- Music: one recorded track ("The Fun Starts Here", Pixabay/mmaudio) makes the set: menu = the song from the top at .82; gameplay = its main section looping (24.87 s to 98.41 s); win = the song's ending sting. Mega Beans keeps its synth tune (it starts after the beans super). GRUMBLEMAX has his own track, "Battle Rage" (Pixabay/desifreemusic, scratchpad music/new/boss.mp3): plays from the top, loops 49.71 s to 151.59 s with a 1 s crossfade baked in. Each store super has its own cue cut from "Boom Mode" (Pixabay/cocamelody, music/new/cue_<k>.mp3, each starting on a big hit: beam 33.11 s, beans 104.44, porcu 120.37, ivy 93.46): the level music dips out at the freeze, the cue plays under the super, the music comes back as the move ends (superMusic).

## Future heroes (planned, not built)
- kit/WORLD_KIT.md is the formula: every slot a hero's world must fill, what's shared (engine, Grumble and GRUMBLEMAX, waffle values, wallet, lives, leaderboard) and the engine work needed (a WORLD config object, per-world asset bundles, hero select and unlock). kit/todd_world.json is the generated inventory of Todd's world.
- Nothing from one hero's world is reused in another's. There is ONE leaderboard for every hero: waffles are waffles on the backend; each world only draws and names them its own way, and each world's store is branded for its hero.
- Next hero: Carlito (Nibble #8102, raccoon). Night-time, grungy world: diner dumpster, alleyway, underground sewer, drainage pond, the junkyard outside the drainage facility, then inside it for GRUMBLEMAX (5 settings, 25 levels plus the boss). Trashy waffles and trash or used-food items. Unlocked for a large waffle price or a small payment. Build only when the user says Todd is done.

## Batch v24 notes
- Mega Beans super: Todd eats, grows giant, then hulk-smashes Grumble twice on his own (c_todd_smash_0..5, SUPERS.beans.smash times, SMT frame timings, SMREACH): he leaps to Grumble, the slam pins Grumble flat on the ground (ghost.pin, c_grum_flat; no new Grumble sheet needed) and he pops back up. Wider camera shots for beans (SUPERS.beans.shots) so the giant stays in frame. The beans weapon ends when the super ends.
- During any super: Todd can't be bonked, Grumble is stunned (no throws or lightning), Booster doesn't come and gifts can't be caught, weapon chips and tip pops are hidden.
- The shout word flies in, holds still, then flies out (drawShout).
- Lightning charge: any hit cancels it (FIZZLE!), Grumble plays his hit reaction, then charges again later.
- Lumpy Oatmeal: a solid bright yellow ring per meter icon (bear.oat); each ring absorbs one bonk and blinks 3 times as it breaks; Booster can toss more oatmeal (PW.oat, unlock 5).
- Ivy Launcher has 1 shot. Stampede: all three animals home in and hit.
- HUD waffle icon is the real w_plain art.
- Background flyers (FLY/FLYBG, no white edge, always behind everything, 1.3x on phones): meadow 2-3 small butterflies (bfn_*); Piney Woods 1-2 shadowy owls gliding behind the near trees (bd_woods_front, lifted from the backdrop by woods/front.py on hue/saturation); mountain swifts in pairs; river canyon dragonflies that hover and dart back and forth; desert 1-2 vultures circling high (glide frames by bank angle, a lazy flap now and then); harvest geese in a V or a loose few. Every bird in a group gets its own size, wingbeat rate, phase and weave so none flap in step. Sheets (Canva, design pages 94-97 as export slots; media ids in sheets/media.txt) are cut on fixed cells by sheets/owl_cut.py <key> (owl, swift, dfly, vulture, goose).
- Ladybug Lane: 1-3 ladybugs walk gently on the Canva walk cycle (cr_lbw_0..5, LBW_A anchors), pausing and turning now and then.
- Lightning art is the user's Grok set (lightning/src, cut by lightning/cut.py on fixed cells): fx_charge0-5 ring around Grumble, fx_bolt0-5 strike (feeler, main bolt, ground burst, breaking pieces), fx_limp0-5 ground impact (flash, crackling dome, dirt, smoke; bottom = ground line), fx_tgt_y / fx_tgt_r / fx_tgt_g target ring. The target lies flat on the ground in perspective around Todd's feet (TGT: width, squash, centre offset), never rising above the ground line: drawTarget(0) draws its back half before anything on the ground (items, junk, drops, Todd), drawTarget(1) its front half right after Todd. Yellow while it follows Todd, red / red glow pulsing once it locks.

## Batch v26 notes
- Background flyers sit in their world's depth: every painted setting with flyers has a near-layer cut-out (bd_<k>_front: woods by woods/front.py, mountain/canyon/desert/harvest by woods/fronts.py) drawn over the flyers. Swifts pass in front of the peaks but behind the boulders and cave; dragonflies stay low behind the cattails and cliffs; vultures and geese stay small and far.
- No white edges on fluttering or crawling critters: butterflies (bf_*, bfn_*) and ladybugs (cr_ladybug, cr_lbw_*) were stripped (art/strip_white.py; originals in art/pre_strip). Ladybugs are drawn 25% smaller (23). The porcupine drop is drawn 72 wide (GIFT_W), at least twice a ladybug.
- No code-drawn spark bursts anywhere (burst() is a no-op; user called them dirty bubbles).
- Chapter items: the lost item pops out of the poof and hovers at Todd's face height (LOSTY) in a soft golden glow, clear of Todd and apart from the waffles; the chapter scene has no Skip button; the use beat and the cheer last longer (2.4 s, 3.2 s).
- Barn-zooka: 5 loads, one of each animal (shuffled), then a STAMPEDE of all four. Shoe Horn always 5 honks (the test link no longer cuts ammo).
- The Noggin Bucket stays on and shows with any held item: the bucket item art (bucket_hat, cut above its handle) is placed by Todd's eyes in every pose (BKEYE, art/bucket_hat.py). Bucket + lightning: a caught bolt bounces back at Grumble on its own after .35 s (no button).
- Bear Handed's chip reads just its name. The level-clear card has no "Clear bonus" row (it was hidden leaderboard-less score). The pause card shows the level number and name. Screen shake stops while paused.
- Difficulty: junk gravity keeps climbing to level 30 (grav), Booster flies faster with the levels (boostPace, to 1.5x).
- A super wipes out any junk, syrup drips and lightning already in the air. Single quill hits no longer freeze the frame (no hitstop), so the Porcu-Popper doesn't stutter. Honeybun soot clears in 1.3 s. Grumble says "MY EARS!" on a honk.
- Booster Beam: Booster always hovers on the roomy side of Grumble and switches sides if Grumble drifts past the screen edge, so the beam never fires out of his back.
- Touch: a second finger only takes over steering once it actually drags (16 px), so a quick tap with another finger fires without breaking the steering thumb. Paddle: the swing turns to the nearest incoming junk and its hit window is wider and longer. Waffles are grabbed by any part of Todd, in the air or bouncing at his feet.

