# Troubleshooting & Logs

When something misbehaves, the logs almost always say why. This page lists where every relevant log lives, how to turn on Papyrus logging, and the fixes for the most common problems.

!!! tip "First stop: Puppet Master"
    Most "arousal isn't doing what I expect" problems are visible on the **Puppet Master** page — open it on yourself and read the live effect list. See the [MCM Reference](mcm-reference.md#puppet-master).

## Where the logs are

All logs live under your **My Games** folder. The exact path depends on your edition:

- **Skyrim SE / AE:** `Documents\My Games\Skyrim Special Edition\`
- **Skyrim VR:** `Documents\My Games\Skyrim VR\`

The paths below use the SE folder; swap in `Skyrim VR` if you are on VR.

| Log | Path | What it tells you |
|-----|------|-------------------|
| **SLA NG plugin log** | `SKSE\SexlabArousedNG.log` | The bundled `SexlabArousedNG.dll` (SKSE plugin) writes here — DLL load, native functions, serialization. If this file is **missing**, the DLL never loaded. |
| **SLA NG script log** | `Logs\Script\User\SLOANG.log` | The Papyrus side of the mod (the framework, plugins, MCM) logs here via its own user log. |
| **SKSE log** | `SKSE\skse64.log` (`sksevr.log` on VR) | Why a plugin was rejected — usually a wrong game version or a missing Address Library. Search it for `SexlabArousedNG`. |
| **Papyrus script log** | `Logs\Script\Papyrus.0.log` | Engine-wide script errors and traces. **Only written when Papyrus logging is enabled — see below.** |
| **KID log** | `SKSE\po3_KeywordItemDistributor.log` | Whether your [exported KID file](kid-export.md) was found and applied. Look under the `**INI**` and `**RESULT**` blocks. |

!!! note "Mod Organizer 2 users"
    Logs still go to the real `Documents\My Games\...` folder, **not** into MO2's virtual file system or the Overwrite folder. Open them directly from Documents.

## Enabling Papyrus logging

The mod's own `SLOANG.log` is always written. The engine-wide `Papyrus.0.log` is only written when Papyrus logging is enabled — turn it on while diagnosing, then turn it back off.

Edit **`Skyrim.ini`** (in the My Games folder above) and add or update this section:

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
bLoadDebugInformation=1
```

Then **launch the game through SKSE**, reproduce the issue, and quit. The fresh log is `Logs\Script\Papyrus.0.log` (older runs roll over to `Papyrus.1.log`, `Papyrus.2.log`).

!!! warning "Mod Organizer 2: edit the profile INI"
    MO2 keeps a per-profile copy of `Skyrim.ini` and ignores the one in Documents. Edit it via **MO2 → Tools → INI Editor → Skyrim.ini**, add the `[Papyrus]` block there, and save. Editing the Documents copy will have no effect.

## Common problems

### My arousal isn't climbing at all

- Check the **Notification Key** on yourself — does the corner message show a number? If not, the mod isn't tracking you. Try toggling **Disabled** off and on.
- Check **Is Arousal Blocked** / **Is Arousal Locked** in Puppet Master — they should both be OFF on you.
- Check the **Default** plugin is enabled in the General page Plugin List.
- If you're testing passive/timed gains with no naked actor nearby, make sure **Naked Only** ("Require naked actors to change arousal") is OFF — when ON it skips arousal updates unless a naked actor is present.
- If you expected passive buildup, note that it comes from the *Timed* effect, not *Naked* — see [Coming from OSL Aroused](tuning-recipes.md#coming-from-osl-aroused).

### The Export to KID button says "PapyrusExtenderSSE is required"

- Install [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) (powerof3's mod). That's the only dependency the export needs that the rest of the mod doesn't.
- Re-launch Skyrim. The button will work normally.

### My exported KID file is empty

- You haven't toggled anything in MCM yet. Open Current Armor List for someone wearing armor, toggle a keyword on, then export.
- Check the popup count — if it says `Exported 0`, that confirms the FormLists are empty.

### My exported KID file isn't being applied at game start

- Verify the filename: must end in `_KID.ini`. Default is `SLArousedNG_Custom_KID.ini`, don't rename it.
- Check `SKSE\po3_KeywordItemDistributor.log` — should list your file under the `**INI**` block near the top.
- Under MO2: confirm the mod containing the file is *enabled* in the left pane.

### MCM toggles look different from what I see in-game

- Close and reopen MCM to refresh the page; the displayed toggles are read once on page open.
- If a keyword is being stripped mid-session by some other mod, check the console: click the item, type `hk <KeywordEditorID>`. Should return `1.00` if present.

### "I see only the Naked toggle for one armor but I want all 8"

- The 8 toggles only appear for the **body slot (32) armor** you're currently wearing. For items in other slots (foot, bikini slots), only the relevant subset shows up. See [Armor Curation](armor-curation.md#layout).

## Reporting a problem

When you report an issue, attach:

1. `SKSE\SexlabArousedNG.log` (or `SKSE\skse64.log` if the plugin log is missing).
2. `Logs\Script\User\SLOANG.log`, and `Logs\Script\Papyrus.0.log` captured **with Papyrus logging enabled** while reproducing the problem.
3. Your load order and the SLA NG version (MCM General page), plus whether you are on SE, AE, or VR.

A clear "what I did → what happened → what I expected" plus those logs is usually enough to pinpoint the cause.

## See also

- **For mod authors**: the [Author Overview](../authors/overview.md) — full API reference, plugin lifecycle, integration patterns, and the multi-fork compatibility shim.
- **KID INI format details**: [KID Reference](../KID_Reference.md).
- **Nexus pages**:
  - [Keyword Item Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/55728)
  - [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) — required for the export button.
  - [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) — required by the framework.
  - [MergeMapper](https://www.nexusmods.com/skyrimspecialedition/mods/56014) — recommended if you use plugin merges.
