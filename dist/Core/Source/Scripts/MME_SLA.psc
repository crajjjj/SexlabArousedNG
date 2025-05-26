Scriptname MME_SLA extends Quest Hidden

Event OnInit()
	StorageUtil.SetIntValue(none,"MME.PluginsCheck.sla",2)
	;debug.notification(ReturnSlaQuest())
EndEvent

bool Function IsIntegraged ()
	Return True
EndFunction

int Function GetActorArousal(Actor akActor)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	return sla.GetActorArousal(akActor)
EndFunction

float Function GetActorExposure(Actor akActor)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	return sla.GetDynamicEffectValue(akActor, "MME")
EndFunction

float Function GetActorExposureRate(Actor akActor)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	return sla.GetActorExposureRate(akActor)
EndFunction

Function UpdateActorExposure(Actor akActor, Int value)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	sla.ModDynamicArousalEffect(akActor, "MME", value as float, 100.0)
	sla.SetDynamicArousalEffect(akActor, "MME", 0.0, sla.DecayFunction, 0.5, 0.0)
EndFunction

Function UpdateActorExposureRate(Actor akActor, Float value)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	sla.UpdateActorExposureRate(akActor, value)
EndFunction

Function UpdateActorOrgasmDate(Actor akActor)
	slaFrameWorkScr sla = Quest.GetQuest("sla_Framework") as slaFrameWorkScr
	sla.UpdateActorOrgasmDate(akActor)
EndFunction

