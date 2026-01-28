Scriptname sla_DefaultPlugin Extends sla_PluginBase

slaInternalScr Property slaUtil Auto
Faction Property slaNaked Auto
Faction Property slaCreatureSexLoverFaction Auto
sla_DDPlugin Property ddPlugin Auto
Keyword Property kActorTypeCreature Auto

event OnEndState()
endEvent

Actor currentObserver = none
int currentNakedCount = 0
bool currentSeesNaked = false
bool currentSeesNakedPref = false

int nakedEff = -1
int satisfactionEff = -1
int timedEff = -1
int timedCycleEff = -1
int legacyEff = -1
int sleepEff = -1

float nakedMax = 50.0
float nakedMaxNonPref = 15.0
float nakedIncrease = 600.0 ; 25.0 * 24.0 
float nakedHalfTime = 0.04166666 ; 1.0 / 24.0

bool useDenialCycle = true
float timedBaseRate = 12.5
float timedMax = 60.0

float orgasmHalfTime = 0.04166666 ; 1.0 / 24.0
float orgasmBase = 50.0
float orgasmRate = 1.0
float femaleOrgasmFactor = 0.8

float legacyMultiplier = 1.0
float legacyDecay = 0.5

float sleepMin = 5.0
float sleepMax = 15.0
float sleepHalfTime = 0.04166666 ; 1.0 / 24.0
float sleepMinHours = 3.0

float sleepStartTime = 0.0

function UpdateDenialModifier(Actor who)
	float denialInc = timedBaseRate * ddPlugin.GetBeltAndPlugModifier(who)
	SetLinearArousalEffect(who, timedEff, denialInc, timedMax)
endFunction

function UpdateDenialCycle(Actor who)
	SetArousalEffectFunction(who, timedCycleEff, 3, 2.0 * 3.14159, 0.5, 1)
	GroupEffects(who, timedEff, timedCycleEff)
endFunction

float function GetOptionValue(int optionId)
	if optionId == 0
		return nakedMax
	elseIf optionId == 1
		return nakedMaxNonPref
	elseIf optionId == 2
		return nakedIncrease / 24.0
	elseIf optionId == 3
		return nakedHalfTime * 24.0
	elseIf optionId == 4
		return useDenialCycle as float
	elseIf optionId == 5
		return timedBaseRate
	elseIf optionId == 6
		return timedMax
	elseIf optionId == 7
		return legacyMultiplier
	elseIf optionId == 8
		return legacyDecay * 24.0
	elseIf optionId == 9
		return orgasmHalfTime * 24.0
	elseIf optionId == 10
		return orgasmBase
	elseIf optionId == 11
		return orgasmRate
	elseIf optionId == 12
		return femaleOrgasmFactor
	elseIf optionId == 13
		return sleepMin
	elseIf optionId == 14
		return sleepMax
	elseIf optionId == 15
		return sleepHalfTime * 24.0
	elseIf optionId == 16
		return sleepMinHours
	endIf
	return 0.0
endFunction

function OnUpdateOption(int optionId, float value)
	if optionId == 0
		nakedMax = value
	elseif optionId == 1
		nakedMaxNonPref = value
	elseIf optionId == 2
		nakedIncrease = value * 24.0
	elseIf optionId == 3
		nakedHalfTime = value / 24.0
	elseIf optionId == 4
		useDenialCycle = (value as bool) 
	elseIf optionId == 5
		timedBaseRate = value
	elseIf optionId == 6
		timedMax = value
	elseIf optionId == 7
		legacyMultiplier = value
	elseIf optionId == 8
		legacyDecay = value / 24.0
	elseIf optionId == 9
		orgasmHalfTime = value / 24.0
	elseIf optionId == 10
		orgasmBase = value
	elseIf optionId == 11
		orgasmRate = value
	elseIf optionId == 12
		femaleOrgasmFactor = value
	elseIf optionId == 13
		sleepMin = value
	elseIf optionId == 14
		sleepMax = value
	elseIf optionId == 15
		sleepHalfTime = value / 24.0
	elseIf optionId == 16
		sleepMinHours = value
	endIf
endFunction

function OnOrgasm(Actor who, float enjoyment)
	slax.Info("sla_DefaultPlugin - OnOrgasm(" + who + ", "+ enjoyment + ")")
	StorageUtil.SetFloatValue(who, "SLAroused.LastOrgasmDate", Utility.GetCurrentGameTime()) ;Added by Bane for Radiant Prostitution Orgasm Detection in V0.1.2 28/06/2023
	SetArousalEffectValue(who, timedEff, 0.0)
	float satisfaction = -orgasmBase - enjoyment * orgasmRate
	if who.GetLeveledActorBase().GetSex() == 1
		satisfaction *= femaleOrgasmFactor
	endIf
	ModArousalEffectValue(who, satisfactionEff, satisfaction, -1000)
	SetArousalDecayEffect(who, satisfactionEff, orgasmHalfTime, 0.0)
	; remove dd teasing effect
	int handle = ModEvent.Create("slaModArousalEffect")
	ModEvent.PushForm(handle, who)
	ModEvent.PushString(handle, "DDTeasing")
	ModEvent.PushFloat(handle, -100.0)
	ModEvent.PushFloat(handle, 0.0)
	ModEvent.Send(handle)
	ForceUpdateArousal(who)
endFunction

float function ModExposureLegacy(Actor who, float exposureValue)
	if isEnabled == false
		return 0.0
	endIf
	float limit = 100.0
	exposureValue *= legacyMultiplier
	if exposureValue < 0
		limit = 0.0
	endIf
	float diff = ModArousalEffectValue(who, legacyEff, exposureValue, limit)
	if !IsEffectActive(who, legacyEff)
		SetArousalDecayEffect(who, legacyEff, legacyDecay, 0.0)
	endIf
	ForceUpdateArousal(who)
	return diff
endFunction

float function GetExposureLegacy(Actor who)
	return GetArousalEffectValue(who, legacyEff)
endFunction 

state Installed
	event OnBeginState()
		OnInstalled()
	endEvent

	event OnEndState()
		OnUninstalled()
	endEvent
	
	function EnablePlugin()
		RegisterForPerodicUpdates()
		RegisterForLOSUpdates()
		nakedEff = RegisterEffect("Naked", "$SLA_Effect_Naked", "$SLA_Effect_NakedDesc")
		satisfactionEff = RegisterEffect("Orgasm", "$SLA_Effect_Satisfaction", "$SLA_Effect_SatisfactionDesc")
		timedEff = RegisterEffect("Timed", "$SLA_Effect_Timed", "$SLA_Effect_TimedDesc")
		timedCycleEff = RegisterEffect("TimedCycle", "Timed Cycle", "[Hidden in UI] Helper for denial effect.")
		HideEffectInUI(timedCycleEff)
		legacyEff = RegisterEffect("Legacy", "$SLA_Effect_Legacy", "$SLA_Effect_LegacyDesc")
		sleepEff = RegisterEffect("Sleep", "$SLA_Effect_Sleep", "$SLA_Effect_SleepDesc")
		RegisterForSleep()
	endFunction

	function AddOptions()
		slax.info("sla_DefaultPlugin - Default.AddOptions()")
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedMax", "$SLA_Effect_NakedMaxDesc", 50.0)
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedMaxNonPref", "$SLA_Effect_NakedMaxNonPrefDesc", 15.0)
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedRate", "$SLA_Effect_NakedRateDesc", 25.0)
		AddOptionEx("$SLA_Effect_NakedCat", "$SLA_Effect_NakedHalfTime", "$SLA_Effect_NakedHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddToggleOption("$SLA_Effect_TimedCat", "$SLA_Effect_TimedUseCycle", "$SLA_Effect_TimedUseCycleDesc", true)
		AddOptionEx("$SLA_Effect_TimedCat", "$SLA_Effect_TimedRate", "$SLA_Effect_TimedRateDesc", 12.5, 0.1, 50.0, 0.5, "{1} arousal/day")
		AddOption("$SLA_Effect_TimedCat", "$SLA_Effect_TimedMax", "$SLA_Effect_TimedMaxDesc.", 60.0)
		AddOptionEx("$SLA_Effect_LegacyCat", "$SLA_Effect_LegacyMultiplier", "$SLA_Effect_LegacyMultiplierDesc", 1.0, 0.0, 10.0, 0.1, "x{1} Rate")
		AddOptionEx("$SLA_Effect_LegacyCat", "$SLA_Effect_LegacyHalfTime", "$SLA_Effect_LegacyHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionHalfTime", "$SLA_Effect_SatisfactionHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOption("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionBase", "$SLA_Effect_SatisfactionBaseDesc", 50.0)
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionRate", "$SLA_Effect_SatisfactionRateDesc", 1.0, 0.0, 10.0, 0.1, "{1} arousal/enjoyment")
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionFemaleRate", "$SLA_Effect_SatisfactionFemaleRateDesc", 0.8, 0.0, 3.0, 0.01, "x{2} Rate")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMin", "$SLA_Effect_SleepMinDesc", 5.0, 0.0, 100.0, 1.0, "{1}")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMax", "$SLA_Effect_SleepMaxDesc", 15.0, 0.0, 100.0, 1.0, "{1}")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepHalfTime", "$SLA_Effect_SleepHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMinTime", "$SLA_Effect_SleepMinTimeDesc", 3.0, 0.0, 24.0, 0.5, "{1} hours")
	endFunction

	function DisablePlugin()
		parent.DisablePlugin()
		UnregisterEffect("Naked")
		UnregisterEffect("Orgasm")
		UnregisterEffect("Timed")
		UnregisterEffect("TimedCycle")
		UnregisterEffect("Legacy")
		UnregisterEffect("Sleep")
		UnregisterForSleep()
	endFunction

	function UpdateActor(Actor who, bool fullUpdate)
		if currentObserver != none
			if !IsEffectActive(currentObserver, timedEff) && GetArousalEffectValue(currentObserver, timedEff) < timedMax
				UpdateDenialModifier(currentObserver)
			endIf

			if useDenialCycle
				if GetArousalEffectFncAux(currentObserver, timedCycleEff) != 1
					UpdateDenialCycle(currentObserver)
				endIf
			elseIf GetArousalEffectFncAux(currentObserver, timedCycleEff) == 1
				DisableArousalEffect(currentObserver, timedCycleEff)
				RemoveEffectGroup(currentObserver, timedEff)
			endIf

			int seesNakedState = 1 ; Sees naked actor with preferred gender
			if currentSeesNaked == false
				seesNakedState = 0 ; No naked actor
			elseIf currentSeesNakedPref == false
				seesNakedState = 2 ; Naked actor without preferred gender
			endIf
			
			int oldState = GetArousalEffectFncAux(currentObserver, nakedEff)
			if (oldState != seesNakedState) 
				if seesNakedState == 0
					SetArousalEffectFunction(currentObserver, nakedEff, 1, nakedHalfTime, 0.0, 0)
				elseIf seesNakedState == 1
					SetArousalEffectFunction(currentObserver, nakedEff, 2, currentNakedCount * nakedIncrease, nakedMax, 1)
				elseIf seesNakedState == 2
					if oldState == 1 && GetArousalEffectValue(currentObserver, nakedEff)
						SetArousalEffectFunction(currentObserver, nakedEff, 1, nakedHalfTime, nakedMaxNonPref, 2)
					else
						SetArousalEffectFunction(currentObserver, nakedEff, 2, currentNakedCount * nakedIncrease, nakedMaxNonPref, 2)
					endIf
				endIf
			endIf
		endIf
		
		currentObserver = who
		if who == none
			return
		endIf
		
		currentNakedCount = 0
		currentSeesNaked = false
		currentSeesNakedPref = false
	endFunction
	
	function UpdateObserver(Actor observer, Actor observed)
		if observed.HasKeyword(kActorTypeCreature)
			if observer.HasKeyword(kActorTypeCreature) || observer.GetFactionRank(slaCreatureSexLoverFaction) > -1
				currentSeesNaked = true
			else
				return
			endIf
		endIf

		bool observedIsNaked = observed.GetFactionRank(slaNaked) > -2
		if !observedIsNaked
			return
		endIf

		currentSeesNaked = true
		int genderPreference = slaUtil.GetGenderPreference(observer)
		if genderPreference == 2 || genderPreference == observed.GetLeveledActorBase().GetSex()
			currentSeesNakedPref = true
			currentNakedCount += 2
		else
			currentNakedCount += 1
		endIf
	endFunction
endState

event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	sleepStartTime = Utility.GetCurrentGameTime()
endEvent

event OnSleepStop(bool abInterrupted)
	if !isEnabled || sleepEff < 0
		return
	endIf

	Actor who = main.playerRef
	if who == none
		return
	endIf

	if sleepMinHours > 0.0 && sleepStartTime > 0.0
		float sleptHours = (Utility.GetCurrentGameTime() - sleepStartTime) * 24.0
		if sleptHours < sleepMinHours
			sleepStartTime = 0.0
			return
		endIf
	endIf
	sleepStartTime = 0.0

	float minValue = sleepMin
	float maxValue = sleepMax
	if maxValue < minValue
		float tmp = minValue
		minValue = maxValue
		maxValue = tmp
	endIf

	float amount = Utility.RandomFloat(minValue, maxValue)
	if amount <= 0.0
		return
	endIf

	ModArousalEffectValue(who, sleepEff, amount, 100.0)
	if sleepHalfTime > 0.0
		SetArousalDecayEffect(who, sleepEff, sleepHalfTime, 0.0)
	endIf
	ForceUpdateArousal(who)
endEvent
