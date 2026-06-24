# Author Overview

SexLab Aroused NG is an SKSE plugin that provides a persistent, per-actor arousal system for Skyrim SE/AE. Other mods plug into this system to read and drive arousal values without needing to coordinate storage or update scheduling themselves.

**Arousal is a single float per actor** (typically 0–100) calculated as the sum of all active effects registered for that actor. Effects can be **static** (always present, plugin-managed) or **dynamic** (event-driven, temporary).

## The arousal model

Each actor has an **arousal value** that is the sum of all their active effects:

```
arousal = sum(static effects not in a group)
        + sum(dynamic effect values)
        + sum(effect group values)
```

Values are floats with no enforced range, though convention is 0–100. Nothing prevents negative or >100 values — clamp in your own plugin if needed.

!!! note "Time is measured in game days"
    **In-game time** is measured in **game days** (the same unit as `Utility.GetCurrentGameTime()`). One game day = 24 in-game hours. Most timed effect parameters use this unit, so a half-life of 4 in-game hours is `4.0 / 24.0`.

### Timed function IDs

Both static and dynamic effects can carry one of these built-in timed functions:

| ID | Name | Behaviour |
|----|------|-----------|
| 0 | None | Effect stays at its current value indefinitely |
| 1 | Decay | Value halves every `param` game days. Stops (and removes effect) when it reaches `limit`. If `param` is negative the effect *grows* until reaching `limit` |
| 2 | Linear | Value changes by `param` per game day. Stops at `limit` |
| 3 | Sine wave | `value = (sin(time * param) + 1.0) * limit` — oscillates continuously, never stops |
| 4 | Delayed step | `value = 0` until `param` game days have elapsed, then `value = limit` |

## Choosing an integration approach

| Need | Use |
|------|-----|
| Temporary / rare effect from any script | [Dynamic effect](dynamic-effects.md) — `SloangNative.AddDecayingEffect(...)` etc., or the `slaSetArousalEffect` ModEvent |
| Always-on per-actor condition, high-frequency updates | [Static effect](static-effects.md) via an `sla_PluginBase` plugin quest |
| Effects that scale each other multiplicatively | Static effects + [`GroupEffects`](papyrus-api.md#effect-groups) |
| Reacting to what actors see | [`RegisterForLOSUpdates`](static-effects.md#los-line-of-sight-updates) in the plugin base |
| Reading or writing arousal from any script, no boilerplate | The [native API](native-api.md) — `SloangNative.GetArousal(who)` etc. |
| Reacting when arousal recalculates | Listen for the [`sla_UpdateComplete`](native-api.md#reacting-to-updates-dont-poll) ModEvent |
| Reading arousal from a non-plugin script | [`slaInternalModules.GetArousal(who)`](papyrus-api.md#reading-arousal) |
| Supporting both OSL Aroused and SLA NG | The [compatibility shim](compatibility.md) |

!!! tip "Dynamic vs static — performance"
    Dynamic effects are stored in a `map<string, EffectData>` per actor. Calling `SetDynamicArousalEffect` / `ModDynamicArousalEffect` very frequently (e.g. every frame) is expensive. For high-frequency, always-on updates prefer a static effect.

## Repo layout

```
SexlabArousedNG/
├─ src/                              C++ SKSE plugin (CommonLibSSE-NG) → SexlabArousedNG.dll. See building.md.
│  ├─ Main.cpp                         entry point, SKSE registration, cosave setup
│  ├─ ArousalManager.cpp               singleton: effect registry, calculation, serialization
│  ├─ ArousalData.cpp                  per-actor data: static/dynamic effects, groups, timed fns
│  ├─ Papyrus.cpp                      native function bindings (slaInternalModules)
│  └─ SerializationHelper.cpp          cosave read/write templates
├─ include/                          C++ headers (incl. CosSin.h sine/cosine table)
├─ dist/Core/                        everything that ships to the player's Data folder:
│  ├─ Source/Scripts/*.psc             Papyrus SOURCES — edit these.
│  ├─ Scripts/*.pex                    compiled bytecode — build output, don't hand-edit.
│  ├─ SKSE/Plugins/                    compiled .dll lands here.
│  └─ Interface/translations/          localized MCM strings (UTF-16 LE BOM).
├─ dist/Patches/                     optional compatibility patches (DummyESPs, SLEN, PAHE).
├─ dist/fomod/                       FOMOD installer (ModuleConfig.xml + info.xml version).
├─ test/                             Catch2 tests (ArousalMath.cpp).
├─ docs/                             this documentation site.
└─ CLAUDE.md                         contributor/build notes.
```

The split that matters: **Papyrus is edited only in `dist/Core/Source/Scripts/`** — everything under `Scripts/` and `SKSE/Plugins/` is build output. See [Building from Source](building.md).

## Key scripts

| Script | Role |
|--------|------|
| `slamainscr` | Main quest, plugin lifecycle, actor tracking |
| `SloangNative` | Canonical global-function API (hidden) — the [native API](native-api.md) |
| `slaInternalModules` | Native bridge to C++ (hidden) — the [Papyrus API](papyrus-api.md) |
| `sla_PluginBase` | Base class for all plugins — see [Static Effects](static-effects.md) |
| `sla_defaultplugin` | Nudity, orgasm, denial, sleep effects |
| `sla_sexlabplugin` | SexLab integration |
| `sla_ddplugin` | Devious Devices integration |
| `sla_ostimplugin` | OStim integration |
| `slaConfigScr` | MCM configuration |
| `slaFrameworkScr` | Framework utilities, gender, factions — the portable read/write surface used by the [compatibility shim](compatibility.md) |
| `slax` | Logging utilities |

`sla_sexlabplugin.psc` and `sla_ddplugin.psc` are complete real-world plugin examples worth reading before you write your own.
