# Requirements

SexLab Aroused NG is an SKSE plugin with a Papyrus API. A small set of mods are **always required**; everything else is optional and only unlocks the integration tied to it.

## Hard requirements

These must be installed or the mod will not load / initialise.

| Mod | Why |
|---|---|
| **SKSE64** (Skyrim Script Extender) | This is an SKSE plugin — nothing works without it |
| [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444) | Standard SKSE plugin runtime dependency |
| [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) | All persistent state and config files use it |

!!! note "Skyrim SE / AE / VR"
    Works on all three runtimes. Use the Address Library build that matches your `SkyrimSE.exe` version.

## Soft dependencies (unlock extra features)

Each of these is optional. Install the ones that match your modlist — the rest of the mod works without them.

| Mod | Unlocks |
|---|---|
| [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) | The *Export to KID file* MCM button. Without it the rest of the mod still works, but that button pops up an error |
| [Keyword Item Distributor (KID)](https://www.nexusmods.com/skyrimspecialedition/mods/55728) | Reads the file you export from MCM and applies your armor curation at game start. Without KID the export is just a text file |
| **SexLab** | SexLab plugin: per-stage arousal during animations, animation-tag scoring |
| [OStim Standalone](https://www.nexusmods.com/skyrimspecialedition/mods/98163) | OStim plugin: NG (and legacy v<29) thread tracking, observer LOS arousal scaling |
| **Devious Devices / NG** | DD plugin: device-equipped arousal, belt/plug denial modifiers, device-stacking multiplier |
| **Milk Mod Economy** | Soft integration |
| **SLEN** (SexLab Eager NPCs) | Soft integration — see the SLEN patch in the FOMOD |
| **MergeMapper** | Auto-remaps FormIDs after plugin merges. Useful if you've merged armor mods |
| **FNIS, Nemesis, or Open Animation Replacer** | Drives the optional aroused animations. Pick one during the FOMOD install (OAR recommended) |

## Notes

- This mod **replaces all previous SL Aroused versions** — uninstall older versions before installing.
- It **requires a new save** unless you are already using *SexLab Aroused NG 0.2.2*. Earlier versions stored arousal data differently and are incompatible; the MCM won't initialise on top of them.
- If an older `SexLabAroused.esm` is already in your load order, it can block initialisation — remove/disable it first. See [Troubleshooting & Logs](troubleshooting.md).

Once requirements are in place, head to [Getting Started](getting-started.md) for installation and first-time setup.
