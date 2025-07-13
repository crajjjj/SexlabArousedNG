ScriptName OArousedScript Extends Quest
{This is a stubbed version of OAroused main script that redirects external mod requests to use OSLAroused}

float Property ScanDistance = 5120.0 AutoReadOnly

bool Property IsSLOArousedNGStub = true Auto

slaConfigScr Property slaConfig Auto
slaMainScr Property slaMain Auto

;formid 010A5BA8
oarousedscript Function GetOAroused() Global
	return game.GetFormFromFile(0x0A5BA8, "SexLabAroused.esm") as OArousedScript
EndFunction

Keyword Property EroticArmor
    Keyword Function Get() 
        Return slaConfig.GetEroticKeyword()
    EndFunction
EndProperty

float Function GetArousal(Actor act)
    return slaInternalModules.GetArousal(act)
EndFunction

float Function ModifyArousal(Actor act, float by)
    if !act
        return 0.0
    endif
    slax.info("OArousedScript ModifyArousal.Act: " + act.GetLeveledActorBase().GetName() + ".Value"+ by)
    return slaMain.defaultPlugin.ModExposureLegacy(act,by)
EndFunction

float Function SetArousal(Actor act, float value, bool updateAccessTime = true)
    if !act
        return 0.0
    endif
    slax.info("OArousedScript SetArousal.Act: " + act.GetLeveledActorBase().GetName() + ".Value"+ value)
    if value == 0.0
       return slaMain.defaultPlugin.ModExposureLegacy(act,-100)
    endif
    return slaMain.defaultPlugin.ModExposureLegacy(act, value)
EndFunction