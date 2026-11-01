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
Actor crosshairRef = None

Bool Property wasPlayerRaped Auto
Bool bWasInitialized = False
Bool bUseLOS = False
Bool bNakedOnly = False ; retired in 3.4.0 (the MCM toggle never reached the update loop); kept for the Get/SetNakedOnly API
Bool bDisabled = False

Actor[] theActors
Actor[] scannedActors ; last native scan, nearest first, player excluded
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
Faction AND_ShowingChest
Faction AND_ShowingAss
Faction AND_ShowingBra
Faction AND_ShowingUnderwear
Faction AND_Modesty ; faction rank 0 (Modest) .. 6 (Shameless)
Faction AND_TopModesty
Faction AND_BottomModesty
Bool Property IsSLPInstalled = false auto hidden ; Sexlab Plus
Bool Property IsSLSOInstalled = false auto hidden ; SLSO
State cleaning

    Event OnUpdate()
    
        GotoState("")
        
        slax.Info("slaMainScr - cleaning state - OnUpdate")
        CleanActorStorage()
        RegisterForSingleUpdate(updateFrequency)
        
    endEvent
    
EndState


State initializing

    Event OnUpdate()
        
        slax.Info("slaMainScr - initialize state - OnUpdate")

        If modVersion < GetCurrentVersion()
            slax.Info("slaMainScr - Updating to version " + GetCurrentVersion() + " from version " + modVersion)
    
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
            
            int i = plugins.Length
            while i > 0
                i -= 1
                if plugins[i]
                    sla_PluginBase plugin = plugins[i]
                    plugin.ClearOptions()
                    plugin.AddOptions()
                endif
            endWhile
            ;"SLAroused.LastOrgasmDate"
            ;"SLAroused.LastRapeDate"
            ;"SLAroused.LastOrgasmDateAdjustmentDate"

        EndIf

        int pluginIdx = plugins.Length
        while pluginIdx > 0
            pluginIdx -= 1
            if plugins[pluginIdx]
                sla_PluginBase refreshPlugin = plugins[pluginIdx]
                refreshPlugin.ClearOptions()
                refreshPlugin.AddOptions()
            endif
        endWhile

        If !slaUtil
            slaUtil = Quest.GetQuest("sla_Internal") As slaInternalScr
        EndIf


        SetVersion(GetCurrentVersion())
        
        slaNextTimePlayerNaked.SetValue(0.0)    
            
        RegisterForModEvents()
        
        RegisterForCrosshairRef()
        
        nakedArmorWord = Keyword.GetKeyword("EroticArmor")
        
        slax.Info("slaMainScr - Initialize state - set up key handling")
        UnregisterForAllKeys()
        UpdateKeyRegistery()

        UpdateDesireSpell()

        slax.Info("slaMainScr - returning to normal state")
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
	slax.info(msg)
endFunction

function RegisterPlugin(sla_PluginBase plugin, bool addMCMOptions = true)
	; if plugins == None
	; 	plugins = new sla_PluginBase[1]
	; endIf
	; LogDebug("RegisterPlugin(" + plugin.name + ")")
	if !plugin || plugins.Find(plugin) > -1
        String pluginName = "None"
        if plugin
            pluginName = plugin.name
        endif
        slax.Warning("slaMainScr - RegisterPlugin - empty or registered.Name: " + pluginName)
		return
	endIf

    int pluginPos = slax.FindFirstFreeIndex(plugins)
    if pluginPos == -1
		slax.Error("slaMainScr - RegisterPlugin - not enough plugin slots" )
        return
	endIf
    slax.info("slaMainScr - RegisterPlugin " + plugin.name + ".Position:" + pluginPos)
	plugins[pluginPos] = plugin
    plugin.EnablePlugin()
    if (addMCMOptions)
        plugin.AddOptions()
    endif
    plugin.isEnabled = true
endFunction

function EnsureRegistered(sla_PluginBase plugin)
    {Re-assert plugins[] membership for a plugin that is already Installed but was
     dropped from the array by a past desync (array reinit / version upgrade). Unlike
     RegisterPlugin this skips EnablePlugin -- the plugin is already installed and
     ReassertSubscriptions handles its live subscriptions -- so it is safe to call on
     every load. Membership drives the Plugin List and the load-time option refresh.}
    if !plugin || !plugins || plugins.Find(plugin) > -1
        return
    endIf
    int pluginPos = slax.FindFirstFreeIndex(plugins)
    if pluginPos == -1
        slax.Error("slaMainScr - EnsureRegistered - not enough plugin slots")
        return
    endIf
    slax.info("slaMainScr - EnsureRegistered re-adding " + plugin.name + ".Position:" + pluginPos)
    plugins[pluginPos] = plugin
    plugin.isEnabled = true
    ; Only rebuild options if they were actually lost; clear first so we never
    ; stack a fresh set on top of orphaned entries left in StorageUtil.
    if plugin.GetNumberOfOptions() == 0
        plugin.ClearOptions()
        plugin.AddOptions()
    endif
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
                 slax.Error("slaMainScr SetPluginLOSEvents - No empty slot to add plugin!")
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
                 slax.Error("slaMainScr SetPluginUPDEvents - No empty slot to add plugin!")
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
        slax.warning("slaMainScr RegisterEffect TryLock failed. Retrying")
        Utility.WaitMenuMode(1.0)
    endWhile
    int idx = slaInternalModules.RegisterStaticEffect(id)
    if (idx == -2)
        slax.error("slaMainScr - RegisterEffect called during cleanup. Title:"+ title + ".Internal idx:" + idx + ".Id:" + id)
        slaInternalModules.Unlock(1)
        return idx
    endif
    slax.info("slaMainScr - RegisterEffect.Title:"+ title + ".Internal idx:" + idx + ".Id:" + id)
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
        slax.warning("slaMainScr UnregisterEffect TryLock failed. Retrying")
        Utility.WaitMenuMode(1.0)
    endWhile
    slax.info("slaMainScr - UnregisterEffect.Id:" + id)
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
    slax.Info("slaMainScr - effectIds:"+ effectIds.length + "--" + sArrayToString(effectIds))
    slax.Info("slaMainScr - effectTitles:"+ effectTitles.length + "--" + sArrayToString(effectTitles))
    slax.Info("slaMainScr - effectDescriptions:"+ effectDescriptions.length + "--" + sArrayToString(effectDescriptions))
    slax.Info("slaMainScr - effectIsVisible:"+ effectIsVisible.length + "--" + bArrayToString(effectIsVisible))
endfunction

bool Function IsEffectVisible(int effectIdx)
    if effectIsVisible && effectIdx >= 0 && effectIdx < effectIsVisible.length
        return effectIsVisible[effectIdx]
    else
        slax.warning("slaMainScr - IsEffectVisible(" + effectIdx + ") not found." )
        debugArrays()
        return false
    endif
EndFunction

string function GetEffectTitle(int effectIdx)
    if effectTitles && effectIdx >= 0 && effectIdx < effectTitles.length && effectTitles[effectIdx]
        return effectTitles[effectIdx]
    else
        slax.warning("slaMainScr - GetEffectTitle(" + effectIdx + ") not found")
        debugArrays()
        return ""
    endif
endFunction

string function GetEffectDescription(int effectIdx)
    if effectDescriptions && effectIdx >= 0 && effectIdx < effectDescriptions.length && effectDescriptions[effectIdx]
        return effectDescriptions[effectIdx]
    else
        slax.warning("slaMainScr - GetEffectDescription(" + effectIdx + ") not found")
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
    if slax.IsVerbose()
        slax.Info("slaMainScr - SetDynamicArousalEffect(" + who.GetLeveledActorBase().GetName() + ", " + effectId + ", " + initialValue + ", " + functionId + ", "+ param+ "," + limit + ")")
    endIf
    slaInternalModules.SetDynamicArousalEffect(who, effectId, initialValue, functionId, param, limit)
endFunction

function ModDynamicArousalEffect(Form whoF, string effectId, float modifier, float limit)
    Actor who = whoF as Actor
    if who == none
        return
    endIf
    if slax.IsVerbose()
        slax.Info("slaMainScr - ModDynamicArousalEffect(" + who.GetLeveledActorBase().GetName() + ", " + effectId + ", " + modifier + "," + limit + ")")
    endIf
    slaInternalModules.ModDynamicArousalEffect(who, effectId, modifier, limit)
endFunction

; ModEvent: fire "slaOrgasm" to register an orgasm for `who` (stamps last-orgasm time
; and applies the default plugin's post-orgasm satisfaction handling). `enjoyment` scales
; the satisfaction dip -- pass 0.0 for a plain "they came" with no extra weighting.
;   int h = ModEvent.Create("slaOrgasm")
;   ModEvent.PushForm(h, akActor)
;   ModEvent.PushFloat(h, 0.0)   ; enjoyment
;   ModEvent.Send(h)
function OnOrgasmEvent(Form whoF, float enjoyment)
    Actor who = whoF as Actor
    if who == none
        return
    endIf
    if slax.IsVerbose()
        slax.Info("slaMainScr - OnOrgasmEvent(" + who.GetLeveledActorBase().GetName() + ", " + enjoyment + ")")
    endIf
    defaultPlugin.OnOrgasm(who, enjoyment)
endFunction

float function ModEffectValue(Actor who, int effectIdx, float diff, float limit) 
    if slax.IsVerbose()
        slax.Info("slaMainScr - ModEffectValue(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + diff + ", " + limit + ")")
    endIf
    return slaInternalModules.ModStaticArousalValue(who, effectIdx, diff, limit)
endFunction

function SetEffectValue(Actor who, int effectIdx, float value) 
    if slax.IsVerbose()
        slax.Info("slaMainScr - SetEffectValue(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + value + ")")
    endIf
    slaInternalModules.SetStaticArousalValue(who, effectIdx, value)
endFunction

function SetTimedEffectFunction(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary) 
    if slax.IsVerbose()
        slax.Info("slaMainScr - SetTimedEffect(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effectIdx) + ", " + functionId + ", " + param + ")")
    endIf
    slaInternalModules.SetStaticArousalEffect(who, effectIdx, functionId, param, limit, auxilliary)
endFunction

bool function GroupEffects(Actor who, int effIdx1, int effIdx2)
    if slax.IsVerbose()
        slax.Info("slaMainScr - GroupEffects(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effIdx1) + ", " + GetEffectTitle(effIdx2) + ")")
    endIf
    return slaInternalModules.GroupEffects(who, effIdx1, effIdx2)
endFunction

bool function RemoveEffectGroup(Actor who, int effIdx)
    if slax.IsVerbose()
        slax.Info("slaMainScr - RemoveEffectGroup(" + who.GetLeveledActorBase().GetName() + ", " + GetEffectTitle(effIdx) + ")")
    endIf
    return slaInternalModules.RemoveEffectGroup(who, effIdx)
endFunction

int function UpdateSingleActorArousal(Actor who)
    {Ticks the native arousal of one actor and publishes it (SLP+ statistic, player
    notifications, SOS, the sla_Arousal faction rank). Returns the clamped 0-100 value.}
    if slax.IsVerbose()
        slax.Info("slaMainScr - UpdateArousal(" + who.GetLeveledActorBase().GetName() + ")")
    endIf
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
	return arousal
endFunction

event OnPlayerLoadGame()
    if bWasInitialized
        SendModEvent("sla_Int_PlayerLoadsGame")
    endIf
    slax.info("slaMainScr - OnPlayerLoadGame()")
    if effectIds != None
        slax.Info("slaMainScr effectIds length: " + effectIds.length)
    else
        slax.Info("slaMainScr effectIds length: 0")
    endif

    if effectTitles != None
        slax.Info("slaMainScr effectTitles length: " + effectTitles.length)
    else
        slax.Info("slaMainScr effectTitles length: 0")
    endif

    if effectDescriptions != None
        slax.Info("slaMainScr effectDescriptions length: " + effectDescriptions.length)
    else
        slax.Info("slaMainScr effectDescriptions length: 0")
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
    slax.Info("slaMainScr: Maintenance")
    UnregisterForUpdate()
    defaultPlugin.registerForInternalEvents()
    defaultPlugin.ddPlugin.registerForInternalEvents()
    sexlabPlugin.registerForInternalEvents()
    ostimPlugin.registerForInternalEvents()

    ; Re-resolve if the most recently added faction (AND_BottomModesty) is unset
    ; too, so saves that detected AND on an older build (IsANDInstalled already
    ; persisted True) still pick up factions added later -- otherwise the graduated
    ; exposure tiers / modesty ranks stay dead on upgrade.
    if (!IsANDInstalled || !AND_BottomModesty) && Game.GetModByName("Advanced Nudity Detection.esp") != 255
         slax.Info("slaMainScr: Advanced Nudity Detection mod found")
         AND_Nude = Game.GetFormFromFile(0x831, "Advanced Nudity Detection.esp") as Faction
         AND_Bottomless = Game.GetFormFromFile(0x833, "Advanced Nudity Detection.esp") as Faction
         AND_Genitals = Game.GetFormFromFile(0x830, "Advanced Nudity Detection.esp") as Faction
         AND_Topless = Game.GetFormFromFile(0x832, "Advanced Nudity Detection.esp") as Faction
         AND_ShowingChest = Game.GetFormFromFile(0x82F, "Advanced Nudity Detection.esp") as Faction
         AND_ShowingAss = Game.GetFormFromFile(0x82E, "Advanced Nudity Detection.esp") as Faction
         AND_ShowingBra = Game.GetFormFromFile(0x834, "Advanced Nudity Detection.esp") as Faction
         AND_ShowingUnderwear = Game.GetFormFromFile(0x835, "Advanced Nudity Detection.esp") as Faction
         AND_Modesty = Game.GetFormFromFile(0x86D, "Advanced Nudity Detection.esp") as Faction
         AND_TopModesty = Game.GetFormFromFile(0x8A3, "Advanced Nudity Detection.esp") as Faction
         AND_BottomModesty = Game.GetFormFromFile(0x8A4, "Advanced Nudity Detection.esp") as Faction
         IsANDInstalled = True
    endif

    If !IsSLPInstalled && SKSE.GetPluginVersion("SexLabUtil") >= 34275456 ;> V2.12.0 - 1.6.1170.zip
        slax.Info("slaMainScr: SLP+ mod found")
        IsSLPInstalled = true
    EndIf

    If !IsSLSOInstalled && 255 != Game.GetModByName("SLSO.esp")
        slax.Info("slaMainScr: SLSO mod found")
        IsSLSOInstalled = true
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
    
    ;slax.Info("slaMainScr Maintenance - trigger OnUpdate in 10.0 seconds")
    
    RegisterForSingleUpdate(10.0)

EndFunction


Function StartCleaning()
    UnregisterForUpdate()
    GotoState("cleaning")
    RegisterForSingleUpdate(10.0)
EndFunction


; Fills theActors with the actors around the player (nearest first, player excluded) and
; returns their count, or -1 while another caller holds the lock. The scan is native since
; 3.4.0 (slaInternalModules.ScanActors: loaded, AI-active actors within the MCM scan radius;
; no children, dead or disabled actors; creatures unless the MCM excludes them). It replaced
; the 25-alias slaScanAll quest, which cost a quest Start/Stop plus a 0.3 s wait per cycle
; and silently dropped every actor past the 25th.
; This handles the locking - callers should NOT pre-lock.
Int Function GetAllActors(Int lockID)
    ; Fails if the lock is already taken
    If(!slaInternalModules.TryLock(lockID))
        slax.Info("slaMainScr - GetAllActors(" + lockID + ") - LOCK NOT TAKEN")
        Return -1 ; Lock not taken
    EndIf

    Float now = Utility.GetCurrentRealTime()    ; In seconds
    If now - lastActorScanTime > 10.0 || scannedActors == None  ; Don't rescan actors if not enough time passed
        scannedActors = slaInternalModules.ScanActors(playerRef, slaConfig.scanRadius, slaConfig.maxTrackedActors, slaConfig.includeCreatures)
        If scannedActors == None ; an empty native array arrives as None
            scannedActors = PapyrusUtil.ActorArray(0)
        EndIf
        _Internal_actorCount = scannedActors.Length
        lastActorScanTime = now
        If slax.IsVerbose()
            slax.Info("slaMainScr - GetAllActors(" + lockID + ") - scanned " + _Internal_actorCount + " actors in " + (Utility.GetCurrentRealTime() - now) + " seconds")
        EndIf
    EndIf

    ; Each theActors array is a unique array - so if another instance modifies it, it's completely safe.
    theActors = slaInternalModules.DuplicateActorArray(scannedActors, _Internal_actorCount)
    If theActors == None
        theActors = PapyrusUtil.ActorArray(0)
    EndIf

    slaInternalModules.Unlock(lockID)
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
    slax.Info("slaMainScr - OnUpdate")
    If bDisabled
        RegisterForSingleUpdate(updateFrequency)
        Return
    EndIf
    
    ; Always a full update since 3.4.0: the old "small update" cycles skipped the observer
    ; pass, which left the naked effect decaying on each of them (and the default slider
    ; value made every cycle full anyway). The pass is native now, so there is nothing to save.
    UpdateActorArousals(true)

    ; Subtle difference - sends mod event before scheduling update - SLAR did the opposite, which could lead to re-entrance.
    RegisterForSingleUpdate(updateFrequency) ; default is 120 seconds, but may vary.
    
EndEvent

function UpdateActorArousals(bool fullUpdate)
    { Updates arousal values for all nearby actors. One cycle:
      1. native scan of the actors around the player (GetAllActors)
      2. per-actor pre-pass: naked state (+ cached exposure), exhibitionist refresh,
         OStim scene membership, gender preference (only when something can be seen)
      3. a native pass over every observer/observed pair (slaInternalModules.ComputeObservations:
         relevance filter, LOS, creature visibility, naked weighting, onlooker counting),
         requested in chunks of about 128 pairs so its raycasts spread over several frames.
         It replaced the Papyrus pair loop in 3.4.0, which cost HasLOS plus up to three
         UpdateObserver calls per pair per cycle.
      4. per actor: plugin.UpdateActor(actor), then plugin.ApplyObservations(actor, ...) for
         every LOS plugin that consumes aggregated observations. LOS plugins that still
         implement the per-pair UpdateObserver hook (third-party) get the old pair loop, for
         themselves only.
      5. plugin.UpdateActor(none) closes the cycle; every actor's arousal is ticked; the
         sla_UpdateComplete mod event fires with the actor count.
      fullUpdate is always true since 3.4.0; the parameter stays for the plugin API. }
    int actorCount = GetAllActors(2) ; LOCK THE ACTORS
    if actorCount < 0
        Debug.Trace("UpdateActorArousals - GetAllActors already locked")
        return
    endIf

    Actor[] updateActors = PapyrusUtil.PushActor(theActors, playerRef)
    actorCount += 1

    ; Drop blocked actors, compacting from the end.
    int i = 0
    while i < actorCount
        if slaUtil.IsActorArousalBlocked(updateActors[i])
            updateActors[i] = updateActors[actorCount - 1]
            actorCount -= 1
        else
            i += 1
        endIf
    endWhile
    if actorCount < 1
        SendModEvent("sla_UpdateComplete", None, 0)
        return
    endIf
    if updateActors.Length != actorCount
        updateActors = PapyrusUtil.ResizeActorArray(updateActors, actorCount)
    endIf

    ; --- per-actor pre-pass ---------------------------------------------------------------
    bool defaultActive = defaultPlugin && defaultPlugin.isEnabled
    bool scaleByExposure = defaultActive && defaultPlugin.ScaleNakedByExposure()
    Keyword creatureKeyword = none
    Faction creatureLover = none
    if defaultActive
        creatureKeyword = defaultPlugin.kActorTypeCreature
        creatureLover = defaultPlugin.slaCreatureSexLoverFaction
    endIf
    Faction slAnimating = sexlabPlugin.getSLAnimatingFaction()
    Actor[] sceneActors = none
    if ostimPlugin && ostimPlugin.isEnabled
        sceneActors = ostimPlugin.GetSceneActors()
    endIf
    int[] flags = Utility.CreateIntArray(actorCount)
    float[] exposure = Utility.CreateFloatArray(actorCount)
    int[] genderPref = Utility.CreateIntArray(actorCount, 2)
    bool anyNakedNPC = false
    bool anyNakedCreature = false
    bool anyExhibiting = false
    float nakedScale
    Actor who
    i = actorCount
    while i > 0
        i -= 1
        who = updateActors[i]
        int f = 0
        nakedScale = RefreshNakedState(who) ; -1.0 = not naked; also refreshes the sla_Naked rank and the cached exposure
        if nakedScale >= 0.0
            f = 1
            exposure[i] = 1.0
            if scaleByExposure
                exposure[i] = nakedScale
            endIf
            ; Creatures wear no body armor, so every tracked creature counts as naked.
            if creatureKeyword && who.HasKeyword(creatureKeyword)
                anyNakedCreature = true
            else
                anyNakedNPC = true
            endIf
        endIf
        if defaultActive && defaultPlugin.RefreshExhibitionist(who)
            f += 2
            anyExhibiting = true
        endIf
        if sceneActors != none && sceneActors.Find(who) >= 0
            f += 4
        endIf
        flags[i] = f
    endWhile
    ; Gender preference falls through to SexLab's sexuality stats for actors without a
    ; faction rank (most NPCs), so only pay for it when something can be seen, and only
    ; for the actors who can see it: a naked creature is visible to creatures and creature
    ; lovers alone, and one nearby horse must not cost a lookup for every tracked actor.
    if anyNakedNPC || anyExhibiting
        i = actorCount
        while i > 0
            i -= 1
            genderPref[i] = slaUtil.GetGenderPreference(updateActors[i])
        endWhile
    elseIf anyNakedCreature
        i = actorCount
        while i > 0
            i -= 1
            who = updateActors[i]
            if who.HasKeyword(creatureKeyword) || (creatureLover && who.GetFactionRank(creatureLover) > -1)
                genderPref[i] = slaUtil.GetGenderPreference(who)
            endIf
        endWhile
    endIf

    ; --- LOS plugins: snapshot once ------------------------------------------------------
    ; The cycle makes many external calls, during which the MCM can unregister or re-slot a
    ; plugin; the snapshot keeps every call of this cycle on the plugin it was planned for.
    bool useLOS = GetUseLOS() as bool
    int losCount = 0
    if losPlugins
        losCount = losPlugins.Length
    endIf
    if losCount > 8
        losCount = 8 ; losPlugins is created with 8 slots and never resized
    endIf
    sla_PluginBase[] aggPlugins = new sla_PluginBase[8]
    sla_PluginBase[] legacyPlugins = new sla_PluginBase[8]
    bool anyAggregated = false
    bool hasLegacyLos = false
    sla_PluginBase losPlugin
    int k = losCount
    if fullUpdate
        while k > 0
            k -= 1
            losPlugin = losPlugins[k]
            if losPlugin
                if losPlugin.UsesAggregatedObservations()
                    aggPlugins[k] = losPlugin
                    anyAggregated = true
                else
                    legacyPlugins[k] = losPlugin
                    hasLegacyLos = true
                endIf
            endIf
        endWhile
    endIf

    ; The observer pass runs on the main thread, so it is asked for in chunks of about 128
    ; observer/observed pairs: a crowded scene spreads its raycasts over several frames
    ; instead of stalling one. obs holds the rows of observers chunkStart .. chunkEnd.
    int chunkSize = 1
    if actorCount > 1
        chunkSize = 128 / (actorCount - 1)
        if chunkSize < 1
            chunkSize = 1
        endIf
    endIf
    float[] obs = none
    int chunkStart = actorCount
    int chunkCount

    ; --- per-actor plugin updates ---------------------------------------------------------
    Actor observer
    Actor observed
    sla_PluginBase plugin
    int j
    int base
    i = actorCount
    while i > 0
        i -= 1
        observer = updateActors[i]

        j = updatePlugins.Length
        while j > 0
            j -= 1
            plugin = updatePlugins[j]
            If (plugin)
                plugin.UpdateActor(observer, fullUpdate)
            EndIf
        endWhile

        if anyAggregated
            if i < chunkStart
                ; Observers are walked downwards: fetch the chunk that ends at i.
                chunkStart = i - chunkSize + 1
                if chunkStart < 0
                    chunkStart = 0
                endIf
                chunkCount = i - chunkStart + 1
                obs = slaInternalModules.ComputeObservations(updateActors, flags, exposure, genderPref, useLOS, creatureLover, slAnimating, chunkStart, chunkCount)
                if obs != none && obs.Length < chunkCount * 8
                    slax.Warning("slaMainScr - ComputeObservations returned " + obs.Length + " values for " + chunkCount + " observers; skipping them this cycle")
                    obs = none
                endIf
            endIf
            if obs != none
                base = (i - chunkStart) * 8
                k = losCount
                while k > 0
                    k -= 1
                    if aggPlugins[k]
                        aggPlugins[k].ApplyObservations(observer, obs[base], obs[base + 1], obs[base + 2] > 0.0, obs[base + 3] > 0.0, obs[base + 4] as int, obs[base + 5] > 0.0, obs[base + 6] > 0.0)
                    endIf
                endWhile
            endIf
        endIf

        if hasLegacyLos
            j = actorCount
            while j > 0
                j -= 1
                observed = updateActors[j]
                if observer != observed
                    if !useLOS || observer.HasLOS(observed)
                        k = losCount
                        while k > 0
                            k -= 1
                            if legacyPlugins[k]
                                legacyPlugins[k].UpdateObserver(observer, observed)
                            endIf
                        endWhile
                    endIf
                endIf
            endWhile
        endIf
    endWhile

    i = updatePlugins.Length
    while i > 0
        i -= 1
        plugin = updatePlugins[i]
        If (plugin)
           plugin.UpdateActor(none, fullUpdate)
        endif
    endWhile

    ; --- tick + bookkeeping ---------------------------------------------------------------
    ; Starts at 0 so only an actor with arousal above 0 can win: with nobody aroused the
    ; result is None, not whichever NPC happened to be scanned first.
    Actor mostAroused = none
    int mostArousal = 0
    i = actorCount
    while i > 0
        i -= 1
        who = updateActors[i]
        int arousal = UpdateSingleActorArousal(who)
        if who != playerRef && arousal > mostArousal
            mostArousal = arousal
            mostAroused = who
        endIf
    endWhile
    ; Feeds slaFrameworkScr.GetMostArousedActorInLocation and the MCM's "AROUSED:" target,
    ; which nothing had written since the original SLA.
    slaConfig.slaMostArousedActorInLocation = mostAroused
    slaConfig.slaArousalOfMostArousedActorInLoc = mostArousal

    SendModEvent("sla_UpdateComplete", None, actorCount)
endfunction

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
    Return RefreshNakedState(who) >= 0.0
EndFunction

; The body of IsActorNaked: refreshes the sla_Naked faction rank and the cached
; "SLAroused.NakedExposure" value, and returns -1.0 when not naked, else the graded
; exposure (GetNakedExposureScale, 1.0 without AND), so the update cycle gets it without
; reading the cache back.
Float Function RefreshNakedState(Actor who)

    If !who
        Return -1.0
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
        ; Cache the graded exposure, where we already pay the AND faction reads once per
        ; actor per cycle; other readers of the key (and pre-3.4.0 plugin code) use it.
        Float scale = GetNakedExposureScale(who)
        StorageUtil.SetFloatValue(who, "SLAroused.NakedExposure", scale)
        Return scale
    EndIf

    who.SetFactionRank(slaNaked, -2)
    Return -1.0

EndFunction


; How arousing the sight of `who` is to onlookers, 0.1 .. 1.0, from Advanced
; Nudity Detection's graduated states: showing bra/underwear +0.1 each, showing
; chest/genitals/ass +0.2 each, topless/bottomless 0.5 per region (subsuming
; that region's showing-states), fully nude 1.0. Returns 1.0 when AND is not
; installed or detects nothing on an actor we consider naked anyway (e.g.
; keyword-flagged naked armor), so the Naked effect keeps full strength.
Float Function GetNakedExposureScale(Actor who)
    If !who || !IsANDInstalled || !AND_Nude
        Return 1.0
    EndIf

    If who.GetFactionRank(AND_Nude) == 1
        Return 1.0
    EndIf

    Float top = 0.0
    If who.GetFactionRank(AND_Topless) == 1
        top = 0.5
    Else
        If AND_ShowingChest && who.GetFactionRank(AND_ShowingChest) == 1
            top += 0.2
        EndIf
        If AND_ShowingBra && who.GetFactionRank(AND_ShowingBra) == 1
            top += 0.1
        EndIf
    EndIf

    Float bottom = 0.0
    If who.GetFactionRank(AND_Bottomless) == 1
        bottom = 0.5
    Else
        If who.GetFactionRank(AND_Genitals) == 1
            bottom += 0.2
        EndIf
        If AND_ShowingAss && who.GetFactionRank(AND_ShowingAss) == 1
            bottom += 0.2
        EndIf
        If AND_ShowingUnderwear && who.GetFactionRank(AND_ShowingUnderwear) == 1
            bottom += 0.1
        EndIf
    EndIf

    Float scale = top + bottom
    If scale <= 0.0
        Return 1.0 ; naked by keyword/armor while AND sees nothing
    EndIf
    Return scale
EndFunction


; Returns how exposed an actor is, 0.0 (covered) .. 1.0 (fully nude), for the
; exhibitionist effect. Uses Advanced Nudity Detection's graduated states when
; present (top and bottom scored independently, then averaged); otherwise falls
; back to the binary slaNaked flag so behaviour is unchanged without AND.
Float Function GetExposureLevel(Actor who)
    If !who
        Return 0.0
    EndIf

    If IsANDInstalled && AND_Nude
        If who.GetFactionRank(AND_Nude) == 1
            Return 1.0
        EndIf

        Float top = 0.0
        If who.GetFactionRank(AND_Topless) == 1
            top = 1.0
        ElseIf AND_ShowingChest && who.GetFactionRank(AND_ShowingChest) == 1
            top = 0.6
        ElseIf AND_ShowingBra && who.GetFactionRank(AND_ShowingBra) == 1
            top = 0.3
        EndIf

        Float bottom = 0.0
        If who.GetFactionRank(AND_Genitals) == 1
            bottom = 1.0
        ElseIf who.GetFactionRank(AND_Bottomless) == 1
            bottom = 0.9
        ElseIf AND_ShowingAss && who.GetFactionRank(AND_ShowingAss) == 1
            bottom = 0.6
        ElseIf AND_ShowingUnderwear && who.GetFactionRank(AND_ShowingUnderwear) == 1
            bottom = 0.3
        EndIf

        Return (top + bottom) / 2.0
    EndIf

    ; No Advanced Nudity Detection: fall back to the binary naked flag.
    If who.GetFactionRank(slaNaked) > -2
        Return 1.0
    EndIf
    Return 0.0
EndFunction


; Dynamic exhibitionism qualification from Advanced Nudity Detection's modesty
; ranks (0 Modest, 1 Reasonable, 2 Relaxed, 3 Comfortable, 4 Tease, 5 Brazen,
; 6 Shameless): TRUE when the overall (strict) rank reaches the threshold, or
; when BOTH the top and bottom region ranks do. FALSE when AND is not installed
; (including a save where AND's factions no longer resolve after uninstall).
Bool Function IsModestyExhibitionist(Actor who, Int threshold)
    If !who || !IsANDInstalled || !AND_Modesty
        Return False
    EndIf

    If who.GetFactionRank(AND_Modesty) >= threshold
        Return True
    EndIf

    If AND_TopModesty && AND_BottomModesty
        Return who.GetFactionRank(AND_TopModesty) >= threshold && who.GetFactionRank(AND_BottomModesty) >= threshold
    EndIf
    Return False
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
        if StorageUtil.GetIntValue(armorToCheck, "SLAroused.IsClothingArmor") > 0 ; user-marked as clothing in MCM
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
            If candidate.HasKeyword(ArmorCuirass) || candidate.HasKeyword(ClothingBody) || StorageUtil.GetIntValue(candidate, "SLAroused.IsClothingArmor") > 0
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

    slax.Info("slaMainScr - UpdateKeyRegistry - key " + slaConfig.NotificationKey)
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

    slax.Info("slaMainScr - Key DOWN - key code " + keyCode + " expecting " + slaConfig.NotificationKey)
    If !Utility.IsInMenuMode() && slaConfig.NotificationKey == keyCode

        slax.Info("slaMainScr - performing key action")
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
 slax.Info("slaMainScr - StartPCMasturbation")
 if sexlabplugin.isEnabled
    sexlabplugin.StartPCMasturbation()
 elseif ostimPlugin.isEnabled
    ostimPlugin.StartPCMasturbation()
 else
    Debug.Notification("slaMainScr (StartPCMasturbation) - Sexlab or ostim plugins are not enabled")
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
    slax.info("slaMainScr: Cleaning actor storage")

    setCleaningTime()
    float days
    if slaConfig.wantsPurging
        days = 5.0
    else
        days = 10.0
    endif
    ; Runs asynchronously on the game thread; the count lands in SexlabArousedNG.log.
    slaInternalModules.CleanUpActors(gameDaysPassed.GetValue() - days)

    slax.info("slaMainScr: Actor cleaning scheduled (older than " + days + " days)")

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
    RegisterForModEvent("slaOrgasm", "OnOrgasmEvent")

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
