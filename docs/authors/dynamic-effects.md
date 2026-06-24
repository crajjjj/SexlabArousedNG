# Dynamic Effects

Dynamic effects are **named, time-aware contributions to an actor's arousal** — ideal for temporary conditions (a teasing encounter, a debuff) and effects that come and go infrequently. No quest script or plugin registration required.

There are two ways to drive them, and both reach the same system:

- **Native API (`SloangNative`) — recommended.** One global call per operation, no boilerplate. Requires compiling against `SloangNative.pex` (SLA NG 3.2.0+). See the [Native API reference](native-api.md). Examples below show it first.
- **ModEvents.** Fire `slaSetArousalEffect` / `slaModArousalEffect`. More verbose, but needs **zero compile-time coupling** and is the only option on older forks (OSL Aroused doesn't register these — see [Compatibility](compatibility.md)).

!!! warning "Performance"
    Each effect is stored in a per-actor `map<string, EffectData>`. Calling these very frequently (e.g. every frame) is expensive — for high-frequency, always-on updates prefer a [static effect](static-effects.md).

Whichever path you use, key each effect by a **unique, namespaced `effectId`** (`"MyMod_..."`) so it won't collide with other mods. Values may be negative (a negative effect lowers total arousal).

## Creating or replacing an effect

The `SloangNative` [convenience wrappers](native-api.md#convenience-wrappers-recommended) cover the common shapes in one line (all times in **in-game hours**):

```papyrus
SloangNative.AddDecayingEffect(akActor, "MyMod_Tease", 50.0, 2.0)   ; +50, halves every 2h toward 0
```

The equivalent ModEvent — `slaSetArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit)`, with `param` in **game days**:

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")  ; unique, namespaced effect ID
ModEvent.PushFloat(handle, 50.0)            ; initialValue: SETS the value (absolute)
ModEvent.PushInt(handle, 1)                 ; functionId 1 = decay (see table)
ModEvent.PushFloat(handle, 2.0 / 24.0)      ; param: half-life of 2 in-game hours
ModEvent.PushFloat(handle, 0.0)             ; limit: decay stops at 0
ModEvent.Send(handle)
```

Re-issuing with the same `effectId` **replaces** the effect. `initialValue` is **absolute** — it sets the value (so on an effect already at 30, passing 50 sets it to 50, raising total arousal by 20). Note `initialValue == 0` is **ignored** (the value is left unchanged) — to zero an effect, clear it (below).

## Modifying an existing effect

```papyrus
SloangNative.ModDynamicEffect(akActor, "MyMod_Tease", -20.0, 0.0)   ; -20, don't drop below 0
```

ModEvent equivalent — `slaModArousalEffect(Actor who, string effectId, float modifier, float limit)`:

```papyrus
int handle = ModEvent.Create("slaModArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")
ModEvent.PushFloat(handle, -20.0)   ; modifier
ModEvent.PushFloat(handle, 0.0)     ; limit
ModEvent.Send(handle)
```

The `limit` direction follows the sign of `modifier`: a lower bound when negative, an upper bound when positive. If the effect doesn't exist yet it is created at `modifier` (no prior create needed).

## Clearing an effect

```papyrus
SloangNative.ClearDynamicEffect(akActor, "MyMod_Tease")
```

There is no single ModEvent that removes an effect: the engine only drops one once its value is `0` **and** its function is `None`. So clearing by ModEvent takes two sends — drive the value to 0, then set the function to None:

```papyrus
; 1) clamp the value down to 0
int h = ModEvent.Create("slaModArousalEffect")
ModEvent.PushForm(h, who)
ModEvent.PushString(h, "MyMod_Tease")
ModEvent.PushFloat(h, -1000000.0)
ModEvent.PushFloat(h, 0.0)
ModEvent.Send(h)
; 2) set function -> None, which drops the now-zero effect
h = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(h, who)
ModEvent.PushString(h, "MyMod_Tease")
ModEvent.PushFloat(h, 0.0)
ModEvent.PushInt(h, 0)
ModEvent.PushFloat(h, 0.0)
ModEvent.PushFloat(h, 0.0)
ModEvent.Send(h)
```

(This two-step is exactly what `SloangNative.ClearDynamicEffect` does for you.)

## Timed function IDs

`functionId` selects how the effect changes over time. The native API exposes these as the [`FuncX()` accessors](native-api.md#timed-function-id-accessors) so you don't hard-code the integers.

| ID | Name | Behaviour |
|----|------|-----------|
| 0 | None | Effect stays at its current value indefinitely |
| 1 | Decay | Value halves every `param` game days. Stops (and removes effect) when it reaches `limit`. Negative `param` *grows* the value toward `limit` instead |
| 2 | Linear | Value changes by `param` per game day. Stops at `limit` |
| 3 | Sine wave | `value = (sin(time * param) + 1.0) * limit` — oscillates continuously, never stops |
| 4 | Delayed step | `value = 0` until `param` game days have elapsed, then `value = limit` |

## Example recipes

Native one-liners (the bracketed timed-function is what the ModEvent form would push):

```papyrus
; Post-sex arousal that fades over 4 hours [decay]
SloangNative.AddDecayingEffect(who, "MyMod_PostSex", 100.0, 4.0)

; Teasing effect that climbs to a cap of 50 [linear]
SloangNative.AddLinearEffect(who, "MyMod_Tease", 1.0, 200.0, 50.0)   ; start ~0, +200/h, cap 50

; Penalty that recovers over a day [linear]
SloangNative.AddLinearEffect(who, "MyMod_Penalty", -50.0, 50.0, 0.0) ; start -50, +50/h to 0

; A delayed effect that appears after 6 hours [delayed step]
SloangNative.AddDelayedEffect(who, "MyMod_SlowBurn", 30.0, 6.0)
```

Sine has no convenience wrapper — drive it with the low-level primitive:

```papyrus
; Ambient oscillation, ~one cycle per game day, amplitude 0–10 [sine]
SloangNative.SetDynamicEffect(who, "MyMod_Ambient", 0.0, SloangNative.FuncSine(), 1.0, 10.0)
```

!!! note "Cross-fork note"
    The native API needs SLA NG 3.2.0+. The `slaSetArousalEffect` / `slaModArousalEffect` ModEvents are registered by SLA NG (any 3.x), but **not** by OSL Aroused or other forks. If your mod must run across forks, guard accordingly — see [Compatibility](compatibility.md).
