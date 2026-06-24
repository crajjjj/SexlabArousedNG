# Compatibility (OSL Aroused & SLA NG)

Several mods ship their own `SexLabAroused.esm` that stubs `slaFrameworkScr` for backwards compatibility. The most common is **OSL Aroused** (`GetVersion() = 20140124`), which does **not** register the `slaSetArousalEffect` / `slaModArousalEffect` ModEvents and predates the [`SloangNative`](native-api.md) facade. This page shows a single interface that **prefers the modern native API when it's available** and falls back gracefully on older forks.

!!! tip "Only targeting SLA NG 3.2.0+? Skip this page."
    If you can require SLA NG 3.2.0 or newer, just call the [native API (`SloangNative`)](native-api.md) directly — no detection, no fallbacks. This page is only for mods that must also run against **older forks** (OSL Aroused, SLAXSE2022, pre-3.2.0 SLA NG). The [`sla_UpdateComplete`](native-api.md#reacting-to-updates-dont-poll) event is SLA NG only; on older forks you must poll.

## Detection

Every fork ships a quest with editor ID `sla_Framework` exposing `GetVersion()`. Read it once and branch on it — it tells you both *which* fork is present and whether the native API is available.

```papyrus
Quest Function GetFramework() Global
    return Quest.GetQuest("sla_Framework")
EndFunction

bool Function IsPresent() Global
    return Game.GetModByName("SexLabAroused.esm") != 255
EndFunction

; 0 if no fork installed. See the version table below.
int Function GetArousalVersion() Global
    Quest sla = GetFramework()
    if !sla
        return 0
    endif
    return (sla as slaframeworkscr).GetVersion()
EndFunction

; The SloangNative facade ships with SLA NG 3.2.0 and later.
bool Function HasNativeApi() Global
    return GetArousalVersion() >= 30200000
EndFunction
```

!!! warning "Don't check for OSLAroused.esp"
    OSL ships its own `SexLabAroused.esm`, so `GetModByName("SexLabAroused.esm")` is present on both installs. Distinguish forks by `GetVersion()`, not by ESP filename.

## Known version numbers

| Fork | `GetVersion()` | ModEvents | `SloangNative` |
|------|----------------|-----------|----------------|
| OSL Aroused (all versions) | `20140124` | No | No |
| SLAXSE2022 | `20190720` | No | No |
| SexLab Aroused NG &lt; 3.2.0 | `30100000`–`30199999` | Yes | No |
| SexLab Aroused NG ≥ 3.2.0 | `>= 30200000` | Yes | Yes |

## Reading arousal

`slaFrameworkScr.GetActorArousal()` returns a 0–100 value and is implemented by **every** fork, so it's the safe portable read. On SLA NG 3.2.0+ use the native call instead:

```papyrus
Float Function GetArousal(Actor who) Global
    if !who
        return 0.0
    endif
    if HasNativeApi()
        return SloangNative.GetArousal(who)
    endif
    Quest sla = GetFramework()
    if !sla
        return 0.0
    endif
    return (sla as slaframeworkscr).GetActorArousal(who) as float
EndFunction
```

## Writing arousal

Contribute your mod's arousal as a **named dynamic effect** under your own namespaced `effectId` — it's readable (`GetDynamicEffectValue`), removable (`ClearDynamicEffect`), and won't collide with other mods. Don't write the shared exposure channel for your own contribution. Older forks have no named effects, so fall back to `slaFrameworkScr.UpdateActorExposure()` (the lowest common denominator, implemented by every fork):

```papyrus
; Nudge this mod's own arousal contribution by `value` (may be negative).
Function ModifyArousal(Actor who, Float value) Global
    if !who
        return
    endif
    if HasNativeApi()
        ; accumulate onto our namespaced effect; clamp up toward 100, down toward 0
        float limit = 100.0
        if value < 0.0
            limit = 0.0
        endif
        SloangNative.ModDynamicEffect(who, "MyMod_Arousal", value, limit)
    else
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, value as int)
        endif
    endif
EndFunction
```

## Timed effects (ramps & decay)

The native API gives you managed ramps/decay through the [convenience wrappers](native-api.md#convenience-wrappers-recommended) — no `functionId`/`param`/`limit` bookkeeping. Older forks can't manage timed effects, so apply a one-shot bump that preserves the direction and rough magnitude:

```papyrus
; A linear arousal climb of `perHour` per in-game hour, capped at `cap`.
Function StartArousalRamp(Actor who, Float perHour, Float cap) Global
    if !who
        return
    endif
    if HasNativeApi()
        SloangNative.AddLinearEffect(who, "MyMod_Ramp", 1.0, perHour, cap)
    else
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, perHour as int) ; untracked one-shot
        endif
    endif
EndFunction

; Stop/clear the ramp (no-op on older forks — fallback writes aren't tracked).
Function StopArousalRamp(Actor who) Global
    if who && HasNativeApi()
        SloangNative.ClearDynamicEffect(who, "MyMod_Ramp")
    endif
EndFunction
```

!!! note "Need timed effects on pre-3.2.0 SLA NG?"
    SLA NG below 3.2.0 has no `SloangNative` but does support the `slaSetArousalEffect` / `slaModArousalEffect` ModEvents. If you must manage timed effects there, fire those events (see [Dynamic Effects](dynamic-effects.md)) in place of the `UpdateActorExposure` fallback above.

## Putting it together as a Hidden interface script

Encapsulate everything in a `Hidden` global script so callers never branch on the fork:

```papyrus
Scriptname MyMod_Arousal Hidden

bool Function IsPresent() Global
    return Game.GetModByName("SexLabAroused.esm") != 255
EndFunction

Quest Function GetFramework() Global
    return Quest.GetQuest("sla_Framework")
EndFunction

bool Function HasNativeApi() Global
    Quest sla = GetFramework()
    if !sla
        return false
    endif
    return (sla as slaframeworkscr).GetVersion() >= 30200000
EndFunction

Float Function GetArousal(Actor who) Global
    if !who
        return 0.0
    endif
    if HasNativeApi()
        return SloangNative.GetArousal(who)
    endif
    Quest sla = GetFramework()
    if !sla
        return 0.0
    endif
    return (sla as slaframeworkscr).GetActorArousal(who) as float
EndFunction

Function ModifyArousal(Actor who, Float value) Global
    if !who
        return
    endif
    if HasNativeApi()
        float limit = 100.0
        if value < 0.0
            limit = 0.0
        endif
        SloangNative.ModDynamicEffect(who, "MyMod_Arousal", value, limit)
    else
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, value as int)
        endif
    endif
EndFunction
```

!!! note "Compile-time imports"
    This script references `slaframeworkscr` and `SloangNative`, so both `.pex` (plus their sources to compile against) must be on your import path — they ship with SLA NG. Neither becomes a runtime **master**: the `SloangNative` calls are gated behind `HasNativeApi()`, so on OSL-only installs they never run.

Callers then simply do:

```papyrus
if MyMod_Arousal.IsPresent()
    float arousal = MyMod_Arousal.GetArousal(akTarget)
    MyMod_Arousal.ModifyArousal(akTarget, 10.0)
endif
```
