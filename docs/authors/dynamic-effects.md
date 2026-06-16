# Dynamic Effects

Dynamic effects are the simplest integration path. They are created by firing a ModEvent from any Papyrus script — **no quest script or plugin registration required**.

They are ideal for:

- Temporary conditions (a teasing encounter, a debuff)
- Effects that come and go infrequently
- Mods that don't want to maintain a persistent plugin quest

!!! warning "Performance"
    Dynamic effects are stored in a `map<string, EffectData>` per actor. Calling `SetDynamicArousalEffect` or `ModDynamicArousalEffect` very frequently (e.g. every frame) is expensive. For high-frequency updates prefer a [static effect](static-effects.md).

## Creating or replacing a dynamic effect

```papyrus
; slaSetArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit)
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)             ; Actor to affect
ModEvent.PushString(handle, "MyMod_Tease") ; Unique effect ID — namespace it to avoid collisions
ModEvent.PushFloat(handle, 50.0)           ; Initial value added to arousal immediately
ModEvent.PushInt(handle, 1)                ; Function ID (see table below)
ModEvent.PushFloat(handle, 2.0 / 24.0)     ; param: half-life of 2 hours
ModEvent.PushFloat(handle, 0.0)            ; limit: decay stops at 0
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

## Modifying an existing dynamic effect

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

## Timed function IDs

| ID | Name | Behaviour |
|----|------|-----------|
| 0 | None | Effect stays at its current value indefinitely |
| 1 | Decay | Value halves every `param` game days. Stops (and removes effect) when it reaches `limit` |
| 2 | Linear | Value changes by `param` per game day. Stops at `limit` |
| 3 | Sine wave | `value = (sin(time * param) + 1.0) * limit` — oscillates continuously, never stops |
| 4 | Delayed step | `value = 0` until `param` game days have elapsed, then `value = limit` |

For function 1 (decay), if `param` is negative the effect *grows* until reaching `limit`.

## Example recipes

### Post-sex arousal that fades over 4 hours

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_PostSex")
ModEvent.PushFloat(handle, 100.0)      ; start at 100
ModEvent.PushInt(handle, 1)            ; decay
ModEvent.PushFloat(handle, 4.0 / 24.0) ; half-life = 4 in-game hours
ModEvent.PushFloat(handle, 0.0)        ; remove when it reaches ~0
ModEvent.Send(handle)
```

### Teasing effect capped at 50

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Tease")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 2)              ; linear
ModEvent.PushFloat(handle, 200.0 * 24.0) ; +200 per hour
ModEvent.PushFloat(handle, 50.0)         ; cap at 50
ModEvent.Send(handle)
```

### Penalty that recovers over a day

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Penalty")
ModEvent.PushFloat(handle, -50.0)       ; start at -50
ModEvent.PushInt(handle, 2)             ; linear
ModEvent.PushFloat(handle, 50.0 * 24.0) ; +50 per hour
ModEvent.PushFloat(handle, 0.0)         ; stop at 0
ModEvent.Send(handle)
```

### Ambient oscillating arousal

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "MyMod_Ambient")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 3)      ; sine
ModEvent.PushFloat(handle, 1.0)  ; frequency: one cycle per game day
ModEvent.PushFloat(handle, 10.0) ; amplitude: oscillates 0–10
ModEvent.Send(handle)
```

!!! note "Cross-fork note"
    These ModEvents are only registered by real SLA NG — OSL Aroused and other forks do not provide them. If your mod must run on multiple forks, guard the ModEvent path behind a version check; see [Compatibility](compatibility.md).
