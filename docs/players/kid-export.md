# Export to KID File

The **Export to KID file** button sits at the top of the *Current Armor List* page, next to *Register Custom Keyword* and *Remove Custom Keyword*. It turns the per-armor curation you've done in MCM (see [Armor Curation](armor-curation.md)) into a permanent, shareable file.

!!! info "Requires PapyrusExtenderSSE"
    This button needs [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) for its source-plugin lookup and ESL-safe FormIDs. Without it the button pops an error; the rest of the mod works normally. See [Troubleshooting](troubleshooting.md#the-export-to-kid-button-says-papyrusextendersse-is-required).

## What it does

Writes a snapshot of every (keyword, armor) pair you've currently flagged to `Data\SLArousedNG_Custom_KID.ini`. KID — if installed — reads this file at the next game start and re-applies all the keywords automatically, **before any save data is touched**.

## Why you'd use it

- **Survives new characters / new saves.** MCM toggles live in your cosave. A fresh save starts clean. The KID file persists at the modlist level, so a brand-new character automatically gets the same curation.
- **Shareable.** The file is plain text. Send it to a friend along with the armor mods you're using and they get your exact curation.
- **Backup-friendly.** If you wipe your save, the KID file rebuilds your curation in seconds.

## What gets exported

- All 8 built-in keyword toggles for every Armor in your `player`-bound FormList — your explicit clicks PLUS items where the mod auto-detected the keyword as already-baked-in by the source ESP.
- All custom keyword toggles on both body-slot and bikini-slot items.
- Each entry uses **load-order-current FormIDs**, with ESL/ESL-FE plugin handling done correctly.

## What does NOT get exported

- *Counts as Clothing* state — it's a metadata flag, not a real Keyword, so there's nothing for KID to distribute.
- Any toggle you've set OFF — only "on" entries appear in the file.
- Arousal effects, sliders, plugin settings — those are saved separately via the General page's *Export Settings* (which writes a JSON, not a KID file). See the [MCM Reference](mcm-reference.md#general-settings).

## Walkthrough

1. Get your curation into the MCM. Equip various outfits across whichever actors you care about (player, followers), toggle keywords ON as you want them. The mod's auto-detect picks up most ESP-baked items automatically — you just need to *visit* them in the MCM with the actor wearing them.
2. Click **Export to KID file**.
3. A popup confirms `Exported N keyword entries to Data\SLArousedNG_Custom_KID.ini`.
4. Restart Skyrim (or load any save) and KID applies the file at game start. Check `Documents\My Games\Skyrim Special Edition\SKSE\po3_KeywordItemDistributor.log` to confirm — look under `**RESULT**` for your keywords getting `added to N/total` lines.

## Caveats

- Each click **overwrites** the file. If you've been hand-editing it (adding filters, tweaking chances), keep your manual edits in a separate `*_KID.ini` file — KID merges them all on load.
- The IDs reflect your current load order. If you merge or reorder plugins, re-export. (MergeMapper at the consumer side handles small reshuffles automatically — but big restructures need a re-export.)
- Under Mod Organizer 2, USVFS catches the write and stores the file in your active **overwrite** mod (often called *Overwrite* or *SKSE Output*). Refresh MO2's left pane to see it. KID still finds it via USVFS, no manual move needed — but for cleanliness, you can cut the file into a dedicated mod folder later.

## Sharing & migration workflows

### "I want to share my curation with someone else"

- Click **Export to KID file**.
- Send them `Data\SLArousedNG_Custom_KID.ini` (or pack it as a tiny mod with just that one file).
- They drop it into their `Data\` folder and launch Skyrim. KID applies it on next game start. Their MCM picks up the same state.
- Caveat: their load order needs the same armor mods loaded (or at least the same plugin filenames) for the FormIDs in the file to resolve.

### "I just merged a bunch of armor mods together"

- Re-export. The file embeds load-order-current IDs which change after a merge.
- MergeMapper at the consumer side can auto-remap if you have it installed — so even without a re-export, things may keep working — but a fresh export is cleaner.

!!! tip "The full KID INI format"
    For a comprehensive reference on the KID file format and exactly how this mod's exporter fits into it, see the [KID Reference](../KID_Reference.md).
