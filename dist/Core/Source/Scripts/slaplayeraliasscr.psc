Scriptname slaPlayerAliasScr extends ReferenceAlias  

slaInternalScr Property slaUtil Auto

Event OnPlayerLoadGame()
	slax.info("slaPlayerAliasScr OnPlayerLoadGame()")
	slaUtil.Maintenance()
	slaUtil.slaMain.OnPlayerLoadGame()
EndEvent