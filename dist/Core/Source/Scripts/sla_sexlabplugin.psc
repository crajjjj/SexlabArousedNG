Scriptname sla_SexlabPlugin Extends sla_PluginBase

Actor Property playerRef Auto
sla_DefaultPlugin Property defaultPlugin Auto
sla_DDPlugin Property ddPlugin Auto

SexLabFramework sexLab

bool function CheckDependencies()
	return Game.GetModByName("SexLab.esm") != 255
endFunction

bool function HasSLSO()
    return 255 != Game.GetModByName("SLSO.esp")  
endFunction

event OnEndState()
	sexLab = Game.GetFormFromFile(0x000D62, "SexLab.esm") as SexLabFramework
endEvent

event OnStageStart(int tid, bool hasPlayer)
endEvent

event OnAnimationEnd(int tid, bool hasPlayer)
endEvent

event OnSexLabOrgasm(Form who, int enjoyment, int orgasms)
endEvent

Float Function GetLewd(Actor who)
    Return SexLab.Stats.GetSkillLevel(who, "Lewd", 0.3)
EndFunction

Float Function GetAnimationDuration(sslThreadController thisThread)
    If !thisThread
        Return -1.0
    EndIf
    
    Float[] timeList =  thisThread.Timers
    
    Float duration = 0.0
    Float stageTimer = 0.0
    
    Int stageCount = thisThread.animation.StageCount()
    
    Int ii = 0
    While (ii < timeList.length && ii < stageCount)
        If ii == stageCount - 1
            stageTimer = timeList[4]
        elseif ii < 3
            stageTimer = timeList[ii]
        Else
            stageTimer = timeList[3]
        EndIf
        
        duration += stageTimer
        ii += 1
	EndWhile
	
    Return duration
EndFunction

bool function CanOtherActorGiveOrgasm(Actor[] actorList, Actor except, bool anal, bool oral, bool breasts)
	int i = actorList.Length
	while i > 0
		i -= 1
		if actorList[i] != except && ddPlugin.CanGiveOrgasm(actorList[i], anal, oral, breasts)
			return true
		endIf
	endWhile
	return false
endFunction

bool[] Function FindActorWillOrgasm(sslThreadController thisThread, sslBaseAnimation animation, Actor[] actorList)
	slax.Info("SLAX - FindCanOrgasm - animation has tags " + animation.GetTags())
    
    Bool hasOral         = animation.HasTag("Oral")
    Bool hasAnal         = animation.HasTag("Anal")
    Bool hasVaginal      = animation.HasTag("Vaginal")
    Bool hasMasturbation = animation.HasTag("Masturbation")
    Bool hasBlowjob      = animation.HasTag("Blowjob")
    Bool hasBoobjob      = animation.HasTag("Boobjob")
    Bool hasHandjob      = animation.HasTag("Handjob")
    Bool hasFootjob      = animation.HasTag("Footjob")
    Bool has69           = animation.HasTag("69")
    Bool hasFisting      = animation.HasTag("Fisting")
    Bool hasCunnilingus  = animation.HasTag("Cunnilingus")
    Bool hasLesbian      = animation.HasTag("Lesbian")
    
    bool canMaleOrgasm = hasAnal || hasVaginal || hasMasturbation || has69 || hasBlowjob || hasBoobjob || hasHandjob || hasFootjob || hasOral
    slax.Info("SLAX - FindCanOrgasm - MALE " + canMaleOrgasm)
    
    bool canFemaleOrgasm = hasAnal || hasVaginal || hasMasturbation || has69 || hasFisting || hasCunnilingus || hasLesbian
    slax.Info("SLAX - FindCanOrgasm - FEMALE " + canFemaleOrgasm)
    
    bool canCreatureOrgasm = canMaleOrgasm
    slax.Info("SLAX - FindCanOrgasm - CREATURE " + canMaleOrgasm)
    	
	bool[] willOrgasm = PapyrusUtil.BoolArray(actorList.length)
    	
	int i = actorList.Length
	while i > 0
		i -= 1
	    int animationGender = animation.GetGender(i)
		actor who = actorList[i]
    	string actorName = who.GetLeveledActorBase().GetName()
		slax.Info("SLAX - FindActorWillOrgasm - " + who.GetLeveledActorBase().GetName() + " in a position with gender #" + animationGender)

		if !ddPlugin.CanRecieveOrgasm(who, hasAnal)
			slax.Info("SLAX - FindActorWillOrgasm - " + actorName + " cannot orgasm due to chastity")
		else
			bool isVictim = thisThread.IsVictim(who)
			bool canOrgasm = true

			if hasAnal && isVictim
				int chance = sexLab.GetSkillLevel(who, "Anal") * 5
				if chance < Utility.RandomInt(0, 100)
					canOrgasm = false
					willOrgasm[i] = false
					slax.Info("SLAX - FindActorWillOrgasm - " + actorName + " in victim in anal and did not passed skill check - can orgasm " + willOrgasm[i])
				endIf
			endIf

			if canOrgasm
				if 0 == animationGender; Male animation slot
					if canMaleOrgasm && (CanOtherActorGiveOrgasm(actorList, who, hasAnal, hasBlowjob, hasBoobjob) || hasMasturbation)
						willOrgasm[i] = true
					else
						willOrgasm[i] = false
					endIf
					slax.Info("SLAX - FindActorWillOrgasm - " + actorName + " in a male position - can orgasm " + willOrgasm[i])
				elseIf 1 == animationGender; Female animation slot
					if canFemaleOrgasm && (CanOtherActorGiveOrgasm(actorList, who, false, hasCunnilingus, false)  || hasMasturbation)
						willOrgasm[i] = true
					else
						willOrgasm[i] = false
					endIf
					slax.Info("SLAX - FindActorWillOrgasm - " + actorName + " in a female position - can orgasm " + willOrgasm[i])
				else ; Creature animation slot
					if canCreatureOrgasm && (CanOtherActorGiveOrgasm(actorList, who, hasAnal, hasBlowjob, hasBoobjob) || hasMasturbation)
						willOrgasm[i] = true
					else
						willOrgasm[i] = false
					endIf
					slax.Info("SLAX - FindActorWillOrgasm - " + actorName + " is in a creature position - can orgasm " + willOrgasm[i])
				endIf
			endIf
		endIf
	endWhile
    
    Return willOrgasm
EndFunction

Actor currentObserver = none
bool isSeeingSex = false
int sexEff = -1
int fatigueEff = -1
int traumaEff = -1

bool alwaysCheckOrgasm = false
float sexEffMax = 50.0
float sexHalfTime = 0.04166666 ; 1.0 / 24.0
float sexPerStage = 5.0

float traumaHalfTime = 0.5
float traumaBase = 10.0
float traumaLewdRate = 1.0

float fatigueHalfTime = 0.5
float fatigueBase = 5.0

float function GetOptionValue(int optionId)
	if optionId == 0
		return sexEffMax
	elseIf optionId == 1
		return sexHalfTime * 24.0
	elseIf optionId == 2
		return alwaysCheckOrgasm as float
	elseIf optionId == 3
		return traumaHalfTime
	elseIf optionId == 4
		return traumaBase
	elseIf optionId == 5
		return traumaLewdRate
	elseIf optionId == 6
		return fatigueBase
	elseIf optionId == 7
		return fatigueHalfTime
	elseIf optionId == 8
		return sexPerStage
	endIf
endFunction

function OnUpdateOption(int optionId, float value)
	if optionId == 0
		sexEffMax = value
	elseIf optionId == 1
		sexHalfTime = value / 24.0
	elseIf optionId == 2
		alwaysCheckOrgasm = value as bool
	elseIf optionId == 3
		traumaHalfTime = value
	elseIf optionId == 4
		traumaBase = value
	elseIf optionId == 5
		traumaLewdRate = value
	elseIf optionId == 6
		fatigueBase = value
	elseIf optionId == 7
		fatigueHalfTime = value
	elseIf optionId == 8
		sexPerStage = value
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
		RegisterForPerodicUpdates()
		RegisterForLOSUpdates()
		; use the same events with and without slso since slso also sends regular events and they contain more information  
		RegisterForModEvent("SexLabOrgasm", "OnSexLabOrgasm")
		RegisterForModEvent("HookStageStart", "OnStageStart")
		RegisterForModEvent("HookOrgasmEnd", "OnAnimationEnd")

		sexEff = RegisterEffect("Sex", "$SLA_Effect_Sex", "$SLA_Effect_SexDesc")
		fatigueEff = RegisterEffect("Fatigue", "$SLA_Effect_Fatigue", "$SLA_Effect_FatigueDesc")
		traumaEff = RegisterEffect("Trauma", "$SLA_Effect_Trauma", "$SLA_Effect_TraumaDesc")
	endFunction
	
	function AddOptions()
		AddOption("$SLA_Effect_SexCat", "$SLA_Effect_SexMax", "$SLA_Effect_SexMaxDesc", 50.0)
		AddOptionEx("$SLA_Effect_SexCat", "$SLA_Effect_SexHalfTime", "$SLA_Effect_SexHalfTimeDesc", 1.0 / 24.0, 0.1, 24.0, 0.1, "{1} hours")
		AddToggleOption("$SLA_Effect_SexCat", "$SLA_AlwaysCheckOrgasm", "$SLA_AlwaysCheckOrgasmDesc", false)
		AddOptionEx("$SLA_Effect_TraumaCat", "$SLA_Effect_TraumaHalfTime", "$SLA_Effect_TraumaHalfTimeDesc", 0.5, 0.0, 7.0, 0.1, "{1} days")
		AddOption("$SLA_Effect_TraumaCat", "$SLA_Effect_TraumaBase", "$SLA_Effect_TraumaBaseDesc", 10.0)
		AddOptionEx("$SLA_Effect_TraumaCat", "$SLA_Effect_TraumaLewd", "$SLA_Effect_TraumaLewdDesc", 1.0, 0.0, 10.0, 0.1, "{1}")
		AddOption("$SLA_Effect_FatigueCat", "$SLA_Effect_FatigueBase", "$SLA_Effect_FatigueBaseDesc", 5.0)
		AddOptionEx("$SLA_Effect_FatigueCat", "$SLA_Effect_FatigueHalfTime", "$SLA_Effect_FatigueHalfTimeDesc", 0.5, 0.0, 7.0, 0.1, "{1} days")
		AddOption("$SLA_Effect_SexCat", "$SLA_Effect_SexPerStage", "$SLA_Effect_SexPerStageDesc", 5.0)
	endFunction

	function DisablePlugin()
		parent.DisablePlugin()
		UnregisterEffect("Sex")
		UnregisterEffect("Fatigue")
		UnregisterEffect("Trauma")
		UnregisterForAllModEvents()	
	endFunction
	
	function UpdateActor(Actor who, bool fullUpdate)
		if currentObserver != none
			; 0 - none 1 - sees sex 2 - participating sex 3 - decay 
			int oldState = GetArousalEffectFncAux(currentObserver, sexEff)
			if SexLab.IsActorActive(currentObserver)
				if oldState != 2
					SetLinearArousalEffect(currentObserver, sexEff, 20.0 * 24.0, sexEffMax, 2)
				endIf
			elseIf isSeeingSex
				if oldState != 1
					SetLinearArousalEffect(currentObserver, sexEff, 20.0 * 24.0, sexEffMax, 1)
				endIf
			elseIf oldState != 0 && oldState != 3
				SetArousalDecayEffect(currentObserver, sexEff, sexHalfTime, 0.0, 3)
			endIf
		endIf
		
		currentObserver = who
		isSeeingSex = false
		if who == none
			return
		endIf
		
	endFunction
	
	function UpdateObserver(Actor observer, Actor observed)
		if (SexLab.IsActorActive(observed))
			isSeeingSex = true
		endIf
	endFunction

	event OnStageStart(int tid, bool hasPlayer)
		slax.Info("SLAX - OnStageStart - " + tid + " : " + hasPlayer)
		sslThreadController thisThread = SexLab.GetController(tid)
		Actor[] actorList = thisThread.Positions
	
		if (actorList.Length < 1)
			return
		endIf
		
		float sexEffectMod = sexPerStage

		if thisThread.animation.HasTag("Foreplay")
			sexEffectMod *= 2.0
		endIf

		int i = 0
		while i < actorList.length
			ModArousalEffectValue(actorList[i], sexEff, sexEffectMod, sexEffMax)
			i += 1
		endWhile
	endEvent
	
	event OnAnimationEnd(int tid, bool hasPlayer)
		slax.Info("SLAX - OnAnimationEnd - " + tid + " : " + hasPlayer)
		
		sslThreadController thisThread = SexLab.GetController(tid)
		Actor[] actorList = thisThread.Positions
	
		If (actorList.Length < 1)
			Return
		EndIf

		Actor[] victims = thisThread.Victims
		sslBaseAnimation animation = thisThread.animation
		
		int i = victims.Length
		if traumaHalfTime != 0.0
			while i > 0
				i -= 1
				if victims[i] == PlayerRef
					self.main.wasPlayerRaped = True
				endIf
				float delta = traumaLewdRate * GetLewd(victims[i]) - traumaBase
				float limit = 50.0
				if delta < 0.0
					limit = -50.0
				endIf
				ModArousalEffectValue(victims[i], traumaEff, delta, limit)
				SetArousalDecayEffect(victims[i], traumaEff, traumaHalfTime, 0.0)
			endWhile
		endIf
		
		float animationDuration = GetAnimationDuration(thisThread)
		float timeFactor = thisThread.TotalTime / animationDuration
		slax.Info("SLAX - OnAnimationEnd - animationDuration " + animationDuration + ", totalTime " + thisThread.TotalTime + ", timeFactor " + timeFactor)

		bool[] willOrgasm
		
		bool applyFatigue = fatigueHalfTime != 0.0 && (thisThread.IsOral || thisThread.IsVaginal || thisThread.IsAnal)
		bool checkForOrgasm = true
		; Use SexLabOrgasm event instead
		if SexLab.Config.SeparateOrgasms || HasSLSO()
			checkForOrgasm = false
		else
			willOrgasm = FindActorWillOrgasm(thisThread, animation, actorList)
		endIf

		i = actorList.Length
		while i
			i -= 1
			
			if applyFatigue
				ModArousalEffectValue(actorList[i], fatigueEff, -fatigueBase, -fatigueBase * 10.0)
				SetArousalDecayEffect(actorList[i], fatigueEff, fatigueHalfTime, 0)
			endIf

			if checkForOrgasm && willOrgasm[i]
				defaultPlugin.OnOrgasm(actorList[i], timeFactor * 20.0)
			endIf
			
			ForceUpdateArousal(actorList[i])
		endWhile
	endEvent

	event OnSexLabOrgasm(Form who, int enjoyment, int orgasms)
		Actor actorWho = who as Actor

		if !who || (!SexLab.Config.SeparateOrgasms && !HasSLSO())
			return
		endIf

		if alwaysCheckOrgasm
			sslThreadController thisThread = SexLab.GetActorController(actorWho)
			Actor[] actorList = thisThread.Positions
			sslBaseAnimation animation = thisThread.animation
			if thisThread != none
				bool[] willOrgasm = FindActorWillOrgasm(thisThread, animation, actorList)
				int i = actorList.Find(actorWho)
				if i != -1 && willOrgasm[i] == false
					return
				endIf
			endIf
		endIf

		defaultPlugin.OnOrgasm(actorWho, enjoyment)
		ForceUpdateArousal(actorWho)
	endEvent
endState