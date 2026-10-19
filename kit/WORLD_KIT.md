# Bonkd World Kit: the formula for a new hero and world

Bonkd is built so each playable hero gets a complete world of their own, while the game underneath stays the same.
This file lists every slot a world must fill. `kit/todd_world.json` is the full inventory of Todd's world, generated from the source.
A new world fills every slot with its own assets, and uses nothing from another hero's world.

## 1. What every world shares (engine, never rebranded)
- The gameplay loop, controls, screen scale, edge and outline standard, art pipeline and test scripts.
- **Grumble and GRUMBLEMAX.** He's the villain in every world. That covers his art (c_grum_*, c_mega_*), his face rules, and the boss fight's phases and HP.
- **Waffle values and the wallet.** Every world has 10 waffle tiers with the same values (5, 25, 100, 250, 500, 1,000, 2,000, 5,000, 10,000, 25,000) and the same drop weights. Each world draws and names its waffles its own way, but the backend only ever counts waffles.
- Lives: 3 a day plus 1 per Nibble, reset at midnight GMT, plus bought lives. These are shared across heroes.
- The leaderboard, profiles, link codes, store purchases (Supabase) and stats.

## 2. What every world owns (rebranded in full)

| Slot | Todd's world | Count | A new world needs |
|---|---|---|---|
| Hero poses | c_todd_* | 67 | full body (stand, armless game body, bucket variant), 6-frame walk, run sheet, bonked, KO, throw, cheer; every held item: stand + walk; story poses; eating poses |
| Hero head icon | todd_head (logo head + lump + stars) | 1 | head sticker from the world's logo |
| Helper | Booster (c_boost_*) | 14 | fly cycle, toss, beam progression (open question: does each world get its own helper?) |
| Story | picnic (pr_*, story beats ST, lines) | 7 props + script | opening scene, props, beat timing, lines, Grumble's story poses reused |
| Settings and backdrops | bd_meadow, bd_woods, bd_mountain, bd_canyon, bd_desert, bd_harvest + bd_hideout | 7 | one Gemini backdrop per setting + the boss lair, made to the Setting checklist |
| Level names | 30 + PICNIC | 31 | 5 per setting, matching each backdrop |
| Items, weapons, power-ups | 25 (PW table) | 25 | same roles (thrown, launcher, shield, heal, slow-mo, giant, damage boost, waffle rain, helper strike), all reskinned to the theme |
| Weapon art | x_*, g_*, ga_*, p_*, m_*, n_*, an_* | 50 | held art, empty and front layers, ammo, drop art, store icon |
| Grumble's junk | j_* (anvil, bowling, brick, coconut, pan, safe) | 6 | 6 junk pieces in the theme (same hit sizes and metal flags) |
| Grumble's reactions to weapons | c_grum_<effect> | per weapon | one reaction pose per new weapon effect |
| Waffles | w_* (plain, chicken, report, unicorn, ring, refund, tree, barrow, truck, lotto) + w_magic | 11 | 10 tier skins + the boss's magic version, with themed names and quips |
| Effects | fx_* | 29 | themed hit and fire effect sheets per weapon (Marvel vs. Capcom style) |
| Sounds | 56 synth + 19 clips | 75 | fire and hit sound per weapon, hero voice beats, waffle pickup, helper in/out |
| Music | "The Fun Starts Here" set | 5 cuts | a track that fits the world's mood, cut into menu, loop, boss and sting |
| Title and logo | logo_text_only + label | 2 | world logo (same "Don't get BONKD!" lettering, the hero's head) + store label |
| Store | "The Waffle Store" | 1 | store branded for the hero; prices in waffles stay the same |
| Chapters | 5 unlock scenes (oatmeal, shoe horn, bear handed, gum, wafflicious) | 5 | 5 themed unlocks + scene art |
| Picnic and ending | ending at the picnic | 1 | ending back at the world's opening spot |

## 3. Pipeline per asset type (the formula)
1. **Hero reference first.** Lock the approved full-body art and write a spec block like audit/todd_spec.txt (head size, proportions, colors, facing, arm rules). Paste it verbatim into every hero prompt.
2. **Canva** makes character poses and animation sheets (6 frames, 2 rows of 3, the single pose art as a reference). Cut them with art/cut.py (STRIP=1, SIZE=640, DRAWN=<game units>), anchor them (face, halo, ears or feet) and check them in the game.
3. **Gemini** makes the backdrops (the user runs the prompt, with art/src_bd_mountain.png attached).
4. **ChatGPT** finishes logo lettering.
5. **Waffles, items and junk** use the object spec (audit/obj_spec.txt) with the SIMPLICITY line and their in-game size.
6. **Everything is checked** on a computer screen and on a phone with real touch, beside the hero and the berry bush for edge weight, before it's shown.
7. **No code-drawn art** anywhere a player looks. Code only places, animates and composites real art.

## 4. Engine work needed before a second world (planned, not built)
- **One WORLD config object** that the engine reads for everything in section 2: art key prefixes, the PW item table, waffle names and quips, levels and BGART, the story script and beats, chapter unlocks, sounds, music, logo, store theme and colors.
- **Per-world asset bundles.** Today the game is one 15 MB page holding Todd's whole world. A second world in the same page would double that, so each world's art and sound has to load only when that hero is picked.
- **Hero select and unlock.** A hero picker on the menu, an unlock for a large waffle price or a small payment, and the unlock stored on the profile (Supabase).
- **Shared progress.** Waffles, lives and leaderboard stay global, and runs are tagged with the hero for stats.

## 5. Next hero: Carlito (planned)
- Nibble #8102 from the Nibbles collection, a raccoon. His story opens with him scavenging by a dumpster at night.
- World: grungy, night time, same animation style. Settings: diner dumpster, alleyway, underground sewer, drainage pond, then inside the drainage facility for the GRUMBLEMAX battle.
- Theme: trashy waffles and used-food or trash weapons, power-ups and items, with playful names. Waffle values stay the same as Todd's.
- Store: the "coming soon" coin is his silhouette only (art/st_carlito.webp, from carlito/silhouette_src.jpg). Nothing else that gives him away.
- Unlock: a large waffle price, or a small payment.
