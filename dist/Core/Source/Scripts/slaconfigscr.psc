Scriptname slaConfigScr extends SKI_ConfigBase  

; FOLDSTART - Properties
Keyword Property kArmorCuirass Auto
Keyword Property kClothingBody Auto

slaInternalScr Property slaUtil Auto
Int[] Property slaSlotMaskValues Auto Hidden
Actor Property slaPuppetActor Auto

Actor Property slaNakedActor Auto Hidden
Actor Property slaMostArousedActorInLocation Auto Hidden
Int Property slaArousalOfMostArousedActorInLoc Auto

ReferenceAlias Property follower Auto

Bool Property isDesireSpell Auto 
Bool Property isUseSOS Auto
Bool Property isExtendedNPCNaked Auto
Bool Property wantsPurging = false Auto Hidden
Bool Property MBonUsesSLGender = True Auto Hidden
Int Property notificationKey = 49 Auto Hidden
Float Property cellScanFreq = 30.00 Auto Hidden
Int Property smallUpdatesPerFull = 1 Auto Hidden
bool Property enableNotifications = true Auto Hidden
bool Property maleAnimation = false Auto Hidden
bool Property femaleAnimation = false Auto Hidden
bool Property useLOS = true Auto Hidden
Bool Property isNakedOnly = false Auto Hidden
Bool Property bDisabled = false Auto Hidden

; FOLDEND - Properties


; FOLDSTART - Keys
String keyNakedArmor
String keyBikiniArmor
String keySexyArmor
String keySlootyArmor
String keyIllegalArmor
String keyPoshArmor
String keyRaggedArmor
String keyKillerHeels
String[] pageKeys
; FOLDEND - Keys

; FOLDSTART - Keywords
Keyword wordNakedArmor
Keyword wordBikiniArmor
Keyword wordSexyArmor
Keyword wordSlootyArmor
Keyword wordIllegalArmor
Keyword wordPoshArmor
Keyword wordRaggedArmor
Keyword wordKillerHeels
; FOLDEND - Keywords


; FOLDSTART - Variables
String pageName
Int pageId

Bool statusNotSplash
Bool sliderMode

Int targetActorIndex
String[] targetActorNames
Actor[] targetActors

Actor puppetActor
Int puppetActorIndex
String[] puppetActorNames
Actor[] puppetActors

string filterMode = ""
string[] filterModes

Armor bodyItem
Armor footItem
Int nakedArmorValue
Int bikiniArmorValue
Int sexyArmorValue
Int slootyArmorValue
Int illegalArmorValue
Int poshArmorValue
Int raggedArmorValue
Int killerHeelsValue

Form[] bikiniArmors ; May not really be bikini armors, but that's what I'm trying to locate.
Int[] bikiniSliderValues
; FOLDEND - Variables

; FOLDSTART - OIDs
Int useSOSOID
Int desireSpellOID
Int exbitionistOID
Int extendedNPCNakedOID
Int blockArousalOID
Int lockArousalOID
Int MBonUsesSLGenderOID
Int notificationKeyOID
Int genderPreferenceOID
int cellScanFreqOID
int smallUpdateOID
int wantsPurgingOID
int maleAnimationOID
int femaleAnimationOID
int useLOSOID
int nakedOnlyOID
int enableNotificationsOID
int bDisabledOID
Int[] currentArmorListOID
Int targetActorMenuOID
Int statusNotSplashOID
Int puppetActorMenuOID
int clearActorDataOID
int clearAllDataOID

int exportSettingsOID
int importSettingsOID

int filterOID

Int sliderModeOID
Int bodyItemOID
Int noBodyItemOID
Int footItemOID
Int noFootItemOID
Int heelsSliderOID
Int heelsToggleOID

Int nakedSliderOID
Int bikiniSliderOID
Int sexySliderOID
Int slootySliderOID
Int illegalSliderOID
Int poshSliderOID
Int raggedSliderOID
Int[] bikiniSliderOIDs

Int nakedToggleOID
Int bikiniToggleOID
Int sexyToggleOID
Int slootyToggleOID
Int illegalToggleOID
Int poshToggleOID
Int raggedToggleOID
Int[] bikiniToggleOIDs

; FOLDEND - OIDs


; FOLDSTART - Quasi constants
slaMainScr slaMain 
Actor player
String[] genderPreferenceList
Form[] emptyFormArray
Armor[] emptyArmorArray
; FOLDEND - Quasi constants


Int Function GetVersion() 
    Return       30000002
	;	0.00.00000
    ; 1.0.0   -> 10000000
    ; 1.1.0   -> 10100000
    ; 1.1.1  ->  10100001
    ; 1.61  ->   16100000
    ; 10.61.20 ->10610020
EndFunction

String Function GetVersionString() 
    Return "3.0.2"
EndFunction

Event OnVersionUpdate(int newVersion)

    ResetConstants()
    
	If (((newVersion >= 7) && (CurrentVersion < 7)) || (Pages.length < 4))
		Debug.Trace(self + ": Updating MCM menus to version " + newVersion)

		InitSlotMaskValues()
	EndIf
    
	If((CurrentVersion > 0) && (CurrentVersion < 28))
    
		Debug.Notification("Updating Aroused Redux to version " + GetVersion() + "...")
		sla_ConfigHelper helper = Quest.getQuest("sla_ConfigHelper") As sla_ConfigHelper
		helper.ResetAllQuests()
        
	Endif

    If ((newVersion >= 30000001) && (CurrentVersion == 30000000))
		Debug.Trace(self + ": Updating MCM menus to version " + newVersion)
        slax.Info("SLOANG cleaning options for pre 3.0.1 versions")
       
        If (slaMain.defaultPlugin.ddPlugin.IsInterfaceActive())
            slaMain.UnregisterPlugin(slaMain.defaultPlugin.ddPlugin)
            slaMain.defaultPlugin.ddPlugin.ClearOptions()
            slaMain.RegisterPlugin(slaMain.defaultPlugin.ddPlugin)
        EndIf
        If (slaMain.defaultPlugin.IsInterfaceActive())
            slaMain.UnregisterPlugin(slaMain.defaultPlugin)
            slaMain.defaultPlugin.ClearOptions()
            slaMain.RegisterPlugin(slaMain.defaultPlugin)
        EndIf
        If (slaMain.ostimPlugin.IsInterfaceActive())
             slaMain.UnregisterPlugin(slaMain.ostimPlugin)
             slaMain.ostimPlugin.ClearOptions()
             slaMain.RegisterPlugin(slaMain.ostimPlugin)
        EndIf
        If (slaMain.sexlabPlugin.IsInterfaceActive())
            slaMain.UnregisterPlugin(slaMain.sexlabPlugin)
            slaMain.sexlabPlugin.ClearOptions()
            slaMain.RegisterPlugin(slaMain.sexlabPlugin)
        EndIf
		
	EndIf
    
EndEvent


Event OnGameReload()

    slax.Info("SLOANG - OnGameReload")
    
    ResetConstants()

    RestoreKeywords(keyNakedArmor,   wordNakedArmor)
    RestoreKeywords(keyBikiniArmor,  wordBikiniArmor)
    RestoreKeywords(keySexyArmor,    wordSexyArmor)
    RestoreKeywords(keySlootyArmor,  wordSlootyArmor)
    RestoreKeywords(keyIllegalArmor, wordIllegalArmor)
    RestoreKeywords(keyPoshArmor,    wordPoshArmor)
    RestoreKeywords(keyRaggedArmor,  wordRaggedArmor)
    RestoreKeywords(keyKillerHeels,  wordKillerHeels)
    
	slaMain = Quest.GetQuest("sla_Main") As slaMainScr
	slaMain.Maintenance()
   
    slaMain.OnPlayerLoadGame()
    parent.OnGameReload() ; Don't forget to call the parent!

EndEvent


Function ResetToDefault()

    ResetConstants()
    
	slaUtil = Quest.GetQuest("sla_Internal") As slaInternalScr
	slaPuppetActor = player
	slaNakedActor = None
	slaMostArousedActorInLocation = None
	slaArousalOfMostArousedActorInLoc = 0
	isDesireSpell = True
	isUseSOS = False
	isExtendedNPCNaked = False
    MBonUsesSLGender = True
	notificationKey = 49
	cellScanFreq = 30
    
    sliderMode = False
    statusNotSplash = False

	InitSlotMaskValues()
    
EndFunction


Event OnConfigOpen()
    
    slaMain = Quest.GetQuest("sla_Main") As slaMainScr
    cellScanFreq = slaMain.updateFrequency
    If(cellScanFreq < 10)
        cellScanFreq = 30
    Endif

    targetActorIndex = 0
    targetActors = new Actor[1]
    targetActorNames = new String[1]
    targetActors[0] = player
    targetActorNames[0] = "PLAYER"
    
    
    puppetActorIndex = 0
    puppetActors = new Actor[1]
    puppetActorNames = new String[1]
    puppetActors[0] = player
    puppetActorNames[0] = "PLAYER"
    puppetActor = player
    
    If follower
        Actor followerActor = follower.GetReference() As Actor
        If followerActor
            String followerName = followerActor.GetLeveledActorBase().GetName()
            
            targetActors = PapyrusUtil.PushActor(targetActors, followerActor)
            targetActorNames = PapyrusUtil.PushString(targetActorNames, followerName)
            puppetActors = PapyrusUtil.PushActor(puppetActors, followerActor)
            puppetActorNames = PapyrusUtil.PushString(puppetActorNames, followerName)
        EndIf
    EndIf
    
    If slaPuppetActor && slaPuppetActor != player
        String puppetName = slaPuppetActor.GetLeveledActorBase().GetName()
        targetActors = PapyrusUtil.PushActor(targetActors, slaPuppetActor)
        targetActorNames = PapyrusUtil.PushString(targetActorNames, "PUPPET: " + puppetName)
        puppetActors = PapyrusUtil.PushActor(puppetActors, slaPuppetActor)
        puppetActorNames = PapyrusUtil.PushString(puppetActorNames, puppetName)
        puppetActor = slaPuppetActor
    EndIf
    
    If slaMostArousedActorInLocation && targetActors.Find(slaMostArousedActorInLocation) < 0
        String arousedName = slaMostArousedActorInLocation.GetLeveledActorBase().GetName()
        targetActors = PapyrusUtil.PushActor(targetActors, slaMostArousedActorInLocation)
        targetActorNames = PapyrusUtil.PushString(targetActorNames, "AROUSED: " + arousedName)
        puppetActors = PapyrusUtil.PushActor(puppetActors, slaMostArousedActorInLocation)
        puppetActorNames = PapyrusUtil.PushString(puppetActorNames, arousedName)
    EndIf

    ; Add follower if present
    ; TODO
    
    
    ; Add other SLA aliases
    ; TODO
    
    
    GetBikiniArmorsForTargetActor(targetActors[targetActorIndex])

EndEvent


Event OnConfigClose()

    slax.Info("SLOANG - OnConfigClose - update spells and key registry")
    
	slaMain.UpdateDesireSpell()
	slaMain.UpdateKeyRegistery()

    slaMain.updateFrequency = cellScanFreq
	slaMain.setUpdateFrequency(cellScanFreq)
    
    StorageUtil.ClearObjIntValuePrefix(none, "SLAroused.MCM.OID.")

EndEvent


Event OnPageReset(String page)
    
    StorageUtil.ClearObjIntValuePrefix(none, "SLAroused.MCM.OID.")

    pageName = page
	; Load custom logo in DDS format
	If page == "" && !statusNotSplash
       
        Int xOffset = 376 - (400 / 2)
		LoadCustomContent("sexlabaroused.dds", xOffset, 0)
		Return
        
	Else
		UnloadCustomContent()
	EndIf
	
	If "$SLA_Settings" == page
        pageId = 0 ; Main
        
		SetCursorFillMode(TOP_TO_BOTTOM)

		AddTextOption("$SLA_Version" , "" + GetVersionString() + "(" + slaUtil.GetVersion() + ")", OPTION_FLAG_DISABLED)
        
		AddHeaderOption("$SLA_General")
        
		notificationKeyOID = AddKeyMapOption("$SLA_StatusKey", notificationKey)
		desireSpellOID = AddToggleOption("$SLA_EnableDesire", isDesireSpell)
		wantsPurgingOID = AddToggleOption("$SLA_WantsPurging", wantsPurging)
		maleAnimationOID = AddToggleOption("$SLA_EnableMaleAnimation", maleAnimation)
		femaleAnimationOID = AddToggleOption("$SLA_EnableFemaleAnimation", femaleAnimation)
		useLOSOID = AddToggleOption("$SLA_UseLOS", useLOS)
        nakedOnlyOID = AddToggleOption("$SLA_IsNakedOnly", isNakedOnly)
        enableNotificationsOID = AddToggleOption("$SLA_EnableNotifications", enableNotifications)
		bDisabledOID = AddToggleOption("$SLA_Disabled", bDisabled)
		extendedNPCNakedOID = AddToggleOption("$SLA_ExtendedNPCNaked", isExtendedNPCNaked)
		useSOSOID = AddToggleOption("$SLA_EnableSOS", isUseSOS)
        statusNotSplashOID = AddToggleOption("$SLA_StatusNotSplash", statusNotSplash)
		
		SetCursorPosition(3) ; Move cursor to top right position (almost)
        AddHeaderOption("$SLA_ExportImport")
        
		importSettingsOID = AddTextOption("$SLA_Import", "")
        exportSettingsOID = AddTextOption("$SLA_Export", "")

		AddHeaderOption("$SLA_Arousal")
        
        if(slaMain.sexlabplugin.IsInterfaceActive())
            MBonUsesSLGenderOID = AddToggleOption("$SLA_MBonUsesSLGender", MBonUsesSLGender)
        endif
        
        cellScanFreqOID = AddSliderOption("$SLA_CellScanFreq", cellScanFreq, "{0}")
        smallUpdateOID = AddSliderOption("$SLA_SmallUpdateCount", smallUpdatesPerFull, "{0}")
        
		clearActorDataOID = AddTextOption("Clear selected actor", "")
		clearAllDataOID = AddTextOption("Clear all data", "")
        
        AddHeaderOption("$SLA_PluginList")
        
        int i = slax.CountNonNullElements(slaMain.plugins)
        slax.Info("SLOANG - OnPageReset - pluginCount:" + i)
        while i > 0
            i -= 1
            sla_PluginBase plugin = slaMain.plugins[i]
            int oid = AddToggleOption(plugin.name, plugin.isEnabled, OPTION_FLAG_DISABLED)
            StorageUtil.SetIntValue(self, "SLAroused.MCM.OID." + oid, i)
        endWhile
        
	ElseIf "$SLA_Status" == page || (statusNotSplash && "" == page)
        pageId = 1 ; Status
        DisplayStatus()
		
	ElseIf "$SLA_PuppetMaster" == page
        pageId = 2 ; Puppet Master
		DisplayPuppetMaster()

	ElseIf "$SLA_CurrentArmorList" == page
        pageId = 3
        DisplayArmorList()
        
    ElseIf "$SLA_EffectSetting" == page
        pageId = 4
        
        string filterLabel = filterMode
        if filterMode == ""
            filterLabel = "$SLA_FilterShowAll"
        endIf

        filterModes = new string[1]
        filterModes[0] = "$SLA_FilterShowAll"

        filterOID = AddMenuOption("$SLA_PluginFilter", filterLabel)
        int optionCount = StorageUtil.StringListCount(slaMain, "SLAroused.MCM.Options")
        while optionCount > 0
            optionCount -= 1
            string prefix = StorageUtil.StringListGet(slaMain, "SLAroused.MCM.Options", optionCount)
            Form pluginForm = StorageUtil.GetFormValue(slaMain, prefix + ".Owner")
            sla_PluginBase plugin = (pluginForm as sla_PluginBase)
            int optionId = StorageUtil.GetIntValue(slaMain, prefix + ".OptionId")
            if (plugin != none)
                AddOptionHelper(plugin, optionId)
            endIf
        endWhile
	EndIf

EndEvent

function AddOptionHelper(sla_PluginBase plugin, int option)
    string prefix =  "SLAroused.MCM." + plugin.name + "." + option
    if (plugin != StorageUtil.GetFormValue(slaMain, prefix + ".Owner") as sla_PluginBase)
        return
    endIf
    string category = StorageUtil.GetStringValue(slaMain, prefix + ".Category")
    if filterModes.Find(category) < 0
        filterModes = PapyrusUtil.PushString(filterModes, category)
    endIf
    if filterMode != "" && category != filterMode
        return
    endIf
	string title = StorageUtil.GetStringValue(slaMain, prefix + ".Title")
    string description = StorageUtil.GetStringValue(slaMain, prefix + ".Description")
    string optionType = StorageUtil.GetStringValue(slaMain, prefix + ".Type")
    string format = StorageUtil.GetStringValue(slaMain, prefix + ".Format", "{0}")
    int oid
    ; Debug.Trace("SLOANG - Option Type = " + optionType, 2)
    if optionType == "toggle"
        oid = AddToggleOption(title, plugin.GetOptionValue(option) != 0.0)
    else
        oid = AddSliderOption(title, plugin.GetOptionValue(option), format)
    endIf
    StorageUtil.SetStringValue(self, "SLAroused.MCM.OID." + oid, prefix)
    StorageUtil.SetIntValue(self, "SLAroused.MCM.OID." + oid, option)
endFunction

; If this returns None, there is no secondary target.
Actor Function GetSecondaryTargetActor()

    If puppetActor && puppetActor != player
        Return puppetActor
    EndIf
    
    If slaMostArousedActorInLocation
        Return slaMostArousedActorInLocation
    EndIf
    
    Return player

EndFunction


Function DisplayStatus()

    SetCursorFillMode(TOP_TO_BOTTOM)
    
    AddTextOption("$SLA_PlayerStatus", "", OPTION_FLAG_DISABLED)
    DisplayActorStatus(player)
    
    SetCursorPosition(1) ; Move cursor to top right position
    Actor secondaryTarget = GetSecondaryTargetActor()
    
    If secondaryTarget && secondaryTarget != player
        ; TODO - replace this with a drop-down to select status target
        AddTextOption("$SLA_NpcStatus", "", OPTION_FLAG_DISABLED)
        DisplayActorStatus(secondaryTarget)
    EndIf

EndFunction

Int OID_TotalArousal

Function DisplayActorStatus(Actor who, bool editable = false)
	AddHeaderOption(who.GetLeveledActorBase().GetName())
	
	OID_TotalArousal = AddTextOption("$SLA_ArousalLevel", slaUtil.GetActorArousal(who), OPTION_FLAG_DISABLED)
	
	int i = slaMain.GetEffectCount()
	while i > 0
        i -= 1
        string title = slaMain.GetEffectTitle(i)
        ;Debug.Trace("SLOANG: Static Effect = " + title)
        if slaMain.IsEffectVisible(i)
            if (title == "")
                AddTextOption("$SLA_UnusedEffect", "-", OPTION_FLAG_DISABLED)
            else
                int oid
                
                if editable && title != "$SLA_Effect_Timed"
                    oid = AddInputOption(title, slaMain.GetEffectValue(who, i))
                else
                    oid = AddTextOption(title, slaMain.GetEffectValue(who, i))
                endIf

                StorageUtil.SetIntValue(self, "SLAroused.MCM.OID." + oid, i)
            endIf
        endIf
    endWhile
    
	i = slaMain.GetDynamicEffectCount(who)
	while i > 0
        i -= 1
        string effect = slaMain.GetDynamicEffect(who, i)
        string name = StorageUtil.GetStringValue(slaMain, "SLAroused.DynamicEffect." + effect + ".Title", effect)
        Debug.Trace("SLOANG: Dynamic Effect = " + name)
        string description = StorageUtil.GetStringValue(slaMain, "SLAroused.DynamicEffect." + effect + ".Description")
        float value = slaMain.GetDynamicEffectValue(who, i)
        int oid = AddTextOption(name, value)
        StorageUtil.SetStringValue(self, "SLAroused.MCM.OID." + oid, description)
	endWhile
	
    if(slaMain.sexlabplugin.IsInterfaceActive())
        Int genderPreference = slaUtil.GetGenderPreference(who)
	    AddTextOption("$SLA_GenderPreference", GenderPreferenceList[genderPreference], OPTION_FLAG_DISABLED)
    endif
EndFunction


Function DisplayPuppetMaster()

	SetCursorFillMode(TOP_TO_BOTTOM)
    
    If puppetActor
    
        AddEmptyOption()
        AddHeaderOption(puppetActor.GetLeveledActorBase().GetName())

        Bool blockArousal = slaUtil.IsActorArousalBlocked(puppetActor)
        blockArousalOID = AddToggleOption("$SLA_ArousalBlocked", BlockArousal)
        
        Bool lockArousal = slaUtil.IsActorArousalLocked(puppetActor)
        lockArousalOID = AddToggleOption("$SLA_ArousalLocked", LockArousal)

        Int genderPreference = slaUtil.GetGenderPreference(puppetActor, True)
        genderPreferenceOID = AddMenuOption("$SLA_GenderPreference", GenderPreferenceList[genderPreference])

        Bool isExbitionist = slaUtil.IsActorExhibitionist(puppetActor)
        exbitionistOID = AddToggleOption("$SLA_IsExhibitionist", IsExbitionist)	
        
    EndIf
    
    ; Move to top right
    SetCursorPosition(1)
    
    puppetActorMenuOID = AddMenuOption("$SLA_SelectPuppet", puppetActorNames[puppetActorIndex])

    If puppetActor
    
        DisplayActorStatus(puppetActor, true)
        
    EndIf
    
EndFunction


Function DisplayArmorList()

        SetCursorFillMode(LEFT_TO_RIGHT)
        sliderModeOID = AddToggleOption("$SLA_EnableDetails", sliderMode)

        targetActorMenuOID = AddMenuOption("$SLA_SelectActor", targetActorNames[targetActorIndex])
        
        AddHeaderOption("$SLA_EquippedItems")
        AddHeaderOption("$SLA_Options")
		
		DisplayWornItems(targetActors[targetActorIndex])

EndFunction


Function DisplayWornItems(Actor who)

    UpdateWornItemStates(who) ; we only care about body and shoes.

    If bodyItem
        bodyItemOID = AddTextOption("$SLA_BodyItem", bodyItem.GetName())
        If sliderMode
            AddSlidersForBodyItem()
        Else
            AddTogglesForBodyItem()
        EndIf
        AddEmptyOption()
        AddEmptyOption()
    Else
        noBodyItemOID = AddTextOption("", "$SLA_NoBodyItem")
        AddEmptyOption()
        AddEmptyOption()
        AddEmptyOption()
    EndIf
    
    If footItem
        footItemOID = AddTextOption("$SLA_ShoesBoots", footItem.GetName())
        If sliderMode
            heelsSliderOID = AddSliderOption("$SLA_HighHeels", killerHeelsValue)
        Else
            heelsToggleOID = AddToggleOption("$SLA_HighHeels", killerHeelsValue > 0)
        EndIf
    Else
        noFootItemOID = AddTextOption("", "$SLA_NoShoesBoots")
        AddEmptyOption()
    EndIf
    
    If bikiniArmors.Length > 0
    
        AddHeaderOption("Items in bikini slots")
        AddHeaderOption("")
    
        Int ii = 0
        Int count = bikiniArmors.Length
        While ii < count
        
            Armor bikini = bikiniArmors[ii] As Armor
            AddTextOption(slaInternalModules.FormatHex(bikini.GetFormId()), bikini.GetName())
            
            Int value = bikiniSliderValues[ii]
            If sliderMode
                bikiniSliderOIDs[ii] = AddSliderOption("$SLA_Bikini", value)
            Else
                bikiniToggleOIDs[ii] = AddToggleOption("$SLA_Bikini", value > 0)
            EndIf
            ii += 1
            
        EndWhile

    EndIf

EndFunction


Function UpdateWornItemStates(Actor who)

    bodyItem = who.GetWornForm(slaSlotMaskValues[2]) As Armor ; 32 - 30
    If bodyItem
        nakedArmorValue   = StorageUtil.GetIntValue(bodyItem, keyNakedArmor)
        bikiniArmorValue  = StorageUtil.GetIntValue(bodyItem, keyBikiniArmor)
        sexyArmorValue    = StorageUtil.GetIntValue(bodyItem, keySexyArmor)
        slootyArmorValue  = StorageUtil.GetIntValue(bodyItem, keySlootyArmor)
        illegalArmorValue = StorageUtil.GetIntValue(bodyItem, keyIllegalArmor)
        raggedArmorValue  = StorageUtil.GetIntValue(bodyItem, keyRaggedArmor)
    EndIf

    footItem  = who.GetWornForm(slaSlotMaskValues[7]) As Armor ; 37 - 30
    If footItem
        killerHeelsValue = StorageUtil.GetIntValue(footItem, keyKillerHeels)
    EndIf
    
    GetBikiniArmorsForTargetActor(who)
    
EndFunction


Function GetBikiniArmorsForTargetActor(Actor who)

    bikiniArmors = emptyFormArray
    
    ; 44, 45 - depravity armors, 48 TAWoBA, 49 SLS, 52 TAWoBA, 56 SLS, 58 harness
    Armor[] candidates = new Armor[7]
    candidates[0] = who.GetWornForm(slaSlotMaskValues[14]) As Armor ; 44
    candidates[1] = who.GetWornForm(slaSlotMaskValues[15]) As Armor ; 45
    candidates[2] = who.GetWornForm(slaSlotMaskValues[18]) As Armor ; 48
    candidates[3] = who.GetWornForm(slaSlotMaskValues[19]) As Armor ; 49
    candidates[4] = who.GetWornForm(slaSlotMaskValues[22]) As Armor ; 52
    candidates[5] = who.GetWornForm(slaSlotMaskValues[26]) As Armor ; 56
    candidates[6] = who.GetWornForm(slaSlotMaskValues[28]) As Armor ; 58
    
    Int ii = 0
    While ii < 7
        Armor item = candidates[ii]
        If item && item != bodyItem && bikiniArmors.Find(item) < 0 && item.GetName() ; don't re-add duplicates, or body slot items, but can re-add boots
            If item.HasKeywordString("ArmorClothes") || item.HasKeywordString("ArmorLight") || item.HasKeywordString("ArmorHeavy") ; exclude schlongs etc.
                bikiniArmors = PapyrusUtil.PushForm(bikiniArmors, item)
            EndIf
        EndIf
        ii += 1
    EndWhile
    
    bikiniSliderOIDs = Utility.CreateIntArray(bikiniArmors.Length)
    bikiniToggleOIDs = Utility.CreateIntArray(bikiniArmors.Length)
    bikiniSliderValues = Utility.CreateIntArray(bikiniArmors.Length)
    
    ii = bikiniArmors.Length
    Debug.Trace("SLOANG: Got " + ii + " bikini items ")
    While ii
        ii -= 1
        bikiniSliderValues[ii] = StorageUtil.GetIntValue(bikiniArmors[ii], keyBikiniArmor)
    EndWhile


EndFunction


Function AddSlidersForBodyItem()
        nakedSliderOID   = AddSliderOption("$SLA_Naked", nakedArmorValue)
        AddEmptyOption()
        bikiniSliderOID  = AddSliderOption("$SLA_Bikini", bikiniArmorValue)
        AddEmptyOption()
        sexySliderOID    = AddSliderOption("$SLA_Sexy", sexyArmorValue)
        AddEmptyOption()
        slootySliderOID  = AddSliderOption("$SLA_Slooty", slootyArmorValue)
        AddEmptyOption()
        illegalSliderOID = AddSliderOption("$SLA_Illegal", illegalArmorValue)
        AddEmptyOption()
        poshSliderOID    = AddSliderOption("$SLA_Posh", poshArmorValue)
        AddEmptyOption()
        raggedSliderOID  = AddSliderOption("$SLA_Ragged", raggedArmorValue)
EndFunction


Function AddTogglesForBodyItem()
        nakedToggleOID   = AddToggleOption("$SLA_Naked", nakedArmorValue > 0)
        AddEmptyOption()
        bikiniToggleOID  = AddToggleOption("$SLA_Bikini", bikiniArmorValue > 0)
        AddEmptyOption()
        sexyToggleOID    = AddToggleOption("$SLA_Sexy", sexyArmorValue > 0)
        AddEmptyOption()
        slootyToggleOID  = AddToggleOption("$SLA_Slooty", slootyArmorValue > 0)
        AddEmptyOption()
        illegalToggleOID = AddToggleOption("$SLA_Illegal", illegalArmorValue > 0)
        AddEmptyOption()
        poshToggleOID    = AddToggleOption("$SLA_Posh", poshArmorValue > 0)
        AddEmptyOption()
        raggedToggleOID  = AddToggleOption("$SLA_Ragged", raggedArmorValue > 0)
EndFunction


Event OnOptionMenuOpen(int option)

    If 2 == pageId ; PuppetMaster
    
        If option == puppetActorMenuOID

            SetMenuDialogOptions(puppetActorNames)
            SetMenuDialogStartIndex(puppetActorIndex)
            SetMenuDialogDefaultIndex(0)

        ElseIf option == genderPreferenceOID
            Int genderPreference = slaUtil.GetGenderPreference(puppetActor, True)
            SetMenuDialogOptions(genderPreferenceList)
            SetMenuDialogStartIndex(genderPreference)
            SetMenuDialogDefaultIndex(1) ; Female
            
        EndIf
    
    ElseIf 3 == pageId ; Armor
    
        If option == targetActorMenuOID
            
            SetMenuDialogOptions(targetActorNames)
            SetMenuDialogStartIndex(targetActorIndex)
            SetMenuDialogDefaultIndex(0)
            
        EndIf
    
    ElseIf 4 == pageId ; Plugins

        if option == filterOID
            SetMenuDialogOptions(filterModes)
            int startIdx = filterModes.Find(filterMode)
            if startIdx < 0
                startIdx = 0
            endIf
            SetMenuDialogStartIndex(startIdx)
            SetMenuDialogDefaultIndex(0)
        endIf

    EndIf
    
EndEvent


Event OnOptionMenuAccept(int option, int index)

    If 2 == pageId ; PuppetMaster
    
        If option == puppetActorMenuOID
            puppetActorIndex = index
            puppetActor = puppetActors[index]
            ForcePageReset()
            
        ElseIf option == genderPreferenceOID
            slaUtil.SetGenderPreference(puppetActor, index)
            SetMenuOptionValue(option, genderPreferenceList[index])
            
        EndIf
        
    ElseIf 3 == pageId ; Armor
    
        If option == targetActorMenuOID
        
            targetActorIndex = index
            UpdateWornItemStates(targetActors[index])
            ForcePageReset()
        
        EndIf
    
    ElseIf 4 == pageId ; Plugins

        if option == filterOID
            if index == 0
                filterMode = ""
            else
                filterMode = filterModes[index]
            endIf
            ForcePageReset()
        endIf

    EndIf
    
EndEvent

Event OnOptionInputOpen(int option) 
    int i = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option, -1)
    
    if i >= 0
        float initialValue = slaMain.GetEffectValue(puppetActor, i)
        SetInputDialogStartText(initialValue)
    endIf
EndEvent

Event OnOptionInputAccept(int option, string value)
    int i = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option, -1)
    
    if i >= 0
        float numeric = value as float
        Debug.Trace("SLOANG: New static arousal value" + value + " numeric = " + numeric)
        if numeric != 0.0 || value == "0" || value == "0.0"
            slaInternalModules.SetStaticArousalValue(puppetActor, i, numeric)
            Debug.Trace("SLOANG: Setting static arousal value" + slaMain.GetEffectValue(puppetActor, i))
            SetInputOptionValue(option, slaMain.GetEffectValue(puppetActor, i))
            setTextOptionValue(OID_TotalArousal, slaUtil.GetActorArousal(puppetActor))
        endIf
    endIf
EndEvent


Event OnOptionSelect(int option)

    If 0 == pageId ; Main
	
        If option == desireSpellOID
            IsDesireSpell = !IsDesireSpell
            SetToggleOptionValue(option, IsDesireSpell)
            
        ElseIf (option == wantsPurgingOID)
            wantsPurging = !wantsPurging
            SetToggleOptionValue(option, wantsPurging)
            If wantsPurging
                slaMain = Quest.GetQuest("sla_Main") As slaMainScr
                slaMain.startCleaning()
            EndIf

        ElseIf option == maleAnimationOID
            maleAnimation = !maleAnimation
            SetToggleOptionValue(option, maleAnimation)
            slaMain.SetIsAnimatingMales(maleAnimation As Int)

        ElseIf (option == femaleAnimationOID)
            femaleAnimation = !femaleAnimation
            SetToggleOptionValue(option, femaleAnimation)
            slaMain.SetIsAnimatingFemales(femaleAnimation As Int)
            
        ElseIf option == useLOSOID
            useLOS = !useLOS
            SetToggleOptionValue(useLOSOID, useLOS)
            slaMain.SetUseLOS(useLOS As Int)

        ElseIf option == nakedOnlyOID
            isNakedOnly = !isNakedOnly
            SetToggleOptionValue(option, IsNakedOnly)
            slaMain.SetNakedOnly(isNakedOnly As Int)

        ElseIf option == enableNotificationsOID
            enableNotifications = !enableNotifications
            SetToggleOptionValue(option, enableNotifications)

        ElseIf option == bDisabledOID
            bDisabled = !bDisabled
            SetToggleOptionValue(option, bDisabled)
            slaMain.SetDisabled(bDisabled As Int)

        ElseIf option == extendedNPCNakedOID
            isExtendedNPCNaked = !isExtendedNPCNaked
            SetToggleOptionValue(option, isExtendedNPCNaked)
            
        ElseIf option == useSOSOID
            isUseSOS = !isUseSOS
            SetToggleOptionValue(option, IsUseSOS)
            
        ElseIf option == statusNotSplashOID
            statusNotSplash = !statusNotSplash
            SetToggleOptionValue(option, statusNotSplash)
        
        ElseIf option == importSettingsOID
            ImportSettings()

        ElseIf option == exportSettingsOID
            ExportSettings()

        ElseIf option == clearActorDataOID
            ClearActorData()

        ElseIf option == clearAllDataOID
            ClearAllData()

        Else
            int pluginId = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option, -1)
            if pluginId != -1
                sla_PluginBase plugin = slaMain.plugins[pluginId]
                if (plugin.isEnabled)
                    plugin.DisablePlugin()
                    plugin.ClearOptions()
                    plugin.isEnabled = false
                    SetToggleOptionValue(option, false)
                else
                    plugin.EnablePlugin()
                    plugin.AddOptions()
                    plugin.isEnabled = true
                    SetToggleOptionValue(option, true)
                endIf
            endIf

        EndIf
            
    ElseIf 2 == pageId ; PuppetMaster
		
        If option == blockArousalOID
            Bool blockArousal = !slaUtil.IsActorArousalBlocked(puppetActor)
            SetToggleOptionValue(option, blockArousal)
            slaUtil.SetActorArousalBlocked(puppetActor, blockArousal)
        
        ElseIf option == lockArousalOID
            Bool lockArousal = !slaUtil.IsActorArousalLocked(puppetActor)
            SetToggleOptionValue(option, lockArousal)
            slaUtil.SetActorArousalLocked(puppetActor, lockArousal)
            
        ElseIf option == exbitionistOID
            Bool isExbitionist = !slaUtil.IsActorExhibitionist(puppetActor)
            SetToggleOptionValue(option, isExbitionist)		
            slaUtil.SetActorExhibitionist(puppetActor, isExbitionist)
            
        EndIf
        
    ElseIf 3 == pageId ; Armor

        If option == sliderModeOID
            sliderMode = !sliderMode
            ForcePageReset()
            
        ElseIf option == nakedToggleOID
            nakedArmorValue = ToggleBodyArmorValue(nakedArmorValue, keyNakedArmor)
            SetToggleOptionValue(option, nakedArmorValue > 0)
            UpdateNakedKeywords(bodyItem, nakedArmorValue)
            
        ElseIf option == bikiniToggleOID
            bikiniArmorValue = ToggleBodyArmorValue(bikiniArmorValue, keyBikiniArmor)
            SetToggleOptionValue(option, bikiniArmorValue > 0)
            UpdateBikiniKeywords(bodyItem, bikiniArmorValue)

        ElseIf option == sexyToggleOID
            sexyArmorValue = ToggleBodyArmorValue(sexyArmorValue, keySexyArmor)
            SetToggleOptionValue(option, sexyArmorValue > 0)
            UpdateSexyKeywords(bodyItem, sexyArmorValue)

        ElseIf option == slootyToggleOID
            slootyArmorValue = ToggleBodyArmorValue(slootyArmorValue, keySlootyArmor)
            SetToggleOptionValue(option, slootyArmorValue > 0)
            UpdateSlootyKeywords(bodyItem, slootyArmorValue)

        ElseIf option == illegalToggleOID
            illegalArmorValue = ToggleBodyArmorValue(illegalArmorValue, keyIllegalArmor)
            SetToggleOptionValue(option, illegalArmorValue > 0)
            UpdateIllegalKeywords(bodyItem, illegalArmorValue)

        ElseIf option == poshToggleOID
            poshArmorValue = ToggleBodyArmorValue(poshArmorValue, keyPoshArmor)
            SetToggleOptionValue(option, poshArmorValue > 0)
            UpdatePoshKeywords(bodyItem, poshArmorValue)

        ElseIf option == raggedToggleOID    
            raggedArmorValue = ToggleBodyArmorValue(raggedArmorValue, keyRaggedArmor)
            SetToggleOptionValue(option, raggedArmorValue >0)
            UpdateRaggedKeywords(bodyItem, raggedArmorValue)

        ElseIf option == heelsToggleOID
            If killerHeelsValue > 0
                killerHeelsValue = 0
            Else
                killerHeelsValue = 75
            EndIf
            SetToggleOptionValue(option, killerHeelsValue > 0)
            UpdateHeelsKeywords(footItem, killerHeelsValue)
            
        Else
        
            Int bikiniIndex = bikiniToggleOIDs.Find(option)
            If bikiniIndex >= 0
                Int value = bikiniSliderValues[bikiniIndex]
                If value > 0
                    value = 0
                Else
                    value = 51
                EndIf
                bikiniSliderValues[bikiniIndex] = value
                SetToggleOptionValue(option, value > 0)
                UpdateBikiniKeywords(bikiniArmors[bikiniIndex], value)
            EndIf
            
        EndIf
        
    ElseIf 4 == pageId ; Plugins

        string prefix = StorageUtil.GetStringValue(self, "SLAroused.MCM.OID." + option)
        int pluginOption = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option)
        sla_PluginBase plugin = StorageUtil.GetFormValue(slaMain, prefix + ".Owner") as sla_PluginBase

        bool oldValue = plugin.GetOptionValue(pluginOption) != 0.0
        if oldValue
            plugin.OnUpdateOption(pluginOption, 0.0)
        else
            plugin.OnUpdateOption(pluginOption, 1.0)
        endIf
        SetToggleOptionValue(option, plugin.GetOptionValue(pluginOption) != 0.0)

    EndIf
    
EndEvent


Event OnOptionSliderOpen(int option)		

    If 0 == pageId ; Main
        
        If option == cellScanFreqOID
            SetSliderDialogStartValue(cellScanFreq as Float)
            SetSliderDialogDefaultValue(30.0)
            SetSliderDialogRange(15.0, 300.0)
            SetSliderDialogInterval(5.0)
        ElseIf option == smallUpdateOID
            SetSliderDialogStartValue(smallUpdatesPerFull)
            SetSliderDialogDefaultValue(1)
            SetSliderDialogRange(0, 20)
            SetSliderDialogInterval(1.0)
        EndIf
        
    ElseIf 2 == pageId ; PuppetMaster
        
        
    ElseIf 3 == pageId ; Armor
    
        If option == nakedSliderOID
            SetSliderDialogStartValue(nakedArmorValue)
        ElseIf option == bikiniSliderOID
            SetSliderDialogStartValue(bikiniArmorValue)
        ElseIf option == sexySliderOID
            SetSliderDialogStartValue(sexyArmorValue)
        ElseIf option == slootySliderOID
            SetSliderDialogStartValue(slootyArmorValue)
        ElseIf option == illegalSliderOID
            SetSliderDialogStartValue(illegalArmorValue)
        ElseIf option == poshSliderOID
            SetSliderDialogStartValue(poshArmorValue)
        ElseIf option == raggedSliderOID
            SetSliderDialogStartValue(raggedArmorValue)
        ElseIf option == heelsSliderOID
            SetSliderDialogStartValue(killerHeelsValue)
            
        Else
        
            Int bikiniIndex = bikiniSliderOIDs.Find(option)
            If bikiniIndex >= 0
                Int value = bikiniSliderValues[bikiniIndex]
                SetSliderDialogStartValue(value)
            EndIf
            
        EndIf
        
        SetSliderDialogDefaultValue(0)
        SetSliderDialogRange(0.0, 100.0)
        SetSliderDialogInterval(1.0)

    ElseIf 4 == pageId ; Plugins

        string prefix = StorageUtil.GetStringValue(self, "SLAroused.MCM.OID." + option)
        int pluginOption = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option)
        sla_PluginBase plugin = StorageUtil.GetFormValue(slaMain, prefix + ".Owner") as sla_PluginBase

        SetSliderDialogStartValue(plugin.GetOptionValue(pluginOption))
        SetSliderDialogDefaultValue(StorageUtil.GetFloatValue(slaMain, prefix + ".Default"))
        float min = StorageUtil.GetFloatValue(slaMain, prefix + ".Min", 0.0)
        float max = StorageUtil.GetFloatValue(slaMain, prefix + ".Max", slaUtil.slaArousalCap)
        SetSliderDialogRange(min, max)
        float interval = StorageUtil.GetFloatValue(slaMain, prefix + ".Interval", (max - min) / 100.0)
        SetSliderDialogInterval(interval)

    EndIf
    
EndEvent


Event OnOptionSliderAccept(Int option, Float value)		

    If 0 == pageId ; Main

        If option == cellScanFreqOID
            cellScanFreq = value As Int
            SetSliderOptionValue(option, value, "{0}")
        ElseIf option == smallUpdateOID
            smallUpdatesPerFull = value As Int
            SetSliderOptionValue(option, value, "{0}")
        EndIf

    ElseIf 2 == pageId ; PuppetMaster
        
    ElseIf 3 == pageId ; Armor
    
        If option == nakedSliderOID
            nakedArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keyNakedArmor, nakedArmorValue)
            
        ElseIf option == bikiniSliderOID
            bikiniArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keyBikiniArmor, bikiniArmorValue)
            
        ElseIf option == sexySliderOID
            sexyArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keySexyArmor, sexyArmorValue)
            
        ElseIf option == slootySliderOID
            slootyArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keySlootyArmor, slootyArmorValue)
            
        ElseIf option == illegalSliderOID
            illegalArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keyIllegalArmor, illegalArmorValue)
            
        ElseIf option == poshSliderOID
            poshArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keyPoshArmor, poshArmorValue)
            
        ElseIf option == raggedSliderOID
            raggedArmorValue = value As Int
            StorageUtil.SetIntValue(bodyItem, keyRaggedArmor, raggedArmorValue)
            
        ElseIf option == heelsSliderOID
            killerHeelsValue = value As Int
            StorageUtil.SetIntValue(footItem, keyKillerHeels, killerHeelsValue)
            
        Else
        
            Int bikiniIndex = bikiniSliderOIDs.Find(option)
            If bikiniIndex >= 0
                Int intValue = value As Int
                bikiniSliderValues[bikiniIndex] = intValue
                StorageUtil.SetIntValue(bikiniArmors[bikiniIndex], keyBikiniArmor, intValue)
            EndIf
            
        EndIf

        SetSliderOptionValue(option, value)

    ElseIf 4 == pageId ; Plugins

        string prefix = StorageUtil.GetStringValue(self, "SLAroused.MCM.OID." + option)
        int pluginOption = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option)
        sla_PluginBase plugin = StorageUtil.GetFormValue(slaMain, prefix + ".Owner") as sla_PluginBase
        plugin.OnUpdateOption(pluginOption, value)
        string format = StorageUtil.GetStringValue(slaMain, prefix + ".Format", "{0}")
        SetSliderOptionValue(option, plugin.GetOptionValue(pluginOption), format)
    
    EndIf
    
EndEvent


Event OnOptionKeyMapChange(Int option, Int keyCode, String conflictingItem, String conflictName)

	Bool ok = True

	; Check for conflict
	If "" != conflictingItem
    
		String boxText
		If conflictName == ""
			boxText = "This key is already mapped to:\n'" + conflictingItem + "'\n\nAre you sure you want to continue?"
		Else
			boxText = "This key is already mapped to:\n'" + conflictingItem + "'\n(" + conflictName + ")\n\nAre you sure you want to continue?"
		EndIf
		ok = ShowMessage(boxText, True, "$SLA_Yes", "$SLA_No")
        
	EndIf

	If ok
    
		If option == NotificationKeyOID
			notificationKey = keyCode			
		EndIf

		SetKeymapOptionValue(option, keyCode)
        
	EndIf
    
EndEvent


Event OnOptionHighlight(int option)

    String infoText
    
    If 0 == pageId ; Main
    
        If option == notificationKeyOID
            infoText = "$SLA_InfoStatusKey"
        ElseIf option == DesireSpellOID
            infoText = "$SLA_InfoDesire"
        ElseIf option == wantsPurgingOID
            infoText = "$SLA_WantsPurgingDesc"
        ElseIf option == maleAnimationOID
            infoText = "$SLA_EnableMaleAnimationDesc"
        ElseIf option == femaleAnimationOID
            infoText = "$SLA_EnableFemaleAnimationDesc"
        ElseIf option == useLOSOID
            infoText = "$SLA_UseLOSDesc"
        ElseIf option == nakedOnlyOID
            infoText = "$SLA_IsNakedOnlyDesc"
        ElseIf option == bDisabledOID
            infoText = "$SLA_DisabledDesc"
        ElseIf option == extendedNPCNakedOID
            infoText = "$SLA_InfoExtendedNPCNaked"
        ElseIf option == useSOSOID
            infoText = "$SLA_InfoEnableSOS"
        ElseIf option == cellScanFreqOID
            infoText = "$SLA_InfoCellScanFreq"
        ElseIf option == smallUpdateOID
            infoText = "$SLA_SmallUpdateDesc"
        ElseIf option == statusNotSplashOID
            infoText = "$SLA_StatusNotSplashInfo"
        EndIf
    
    ElseIf 1 == pageId ; Status

        int effId = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option, -1)
        if effId != -1
            infoText = slaUtil.slaMain.GetEffectDescription(effId)
        else
            infoText = StorageUtil.SetStringValue(self, "SLAroused.MCM.OID." + option, "")
        endIf

    ElseIf 2 == pageId ; PuppetMaster
    
        If option == puppetActorMenuOID
            infoText = "$SLA_SelectPuppetInfo"
        ElseIf option == blockArousalOID
            infoText = "$SLA_InfoBlockedArousal"
        ElseIf option == lockArousalOID
            infoText = "$SLA_InfoLockedArousal"
        ElseIf option == exbitionistOID
            infoText = "$SLA_InfoIsExhibitionist"
        ElseIf option == genderPreferenceOID
            infoText = "$SLA_InfoGenderPreference"
        EndIf
        
    ElseIf 3 == pageId ; Armor

        If option == targetActorMenuOID
            InfoText = "$SLA_TargetActorMenuInfo"
        ElseIf option == sliderModeOID
            infoText = "$SLA_SliderModeInfo"
        ElseIf option == bodyItemOID
            infoText = "$SLA_BodyItemInfo"
        ElseIf option == noBodyItemOID
            infoText = "$SLA_NoBodyItemInfo"
        ElseIf option == nakedSliderOID
            infoText = "$SLA_NakedSliderInfo"
        ElseIf option == bikiniSliderOID
            infoText = "$SLA_BikiniSliderInfo"
        ElseIf option == sexySliderOID
            infoText = "$SLA_SexySliderInfo"
        ElseIf option == slootySliderOID
            infoText = "$SLA_SlootySliderInfo"
        ElseIf option == illegalSliderOID
            infoText = "$SLA_IllegalSliderInfo"
        ElseIf option == poshSliderOID
            infoText = "$SLA_PoshSliderInfo"
        ElseIf option == raggedSliderOID
            infoText = "$SLA_RaggedSliderInfo"

        ElseIf option == nakedToggleOID
            infoText = "$SLA_NakedToggleInfo"
        ElseIf option == bikiniToggleOID
            infoText = "$SLA_BikiniToggleInfo"
        ElseIf option == sexyToggleOID
            infoText = "$SLA_SexyToggleInfo"
        ElseIf option == slootyToggleOID
            infoText = "$SLA_SlootyToggleInfo"
        ElseIf option == illegalToggleOID
            infoText = "$SLA_IllegalToggleInfo"
        ElseIf option == poshToggleOID
            infoText = "$SLA_PoshToggleInfo"
        ElseIf option == raggedToggleOID
            infoText = "$SLA_RaggedToggleInfo"

        ElseIf option == footItemOID
            infoText = "$SLA_FootItemInfo"
        ElseIf option == noFootItemOID
            infoText = "$SLA_NoFootItemInfo"
        ElseIf option == heelsSliderOID
            infoText = "$SLA_HeelsSliderInfo"
        ElseIf option == heelsToggleOID
            infoText = "$SLA_HeelsToggleInfo"
        EndIf
        
    ElseIf 4 == pageId ; Plugins

        string prefix = StorageUtil.GetStringValue(self, "SLAroused.MCM.OID." + option)
        infoText = StorageUtil.GetStringValue(slaMain, prefix + ".Description")
    
    EndIf
    
    SetInfoText(infoText)
     
EndEvent


Event OnOptionDefault(int option)

    If 0 == pageId ; Main
    
        If (option == NotificationKeyOID)
            notificationKey = 49 ; default value
            SetKeymapOptionValue(option, notificationKey)
            
        ElseIf (option == DesireSpellOID)
            IsDesireSpell = True
            SetToggleOptionValue(desireSpellOID, isDesireSpell)
            
        ElseIf (option == wantsPurgingOID)
            wantsPurging = False
            SetToggleOptionValue(wantsPurgingOID, wantsPurging)
            
        ElseIf (option == maleAnimationOID)
            maleAnimation = False
            SetToggleOptionValue(maleAnimationOID, maleAnimation)
            slaMain.SetIsAnimatingMales(maleAnimation As Int)
            
        ElseIf (option == femaleAnimationOID)
            femaleAnimation = False
            SetToggleOptionValue(femaleAnimationOID, femaleAnimation)
            slaMain.SetIsAnimatingFemales(femaleAnimation As Int)
            
        ElseIf (option == useLOSOID)
            useLOS = True
            SetToggleOptionValue(useLOSOID, useLOS)
            slaMain.setUseLOS(useLOS as Int)
            
        ElseIf (option == nakedOnlyOID)
            isNakedOnly = false
            SetToggleOptionValue(nakedOnlyOID, isNakedOnly)
            slaMain.setNakedOnly(isNakedOnly as Int)
            
        ElseIf (option == enableNotificationsOID)
            enableNotifications = true
            SetToggleOptionValue(enableNotificationsOID, enableNotifications)

        ElseIf (option == bDisabledOID)
            bDisabled = False
            SetToggleOptionValue(bDisabledOID, bDisabled)
            slaMain.setDisabled(bDisabled as Int)
            
        ElseIf (option == extendedNPCNakedOID)
            isExtendedNPCNaked = False
            SetToggleOptionValue(extendedNPCNakedOID, isExtendedNPCNaked)
            
        ElseIf (option == useSOSOID)
            isUseSOS = False
            SetToggleOptionValue(useSOSOID, isUseSOS)
            
        ElseIf (option == MBonUsesSLGenderOID)
            MBonUsesSLGender = True
            SetToggleOptionValue(MBonUsesSLGenderOID, MBonUsesSLGender)
            
        ElseIf (option == cellScanFreqOID)
            cellScanFreq = 30.0
            SetSliderOptionValue(cellScanFreqOID, cellScanFreq, "{1}")
        
        ElseIf (option == smallUpdateOID)

            smallUpdatesPerFull = 1
            SetSliderOptionValue(smallUpdateOID, smallUpdatesPerFull, "{0}")

        EndIf
    
    ElseIf 2 == pageId ; PuppetMaster
						
        If (option == blockArousalOID)
            Bool blockArousal = False
            SetToggleOptionValue(blockArousalOID, blockArousal)
            slaUtil.SetActorArousalBlocked(puppetActor, blockArousal)
            
        ElseIf (option == lockArousalOID)
            Bool lockArousal = False
            SetToggleOptionValue(lockArousalOID, lockArousal)
            slaUtil.SetActorArousalLocked(puppetActor, lockArousal)
            
        ElseIf (option == ExbitionistOID)
            Bool IsExbitionist = False
            slaUtil.SetActorExhibitionist(puppetActor, isExbitionist)
            SetToggleOptionValue(exbitionistOID, isExbitionist)

        ElseIf (option == genderPreferenceOID)
            slaUtil.SetGenderPreference(puppetActor, -2)
            Int genderPreference = slaUtil.GetGenderPreference(puppetActor, True)
            SetMenuOptionValue(genderPreferenceOID, genderPreferenceList[genderPreference])
        EndIf
		

    ElseIf 4 == pageId ; Plugins

        string prefix = StorageUtil.GetStringValue(self, "SLAroused.MCM.OID." + option)
        int pluginOption = StorageUtil.GetIntValue(self, "SLAroused.MCM.OID." + option)
        sla_PluginBase plugin = StorageUtil.GetFormValue(slaMain, prefix + ".Owner") as sla_PluginBase
        float defaultValue = StorageUtil.GetFloatValue(slaMain, prefix + ".Default")
        plugin.OnUpdateOption(pluginOption, defaultValue)
    
    EndIf
    
EndEvent


Function UpdateNakedKeywords(Armor item, Int value)
    Debug.Trace("BEFORE AddNakedKeywords - value " + value + " : keyword present " + item.HasKeyword(wordNakedArmor))
    UpdateWearableState(item, keyNakedArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordNakedArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordNakedArmor)
    EndIf
    Debug.Trace("AFTER AddNakedKeywords - value " + value + " : keyword present " + item.HasKeyword(wordNakedArmor))
EndFunction

Function UpdateBikiniKeywords(Form item, Int value)
    Debug.Trace("BEFORE AddBikiniKeywords - value " + value + " : keyword present " + item.HasKeyword(wordBikiniArmor))
    UpdateWearableState(item, keyBikiniArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordBikiniArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordBikiniArmor)
    EndIf
    Debug.Trace("AFTER AddBikiniKeywords - value " + value + " : keyword present " + item.HasKeyword(wordBikiniArmor))
EndFunction

Function UpdateSexyKeywords(Armor item, Int value)
    Debug.Trace("BEFORE AddSexyKeywords - value " + value + " : keyword present " + item.HasKeyword(wordSexyArmor))
    UpdateWearableState(item, keySexyArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordSexyArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordSexyArmor)
    EndIf
    Debug.Trace("AFTER AddSexyKeywords - value " + value + " : keyword present " + item.HasKeyword(wordSexyArmor))
EndFunction

Function UpdateSlootyKeywords(Armor item, Int value)
    UpdateWearableState(item, keySlootyArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordSlootyArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordSlootyArmor)
    EndIf
EndFunction

Function UpdateIllegalKeywords(Armor item, Int value)
    UpdateWearableState(item, keyIllegalArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordIllegalArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordIllegalArmor)
    EndIf
EndFunction

Function UpdatePoshKeywords(Armor item, Int value)
    UpdateWearableState(item, keyPoshArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordPoshArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordPoshArmor)
    EndIf
EndFunction

Function UpdateRaggedKeywords(Armor item, Int value)
    UpdateWearableState(item, keyRaggedArmor, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordRaggedArmor)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordRaggedArmor)
    EndIf
EndFunction

Function UpdateHeelsKeywords(Armor item, Int value)
    UpdateWearableState(item, keyKillerHeels, value)
    If value > 0
        KeywordUtil.AddKeywordToForm(item, wordKillerHeels)
    Else
        KeywordUtil.RemoveKeywordFromForm(item, wordKillerHeels)
    EndIf
EndFunction


Function UpdateWearableState(Form item, String keyValue, Int stateValue)

    If !item
        Return
    EndIf

    StorageUtil.SetIntValue(item, keyValue, stateValue)
    
    If stateValue > 0
        StorageUtil.FormListAdd(player, keyValue, item, False) ; no duplicates
        StorageUtil.FormListRemove(player, keyValue+"No", item, True) ; all instances
    Else
        StorageUtil.FormListAdd(player, keyValue+"No", item, False) ; no duplicates
        StorageUtil.FormListRemove(player, keyValue, item, True) ; all instances
    EndIf
    
EndFunction


Function RestoreKeywords(String keyValue, Keyword wordValue)

    Form[] addItems = StorageUtil.FormListToArray(player, keyValue)
    Form[] removeItems = StorageUtil.FormListToArray(player, keyValue+"No")
    
    If addItems
        KeywordUtil.AddKeywordToForms(addItems, wordValue)
    EndIf

    If removeItems
        KeywordUtil.RemoveKeywordFromForms(removeItems, wordValue)
    EndIf
    
EndFunction


Int Function ToggleBodyArmorValue(Int value, String keyTag)

    If value > 0
        value = 0
    Else
        value = 51
    EndIf
    StorageUtil.SetIntValue(bodyItem, keyTag, value)
    Return value
    
EndFunction


; Get a list of Armor items worn by the target actor - deprecated
; This is extremely SLOW due to all the GetWornForm calls.
; Retained only in case somebody is referencing it - it's not used here.
Form[] Function GetEquippedArmors(Actor who)

	Form[] armorList

	If !who
		Return armorList
	EndIf
	
    Int itemCount = slaSlotMaskValues.Length
	Int slot = 0
	While slot < itemCount
    
		Form slotForm = who.GetWornForm(slaSlotMaskValues[slot])
		
		If slotForm
            If armorList.Find(slotForm) < 0
                armorList = PapyrusUtil.PushForm(armorList, slotForm)
            EndIf
		EndIf
		
		slot += 1
        
	EndWhile
	
	Return armorList
    
EndFunction


Function InitSlotMaskValues()

	slaSlotMaskValues = new int[31]
    
	Int slotValue = 1
    
	Int ii = 0
	While ii < 31
		slaSlotMaskValues[ii] = slotValue
		slotValue *= 2
		ii += 1
	EndWhile
    
EndFunction


Function ResetPageNames()

	Pages = new String[5]
	Pages[0] = "$SLA_Settings"
	Pages[1] = "$SLA_EffectSetting"
	Pages[2] = "$SLA_Status"
	Pages[3] = "$SLA_PuppetMaster"
	Pages[4] = "$SLA_CurrentArmorList"

EndFunction


Function ResetKeys()

    keyNakedArmor = "SLAroused.IsNakedArmor"
    keyBikiniArmor = "SLAroused.IsBikiniArmor"
    keySexyArmor = "SLAroused.IsSexyArmor"
    keySlootyArmor = "SLAroused.IsSlootyArmor"
    keyIllegalArmor = "SLAroused.IsIllegalArmor"
    keyPoshArmor = "SLAroused.IsPoshArmor"
    keyRaggedArmor = "SLAroused.IsRaggedArmor"
    keyKillerHeels = "SLAroused.IsKillerHeels"
    
    pageKeys = new String[8]
    pageKeys[0] = keyNakedArmor
    pageKeys[1] = keyBikiniArmor
    pageKeys[2] = keySexyArmor
    pageKeys[3] = keySlootyArmor
    pageKeys[4] = keyIllegalArmor
    pageKeys[5] = keyPoshArmor
    pageKeys[6] = keyRaggedArmor
    pageKeys[7] = keyKillerHeels
    
EndFunction


Function ResetKeywords()

    wordNakedArmor   = Keyword.GetKeyword("EroticArmor")
    wordBikiniArmor  = Keyword.GetKeyword("SLA_ArmorHalfNakedBikini")
    wordSexyArmor    = Keyword.GetKeyword("SLA_ArmorPretty")
    wordSlootyArmor  = Keyword.GetKeyword("SLA_ArmorHalfNaked")
    wordIllegalArmor = Keyword.GetKeyword("SLA_ArmorIllegal")
    wordPoshArmor    = Keyword.GetKeyword("ClothingRich")
    wordRaggedArmor  = Keyword.GetKeyword("ClothingPoor")
    wordKillerHeels  = Keyword.GetKeyword("SLA_KillerHeels")

EndFunction


Function ResetGenderPreferenceList()

    genderPreferenceList = new String[4]
    genderPreferenceList[0] = "$SLA_Male"
    genderPreferenceList[1] = "$SLA_Female"
    genderPreferenceList[2] = "$SLA_Both"
    genderPreferenceList[3] = "$SLA_UseSexLab"

EndFunction


Function ResetConstants()

    player = Game.GetPlayer()
    ResetPageNames()
    ResetGenderPreferenceList()
    ResetKeys()
    ResetKeywords()
    
EndFunction

function ClearActorData()
    if !ShowMessage("Do you want to reset all data for the selected actor (puppet actor)?")
        return
    endIf

    Actor who = slaPuppetActor

	int i = slaMain.GetEffectCount()
	while i > 0
        i -= 1
        slaMain.SetTimedEffectFunction(who, i, 0, 0, 0.0, 0)
        slaMain.SetEffectValue(who, i, 0.0)
    endWhile
    
	i = slaMain.GetDynamicEffectCount(who)
	while i > 0
        i -= 1
        
        string effect = slaMain.GetDynamicEffect(who, i)
        float value = slaMain.GetDynamicEffectValue(who, i)
        slaMain.ModDynamicArousalEffect(who, effect, -value, 0.0)
        slaMain.SetDynamicArousalEffect(who, effect, 0.0, 0, 0.0, 0.0)
    endWhile
endFunction

function ClearAllData()
    if !ShowMessage("Do you really want to delete all actor data from the current save?")
        return
    endIf
    slaInternalModules.CleanUpActors(Utility.GetCurrentGameTime())
endFunction

function ExportSettings()
    if !ShowMessage("Are you sure you want to overwrite the settings saved in the json file with your current settings?")
        return
    endIf
    string fileName = "..\\SLAX\\Settings"
    ;SLAX/Settings.json"
    SetTextOptionValue(exportSettingsOID, "$SLA_Working")
    JsonUtil.SetIntValue(fileName, "enableDesireSpell", IsDesireSpell as int)
    JsonUtil.SetIntValue(fileName, "wantsPurging", wantsPurging as int)
    JsonUtil.SetIntValue(fileName, "maleAnimation", maleAnimation as int)
    JsonUtil.SetIntValue(fileName, "femaleAnimation", femaleAnimation as int)
    JsonUtil.SetIntValue(fileName, "useLOS", useLOS as int)
    JsonUtil.SetIntValue(fileName, "isNakedOnly", isNakedOnly as int)
    JsonUtil.SetIntValue(fileName, "enableNotifications", enableNotifications as int)
    JsonUtil.SetIntValue(fileName, "bDisabled", bDisabled as int)
    JsonUtil.SetIntValue(fileName, "isExtendedNPCNaked", isExtendedNPCNaked as int)
    JsonUtil.SetIntValue(fileName, "isUseSOS", isUseSOS as int)
    JsonUtil.SetIntValue(fileName, "statusNotSplash", statusNotSplash as int)
    JsonUtil.SetFloatValue(fileName, "cellScanFreq", cellScanFreq)
    JsonUtil.SetIntValue(fileName, "smallUpdatesPerFull", smallUpdatesPerFull)
    JsonUtil.SetIntValue(fileName, "notificationKey", notificationKey)
    
    
    JsonUtil.FormListClear(fileName, "PluginOption")
    JsonUtil.IntListClear(fileName, "PluginOptionId")
    JsonUtil.FloatListClear(fileName, "PluginOptionValue")
    int optionCount = StorageUtil.StringListCount(slaMain, "SLAroused.MCM.Options")
    while optionCount > 0
        optionCount -= 1
        string prefix = StorageUtil.StringListGet(slaMain, "SLAroused.MCM.Options", optionCount)
        Form pluginForm = StorageUtil.GetFormValue(slaMain, prefix + ".Owner")
        sla_PluginBase plugin = (pluginForm as sla_PluginBase)
        int optionId = StorageUtil.GetIntValue(slaMain, prefix + ".OptionId")
        if (plugin != none)
            JsonUtil.FormListAdd(fileName, "PluginOption", plugin)
            JsonUtil.IntListAdd(fileName, "PluginOptionId", optionId)
            JsonUtil.FloatListAdd(fileName, "PluginOptionValue", plugin.GetOptionValue(optionId))
        endIf
    endWhile
    if !jsonutil.Save(fileName, false)
        SetTextOptionValue(exportSettingsOID, "Error")
		slax.Error("SLOANG export failed: " + jsonutil.GetErrors(fileName))
    Else
        SetTextOptionValue(exportSettingsOID, "$SLA_Done")
	endIf
   
endFunction

function ImportSettings()
    if !ShowMessage("Are you sure you want to overwrite your current settings with the settings save in the json file?")
        return
    endIf
    string fileName = "SLAX/Settings.json"
    SetTextOptionValue(exportSettingsOID, "SLA_Working")
    IsDesireSpell = JsonUtil.GetIntValue(fileName, "enableDesireSpell") as bool
    wantsPurging = JsonUtil.GetIntValue(fileName, "wantsPurging") as bool
    maleAnimation = JsonUtil.GetIntValue(fileName, "maleAnimation") as bool
    femaleAnimation = JsonUtil.GetIntValue(fileName, "femaleAnimation") as bool
    useLOS = JsonUtil.GetIntValue(fileName, "useLOS") as bool
    isNakedOnly = JsonUtil.GetIntValue(fileName, "isNakedOnly") as bool
    enableNotifications = JsonUtil.GetIntValue(fileName, "enableNotifications") as bool
    bDisabled = JsonUtil.GetIntValue(fileName, "bDisabled") as bool
    isExtendedNPCNaked = JsonUtil.GetIntValue(fileName, "isExtendedNPCNaked") as bool
    isUseSOS = JsonUtil.GetIntValue(fileName, "isUseSOS") as bool
    statusNotSplash = JsonUtil.GetIntValue(fileName, "statusNotSplash") as bool
    cellScanFreq = JsonUtil.GetFloatValue(fileName, "cellScanFreq")
    smallUpdatesPerFull = JsonUtil.GetIntValue(fileName, "smallUpdatesPerFull")
    notificationKey = JsonUtil.GetIntValue(fileName, "notificationKey")

    int i = JsonUtil.FormListCount(fileName, "PluginOption")
    while i > 0
        i -= 1
        Form pluginForm = JsonUtil.FormListGet(slaMain, "PluginOption", i)
        sla_PluginBase plugin = (pluginForm as sla_PluginBase)
        if (plugin != none)
            int optionId = JsonUtil.IntListGet(fileName, "PluginOptionId", i) 
            float value = JsonUtil.FloatListGet(fileName, "PluginOptionValue", i)
            plugin.OnUpdateOption(optionId, value)
        endIf
    endWhile

    ForcePageReset()
endFunction

; obsolete - keep for backward compatibility
float Property defaultExposureRate = 2.0 Auto Hidden
float Property TimeRateHalfLife = 2.0 Auto Hidden
