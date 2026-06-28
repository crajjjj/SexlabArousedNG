# SexLab Aroused NG

A persistent, per-actor **arousal system** for Skyrim SE/AE, packaged as an SKSE C++ plugin with a Papyrus script API. Every tracked actor has a single arousal float (typically 0–100) that other mods read and react to. The framework handles storage, decay, scanning, line-of-sight evaluation, and MCM curation — your scripts and other adult-mod integrations stay focused on the *behavior* triggered by arousal, not the bookkeeping.

These docs are split into two tracks. Pick the one that fits you:

## For Players

Install it, play it, configure it. Start here if you just want to use the mod.

- [Getting Started](players/getting-started.md) — requirements, installation, the FOMOD options, and first-time setup
- [How Arousal Works](players/how-arousal-works.md) — the single-float model, time units, and the five built-in effect categories
- [MCM Reference](players/mcm-reference.md) — every MCM page, control by control
- [Armor Curation](players/armor-curation.md) — the *Current Armor List* page, custom keywords, and the built-in keyword cheat sheet
- [Export to KID File](players/kid-export.md) — make your curation survive new saves and share it with friends
- [Tuning Recipes](players/tuning-recipes.md) — "make it climb faster", coming from OSL Aroused, and other common workflows
- [Troubleshooting & Logs](players/troubleshooting.md) — log locations, enabling Papyrus logging, and what to attach when reporting

## For Mod Authors

Integrate with the arousal framework without touching its core scripts.

- [Overview](authors/overview.md) — the arousal model, repo layout, the key scripts, and how to choose an integration approach
- [Dynamic Effects](authors/dynamic-effects.md) — the easy path: fire a ModEvent from any script, with ready-to-use recipes
- [Static Effects (Plugin Quests)](authors/static-effects.md) — `sla_PluginBase`, the plugin lifecycle, LOS updates, and MCM options
- [Papyrus API Reference](authors/papyrus-api.md) — every `slaInternalModules` native function, plus effect groups
- [Compatibility (OSL Aroused & SLA NG)](authors/compatibility.md) — a universal interface that works on every fork
- [Building from Source](authors/building.md) — CMake/vcpkg, the build presets, and the repo layout

## At a glance

- **Single float per actor**, calculated as the sum of all active effects.
- **Six built-in effect categories** (Naked, Exhibitionist, Timed, Sleep, Satisfaction, Legacy) shipped by the Default plugin, each with its own MCM page.
- **Plugins** for SexLab, Devious Devices, and OStim register additional effects when those mods are present.
- **Per-armor keyword curation** in MCM with on-disk persistence and KID export.
- **Cosave-backed state** that survives across saves, with a configurable scan/update loop and full LOS evaluation.

---

- **Source / issues**: [github.com/crajjjj/SexlabArousedNG](https://github.com/crajjjj/SexlabArousedNG)
- **License**: Apache-2.0
- **Changelog**: [GitHub releases page](https://github.com/crajjjj/SexlabArousedNG/releases)
