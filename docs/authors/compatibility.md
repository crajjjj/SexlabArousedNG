# Compatibility (OSL Aroused & SLA NG)

Several mods ship their own `SexLabAroused.esm` that stubs `slaFrameworkScr` for backwards compatibility. The most common is **OSL Aroused**, which returns `GetVersion() = 20140124` and **does not** register the `slaSetArousalEffect` / `slaModArousalEffect` ModEvents. Writing a universal interface that gracefully handles both is straightforward.

## Detection

Both forks ship a quest with editor ID `sla_Framework`. Use that as your single presence check:

```papyrus
Quest Function GetFramework() Global
    return Quest.GetQuest("sla_Framework")
EndFunction

bool Function IsPresent() Global
    return Game.GetModByName("SexLabAroused.esm") != 255
EndFunction

; True only when real SLA NG is installed (OSL stub returns 20140124).
bool Function SupportsSLANG() Global
    Quest sla = GetFramework()
    if !sla
        return false
    endif
    return (sla as slaframeworkscr).GetVersion() > 20200000
EndFunction
```

!!! warning "Don't check for OSLAroused.esp"
    OSL ships its own `SexLabAroused.esm`, so `GetModByName("SexLabAroused.esm")` is present on both installs. Distinguish the forks by `GetVersion()`, not by ESP filename.

## Known version numbers

| Fork | `GetVersion()` | Registers ModEvents? |
|------|---------------|----------------------|
| OSL Aroused (all versions) | `20140124` | No |
| SLAXSE2022 | `20190720` | No |
| SexLab Aroused NG (this mod) | `>= 20200000` | Yes |

## Reading arousal (works on both forks)

`slaFrameworkScr.GetActorArousal()` is implemented by both forks and returns a value in 0–100. Prefer this over calling `slaInternalModules.GetArousal()` directly — it is portable.

```papyrus
Float Function GetArousal(Actor who) Global
    if !who
        return 0.0
    endif
    Quest sla = GetFramework()
    if !sla
        return 0.0
    endif
    return (sla as slaframeworkscr).GetActorArousal(who) as float
EndFunction
```

## Writing arousal (version-gated)

Use the ModEvent path for real SLA NG. For the OSL stub, fall back to `slaFrameworkScr.UpdateActorExposure()`, which OSL implements as a direct native call:

```papyrus
; Adds `value` to actor's arousal, capped at 100.
Function ModifyArousal(Actor who, Float value) Global
    if !who
        return
    endif
    if SupportsSLANG()
        ; Real SLA NG: use the ModEvent API (see Dynamic Effects).
        int handle = ModEvent.Create("slaModArousalEffect")
        if handle
            ModEvent.PushForm(handle, who)
            ModEvent.PushString(handle, "MyMod_Arousal") ; namespace your effect ID
            ModEvent.PushFloat(handle, value)
            ModEvent.PushFloat(handle, 100.0)            ; upper limit
            ModEvent.Send(handle)
        endif
    else
        ; OSL stub: UpdateActorExposure is available on both forks.
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, value as int)
        endif
    endif
EndFunction
```

For **timed effects** (ramps, decay), use `slaSetArousalEffect` guarded by `SupportsSLANG()`. Apply a one-shot `UpdateActorExposure` bump as the fallback — the timing won't be managed, but it preserves the direction and rough magnitude:

```papyrus
; Start a linear arousal climb at perDayDelta/day, capped at cap.
Function StartArousalRamp(Actor who, Float perDayDelta, Float cap) Global
    if !who || perDayDelta <= 0.0
        return
    endif
    if SupportsSLANG()
        int handle = ModEvent.Create("slaSetArousalEffect")
        if handle
            ModEvent.PushForm(handle, who)
            ModEvent.PushString(handle, "MyMod_Ramp")
            ModEvent.PushFloat(handle, 0.0)         ; initial delta
            ModEvent.PushInt(handle, 2)             ; functionId 2 = Linear
            ModEvent.PushFloat(handle, perDayDelta) ; param: change per game day
            ModEvent.PushFloat(handle, cap)         ; limit
            ModEvent.Send(handle)
        endif
    else
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, perDayDelta as int)
        endif
    endif
EndFunction

; Stop the ramp (no-op on OSL stub — fallback writes aren't tracked).
Function StopArousalRamp(Actor who) Global
    if !who || !SupportsSLANG()
        return
    endif
    int handle = ModEvent.Create("slaSetArousalEffect")
    if handle
        ModEvent.PushForm(handle, who)
        ModEvent.PushString(handle, "MyMod_Ramp")
        ModEvent.PushFloat(handle, 0.0)
        ModEvent.PushInt(handle, 0)   ; functionId 0 = None (removes effect)
        ModEvent.PushFloat(handle, 0.0)
        ModEvent.PushFloat(handle, 0.0)
        ModEvent.Send(handle)
    endif
EndFunction
```

## Putting it together as a Hidden interface script

Encapsulate all of this in a `Hidden` global script so callers don't need to know which fork is installed:

```papyrus
Scriptname MyMod_Arousal Hidden

bool Function IsPresent() Global
    return Game.GetModByName("SexLabAroused.esm") != 255
EndFunction

Quest Function GetFramework() Global
    return Quest.GetQuest("sla_Framework")
EndFunction

bool Function SupportsSLANG() Global
    Quest sla = GetFramework()
    if !sla
        return false
    endif
    return (sla as slaframeworkscr).GetVersion() > 20200000
EndFunction

Float Function GetArousal(Actor who) Global
    if !who
        return 0.0
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
    if SupportsSLANG()
        int handle = ModEvent.Create("slaModArousalEffect")
        if handle
            ModEvent.PushForm(handle, who)
            ModEvent.PushString(handle, "MyMod_Arousal")
            ModEvent.PushFloat(handle, value)
            ModEvent.PushFloat(handle, 100.0)
            ModEvent.Send(handle)
        endif
    else
        Quest sla = GetFramework()
        if sla
            (sla as slaframeworkscr).UpdateActorExposure(who, value as int)
        endif
    endif
EndFunction
```

Callers then simply do:

```papyrus
if MyMod_Arousal.IsPresent()
    float arousal = MyMod_Arousal.GetArousal(akTarget)
    MyMod_Arousal.ModifyArousal(akTarget, 10.0)
endif
```
