# Papyrus API Reference

All functions live on the `slaInternalModules` (hidden) script and are called as globals. The preferred way to call them from a plugin script is through the `sla_PluginBase` wrappers (see [Static Effects](static-effects.md)) — call `slaInternalModules` directly only for things not covered by the base class.

## Reading arousal

```papyrus
; Get total arousal for an actor (sum of all effects). Triggers a full recalculation.
float function GetArousal(Actor who) global native

; Trigger the framework's own update pass for one actor (e.g. after adding effects mid-scene).
; GameDaysPassed should be Utility.GetCurrentGameTime().
function UpdateSingleActorArousal(Actor who, float GameDaysPassed) global native
```

!!! tip "Prefer the portable read"
    For reading arousal from a non-plugin script that may run alongside other forks, prefer `slaFrameworkScr.GetActorArousal(who)` — it is implemented by every fork. See [Compatibility](compatibility.md).

## Dynamic effect functions

```papyrus
; Create or replace a dynamic effect. initialValue is a delta applied immediately.
; Setting functionId=0 and initialValue=0 removes the effect.
function SetDynamicArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit) global native

; Add modifier to an existing dynamic effect, clamped by limit.
function ModDynamicArousalEffect(Actor who, string effectId, float modifier, float limit) global native

; Enumerate dynamic effects on an actor (for debugging / UI display):
int    function GetDynamicEffectCount(Actor who) global native
string function GetDynamicEffect(Actor who, int index) global native       ; returns effectId at index
float  function GetDynamicEffectValue(Actor who, int index) global native  ; returns value at index
float  function GetDynamicEffectValueByName(Actor who, string effectId) global native
```

See [Dynamic Effects](dynamic-effects.md) for the ModEvent-based wrappers most mods should use.

## Static effect management

```papyrus
; Registration — call from your plugin's EnablePlugin() via sla_PluginBase.RegisterEffect().
; Returns the effect slot index (>= 0). Returns -1 if not found, -2 if called during cleanup.
int  function RegisterStaticEffect(string id) global native
int  function GetStaticEffectId(string id) global native
bool function UnregisterStaticEffect(string id) global native

; Total number of registered static effect slots:
int function GetStaticEffectCount() global native
```

## Static effect values

```papyrus
; Read the current value of a static effect slot.
float function GetStaticEffectValue(Actor who, int effectIdx) global native

; Set absolute value:
function SetStaticArousalValue(Actor who, int effectIdx, float value) global native

; Add diff clamped by limit. Returns the actual change applied.
float function ModStaticArousalValue(Actor who, int effectIdx, float diff, float limit) global native
```

## Static effect timed functions

```papyrus
; Set a timed function on a static effect (same function IDs as dynamic effects).
function SetStaticArousalEffect(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary) global native

; Read function parameters back:
float function GetStaticEffectParam(Actor who, int effectIdx) global native
int   function GetStaticEffectAux(Actor who, int effectIdx) global native

; Check if a timed function is currently running on this slot:
bool function IsStaticEffectActive(Actor who, int effectIdx) global native
```

## Auxiliary storage (static effects)

```papyrus
function SetStaticAuxillaryFloat(Actor who, int effectIdx, float value) global native
function SetStaticAuxillaryInt(Actor who, int effectIdx, int value) global native
; Read the int back with GetStaticEffectAux.
```

## Maintenance

```papyrus
; Asynchronously remove actor data that hasn't been updated since lastUpdateBefore game days.
; Use Utility.GetCurrentGameTime() - 30 to purge actors not seen in 30 days.
; Returns 0 immediately; deletion happens on the next game tick.
int function CleanUpActors(float lastUpdateBefore) global native
```

## Effect groups

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

**Example** — a nudity arousal plugin and a clothing-factor plugin want their effects to multiply:

```papyrus
; Plugin A registers "MyMod_Nudity", Plugin B registers "MyMod_ClothingFactor"
; After both are registered, one of them groups the two:
int nudityIdx = slaInternalModules.GetStaticEffectId("MyMod_Nudity")
int clothIdx  = slaInternalModules.GetStaticEffectId("MyMod_ClothingFactor")
slaInternalModules.GroupEffects(who, nudityIdx, clothIdx)
; Now arousal contribution = nudity_value * clothingFactor_value
```
