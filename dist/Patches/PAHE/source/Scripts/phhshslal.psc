scriptName phhshslal extends Quest

;-- Properties --------------------------------------
Actor[] property actorList
	Actor[] function get()

		if !_actorList
			_actorList = new Actor[20]
			actorsNumber = 0
		endIf
		return _actorList
	endFunction
endproperty
Int property actorsNumber = 0 auto hidden

;-- Variables ---------------------------------------
Actor[] _actorList

;-- Functions ---------------------------------------

; Skipped compiler generated GetState

; Skipped compiler generated GotoState

Int function GetActorArousal(actor a)

	slaframeworkscr pslaMainScr = game.GetFormFromFile(272655, "SexLabAroused.esm") as slaframeworkscr
	if pslaMainScr != none
		return pslaMainScr.GetActorArousal(a)
	else
		return 0
	endIf
endFunction

function UnlockScan(Int myLockNum)

	slamainscr pslaMainScr = game.GetFormFromFile(273762, "SexLabAroused.esm") as slamainscr
	if pslaMainScr != none
		pslaMainScr.UnlockScan(myLockNum)
	endIf
endFunction

Bool function GetActors(Int myLockNum, Float c)

	slamainscr pslaMainScr = game.GetFormFromFile(273762, "SexLabAroused.esm") as slamainscr
	if pslaMainScr != none
		Actor[] myActors = pslaMainScr.getLoadedActors(myLockNum)
		;slax.Info("PHH - GetActors: c: " + c + "")
		;slax.Info("PHH - GetActors: getLoadedActors: " + myActors.Length + " actors")
		;slax.Info("PHH - GetActors: getLoadedActors: " + self.actorList.length + " actors")
		Int i = 0
		Int n = self.actorList.length
		Int l = myActors.length
		while i as Float < c && i < n && i < l
			;slax.Info("PHH - GetActors: loop: " + i + " -(i)" + n + "-(n)" + c + "-(c)" + l + "-(l)")
			self.actorList[i] = myActors[i]
			i += 1
		endWhile
		actorsNumber = i
		return true
	else
		debug.Notification("HSH: SL Aroused main quest not found!")
		return false
	endIf
endFunction

Bool function HasSlal()

	return true
endFunction
