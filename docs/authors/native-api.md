# Native API (`SloangNative`)

`SloangNative` is the canonical, no-boilerplate way to read and write arousal from any Papyrus script. It is a `hidden` script of **global functions**, so you call it directly — no quest casts, no `ModEvent.Create`/`Push`/`Send` sequences:

```papyrus
SloangNative.ModArousal(akActor, 10.0)
float a = SloangNative.GetArousal(akActor)
```

!!! note "What depending on this actually costs"
    Global calls like `SloangNative.Foo()` are **not** an ESM master dependency and will **not** stop your plugin from loading if SLA is missing — they resolve by script name at runtime, and an absent script just logs an error and returns a default (`0` / `None` / no-op). The only real coupling is at **compile time**: `SloangNative.pex` must be on your import path. `SexLabAroused.esm` is a very common requirement, so that's fine for most mods. If you want **zero compile-time coupling** too, use the [`slaSetArousalEffect` / `slaModArousalEffect` ModEvents](dynamic-effects.md) instead — same underlying system, purely an ergonomics trade-off.

!!! warning "There is no presence guard"
    Don't try to wrap calls in an "is SLA installed?" check — any such check would itself be a global call on this script, logging the same missing-script error when SLA is absent. If you require `SexLabAroused.esm`, just call the API directly. `GetVersion()` is for **runtime version gating only** (it returns `0` when the esm is present but disabled).

!!! danger "`SloangNative` ≠ `OSLArousedNative`"
    `SloangNative` is the canonical SLA NG API. `OSLArousedNative` is a separate **compatibility stub** that redirects calls written against the older *OSL Aroused* mod. They are different scripts — call `SloangNative` for new integrations.

## Reading arousal

| Function | Returns |
|----------|---------|
| `float GetArousal(Actor who)` | Current arousal (unclamped float) |
| `int GetArousalInt(Actor who)` | Current arousal clamped to 0–100 |
| `float GetExposure(Actor who)` | Legacy exposure component |

## Writing arousal

| Function | Effect |
|----------|--------|
| `float ModArousal(Actor who, float modifier)` | Adds `modifier` to the actor's exposure; returns the new value |
| `float SetArousal(Actor who, float value)` | Sets arousal toward `value` (`0.0` resets toward the floor) |

## Dynamic effects (no ModEvent boilerplate)

Named, time-aware contributions to arousal — the direct-call equivalents of the [dynamic-effect ModEvents](dynamic-effects.md). **Prefer the convenience wrappers below for almost everything**; only drop to the [low-level primitives](#low-level-primitives) when no wrapper fits.

### Convenience wrappers (recommended)

One line per common shape — you never touch raw `functionId`/`param`/`limit`. **All time arguments are in in-game hours.** Each `Add…` call creates or refreshes the named effect (it does not stack — use `ModDynamicEffect` to accumulate). Amounts may be negative (a negative effect lowers arousal).

```papyrus
SloangNative.AddDecayingEffect(akActor, "MyMod_Tease",  50.0, 2.0)   ; +50, halves every 2h
SloangNative.AddLinearEffect (akActor, "MyMod_Denial",  1.0, 2.0, 80.0) ; start 1, +2/h, cap 80
SloangNative.AddFlatEffect   (akActor, "MyMod_Cursed",  15.0)        ; steady +15 until cleared
SloangNative.AddDelayedEffect(akActor, "MyMod_SlowBurn",30.0, 6.0)   ; nothing for 6h, then +30
SloangNative.ClearDynamicEffect(akActor, "MyMod_Tease")             ; remove entirely
```

| Function | Effect |
|----------|--------|
| `AddFlatEffect(Actor who, string effectId, float amount)` | Constant, non-decaying named contribution |
| `AddDecayingEffect(Actor who, string effectId, float amount, float halveEveryHours)` | One-shot bump that halves every `halveEveryHours` toward 0 |
| `AddLinearEffect(Actor who, string effectId, float startAmount, float ratePerHour, float cap)` | Ramps by `ratePerHour` (negative to ramp down) until `cap` |
| `AddDelayedEffect(Actor who, string effectId, float amount, float delayHours)` | Contributes 0 for `delayHours`, then jumps to `amount` |
| `ClearDynamicEffect(Actor who, string effectId)` | Removes the effect entirely (safe if absent) |
| `bool HasDynamicEffect(Actor who, string effectId)` | True if the effect has a non-zero value |

### Low-level primitives

Reach for these only when a wrapper doesn't fit — you manage the raw `functionId`/`param`/`limit` yourself (use the [`FuncX()` accessors](#timed-function-id-accessors), not bare ints).

```papyrus
SloangNative.SetDynamicEffect(akActor, "MyMod_Tease", 50.0, SloangNative.FuncDecay(), 2.0 / 24.0, 0.0)
SloangNative.ModDynamicEffect(akActor, "MyMod_Tease", -20.0, 0.0)
float v = SloangNative.GetDynamicEffectValue(akActor, "MyMod_Tease")
```

| Function | Effect |
|----------|--------|
| `SetDynamicEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit)` | Create/replace a dynamic effect. `initialValue` is **absolute** (sets the value), and `initialValue == 0` is **ignored** — use `ClearDynamicEffect` to remove |
| `ModDynamicEffect(Actor who, string effectId, float modifier, float limit)` | Add `modifier` to an effect, clamped at `limit` |
| `float GetDynamicEffectValue(Actor who, string effectId)` | Read a single dynamic effect's value |

### Timed-function ID accessors

Prefer these over bare integers — they document intent and survive any future renumbering. See [Timed function IDs](overview.md#timed-function-ids) for behaviour.

| Accessor | ID | Behaviour |
|----------|----|-----------|
| `FuncNone()` | 0 | Static value |
| `FuncDecay()` | 1 | Halves every `param` game days |
| `FuncLinear()` | 2 | Changes by `param` per game day |
| `FuncSine()` | 3 | Oscillates |
| `FuncDelayedStep()` | 4 | Jumps to `limit` after `param` days |

## Reacting to updates (don't poll)

SLA recomputes arousal on its own scan cycle and fires the **`sla_UpdateComplete`** ModEvent once at the end of each cycle. React to that instead of polling `GetArousal` on a timer. There is no global-function wrapper — `RegisterForModEvent` must run on **your** script instance, so register and handle it directly (no dependency on `SloangNative` to receive it).

The numeric arg is the **count of actors** updated that cycle, not a specific actor — read whichever actor you care about (usually the player) inside the handler.

!!! note "This event is infrequent — not real-time"
    The scan cycle defaults to **120 seconds** (MCM-configurable), so `sla_UpdateComplete` fires only every couple of minutes. If you need the current value between cycles, just call `GetArousal` any time — it's a direct SKSE native call that re-sums the actor's effects on each call (not a cached value), so it always reflects the latest effect values. The event just marks the end of a scan cycle (timed effects advanced, plugins ran); it isn't what makes `GetArousal` current.

```papyrus
; register once, e.g. in OnInit / OnPlayerLoadGame
RegisterForModEvent("sla_UpdateComplete", "OnSlaUpdateComplete")

Event OnSlaUpdateComplete(string eventName, string strArg, float actorCount, Form sender)
    int arousal = SloangNative.GetArousalInt(Game.GetPlayer())
    ; ... map arousal -> your effect ...
EndEvent
```

## Per-actor flags & preferences

| Function | Notes |
|----------|-------|
| `bool IsActorNaked(Actor who)` | Uses the configured naked-detection rules |
| `bool IsActorExhibitionist(Actor who)` / `SetActorExhibitionist(Actor who, bool)` | |
| `bool IsArousalLocked(Actor who)` / `SetArousalLocked(Actor who, bool)` | Locked actors keep a fixed value |
| `bool IsArousalBlocked(Actor who)` / `SetArousalBlocked(Actor who, bool)` | Blocked actors are skipped by updates |
| `int GetGenderPreference(Actor who)` / `SetGenderPreference(Actor who, int)` | `0` Male, `1` Female, `2` Both, `3` SexLab |

## Orgasm tracking

| Function | Notes |
|----------|-------|
| `float GetDaysSinceLastOrgasm(Actor who)` | Game days since last recorded orgasm |
| `UpdateOrgasmDate(Actor who)` | Stamp an orgasm now (applies the default plugin's post-orgasm satisfaction handling, enjoyment `0`) |
| `Orgasm(Actor who, float enjoyment)` | Same as `UpdateOrgasmDate` but `enjoyment` weights the climax (`0.0` plain; higher deepens the post-orgasm dip) |

To register an orgasm from a script that must **not** compile-couple to SLA (e.g. cross-fork code, or you'd rather not import `SloangNative`), fire the **`slaOrgasm`** ModEvent instead — same effect as `UpdateOrgasmDate`, plus an `enjoyment` weight (`0.0` = a plain climax; higher values deepen the post-orgasm satisfaction dip):

```papyrus
int h = ModEvent.Create("slaOrgasm")
ModEvent.PushForm(h, akActor)
ModEvent.PushFloat(h, 0.0)   ; enjoyment
ModEvent.Send(h)
```

Registered by SLA NG 3.2.1+ only (older builds and other forks ignore it — use `UpdateOrgasmDate` / `slaFrameworkScr.UpdateActorOrgasmDate` there).

## Meta

| Function | Notes |
|----------|-------|
| `int GetVersion()` | Packed integer version (`MMmmppp`) |
