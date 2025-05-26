Scriptname slaResetScr extends activemagiceffect  

Int Property Dummy  Auto  


Event OnEffectStart(Actor akTarget, Actor akCaster)

	Debug.Notification("SLAX - attempting reset - please wait...")

	Spell slaCloakSpell = Game.GetFormFromFile(0x0204DE5E, "SexLabAroused.esm") As Spell
	Spell slaDesireSpell = Game.GetFormFromFile(0x02038059, "SexLabAroused.esm") As Spell
	Spell slaResetSpell = Game.GetFormFromFile(0x02083BFD, "SexLabAroused.esm") As Spell
	
    Actor player = Game.GetPlayer()
	player.RemoveSpell(slaResetSpell)
	player.RemoveSpell(slaCloakSpell)
	player.RemoveSpell(slaDesireSpell)
	
	Utility.Wait(15.0)
	
	Debug.Notification("SLAX - resetting quests")
	
	slaConfigScr slaConfig = Quest.GetQuest("sla_Config") As slaConfigScr
	slaMainScr slaMain = Quest.GetQuest("sla_Main") As slaMainScr
	slaInternalScr slaInternal = Quest.GetQuest("sla_Internal") As slaInternalScr
	slaFrameworkScr slaFramework = Quest.GetQuest("sla_Framework") As slaFrameworkScr

	slaConfig.ResetToDefault()

	slaMain.Stop()
	slaInternal.Stop()
	slaFramework.Stop()
	
	Utility.Wait(10.0)
	
	slaMain.Reset()
	slaInternal.Reset()
	slaFramework.Reset()
	
	slaMain.slaUtil = slaInternal

   	Utility.Wait(5.0)

	Debug.Notification("SLAX - reset complete")
    
EndEvent
