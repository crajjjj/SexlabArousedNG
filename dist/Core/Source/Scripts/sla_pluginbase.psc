Scriptname sla_PluginBase extends Quest

slaMainScr Property main Auto
string Property name Auto
bool Property isEnabled = false Auto Hidden

function LogDebug(string msg)
	Debug.TraceUser("SLA", name + ": " + msg)
endFunction

bool function IsInterfaceActive()
	if GetState() == "Installed"
		return true
	endIf
	return false
endFunction

event OnInit()
	RegisterForModEvent("sla_Int_PlayerLoadsGame", "On_sla_Int_PlayerLoadsGame")
endEvent

event On_sla_Int_PlayerLoadsGame(string eventName, string strArg, float numArg, Form sender)
	PlayerLoadsGame()
endEvent

function PlayerLoadsGame()
	if CheckDependencies()
		if GetState() != "Installed"
			GoToState("Installed")
		endIf
	else
		if GetState() != ""
			GoToState("")
		endIf
	endIf
endFunction

bool function CheckDependencies()
	{To be implemented by plugin}
	return true
endFunction

function EnablePlugin()
	{To be implemented by plugin}
endFunction

function AddOptions()
	{To be implemented by plugin}
endFunction

function DisablePlugin()
	{To be implemented by plugin}
	UnregisterForLOSUpdates()
	main.SetPluginUpdateEvents(self, true)
endFunction

function Update(Actor[] actors, Actor[] nakedActors)
	{To be implemented by plugin}
endFunction

function UpdateActor(Actor who, bool fullUpdate)
	{To be implemented by plugin. See documentation for UpdateActorArousals in slamainsrc.psc}
endFunction

function UpdateObserver(Actor observer, Actor observed)
	{To be implemented by plugin}
endFunction

function ClearActor(Actor who)
	{To be implemented by plugin}
endFunction

int numberOfOptions = 0

function ClearOptions()
	StorageUtil.ClearAllPrefix("SLAroused.MCM." + self.name)
	numberOfOptions = 0
endFunction

int function GetNumberOfOptions()
	return numberOfOptions
endFunction

int function AddToggleOption(string category, string title, string description, bool defaultValue)
	int option = AddOption(category, title, description, defaultValue as Float)
	SetToggleOption(option)
	return option
endFunction

int function AddOptionEx(string category, string title, string description, float defaultValue, float min, float max, float step, string format = "{0}")
	int optionId = AddOption(category, title, description, defaultValue)
	string prefix = "SLAroused.MCM." + self.name + "." + optionId
	StorageUtil.SetFloatValue(main, prefix + ".Min", min)
	StorageUtil.SetFloatValue(main, prefix + ".Max", max)
	StorageUtil.SetFloatValue(main, prefix + ".Interval", step)
	StorageUtil.SetStringValue(main, prefix + ".Format", format)
	return optionId
endFunction

int function AddOption(string category, string title, string description, float defaultValue)
	string prefix = "SLAroused.MCM." + self.name + "." + numberOfOptions
	StorageUtil.SetFormValue(main, prefix + ".Owner", self)
	StorageUtil.SetIntValue(main, prefix + ".OptionId", numberOfOptions)
	StorageUtil.SetStringValue(main, prefix + ".Title", title)
	StorageUtil.SetStringValue(main, prefix + ".Description", description)
	StorageUtil.SetStringValue(main, prefix + ".Category", category)
	SetOptionDefault(numberOfOptions, defaultValue)
	numberOfOptions += 1
	StorageUtil.StringListAdd(main, "SLAroused.MCM.Options", prefix, false)
	return numberOfOptions - 1
endFunction

function SetOptionDefault(int option, float defaultValue)
	string id = "SLAroused.MCM." + self.name + "." + numberOfOptions + ".Default"
	StorageUtil.SetFloatValue(main, id, defaultValue)
endFunction

Function SetToggleOption(int option)
	string id = "SLAroused.MCM." + self.name + "." + option + ".Type"
	StorageUtil.SetStringValue(main, id, "toggle")
EndFunction

float function GetOptionValue(int optionId)
	{To be implemented by plugin}
	return 0.0
endFunction

function OnUpdateOption(int optionId, float value)
	{To be implemented by plugin}
endFunction

function RegisterForPerodicUpdates()
	main.SetPluginUpdateEvents(self, true)
endFunction

function RegisterForLOSUpdates()
	main.SetPluginLOSEvents(self, true)
endFunction

function UnregisterForLOSUpdates()
	main.SetPluginLOSEvents(self, false)
endFunction

function HideEffectInUI(int effectId)
	main.SetEffectVisible(effectId, false)
endFunction

function ShowEffectInUI(int effectId)
	main.SetEffectVisible(effectId, false)
endFunction

int function RegisterEffect(string id, string title, string description)
	return main.RegisterEffect(id, title, description, self)
endFunction

function UnregisterEffect(string id)
	main.UnregisterEffect(id)
endFunction

bool Function IsEffectActive(Actor who, int effectIdx)
	return main.IsEffectActive(who, effectIdx)
EndFunction

float function GetArousalEffectValue(Actor who, int effectIdx)
	return main.GetEffectValue(who, effectIdx)
endFunction

function SetArousalEffectValue(Actor who, int effectIdx, float value)
	main.SetEffectValue(who, effectIdx, value)
endFunction

float function ModArousalEffectValue(Actor who, int effectIdx, float diff, float limit)
	return main.ModEffectValue(who, effectIdx, diff, limit)
endFunction

function SetArousalEffectFunction(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary = 0)
	{Use a built-in function for this effect. 
	functionId: 0 - none
				1 - reduce by 50% after $param ingame days
				2 - change effect value by $param per day
				3 - effect value is equal to (sin(days * $param) + 1.0) * limit
				4 - effect value is 0 if time < $param otherwise limit
	limit is the upper/lower bound for this
	auxilliary can be used to storage additional information used by the plugin}
	main.SetTimedEffectFunction(who, effectIdx, functionId, param, limit, auxilliary)
endFunction

function SetLinearArousalEffect(Actor who, int effectIdx, float ratePerDay, float limit, int auxilliary = 0)
	main.SetTimedEffectFunction(who, effectIdx, 2, ratePerDay, limit, auxilliary)
endFunction

function SetArousalDecayEffect(Actor who, int effectIdx, float halfLifeInDays, float limit, int auxilliary = 0)
	main.SetTimedEffectFunction(who, effectIdx, 1, halfLifeInDays, limit, auxilliary)
endFunction

int function GetArousalEffectFncAux(Actor who, int effectIdx)
	return main.GetTimedEffectAuxilliary(who, effectIdx)
endFunction

float function GetArousalEffectFncLimit(Actor who, int effectIdx)
	return main.GetTimedEffectLimit(who, effectIdx)
endFunction

float function GetArousalEffectFncParam(Actor who, int effectIdx)
	return main.GetTimedEffectParameter(who, effectIdx)
endFunction

function ForceUpdateArousal(Actor who)
	{Forces a recalculation of current arousal values and immediately update
	arousal effects on the target actor. Without this forced update effects 
	are applied delayed.}
	main.UpdateSingleActorArousal(who)
endFunction

function DisableArousalEffect(Actor who, int effectIdx)
	SetArousalEffectFunction(who, effectIdx, 0, 0, 0.0, 0)
	SetArousalEffectValue(who, effectIdx, 0.0)
endFunction

bool function GroupEffects(Actor who, int effIdx1, int effIdx2)
	{Merges two arousal effects into one group. All effects in the same 
	group will be multiplied and added to the total arousal value instead 
	of the idividual effect values. At least one effect has to be not 
	part of a group. In other words you can't merge two groups with this 
	fuction. }
	return main.GroupEffects(who, effIdx1, effIdx2)
endFunction

bool function RemoveEffectGroup(Actor who, int effIdx)
	return main.RemoveEffectGroup(who, effIdx)
endFunction

event OnInstalled()
	main.RegisterPlugin(self)
endEvent

event OnUninstalled()
	main.UnregisterPlugin(self)
endEvent
