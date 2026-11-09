# WrathRank

<img src="assets/wrathrank.png" alt="WrathRank shield with an upward arrow" width="96">

WrathRank adds gear scores and upgrade comparisons to item tooltips in **World of Warcraft 3.3.5a (Wrath of the Lich King)**. It uses stat weights for your active talent tree or a scale you select. It has no addon dependencies.

## Install

1. Download the `WrathRank-<version>.zip` release asset and extract it into your client's `Interface/AddOns` folder.
2. Confirm the manifest is at `Interface/AddOns/WrathRank/WrathRank.toc`. Restart the client and enable WrathRank at character selection.
3. Type `/wr` or open **Escape → Interface → AddOns → WrathRank**. Hover an item or open an item link to see the score and the change versus your equipped gear.

This release targets the original 3.3.5a client, interface `30300`. When installing from a source checkout, copy the inner `WrathRank` folder into `Interface/AddOns`.

## Choose a scale

- **Automatic** follows the tree with the most talent points in your active build. It updates when you change talents or switch dual spec. A tie or an unspent build uses a class leveling scale.
- **Class and talent tree** locks the scale to your selection. All 10 classes and 30 trees are listed. Druid and Death Knight also have manual tank options.
- **Custom weights** lets you edit any stat. Blank or zero ignores a stat. Use **Apply** or **Okay** to save, or **Cancel** to discard pending edits. Settings are stored per character and carried forward on update.

`/wr stats` prints the active weights. `/wr auto` switches to automatic scoring. `/wr help` lists the other commands.

## Read the tooltip

The score is the sum of each supported base stat multiplied by its weight. Comparisons show the point change and, when the equipped score is positive, the percentage change in **score**. Rings and trinkets show separate comparisons for each slot. Weapon scoring can use separate main-hand, off-hand, and ranged DPS weights. Equipped items show their own score.

The built-in weights are starting points. Stat caps, gems, enchants, sockets, procs, on-use effects, and set bonuses are outside the calculation. A proc-heavy item can score zero. Weapon comparisons use the current weapon layout, with support for eligible Titan's Grip replacements. Check the item’s equip requirements and unique-equipped rules before replacing gear.

## Weight sources

[WoWSims Wrath](https://github.com/wowsims/wotlk) gear-picker defaults inform the Fury and Protection Warrior, all three Paladin, Survival Hunter, Assassination Rogue, Discipline and Shadow Priest, dual-wield Unholy and tank Death Knight, Elemental and Enhancement Shaman, Fire Mage, Affliction Warlock, and Balance, Feral DPS, and Bear Druid scales. Other trees use role estimates. See the corresponding `ui/<spec>/sim.ts` files in WoWSims.

WrathRank combines separate melee and spell weights for shared ratings, uses one armor weight, and omits unsupported stats. The Elemental and Balance scales add estimated hit weights. Feral DPS converts the reference weapon DPS weight into Feral Attack Power above the 54.8 DPS threshold.

## Development

From the repository root, run `lua5.1 tests/test-wrathrank.lua` (or `lua tests/test-wrathrank.lua` if `lua` resolves to Lua 5.1). The tests simulate the client APIs and exercise talent detection, settings, item scoring, and the score cache. For bug reports, include the WrathRank version, WoW client version, class and talent tree, and the item link or Lua error.

Run `./package.ps1` from PowerShell to build the installable ZIP in `dist/`. The file name comes from the version in `WrathRank/WrathRank.toc`.

WrathRank is released under the [MIT license](LICENSE). The license also preserves credit for the adapted WoWSims weights.
