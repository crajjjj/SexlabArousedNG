Scriptname slaInternalScr extends slaFrameworkScr  

Event OnInit()
	Maintenance()
EndEvent

Function Maintenance()
	slaMain.Maintenance()
EndFunction
