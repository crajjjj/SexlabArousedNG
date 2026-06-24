Scriptname SloangNative hidden
{Canonical native API for SLO Aroused NG: GLOBAL functions to read/write arousal with
no quest casts or ModEvent boilerplate. One call per line:

    SloangNative.ModArousal(akActor, 10.0)
    float a = SloangNative.GetArousal(akActor)

Not to be confused with OSLArousedNative -- that is the separate OSL Aroused compat stub.

DEPENDENCY
    These global calls are NOT an esm master and won't stop your plugin loading when SLA
    is missing (an absent script just logs and returns 0/None/no-op). The only real
    coupling is at COMPILE time: SloangNative.pex on your import path. For zero compile
    coupling, use the slaSetArousalEffect / slaModArousalEffect ModEvents instead (same
    system, see the Dynamic Effects docs).

UNITS
    Arousal is one float per actor, conventionally 0-100 but unclamped (use GetArousalInt
    for a clamped 0-100). Raw FuncX/dynamic-effect time params are in GAME DAYS; the Add*
    wrappers take in-game HOURS.

REACTING -- don't poll
    To react to changes, register for the sla_UpdateComplete event (see EVENTS) rather
    than polling. GetArousal is a cheap native read; dynamic-effect writes are heavier,
    so don't spam them every frame (prefer a static-effect plugin for that).}

; ===========================================================================
; META  -- version check
; ===========================================================================

int function GetVersion() global
    {Returns the packed integer version (MMmmppp scheme, e.g. 30200000 for 3.2.0),
     or 0 if SLA is absent. Use it for feature-gating against a known minimum.

     Sample:
         if SloangNative.GetVersion() >= 30200000
             ; safe to use 3.2.0+ behaviour
         endif}
    slaMainScr slaMain = _Main()
    if !slaMain
        return 0
    endif
    return slaMain.GetVersion()
endFunction

; ===========================================================================
; EVENTS  -- there is no global wrapper: RegisterForModEvent must run on YOUR instance.
;
; sla_UpdateComplete -- fires at the end of each SLA scan cycle. React to this instead
;     of polling. It is INFREQUENT (cycle defaults to 120s, MCM-configurable) and the
;     numeric arg is the COUNT of actors updated, not a specific actor -- read whoever
;     you care about (usually the player) in the handler.
;
;         RegisterForModEvent("sla_UpdateComplete", "OnSlaUpdateComplete")
;
;         Event OnSlaUpdateComplete(string eventName, string strArg, float actorCount, Form sender)
;             int arousal = SloangNative.GetArousalInt(Game.GetPlayer())
;         EndEvent
; ===========================================================================

; ===========================================================================
; TIMED-FUNCTION IDs  -- pass these as the functionId of SetDynamicEffect.
; Prefer these accessors over bare ints: they document intent and survive any
; future renumbering. Behaviour summary (param/limit are per-effect):
;     None        value stays put forever
;     Decay       value halves every `param` game days, stops at `limit`
;                 (negative param GROWS toward `limit` instead)
;     Linear      value changes by `param` per game day, stops at `limit`
;     Sine        value = (sin(time * param) + 1) * limit, oscillates forever
;     DelayedStep value = 0 until `param` days elapse, then jumps to `limit`
; ===========================================================================

int function FuncNone() global
    {Timed-function ID 0: static value, never changes on its own.}
    return 0
endFunction

int function FuncDecay() global
    {Timed-function ID 1: exponential decay. Halves every `param` game days,
     stopping at `limit`. A NEGATIVE `param` grows the value toward `limit`.

     Sample -- a tease that starts at 50 and halves every 2 in-game hours down to 0:
         SloangNative.SetDynamicEffect(akActor, "MyMod_Tease", 50.0, SloangNative.FuncDecay(), 2.0 / 24.0, 0.0)}
    return 1
endFunction

int function FuncLinear() global
    {Timed-function ID 2: linear ramp. Changes by `param` per game day, stopping at `limit`.

     Sample -- build +10 per game day up to a cap of 80:
         SloangNative.SetDynamicEffect(akActor, "MyMod_Build", 0.0, SloangNative.FuncLinear(), 10.0, 80.0)}
    return 2
endFunction

int function FuncSine() global
    {Timed-function ID 3: continuous oscillation, value = (sin(time * param) + 1) * limit.
     Never stops on its own -- clear it explicitly when done (see SetDynamicEffect notes).}
    return 3
endFunction

int function FuncDelayedStep() global
    {Timed-function ID 4: stays 0 until `param` game days have elapsed, then jumps to `limit`.

     Sample -- nothing for 1 game day, then +30:
         SloangNative.SetDynamicEffect(akActor, "MyMod_Delayed", 0.0, SloangNative.FuncDelayedStep(), 1.0, 30.0)}
    return 4
endFunction

; ===========================================================================
; READING AROUSAL
; ===========================================================================

float function GetArousal(Actor who) global
    {Returns `who`'s current total arousal as an unclamped float (may exceed 100 or
     be negative). Returns 0.0 for a None actor. This is a direct SKSE native call
     that re-sums the actor's effects each call (not cached) -- cheap to call any time.

     Sample:
         float a = SloangNative.GetArousal(Game.GetPlayer())
         if a >= 80.0
             Debug.Notification("You are very aroused.")
         endif}
    if !who
        return 0.0
    endif
    return slaInternalModules.GetArousal(who)
endFunction

int function GetArousalInt(Actor who) global
    {Same as GetArousal but rounded and clamped to the 0-100 convention range.
     Handy for thresholds and UI. Returns 0 for a None actor.

     Sample:
         int pct = SloangNative.GetArousalInt(akTarget)   ; always 0..100}
    if !who
        return 0
    endif
    return PapyrusUtil.ClampInt(slaInternalModules.GetArousal(who) as int, 0, 100)
endFunction

float function GetExposure(Actor who) global
    {Returns only the legacy "exposure" component of arousal (the value driven by
     ModArousal/SetArousal and the default plugin), excluding other effects. Most
     mods want GetArousal instead; use this only if you specifically track exposure.
     Returns 0.0 for a None actor or when SLA is absent.}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return 0.0
    endif
    return slaMain.defaultPlugin.GetExposureLegacy(who)
endFunction

; ===========================================================================
; WRITING AROUSAL  (simple, exposure-based)
; ===========================================================================

float function ModArousal(Actor who, float modifier) global
    {Adds `modifier` (may be negative) to `who`'s exposure and returns the resulting
     value. This is the simplest "nudge arousal" call. Returns 0.0 for a None actor
     or when SLA is absent.

     For temporary effects that decay/ramp over time, or that you want to update or
     remove later by name, prefer SetDynamicEffect/ModDynamicEffect instead.

     Sample -- a one-shot bump and a one-shot reduction:
         SloangNative.ModArousal(akActor, 15.0)    ; +15
         SloangNative.ModArousal(akActor, -10.0)   ; -10}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return 0.0
    endif
    return slaMain.defaultPlugin.ModExposureLegacy(who, modifier)
endFunction

float function SetArousal(Actor who, float value) global
    {Drives `who`'s arousal toward `value` and returns the resulting value. Passing
     0.0 resets toward the floor (applies a large negative). Returns 0.0 for a None
     actor or when SLA is absent.

     NOTE: this is exposure-based, mirroring the legacy OSL/OAroused stubs -- it is
     not a guaranteed absolute "GetArousal will now equal `value`" set, because other
     active effects also contribute to total arousal. If you need precise control of
     a named amount, use a dynamic effect.

     Sample:
         SloangNative.SetArousal(akActor, 0.0)     ; calm them down
         SloangNative.SetArousal(akActor, 60.0)    ; push toward 60}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return 0.0
    endif
    if value == 0.0
        return slaMain.defaultPlugin.ModExposureLegacy(who, -100)
    endif
    return slaMain.defaultPlugin.ModExposureLegacy(who, value)
endFunction

; ===========================================================================
; DYNAMIC EFFECTS  -- named, time-aware contributions to arousal.
;
; PREFER the convenience wrappers in this section (AddFlatEffect / AddDecayingEffect /
; AddLinearEffect / AddDelayedEffect / ClearDynamicEffect) for almost everything: they
; cover the common shapes in one line and you never touch raw functionId / param /
; limit. Reach for the low-level SetDynamicEffect / ModDynamicEffect primitives (at the
; END of this section) only when no wrapper fits.
;
; Each effect is keyed by a string `effectId` PER ACTOR; namespace it with your mod's
; prefix ("MyMod_...") to avoid collisions. Effect values may be NEGATIVE: a negative
; effect lowers total arousal (e.g. calming/satisfaction). These are the direct-call
; equivalents of the slaSetArousalEffect / slaModArousalEffect ModEvents.
; ===========================================================================

; ---------------------------------------------------------------------------
; CONVENIENCE WRAPPERS -- the recommended way to use dynamic effects.
; All time arguments are in IN-GAME HOURS (converted to game days internally). Each
; "Add..." call CREATES or REFRESHES the named effect: calling it again with the same
; effectId resets it from scratch (it does not stack -- use ModDynamicEffect, below,
; to accumulate onto an existing effect).
; ---------------------------------------------------------------------------

function AddFlatEffect(Actor who, string effectId, float amount) global
    {Adds a constant, non-decaying contribution `amount` under `effectId`. Stays until
     you change or ClearDynamicEffect it. Unlike ModArousal, it is named, so you can
     read it back (GetDynamicEffectValue) or remove it later. No-op if amount == 0
     (use ClearDynamicEffect to remove) / None actor / no SLA.

     Sample -- a steady +15 while some condition holds, removed when it ends:
         SloangNative.AddFlatEffect(akActor, "MyMod_Cursed", 15.0)
         ; ... later ...
         SloangNative.ClearDynamicEffect(akActor, "MyMod_Cursed")

     Sample -- a steady penalty (negative): -20 while wearing a chastity belt:
         SloangNative.AddFlatEffect(akActor, "MyMod_Belt", -20.0)}
    SetDynamicEffect(who, effectId, amount, FuncNone(), 0.0, 0.0)
endFunction

function AddDecayingEffect(Actor who, string effectId, float amount, float halveEveryHours) global
    {Adds a one-shot bump of `amount` that fades exponentially, halving every
     `halveEveryHours` in-game hours, toward 0. The most common "temporary arousal"
     shape (a tease, a fleeting thrill). No-op if amount == 0 / None actor / no SLA.

     A NEGATIVE amount is a fading penalty: it starts below 0 and climbs back to 0.

     Sample -- +50 that loses half its strength every 2 in-game hours:
         SloangNative.AddDecayingEffect(akActor, "MyMod_Tease", 50.0, 2.0)

     Sample -- a -30 post-orgasm dip that recovers, halving every 4 in-game hours:
         SloangNative.AddDecayingEffect(akActor, "MyMod_Spent", -30.0, 4.0)}
    SetDynamicEffect(who, effectId, amount, FuncDecay(), halveEveryHours / 24.0, 0.0)
endFunction

function AddLinearEffect(Actor who, string effectId, float startAmount, float ratePerHour, float cap) global
    {Adds an effect starting at `startAmount` that changes by `ratePerHour` per in-game
     hour until it reaches `cap`, then holds. Use a negative `ratePerHour` to ramp down.
     No-op if startAmount == 0 (give a tiny non-zero start if you need to begin at ~0) /
     None actor / no SLA.

     Sample -- frustration that climbs +2/hour up to 80:
         SloangNative.AddLinearEffect(akActor, "MyMod_Denial", 1.0, 2.0, 80.0)

     Sample -- a cooldown that ramps DOWN from 0 by 5/hour to a -40 floor:
         SloangNative.AddLinearEffect(akActor, "MyMod_Cooldown", -1.0, -5.0, -40.0)}
    SetDynamicEffect(who, effectId, startAmount, FuncLinear(), ratePerHour * 24.0, cap)
endFunction

function AddDelayedEffect(Actor who, string effectId, float amount, float delayHours) global
    {Adds an effect that contributes nothing for `delayHours` in-game hours, then jumps
     to `amount` and holds. Useful for "kicks in after a while" mechanics. No-op if
     amount == 0 / None actor / no SLA.

     Sample -- +30 that only appears after 6 in-game hours:
         SloangNative.AddDelayedEffect(akActor, "MyMod_SlowBurn", 30.0, 6.0)

     Sample -- a -25 penalty that kicks in after 12 in-game hours:
         SloangNative.AddDelayedEffect(akActor, "MyMod_Withering", -25.0, 12.0)}
    ; The step target is `limit`; the value must START at 0 so nothing shows before the
    ; delay. initialValue 0 is ignored by the engine, which is exactly right here: a new
    ; effect defaults to value 0, and the timed function drives it to `limit` after the delay.
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return
    endif
    slaMain.SetDynamicArousalEffect(who, effectId, 0.0, FuncDelayedStep(), delayHours / 24.0, amount)
endFunction

function ClearDynamicEffect(Actor who, string effectId) global
    {Removes the dynamic effect `effectId` from `who` entirely (value -> 0, effect
     dropped). Safe to call when the effect does not exist. No-op for a None actor / no SLA.

     Removal requires BOTH driving the value to 0 and clearing the timed function, so
     this does it in two steps: ModDynamicEffect drives the value to the 0 floor, then
     SetDynamicEffect sets the function to None which lets the engine drop the entry.

     Sample:
         SloangNative.ClearDynamicEffect(akActor, "MyMod_Tease")}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return
    endif
    ; Big negative modifier clamped at 0 -> value becomes exactly 0 regardless of current value.
    slaMain.ModDynamicArousalEffect(who, effectId, -1000000.0, 0.0)
    ; function -> None with value already 0 triggers removal; initialValue 0 is intentionally ignored.
    slaMain.SetDynamicArousalEffect(who, effectId, 0.0, 0, 0.0, 0.0)
endFunction

bool function HasDynamicEffect(Actor who, string effectId) global
    {Convenience check: TRUE if `effectId` currently has a non-zero value on `who`.
     Note this is VALUE-based -- an effect sitting at exactly 0 reads as FALSE (and is
     usually already removed). Good enough for "is my buff active?" gating.

     Sample:
         if !SloangNative.HasDynamicEffect(akActor, "MyMod_Tease")
             SloangNative.AddDecayingEffect(akActor, "MyMod_Tease", 50.0, 2.0)
         endif}
    return GetDynamicEffectValue(who, effectId) != 0.0
endFunction

; ---------------------------------------------------------------------------
; LOW-LEVEL PRIMITIVES -- only when the wrappers above do not fit. You manage the
; raw functionId / param / limit yourself (see the TIMED-FUNCTION IDs section).
; ---------------------------------------------------------------------------

float function GetDynamicEffectValue(Actor who, string effectId) global
    {Returns the current value of a single named dynamic effect on `who`, or 0.0 if
     it does not exist / actor is None / SLA is absent. Lets you read back only your
     own contribution rather than the actor's total arousal.

     Sample:
         float mine = SloangNative.GetDynamicEffectValue(akActor, "MyMod_Tease")}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return 0.0
    endif
    return slaMain.GetDynamicEffectValueByName(who, effectId)
endFunction

function SetDynamicEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit) global
    {Creates or REPLACES the dynamic effect `effectId` on `who`. This is the low-level
     primitive; for common cases prefer the AddDecayingEffect / AddLinearEffect /
     AddFlatEffect / AddDelayedEffect / ClearDynamicEffect wrappers above.
        initialValue : the effect's value is SET to this (absolute, not a delta). The
                       total arousal change equals initialValue minus the previous value.
                       IMPORTANT: initialValue == 0 is IGNORED (the value is left
                       unchanged) -- to zero/remove an effect use ClearDynamicEffect.
        functionId   : one of the FuncX() accessors (FuncNone/FuncDecay/FuncLinear/FuncSine/FuncDelayedStep)
        param, limit : interpreted per the chosen function (see the FuncX docs)
     No-op for a None actor or when SLA is absent.

     Sample -- a tease that fades over ~2 in-game hours:
         SloangNative.SetDynamicEffect(akActor, "MyMod_Tease", 50.0, SloangNative.FuncDecay(), 2.0 / 24.0, 0.0)}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return
    endif
    slaMain.SetDynamicArousalEffect(who, effectId, initialValue, functionId, param, limit)
endFunction

function ModDynamicEffect(Actor who, string effectId, float modifier, float limit) global
    {Adds `modifier` to the current value of the dynamic effect `effectId` on `who`,
     clamping at `limit`. The clamp direction follows the sign of `modifier`:
     modifier < 0 treats `limit` as a lower bound; modifier > 0 as an upper bound.
     If the effect does not exist yet it is created at `modifier`. No-op for a None
     actor or when SLA is absent.

     Sample -- nudge an existing effect down without dropping below 0:
         SloangNative.ModDynamicEffect(akActor, "MyMod_Tease", -20.0, 0.0)}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return
    endif
    slaMain.ModDynamicArousalEffect(who, effectId, modifier, limit)
endFunction

; ===========================================================================
; PER-ACTOR FLAGS & PREFERENCES
; ===========================================================================

bool function IsActorNaked(Actor who) global
    {TRUE if `who` is considered naked under the player's configured naked-detection
     rules (keywords + armor slots). FALSE for a None actor or when SLA is absent.

     Sample:
         if SloangNative.IsActorNaked(akActor)
             SloangNative.ModArousal(akActor, 5.0)
         endif}
    slaMainScr slaMain = _Main()
    if !who || !slaMain
        return false
    endif
    return slaMain.IsActorNaked(who)
endFunction

bool function IsActorExhibitionist(Actor who) global
    {TRUE if `who` is flagged as an exhibitionist. FALSE for a None actor / no SLA.}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return false
    endif
    return slaFramework.IsActorExhibitionist(who)
endFunction

function SetActorExhibitionist(Actor who, bool isExhibitionist) global
    {Sets/clears the exhibitionist flag on `who`. No-op for a None actor / no SLA.

     Sample:
         SloangNative.SetActorExhibitionist(Game.GetPlayer(), true)}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return
    endif
    slaFramework.SetActorExhibitionist(who, isExhibitionist)
endFunction

bool function IsArousalLocked(Actor who) global
    {TRUE if `who`'s arousal is LOCKED (held at a fixed value; updates do not change it).
     FALSE for a None actor / no SLA.}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return false
    endif
    return slaFramework.IsActorArousalLocked(who)
endFunction

function SetArousalLocked(Actor who, bool isLocked) global
    {Locks/unlocks `who`'s arousal at its current value. While locked, the system will
     not recalculate it. No-op for a None actor / no SLA.

     Sample -- pin arousal during a scripted scene, then release:
         SloangNative.SetArousalLocked(akActor, true)
         ; ... scene ...
         SloangNative.SetArousalLocked(akActor, false)}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return
    endif
    slaFramework.SetActorArousalLocked(who, isLocked)
endFunction

bool function IsArousalBlocked(Actor who) global
    {TRUE if `who` is BLOCKED from arousal updates entirely (skipped by scans).
     FALSE for a None actor / no SLA.}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return false
    endif
    return slaFramework.IsActorArousalBlocked(who)
endFunction

function SetArousalBlocked(Actor who, bool isBlocked) global
    {Blocks/unblocks `who` from arousal updates. Blocked actors are ignored by the
     update loop. No-op for a None actor / no SLA.}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return
    endif
    slaFramework.SetActorArousalBlocked(who, isBlocked)
endFunction

int function GetGenderPreference(Actor who) global
    {Returns `who`'s gender preference: 0 Male, 1 Female, 2 Both, 3 SexLab (defer to
     SexLab's sexuality). Returns -2 for a None actor / no SLA.

     Sample:
         int pref = SloangNative.GetGenderPreference(akActor)}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return -2
    endif
    return slaFramework.GetGenderPreference(who)
endFunction

function SetGenderPreference(Actor who, int gender) global
    {Sets `who`'s gender preference. Pass 0 Male, 1 Female, 2 Both, or 3 SexLab.
     No-op for a None actor / no SLA.

     Sample:
         SloangNative.SetGenderPreference(akActor, 2)   ; attracted to both}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return
    endif
    slaFramework.SetGenderPreference(who, gender)
endFunction

; ===========================================================================
; ORGASM TRACKING
; ===========================================================================

float function GetDaysSinceLastOrgasm(Actor who) global
    {Returns game days elapsed since `who`'s last recorded orgasm (falls back to
     SexLab's last-sex time if SLA has no record). Returns -2.0 for a None actor / no SLA.

     Sample -- gate behaviour on a dry spell:
         if SloangNative.GetDaysSinceLastOrgasm(akActor) > 3.0
             SloangNative.ModArousal(akActor, 10.0)
         endif}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return -2.0
    endif
    return slaFramework.GetActorDaysSinceLastOrgasm(who)
endFunction

function UpdateOrgasmDate(Actor who) global
    {Stamps `who`'s last-orgasm time to now (and applies the default plugin's
     post-orgasm handling). Call this from your own climax events so the dry-spell
     and satisfaction systems stay in sync. No-op for a None actor / no SLA.

     Sample:
         SloangNative.UpdateOrgasmDate(akActor)}
    slaFrameworkScr slaFramework = _Framework()
    if !who || !slaFramework
        return
    endif
    slaFramework.UpdateActorOrgasmDate(who)
endFunction

; ===========================================================================
; INTERNAL HELPERS  (not part of the public API -- do not call directly)
; ===========================================================================

slaMainScr function _Main() global
    {Internal: resolves the main quest (sla_Main). Returns None if SLA is absent.}
    return Quest.GetQuest("sla_Main") as slaMainScr
endFunction

slaFrameworkScr function _Framework() global
    {Internal: resolves the framework quest (sla_Framework). Returns None if SLA is absent.}
    return Quest.GetQuest("sla_Framework") as slaFrameworkScr
endFunction
