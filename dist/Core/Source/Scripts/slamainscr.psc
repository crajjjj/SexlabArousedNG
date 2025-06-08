Scriptname slaMainScr extends Quest  

Int Function GetCurrentVersion()
    return slaConfig.GetVersion() 
EndFunction

; FOLDSTART - Properties

slaInternalScr Property slaUtil Auto
slaConfigScr Property slaConfig Auto
Spell Property slaDesireSpell Auto
GlobalVariable Property slaNextTimePlayerNaked Auto
Quest Property slaScanAll Auto
Quest Property slaNakedNPC Auto
Keyword Property armorCuirass Auto
Keyword Property clothingBody Auto
Faction Property slaNaked Auto
Faction Property slaArousal Auto
GlobalVariable Property sla_NextMaintenance  Auto
GlobalVariable Property sla_AnimateFemales Auto
GlobalVariable Property sla_AnimateMales Auto
GlobalVariable Property sla_AnimationThreshhold Auto
GlobalVariable Property sla_UseLineOfSight Auto
Formlist Property sla_NakedArmorList Auto
Float Property updateFrequency = 30.00 Auto Hidden
Int[] Property actorTypes Auto Hidden ; [0] = 43/kNPC [1] = 44/kLeveledCharacter [2] = 62/kCharacter
SexLabFramework Property sexLab Auto ; deprecated
Actor Property playerRef Auto
GlobalVariable Property gameDaysPassed Auto
Quest Property slaScanAllNpcs Auto

sla_DefaultPlugin Property defaultPlugin Auto
sla_sexlabplugin Property sexlabPlugin Auto
sla_OStimPlugin Property ostimPlugin Auto
; FOLDEND - Properties


; FOLDSTART - Variables

Int previousPlayerArousal = 0;
Float lastNotificationTime = 0.0;
int updateCounter = 0;
Actor crosshairRef = None

Bool Property wasPlayerRaped Auto
Bool bWasInitialized = False
Bool bUseLOS = False
Bool bNakedOnly = True
Bool bDisabled = False

Actor[] theActors
Int _Internal_actorCount
Float lastActorScanTime

; FOLDEND - Variables


; FOLDSTART - Quasi constants

Int modVersion = 0;
Keyword nakedArmorWord

; FOLDEND - Quasi constants



; FOLDSTART - Plugin system

int Property pluginCount Auto ;deprecated
sla_PluginBase[] Property plugins Auto Hidden
int updatePluginCount ;deprecated
sla_PluginBase[] updatePlugins
int losPluginCount ; deprecated
sla_PluginBase[] losPlugins

; FOLDEND - Plugin system
;External
Bool Property IsANDInstalled = false auto hidden ; Advanced Nudity Detection
Faction AND_Nude
Faction AND_Topless
Faction AND_Bottomless
Faction AND_Genitals
Bool Property IsSLPInstalled = false auto hidden ; Sexlab Plus

State cleaning

    Event OnUpdate()
    
        GotoState("")
        
        slax.Info("SLOANG - cleaning state - OnUpdate")
        CleanActorStorage()
        RegisterForSingleUpdate(updateFrequency)
        
    endEvent
    
EndState


State initializing

    Event OnUpdate()
        
        slax.Info("SLOANG - initialize state - OnUpdate")

        If modVersion < GetCurrentVersion()
            slax.Info("SLOANG - Updating to version " + GetCurrentVersion() + " from version " + modVersion)
    
            slaConfig.IsUseSOS = False
            slaConfig.slaPuppetActor = playerRef
            
            slaUtil = Quest.GetQuest("sla_Internal") As slaInternalScr
            slaConfig.slaUtil = slaUtil
            
            StorageUtil.ClearFloatValuePrefix("SLAroused.TimeRate")
            StorageUtil.ClearFloatValuePrefix("SLAroused.Fatigue")
            StorageUtil.ClearFloatValuePrefix("SLAroused.Frustration")
            StorageUtil.ClearFloatValuePrefix("SLAroused.Trauma")
            StorageUtil.ClearFloatValuePrefix("SLAroused.ExposureRate")
            StorageUtil.ClearFloatValuePrefix("SLAroused.ActorExposure")
            StorageUtil.ClearFloatValuePrefix("SLAroused.ActorExposureDate")
            
            int i = slax.CountNonNullElements(plugins)
            while i > 0
                i -= 1
                sla_PluginBase plugin = plugins[i]
                plugin.ClearOptions()
                plugin.AddOptions()
            endWhile
            ;"SLAroused.LastOrgasmDate"
            ;"SLAroused.LastRapeDate"
            ;"SLAroused.LastOrgasmDateAdjustmentDate"

        EndIf
        
        If !slaUtil
            slaUtil = Quest.GetQuest("sla_Internal") As slaInternalScr
        EndIf
        

        SetVersion(GetCurrentVersion())
        
        slaNextTimePlayerNaked.SetValue(0.0)    
            
        RegisterForModEvents()
        
        RegisterForCrosshairRef()
        
        nakedArmorWord = Keyword.GetKeyword("EroticArmor")
        
        slax.Info("SLOANG - Initialize state - set up key handling")
        UnregisterForAllKeys()
        UpdateKeyRegistery()

        UpdateDesireSpell()

        slax.Info("SLOANG - return to empty state")
        GotoState("")
        RegisterForSingleUpdate(updateFrequency) ;Start scanning in two minutes

        if (GameDaysPassed.getValue() >= sla_NextMaintenance.getValue())
            StartCleaning()
        endif
		
		if !plugins
		    plugins = new sla_PluginBase[8]
            losPlugins = new sla_PluginBase[8]
            updatePlugins = new sla_PluginBase[8]
		    effectIds = new string[1]
		    effectTitles = new string[1]
            effectDescriptions = new string[1]
            effectIsVisible = new bool[1]
            effectOwners = new Form[1]
        endIf
		bWasInitialized = True
		SendModEvent("sla_Int_PlayerLoadsGame")        
    EndEvent

EndState


; State - EMPTY
function LogDebug(string msg)
	Debug.Notification(msg)
endFunction

function RegisterPlugin(sla_PluginBase plugin, bool addMCMOptions = true)
	; if plugins == None
	; 	plugins = new sla_PluginBase[1]
	; endIf
	; LogDebug("RegisterPlugin(" + plugin.name + ")")
	if !plugin || plugins.Find(plugin) > -1
        slax.Error("SLOANG - RegisterPlugin - empty or registered" )
		return
	endIf

    int pluginPos = slax.FindFirstFreeIndex(plugins)
    if pluginPos == -1
		slax.Error("SLOANG - RegisterPlugin - not enough plugin slots" )
        return
	endIf
    slax.info("SLOANG - RegisterPlugin " + plugin.name + ".Position:" + pluginPos)
	plugins[pluginPos] = plugin
    plugin.EnablePlugin()
    if (addMCMOptions)
        plugin.AddOptions()
    endif
    plugin.isEnabled = true
endFunction

function UnregisterPlugin(sla_PluginBase plugin)
	; LogDebug("UnregisterPlugin(" + plugin.name + ")")
	int idx = plugins.Find(plugin)
	if idx == -1
		return
	endIf
	plugins[idx] = none
endFunction

function SetPluginLOSEvents(sla_PluginBase plugin, bool listenToLOS)
    if listenToLOS
        ; Add plugin to first available None slot, if not present
        if losPlugins.Find(plugin) == -1
            int freeind = slax.FindFirstFreeIndex(losPlugins)
            if freeind == -1
                 slax.Error("SLOANG SetPluginLOSEvents - No empty slot to add plugin!")
            else
                losPlugins[freeind] = plugin
            endif
        endif
    else
        ; Remove plugin by setting to None
        int i = losPlugins.Find(plugin)
        if i != -1
            losPlugins[i] = None
        endif
    endif
endFunction

function SetPluginUpdateEvents(sla_PluginBase plugin, bool listenToUpdate)
    if listenToUpdate
         if updatePlugins.Find(plugin) == -1
            int freeind = slax.FindFirstFreeIndex(updatePlugins)
            if freeind == -1
                 slax.Error("SLOANG SetPluginUPDEvents - No empty slot to add plugin!")
            else
                updatePlugins[freeind] = plugin
            endif
        endif
    else
        int i = updatePlugins.Find(plugin)
        if i != -1
            updatePlugins[i] = None
        endif
    endif
endFunction

string[] effectIds
string[] effectTitles
string[] effectDescriptions
bool[] effectIsVisible
Form[] effectOwners ; sla_PluginBase[]

function RegisterDynamicEffect(string id, string title, string description)
    StorageUtil.SetStringValue(self, "SLAroused.DynamicEffect." + id + ".Title", title)
    StorageUtil.SetStringValue(self, "SLAroused.DynamicEffect." + id + ".Description", description)
endFunction

int function RegisterEffect(string id, string title, string description, sla_PluginBase effectOwner)
{Returns the effect index of the (possibly) newly registed effect.}
    while !slaInternalModules.TryLock(1)
        slax.warning("SLOANG RegisterEffect TryLock failed. Retrying")
        Utility.WaitMenuMode(1.0)
    endWhile
    int idx = slaInternalModules.RegisterStaticEffect(id)
    if (idx == -2)
        slax.error("SLOANG - RegisterEffect called during cleanup. Title:"+ title + ".Internal idx:" + idx + ".Id:" + id)
        slaInternalModules.Unlock(1)
        return idx
    endif
    slax.info("SLOANG - RegisterEffect.Title:"+ title + ".Internal idx:" + idx + ".Id:" + id)
    if idx >= effectIds.length
        effectIds = PapyrusUtil.ResizeStringArray(effectIds, idx + 1)
        effectTitles = PapyrusUtil.ResizeStringArray(effectTitles, idx + 1)
        effectDescriptions = PapyrusUtil.ResizeStringArray(effectDescriptions, idx + 1)
        effectOwners = PapyrusUtil.ResizeFormArray(effectOwners, idx + 1)
        effectIsVisible = PapyrusUtil.ResizeBoolArray(effectIsVisible, idx + 1)
    endIf
	effectIds[idx] = id
	effectTitles[idx] = title
	effectDescriptions[idx] = description
    effectOwners[idx] = effectOwner
    effectIsVisible[idx] = true
    slaInternalModules.Unlock(1)
	return idx
endFunction

function UnregisterEffect(string id)
    while !slaInternalModules.TryLock(1)
        slax.warning("SLOANG UnregisterEffect TryLock failed. Retrying")
        Utility.WaitMenuMode(1.0)
    endWhile
    slax.info("SLOANG - UnregisterEffect.Id:" + id)
    int result = effectIds.Find(id)
	if result > -1
        effectIds[result] = ""
        effectTitles[result] = ""
        effectDescriptions[result] = ""
        effectOwners[result] = none
    endIf
    slaInternalModules.UnregisterStaticEffect(id)
    slaInternalModules.Unlock(1)
endFunction

function SetEffectVisible(int effectIdx, bool visible)
    effectIsVisible[effectIdx] = visible
endfunction

int function GetDynamicEffectCount(Actor who)
    return slaInternalModules.GetDynamicEffectCount(who)
endFunction

string function GetDynamicEffect(Actor who, int number)
    return slaInternalModules.GetDynamicEffect(who, number)
endFunction

float function GetDynamicEffectValue(Actor who, int number)
    return slaInternalModules.GetDynamicEffectValue(who, number)
endFunction

float function GetDynamicEffectValueByName(Actor who, string effectId)
    return slaInternalModules.GetDynamicEffectValueByName(who, effectId)
endFunction

int function GetEffectCount()
    return slaInternalModules.GetStaticEffectCount()
endFunction

String Function sArrayToString(String[] values) Global
    if !values
        return "Empty Array"
    endif
    String result = ""
    Int i = 0
    While i < values.Length
        If values[i]
            result = result + "["+ i + "]:" + values[i]
        else
            result = result + "["+ i + "]: !None!"
        EndIf
        If i < values.Length - 1
            result = result + ","
        EndIf
        i=i+1
    EndWhile
    Return result
EndFunction
String Function bArrayToString(bool[] values) Global
    if !values
        return "Empty Array"
    endif
    String result = ""
    Int i = 0
    While i < values.Length
        result = result + "["+ i + "]:" + values[i]
        If i < values.Length - 1
           result = result + ","
        EndIf
        i=i+1
    EndWhile
    Return result
EndFunction

Function debugArrays()
    slax.Info("SLOANG - effectIds:"+ effectIds.length + "--" + sArrayToString(effectIds))
    slax.Info("SLOANG - effectTitles:"+ effectTitles.length + "--" + sArrayToString(effectTitles))
    slax.Info("SLOANG - effectDescriptions:"+ effectDescriptions.length + "--" + sArrayToString(effectDescriptions))
    slax.Info("SLOANG - effectIsVisible:"+ effectIsVisible.length + "--" + bArrayToString(effectIsVisible))
endfunction

bool Function IsEffectVisible(int effectIdx)
    if effectIsVisible && effectIdx >= 0 && effectIdx < effectIsVisible.length
        return effectIsVisible[effectIdx]
    else
        slax.warning("SLOANG - IsEffectVisible(" + effectIdx + ") not found." )
        debugArrays()
        return false
    endif
EndFunction

string function GetEffectTitle(int effectIdx)
    if effectTitles && effectIdx >= 0 && effectIdx < effectTitles.length && effectTitles[effectIdx]
        return effectTitles[effectIdx]
    else
        slax.warning("SLOANG - GetEffectTitle(" + effectIdx + ") not found")
        debugArrays()
        return ""
    endif
endFunction

string function GetEffectDescription(int effectIdx)
    if effectDescriptions && effectIdx >= 0 && effectIdx < effectDescriptions.length && effectDescriptions[effectIdx]
        return effectDescriptions[effectIdx]
    else
        slax.warning("SLOANG - GetEffectDescription(" + effectIdx + ") not found")
        debugArrays()
        return ""
    endif
endFunction

bool function IsEffectActive(Actor who, int effectIdx)
    return slaInternalModules.IsStaticEffectActive(who, effectIdx)
endFunction

float function GetEffectValue(Actor who, int effectIdx)
    return slaInternalModules.GetStaticEffectValue(who, effectIdx)
endFunction

float Function GetTimedEffectParameter(Actor who, int effectIdx)
    return slaInternalModules.GetStaticEffectParam(who, effectIdx)
endFunction

int Function GetTimedEffectAuxilliary(Actor who, int effectIdx)
    return slaInternalModules.GetStaticEffectAux(who, effectIdx)
endFunction

float Function GetTimedEffectLimit(Actor who, int effectIdx)
    return slaInternalModules.GetStaticEffectLimit(who, effectIdx)
endFunction

function SetDynamicArousalEffect(Form whoF, string effectId, float initialValue, int functionId, float param, float limit)
    Actor who = whoF as Actor
    if who == none
        return
    endIf
    slax.Info("SLOANG - SetDynamicArousalEffect(" + who.GetLeveledActorBase().GetName() + ", " + effectId + ", " + initialValue + ", " + functionId + ", "+ param+ "," + limit + ")")
    slaInternalModules.SetDynamicArousalEffect(who, effectId, initialValue, functionId, param, limit)
endFunction

function ModDynamicArousalEffect(Form whoF, string effectId, float modifier, float limit)
    Actor who = whoF as Actor
    if who == none
        return
    endIf
    slax.Info("SLOANG - ModDynamicArousalEffect(" + who.GetLeveledActorBase().GetName() + ", " + effectId + ", " + modifier + "," + limit + ")")
    slaInternalModules.ModDynamicArousalEffect(who, effectId, modifier, limit)
endFunction

float function ModEffectValue(Actor who, int effectIdx, float diff, float limit) 
    slax.Info("SLOANG - ModEffectValue(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + diff + ", " + limit + ")")
    return slaInternalModules.ModStaticArousalValue(who, effectIdx, diff, limit)
endFunction

function SetEffectValue(Actor who, int effectIdx, float value) 
    slax.Info("SLOANG - SetEffectValue(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + value + ")")
    slaInternalModules.SetStaticArousalValue(who, effectIdx, value)
endFunction

function SetTimedEffectFunction(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary) 
    slax.Info("SLOANG - SetTimedEffect(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + functionId + ", " + param + ")")
    slaInternalModules.SetStaticArousalEffect(who, effectIdx, functionId, param, limit, auxilliary)
endFunction

bool function GroupEffects(Actor who, int effIdx1, int effIdx2)
    slax.Info("SLOANG - GroupEffects(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effIdx1) + ", " + GetEffectTitle(effIdx2) + ")")
    return slaInternalModules.GroupEffects(who, effIdx1, effIdx2)
endFunction

bool function RemoveEffectGroup(Actor who, int effIdx)
    slax.Info("SLOANG - RemoveEffectGroup(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effIdx) + ")")
    return slaInternalModules.RemoveEffectGroup(who, effIdx)
endFunction

function UpdateSingleActorArousal(Actor who)
    slax.Info("SLOANG - UpdateArousal(" + who.GetLeveledActorBase().GetName() + ")")
    slaInternalModules.UpdateSingleActorArousal(who, GameDaysPassed.GetValue())

    int arousal = slaUtil.GetActorArousal(who)
    
    if IsSLPInstalled
        SexlabStatistics.SetStatistic(who, 17, arousal)
    endif

    if who == playerRef
        OnPlayerArousalUpdate(arousal)
    endIf

    if slaConfig.IsUseSOS
        slaUtil.UpdateSOSPosition(who, arousal)
    endIf

	If !who.IsInFaction(slaArousal)
		who.AddToFaction(slaArousal)
	EndIf

	who.SetFactionRank(slaArousal, arousal)
endFunction

event OnPlayerLoadGame()
    if bWasInitialized
        SendModEvent("sla_Int_PlayerLoadsGame")
    endIf
    slax.info("SLOANG - OnPlayerLoadGame()")
    if effectIds != None
        slax.Info("SLOANG effectIds length: " + effectIds.length)
    else
        slax.Info("SLOANG effectIds length: 0")
    endif

    if effectTitles != None
        slax.Info("SLOANG effectTitles length: " + effectTitles.length)
    else
        slax.Info("SLOANG effectTitles length: 0")
    endif

    if effectDescriptions != None
        slax.Info("SLOANG effectDescriptions length: " + effectDescriptions.length)
    else
        slax.Info("SLOANG effectDescriptions length: 0")
    endif
endEvent

Int Function IsAnimatingFemales()
    Return sla_AnimateFemales.getValue() As Int
EndFunction

Function SetIsAnimatingFemales(Int newValue)
    sla_AnimateFemales.setValue(newValue)
EndFunction

Int Function IsAnimatingMales()
    Return sla_AnimateMales.getValue() As Int
EndFunction

Function SetIsAnimatingMales(Int newValue)
    sla_AnimateMales.setValue(newValue)
EndFunction

Int Function GetAnimationThreshold()
    Return sla_AnimationThreshhold.getValue() As Int
EndFunction

Function SetAnimationThreshold(Int newValue)
    sla_AnimationThreshhold.setValue(newValue)
EndFunction

Int Function GetUseLOS()
    Return sla_UseLineOfSight.GetValue() As Int
EndFunction

Int Function GetNakedOnly()
    Return bNakedOnly As Int
EndFunction

Function SetNakedOnly(Int newValue)
    bNakedOnly = newValue As Bool
EndFunction

Int Function GetDisabled()
    Return bDisabled As Int
EndFunction

Function SetDisabled(Int newValue)
    bDisabled = newValue As Bool
EndFunction

Function SetUseLOS(Int newValue)
    sla_UseLineOfSight.setValue(newValue)
    bUseLOS = newValue As Bool
EndFunction

Function SetUpdateFrequency(Float frequency)
    updateFrequency = frequency
    If(bWasInitialized)
        UnregisterForUpdate()
        RegisterForSingleUpdate(updateFrequency)
    EndIf
EndFunction 

Event OnInit()
EndEvent

Function SetCleaningTime()
    Float nextTime = GameDaysPassed.GetValue() + 5.0 
    sla_NextMaintenance.SetValue(nextTime)
EndFunction


; This always runs on load
Function Maintenance()

    UnregisterForUpdate()
    defaultPlugin.registerForInternalEvents()
    defaultPlugin.ddPlugin.registerForInternalEvents()
    sexlabPlugin.registerForInternalEvents()
    ostimPlugin.registerForInternalEvents()

    if !IsANDInstalled && Game.GetModByName("Advanced Nudity Detection.esp") != 255
         slax.Info("SLOANG: Advanced Nudity Detection mod found")
         AND_Nude = Game.GetFormFromFile(0x831, "Advanced Nudity Detection.esp") as Faction
         AND_Bottomless = Game.GetFormFromFile(0x833, "Advanced Nudity Detection.esp") as Faction
         AND_Genitals = Game.GetFormFromFile(0x830, "Advanced Nudity Detection.esp") as Faction
         AND_Topless = Game.GetFormFromFile(0x832, "Advanced Nudity Detection.esp") as Faction
         IsANDInstalled = True
    endif

    If (!IsSLPInstalled && SKSE.GetPluginVersion("SexLabUtil") >= 34340864)
        slax.Info("SLOANG: SLP+ mod found")
        IsSLPInstalled = true
    EndIf

    GotoState("initializing")
    
    bWasInitialized = False

    ActorTypes = new Int[3]
    ActorTypes[0] = 43
    ActorTypes[1] = 44
    ActorTypes[2] = 62
    
    ; Since we don't save lock ClearLocks() is not necessary here
    lastActorScanTime = 0
    bUseLOS = GetUseLOS() As Bool
    
    ;slax.Info("SLOANG Maintenance - trigger OnUpdate in 10.0 seconds")
    
    RegisterForSingleUpdate(10.0)

EndFunction


Function StartCleaning()
    UnregisterForUpdate()
    GotoState("cleaning")
    RegisterForSingleUpdate(10.0)
EndFunction


; This handles the locking - callers should NO LONGER TRY TO pre-LOCK, that WAS A BROKEN PATTERN.
Int Function GetAllActors(Int lockID)
    slax.EnableDebugSpam(True)
    slax.DebugSpam_SetInfo()
    slax.Info("SLOANG - GetAllActors(" + lockID + ")")
    
    ; Fails if ANY lock already taken
    If(!slaInternalModules.TryLock(lockID))
        slax.Info("SLOANG - GetAllActors(" + lockID + ") - LOCK NOT TAKEN")
        ;Debug.Trace("Was locked, returning lock failed indicator")
        Return -1 ; Lock not taken
    EndIf
    
    ; TODO: can add feature here to never process creatures for arousal ... some might find it useful (use slaScanAllNpcs)
    slaScanAllScript scanner = slaScanAll As slaScanAllScript
    Float now = Utility.GetCurrentRealTime()    ; In seconds
    
    slax.Info("SLOANG - GetAllActors(" + lockID + ") - start scan at " + now)
    
    If now - lastActorScanTime > 10.0           ; Don't rescan actors if not enough time passed
    
        _Internal_actorCount = scanner.GetArousedActors()
        slax.Info("SLOANG - GetAllActors - scanned " + _Internal_actorCount + " local actors")

        lastActorScanTime = now
        
    EndIf
    
    ; Each theActors array is a unique array - so if another instance modifies it, it's completely safe.
    theActors = slaInternalModules.DuplicateActorArray(scanner.arousedActors, _Internal_actorCount)

    ; Note lock got taken above, and must be released at some point.
    slaInternalModules.Unlock(lockID)

    Float final = Utility.GetCurrentRealTime()
    slax.Info("SLOANG - GetAllActors(" + lockID + ") - end scan at " + now + " = " + (final - now) + " seconds")
    slax.Info("SLOANG - got " + theActors.Length + " actors")
    
    Return theActors.Length

EndFunction

Actor[] function GetNearbyActors()
    int maxTries = 10
    while maxTries > 0
        maxTries -= 1
        int actorCount = GetAllActors(1)
        if actorCount != -1
            return theActors
        endIf
    endWhile
    return new Actor[1]
endFunction

Event OnUpdate()
    slax.Info("SLOANG - OnUpdate")
    If bDisabled
        RegisterForSingleUpdate(updateFrequency)
        Return
    EndIf
    
    bool fullUpdate = true
    if slaConfig.smallUpdatesPerFull > 0
        if updateCounter >= slaConfig.smallUpdatesPerFull
            updateCounter = 0
        else
            fullUpdate = false
        endIf
        updateCounter += 1
    endIf
    UpdateActorArousals(fullUpdate)

    ; Subtle difference - sends mod event before scheduling update - SLAR did the opposite, which could lead to re-entrance.
    RegisterForSingleUpdate(updateFrequency) ; default is 120 seconds, but may vary.
    
EndEvent

function UpdateActorArousals(bool fullUpdate)
    { Updates arousal values for all nearby actors. Every actor update works in two steps: 
    First plugin.UpdateActor(...) will be called for every plugin. Then plugin.UpdateObserver(...) 
    will be called for every actor in line of sight to the actor being updated. The second 
    step will be skipped if fullUpdate is false.
    At the end plugin.UpdateActor(none) for each plugin to indicate the end of the update cycle. }
    int actorCount = GetAllActors(2) ; LOCK THE ACTORS
    if actorCount < 0
        Debug.Trace("UpdateActorArousals - GetAllActors already locked")
        return
    endIf
    
    Actor[] updateActors = PapyrusUtil.PushActor(theActors, playerRef)
    actorCount += 1 

    int i = 0
    while i < actorCount

        if slaUtil.IsActorArousalBlocked(updateActors[i])
            updateActors[i] = updateActors[actorCount - 1]
            actorCount -= 1
        ;elseIf updateActors[i].IsChild() ; GetAllActors should not find child actors anyway
        ;    slaUtil.SetActorArousalBlocked(updateActors[i], true)
        else
            ; updates naked state for actor
            IsActorNaked(updateActors[i])
            i += 1
        endIf

    endWhile
    ;int updPluginsAmount = slax.CountNonNullElements(updatePlugins)
    ;int losPluginsAmount = slax.CountNonNullElements(losPlugins)
    i = actorCount
    while i > 0
        i -= 1
        Actor observer = updateActors[i]
       
		;int j = updPluginsAmount
        int j = updatePlugins.Length
        while j > 0
            j -= 1
            sla_PluginBase plugin = updatePlugins[j]
            If (plugin)
                plugin.UpdateActor(observer, fullUpdate)
            EndIf
        endWhile

        if fullUpdate
            j = actorCount
            while j > 0
                j -= 1
                Actor observed = updateActors[j]
                if observer != observed
                    if !GetUseLOS() || observer.HasLOS(observed)
                        int k = losPlugins.Length
                        while k > 0
                            k -= 1
                            sla_PluginBase plugin = losPlugins[k]
                            If (plugin)
                                 plugin.UpdateObserver(observer, observed)
                            endif
                        endWhile
                    endIf
                endIf
            endWhile
        endIf
    endWhile
	
	i = updatePlugins.Length
	while i > 0
		i -= 1
		sla_PluginBase plugin = updatePlugins[i]
        If (plugin)
           plugin.UpdateActor(none, fullUpdate)
        endif
	endWhile
    
    i = actorCount
    while i > 0
        i -= 1
		UpdateSingleActorArousal(updateActors[i])
    endWhile

    SendModEvent("sla_UpdateComplete", None, actorCount)
endFunction

function ForceUpdateActor(Actor who)
    if who == none
        return
    endIf

    int i = 0
    if updatePlugins
        i = updatePlugins.Length
    endif

    while i > 0
        i -= 1
        sla_PluginBase plugin = updatePlugins[i]
        if plugin
            plugin.UpdateActor(who, false)
            plugin.UpdateActor(none, false)
        endIf
    endWhile
    UpdateSingleActorArousal(who)
endFunction

;Called by external programs using a modevent like
;Int eid = ModEvent.Create("eventname")
;ModEvent.PushForm(eid, Actor)
;ModEvent.PushFloat(eid, 3.5)
;ModEvent.Send(eid)

Event ModifyExposure(Form actorForm, Float exposureValue)

    Actor who = actorForm As Actor
    If who
        defaultPlugin.ModExposureLegacy(who, exposureValue)
    EndIf
    
EndEvent

; Note to modders : do not call IsActorNaked() because it is expensive - check sla_Naked faction rank instead
Bool Function IsActorNaked(Actor who)

    If !who
        Return False
    EndIf

    Bool isNaked = IsActorNakedVanilla(who)
    
    If !isNaked
        ; Consider 'naked armor for NPC' option
        If who == playerRef || slaConfig.IsExtendedNPCNaked
            isNaked = IsActorNakedExtended(who)
        EndIf
    EndIf

    If isNaked
        who.SetFactionRank(slaNaked, 0)
    Else
        who.SetFactionRank(slaNaked, -2)
    EndIf
    
    Return isNaked
    
EndFunction


Bool Function IsActorNakedVanilla(Actor who)

    Return !(who.WornHasKeyword(ArmorCuirass) || who.WornHasKeyword(ClothingBody))
    
EndFunction


Bool Function IsActorNakedExtended(Actor who)
    ;Can't just use WornHasKeyword, because we're trying to establish nakedness, not simply presence of a flagged armor.
    ;Check Advanced Nudity first
    If IsANDInstalled == True && AND_Nude
		If who.GetFactionRank(AND_Nude) == 1
			return True
		ElseIf who.GetFactionRank(AND_Topless) == 1 || who.GetFactionRank(AND_Bottomless) == 1
			return True
		ElseIf  who.GetFactionRank(AND_Genitals) == 1
			return True
		EndIf
	EndIf
    
    Armor armorToCheck = who.GetWornForm(0x00000004) As Armor ; Slot 32 - body
      if armorToCheck
        if armorToCheck.HasKeyword(nakedArmorWord) || StorageUtil.GetIntValue(armorToCheck, "SLAroused.IsNakedArmor") > 0  ; Naked in body slot overrides other armors.
            return true
        endif
        if armorToCheck.HasKeyword(ArmorCuirass) || armorToCheck.HasKeyword(ClothingBody) ;wearing slot 32 that is not naked
            return false
        endif
    endif
    
    ; Old code called GetEquippedArmors, which was a cut+paste of the same code in the MCM...
    ; ... it took several seconds to complete ...
    ; This was likely the reason for the option to disable NPC naked armors, as even the PC check alone would take several seconds!
    
    ; Instead just check feasible bikini slots... This is NOT the same code As GetBikiniArmorsForTargetActor in the MCM.
    ; It's still expensive, but it's an order faster than it was, as the cost of being a little more picky about its conditions.
    
    ; The extent to which this improves the responsiveness of arousal with armors in play is not to be underestimated, as the cost
    ; before this change was several seconds *per* npc tested.
    
    ; It was also written to get all armors THEN test them for nakedness - so it always paid the full fetch price, even if an armor could be found on the first try.
    String orderCacheKey = "sla_AuxilliaryArmorSlots"
    Int[] slotsToTest = StorageUtil.IntListToArray(slaConfig, orderCacheKey)
    
    If !slotsToTest || slotsToTest.Length != 7
        ; slotsToTest = new Int[7]
        ; slotsToTest[0] = Math.LeftShift(1, 14) ; slot 44
        ; slotsToTest[1] = Math.LeftShift(1, 15) ; slot 45
        ; slotsToTest[2] = Math.LeftShift(1, 18) ; slot 48
        ; slotsToTest[3] = Math.LeftShift(1, 19) ; slot 49
        ; slotsToTest[4] = Math.LeftShift(1, 22) ; slot 52
        ; slotsToTest[5] = Math.LeftShift(1, 26) ; slot 56
        ; slotsToTest[6] = Math.LeftShift(1, 28) ; slot 58
         slotsToTest = new int[7]
         slotsToTest[0] = 16384 ; slot 44
         slotsToTest[1] = 32768 ; slot 45
         slotsToTest[2] = 262144 ; slot 48
         slotsToTest[3] = 524288 ; slot 49
         slotsToTest[4] = 4194304 ; slot 52
         slotsToTest[5] = 67108864 ; slot 56
         slotsToTest[6] = 268435456 ; slot 58
        StorageUtil.IntListCopy(slaConfig, orderCacheKey, slotsToTest)
    EndIf

    Int ii = 0
    While ii < 7
        Armor candidate = who.GetWornForm(slotsToTest[ii]) As Armor
        ; We can early-out if we find a naked armor
        If candidate
            If candidate.HasKeyword(ArmorCuirass) || candidate.HasKeyword(ClothingBody)
                ; Look for an alternative to body covering armor that would make the character appear non-naked
                If (StorageUtil.GetIntValue(candidate, "SLAroused.IsNakedArmor") < 1) && !candidate.HasKeyword(nakedArmorWord)
                    Return False
                EndIf
            EndIf
        EndIf
        ii += 1
    EndWhile
    
    Return True ; Nothing found, naked after all...
    
EndFunction


Int Function GetVersion()
    Return modVersion
EndFunction


Function UpdateKeyRegistery() ; Wish I could fix the spelling of this.

    slax.Info("SLOANG - UpdateKeyRegistry - key " + slaConfig.NotificationKey)
    RegisterForKey(slaConfig.NotificationKey)
    
EndFunction


Function SetVersion(Int  newVersion)

    If modVersion < newVersion
        modVersion = newVersion
    ElseIf (modVersion > newVersion)
        Debug.Notification("SLO Aroused NG error : downgrading to version " + newVersion + " is not supported")
    EndIf
    
EndFunction


Function UpdateDesireSpell()

    If slaConfig.IsDesireSpell
        playerRef.RemoveSpell(slaDesireSpell)
        playerRef.AddSpell(slaDesireSpell, False)
    Else
        playerRef.RemoveSpell(slaDesireSpell)
    EndIf
    
EndFunction


Event OnKeyDown(Int keyCode)    

    slax.Info("SLOANG - Key DOWN - key code " + keyCode + " expecting " + slaConfig.NotificationKey)
    If !Utility.IsInMenuMode() && slaConfig.NotificationKey == keyCode

        slax.Info("SLOANG - performing key action")
        Debug.Notification(playerRef.GetLeveledActorBase().GetName() + " arousal level " + slaUtil.GetActorArousal(playerRef))
        
        If crosshairRef
            Debug.Notification(crosshairRef.GetLeveledActorBase().GetName() + " arousal level " + slaUtil.GetActorArousal(crosshairRef))
            slaConfig.slaPuppetActor = crosshairRef
        Else
            slaConfig.slaPuppetActor = playerRef
        EndIf
    EndIf
    
EndEvent


Event OnKeyUp(Int KeyCode, Float HoldTime)

    If !Utility.IsInMenuMode() && slaConfig.NotificationKey == keyCode
        If (HoldTime > 2.0)
            StartPCMasturbation()
        EndIf
    EndIf
    
EndEvent


Function StartPCMasturbation()
 slax.Info("SLOANG - StartPCMasturbation")
 if sexlabplugin.isEnabled
    sexlabplugin.StartPCMasturbation()
 elseif ostimPlugin.isEnabled
    ostimPlugin.StartPCMasturbation()
 else
    Debug.Notification("SLOANG (StartPCMasturbation) - Sexlab or ostim plugins are not enabled")
 endif

EndFunction


Event OnCrosshairRefChange(ObjectReference ref)

    crosshairRef = ref as Actor
    
EndEvent

Function OnPlayerArousalUpdate(Int arousal) 
    if slaConfig.enableNotifications == False
        return
    endIf

    If (arousal <= 20 && (previousPlayerArousal > 20 || lastNotificationTime + 0.5 <= GameDaysPassed.GetValue()))
        If wasPlayerRaped
            Debug.Notification("$SLA_NotificationArousal20Rape")
            wasPlayerRaped = False
        Else
            Debug.Notification("$SLA_NotificationArousal20")
        EndIf
        lastNotificationTime = GameDaysPassed.GetValue()
    ElseIf arousal >= 90 && (previousPlayerArousal < 90 || lastNotificationTime + 0.2 <= GameDaysPassed.GetValue())
        Debug.Notification("$SLA_NotificationArousal90")
        lastNotificationTime = GameDaysPassed.GetValue()
    ElseIf arousal >= 70 && (previousPlayerArousal < 70 || lastNotificationTime + 0.3 <= GameDaysPassed.GetValue())
        Debug.Notification("$SLA_NotificationArousal70")
        lastNotificationTime = GameDaysPassed.GetValue()
    ElseIf arousal >= 50 && (previousPlayerArousal < 50 || lastNotificationTime + 0.4 <= GameDaysPassed.GetValue())
        Debug.Notification("$SLA_NotificationArousal50")
        lastNotificationTime = GameDaysPassed.GetValue()
    EndIf

    previousPlayerArousal = arousal
    
EndFunction


Function CleanActorStorage()

    Debug.Notification("SLAX cleaning actor storage")
    
    setCleaningTime()
    float days
    if slaConfig.wantsPurging
        days = 5.0
    else
        days = 10.0
    endif
    int removedCount = slaInternalModules.CleanUpActors(gameDaysPassed.GetValue() - days)

    Debug.Trace("Removed " + removedCount + " unused settings.  Finished at " + Utility.GetCurrentRealTime());
    Debug.Notification("Actor cleaning complete removed: " + removedCount)
    
EndFunction


Bool Function IsImportant(Actor who)

    If !who || who.IsDead() || who.IsDeleted() || who.IsChild()
        Return False
    elseIf who == playerRef
        Return True
    EndIf
    
    ActorBase whoBase = who.GetLeveledActorBase()
    Return whoBase.IsUnique() || whoBase.IsEssential() || whoBase.IsInvulnerable() || whoBase.IsProtected() || who.IsGuard() || who.IsPlayerTeammate()
    
EndFunction


Function ClearFromActorStorage(Form FormRef)
    
    
EndFunction


Function RegisterForModEvents()

    UnregisterForAllModEvents()
    
    RegisterForModEvent("slaRegisterDynamicEffect", "RegisterDynamicEffect")
    RegisterForModEvent("slaSetArousalEffect", "SetDynamicArousalEffect")
    RegisterForModEvent("slaModArousalEffect", "ModDynamicArousalEffect")
    RegisterForModEvent("slaUpdateExposure", "ModifyExposure")
    
EndFunction

Actor [] function getLoadedActors(int lockNum)
    Actor [] actors = GetNearbyActors()
   ; slax.Info("SLAX - getLoadedActors(" + lockNum + ")")
    If actors.Length > 0
       ; slax.Info("SLAX - getLoadedActors: GetNearbyActors: " + actors.Length + " actors")
       ; slax.Info("SLAX - getLoadedActors: the actors: " + theActors.Length + " actors")
        return actors
    EndIf
    ;slax.Info("SLAX - getLoadedActors: GetNearbyActors(" + lockNum + ") - returned None")
    return new Actor[1]
endFunction

bool function UnlockScan(int lockNum)
    ;compatibility method
	return true
endFunction
