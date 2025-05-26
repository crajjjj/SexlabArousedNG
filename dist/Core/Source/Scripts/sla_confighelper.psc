;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname sla_ConfigHelper Extends Quest Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0()
;BEGIN CODE
;
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

function resetAllQuests()
	RegisterForSingleUpdate(6)
endFunction

Event OnUpdate()

	if(PlayerRef == none)
		PlayerRef = Game.getPlayer()
	endif
	if(!PlayerRef.Is3dLoaded())
		debug.trace("Player 3d Not Loaded, waiting a bit")
		RegisterForSingleUpdate(2)
		return
	endif
	ResetQuests()
	;Debug.notification("SexLab Aroused upgraded to version " + getVersion())

endEvent

function ResetQuests()
	debug.trace("Sla resetting all quests")
	;slaConfigScr slaConfig = Quest.GetQuest("sla_Config") As slaConfigScr
	slaMainScr slaMain = Quest.GetQuest("sla_Main") As slaMainScr
	slaInternalScr slaInternal = Quest.GetQuest("sla_Internal") As slaInternalScr
	slaFrameworkScr slaFramework = Quest.GetQuest("sla_Framework") As slaFrameworkScr

	;slaConfig.ResetToDefault()

	slaMain.Stop()
;	slaConfig.Stop()
	slaInternal.Stop()
	slaFramework.Stop()
	
	Utility.Wait(5.0)
	
	slaMain.Reset()
;	slaConfig.Reset()
	slaInternal.Reset()
	slaFramework.Reset()
	debug.notification("Sexlab Aroused is ready to use")
	
endFunction


Actor Property PlayerRef Auto


