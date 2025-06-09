Scriptname MME_SLA extends Quest Hidden

Event OnInit()
	StorageUtil.SetIntValue(none,"MME.PluginsCheck.sla",2)
	;debug.notification(ReturnSlaQuest())
EndEvent

bool Function IsIntegraged()
	Return True
EndFunction

int Function GetActorArousal(Actor akActor)
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	return sla.GetActorArousal(akActor)
EndFunction

float Function GetActorExposure(Actor akActor)
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	return sla.GetDynamicEffectValue(akActor, "MME")
EndFunction

float Function GetActorExposureRate(Actor akActor)
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	return sla.GetActorExposureRate(akActor)
EndFunction

Function UpdateActorExposure(Actor akActor, Int value)
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	if sla.GetDynamicEffectValue(akActor,"MME") > 0
		sla.ModDynamicArousalEffect(akActor, "MME", value as float, 30.0)
		return
	endif
	sla.SetDynamicArousalEffect(akActor, "MME", 0.0, sla.DecayFunction, 0.5, 0.0)
EndFunction

Function UpdateActorExposureRate(Actor akActor, Float value)
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	sla.UpdateActorExposureRate(akActor, value)
EndFunction

Function UpdateActorOrgasmDate(Actor akActor)
	;deprecated
	slaFrameworkScr sla = Quest.GetQuest("sla_Framework") as slaFrameworkScr
	sla.UpdateActorOrgasmDate(akActor)
EndFunction

