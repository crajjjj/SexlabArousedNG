# SexLab Aroused NG — User Guide

A guide for players. If you're a mod author integrating with the arousal framework, see [README.md](../README.md) instead — that doc covers the Papyrus / SKSE API in depth.

---

## Table of contents

- [What this mod actually does](#what-this-mod-actually-does)
- [Installation](#installation)
- [First-time setup](#first-time-setup)
- [How arousal works](#how-arousal-works)
- [The MCM, page by page](#the-mcm-page-by-page)
- [Per-armor curation (the Current Armor List page)](#per-armor-curation-the-current-armor-list-page)
- [Custom keywords](#custom-keywords)
- [Export to KID file](#export-to-kid-file)
- [Built-in arousal keywords cheat sheet](#built-in-arousal-keywords-cheat-sheet)
- [Common workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [References & further reading](#references--further-reading)

---

## What this mod actually does

SexLab Aroused NG is the underlying *arousal system* for a family of adult Skyrim mods. Every actor (you, every NPC) gets a single **arousal number** — a float typically in the 0–100 range — that goes up and down over time based on what's happening around them.

The mod by itself doesn't really *do* anything visible — it tracks the number and provides an MCM to inspect and curate it. The interesting behavior comes from **dependent mods** that read the number and react: dialogue changes, NPC approaches, animations, equipment behavior, magic effects, etc.

What this mod *does* give you directly:

- A persistent per-actor arousal value that survives saves.
- An MCM to inspect any actor's arousal and tweak how it's calculated for them.
- A per-armor flagging system — mark specific items as "naked", "bikini", "sexy", "slooty", "illegal", etc., and the mod takes those into account when computing exposure.
- The ability to register your own custom keywords and apply them to items, then **export everything to a KID file** so the curation survives new saves and can be shared.

---

## Installation

### Required

| Mod | Why |
|---|---|
| **SKSE64** (Skyrim Script Extender) | This is an SKSE plugin |
| **Address Library for SKSE Plugins** | Standard SKSE plugin runtime dep |
| **PapyrusUtil SE** | All persistent state and config files use it |
| **PapyrusExtenderSSE** | Required by the *Export to KID file* MCM button. Without it the rest of the mod still works, but the export button will pop up an error |

### Recommended

| Mod | Why |
|---|---|
| **Keyword Item Distributor (KID)** | Reads the file you export from MCM and applies it at game start. Without KID the export is just a text file |
| **MergeMapper** | Auto-remaps FormIDs after plugin merges. Useful if you've merged armor mods |
| **An animation system** — Open Animation Replacer (recommended) or FNIS/Nemesis | Drives the arousal animations. Picked during FOMOD install |

### FOMOD options

When you install via Mod Organizer 2 / Vortex you'll be asked to pick:

- **Animation System** — Open Animation Replacer (recommended), FNIS, or None.
- **Patches** — Dummy ESPs (for backwards compat with mods expecting `OAroused.esp` / `OSLAroused.esp`), SexLab Eager NPCs patch, Paradise Halls Enhanced patch. Pick as appropriate to your modlist.

---

## First-time setup

1. Install via mod manager, complete the FOMOD wizard.
2. Launch Skyrim and load a save (or new game).
3. Open the MCM: pause menu → **Mod Configuration** → **SLO Aroused NG**.
4. The first thing you'll see is a status splash. Click any tab on the left.
5. Walk through **System** (the General page) and read tooltips. Defaults are reasonable.
6. If you want exposure to depend on whether actors actually *see* nudity, leave **Use LOS** ON. If you want it to count any nearby nudity regardless of LOS, turn it OFF.
7. Set the **Notification Key** to a key that doesn't conflict with your other mods — pressing it shows your arousal value in the corner.

That's enough to start playing. Everything below is optional curation.

---

## How arousal works

In 30 seconds:

- Each actor has a single arousal number.
- It rises when arousing things happen: seeing nudity, having sex, wearing certain armor types, being trapped in devices.
- It falls passively over time, and drops fast after orgasm.
- Dependent mods react when it crosses thresholds.

In a bit more depth:

- Each actor's number is the **sum of all currently-active effects** — both built-in (the default plugin contributes nudity exposure, sleep decay, orgasm cooldown, denial buildup) and from any other plugin (SexLab, Devious Devices, OStim).
- Most timed effects use **game days** as the time unit (one in-game day = 24 in-game hours).
- The arousal value isn't clamped to 0–100 by default — it's just a float. The convention is 0–100 and most consumer mods assume that range, but individual effects can push outside it.

For the full math, see the *Arousal Model Overview* section of [README.md](../README.md).

---

## The MCM, page by page

### General Settings

Home page. Key controls:

- **Notification Key** — press in-game to print your arousal to the corner. With crosshair on an NPC, also pins that NPC as your "Puppet" for inspection (see below).
- **Enable Desire Spell** — gives you a power that displays your own arousal as a buff/debuff.
- **Enable for Male/Female Animation** — whether arousal animations play for each gender.
- **Use LOS** — whether actors need line-of-sight on naked actors to gain exposure.
- **Naked Only** — when ON, only the *Naked* keyword counts toward exposure (Bikini / Sexy / Slooty / etc. don't).
- **Enable Notifications** — corner messages from the mod.
- **Disabled** — full off switch.

At the bottom is the **Plugin List** showing which integrations are active. The four built-in ones:

| Plugin | Drives |
|---|---|
| **Default** | Naked exposure, post-orgasm satisfaction decay, chastity denial buildup, sleep arousal decay |
| **SexLab** | Per-stage arousal during SexLab animations, animation-tag scoring |
| **Devious Devices** | Device-equipped arousal, belt/plug denial modifiers, device-stacking multiplier |
| **OStim** | OStim NG (and legacy v<29) thread tracking, observer LOS arousal scaling |

The **Import** / **Export** buttons here (different from the KID export) save and restore your *MCM settings* — sliders, toggles, key bindings — as JSON via PapyrusUtil. Not to be confused with the per-armor KID export.

### Status

Real-time arousal numbers for actors the mod is tracking, plus a summary of recent events.

### Puppet Master

Inspect any actor's arousal effects in detail. Pick them from the **Select Puppet** dropdown — by default you can see yourself, your follower, and the actor you last pinned with the NotificationKey.

- **Block Arousal** — freeze this actor's arousal calculations (no updates).
- **Lock Arousal** — keep their arousal pinned at the current value.
- **Exhibitionist** — flag them as enjoying being seen naked. Changes some plugin calculations.
- **Gender Preference** — what this actor finds arousing.

The list below shows every static arousal effect on this actor with the current value, the timed function (if any), and parameters. You can edit values directly via input fields on each row.

### Current Armor List

Per-item keyword curation — covered fully in the next section.

### Plugins

Each integration plugin has its own MCM page with settings specific to that integration: the Default plugin has sliders for nudity rate, orgasm satiation, sleep decay, etc. Devious Devices has device-rate sliders. SexLab has per-stage bonuses. OStim has thread / observer toggles and rate scaling.

You don't normally need to touch these unless you want to tune the feel.

---

## Per-armor curation (the *Current Armor List* page)

This is the most player-facing feature of the mod. The page lets you mark specific armor items with arousal-relevant keywords, on a per-piece basis.

### Layout

- **Select Actor** picker at the top — pick whose outfit you want to inspect (you, follower, puppet).
- **Equipped Items** column on the left shows their currently-worn pieces:
  - **Body armor** (slot 32) — toggles for **Naked, Bikini, Sexy, Slooty, Illegal, Posh, Ragged, Counts as Clothing**.
  - **Shoes/boots** (slot 37) — **High Heels** toggle.
  - **Items in bikini slots** (44, 45, 48, 49, 52, 56, 58) — **Bikini** + **Counts as Clothing** toggle per item, plus your custom keyword toggles.

Toggle ON to apply the keyword to that Armor template (it's per-template, so every actor wearing the same Armor template inherits the toggle). Toggle OFF to remove it.

### How toggles persist

- Each toggle writes to the SKSE cosave via PapyrusUtil's StorageUtil. The flag survives saves and quits.
- On every game reload, the mod re-applies the toggled keywords to their Armor records — so the curation comes back even after you exit and relaunch Skyrim.
- If an Armor record **already has** the keyword baked into its source ESP (e.g. TAWoBA armors that ship with `SLA_ArmorHalfNakedBikini` pre-applied), the toggle lights up automatically when you open the page, AND the mod silently records that match so it shows up in your *Export to KID file* output.

### "Counts as Clothing" specifically

This one's not a keyword — it's a state flag. Marking an item "Counts as Clothing" tells the naked-detection logic to treat the wearer as clothed even if they're showing skin. Useful for body suits, tights, see-through items, etc., that you don't want triggering the "naked" state.

---

## Custom keywords

Beyond the 8 built-in keywords, you can register **any keyword** from any loaded ESP as a custom toggle.

### Adding a custom keyword

1. Find the keyword's **EditorID** — usually documented in the keyword-providing mod's description (e.g. `SLA_ArmorHalfNakedBondage`, `BHUNP_SkinTight`).
2. On the *Current Armor List* page, click **Register Custom Keyword**.
3. Type the EditorID exactly and confirm.
4. The keyword now appears as a toggle on every body-slot armor and every item in the bikini slots.

### Removing a custom keyword

Click **Remove Custom Keyword** and type the EditorID. It's removed from the registry; previously toggled items keep the keyword unless you toggle them off individually first.

### Limits

- Maximum ~18 custom keywords are visible on a bikini-slot item simultaneously (Papyrus has a 128-element array limit; we use `bikini_count × keyword_count` for the toggle grid). With 7 worn bikini-slot items you can show ~18 per item. The actual StorageUtil data is unlimited — only the on-screen toggles are capped.
- The EditorID must exactly match a keyword in your load order — if not, you get an error popup.

---

## Export to KID file

Located at the top of the *Current Armor List* page, next to *Register Custom Keyword* and *Remove Custom Keyword*.

### What it does

Writes a snapshot of every (keyword, armor) pair you've currently flagged to `Data\SLArousedNG_Custom_KID.ini`. KID — if installed — reads this file at the next game start and re-applies all the keywords automatically, **before any save data is touched**.

### Why you'd use it

- **Survives new characters / new saves.** MCM toggles live in your cosave. A fresh save starts clean. The KID file persists at the modlist level, so a brand-new character automatically gets the same curation.
- **Shareable.** The file is plain text. Send it to a friend along with the armor mods you're using and they get your exact curation.
- **Backup-friendly.** If you wipe your save, the KID file rebuilds your curation in seconds.

### What gets exported

- All 8 built-in keyword toggles for every Armor in your `player`-bound FormList — your explicit clicks PLUS items where the mod auto-detected the keyword as already-baked-in by the source ESP.
- All custom keyword toggles on both body-slot and bikini-slot items.
- Each entry uses **load-order-current FormIDs**, with ESL/ESL-FE plugin handling done correctly.

### What does NOT get exported

- *Counts as Clothing* state — it's a metadata flag, not a real Keyword, so there's nothing for KID to distribute.
- Any toggle you've set OFF — only "on" entries appear in the file.
- Arousal effects, sliders, plugin settings — those are saved separately via the General page's *Export Settings* (which writes a JSON, not a KID file).

### Walkthrough

1. Get your curation into the MCM. Equip various outfits across whichever actors you care about (player, followers), toggle keywords ON as you want them. The mod's auto-detect picks up most ESP-baked items automatically — you just need to *visit* them in the MCM with the actor wearing them.
2. Click **Export to KID file**.
3. A popup confirms `Exported N keyword entries to Data\SLArousedNG_Custom_KID.ini`.
4. Restart Skyrim (or load any save) and KID applies the file at game start. Check `Documents\My Games\Skyrim Special Edition\SKSE\po3_KeywordItemDistributor.log` to confirm — look under `**RESULT**` for your keywords getting `added to N/total` lines.

### Caveats

- Each click **overwrites** the file. If you've been hand-editing it (adding filters, tweaking chances), keep your manual edits in a separate `*_KID.ini` file — KID merges them all on load.
- The IDs reflect your current load order. If you merge or reorder plugins, re-export. (MergeMapper at the consumer side handles small reshuffles automatically — but big restructures need a re-export.)
- Under Mod Organizer 2, USVFS catches the write and stores the file in your active **overwrite** mod (often called *Overwrite* or *SKSE Output*). Refresh MO2's left pane to see it. KID still finds it via USVFS, no manual move needed — but for cleanliness, you can cut the file into a dedicated mod folder later.
- **PapyrusExtenderSSE is required** for this button to work. Without it the popup explains what to install. The rest of the mod still functions normally.

---

## Built-in arousal keywords cheat sheet

| Internal name | MCM toggle label | What it represents | Affects naked detection? |
|---|---|---|---|
| `EroticArmor` | Naked | Body covering that exposes too much to count as "clothed" | Yes — directly triggers the naked state |
| `SLA_ArmorHalfNakedBikini` | Bikini | Bikini-style outfits (TAWoBA et al.) | Yes — soft naked |
| `SLA_ArmorPretty` | Sexy | Form-fitting, attractive but not revealing | Mild exposure |
| `SLA_ArmorHalfNaked` | Slooty | Revealing without being bikini-cut | Soft naked |
| `SLA_ArmorIllegal` | Illegal | Outfits forbidden in towns; some mods trigger guard reactions | No (but plugins react) |
| `ClothingRich` | Posh | Fancy clothes | Changes NPC reactions |
| `ClothingPoor` | Ragged | Beggar / worn attire | Changes NPC reactions |
| `SLA_KillerHeels` | High Heels | Heels / heeled boots | Affects walk animations |
| *(state-only)* | Counts as Clothing | Mark a revealing item as NOT triggering naked detection | Overrides naked state |

---

## Common workflows

### "I want my arousal to climb faster"

- Turn OFF **Use LOS** (any nearby naked actor counts, not just visible ones).
- Increase exposure rate sliders in the **Default** plugin page.
- Turn OFF **Naked Only** so Bikini/Sexy items also contribute.

### "TAWoBA's armor already counts as Bikini but for this one outfit I want it not to"

- Open *Current Armor List* with that outfit equipped.
- Click the Bikini toggle OFF. The mod removes the keyword from the Armor record AND adds the item to its "off" persistence list, so it stays off across reloads.

### "I want to share my curation with someone else"

- Click **Export to KID file**.
- Send them `Data\SLArousedNG_Custom_KID.ini` (or pack it as a tiny mod with just that one file).
- They drop it into their `Data\` folder and launch Skyrim. KID applies it on next game start. Their MCM picks up the same state.
- Caveat: their load order needs the same armor mods loaded (or at least the same plugin filenames) for the FormIDs in the file to resolve.

### "I just merged a bunch of armor mods together"

- Re-export. The file embeds load-order-current IDs which change after a merge.
- MergeMapper at the consumer side can auto-remap if you have it installed — so even without a re-export, things may keep working — but a fresh export is cleaner.

### "I want to back up my settings (sliders, toggles, plugin options) — not the armor flags"

- Go to **General Settings** → **Export Settings**. Writes `SLAX/Settings.json` via PapyrusUtil's JsonUtil.
- Restore via **Import Settings**.

### "I want to nuke everything and start over"

- **Clear selected actor** on General page wipes data for the currently-selected actor.
- **Clear all data** wipes the entire mod's persistent state.

---

## Troubleshooting

### My arousal isn't climbing at all

- Check the **Notification Key** on yourself — does the corner message show a number? If not, the mod isn't tracking you. Try toggling **Disabled** off and on.
- Check **Block Arousal** / **Lock Arousal** in Puppet Master — they should both be OFF on you.
- Check the **Default** plugin is enabled in the General page Plugin List.
- Check that you don't have **Naked Only** ON when you're trying to test with a clothed naked-keyword item.

### The Export to KID button says "PapyrusExtenderSSE is required"

- Install [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) (powerof3's mod). That's the only dependency the export needs that the rest of the mod doesn't.
- Re-launch Skyrim. The button will work normally.

### My exported KID file is empty

- You haven't toggled anything in MCM yet. Open Current Armor List for someone wearing armor, toggle a keyword on, then export.
- Check the popup count — if it says `Exported 0`, that confirms the FormLists are empty.

### My exported KID file isn't being applied at game start

- Verify the filename: must end in `_KID.ini`. Default is `SLArousedNG_Custom_KID.ini`, don't rename it.
- Check `Documents\My Games\Skyrim Special Edition\SKSE\po3_KeywordItemDistributor.log` — should list your file under the `**INI**` block near the top.
- Under MO2: confirm the mod containing the file is *enabled* in the left pane.

### MCM toggles look different from what I see in-game

- Close and reopen MCM to refresh the page; the displayed toggles are read once on page open.
- If a keyword is being stripped mid-session by some other mod, check console: click the item, type `hk <KeywordEditorID>`. Should return `1.00` if present.

### "I see only the Naked toggle for one armor but I want all 8"

- The 8 toggles only appear for the **body slot (32) armor** you're currently wearing. For items in other slots (foot, bikini slots), only the relevant subset shows up.

### My follower's armor is missing from the list

- Switch the **Select Actor** picker to the follower. The Current Armor List always operates on whichever actor is selected.
- The picker only includes the player, followers tracked via the SLA follower alias, the most recent puppet (NotificationKey crosshair pick), and the most-aroused NPC in the location. If your follower isn't appearing, press the NotificationKey while looking at them — they'll show up as a "Puppet" option.

---

## References & further reading

- **For mod authors**: [README.md](../README.md) — full API reference, plugin lifecycle, integration patterns, the multi-fork compatibility shim.
- **KID INI format details**: [docs/KID_Reference.md](KID_Reference.md) — comprehensive reference for the KID file format with a section on this mod's export.
- **Nexus pages**:
  - [Keyword Item Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/55728) — read the file you export.
  - [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) — required for the export button.
  - [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) — required by the framework.
  - [MergeMapper](https://www.nexusmods.com/skyrimspecialedition/mods/56014) — recommended if you use plugin merges.

Logs to check when things go wrong:

- `Documents\My Games\Skyrim Special Edition\SKSE\sla.log` — this mod's own log.
- `Documents\My Games\Skyrim Special Edition\SKSE\po3_KeywordItemDistributor.log` — KID's log (look here after launching to see how your exported file was processed).
