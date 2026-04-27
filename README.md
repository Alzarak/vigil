# Vigil

[![WoW Midnight 12.0.5](https://img.shields.io/badge/World%20of%20Warcraft-Midnight%2012.0.5-F8B700?logo=battlenet&logoColor=white)](https://worldofwarcraft.blizzard.com/)
[![Lua](https://img.shields.io/badge/Lua-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![GitHub](https://img.shields.io/badge/GitHub-Alzarak%2Fvigil-181717?logo=github)](https://github.com/Alzarak/vigil)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-DA7857?logo=anthropic)](https://claude.ai/code)

A 5-man party cooldown tracker for **World of Warcraft: Midnight** (patch 12.0+). Vigil shows a compact icon strip of party members' defensives, externals, interrupts, stuns, roots, and major healing cooldowns so healers, tanks, and DPS can coordinate without guessing.

The addon fills the gap left by OmniCD, which broke at the Midnight launch ("Addonpocalypse") when Blizzard restricted the events addons used to track party member casts. Vigil works within those restrictions by using addon-to-addon synchronization as the sole tracking source.

**Primary use case:** Mistweaver Monk healer in Mythic+ keys.

---

## How It Works

In WoW Midnight 12.0+, both `COMBAT_LOG_EVENT_UNFILTERED` and `UNIT_SPELLCAST_SUCCEEDED` are silently restricted for party member unit tokens. Addons cannot detect when a party member casts a spell via any documented event. This is a Blizzard limitation, not an addon limitation, and is what broke the entire pre-Midnight cooldown-tracker ecosystem.

Vigil works around this by treating addon-message broadcasts as the only data source:

1. **Loadout broadcast** — on group form, zone-in, or talent change, each Vigil client sends its spec + per-spell talented cooldowns to the party via `SendAddonMessage`. Peers cache it and render the player's full spell roster immediately.
2. **Cast broadcast** — when a Vigil client casts a tracked spell (detected via `UNIT_SPELLCAST_SUCCEEDED` for the `player` token, which still works because only `partyN` tokens are restricted), it sends a cast notification. Peers start a countdown timer.
3. **Non-Vigil party members are not displayed** — there is no documented event that surfaces their casts. Showing static decorative icons would create false impressions of tracking; an empty row is the right trade.

The implication: **Vigil's value scales with adoption**. A party of all-Vigil users gets full tracking. A party where you're the only Vigil user shows an empty frame (your own row is excluded — the native Cooldown Manager handles self).

---

## Status and Metrics

| Metric | Count |
|---|---|
| Lua source files | 5 |
| Lines of code | 1,182 |
| Spells tracked | 96 |
| Categories | 6 (INTERRUPT, STUN, ROOT, DEFENSIVE, EXTERNAL, HEALING) |
| Classes covered | 13 (all of them) |
| Slash commands | 12 |
| Build version | 0.1.30 |

### Spell coverage by category

| Category | Spells |
|---|---:|
| DEFENSIVE | 37 |
| STUN | 15 |
| EXTERNAL | 15 |
| INTERRUPT | 14 |
| HEALING | 11 |
| ROOT | 4 |

### Spell coverage by class

| Class | Spells | Class | Spells |
|---|---:|---|---:|
| Death Knight | 8 | Mage | 7 |
| Demon Hunter | 7 | Monk | 6 |
| Druid | 8 | Paladin | 11 |
| Evoker | 8 | Priest | 9 |
| Hunter | 7 | Rogue | 5 |
| Shaman | 8 | Warlock | 4 |
| Warrior | 8 | | |

---

## Getting Started

### Install

Clone or download the repository, then copy the `Vigil/` folder into your WoW AddOns directory:

```
<WoW install>/_retail_/Interface/AddOns/Vigil/
```

Common WoW install paths:
- **Windows**: `C:\Program Files (x86)\World of Warcraft\_retail_\`
- **macOS**: `/Applications/World of Warcraft/_retail_/`

To find your install path: open the Battle.net launcher → World of Warcraft → ⚙ → "Show in Explorer" / "Show in Finder".

After copying, the resulting structure should be:

```
<WoW install>/_retail_/Interface/AddOns/Vigil/
├── Vigil.toc
├── SpellDB.lua
├── Config.lua
├── Sync.lua
├── Display.lua
└── Vigil.lua
```

### Enable in-game

1. Launch WoW.
2. At the character select screen, click **AddOns** (bottom-left).
3. Confirm "Vigil" is listed and checked.
4. If marked "Out of Date," toggle **"Load out of date AddOns"** at the top.
5. Log in. Type `/console scriptErrors 1` then `/reload` so Lua errors surface in chat.

### Slash commands

| Command | Description |
|---|---|
| `/vigil` | Toggle the display |
| `/vigil show` / `hide` | Force show/hide |
| `/vigil lock` / `unlock` | Lock/unlock for dragging |
| `/vigil reset` | Reset frame to default position |
| `/vigil status` | Print loaded build, DB size, peer count, debug flag |
| `/vigil dump [N]` | Inspect what Vigil knows about partyN |
| `/vigil simulate` | Fire a 30s test timer on each party row |
| `/vigil test` | Toggle 4 fake party members for positioning / UI testing |
| `/vigil events` | Dump recent event-handler log |
| `/vigil debug` | Toggle verbose debug prints |
| `/vigil version` | Print loaded build |
| `/vigil help` | Show all commands |

### First test

1. `/vigil test` — 4 fake party members appear. Drag the frame to position.
2. `/vigil simulate` — fires a 30-second test timer on each row to verify the icon sweep, glow, and tooltip.
3. `/vigil test` again to clear when done.

For real testing, get at least one other Vigil user in your party. `/vigil status` will report `vigilPeers >= 1` once their loadout broadcast arrives.

---

## Repository Structure

```
vigil/
├── Vigil/                       # The addon itself (copy this folder into AddOns/)
│   ├── Vigil.toc                # Addon manifest, interface 120005, file load order
│   ├── SpellDB.lua              # Spell database (96 entries) + spec/class helpers
│   ├── Config.lua               # SavedVariables, all slash commands, AddonCompartment hook
│   ├── Sync.lua                 # SendAddonMessage broadcast + receive; cache; timers
│   ├── Display.lua              # Frame creation, icon rendering, drag, OnUpdate sweep
│   └── Vigil.lua                # Event registration + dispatcher; event log
│
├── CLAUDE.md                    # Architecture spec, API constraints, design decisions
├── Blizzard_APIDocumentationGenerated/   # Reference: WoW 12.0.5 API docs (read-only)
├── wow-ui-source/               # Reference: full Blizzard UI source for the patch (not used at runtime)
└── README.md                    # This file
```

---

## Architecture Summary

The full design rationale lives in [CLAUDE.md](CLAUDE.md). Key points:

- **Sync-only data flow**: see "How It Works" above. Combat-log fallback is dead in 12.0+.
- **Class-based icon seed has been removed**: only Vigil-broadcasted party members get rows. No speculative rendering.
- **Talented cooldowns**: the broadcaster computes its own talented CD via `C_Spell.GetSpellCooldownDuration(spellID, true)` (not restricted) and includes it in the broadcast. Receivers use the broadcast value as authoritative.
- **Display**: one row per Vigil-broadcasting party member, class-colored name, spell icons sorted by category (`INTERRUPT → STUN → ROOT → DEFENSIVE → EXTERNAL → HEALING`).
- **No external libraries**: pure Lua, no Ace3, no LibStub. The TOC lists only the 5 source files.
- **AddonCompartment**: minimap entry point uses Blizzard's native `## AddonCompartmentFunc:` hook rather than LibDBIcon.

### What's blocked in 12.0+

| Event / API | Status |
|---|---|
| `COMBAT_LOG_EVENT_UNFILTERED` for `partyN` source | **Restricted** — does not fire |
| `UNIT_SPELLCAST_SUCCEEDED` for `partyN` token | **Restricted** — does not fire |
| `UNIT_AURA` for party tokens | **Restricted** (same class) |
| `C_Spell.GetSpellCooldown` in M+ | **Restricted** — returns nil |
| `UNIT_SPELLCAST_SUCCEEDED` for `player` token | Works |
| `C_Spell.GetSpellCooldownDuration(id, true)` | Works |
| `SendAddonMessage` / `CHAT_MSG_ADDON` | Works |

---

## Reporting Issues

Found a bug, wrong cooldown, missing spell, or have a suggestion?

[Open an issue on GitHub](https://github.com/Alzarak/vigil/issues)

When reporting, please include:

- WoW build version
- Output of `/vigil version` and `/vigil status`
- Output of `/vigil events` if the issue is around group/zone transitions
- Steps to reproduce
- Whether other party members had Vigil installed

Spell DB corrections are especially welcome — the hand-curated entries may have wrong cooldowns or stale spell IDs after Blizzard hotfixes. Run `/vigil debug` and paste the `Vigil dbg` lines for any cast where you suspect a wrong value.

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) — see [LICENSE](LICENSE) for the full text.

You are free to use, modify, and distribute Vigil with attribution.

---

## Acknowledgements

- **Blizzard Entertainment** — for the [`wow-ui-source` reference dump](https://github.com/Gethe/wow-ui-source) used during development to verify which APIs are addon-callable and which are restricted.
- **OmniCD** by Treebonker — the original party cooldown tracker; Vigil exists to fill the gap left when 12.0 broke it. The `Sync Mode` concept in OmniCD was foundational.
- **Anthropic Claude** — Vigil was built collaboratively using Claude Code. Architecture decisions, spell database curation, and the sync-only pivot after empirical confirmation of API restrictions were all worked out in conversation.
- The WoW addon developer community on Wago, CurseForge, and Reddit, whose post-Addonpocalypse autopsies confirmed that the combat-log dead-end is real and not a workaround-able bug.

---

## Contact

**Alzarak** — [@Alzarak on GitHub](https://github.com/Alzarak)

For questions or contributions, open an issue or PR on the repository.
