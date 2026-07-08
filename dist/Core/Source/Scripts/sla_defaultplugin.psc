Scriptname sla_DefaultPlugin Extends sla_PluginBase

slaInternalScr Property slaUtil Auto
Faction Property slaNaked Auto
Faction Property slaCreatureSexLoverFaction Auto
sla_DDPlugin Property ddPlugin Auto
Keyword Property kActorTypeCreature Auto

event OnEndState()
endEvent

Actor currentObserver = none
float currentNakedWeight = 0.0 ; onlooker count weighted by gender preference and AND exposure
float currentNakedMaxExposure = 0.0 ; most exposed naked actor in view, 0.0 .. 1.0
bool currentSeesNaked = false
bool currentSeesNakedPref = false
bool currentObserverExhibiting = false
int currentExhibitionistCount = 0
float currentExhibitionistExposure = 0.0

int nakedEff = -1
int exhibitionistEff = -1
int satisfactionEff = -1
int timedEff = -1
int timedCycleEff = -1
int legacyEff = -1
int sleepEff = -1

float nakedMax = 50.0
float nakedMaxNonPref = 15.0
float nakedIncrease = 600.0 ; 25.0 * 24.0
float nakedHalfTime = 0.04166666 ; 1.0 / 24.0
; Scale the Naked effect by how much the observed actor is showing (AND graded
; exposure, cached per cycle) -- see slaMainScr.GetNakedExposureScale.
bool scaleNakedByExposure = true

float exhibMax = 50.0
float exhibIncrease = 600.0 ; 25.0 * 24.0
float exhibHalfTime = 0.04166666 ; 1.0 / 24.0
; Dynamic exhibitionism: mirror Advanced Nudity Detection's modesty ranks into
; the exhibitionist faction -- see slaFrameworkScr.UpdateDynamicExhibitionist.
bool useModestyRanks = true
int modestyThreshold = 4 ; AND rank: 4 Tease, 5 Brazen, 6 Shameless

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
float sleepHalfTime = 0.20833333 ; 5.0 / 24.0
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
	elseIf optionId == 17
		return exhibMax
	elseIf optionId == 18
		return exhibIncrease / 24.0
	elseIf optionId == 19
		return exhibHalfTime * 24.0
	elseIf optionId == 20
		return useModestyRanks as float
	elseIf optionId == 21
		return modestyThreshold as float
	elseIf optionId == 22
		return scaleNakedByExposure as float
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
	elseIf optionId == 17
		exhibMax = value
	elseIf optionId == 18
		exhibIncrease = value * 24.0
	elseIf optionId == 19
		exhibHalfTime = value / 24.0
	elseIf optionId == 20
		useModestyRanks = (value as bool)
	elseIf optionId == 21
		modestyThreshold = value as int
	elseIf optionId == 22
		scaleNakedByExposure = (value as bool)
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
		exhibitionistEff = RegisterEffect("Exhibitionist", "$SLA_Effect_Exhibitionist", "$SLA_Effect_ExhibitionistDesc")
		satisfactionEff = RegisterEffect("Orgasm", "$SLA_Effect_Satisfaction", "$SLA_Effect_SatisfactionDesc")
		timedEff = RegisterEffect("Timed", "$SLA_Effect_Timed", "$SLA_Effect_TimedDesc")
		timedCycleEff = RegisterEffect("TimedCycle", "Timed Cycle", "[Hidden in UI] Helper for denial effect.")
		HideEffectInUI(timedCycleEff)
		legacyEff = RegisterEffect("Legacy", "$SLA_Effect_Legacy", "$SLA_Effect_LegacyDesc")
		sleepEff = RegisterEffect("Sleep", "$SLA_Effect_Sleep", "$SLA_Effect_SleepDesc")
		RegisterForSleep()
	endFunction

	function ReassertSubscriptions()
		RegisterForPerodicUpdates()
		RegisterForLOSUpdates()
	endFunction

	function AddOptions()
		slax.info("sla_DefaultPlugin - Default.AddOptions()")
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedMax", "$SLA_Effect_NakedMaxDesc", 50.0)
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedMaxNonPref", "$SLA_Effect_NakedMaxNonPrefDesc", 15.0)
		AddOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedRate", "$SLA_Effect_NakedRateDesc", 25.0)
		AddOptionEx("$SLA_Effect_NakedCat", "$SLA_Effect_NakedHalfTime", "$SLA_Effect_NakedHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddToggleOption("$SLA_Effect_TimedCat", "$SLA_Effect_TimedUseCycle", "$SLA_Effect_TimedUseCycleDesc", true)
		AddOptionEx("$SLA_Effect_TimedCat", "$SLA_Effect_TimedRate", "$SLA_Effect_TimedRateDesc", 12.5, 0.1, 50.0, 0.5, "{1} arousal/day")
		AddOption("$SLA_Effect_TimedCat", "$SLA_Effect_TimedMax", "$SLA_Effect_TimedMaxDesc", 60.0)
		AddOptionEx("$SLA_Effect_LegacyCat", "$SLA_Effect_LegacyMultiplier", "$SLA_Effect_LegacyMultiplierDesc", 1.0, 0.0, 10.0, 0.1, "x{1} Rate")
		AddOptionEx("$SLA_Effect_LegacyCat", "$SLA_Effect_LegacyHalfTime", "$SLA_Effect_LegacyHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionHalfTime", "$SLA_Effect_SatisfactionHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOption("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionBase", "$SLA_Effect_SatisfactionBaseDesc", 50.0)
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionRate", "$SLA_Effect_SatisfactionRateDesc", 1.0, 0.0, 10.0, 0.1, "{1} arousal/enjoyment")
		AddOptionEx("$SLA_Effect_SatisfactionCat", "$SLA_Effect_SatisfactionFemaleRate", "$SLA_Effect_SatisfactionFemaleRateDesc", 0.8, 0.0, 3.0, 0.01, "x{2} Rate")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMin", "$SLA_Effect_SleepMinDesc", 5.0, 0.0, 100.0, 1.0, "{1}")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMax", "$SLA_Effect_SleepMaxDesc", 15.0, 0.0, 100.0, 1.0, "{1}")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepHalfTime", "$SLA_Effect_SleepHalfTimeDesc", 5.0, 0.1, 24.0, 0.1, "{1} hours")
		AddOptionEx("$SLA_Effect_SleepCat", "$SLA_Effect_SleepMinTime", "$SLA_Effect_SleepMinTimeDesc", 3.0, 0.0, 24.0, 0.5, "{1} hours")
		; Appended last so these keep option IDs 17/18/19, matching GetOptionValue/OnUpdateOption.
		; AddOption assigns IDs by call order (sla_PluginBase numberOfOptions), so they must not
		; be inserted mid-list -- doing so would renumber every later option and scramble the MCM.
		AddOption("$SLA_Effect_ExhibitionistCat", "$SLA_Effect_ExhibitionistMax", "$SLA_Effect_ExhibitionistMaxDesc", 50.0)
		AddOption("$SLA_Effect_ExhibitionistCat", "$SLA_Effect_ExhibitionistRate", "$SLA_Effect_ExhibitionistRateDesc", 25.0)
		AddOptionEx("$SLA_Effect_ExhibitionistCat", "$SLA_Effect_ExhibitionistHalfTime", "$SLA_Effect_ExhibitionistHalfTimeDesc", 1.0, 0.1, 24.0, 0.1, "{1} hours")
		; IDs 20/21/22 -- Advanced Nudity Detection integration. Appended last (see above).
		AddToggleOption("$SLA_Effect_ExhibitionistCat", "$SLA_Effect_ExhibitionistANDRanks", "$SLA_Effect_ExhibitionistANDRanksDesc", true)
		AddOptionEx("$SLA_Effect_ExhibitionistCat", "$SLA_Effect_ExhibitionistANDThreshold", "$SLA_Effect_ExhibitionistANDThresholdDesc", 4.0, 1.0, 6.0, 1.0, "{0}")
		AddToggleOption("$SLA_Effect_NakedCat", "$SLA_Effect_NakedANDScale", "$SLA_Effect_NakedANDScaleDesc", true)
	endFunction

	function DisablePlugin()
		parent.DisablePlugin()
		UnregisterEffect("Naked")
		UnregisterEffect("Exhibitionist")
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

			int nakedState = seesNakedState
			if seesNakedState != 0
				if currentNakedMaxExposure <= 0.0
					; Seeing "naked" without a weighted contribution (creature-lover
					; path with a creature outside the naked faction) -- keep the
					; caps at full strength instead of collapsing them to 0.
					currentNakedMaxExposure = 1.0
				endIf
				; Fold the quantised max exposure (tiers 1-10) into the aux state so a
				; change in how much the most exposed actor shows re-applies rate/cap
				; (the effect only refreshes on an aux-state transition). Decode the
				; base state as aux - (aux / 4) * 4; legacy saves stored plain 1/2,
				; which decodes the same and just triggers a one-time re-apply.
				nakedState = seesNakedState + (((currentNakedMaxExposure * 9.0) as int) + 1) * 4
			endIf

			int oldState = GetArousalEffectFncAux(currentObserver, nakedEff)
			if (oldState != nakedState)
				if seesNakedState == 0
					SetArousalEffectFunction(currentObserver, nakedEff, 1, nakedHalfTime, 0.0, 0)
				elseIf seesNakedState == 1
					SetArousalEffectFunction(currentObserver, nakedEff, 2, currentNakedWeight * nakedIncrease, nakedMax * currentNakedMaxExposure, nakedState)
				elseIf seesNakedState == 2
					if oldState - (oldState / 4) * 4 == 1 && GetArousalEffectValue(currentObserver, nakedEff)
						SetArousalEffectFunction(currentObserver, nakedEff, 1, nakedHalfTime, nakedMaxNonPref * currentNakedMaxExposure, nakedState)
					else
						SetArousalEffectFunction(currentObserver, nakedEff, 2, currentNakedWeight * nakedIncrease, nakedMaxNonPref * currentNakedMaxExposure, nakedState)
					endIf
				endIf
			endIf

			int exhibTier = 0 ; Covered, or not being seen while exhibiting
			if currentExhibitionistCount > 0 && currentExhibitionistExposure > 0.0
				; Quantise exposure into tiers 1-4 and store it as the aux state, so a
				; change in how much is shown re-applies the rate/cap (the effect only
				; refreshes on an aux-state transition).
				exhibTier = ((currentExhibitionistExposure * 3.0) as int) + 1
			endIf

			int oldExhibState = GetArousalEffectFncAux(currentObserver, exhibitionistEff)
			if (oldExhibState != exhibTier)
				if exhibTier == 0
					SetArousalEffectFunction(currentObserver, exhibitionistEff, 1, exhibHalfTime, 0.0, 0)
				else
					; More exposed -> both a higher cap and a faster climb.
					SetArousalEffectFunction(currentObserver, exhibitionistEff, 2, currentExhibitionistCount * exhibIncrease * currentExhibitionistExposure, exhibMax * currentExhibitionistExposure, exhibTier)
				endIf
			endIf
		endIf

		currentObserver = who
		if who == none
			return
		endIf

		currentNakedWeight = 0.0
		currentNakedMaxExposure = 0.0
		currentSeesNaked = false
		currentSeesNakedPref = false
		currentExhibitionistCount = 0
		currentExhibitionistExposure = 0.0
		; Dynamic exhibitionism: mirror AND's modesty ranks into the exhibitionist
		; faction (rank 1 = auto-managed; manual rank-0 flags are never touched)
		; before reading it -- see slaFrameworkScr.UpdateDynamicExhibitionist.
		if useModestyRanks && main.IsANDInstalled
			slaUtil.UpdateDynamicExhibitionist(who, modestyThreshold)
		endIf
		; Only exhibitionists feed the exposure check (avoids ~8 faction reads per
		; non-exhibitionist). Exposure is graduated via Advanced Nudity Detection
		; when present, else the binary naked flag -- see slaMainScr.GetExposureLevel.
		currentObserverExhibiting = slaUtil.IsActorExhibitionist(who)
		if currentObserverExhibiting
			currentExhibitionistExposure = main.GetExposureLevel(who)
			currentObserverExhibiting = currentExhibitionistExposure > 0.0
		endIf
	endFunction
	
	function UpdateObserver(Actor observer, Actor observed)
		; Exhibitionism: a naked exhibitionist (the observer) gains arousal from each
		; nearby onlooker (the observed) who is attracted to them. Counted before the
		; nudity checks below so it does not depend on the onlooker being naked.
		if currentObserverExhibiting && !observed.HasKeyword(kActorTypeCreature)
			int audiencePreference = slaUtil.GetGenderPreference(observed)
			if audiencePreference == 2 || audiencePreference == observer.GetLeveledActorBase().GetSex()
				currentExhibitionistCount += 2
			else
				currentExhibitionistCount += 1
			endIf
		endIf

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

		; Graded exposure of the observed actor, cached once per cycle by
		; slaMainScr.IsActorNaked (1.0 without AND / for pre-cache saves).
		float exposureScale = 1.0
		if scaleNakedByExposure
			exposureScale = StorageUtil.GetFloatValue(observed, "SLAroused.NakedExposure", 1.0)
		endIf

		currentSeesNaked = true
		if exposureScale > currentNakedMaxExposure
			currentNakedMaxExposure = exposureScale
		endIf
		int genderPreference = slaUtil.GetGenderPreference(observer)
		if genderPreference == 2 || genderPreference == observed.GetLeveledActorBase().GetSex()
			currentSeesNakedPref = true
			currentNakedWeight += 2.0 * exposureScale
		else
			currentNakedWeight += 1.0 * exposureScale
		endIf
	endFunction
endState

event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	if afSleepStartTime > 0.0
		sleepStartTime = afSleepStartTime
	else
		sleepStartTime = Utility.GetCurrentGameTime()
	endIf
endEvent

event OnSleepStop(bool abInterrupted)
	if !isEnabled || sleepEff < 0
		return
	endIf

	Actor who = main.playerRef
	if who == none
		sleepStartTime = 0.0
		return
	endIf

	if sleepStartTime <= 0.0
		sleepStartTime = 0.0
		return
	endIf

	if sleepMinHours > 0.0
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
