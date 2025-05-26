Scriptname sla_DDPlugin Extends sla_PluginBase

Actor Property playerRef Auto
sla_DefaultPlugin Property defaultPlugin Auto

zadLibs libs

bool function CheckDependencies()
	return Game.GetModByName("Devious Devices - Integration.esm") != 255
endFunction

event OnEndState()
	libs = Game.GetFormFromFile(0x00F624, "Devious Devices - Integration.esm") as zadLibs
endEvent

bool function CanActorOrgasmGeneric(Actor who)
    return true
endFunction

bool function CanGiveOrgasm(Actor who, bool anal, bool oral, bool breasts)
    return true
endFunction

bool function CanRecieveOrgasm(Actor who, bool anal)
	return true
endFunction

Actor currentObserver = none
int deviceEff = -1

float function GetBeltAndPlugModifier(Actor who)
	return 1.0
endFunction

event OnDeviceEquipped(Form inventoryDevice, Form deviceKeyword, Form akActor)
	Actor who = akActor as Actor
	if !who
		return
	endIf
	if deviceKeyword == libs.zad_DeviousBelt || deviceKeyword == libs.zad_DeviousPlug || deviceKeyword == libs.zad_DeviousPlugVaginal || deviceKeyword == libs.zad_DeviousPlugAnal
		defaultPlugin.UpdateDenialModifier(who)
	endIf
	ModArousalEffectValue(who, deviceEff, deviceArousal, deviceArousal * 10.0)
	float minimum = deviceMin
	if minimum && devicePerDevice
		int numberOfDevices = 0
		if libs.GetWornDevice(who, libs.zad_DeviousBelt)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousPlugVaginal)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousPlugAnal)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousBra)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousCollar)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousArmCuffs)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousLegCuffs)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousHeavyBondage)
			numberOfDevices += 3
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousCorset)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousClamps)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousGloves)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousHood)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousSuit)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousGag)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousBoots)
			numberOfDevices += 1
		endIf
		if libs.GetWornDevice(who, libs.zad_DeviousBlindfold)
			numberOfDevices += 1
		endIf
		if numberOfDevices > 0
			minimum = minimum * numberOfDevices
		endIf
	endIf
	SetLinearArousalEffect(who, deviceEff, -deviceHalfTime, minimum)
endEvent

event OnDeviceRemoved(Form inventoryDevice, Form deviceKeyword, Form akActor)
	Actor who = akActor as Actor
	if !who
		return
	endIf
	if deviceKeyword == libs.zad_DeviousBelt || deviceKeyword == libs.zad_DeviousPlug || deviceKeyword == libs.zad_DeviousPlugVaginal || deviceKeyword == libs.zad_DeviousPlugAnal
		defaultPlugin.UpdateDenialModifier(who)
	endIf
	if !who.WornHasKeyword(libs.zad_Lockable)
		SetLinearArousalEffect(who, deviceEff, -deviceHalfTime * 2.0, 0.0)
	endIf
endEvent

function SetTeasingEffectIfNeeded(Actor who)
	if who && libs.IsVibrating(who) && teasingActors.Find(who) == -1
		int handle = ModEvent.Create("slaModArousalEffect")
		ModEvent.PushForm(handle, who)
		ModEvent.PushString(handle, "DDTeasing")
		ModEvent.PushFloat(handle, 5.0) ; +5 arousal
		ModEvent.PushFloat(handle, 100.0) ; max
		ModEvent.Send(handle)

		handle = ModEvent.Create("slaSetArousalEffect")
		ModEvent.PushForm(handle, who)
		ModEvent.PushString(handle, "DDTeasing")
		ModEvent.PushFloat(handle, 0.0)
		ModEvent.PushInt(handle, 2) ; linear increase
		ModEvent.PushFloat(handle, 400.0 * 24.0) ; 400 arousal per hour
		ModEvent.PushFloat(handle, 100.0) ; max
		ModEvent.Send(handle)
		if teasingActors.Length == 0
			RegisterForSingleUpdate(1.0)
		endIf
		teasingActors = PapyrusUtil.PushActor(teasingActors, who)
	endIf
endFunction

Actor[] teasingActors

event OnVibrationStart(string eventName, string actorName, float strength, Form sender)
	Actor[] actors = main.GetNearbyActors()
	SetTeasingEffectIfNeeded(main.playerRef)
	int i = actors.Length
	while i > 0
		i -= 1
		SetTeasingEffectIfNeeded(actors[i])
	endWhile
endEvent

event OnVibrationStop(string eventName, string actorName, float argNum, Form sender)
	int i = teasingActors.Length
	while i > 0
		i -= 1
		Actor who = teasingActors[i]
		if who && !libs.IsVibrating(who)
			ForceUpdateArousal(who)
			int handle = ModEvent.Create("slaSetArousalEffect")
			ModEvent.PushForm(handle, who)
			ModEvent.PushString(handle, "DDTeasing")
			ModEvent.PushFloat(handle, 0.0)
			ModEvent.PushInt(handle, 1) ; decay
			ModEvent.PushFloat(handle, 2.0 / 24.0) ; 50 % every other hour
			ModEvent.PushFloat(handle, 0.0) ; remove at 0
			ModEvent.Send(handle)
			teasingActors[i] = none
		endIf
	endWhile
	teasingActors = PapyrusUtil.RemoveActor(teasingActors, none)
endEvent

event OnUpdate()
	int i = teasingActors.Length
	while i > 0
		i -= 1
		Actor who = teasingActors[i]
		ForceUpdateArousal(who)
	endWhile
	if teasingActors.Length > 0
    	RegisterForSingleUpdate(1.0)
	endIf
endEvent

float deviceHalfTime = 24.0
float deviceArousal = 5.0
float deviceMin = 0.0
bool devicePerDevice = true

float function GetOptionValue(int optionId)
	if optionId == 0
		return deviceHalfTime
	elseIf optionId == 1
		return deviceArousal
	elseIf optionId == 2
		return deviceMin
	elseIf optionId == 3
		return devicePerDevice as float
	endIf
endFunction

function OnUpdateOption(int optionId, float value)
	if optionId == 0
		deviceHalfTime = value
	elseIf optionId == 1
		deviceArousal = value
	elseIf optionId == 2
		deviceMin = value
	elseIf optionId == 3
		devicePerDevice = value as bool
	endIf
endFunction

state Installed
	event OnBeginState()
		OnInstalled()
	endEvent

	event OnEndState()
		OnUninstalled()
	endEvent
	
	function EnablePlugin()
		teasingActors = PapyrusUtil.ActorArray(0)
		RegisterForModEvent("DDI_DeviceEquipped", "OnDeviceEquipped")
		RegisterForModEvent("DDI_DeviceRemoved", "OnDeviceRemoved")
		RegisterForModEvent("DeviceVibrateEffectStart", "OnVibrationStart")
		RegisterForModEvent("DeviceVibrateEffectStop", "OnVibrationStop")
		deviceEff = RegisterEffect("Devices", "$SLA_Effect_Devices", "$SLA_Effect_DevicesDesc")
		int handle = ModEvent.Create("slaRegisterDynamicEffect")
		ModEvent.PushString(handle, "DDTeasing")
		ModEvent.PushString(handle, "$SLA_Effect_DDTeasing")
		ModEvent.PushString(handle, "$SLA_Effect_DDTeasingDesc")
		ModEvent.Send(handle)
	endFunction
	
	function AddOptions()
		AddOptionEx("$SLA_Effect_DeviceCat", "$SLA_Effect_DevicesHalfTime", "$SLA_Effect_DevicesHalfTimeDesc", 1.0, 0.0, 24.0, 0.1, "{1}/hour")
		AddOptionEx("$SLA_Effect_DeviceCat", "$SLA_Effect_DevicesArousalOnEquip", "$SLA_Effect_DevicesArousalOnEquipDesc", 5.0, 0.0, 25.0, 0.1, "{1}")
		AddOption("$SLA_Effect_DeviceCat", "$SLA_Effect_DevicesMin", "$SLA_Effect_DevicesMinDesc", 0.0)
		AddToggleOption("$SLA_Effect_DeviceCat", "$SLA_Effect_DevicesPerDevice", "$SLA_Effect_DevicesPerDevice", true)
	endFunction

	function DisablePlugin()
		parent.DisablePlugin()
		UnregisterEffect("Devices")
		UnregisterForAllModEvents()
	endFunction

	bool function CanActorOrgasmGeneric(Actor who)
		return who.WornHasKeyword(libs.zad_DeviousBelt) == false
	endFunction
	
	bool function CanGiveOrgasm(Actor who, bool anal, bool oral, bool breasts)
		if anal
			if who.WornHasKeyword(libs.zad_DeviousBelt)
				return who.WornHasKeyword(libs.zad_PermitAnal)
			endIf
			return true
		elseIf oral
			if who.WornHasKeyword(libs.zad_DeviousGag)
				return who.WornHasKeyword(libs.zad_PermitOral)
			endIf
			return true
		elseIf breasts
			return !who.WornHasKeyword(libs.zad_DeviousBra)
		endIf
	
		if who.WornHasKeyword(libs.zad_DeviousBelt)
			return who.WornHasKeyword(libs.zad_PermitVaginal)
		endIf
		return true
	endFunction
	
	bool function CanRecieveOrgasm(Actor who, bool anal)
		if who.WornHasKeyword(libs.zad_DeviousBelt)
			if anal
				return who.WornHasKeyword(libs.zad_PermitAnal)
			else
				return who.WornHasKeyword(libs.zad_PermitVaginal)
			endIf
		endIf
		return true
	endFunction

	float function GetBeltAndPlugModifier(Actor who)
		float result = 1.0
		if who.WornHasKeyword(libs.zad_DeviousPlug)
			result *= libs.GetPlugRateMult()
		endIf
		if who.WornHasKeyword(libs.zad_DeviousBelt)
			result *= libs.GetBeltRateMult()
		endIf
		return result
	endFunction
	
	function UpdateActor(Actor who, bool fullUpdate)
		if currentObserver != none
			; todo add line of sight feature
		endIf

		currentObserver = who
		if who == none
			return
		endIf
	endFunction
endState