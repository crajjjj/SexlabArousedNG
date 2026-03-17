
# SexLab Aroused NG

An SKSE plugin that provides a persistent, per-actor arousal system for Skyrim SE/AE. Other mods plug into this system to read and drive arousal values without needing to coordinate storage or update scheduling themselves.

**Arousal is a single float per actor** (typically 0–100) calculated as the sum of all active effects registered for that actor. Effects can be static (always present, plugin-managed) or dynamic (event-driven, temporary).

---

## Table of Contents

- [Build Instructions](#build-instructions)
- [Arousal Model Overview](#arousal-model-overview)
- [For Mod Authors — Dynamic Effects (Easy)](#for-mod-authors--dynamic-effects-easy)
- [For Mod Authors — Static Effects (Plugin Quest)](#for-mod-authors--static-effects-plugin-quest)
- [Full Papyrus API Reference](#full-papyrus-api-reference)
- [Effect Groups](#effect-groups)
---

## Build Instructions

This project uses **CMake** and **vcpkg** for dependency management. **MSVC or Clang-CL on Windows is required** — GCC and MinGW are not supported because SKSE plugins must be Windows DLLs built against the Windows SDK.

### Prerequisites

* [CMake 3.21+](https://cmake.org/download/)
* [vcpkg](https://github.com/microsoft/vcpkg)
* MSVC (Visual Studio 2022) or Clang-CL

### Build Steps

1. **Clone the repository:**

   ```sh
   git clone <your-repo-url>
   cd <your-repo-folder>
   ```

2. **Bootstrap vcpkg (Windows):**

   ```bat
   git clone https://github.com/microsoft/vcpkg.git
   .\vcpkg\bootstrap-vcpkg.bat
   .\vcpkg\vcpkg install --triplet x64-windows-skse
   ```

3. **Set `VCPKG_ROOT`:**

   PowerShell:
   ```powershell
   $env:VCPKG_ROOT = "C:\path\to\vcpkg"
   ```
   Command Prompt:
   ```cmd
   set VCPKG_ROOT=C:\path\to\vcpkg
   ```

4. **Configure and build:**

   Available presets:

   | Preset (configure) | Preset (build) | Compiler |
   |-|-|-|
   | `build-release-msvc` | `release-msvc` | MSVC |
   | `build-debug-msvc` | `debug-msvc` | MSVC |
   | `build-release-clang` | `release-clang` | Clang-CL |
   | `build-debug-clang` | `debug-clang` | Clang-CL |

   ```sh
   cmake --preset build-release-msvc
   cmake --build --preset release-msvc
   ```

   The output DLL is placed in `build/<preset>/`.

---

## Arousal Model Overview

Each actor has an **arousal value** that is the sum of all their active effects:

```
arousal = sum(static effects not in a group)
        + sum(dynamic effect values)
        + sum(effect group values)
```

Values are floats with no enforced range, though convention is 0–100. Nothing prevents negative or >100 values — clamp in your own plugin if needed.

**In-game time** is measured in **game days** (the same unit as `Utility.GetCurrentGameTime()`). One game day = 24 in-game hours. Most timed effect parameters use this unit.

---

## For Mod Authors — Dynamic Effects (Easy)

Dynamic effects are the simplest integration path. They are created by firing a ModEvent from any Papyrus script — no quest script or plugin registration required.

They are ideal for:
- Temporary conditions (a teasing encounter, a debuff)
- Effects that come and go infrequently
- Mods that don't want to maintain a persistent plugin quest

**Performance note:** Dynamic effects are stored in a `map<string, EffectData>` per actor. Calling `SetDynamicArousalEffect` or `ModDynamicArousalEffect` very frequently (e.g. every frame) is expensive. For high-frequency updates prefer a static effect.

### Creating or Replacing a Dynamic Effect

```papyrus
; slaSetArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit)
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)              ; Actor to affect
ModEvent.PushString(handle, "MyMod_Tease") ; Unique effect ID — namespace it to avoid collisions
ModEvent.PushFloat(handle, 50.0)           ; Initial value added to arousal immediately
ModEvent.PushInt(handle, 1)                ; Function ID (see table below)
ModEvent.PushFloat(handle, 2.0 / 24.0)    ; param: half-life of 2 hours
ModEvent.PushFloat(handle, 0.0)           ; limit: decay stops at 0
ModEvent.Send(handle)
```

Setting a new effect with the same `effectId` on the same actor **replaces** the previous one. The `initialValue` is applied as a delta relative to the effect's current value — if the effect already exists and has value 30, and you pass `initialValue = 50`, arousal increases by 20.

To **clear** an effect, set `functionId = 0` and `initialValue = 0`:
```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 0)
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushFloat(handle, 0.0)
ModEvent.Send(handle)
```

### Modifying an Existing Dynamic Effect

Adds `modifier` to an effect's current value, clamping at `limit`:

```papyrus
; slaModArousalEffect(Actor who, string effectId, float modifier, float limit)
int handle = ModEvent.Create("slaModArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")
ModEvent.PushFloat(handle, -20.0)   ; reduce by 20
ModEvent.PushFloat(handle, 0.0)     ; clamp: don't go below 0
ModEvent.Send(handle)
```

The `limit` direction is inferred from `modifier`: if modifier < 0, limit is treated as a lower bound; if modifier > 0, it is an upper bound.

### Timed Function IDs

| ID | Name | Behaviour |
|----|------|-----------|
| 0 | None | Effect stays at its current value indefinitely |
| 1 | Decay | Value halves every `param` game days. Stops (and removes effect) when it reaches `limit` |
| 2 | Linear | Value changes by `param` per game day. Stops at `limit` |
| 3 | Sine wave | `value = (sin(time * param) + 1.0) * limit` — oscillates continuously, never stops |
| 4 | Delayed step | `value = 0` until `param` game days have elapsed, then `value = limit` |

For function 1 (decay), if `param` is negative the effect *grows* until reaching `limit`.

### Example Recipes

#### Post-sex arousal that fades over 4 hours

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_PostSex")
ModEvent.PushFloat(handle, 100.0)       ; start at 100
ModEvent.PushInt(handle, 1)             ; decay
ModEvent.PushFloat(handle, 4.0 / 24.0) ; half-life = 4 in-game hours
ModEvent.PushFloat(handle, 0.0)         ; remove when it reaches ~0
ModEvent.Send(handle)
```

#### Teasing effect capped at 50

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 2)                  ; linear
ModEvent.PushFloat(handle, 200.0 * 24.0)     ; +200 per hour
ModEvent.PushFloat(handle, 50.0)             ; cap at 50
ModEvent.Send(handle)
```

#### Penalty that recovers over a day

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Penalty")
ModEvent.PushFloat(handle, -50.0)            ; start at -50
ModEvent.PushInt(handle, 2)                  ; linear
ModEvent.PushFloat(handle, 50.0 * 24.0)      ; +50 per hour
ModEvent.PushFloat(handle, 0.0)              ; stop at 0
ModEvent.Send(handle)
```

#### Ambient oscillating arousal

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Ambient")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 3)             ; sine
ModEvent.PushFloat(handle, 1.0)         ; frequency: one cycle per game day
ModEvent.PushFloat(handle, 10.0)        ; amplitude: oscillates 0–10
ModEvent.Send(handle)
```

---

## For Mod Authors — Static Effects (Plugin Quest)

Static effects are pre-allocated slots that exist on every tracked actor. They are updated on a timer by the framework, making them more efficient than dynamic effects for always-on conditions.

This requires implementing a **plugin quest script** that extends `sla_PluginBase`.

### Plugin Lifecycle

Your quest script extends `sla_PluginBase` and overrides the lifecycle functions:

```papyrus
Scriptname MyMod_SLAPlugin extends sla_PluginBase

; Called on every periodic update. actors = all tracked actors, nakedActors = subset that are naked.
function Update(Actor[] actors, Actor[] nakedActors)
    int i = actors.Length - 1
    while i >= 0
        UpdateActor(actors[i], true)
        i -= 1
    endWhile
endFunction

; Called per-actor. fullUpdate = true means a complete recalculation is expected.
function UpdateActor(Actor who, bool fullUpdate)
    float exposure = ComputeExposure(who)
    SetArousalEffectValue(who, _exposureEffectIdx, exposure)
endFunction

; Called when an actor is removed from tracking (e.g. leaves the area).
function ClearActor(Actor who)
    SetArousalEffectValue(who, _exposureEffectIdx, 0.0)
endFunction

; Return true when all dependencies are present.
bool function CheckDependencies()
    return (Game.GetFormFromFile(0x800, "MyMod.esp") as Quest) != none
endFunction

; Called when the plugin transitions to "Installed" state.
function EnablePlugin()
    _exposureEffectIdx = RegisterEffect("MyMod_Exposure", "Exposure", "Arousal from nearby nudity")
endFunction

; Called when the plugin transitions out of "Installed" state.
function DisablePlugin()
    UnregisterEffect("MyMod_Exposure")
endFunction

int _exposureEffectIdx = -1
```

### Plugin State Machine

The base class manages a two-state machine: `""` (not installed) and `"Installed"`. On every game load, `CheckDependencies()` is called:

- If it returns `true` and the state is not `"Installed"` → calls `EnablePlugin()` then enters `"Installed"`
- If it returns `false` and the state is `"Installed"` → calls `DisablePlugin()` then leaves `"Installed"`

`OnInstalled()` and `OnUninstalled()` are called automatically to register/unregister your plugin with the framework. Override `EnablePlugin`/`DisablePlugin` for your setup/teardown, not these events.

### Registering and Using Static Effects

```papyrus
; In EnablePlugin():
int effectIdx = RegisterEffect("MyMod_Exposure", "Exposure", "From nearby nudity")
; effectIdx is the slot index. Store it — you need it for all subsequent calls.

; In UpdateActor():
SetArousalEffectValue(who, effectIdx, 35.0)     ; set absolute value
; or
ModArousalEffectValue(who, effectIdx, 5.0, 100.0) ; add 5, cap at 100

; To apply a built-in timed function to a static effect:
SetArousalEffectFunction(who, effectIdx, 1, 4.0 / 24.0, 0.0) ; decay, half-life 4h
; Convenience wrappers:
SetLinearArousalEffect(who, effectIdx, 50.0 * 24.0, 100.0)    ; +50/hour, cap 100
SetArousalDecayEffect(who, effectIdx, 2.0 / 24.0, 0.0)         ; half-life 2h, floor 0

; To read back values:
float val   = GetArousalEffectValue(who, effectIdx)
float param = GetArousalEffectFncParam(who, effectIdx)
float limit = GetArousalEffectFncLimit(who, effectIdx)
int   aux   = GetArousalEffectFncAux(who, effectIdx)

; To disable (zero out) an effect:
DisableArousalEffect(who, effectIdx)

; Force immediate recalculation (normally updates are batched):
ForceUpdateArousal(who)
```

### Auxiliary Storage

Each static effect slot carries two auxiliary fields for plugin use: one `int` and one `float`. These are not part of the arousal sum — they are free storage for your plugin state.

```papyrus
; Store per-actor state alongside the effect:
slaInternalModules.SetStaticAuxillaryInt(who, effectIdx, someState)
slaInternalModules.SetStaticAuxillaryFloat(who, effectIdx, someTimestamp)

int state = slaInternalModules.GetStaticEffectAux(who, effectIdx)
```

### LOS (Line-of-Sight) Updates

If your plugin needs to react when an actor sees another, register for LOS events:

```papyrus
function EnablePlugin()
    ...
    RegisterForLOSUpdates()
endFunction

; Called when observer gains LOS on observed:
function UpdateObserver(Actor observer, Actor observed)
    ModArousalEffectValue(observer, _exposureEffectIdx, 2.0, 50.0)
endFunction
```

Unregister in `DisablePlugin()` — the base class calls `UnregisterForLOSUpdates()` automatically, but only after your override runs.

### MCM Options

Plugins can expose options to the SLA MCM:

```papyrus
function AddOptions()
    AddToggleOption("General", "Enable Exposure", "Count nearby nudity", true)
    AddOptionEx("General", "Rate", "Arousal per nude actor", 5.0, 0.0, 20.0, 1.0, "{0}")
endFunction

float function GetOptionValue(int optionId)
    if optionId == 0
        return _enabled as Float
    elseIf optionId == 1
        return _rate
    endIf
    return 0.0
endFunction

function OnUpdateOption(int optionId, float value)
    if optionId == 0
        _enabled = (value as int) as bool
    elseIf optionId == 1
        _rate = value
    endIf
endFunction
```

---

## Full Papyrus API Reference

All functions live on the `slaInternalModules` (hidden) script and are called as globals.
The preferred way to call them from a plugin script is through the `sla_PluginBase` wrappers — call `slaInternalModules` directly only for things not covered by the base class.

### Reading Arousal

```papyrus
; Get total arousal for an actor (sum of all effects). Triggers a full recalculation.
float function GetArousal(Actor who) global native

; Trigger the framework's own update pass for one actor (e.g. after adding effects mid-scene).
; GameDaysPassed should be Utility.GetCurrentGameTime().
function UpdateSingleActorArousal(Actor who, float GameDaysPassed) global native
```

### Dynamic Effect Functions

```papyrus
; Create or replace a dynamic effect. initialValue is a delta applied immediately.
; Setting functionId=0 and initialValue=0 removes the effect.
function SetDynamicArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit) global native

; Add modifier to an existing dynamic effect, clamped by limit.
function ModDynamicArousalEffect(Actor who, string effectId, float modifier, float limit) global native

; Enumerate dynamic effects on an actor (for debugging / UI display):
int    function GetDynamicEffectCount(Actor who) global native
string function GetDynamicEffect(Actor who, int index) global native          ; returns effectId at index
float  function GetDynamicEffectValue(Actor who, int index) global native     ; returns value at index
float  function GetDynamicEffectValueByName(Actor who, string effectId) global native
```

### Static Effect Management

```papyrus
; Registration — call from your plugin's EnablePlugin() via sla_PluginBase.RegisterEffect().
; Returns the effect slot index (>= 0). Returns -1 if not found, -2 if called during cleanup.
int  function RegisterStaticEffect(string id) global native
int  function GetStaticEffectId(string id) global native
bool function UnregisterStaticEffect(string id) global native

; Total number of registered static effect slots:
int function GetStaticEffectCount() global native
```

### Static Effect Values

```papyrus
; Read the current value of a static effect slot.
float function GetStaticEffectValue(Actor who, int effectIdx) global native

; Set absolute value:
function SetStaticArousalValue(Actor who, int effectIdx, float value) global native

; Add diff clamped by limit. Returns the actual change applied.
float function ModStaticArousalValue(Actor who, int effectIdx, float diff, float limit) global native
```

### Static Effect Timed Functions

```papyrus
; Set a timed function on a static effect (same function IDs as dynamic effects).
function SetStaticArousalEffect(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary) global native

; Read function parameters back:
float function GetStaticEffectParam(Actor who, int effectIdx) global native
int   function GetStaticEffectAux(Actor who, int effectIdx) global native

; Check if a timed function is currently running on this slot:
bool function IsStaticEffectActive(Actor who, int effectIdx) global native
```

### Auxiliary Storage (Static Effects)

```papyrus
function SetStaticAuxillaryFloat(Actor who, int effectIdx, float value) global native
function SetStaticAuxillaryInt(Actor who, int effectIdx, int value) global native
; Read back with GetStaticEffectAux (int) — see Known Issues for float read.
```

### Maintenance

```papyrus
; Asynchronously remove actor data that hasn't been updated since lastUpdateBefore game days.
; Use Utility.GetCurrentGameTime() - 30 to purge actors not seen in 30 days.
; Returns 0 immediately; deletion happens on the next game tick.
int function CleanUpActors(float lastUpdateBefore) global native
```

---

## Effect Groups

Effect groups **multiply** their member effects together instead of summing them. This is useful when effects should scale each other (e.g. a base exposure value multiplied by a clothing factor).

```papyrus
; Merge effectIdx1 and effectIdx2 into the same group.
; At least one of the two must not already belong to a group.
; You cannot merge two existing groups with this call.
; Returns true on success, false if both are already in different groups.
bool function GroupEffects(Actor who, int effIdx1, int effIdx2) global native

; Remove the group containing effectIdx. All members return to summing normally.
bool function RemoveEffectGroup(Actor who, int effIdx) global native
```

**Example:** a nudity arousal plugin and a clothing-factor plugin want their effects to multiply:

```papyrus
; Plugin A registers "MyMod_Nudity", Plugin B registers "MyMod_ClothingFactor"
; After both are registered, one of them groups the two:
int nudityIdx  = slaInternalModules.GetStaticEffectId("MyMod_Nudity")
int clothIdx   = slaInternalModules.GetStaticEffectId("MyMod_ClothingFactor")
slaInternalModules.GroupEffects(who, nudityIdx, clothIdx)
; Now arousal contribution = nudity_value * clothingFactor_value
```

---


## Summary — Choosing an Integration Approach

| Need | Use |
|------|-----|
| Temporary / rare effect from any script | Dynamic effect via `slaSetArousalEffect` ModEvent |
| Always-on per-actor condition, high frequency updates | Static effect via `sla_PluginBase` plugin quest |
| Effects that scale each other multiplicatively | Static effects + `GroupEffects` |
| Reacting to what actors see | `RegisterForLOSUpdates` in plugin base |
| Reading arousal from a non-plugin script | `slaInternalModules.GetArousal(who)` |

See `sla_PluginBase.psc` for the full base class API and `sla_sexlabplugin.psc` / `sla_ddplugin.psc` for complete real-world plugin examples.
