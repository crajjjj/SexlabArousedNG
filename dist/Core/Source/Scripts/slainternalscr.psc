Scriptname slaInternalScr extends slaFrameworkScr  

Event OnInit()
	slax.Info("slaInternalScr onInit")
	RegisterForSingleUpdate(5)
EndEvent

Function Maintenance()
	slaMain.Maintenance()
EndFunction

Event OnUpdate()
	slax.Info("slaInternalScr OnUpdate: calling Maintenance()")
	Maintenance()
EndEvent