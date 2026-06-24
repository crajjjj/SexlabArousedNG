# Static Effects (Plugin Quests)

Static effects are pre-allocated slots that exist on every tracked actor. They are updated on a timer by the framework, making them more efficient than [dynamic effects](dynamic-effects.md) for always-on conditions.

This requires implementing a **plugin quest script** that extends `sla_PluginBase`.

## Plugin lifecycle

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
    RegisterForPerodicUpdates()  ; required, or Update() / UpdateActor() never fire
    _exposureEffectIdx = RegisterEffect("MyMod_Exposure", "Exposure", "Arousal from nearby nudity")
endFunction

; Called on every game load while ALREADY "Installed". Re-register only your
; periodic/LOS subscriptions here — see "Plugin state machine" below for why.
function ReassertSubscriptions()
    RegisterForPerodicUpdates()  ; must match the subscriptions EnablePlugin() made
endFunction

; Called when the plugin transitions out of "Installed" state.
function DisablePlugin()
    parent.DisablePlugin()  ; tears down periodic/LOS registrations
    UnregisterEffect("MyMod_Exposure")
endFunction

int _exposureEffectIdx = -1
```

## Plugin state machine

The base class manages a two-state machine: `""` (not installed) and `"Installed"`. On every game load, `CheckDependencies()` is called:

- If it returns `true` and the state is not `"Installed"` → calls `EnablePlugin()` then enters `"Installed"`
- If it returns `true` and the state is **already** `"Installed"` (the usual game-load case) → calls `ReassertSubscriptions()`
- If it returns `false` and the state is `"Installed"` → calls `DisablePlugin()` then leaves `"Installed"`

`OnInstalled()` and `OnUninstalled()` are called automatically to register/unregister your plugin with the framework. Override `EnablePlugin`/`DisablePlugin` for your setup/teardown, not these events.

!!! warning "Re-register periodic/LOS subscriptions in `ReassertSubscriptions()`"
    The framework's periodic-update and LOS subscription lists are stored in the save and are **not** rebuilt from scratch on load. `EnablePlugin()` only runs on the *first* install transition — on a normal load your plugin is already `"Installed"`, so `EnablePlugin()` does **not** run again. If those lists ever desync (most often after a mod version upgrade), a plugin can stay "installed" yet silently stop receiving `UpdateActor()` / `UpdateObserver()` calls — its effects freeze at their last value while event-driven effects keep working.

    `ReassertSubscriptions()` exists to heal that: it runs on every load and must re-make exactly the `RegisterForPerodicUpdates()` / `RegisterForLOSUpdates()` calls your `EnablePlugin()` made. Both are idempotent (the framework skips duplicates), so re-registering when already subscribed is a safe no-op. **Do not** re-register effects (`RegisterEffect`) or re-run other setup here — the C++ effect registry survives the save, and re-running full setup can clobber live state. A purely event-driven plugin (no periodic/LOS subscriptions) can leave this as the inherited no-op.

## Registering and using static effects

```papyrus
; In EnablePlugin():
int effectIdx = RegisterEffect("MyMod_Exposure", "Exposure", "From nearby nudity")
; effectIdx is the slot index. Store it — you need it for all subsequent calls.

; In UpdateActor():
SetArousalEffectValue(who, effectIdx, 35.0)       ; set absolute value
; or
ModArousalEffectValue(who, effectIdx, 5.0, 100.0) ; add 5, cap at 100

; To apply a built-in timed function to a static effect:
SetArousalEffectFunction(who, effectIdx, 1, 4.0 / 24.0, 0.0) ; decay, half-life 4h
; Convenience wrappers:
SetLinearArousalEffect(who, effectIdx, 50.0 * 24.0, 100.0)   ; +50/hour, cap 100
SetArousalDecayEffect(who, effectIdx, 2.0 / 24.0, 0.0)       ; half-life 2h, floor 0

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

## Auxiliary storage

Each static effect slot carries two auxiliary fields for plugin use: one `int` and one `float`. These are **not** part of the arousal sum — they are free storage for your plugin state.

```papyrus
; Store per-actor state alongside the effect:
slaInternalModules.SetStaticAuxillaryInt(who, effectIdx, someState)
slaInternalModules.SetStaticAuxillaryFloat(who, effectIdx, someTimestamp)

int state = slaInternalModules.GetStaticEffectAux(who, effectIdx)
```

## LOS (line-of-sight) updates

If your plugin needs to react when an actor sees another, register for LOS events:

```papyrus
function EnablePlugin()
    ...
    RegisterForLOSUpdates()
endFunction

function ReassertSubscriptions()
    ...
    RegisterForLOSUpdates()  ; re-assert on load alongside RegisterForPerodicUpdates()
endFunction

; Called when observer gains LOS on observed:
function UpdateObserver(Actor observer, Actor observed)
    ModArousalEffectValue(observer, _exposureEffectIdx, 2.0, 50.0)
endFunction
```

The base `DisablePlugin()` calls `UnregisterForLOSUpdates()` (and stops periodic updates) for you — but Papyrus does **not** chain to the parent automatically, so your override must call `parent.DisablePlugin()` (as shown in the lifecycle example above) for that teardown to run.

## MCM options

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

!!! tip "Read the shipped plugins"
    `sla_sexlabplugin.psc` and `sla_ddplugin.psc` are complete, real plugins built on this base class. See `sla_PluginBase.psc` for the full wrapper API and the [Papyrus API Reference](papyrus-api.md) for the underlying native functions, including [effect groups](papyrus-api.md#effect-groups).
