Scriptname OSLArousedNative hidden
{Compatibility stub: redirects OSL Aroused global API calls to SLO Aroused NG internals
so mods written against OSL Aroused (e.g. NPCs Approach) can run unchanged.
Functions without a clean SLA mapping return safe defaults.}

float function GetArousal(Actor who) global
    if !who
        return 0.0
    endif
    return slaInternalModules.GetArousal(who)
endFunction

float function GetArousalNoSideEffects(Actor who) global
    ; SLA's GetArousal is a cached read with no time-based recompute, so both delegate identically.
    return GetArousal(who)
endFunction

float function SetArousal(Actor who, float value) global
    if !who
        return 0.0
    endif
    slaMainScr slaMain = Quest.GetQuest("sla_Main") as slaMainScr
    if !slaMain
        return 0.0
    endif
    if value == 0.0
        return slaMain.defaultPlugin.ModExposureLegacy(who, -100)
    endif
    return slaMain.defaultPlugin.ModExposureLegacy(who, value)
endFunction

float function ModifyArousal(Actor who, float value) global
    if !who
        return 0.0
    endif
    slaMainScr slaMain = Quest.GetQuest("sla_Main") as slaMainScr
    if !slaMain
        return 0.0
    endif
    return slaMain.defaultPlugin.ModExposureLegacy(who, value)
endFunction

float function GetExposure(Actor who) global
    if !who
        return 0.0
    endif
    slaMainScr slaMain = Quest.GetQuest("sla_Main") as slaMainScr
    if !slaMain
        return 0.0
    endif
    return slaMain.defaultPlugin.GetExposureLegacy(who)
endFunction

float function GetArousalMultiplier(Actor who) global
    return 1.0
endFunction

float function GetLibido(Actor who) global
    return 0.0
endFunction

float function GetArousalBaseline(Actor who) global
    return 0.0
endFunction

bool function IsActorNaked(Actor who) global
    if !who
        return false
    endif
    slaMainScr slaMain = Quest.GetQuest("sla_Main") as slaMainScr
    if !slaMain
        return false
    endif
    return slaMain.IsActorNaked(who)
endFunction

bool function IsActorExhibitionist(Actor who) global
    if !who
        return false
    endif
    slaFrameworkScr slaFramework = Quest.GetQuest("sla_Framework") as slaFrameworkScr
    if !slaFramework
        return false
    endif
    return slaFramework.IsActorExhibitionist(who)
endFunction

function SetActorExhibitionist(Actor who, bool bIsExhibitionist) global
    if !who
        return
    endif
    slaFrameworkScr slaFramework = Quest.GetQuest("sla_Framework") as slaFrameworkScr
    if !slaFramework
        return
    endif
    slaFramework.SetActorExhibitionist(who, bIsExhibitionist)
endFunction

float function GetDaysSinceLastOrgasm(Actor who) global
    ; Approximate from the timestamp sla_DefaultPlugin stashes via StorageUtil on orgasm
    ; (see sla_defaultplugin.psc OnOrgasm). Untracked actors get a large default so
    ; callers gating on "long time since orgasm" treat them as ready, not just-satisfied.
    if !who
        return 999.0
    endif
    float lastOrgasm = StorageUtil.GetFloatValue(who, "SLAroused.LastOrgasmDate", -1.0)
    if lastOrgasm < 0.0
        return 999.0
    endif
    return Utility.GetCurrentGameTime() - lastOrgasm
endFunction
