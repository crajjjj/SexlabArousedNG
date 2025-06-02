
scriptname OSLAroused_ModInterface hidden

int function GetVersion() global
    return 271 ;2.7.1
endfunction

function SetUseOSLArousalMode(bool val) global
    Log("SetUseOSLArousalMode: Set to val: " + val)
    
    if(OSLArousedNativeConfig.IsInOSLMode() != val)
        OSLArousedNativeConfig.SetInOSLMode(val)
    endif
endfunction

float function GetArousal(Actor target) global
    return OSLArousedNative.GetArousal(target)
endfunction

float function GetArousalMultiplier(Actor target) global
    return OSLArousedNative.GetArousalMultiplier(target)
endfunction

float function GetExposure(Actor target) global
    return OSLArousedNative.GetExposure(target)
endfunction

float function ModifyArousal(Actor target, float value, string reason = "unknown") global
    Log("ModifyArousal: " + target.GetDisplayName() + " modified by val: " + value + " Reason: " + reason)
    return OSLArousedNative.ModifyArousal(target, value)
endfunction

float function SetArousal(Actor target, float value, string reason = "unknown") global
    Log("ModifyASetArousalrousal: " + target.GetDisplayName() + " set to val: " + value + " Reason: " + reason)
    return OSLArousedNative.SetArousal(target, value)
endfunction

function ModifyArousalMultiple(Actor[] actorArray, float value, string reason = "unknown") global
    Log("ModifyArousalMultiple: " + actorArray.Length + " actors modified by val: " + value + " Reason: " + reason)
    OSLArousedNative.ModifyArousalMultiple(actorArray, value)
endfunction

float function SetArousalMultiplier(Actor target, float value, string reason = "unknown") global
    Log("SetArousalMultiplier: " + target.GetDisplayName() + " Set to val: " + value + " Reason: " + reason)
    return OSLArousedNative.SetArousalMultiplier(target, value)
endfunction

float function ModifyArousalMultiplier(Actor target, float value, string reason = "unknown") global
    Log("ModifyArousalMultiplier: " + target.GetDisplayName() + " set to val: " + value + " Reason: " + reason)
    return OSLArousedNative.ModifyArousalMultiplier(target, value)
endfunction

float function GetLibido(Actor target) global
    return OSLArousedNative.GetLibido(target)
endfunction

float function ModifyLibido(Actor target, float value, string reason = "unknown") global
    Log("ModifyLibido: " + target.GetDisplayName() + " modified by val: " + value + " Reason: " + reason)
    return OSLArousedNative.ModifyLibido(target, value)
endfunction

function RegisterOrgasm(Actor target) global
    Log("RegisterOrgasm: " + target.GetDisplayName())
    OSLArousedNative.RegisterActorOrgasm(target)
endfunction

float function GetActorDaysSinceLastOrgasm(Actor target) global
    return OSLArousedNative.GetDaysSinceLastOrgasm(target)
endfunction

bool Function IsActorArousalLocked(Actor akRef) global
    return OSLArousedNative.IsActorArousalLocked(akRef)
endfunction
Function SetActorArousalLocked(Actor akRef, bool val = false) global
    Log("SetActorArousalLocked: " + akRef.GetDisplayName() + " Set to val: " + val)
    OSLArousedNative.SetActorArousalLocked(akRef, val)
endfunction

bool Function IsActorExhibitionist(Actor akRef) global
    return OSLArousedNative.IsActorExhibitionist(akRef)
endfunction
Function SetActorExhibitionist(Actor akRef, bool val = false) global
    Log("SetActorExhibitionist: " + akRef.GetDisplayName() + " Set to val: " + val)
    OSLArousedNative.SetActorExhibitionist(akRef, val)
endfunction

float function GetSLADefaultExposureRate() global
    return OSLAroused_Main.Get().SLADefaultExposureRate
endfunction

function Log(string msg) global
    if(OSLAroused_Main.Get().EnableDebugMode)
        Debug.Trace("---OSLAroused--- [ModInterface] " + msg)
    endif
endfunction