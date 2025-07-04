Scriptname sla_OStimPlugin Extends sla_PluginBase

Actor Property playerRef Auto
sla_DefaultPlugin Property defaultPlugin Auto

OSexIntegrationMain OStim
actor[] ActiveSceneActors

float[] previousModifiersThread0
float[] previousModifiersThread1
float[] previousModifiersThread2
float[] previousModifiersThread3
float[] previousModifiersThread4
float[] previousModifiersThread5
float[] previousModifiersThread6
float[] previousModifiersThread7
float[] previousModifiersThread8
float[] previousModifiersThread9

int sexEff = -1
int fatigueEff = -1
int traumaEff = -1

bool alwaysCheckOrgasm = false
float sexEffMax = 50.0
float sexHalfTime = 0.04166666 ; 1.0 / 24.0
float sexPerStage = 5.0

float traumaHalfTime = 0.5
float traumaBase = 11.0
float traumaLewdRate = 1.0

float fatigueHalfTime = 0.5
float fatigueBase = 5.0

bool function CheckDependencies()
    return Game.GetModByName("Ostim.esp") != 255
endFunction

event OnEndState()
    OStim = OUtils.GetOStim()
endEvent

	Function StartPCMasturbation()
    EndFunction
; ========== CONFIGURATION ==================

float function GetOptionValue(int optionId)
    if optionId == 0
        return sexEffMax
    elseif optionId == 1
        return sexHalfTime * 24.0
    elseif optionId == 2
        return alwaysCheckOrgasm as float
    elseif optionId == 3
        return traumaHalfTime
    elseif optionId == 4
        return traumaBase
    elseif optionId == 5
        return traumaLewdRate
    elseif optionId == 6
        return fatigueBase
    elseif optionId == 7
        return fatigueHalfTime
    elseif optionId == 8
        return sexPerStage
    endif
    return 0.0
endFunction

function OnUpdateOption(int optionId, float value)
    if optionId == 0
        sexEffMax = value
    elseif optionId == 1
        sexHalfTime = value / 24.0
    elseif optionId == 2
        alwaysCheckOrgasm = value as bool
    elseif optionId == 3
        traumaHalfTime = value
    elseif optionId == 4
        traumaBase = value
    elseif optionId == 5
        traumaLewdRate = value
    elseif optionId == 6
        fatigueBase = value
    elseif optionId == 7
        fatigueHalfTime = value
    elseif optionId == 8
        sexPerStage = value
    endif
endFunction

int function registerOstimEventHandlers()
    if (Game.GetModByName("Ostim.esp") == 255)
        return 0
    endif

    OStim = OUtils.GetOStim()
    if (OStim == none || OStim.GetAPIVersion() < 23)
        return 0
    endif

    if (OStim.GetAPIVersion() >= 29)
        RegisterForModEvent("ostim_thread_start", "OStimStartThread")
        RegisterForModEvent("ostim_thread_end", "OStimEndThread")
        RegisterForModEvent("ostim_actor_orgasm", "OStimOrgasmThread")
    else
        RegisterForModEvent("ostim_start", "OStimStart")
        RegisterForModEvent("ostim_end", "OStimEnd")
        RegisterForModEvent("ostim_orgasm", "OStimOrgasm")
    endif
    return 2
endFunction

Event OStimStartThread(String EventName, String Args, float ThreadID, Form Sender)
    HandleStartScene(ThreadID as int, OThread.GetActors(ThreadID as int))
EndEvent

Event OStimEndThread(String EventName, String Json, Float ThreadID, Form Sender)
    ; only works with API version 7.3.1 or higher
	Actor[] Actors = OJSON.GetActors(Json)
	HandleEndScene(ThreadID as int, Actors)
EndEvent

Event OStimStart(String EventName, String Args, Float Nothing, Form Sender)
    OStim = OUtils.GetOStim()
	; If this is OStim NG, return (processed in OStimStartThread)
	if (OStim.GetAPIVersion() >= 29)
		return
	endif
	ActiveSceneActors = OStim.GetActors()
	HandleStartScene(0, ActiveSceneActors)
EndEvent

Event OStimEnd(String EventName, String Args, Float Nothing, Form Sender)
   	; If this is OStim NG, return (processed in OStimEndThread)
	if (OUtils.GetOStim().GetAPIVersion() >= 29)
		return
	endif
	HandleEndScene(0, ActiveSceneActors)
EndEvent

Event OStimOrgasmThread(String EventName, String Args, Float ThreadID, Form Sender)
    if sender as Actor
		HandleActorOrgasm(ThreadID as int, sender as Actor)
	endif
EndEvent

Event OStimOrgasm(String EventName, String Args, Float Nothing, Form Sender)
	OStim = OUtils.GetOStim()
	; If this is OStim NG, bail out (Since Below code is processed in OStimOrgasmThread)
	if (OStim.GetAPIVersion() >= 29)
		return
	endif

	if sender as Actor
		HandleActorOrgasm(0, sender as Actor)
		return
	else ;Backup check for most recent orgasmer
		actor orgasmer = OStim.GetMostRecentOrgasmedActor() ; Was never all that reliable but it is the only failsafe if Sender isnt sent
		if orgasmer
			HandleActorOrgasm(0, orgasmer)
		endif
	endif

EndEvent

; ========== SHARED HANDLERS ================

Function HandleStartScene(int threadId, Actor[] threadActors)
    slax.Info("SLOANG - Ostim HandleStartScene - threadId " + threadId)
    CreatePreviousModifiers(ThreadID)
    bool bIsAggressive = OStim.IsSceneAggressiveThemed()
    int i = 0
    while i < threadActors.Length
        float sexEffectMod = sexPerStage
        if bIsAggressive
            sexEffectMod *= 2.0
        endif
        if !OStim.IsVictim(threadActors[i])
            ModArousalEffectValue(threadActors[i], sexEff, sexEffectMod, sexEffMax)
        endif
        CalculateStimMultiplier(ThreadID, threadActors[i], bIsAggressive, i)
        i += 1
    endwhile
EndFunction

Function HandleEndScene(int threadId, Actor[] threadActors)
    slax.Info("SLOANG - Ostim HandleEndScene - threadId " + threadId)
	Actor[] actorList = threadActors
	
	If (actorList.Length < 1)
		Return
	EndIf
		
	if OStim.IsSceneAggressiveThemed()
        Actor[] victims = threadActors
        int v = victims.Length
	 if traumaHalfTime != 0.0
	   while v > 0
	     v -= 1
        if OStim.IsVictim(victims[v])
            if victims[v] == PlayerRef
	      	    self.main.wasPlayerRaped = True
	        endIf
	        float delta = traumaLewdRate - traumaBase
	        float limit = 50.0
	        if delta < 0.0
	             limit = -50.0
	        endIf
	        ModArousalEffectValue(victims[v], traumaEff, delta, limit)
	        SetArousalDecayEffect(victims[v], traumaEff, traumaHalfTime, 0.0)
         endif
	   endWhile
	  endIf
    endif
    int i = actorList.Length
    bool applyFatigue = fatigueHalfTime != 0.0
    while i
    	i -= 1
    	if applyFatigue
    		ModArousalEffectValue(actorList[i], fatigueEff, -fatigueBase, -fatigueBase * 10.0)
    		SetArousalDecayEffect(actorList[i], fatigueEff, fatigueHalfTime, 0)
    	endIf
    	ForceUpdateArousal(actorList[i])
    endWhile
    
EndFunction

Function HandleActorOrgasm(int threadId, Actor targetActor)
    slax.Info("SLOANG - Ostim HandleActorOrgasm - threadId " + threadId)
    defaultPlugin.OnOrgasm(targetActor, 0)
    ForceUpdateArousal(targetActor)
EndFunction

Function CalculateStimMultiplier(int threadId, Actor act, bool isAggressive, int index)
	float[]  Modifiers = GetPreviousModifiers(threadId)
	float arousal = slaInternalModules.GetArousal(act)
	float modifyBy
       If (isAggressive && OStim.IsVictim(act))
           modifyBy= 0.0
       else
           if arousal >= 95
		    modifyBy = 1.25
	    elseif arousal <= 5
		    modifyBy = -0.35
	    elseif arousal <= 40 
		    modifyBy = 0.0
	    else 
		    arousal -= 40.0
		    modifyBy = (arousal/100.0)
	    endif 
       EndIf
	OUtils.GetOStim().ModifyStimMult(act, modifyBy - Modifiers[index])
	ModifyPreviousModifiers(threadId, index, modifyBy)
EndFunction

float[] Function GetPreviousModifiers(int ThreadID)
	if ThreadID == 0
		return previousModifiersThread0
	elseif ThreadID == 1
		return previousModifiersThread1
	elseif ThreadID == 2
		return previousModifiersThread2
	elseif ThreadID == 3
		return previousModifiersThread3
	elseif ThreadID == 4
		return previousModifiersThread4
	elseif ThreadID == 5
		return previousModifiersThread5
	elseif ThreadID == 6
		return previousModifiersThread6
	elseif ThreadID == 7
		return previousModifiersThread7
	elseif ThreadID == 8
		return previousModifiersThread8
	elseif ThreadID == 9
		return previousModifiersThread9
	endif
	return Utility.CreateFloatArray(10)
EndFunction

Function CreatePreviousModifiers(int ThreadID)
	if ThreadID == 0
		previousModifiersThread0 = Utility.CreateFloatArray(10)
	elseif ThreadID == 1
		previousModifiersThread1 = Utility.CreateFloatArray(10)
	elseif ThreadID == 2
		previousModifiersThread2 = Utility.CreateFloatArray(10)
	elseif ThreadID == 3
		previousModifiersThread3 = Utility.CreateFloatArray(10)
	elseif ThreadID == 4
		previousModifiersThread4 = Utility.CreateFloatArray(10)
	elseif ThreadID == 5
		previousModifiersThread5 = Utility.CreateFloatArray(10)
	elseif ThreadID == 6
		previousModifiersThread6 = Utility.CreateFloatArray(10)
	elseif ThreadID == 7
		previousModifiersThread7 = Utility.CreateFloatArray(10)
	elseif ThreadID == 8
		previousModifiersThread8 = Utility.CreateFloatArray(10)
	elseif ThreadID == 9
		previousModifiersThread9 = Utility.CreateFloatArray(10)
	endif
EndFunction

Function ModifyPreviousModifiers(int ThreadID, int index, float modify)
	if ThreadID == 0
		previousModifiersThread0[index] = modify
	elseif ThreadID == 1
		previousModifiersThread1[index] = modify
	elseif ThreadID == 2
		previousModifiersThread2[index] = modify
	elseif ThreadID == 3
		previousModifiersThread3[index] = modify
	elseif ThreadID == 4
		previousModifiersThread4[index] = modify
	elseif ThreadID == 5
		previousModifiersThread5[index] = modify
	elseif ThreadID == 6
		previousModifiersThread6[index] = modify
	elseif ThreadID == 7
		previousModifiersThread7[index] = modify
	elseif ThreadID == 8
		previousModifiersThread8[index] = modify
	elseif ThreadID == 9
		previousModifiersThread9[index] = modify
	endif
EndFunction

bool function isInScene(Actor act)
    return false
EndFunction  

state Installed
    event OnBeginState()
        OnInstalled()
    endEvent

    event OnEndState()
        OnUninstalled()
    endEvent

    function EnablePlugin()
        RegisterForPerodicUpdates()
        ;RegisterForLOSUpdates()
        registerOstimEventHandlers()
        sexEff = RegisterEffect("OSex", "$SLA_Effect_OSex", "$SLA_Effect_OSexDesc")
        fatigueEff = RegisterEffect("OFatigue", "$SLA_Effect_OFatigueBase", "$SLA_Effect_FatigueDesc")
        traumaEff = RegisterEffect("OTrauma", "$SLA_Effect_OTrauma", "$SLA_Effect_OTraumaDesc")
    endFunction

    function AddOptions()
        slax.info("SLOANG - Ostim.AddOptions()")
        AddOption("$SLA_Effect_SexCat", "$SLA_Effect_OSexMax", "$SLA_Effect_OSexMaxDesc", 50.0)
        AddOptionEx("$SLA_Effect_SexCat", "$SLA_Effect_OSexHalfTime", "$SLA_Effect_OSexHalfTimeDesc", 1.0 / 24.0, 0.1, 24.0, 0.1, "{1} hours")
        AddToggleOption("$SLA_Effect_SexCat", "$SLA_OAlwaysCheckOrgasm", "$SLA_OAlwaysCheckOrgasmDesc", false)
        AddOptionEx("$SLA_Effect_TraumaCat", "$SLA_Effect_OTraumaHalfTime", "$SLA_Effect_OTraumaHalfTimeDesc", 0.5, 0.0, 7.0, 0.1, "{1} days")
        AddOption("$SLA_Effect_TraumaCat", "$SLA_Effect_OTraumaBase", "$SLA_Effect_OTraumaBaseDesc", 10.0)
        AddOptionEx("$SLA_Effect_TraumaCat", "$SLA_Effect_OTraumaLewd", "$SLA_Effect_OTraumaLewdDesc", 1.0, 0.0, 10.0, 0.1, "{1}")
        AddOption("$SLA_Effect_FatigueCat", "$SLA_Effect_OFatigueBase", "$SLA_Effect_OFatigueBaseDesc", 5.0)
        AddOptionEx("$SLA_Effect_FatigueCat", "$SLA_Effect_OFatigueHalfTime", "$SLA_Effect_OFatigueHalfTimeDesc", 0.5, 0.0, 7.0, 0.1, "{1} days")
        AddOption("$SLA_Effect_SexCat", "$SLA_Effect_OSexPerStage", "$SLA_Effect_OSexPerStageDesc", 5.0)
    endFunction

    function DisablePlugin()
        parent.DisablePlugin()
        UnregisterEffect("OSex")
        UnregisterEffect("OFatigue")
        UnregisterEffect("OTrauma")
        UnregisterForAllModEvents()
    endFunction

    Function StartPCMasturbation()
        slax.Info("SLOANG (Ostim) - StartPCMasturbation")
        objectreference currentFurniture
	    String id
	    String animationX
        Actor targ = playerRef
        String typeAction

        if targ.GetLeveledActorBase().getSex() == 1 || targ.GetActorBase().getSex() == 1
			typeAction = "femalemasturbation"
		endIf
		if targ.GetLeveledActorBase().getSex() == 0 || targ.GetActorBase().getSex() == 0
			typeAction = "malemasturbation"
		endIf

	    targ.stopCombat()
	    utility.wait(0.200000)
	    Int currentThread = othreadbuilder.Create(oactorutil.ToArray(targ, none, none, none, none, none, none, none, none, none))
	    othreadbuilder.SetDominantActors(currentThread, oactorutil.ToArray(targ, none, none, none, none, none, none, none, none, none))
	    othreadbuilder.SetDuration(currentThread, 300 as Float)
	    objectreference[] Furnitures = ofurniture.FindFurniture(1, targ as objectreference, OStim.FurnitureSearchDistance as Float * 100.000, 96 as Float)
	    Int i = Furnitures.length
	    while i > 0
	    	i -= 1
	    	currentFurniture = Furnitures[i]
	    	String furnitureType = ofurniture.GetFurnitureType(currentFurniture)
	    	animationX = olibrary.GetRandomFurnitureSceneWithAction(oactorutil.ToArray(targ, none, none, none, none, none, none, none, none, none), furnitureType, typeAction)
	    	if animationX != ""
	    		i = -1
	    	endIf
	    endWhile
	    if animationX != ""
	    	othreadbuilder.SetFurniture(currentThread, currentFurniture)
	    	othreadbuilder.SetStartingAnimation(currentThread, animationX)
	    else
	    	othreadbuilder.NoFurniture(currentThread)
	    	id = olibrary.GetRandomSceneWithAction(oactorutil.ToArray(targ, none, none, none, none, none, none, none, none, none), typeAction)
	    	othreadbuilder.SetStartingAnimation(currentThread, id)
	    endIf
	    if animationX != "" || id != ""
	    	othreadbuilder.Start(currentThread)
        else
            Debug.Notification("OStim animation failed to start")
        endIf
        ; ; Send a mod event to OStim requesting a solo scene
        ; String genderTag = "F"
        ; if 0 == playerRef.GetLeveledActorBase().GetSex()
        ;     genderTag = "M"
        ; endIf

        ; int handle = ModEvent.Create("OStimStartSoloScene")
        ; ModEvent.PushForm(handle, playerRef)
        ; ModEvent.PushString(handle, genderTag)
        ; bool ok = ModEvent.Send(handle)

    EndFunction
    
    bool function isInScene(Actor act)
        if ActiveSceneActors && ActiveSceneActors.Length > 0
            int i = 0
            while i < ActiveSceneActors.Length
                if act == ActiveSceneActors[i]
                    return true
                endif
            i += 1
            endwhile
        endif
    return false
    EndFunction
endState
