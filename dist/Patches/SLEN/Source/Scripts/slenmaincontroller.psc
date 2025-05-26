Scriptname SLENMainController extends Quest


Quest Property SLENDialogueQuest Auto
SLENScannerScript Property SLENScannerQuest Auto
Message Property SLENMsgSleepEvent1 Auto
Message Property SLENMsgSleepEvent2 Auto
Message Property SLENMsgSleepEvent3 Auto
Message Property SLENMsgSleepEvent4 Auto
slaFrameworkScr Property sla_Framework Auto
Quest Property SLENDialogueTrainers Auto
Bool Property UseGenderPreference Auto
Actor Property PlayerREF Auto
Faction Property SLENForcedGenderFaction Auto
Faction Property SexLabGenderFaction Auto
Keyword Property ActorTypeNPC Auto
Message Property SLENMsgDragonKillEvent Auto
Message Property SLENMsgDungeonClearedEvent Auto
Faction Property SLENBlockAllFaction Auto
Spell Property Rested Auto
Spell Property WellRested Auto
Spell Property MarriageRested Auto
Spell Property doomLoverAbility Auto
Message Property MarriageRestedMessage Auto
Message Property SLENMsgDragonKillEventNoPC Auto
Message Property SLENMsgDungeonClearedEventNoPC Auto
WordOfPower Property SLENWordVibrate Auto
WordOfPower Property SLENWordRumble Auto
WordOfPower Property SLENWordShake Auto
Faction Property SLENPlayerLoveIncreaseFaction Auto
Message Property SLENMsgTeachToTWord1 Auto
Message Property SLENMsgTeachToTWord2 Auto
Message Property SLENMsgTeachToTWord3 Auto
Quest Property SLENSexAddictionQuest Auto
SLENSOSIntegrationScript Property SLENSOSIntegrationQuest Auto
Quest Property SLENLoversPerksQuest Auto
Quest Property SLENShoutVoicesQuest Auto        ; deprecated after 20150825
Faction Property JobTrainerFaction Auto
Faction Property JobTrainerMarksmanFaction Auto
Faction Property JobTrainerHeavyArmorFaction Auto
Faction Property JobTrainerRestorationFaction Auto
Faction Property JobTrainerSmithingFaction Auto
Faction Property JobTrainerSpeechcraftFaction Auto
Faction Property JobTrainerTwoHandedFaction Auto
Faction Property JobTrainerEnchantingFaction Auto
SLENHotkeyScript Property SLENHotkeyQuest Auto
FormList Property SLENRecentPartnersList Auto
Quest Property SLENDBQuest Auto
Sound Property SLENSNDRRUp Auto
Sound Property SLENSNDRRLover Auto
Quest Property MQ104 Auto
Perk Property T01DibellaReward Auto
Quest Property SLENDialogueTrainers2 Auto
Message[] Property SLENRRIncreaseNotes Auto
Message[] Property SLENSexChangeNotes Auto
Spell Property SLENDragonKillWitnessSpell Auto
Message Property SLENMsgSleepEvent Auto
Quest Property SLENLocChangeArousalRecalcQuest Auto
GlobalVariable Property SLENChangeLocScan Auto
ObjectReference Property SLENPCTrackerREF Auto
Spell Property SLENMountedExposureAb Auto


Int m_iSleepEventChance = 0
Int m_iDragonSoulEventChance = 0
Int m_iWerewolfXformEventChance = 0
Int m_iDragonSoulEventExposure = 0
Int m_iDragonKillWitnessExposure = 0
Int m_iDungeonClearedEventChance = 0
Bool m_bSOSLoaded = FALSE
Bool m_bSOSAutoGender = FALSE
Faction[] m_afactF2M
Faction[] m_afactM2F
Int m_iF2MFactionCount
Int m_iM2FFactionCount
Float m_fLastOrgyTime
Bool m_bPleasantSurpriseGivesComfort = FALSE
Int m_iPCUgliness = 0
Bool m_bLearnToTShout = FALSE
Bool m_bLoversCook = FALSE
Bool m_bDragonEventConfirmation = TRUE
Bool m_bDungeonEventConfirmation = TRUE
Bool m_bSleepEventConfirmation = TRUE
Float m_fDragonEventDelay = 5.0
Float m_fDungeonEventDelay = 5.0
Float m_fSleepEventDelay = 5.0
Bool m_bDibellasRefugeState = FALSE
Float m_fRRIncreaseDifficulty = 1.0
Float m_fCharmDifficulty = 1.0
Float m_fCharmXPFactor = 1.0
Bool m_bAllowNonUnique = FALSE
Actor[] m_aLoveQueueActors
Int[] m_aLoveQueueValues
Int[] m_aLoveQueueChances
Int m_iLoveQueuePointer = 0
Bool m_bProcessingLoveQueue = FALSE
Int m_iOrgyMinGroupSize = 2
Int m_iOrgyMaxGroupSize = 5
Bool m_bOrgyAllowAggressive = TRUE
Bool m_bForceCHTargetGender = FALSE
Bool m_bProcessingCrossHairRef = FALSE
Bool m_bOrgyAllowFurniture = FALSE
Int[] m_aiOptionCountersGG      ; for Genetic Girls
Int[] m_aiOptionCountersMM      ; for Macho Males
Int[] m_aiOptionCountersSM      ; for Shemales
Int[] m_aiOptionCountersPM      ; for Pussy-males
Int[] m_aiOptionAnimLevels
Int m_iOptionPage1Length = 10
Int[] m_aiLocationCache
Float[] m_afScanTimesCache
Int m_iCurrentScanCellID
Int m_iMountedExposure


Bool Property ModState
        Bool Function Get()
                Return Parent.IsRunning()
        EndFunction
        Function Set(Bool newValue)
                If (newValue)
                        If (!Parent.IsRunning())
                                Parent.Start()
                        EndIf
                        If (m_aLoveQueueActors.Length == 0)
                                m_aLoveQueueActors = New Actor[32]
                                m_aLoveQueueValues = New Int[32]
                                m_aLoveQueueChances = New Int[32]
                                m_iLoveQueuePointer = 0
                                m_bProcessingLoveQueue = FALSE
                        EndIf
                        If (m_aiOptionAnimLevels.Length == 0)
                                InitSexOptionSettings()
                        EndIf
                        If (m_aiLocationCache.Length == 0)
                                m_aiLocationCache = New Int[128]
                                m_afScanTimesCache = New Float[128]
                        EndIf
                Else
                        Bool[] ab1 = New Bool[20]
                        Bool[] ab2 = New Bool[20]
                        SetSOSData(none, ab1, ab2)
                        UnregisterForSleep()
                        m_iSleepEventChance = 0
                        m_iWerewolfXformEventChance = 0
                        m_iDragonSoulEventChance = 0
                        m_iDragonSoulEventExposure = 0
                        m_iDragonKillWitnessExposure = 0
                        m_iDungeonClearedEventChance = 0
                        m_bLearnToTShout = FALSE
                        UseGenderPreference = TRUE
                        MountedExposure = 0
                        m_bDibellasRefugeState = FALSE
                        m_bForceCHTargetGender = FALSE
                        UnregisterForCrosshairRef()
                        CheckRegisterForStats()
                        If (SLENLoversPerksQuest.IsRunning())
                                SLENLoversPerksQuest.Stop()
                        EndIf
                        If (SLENDialogueQuest.IsRunning())
                                (SLENDialogueQuest As SLENDialogueTools).Stop()
                        EndIf
                        If (SLENDialogueTrainers.IsRunning())
                                CheckDLCTrainers(FALSE)
                                SLENDialogueTrainers.Stop()
                        EndIf
                        If (SLENScannerQuest.IsRunning())
                                SLENScannerQuest.Stop()
                        EndIf
                        If (SLENSexAddictionQuest.IsRunning())
                                SLENSexAddictionQuest.Stop()
                        EndIf
                        If (SLENHotkeyQuest.IsRunning())
                                SLENHotkeyQuest.Stop()
                        EndIf
                        If (SLENDBQuest.IsRunning())
                                SLENDBQuest.Stop()
                        EndIf
                        If (Parent.IsRunning())
                                Parent.Stop()
                        EndIf
                EndIf
        EndFunction
EndProperty

Bool Property DialogueState
        Bool Function Get()
                Return SLENDialogueQuest.IsRunning()
        EndFunction
        Function Set(Bool newValue)
                If (newValue)
                        If (!SLENDialogueQuest.IsRunning())
                                (SLENDialogueQuest As SLENDialogueTools).Start()
                        EndIf
                        (SLENDialogueQuest As SLENDialogueTools).PCUgliness = m_iPCUgliness
                Else
                        If (SLENDialogueQuest.IsRunning())
                                (SLENDialogueQuest As SLENDialogueTools).Stop()
                        EndIf
                EndIf
        EndFunction
EndProperty

Bool Property TrainerState
        Bool Function Get()
                Return SLENDialogueTrainers.IsRunning()
        EndFunction
        Function Set(Bool newValue)
                If (newValue)
                        If (!SLENDialogueTrainers.IsRunning())
                                SLENDialogueTrainers.Start()
                                CheckDLCTrainers(SLENDialogueTrainers.IsRunning())
                        EndIf
                Else
                        If (SLENDialogueTrainers.IsRunning())
                                SLENDialogueTrainers.Stop()
                                CheckDLCTrainers(SLENDialogueTrainers.IsRunning())
                        EndIf
                EndIf
        EndFunction
EndProperty

Int Property TrainerDialogueState
        Int Function Get()
                If (SLENDialogueTrainers.IsRunning())
                        Return 1
                ElseIf (SLENDialogueTrainers2.IsRunning())
                        Return 2
                EndIf
                Return 0
        EndFunction
        Function Set(Int newValue)
                If (newValue != Self.TrainerDialogueState)
                        If (newValue == 2)
                                If (SLENDialogueTrainers.IsRunning())
                                        SLENDialogueTrainers.Stop()
                                EndIf
                                If (!SLENDialogueTrainers2.IsRunning())
                                        (SLENDialogueTrainers2 As SLENDialogueTools).Start()
                                EndIf
                        ElseIf (newValue == 1)
                                If (SLENDialogueTrainers2.IsRunning())
                                        (SLENDialogueTrainers2 As SLENDialogueTools).Stop()
                                EndIf
                                If (!SLENDialogueTrainers.IsRunning())
                                        SLENDialogueTrainers.Start()
                                EndIf
                        Else
                                If (SLENDialogueTrainers.IsRunning())
                                        SLENDialogueTrainers.Stop()
                                EndIf
                                If (SLENDialogueTrainers2.IsRunning())
                                        (SLENDialogueTrainers2 As SLENDialogueTools).Stop()
                                EndIf
                        EndIf
                        CheckDLCTrainers((SLENDialogueTrainers.IsRunning() || SLENDialogueTrainers2.IsRunning()))
                EndIf
        EndFunction
EndProperty

Int Property SleepEventChance
        Int Function Get()
                Return m_iSleepEventChance
        EndFunction
        Function Set(Int newValue)
                If (newValue)
                        RegisterForSleep()
                Else
                        UnregisterForSleep()
                EndIf
                m_iSleepEventChance = newValue
        EndFunction
EndProperty

Int Property DragonSoulEventChance
        Int Function Get()
                Return m_iDragonSoulEventChance
        EndFunction
        Function Set(Int newValue)
                m_iDragonSoulEventChance = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Int Property DragonSoulEventExposure
        Int Function Get()
                Return m_iDragonSoulEventExposure
        EndFunction
        Function Set(Int newValue)
                m_iDragonSoulEventExposure = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Int Property DragonKillWitnessExposure
        Int Function Get()
                Return m_iDragonKillWitnessExposure
        EndFunction
        Function Set(Int newValue)
                m_iDragonKillWitnessExposure = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Int Property DungeonClearedEventChance
        Int Function Get()
                Return m_iDungeonClearedEventChance
        EndFunction
        Function Set(Int newValue)
                m_iDungeonClearedEventChance = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Int Property WerewolfXformEventChance
        Int Function Get()
                Return m_iWerewolfXformEventChance
        EndFunction
        Function Set(Int newValue)
                m_iWerewolfXformEventChance = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Bool Property PleasantSurpriseGivesComfort
        Bool Function Get()
                Return m_bPleasantSurpriseGivesComfort
        EndFunction
        Function Set(Bool newValue)
                m_bPleasantSurpriseGivesComfort = newValue
        EndFunction
EndProperty

Int Property PCUgliness
        Int Function Get()
                Return m_iPCUgliness
        EndFunction
        Function Set(Int newValue)
                m_iPCUgliness = newValue
                If (Self.DialogueState)
                        (SLENDialogueQuest As SLENDialogueTools).PCUgliness = m_iPCUgliness
                EndIf
        EndFunction
EndProperty

Bool Property LearnToTShout
        Bool Function Get()
                Return m_bLearnToTShout
        EndFunction
        Function Set(Bool newValue)
                m_bLearnToTShout = newValue
                CheckRegisterForStats()
        EndFunction
EndProperty

Bool Property SexAddictionQuestState
        Bool Function Get()
                Return SLENSexAddictionQuest.IsRunning()
        EndFunction
        Function Set(Bool newValue)
                If (newValue)
                        If (!SLENSexAddictionQuest.IsRunning())
                                SLENSexAddictionQuest.Start()
                        EndIf
                Else
                        If (SLENSexAddictionQuest.IsRunning())
                                SLENSexAddictionQuest.Stop()
                        EndIf
                EndIf
        EndFunction
EndProperty

Bool Property LoversCookState
        Bool Function Get()
                Return SLENLoversPerksQuest.IsRunning()
        EndFunction
        Function Set(Bool newValue)
                If (newValue)
                        If (!SLENLoversPerksQuest.IsRunning())
                                SLENLoversPerksQuest.Start()
                        EndIf
                Else
                        If (SLENLoversPerksQuest.IsRunning())
                                SLENLoversPerksQuest.Stop()
                        EndIf
                EndIf
        EndFunction
EndProperty

Bool Property DragonEventConfirmation
        Bool Function Get()
                Return m_bDragonEventConfirmation
        EndFunction
        Function Set(Bool newValue)
                m_bDragonEventConfirmation = newValue
        EndFunction
EndProperty

Bool Property DungeonEventConfirmation
        Bool Function Get()
                Return m_bDungeonEventConfirmation
        EndFunction
        Function Set(Bool newValue)
                m_bDungeonEventConfirmation = newValue
        EndFunction
EndProperty

Bool Property SleepEventConfirmation
        Bool Function Get()
                Return m_bSleepEventConfirmation
        EndFunction
        Function Set(Bool newValue)
                m_bSleepEventConfirmation = newValue
        EndFunction
EndProperty

Int Property GenderToggleHotkey
        Int Function Get()
                If (SLENHotkeyQuest.IsRunning())
                        Return SLENHotkeyQuest.HotkeyCode
                EndIf
                Return -1
        EndFunction
        Function Set(Int newValue)
                If (newValue != SLENHotkeyQuest.HotkeyCode)
                        SLENHotkeyQuest.HotkeyCode = newValue
                EndIf
        EndFunction
EndProperty

Float Property DragonEventDelay
        Float Function Get()
                Return m_fDragonEventDelay
        EndFunction
        Function Set(Float newValue)
                m_fDragonEventDelay = newValue
        EndFunction
EndProperty

Float Property DungeonEventDelay
        Float Function Get()
                Return m_fDungeonEventDelay
        EndFunction
        Function Set(Float newValue)
                m_fDungeonEventDelay = newValue
        EndFunction
EndProperty

Float Property SleepEventDelay
        Float Function Get()
                Return m_fSleepEventDelay
        EndFunction
        Function Set(Float newValue)
                m_fSleepEventDelay = newValue
        EndFunction
EndProperty

Bool Property DibellasRefugeState
        Bool Function Get()
                Return m_bDibellasRefugeState
        EndFunction
        Function Set(Bool newValue)
                m_bDibellasRefugeState = newValue
                If ((m_bDibellasRefugeState) && (PlayerREF.GetFactionRank(SLENPlayerLoveIncreaseFaction) >= 25) && (!SLENDBQuest.IsCompleted()))
                        If ((!SLENDBQuest.IsRunning()) && (PlayerREF.HasPerk(T01DibellaReward)) && (MQ104.IsCompleted()))
                                Debug.Trace("SLEN Main - Info: Starting Dibella's Champion quest (SLENDBQuest)")
                                If (SLENDBQuest.Start())
                                        Debug.Trace("SLEN Main - Info: Dibella's Champion quest started successfully")
                                Else
                                        Debug.Trace("SLEN Main - Info: Failed to start Dibella's Champion quest")
                                        SLENDBQuest.Reset()
                                EndIf
                        EndIf
                EndIf
        EndFunction
EndProperty

Float Property RRIncreaseDifficulty
        Float Function Get()
                Return m_fRRIncreaseDifficulty
        EndFunction
        Function Set(Float newValue)
                m_fRRIncreaseDifficulty = newValue
        EndFunction
EndProperty

Float Property CharmDifficulty
        Float Function Get()
                Return m_fCharmDifficulty
        EndFunction
        Function Set(Float newValue)
                m_fCharmDifficulty = newValue
        EndFunction
EndProperty

Float Property CharmXPFactor
        Float Function Get()
                Return m_fCharmXPFactor
        EndFunction
        Function Set(Float newValue)
                m_fCharmXPFactor = newValue
        EndFunction
EndProperty

Bool Property AllowNonUnique
        Bool Function Get()
                Return m_bAllowNonUnique
        EndFunction
        Function Set(Bool newValue)
                m_bAllowNonUnique = newValue
        EndFunction
EndProperty

Int Property OrgyMinGroupSize
        Int Function Get()
                Return m_iOrgyMinGroupSize
        EndFunction
        Function Set(Int newValue)
                m_iOrgyMinGroupSize = newValue
                If (m_iOrgyMinGroupSize > m_iOrgyMaxGroupSize)
                        m_iOrgyMaxGroupSize = m_iOrgyMinGroupSize
                EndIf
        EndFunction
EndProperty

Int Property OrgyMaxGroupSize
        Int Function Get()
                Return m_iOrgyMaxGroupSize
        EndFunction
        Function Set(Int newValue)
                m_iOrgyMaxGroupSize = newValue
                If (m_iOrgyMaxGroupSize < m_iOrgyMinGroupSize)
                        m_iOrgyMinGroupSize = m_iOrgyMaxGroupSize
                EndIf
        EndFunction
EndProperty

Bool Property OrgyAllowAggressive
        Bool Function Get()
                Return m_bOrgyAllowAggressive
        EndFunction
        Function Set(Bool newValue)
                m_bOrgyAllowAggressive = newValue
        EndFunction
EndProperty

Bool Property ForceGenderOfCrosshairTarget
        Bool Function Get()
                Return m_bForceCHTargetGender
        EndFunction
        Function Set(Bool newValue)
                m_bForceCHTargetGender = newValue
                If (m_bForceCHTargetGender && m_bSOSLoaded && m_bSOSAutoGender)
                        UnregisterforCrosshairRef()
                        m_bProcessingCrossHairRef = FALSE
                        RegisterforCrosshairRef()
                Else
                        UnregisterforCrosshairRef()
                EndIf
        EndFunction
EndProperty

Bool Property OrgyAllowFurniture
        Bool Function Get()
                Return m_bOrgyAllowFurniture
        EndFunction
        Function Set(Bool newValue)
                m_bOrgyAllowFurniture = newValue
        EndFunction
EndProperty

Int Property SexDialoguePageLength
        Int Function Get()
                Return m_iOptionPage1Length
        EndFunction
        Function Set(Int newValue)
                m_iOptionPage1Length = newValue
        EndFunction
EndProperty

Int Property MountedExposure
        Int Function Get()
                Return m_iMountedExposure
        EndFunction
        Function Set(Int newValue)
                m_iMountedExposure = newValue
                If ((m_iMountedExposure) && (!PlayerREF.HasSpell(SLENMountedExposureAb)))
                        PlayerREF.AddSpell(SLENMountedExposureAb)
                ElseIf ((m_iMountedExposure == 0) && (PlayerREF.HasSpell(SLENMountedExposureAb)))
                        PlayerREF.RemoveSpell(SLENMountedExposureAb)
                EndIf
        EndFunction
EndProperty


Event OnCrosshairRefChange(ObjectReference ref)
        If (m_bProcessingCrossHairRef)
                Return
        EndIf
        m_bProcessingCrossHairRef = TRUE
        If (!PlayerREF.IsInCombat())
                If (ref)
                        If ((ref As Form).HasKeyword(ActorTypeNPC))
                                ;Debug.Trace("SLEN Main - Info: Crosshair ref has ActorTypeNPC keyword")
                                Actor aActor = ref As Actor
                                If (aActor)
                                        If (!aActor.IsDead())
                                                ;Debug.Trace("SLEN Main - Info: Crosshair ref is Actor and not dead")
                                                CheckForceGender(aActor)
                                        EndIf
                                EndIf
                        EndIf
                EndIf
        EndIf
        m_bProcessingCrossHairRef = FALSE
EndEvent

Event OnSleepStop(Bool abInterrupted)
        Float fStartTime = Game.GetRealHoursPassed()
        Float fTime
        Float fWait

        If (SLENChangeLocScan.GetValue() > 0.5)
                ScanTrackerCell()
        EndIf
        If (abInterrupted)
                Debug.Trace("SLEN Main - Info: Player was woken by something, no SLEN Sleep event will occur.")
                Return
        ElseIf (PlayerREF.IsInFaction(SLENBlockAllFaction))
                Debug.Trace("SLEN Main - Info: Player is blocked from all SLEN interactions, no SLEN Sleep event will occur.")
                Return
        EndIf

        Debug.Trace("SLEN Main - Info: Rolling for Pleasant Surprise event, chance = " + (m_iSleepEventChance As String) + " (0-99 roll has to be lower)")
        Int iRoll = Utility.RandomInt(0, 99)
        If (iRoll < m_iSleepEventChance)
                If (SLENScannerQuest.IsRunning())
                        SLENScannerQuest.Stop()
                        Utility.Wait(0.1)
                EndIf
                SLENScannerQuest.SetScannerFilter(Distance = 2200.0, Arousal = 0)

                If (m_fSleepEventDelay > 0.0)
                        fTime = Game.GetRealHoursPassed()
                        fWait = m_fSleepEventDelay - ((fTime - fStartTime) * 3600.0)
                        If (fWait > 0.0)
                                Debug.Trace("SLEN Main - Info: waiting " + (fWait As String) + " seconds")
                                Utility.Wait(fWait)
                        EndIf
                EndIf

                Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", checking for nearby lovers")
                SLENScannerQuest.Start()
                Utility.Wait(0.1)
                SLENScannerQuest.ProcessReferencesFiltered(Lovers = TRUE, Allies = TRUE, Confidants = TRUE)

                Int iNrOfLovers = SLENScannerQuest.NumberOfLovers

                If (iNrOfLovers == 0)
                        Debug.Trace("SLEN Main - Info: no lover is nearby, skipping Pleasant Surprise event")
                        SLENScannerQuest.Stop()
                        Return
                EndIf

                Debug.Trace("SLEN Main - Info: Filling orgy array and determining min required genders")

                Int iNrOfAllies = SLENScannerQuest.NumberOfAllies
                Int iNrOfConfidants = SLENScannerQuest.NumberOfConfidants
                Int iActorCount = iNrOfLovers + iNrOfAllies + iNrOfConfidants

                SexLabFramework SexLab = SexLabUtil.GetAPI()
                Int iAlias
                Actor aTemp
                Int iButton = 0
                Bool bPlayerParticipates
                Bool bPlayerIsMale
                Actor[] aaLovers = SLENScannerQuest.GetLovers()
                Actor[] aaAllies = SLENScannerQuest.GetAllies()
                Actor[] aaConfidants = SLENScannerQuest.GetConfidants()

                If (m_bSleepEventConfirmation)
                        Message msgToShow
                        Int iIndex
                        iButton = 3
                        While (iButton == 3)
                                ; picking message to show
                                If (iActorCount > 4)
                                        msgToShow = SLENMsgSleepEvent
                                ElseIf (iActorCount == 1)
                                        msgToShow = SLENMsgSleepEvent1
                                ElseIf (iActorCount == 2)
                                        msgToShow = SLENMsgSleepEvent2
                                ElseIf (iActorCount == 3)
                                        msgToShow = SLENMsgSleepEvent3
                                ElseIf (iActorCount == 4)
                                        msgToShow = SLENMsgSleepEvent4
                                EndIf
                                ; setting up aliases for message
                                iAlias = 0
                                iIndex = 0
                                While ((iAlias < 4) && (iIndex < iNrOfLovers))
                                        Debug.Trace("SLEN Main - Info: forcing alias " + (iAlias As String) + " to " + aaLovers[iIndex].GetLeveledActorBase().GetName())
                                        ;aaLovers[iIndex].KeepOffsetFromActor(PlayerREF, (((iAlias % 2) * 2 - 1) * 40) As Float, (((iAlias / 2) * 2 - 1) * 40) As Float, 0.0, 0.0, 0.0, 0.0, 100.0, 50.0)
                                        (Parent.GetAlias(iAlias) As ReferenceAlias).ForceRefTo(aaLovers[iIndex] As ObjectReference)
                                        iIndex += 1
                                        iAlias += 1
                                EndWhile
                                iIndex = 0
                                While ((iAlias < 4) && (iIndex < iNrOfAllies))
                                        Debug.Trace("SLEN Main - Info: forcing alias " + (iAlias As String) + " to " + aaAllies[iIndex].GetLeveledActorBase().GetName())
                                        ;aaAllies[iIndex].KeepOffsetFromActor(PlayerREF, (((iAlias % 2) * 2 - 1) * 40) As Float, (((iAlias / 2) * 2 - 1) * 40) As Float, 0.0, 0.0, 0.0, 0.0, 100.0, 50.0)
                                        (Parent.GetAlias(iAlias) As ReferenceAlias).ForceRefTo(aaAllies[iIndex] As ObjectReference)
                                        iIndex += 1
                                        iAlias += 1
                                EndWhile
                                iIndex = 0
                                While ((iAlias < 4) && (iIndex < iNrOfConfidants))
                                        Debug.Trace("SLEN Main - Info: forcing alias " + (iAlias As String) + " to " + aaConfidants[iIndex].GetLeveledActorBase().GetName())
                                        ;aaConfidants[iIndex].KeepOffsetFromActor(PlayerREF, (((iAlias % 2) * 2 - 1) * 40) As Float, (((iAlias / 2) * 2 - 1) * 40) As Float, 0.0, 0.0, 0.0, 0.0, 100.0, 50.0)
                                        (Parent.GetAlias(iAlias) As ReferenceAlias).ForceRefTo(aaConfidants[iIndex] As ObjectReference)
                                        iIndex += 1
                                        iAlias += 1
                                EndWhile
                                ; ask player what to do
                                iButton = msgToShow.Show()
                                If (iButton == 3)       ; player chose snooze, wait and rescan
                                        Debug.Trace("SLEN Main - Info: player snoozed, waiting and re-scanning")
                                        SLENScannerQuest.Stop()
                                        Utility.Wait(17.5)
                                        SLENScannerQuest.Start()
                                        Utility.Wait(0.1)
                                        SLENScannerQuest.ProcessReferencesFiltered(Lovers = TRUE, Allies = TRUE, Confidants = TRUE)
                                        iNrOfLovers = SLENScannerQuest.NumberOfLovers
                                        iNrOfAllies = SLENScannerQuest.NumberOfAllies
                                        iNrOfConfidants = SLENScannerQuest.NumberOfConfidants
                                        iActorCount = iNrOfLovers + iNrOfAllies + iNrOfConfidants
                                        aaLovers = SLENScannerQuest.GetLovers()
                                        aaAllies = SLENScannerQuest.GetAllies()
                                        aaConfidants = SLENScannerQuest.GetConfidants()
                                        ;While (iAlias)
                                        ;        iAlias -= 1
                                        ;        aTemp = (Parent.GetAlias(iAlias) As ReferenceAlias).GetReference() As Actor
                                        ;        If (aTemp)
                                        ;                aTemp.ClearKeepOffsetFromActor()
                                        ;        EndIf
                                        ;EndWhile
                                EndIf
                        EndWhile        ; loops while player chooses snooze
                EndIf

                If (iButton == 2)       ; stop
                        Debug.Trace("SLEN Main - Info: player stopped Pleasant Surprise event")
                        While (iAlias)
                                iAlias -= 1
                                (Parent.GetAlias(iAlias) As ReferenceAlias).Clear()
                        EndWhile
                        Return
                ElseIf (iButton == 1)   ; watch
                        Debug.Trace("SLEN Main - Info: player will watch Pleasant Surprise event")
                        bPlayerParticipates = FALSE
                Else                    ; join
                        Debug.Trace("SLEN Main - Info: player will participate in Pleasant Surprise event")
                        bPlayerParticipates = TRUE
                        iActorCount += 1
                        CheckForceGender(PlayerREF)
                        bPlayerIsMale = (SexLab.GetGender(PlayerREF) == 0)
                EndIf

                Actor[] aaOrgy

                aaOrgy = SLENUtility.NewActorArray(iActorCount)
                Int iActorIdx = 0
                Int iMinMales = 0
                Int iMinFemales = 0
                ObjectReference orCenter

                If (bPlayerParticipates)
                        aaOrgy[iActorIdx] = PlayerREF
                        iActorIdx += 1
                        If (bPlayerIsMale)
                                iMinMales += 1
                        Else
                                iMinFemales += 1
                        EndIf
                Else
                        orCenter = SexLab.FindBed(PlayerREF As ObjectReference)
                        If (!orCenter)
                                orCenter = (aaLovers[0] As ObjectReference)
                        EndIf
                EndIf

                If (SexLab.GetGender(aaLovers[0]) == 0) ; closest lover is male
                        iMinMales += 1
                Else
                        iMinFemales += 1
                EndIf
                Int i = 0
                While (i < 8)
                        If (i < iNrOfLovers)
                                aaOrgy[iActorIdx] = aaLovers[i]
                                CheckForceGender(aaOrgy[iActorIdx])
                                iActorIdx += 1
                        EndIf
                        If (i < iNrOfConfidants)
                                aaOrgy[iActorIdx] = aaConfidants[i]
                                CheckForceGender(aaOrgy[iActorIdx])
                                iActorIdx += 1
                        EndIf
                        If (i < iNrOfAllies)
                                aaOrgy[iActorIdx] = aaAllies[i]
                                CheckForceGender(aaOrgy[iActorIdx])
                                iActorIdx += 1
                        EndIf
                        i += 1
                EndWhile

                While (iAlias)
                        iAlias -= 1
                        ;aTemp = (Parent.GetAlias(iAlias) As ReferenceAlias).GetReference() As Actor
                        ;If (aTemp)
                        ;        aTemp.ClearKeepOffsetFromActor()
                        ;EndIf
                        (Parent.GetAlias(iAlias) As ReferenceAlias).Clear()
                EndWhile
                If (bPlayerParticipates)
                        If (SLENUtility.MakeRandomSexEx(aaOrgy, 5, 2, FALSE, FALSE, TRUE, orCenter, 50, 1, 1, iMinFemales, iMinMales, FALSE))
                                If (m_bPleasantSurpriseGivesComfort && (PlayerREF.HasSpell(doomLoverAbility) == 0))
                                        Utility.Wait(10.0)
                                        Debug.Trace("SLEN Main - Info: Player gets Lover's Comfort effect from pleasant surprise event")
                                        MarriageRestedMessage.Show()
                                        RemoveRested()
                                        PlayerREF.AddSpell(MarriageRested, abVerbose = FALSE)
                                EndIf
                        EndIf
                ElseIf (iActorCount == 1)
                        SLENUtility.MakeRandomSexEx(aaOrgy, 1, 1, FALSE, FALSE, TRUE, orCenter, 0, 0, 1, iMinFemales, iMinMales, FALSE)
                Else
                        SLENUtility.MakeRandomSexEx(aaOrgy, 5, 2, FALSE, FALSE, TRUE, orCenter, 0, 0, 1, iMinFemales, iMinMales, FALSE)
                EndIf

                SLENScannerQuest.Stop()
        Else
                Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", skipping Pleasant Surprise event")
        EndIf
EndEvent

Event OnTrackedStatsEvent(String asStat, Int aiStatValue)
;    Locations Discovered
;    Dungeons Cleared
;    Days Passed
;    Hours Slept
;    Hours Waiting
;    Standing Stones Found
;    Gold Found
;    Most Gold Carried
;    Chests Looted
;    Skill Increases
;    Skill Books Read
;    Food Eaten
;    Training Sessions
;    Books Read
;    Horses Owned
;    Houses Owned
;    Stores Invested In
;    Barters
;    Persuasions
;    Bribes
;*   Intimidations
;*   Diseases Contracted
;    Days as a Vampire
;    Days as a Werewolf
;*   Necks Bitten
;    Vampirism Cures
;*   Werewolf Transformations
;    Mauls
;    Quests Completed
;    Misc Objectives Completed
;    Main Quests Completed
;    Side Quests Completed
;    The Companions Quests Completed
;    College of Winterhold Quests Completed
;    Thieves' Guild Quests Completed
;    The Dark Brotherhood Quests Completed
;    Civil War Quests Completed
;    Daedric Quests Completed
;    Dawnguard Quests Completed
;    Dragonborn Quests Completed
;    Questlines Completed
;*   People Killed
;*   Animals Killed
;*   Creatures Killed
;    Undead Killed
;    Daedra Killed
;    Automatons Killed
;    Favorite Weapon
;    Critical Strikes
;*   Sneak Attacks
;*   Backstabs
;    Weapons Disarmed
;*   Brawls Won
;*   Bunnies Slaughtered
;    Spells Learned
;    Favorite Spell
;    Favorite School
;*   Dragon Souls Collected
;*   Words Of Power Learned
;    Words Of Power Unlocked
;*   Shouts Learned
;    Shouts Unlocked
;    Shouts Mastered
;*   Times Shouted
;    Favorite Shout
;    Soul Gems Used
;*   Souls Trapped
;    Magic Items Made
;    Weapons Improved
;    Weapons Made
;    Armor Improved
;    Armor Made
;    Potions Mixed
;    Potions Used
;    Poisons Mixed
;    Poisons Used
;    Ingredients Harvested
;    Ingredients Eaten
;    Nirnroots Found
;    Wings Plucked
;*   Total Lifetime Bounty
;    Largest Bounty
;    Locks Picked
;*   Pockets Picked
;    Items Pickpocketed
;    Times Jailed
;    Days Jailed
;    Fines Paid
;    Jail Escapes
;    Items Stolen
;*   Assaults
;*   Murders
;*   Horses Stolen
;    Trespasses
;    Eastmarch Bounty
;    Falkreath Bounty
;    Haafingar Bounty
;    Hjaalmarch Bounty
;    The Pale Bounty
;    The Reach Bounty
;    The Rift Bounty
;    Tribal Orcs Bounty
;    Whiterun Bounty
;    Winterhold Bounty
        ;Debug.Trace("SLEN Main - DEBUG: detected " + asStat + " event " + (aiStatValue As String))
        Int iRoll = Utility.RandomInt(0, 99)
        Float fStartTime = Game.GetRealHoursPassed()
        Float fTime
        Float fWait

        If (asStat == "Dragon Souls Collected")
                Debug.Trace("SLEN Main - Info: detected " + asStat + " event " + (aiStatValue As String))

                Bool bPlayerBlocked = PlayerREF.IsInFaction(SLENBlockAllFaction)

                If (m_iDragonSoulEventExposure > 0)
                        If (bPlayerBlocked)
                                Debug.Trace("SLEN Main - Info: skipping dragon soul absorb exposure with value " + (m_iDragonSoulEventExposure As String) + " because player is blocked")
                        Else
                                Debug.Trace("SLEN Main - Info: processing dragon soul absorb exposure with value " + (m_iDragonSoulEventExposure As String))
                                sla_Framework.UpdateActorExposure(PlayerREF, m_iDragonSoulEventExposure, "absorbing a dragon soul (SLEN)")
                        EndIf
                EndIf

                If ((m_bLearnToTShout) && (aiStatValue > 1))
                        If (bPlayerBlocked)
                                Debug.Trace("SLEN Main - Info: skipping check for learning Thrill of the Tempest shout because player is blocked")
                        Else
                                Int iRank = PlayerREF.GetFactionRank(SLENPlayerLoveIncreaseFaction)
                                If ((iRank >= 10) && (!(SLENWordVibrate As Form).PlayerKnows()))
                                        Debug.Trace("SLEN Main - Info: Teaching word one of Thrill of the Tempest shout")
                                        SLENMsgTeachToTWord1.Show()
                                        Game.TeachWord(SLENWordVibrate)
                                ElseIf ((iRank >= 25) && (!(SLENWordRumble As Form).PlayerKnows()))
                                        Debug.Trace("SLEN Main - Info: Teaching word two of Thrill of the Tempest shout")
                                        SLENMsgTeachToTWord2.Show()
                                        Game.TeachWord(SLENWordRumble)
                                ElseIf ((iRank >= 50) && (!(SLENWordShake As Form).PlayerKnows()))
                                        Debug.Trace("SLEN Main - Info: Teaching word three of Thrill of the Tempest shout")
                                        SLENMsgTeachToTWord3.Show()
                                        Game.TeachWord(SLENWordShake)
                                EndIf
                        EndIf
                EndIf

                Int c
                Debug.Trace("SLEN Main - Info: processing dragon kill witnesses")
                Actor[] aaTemp

                If (SLENScannerQuest.IsRunning())
                        SLENScannerQuest.Stop()
                        Utility.Wait(0.1)
                EndIf
                SLENScannerQuest.SetScannerFilter(Distance = 2800.0, Arousal = 0)       ; ~ 40 meter / 130 feet
                SLENScannerQuest.Start()
                Utility.Wait(0.1)
                SLENScannerQuest.ProcessReferences()

                Int iNrOfLovers = SLENScannerQuest.NumberOfLovers
                Int iNrOfAllies = SLENScannerQuest.NumberOfAllies
                Int iNrOfConfidants = SLENScannerQuest.NumberOfConfidants
                Int iNrOfFriends = SLENScannerQuest.NumberOfFriends
                Int iNrOfBystanders = SLENScannerQuest.NumberOfBystanders
                Int iNrOfRapists = SLENScannerQuest.NumberOfRapists

                Actor[] aaLovers = SLENScannerQuest.GetLovers()
                Actor[] aaAllies = SLENScannerQuest.GetAllies()
                Actor[] aaConfidants = SLENScannerQuest.GetConfidants()
                Actor[] aaFriends = SLENScannerQuest.GetFriends()
                Actor[] aaBystanders = SLENScannerQuest.GetBystanders()
                Actor[] aaRapists = SLENScannerQuest.GetRapists()

                c = iNrOfLovers
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaLovers[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaLovers[c])
                        EndWhile
                EndIf
                c = iNrOfAllies
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaAllies[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaAllies[c])
                        EndWhile
                EndIf
                c = iNrOfConfidants
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaConfidants[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaConfidants[c])
                        EndWhile
                EndIf
                c = iNrOfFriends
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaFriends[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaFriends[c])
                        EndWhile
                EndIf
                c = iNrOfBystanders
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaBystanders[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaBystanders[c])
                        EndWhile
                EndIf
                c = iNrOfRapists
                If (c)
                        While (c)
                                c -= 1
                                If (m_iDragonKillWitnessExposure)
                                        sla_Framework.UpdateActorExposure(aaRapists[c], m_iDragonKillWitnessExposure, "witnessing a dragon kill (SLEN)")
                                EndIf
                                SLENDragonKillWitnessSpell.RemoteCast(PlayerREF, PlayerREF, aaRapists[c])
                        EndWhile
                EndIf
                SLENScannerQuest.Stop()

                If (aiStatValue == 1)
                        Debug.Trace("SLEN Main - Info: first dragon kill, skipping event to let main quest progress without interruption")
                        Return
                EndIf

                If ((Utility.GetCurrentGameTime() - m_fLastOrgyTime) < (2.0/24.0))
                        Debug.Trace("SLEN Main - Info: Less than 2 hours since last orgy, skipping dragon kill orgy event")
                        Return
                EndIf

                c = 0
                PlayerREF.GetCombatState()
                While ((PlayerREF.GetCombatState() == 1) && (c < 12))
                        Utility.Wait(5.0)
                        c += 1
                EndWhile
                If (PlayerREF.GetCombatState() == 1)
                        Debug.Trace("SLEN Main - Info: Player in combat for more than 1 minute after absorbing dragon soul, skipping dragon kill orgy event")
                        Return
                EndIf

                If (m_fDragonEventDelay > 0.0)
                        fTime = Game.GetRealHoursPassed()
                        fWait = m_fDragonEventDelay - ((fTime - fStartTime) * 3600.0)
                        If (fWait > 0.0)
                                Debug.Trace("SLEN Main - Info: waiting " + (fWait As String) + " seconds")
                                Utility.Wait(fWait)
                        EndIf
                EndIf

                Debug.Trace("SLEN Main - Info: Rolling for Dragon kill event, chance = " + (m_iDragonSoulEventChance As String) + " (0-99 roll has to be lower)")
                If (iRoll < m_iDragonSoulEventChance)
                        Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", checking for nearby participants")

                        If (c > 3)      ; more than 20 seconds since scan, time to rescan
                                If (SLENScannerQuest.IsRunning())
                                        SLENScannerQuest.Stop()
                                        Utility.Wait(0.1)
                                EndIf

                                SLENScannerQuest.SetScannerFilter(Distance = 2800.0, Arousal = 0)       ; ~ 40 meter / 130 feet
                                SLENScannerQuest.Start()
                                Utility.Wait(0.1)
                                SLENScannerQuest.ProcessReferences()

                                iNrOfLovers = SLENScannerQuest.NumberOfLovers
                                iNrOfAllies = SLENScannerQuest.NumberOfAllies
                                iNrOfConfidants = SLENScannerQuest.NumberOfConfidants
                                iNrOfFriends = SLENScannerQuest.NumberOfFriends
                                iNrOfBystanders = SLENScannerQuest.NumberOfBystanders
                                iNrOfRapists = SLENScannerQuest.NumberOfRapists

                                aaLovers = SLENScannerQuest.GetLovers()
                                aaAllies = SLENScannerQuest.GetAllies()
                                aaConfidants = SLENScannerQuest.GetConfidants()
                                aaFriends = SLENScannerQuest.GetFriends()
                                aaBystanders = SLENScannerQuest.GetBystanders()
                                aaRapists = SLENScannerQuest.GetRapists()
                        EndIf
                        Int iNrOfActors = iNrOfLovers + iNrOfAllies + iNrOfConfidants + iNrOfFriends + iNrOfBystanders + iNrOfRapists + 1
                        If (iNrOfActors < 3)
                                Debug.Trace("SLEN Main - Info: found less than 2 nearby actors, dragon kill orgy event skipped")
                                SLENScannerQuest.Stop()
                                Return
                        EndIf

                        Actor[] aaOrgy = SLENUtility.NewActorArray(iNrOfActors)
                        aaOrgy[0] = PlayerREF
                        Int iOrgyCount = 1

                        c = 0
                        While (c < 8)
                                If (c < iNrOfLovers)
                                        aaOrgy[iOrgyCount] = aaLovers[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfFriends)
                                        aaOrgy[iOrgyCount] = aaFriends[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfConfidants)
                                        aaOrgy[iOrgyCount] = aaConfidants[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfRapists)
                                        aaOrgy[iOrgyCount] = aaRapists[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfAllies)
                                        aaOrgy[iOrgyCount] = aaAllies[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfBystanders)
                                        aaOrgy[iOrgyCount] = aaBystanders[c]
                                        iOrgyCount += 1
                                EndIf
                                c += 1
                        EndWhile

                        If (m_bSOSAutoGender)
                                Debug.Trace("SLEN Main - Info: Dragon kill orgy event checking " + (iOrgyCount As String) + " actors for auto gender change")
                                c = iOrgyCount
                                While (c)
                                        c -= 1
                                        CheckForceGender(aaOrgy[c])
                                EndWhile
                        EndIf

                        Int iButton
                        If (bPlayerBlocked)
                                If (m_bDragonEventConfirmation)
                                        iButton = 1 + SLENMsgDragonKillEventNoPC.Show()
                                Else
                                        iButton = 1
                                EndIf
                        Else
                                If (m_bDragonEventConfirmation)
                                        iButton = SLENMsgDragonKillEvent.Show()
                                Else
                                        iButton = 0
                                EndIf
                        EndIf
                        If (iButton < 2)
                                Int iModPCLoveChance = (64 - iOrgyCount) / 4    ; 15 for smallest orgy to 1 for largest orgy
                                c = iOrgyCount
                                If (iButton)
                                        Debug.Trace("SLEN Main - Info: Player is blocked or chose to watch, will not participate in dragon kill orgy event")
                                        aaOrgy[0] = none
                                        iOrgyCount -= 1
                                        iModPCLoveChance = 0
                                EndIf
                                Debug.Trace("SLEN Main - Info: Dragon kill event starting random sex with " + (iOrgyCount As String) + " actors")
                                If (SLENUtility.MakeRandomSexEx(aaOrgy, m_iOrgyMaxGroupSize, m_iOrgyMinGroupSize, m_bOrgyAllowAggressive, m_bOrgyAllowFurniture, modPlayerLoveChance = iModPCLoveChance))
                                        m_fLastOrgyTime = Utility.GetCurrentGameTime()
                                EndIf
                        Else
                                Debug.Trace("SLEN Main - Info: Player stopped dragon kill orgy event")
                        EndIf
                Else
                        Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", skipping Dragon kill event")
                EndIf
                If (SLENScannerQuest.IsRunning())
                        SLENScannerQuest.Stop()
                EndIf
        ElseIf (asStat == "Dungeons Cleared")
                Debug.Trace("SLEN Main - Info: detected " + asStat + " event " + (aiStatValue As String))
                If ((Utility.GetCurrentGameTime() - m_fLastOrgyTime) < (2.0/24.0))
                        Debug.Trace("SLEN Main - Info: Less than 2 hours since last orgy, skipping event")
                        Return
                EndIf

                If (m_fDungeonEventDelay > 0.0)
                        fTime = Game.GetRealHoursPassed()
                        fWait = m_fDungeonEventDelay - ((fTime - fStartTime) * 3600.0)
                        If (fWait > 0.0)
                                Debug.Trace("SLEN Main - Info: waiting " + (fWait As String) + " seconds")
                                Utility.Wait(fWait)
                        EndIf
                EndIf

                Debug.Trace("SLEN Main - Info: Rolling for Location cleared event, chance = " + (m_iDungeonClearedEventChance As String) + " (0-99 roll has to be lower)")
                If (iRoll < m_iDungeonClearedEventChance)
                        Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", Location cleared event will occur")
                        Bool bPlayerBlocked = PlayerREF.IsInFaction(SLENBlockAllFaction)

                        Int c = 0
                        PlayerREF.GetCombatState()
                        While ((PlayerREF.GetCombatState() == 1) && (c < 12))
                                Utility.Wait(5.0)
                                c += 1
                        EndWhile
                        If (PlayerREF.GetCombatState() == 1)
                                Debug.Trace("SLEN Main - Info: Player in combat for more than 1 minute after clearing location, skipping location cleared orgy event")
                                Return
                        EndIf

                        If (SLENScannerQuest.IsRunning())
                                SLENScannerQuest.Stop()
                                Utility.Wait(0.1)
                        EndIf

                        SLENScannerQuest.SetScannerFilter(Distance = 2100.0, Arousal = 0)       ; ~ 30 meter / 100 feet
                        SLENScannerQuest.Start()
                        Utility.Wait(0.1)
                        SLENScannerQuest.ProcessReferencesFiltered(Lovers = TRUE, Allies = TRUE, Confidants = TRUE, Friends = TRUE)

                        Int iNrOfLovers = SLENScannerQuest.NumberOfLovers
                        Int iNrOfAllies = SLENScannerQuest.NumberOfAllies
                        Int iNrOfConfidants = SLENScannerQuest.NumberOfConfidants
                        Int iNrOfFriends = SLENScannerQuest.NumberOfFriends
                        Int iActorCount = iNrOfLovers + iNrOfAllies + iNrOfConfidants + iNrOfFriends + 1
                        If (iActorCount < 2)
                                Debug.Trace("SLEN Main - Info: no nearby actors, dungeon cleared event skipped")
                                SLENScannerQuest.Stop()
                                Return
                        EndIf

                        Actor[] aaLovers = SLENScannerQuest.GetLovers()
                        Actor[] aaAllies = SLENScannerQuest.GetAllies()
                        Actor[] aaConfidants = SLENScannerQuest.GetConfidants()
                        Actor[] aaFriends = SLENScannerQuest.GetFriends()
                        Actor[] aaOrgy = SLENUtility.NewActorArray(iActorCount)
                        aaOrgy[0] = PlayerREF
                        Int iOrgyCount = 1

                        c = 0
                        While (c < 8)
                                If (c < iNrOfConfidants)
                                        aaOrgy[iOrgyCount] = aaConfidants[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfFriends)
                                        aaOrgy[iOrgyCount] = aaFriends[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfLovers)
                                        aaOrgy[iOrgyCount] = aaLovers[c]
                                        iOrgyCount += 1
                                EndIf
                                If (c < iNrOfAllies)
                                        aaOrgy[iOrgyCount] = aaAllies[c]
                                        iOrgyCount += 1
                                EndIf
                                c += 1
                        EndWhile
                        SLENScannerQuest.Stop()

                        If (m_bSOSAutoGender)
                                Debug.Trace("SLEN Main - Info: Dungeon cleared event checking " + (iOrgyCount As String) + " actors for auto gender change")
                                c = iOrgyCount
                                While (c)
                                        c -= 1
                                        CheckForceGender(aaOrgy[c])
                                EndWhile
                        EndIf

                        If (((iOrgyCount > 1) && (!bPlayerBlocked)) || (iOrgyCount > 2))
                                Int iButton
                                If (bPlayerBlocked)
                                        If (m_bDungeonEventConfirmation)
                                                iButton = 1 + SLENMsgDungeonClearedEventNoPC.Show()
                                        Else
                                                iButton = 1
                                        EndIf
                                Else
                                        If (m_bDungeonEventConfirmation)
                                                iButton = SLENMsgDungeonClearedEvent.Show()
                                                While (iButton == 3)
                                                        Utility.Wait(20.0)
                                                        iButton = SLENMsgDungeonClearedEvent.Show()
                                                EndWhile
                                        Else
                                                iButton = 0
                                        EndIf
                                EndIf
                                If (iButton < 2)
                                        Int iModPCLoveChance = 20
                                        If (iButton)
                                                Debug.Trace("SLEN Main - Info: Player is blocked or chose to watch, will not participate in dungeon cleared event")
                                                aaOrgy[0] = none
                                                iOrgyCount -= 1
                                                iModPCLoveChance = 0
                                        EndIf
                                        Debug.Trace("SLEN Main - Info: Dungeon Cleared event starting random sex with " + (iOrgyCount As String) + " actors")
                                        If (SLENUtility.MakeRandomSexEx(aaOrgy, m_iOrgyMaxGroupSize, m_iOrgyMinGroupSize, m_bOrgyAllowAggressive, m_bOrgyAllowFurniture, modPlayerLoveChance = iModPCLoveChance))
                                                m_fLastOrgyTime = Utility.GetCurrentGameTime()
                                        EndIf
                                Else
                                        Debug.Trace("SLEN Main - Info: Player stopped dungeon cleared event")
                                EndIf
                        EndIf
                Else
                        Debug.Trace("SLEN Main - Info: Roll = " + (iRoll As String) + ", skipping Location cleared event")
                EndIf
        EndIf
EndEvent

Event OnUpdate()
        m_bProcessingLoveQueue = TRUE
        Int i = 0
        While (i < m_iLoveQueuePointer)
                ModPlayerLove(m_aLoveQueueActors[i], m_aLoveQueueChances[i], m_aLoveQueueValues[i])
                m_aLoveQueueActors[i] = none
                m_aLoveQueueChances[i] = 0
                m_aLoveQueueValues[i] = 0
                i += 1
        EndWhile
        m_iLoveQueuePointer = 0
        m_bProcessingLoveQueue = FALSE
EndEvent


Function SetSOSData(FormList addonList, Bool[] forceF2M, Bool[] forceM2F)       ; FormList addonList is deprecated after 20150808
        m_bSOSLoaded = FALSE
        m_bSOSAutoGender = FALSE
        m_afactF2M = New Faction[20]
        m_afactM2F = New Faction[20]
        m_iF2MFactionCount = 0
        m_iM2FFactionCount = 0

        If ((SLENSOSIntegrationQuest As Quest).IsRunning())
                m_bSOSLoaded = TRUE

                String strName
                Faction fAddonFaction

                Int i = SLENSOSIntegrationQuest.GetAddonCount()
                If (i > 20)
                        i = 20
                        Debug.Trace("SLEN Main - Warning: more than 20 SOS addons found, only the first 20 will be used.")
                EndIf

                While (i)
                        i -= 1
                        strName = SLENSOSIntegrationQuest.GetAddonName(i)
                        fAddonFaction = SLENSOSIntegrationQuest.GetAddonFaction(i)

                        Debug.Trace("SLEN Main - Info: checking " + strName + " schlong addon.")
                        If (forceF2M[i])
                                Debug.Trace("SLEN Main - Info: " + strName + " is a F2M schlong addon")
                                m_afactF2M[m_iF2MFactionCount] = fAddonFaction
                                m_iF2MFactionCount += 1
                                m_bSOSAutoGender = TRUE
                        EndIf
                        If (forceM2F[i])
                                Debug.Trace("SLEN Main - Info: " + strName + " is a M2F schlong addon")
                                m_afactM2F[m_iM2FFactionCount] = fAddonFaction
                                m_iM2FFactionCount += 1
                                m_bSOSAutoGender = TRUE
                        EndIf
                EndWhile
        Else
                Debug.Trace("SLEN Main - Error: SLENMainController.SetSOSData called while SOS quest is not running. This should not happen.")
        EndIf

        If (m_bSOSAutoGender)
                Debug.Trace("SLEN Main - Info: Automatic SexLab Gender for Schlongified actors enabled, " + (m_iF2MFactionCount As String) + " F2M, " + (m_iM2FFactionCount As String) + " M2F")
                ;RegisterForCrosshairRef()
                CheckForceGender(PlayerREF)
                Self.ForceGenderOfCrosshairTarget = m_bForceCHTargetGender
        Else
                Debug.Trace("SLEN Main - Info: Automatic SexLab Gender for Schlongified actors disabled")
                Self.ForceGenderOfCrosshairTarget = FALSE
        EndIf
EndFunction

Int Function CheckForceGender(Actor aActor)
        If ((m_bSOSLoaded) && (m_bSOSAutoGender))
                ;If (!aActor.IsInFaction(SLENForcedGenderFaction))
                ;Debug.Trace("SLEN Main - Info: Crosshair ref is not in SLENForcedGenderFaction faction")
                If (!aActor.IsInFaction(SLENBlockAllFaction) && !aActor.IsChild())
                        If (!aActor.IsInFaction(SexLabGenderFaction))
                                ;Debug.Trace("SLEN Main - Info: Checking schlongified actor " + aActor.GetLeveledActorBase().GetName() + " for Auto-Gender switch")
                                Int iSex = aActor.GetLeveledActorBase().GetSex()
                                Int i
                                If (iSex == 1)  ; female
                                        ;Debug.Trace("SLEN Main - Info: Actor is female, checking female schlongs")
                                        i = m_iF2MFactionCount
                                        While (i)
                                                i -= 1
                                                If (aActor.IsInFaction(m_afactF2M[i]))
                                                        Debug.Trace("SLEN Main - Info: Forcing gender for " + aActor.GetLeveledActorBase().GetName() + " to Male")
                                                        ;Debug.Notification("(SLEN) Forcing gender for " + aActor.GetLeveledActorBase().GetName() + " to Male")
                                                        aActor.SetFactionRank(SexLabGenderFaction, 0)
                                                        aActor.SetFactionRank(SLENForcedGenderFaction, 0)
                                                        (Parent.GetAlias(3) As ReferenceAlias).ForceRefTo(aActor As ObjectReference)
                                                        SLENSexChangeNotes[0].Show()
                                                        (Parent.GetAlias(3) As ReferenceAlias).Clear()
                                                        Return 0
                                                EndIf
                                        EndWhile
                                ElseIf (iSex == 0)  ; male
                                        ;Debug.Trace("SLEN Main - Info: Actor is male, checking male schlongs")
                                        i = m_iM2FFactionCount
                                        While (i)
                                                i -= 1
                                                If (aActor.IsInFaction(m_afactM2F[i]))
                                                        Debug.Trace("SLEN Main - Info: Forcing gender for " + aActor.GetLeveledActorBase().GetName() + " to Female")
                                                        ;Debug.Notification("(SLEN) Forcing gender for " + aActor.GetLeveledActorBase().GetName() + " to Female")
                                                        aActor.SetFactionRank(SexLabGenderFaction, 1)
                                                        aActor.SetFactionRank(SLENForcedGenderFaction, 1)
                                                        (Parent.GetAlias(3) As ReferenceAlias).ForceRefTo(aActor As ObjectReference)
                                                        SLENSexChangeNotes[1].Show()
                                                        (Parent.GetAlias(3) As ReferenceAlias).Clear()
                                                        Return 1
                                                EndIf
                                        EndWhile
                                EndIf
                                Return iSex
                        EndIf
                EndIf
                ;EndIf
                Return -1       ; already forced or blocked
        EndIf
        Return -2
EndFunction

Bool Function CheckRegisterForStats()
        If ((m_bLearnToTShout) || (m_iDragonSoulEventChance > 0) || (m_iDragonSoulEventExposure != 0) || (m_iWerewolfXformEventChance > 0) || (DragonKillWitnessExposure != 0) || (m_iDungeonClearedEventChance > 0))
                RegisterForTrackedStatsEvent()
                Return TRUE
        Else
                UnregisterForTrackedStatsEvent()
                Return FALSE
        EndIf
EndFunction

Function RemoveRested()
        ;remove all previous rested states
        PlayerREF.RemoveSpell(Rested)
        PlayerREF.RemoveSpell(WellRested)
        PlayerREF.RemoveSpell(MarriageRested)
EndFunction

Int Function UpgradeTo(Int newVersion)
        Debug.Trace("SLEN Main - Info: UpgradeTo(" + (newVersion As String) + ")")
        If (newVersion == 20150825)
                ;If (m_bLearnToTShout)
                ;        SLENShoutVoicesQuest.Start()
                ;EndIf
                If (SLENDialogueTrainers.IsRunning())
                        CheckDLCTrainers(TRUE)
                EndIf
        ElseIf (newVersion == 20160618)
                m_aLoveQueueActors = New Actor[32]
                m_aLoveQueueValues = New Int[32]
                m_aLoveQueueChances = New Int[32]
                m_iLoveQueuePointer = 0
                m_bProcessingLoveQueue = FALSE
        ElseIf (newVersion == 20160820)
                m_iOrgyMinGroupSize = 2
                m_iOrgyMaxGroupSize = 5
                m_bOrgyAllowAggressive = FALSE
                m_bForceCHTargetGender = FALSE
                m_bOrgyAllowFurniture = FALSE
                InitSexOptionSettings()
                If (SLENDialogueQuest.IsRunning())
                        (SLENDialogueQuest As SLENDialogueTools).InitOptionPages()
                EndIf
                If (SLENDialogueTrainers.IsRunning())
                        (SLENDialogueTrainers As SLENDialogueTools).InitOptionPages()
                EndIf
                If (SLENDialogueTrainers2.IsRunning())
                        (SLENDialogueTrainers2 As SLENDialogueTools).InitOptionPages()
                EndIf
                m_aiLocationCache = New Int[128]
                m_afScanTimesCache = New Float[128]
        EndIf

        Return 0
EndFunction

;Dragonborn:
; Neloth                  xx0177DA        Enchanting
;
;Dawnguard:
; Sorine Jurard           xx003475        Marksman
; Isran                   xx003478        Heavy Armor
; Florentius Baenius      xx003476        Restoration
; Gunmar                  xx003477        Smithing
; Ronthil                 xx0033AF        Speechcraft
; Fura Bloodmouth         xx0033B2        Two Handed
Function CheckDLCTrainers(Bool newState)
        Form fTemp
        Actor aTemp

        Debug.Trace("SLEN Main - Info: Checking DLC masters for trainers.")

        If (Game.GetModByName("Dawnguard.esm") == 255)
                Debug.Trace("SLEN Main - Info: 'Dawnguard.esm' not found in load order, skipping Dawnguard trainers.")
        Else
                Debug.Trace("SLEN Main - Info: 'Dawnguard.esm' found in load order, processing Dawnguard trainers.")
                fTemp = Game.GetFormFromFile(0x3475, "Dawnguard.esm")      ; Sorine Jurard
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Sorine Jurard to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerMarksmanFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Sorine Jurard from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerMarksmanFaction)
                                EndIf
                        EndIf
                EndIf
                fTemp = Game.GetFormFromFile(0x3478, "Dawnguard.esm")      ; Isran
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Isran to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerHeavyArmorFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Isran from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerHeavyArmorFaction)
                                EndIf
                        EndIf
                EndIf
                fTemp = Game.GetFormFromFile(0x3476, "Dawnguard.esm")      ; Florentius Baenius
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Florentius Baenius to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerRestorationFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Florentius Baenius from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerRestorationFaction)
                                EndIf
                        EndIf
                EndIf
                fTemp = Game.GetFormFromFile(0x3477, "Dawnguard.esm")      ; Gunmar
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Gunmar to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerSmithingFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Gunmar from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerSmithingFaction)
                                EndIf
                        EndIf
                EndIf
                fTemp = Game.GetFormFromFile(0x33AF, "Dawnguard.esm")      ; Ronthil
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Ronthil to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerSpeechcraftFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Ronthil from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerSpeechcraftFaction)
                                EndIf
                        EndIf
                EndIf
                fTemp = Game.GetFormFromFile(0x33B2, "Dawnguard.esm")      ; Fura Bloodmouth
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Fura Bloodmouth to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerTwoHandedFaction)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Fura Bloodmouth from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerTwoHandedFaction)
                                EndIf
                        EndIf
                EndIf
        EndIf

        If (Game.GetModByName("Dragonborn.esm") == 255)
                Debug.Trace("SLEN Main - Info: 'Dragonborn.esm' not found in load order, skipping Dragonborn trainers.")
        Else
                Debug.Trace("SLEN Main - Info: 'Dragonborn.esm' found in load order, processing Dragonborn trainers.")
                fTemp = Game.GetFormFromFile(0x177DA, "Dragonborn.esm")      ; Neloth
                If (fTemp)
                        aTemp = fTemp As Actor
                        If (aTemp)
                                If (newState)
                                        Debug.Trace("SLEN Main - Info: Adding Neloth to trainer factions.")
                                        aTemp.AddToFaction(JobTrainerFaction)
                                        aTemp.AddToFaction(JobTrainerEnchantingFaction)
                                        aTemp.SetFactionRank(JobTrainerEnchantingFaction, 90)
                                Else
                                        Debug.Trace("SLEN Main - Info: Removing Neloth from trainer factions.")
                                        aTemp.RemoveFromFaction(JobTrainerFaction)
                                        aTemp.RemoveFromFaction(JobTrainerEnchantingFaction)
                                EndIf
                        EndIf
                EndIf
        EndIf
EndFunction

Int Function ModPlayerLove(Actor npc, Int chance, Int amount = 1)
        If (!npc)
                Return -1
        EndIf

        If (npc == PlayerREF)
                Return -5
        EndIf

        Int iRel = npc.GetRelationshipRank(PlayerREF)
        If (iRel >= 4)
                Debug.Trace("SLEN Main - Info: Relationship rank for actor " + npc.GetLeveledActorBase().GetName() + " is already at " + (iRel As String) + ", skipping die roll")
                Return -4
        EndIf

        ;If (!(npc.GetLeveledActorBase()))
        ;        Debug.Trace("SLEN Main - Info: Actor " + (npc As Form).GetName() + " is not unique, skipping die roll for Relationship increase")
        ;        Return -1
        ;EndIf

        ;If (!m_bAllowNonUnique && (!npc.GetLeveledActorBase().IsUnique()))
        ;        Debug.Trace("SLEN Main - Info: Actor " + (npc As Form).GetName() + " is not unique, skipping die roll for Relationship increase")
        ;        Return -1
        ;EndIf

        If (PlayerREF.IsInFaction(SLENBlockAllFaction))
                Debug.Trace("SLEN Main - Info: Relationship increase blocked for Player, skipping die roll")
                Return -2
        EndIf

        If (npc.IsInFaction(SLENBlockAllFaction))
                Debug.Trace("SLEN Main - Info: Relationship increase blocked for actor " + npc.GetLeveledActorBase().GetName() + ", skipping die roll")
                Return -3
        EndIf

        Int iChance = ((1.0 + ((Math.Pow((iRel As Float) + 4.0, 0.8) - 4.0) * -0.6)) * (chance As Float) * m_fRRIncreaseDifficulty) As Int
        Int iRoll = Utility.RandomInt(0, 99)
        If (iRoll >= iChance)
                Debug.Trace("SLEN Main - Info: Roll " + (iRoll As String) + " >= Chance " + (iChance As String) + " for " + npc.GetLeveledActorBase().GetName() + ", relationship will not increase")
                Return 0
        Else
                String strName = npc.GetLeveledActorBase().GetName()
                ;String[] astrRRRanks = New String[5]
                ;astrRRRanks[0] = "Acquaintance"
                ;astrRRRanks[1] = "Friend"
                ;astrRRRanks[2] = "Confidant"
                ;astrRRRanks[3] = "Ally"
                ;astrRRRanks[4] = "Lover"
                Int iRelNew = iRel + amount

                If (iRelNew > 4)
                        iRelNew = 4
                EndIf
                Int iIncrease = iRelNew - iRel
                Debug.Trace("SLEN Main - Info: Roll " + (iRoll As String) + " < Chance " + (iChance As String) + " for " + strName + ", relationship increase from " + (iRel As String) + " to " + (iRelNew As String))
                ;Debug.Notification("(SLEN) Your relationship with " + strName + " is improving from " + astrRRRanks[iRel] + " to " + astrRRRanks[iRelNew])
                npc.SetRelationshipRank(PlayerREF, iRelNew)
                If (npc.IsInFaction(SLENPlayerLoveIncreaseFaction))
                        npc.ModFactionRank(SLENPlayerLoveIncreaseFaction, iIncrease)
                Else
                        npc.SetFactionRank(SLENPlayerLoveIncreaseFaction, iIncrease)
                EndIf
                Int iPCRank = PlayerREF.GetFactionRank(SLENPlayerLoveIncreaseFaction)
                If (iPCRank < 0)
                        iPCRank = 0
                EndIf
                iPCRank += iIncrease
                If (iPCRank > 126)
                        iPCRank = 126
                EndIf
                PlayerREF.SetFactionRank(SLENPlayerLoveIncreaseFaction, iPCRank)
                If (iIncrease > 0)
                        Sound soundToPlay
                        If (iRelNew >= 4)
                                soundToPlay = SLENSNDRRLover
                        Else
                                soundToPlay = SLENSNDRRUp
                        EndIf
                        If (soundToPlay.Play(PlayerREF As ObjectReference) == 0)
                                Debug.Trace("SLEN Main - Warning: failed to play heralds for relationship increase")
                        EndIf
                        (Parent.GetAlias(3) As ReferenceAlias).ForceRefTo(npc As ObjectReference)
                        Int iRelMsgIndex = iRelNew + 3
                        SLENRRIncreaseNotes[iRelMsgIndex].Show()
                        (Parent.GetAlias(3) As ReferenceAlias).Clear()
                EndIf
                ; check quest start conditions
                If ((m_bDibellasRefugeState) && (iPCRank >= 25) && (!SLENDBQuest.IsCompleted()))
                        If ((!SLENDBQuest.IsRunning()) && (PlayerREF.HasPerk(T01DibellaReward)) && (MQ104.IsCompleted()))
                                Debug.Trace("SLEN Main - Info: Starting Dibella's Champion quest (SLENDBQuest)")
                                If (SLENDBQuest.Start())
                                        Debug.Trace("SLEN Main - Info: Dibella's Champion quest started successfully")
                                Else
                                        Debug.Trace("SLEN Main - Info: Failed to start Dibella's Champion quest")
                                        SLENDBQuest.Reset()
                                EndIf
                        EndIf
                EndIf
                Return (iIncrease)
        EndIf
EndFunction

Int Function AddRecentPartners(Actor[] npcs)
        Int i = npcs.Length
        Bool bCheckQuest = FALSE

        If (SLENDBQuest.IsRunning())
                If (SLENDBQuest.GetCurrentStageID() == 30)
                        bCheckQuest = TRUE
                EndIf
        EndIf

        Debug.Trace("SLEN Main - Info: checking Recent Partners list for new additions")
        While (i)
                i -= 1
                If (npcs[i])
                        If (npcs[i].GetLeveledActorBase())
                                ;If (m_bAllowNonUnique || npcs[i].GetLeveledActorBase().IsUnique())
                                If (npcs[i].GetLeveledActorBase().IsUnique())
                                        If (npcs[i] != PlayerREF)
                                                If (SLENRecentPartnersList.Find(npcs[i]) == -1)
                                                        Debug.Trace("SLEN Main - Info: adding " + npcs[i].GetLeveledActorBase().GetName() + " to end of Recent Partners list")
                                                        SLENRecentPartnersList.AddForm(npcs[i] As Form)
                                                ;Else
                                                ;        Debug.Trace("SLEN Main - Info: " + npcs[i].GetLeveledActorBase().GetName() + " is already in the Recent Partners list")
                                                EndIf
                                        EndIf
                                EndIf
                        EndIf
                        If (bCheckQuest)
                                Int iObjective
                                Int iRank = npcs[i].GetRelationshipRank(PlayerREF)
                                If (iRank <= 0)
                                        iObjective = 30
                                ElseIf (iRank >= 4)
                                        iObjective = 34
                                Else
                                        iObjective = 30 + iRank
                                EndIf
                                If (!SLENDBQuest.IsObjectiveCompleted(iObjective))
                                        SLENDBQuest.SetObjectiveCompleted(iObjective, TRUE)
                                        If (SLENDBQuest.IsObjectiveCompleted(30) && SLENDBQuest.IsObjectiveCompleted(31) && SLENDBQuest.IsObjectiveCompleted(32) && SLENDBQuest.IsObjectiveCompleted(33) && SLENDBQuest.IsObjectiveCompleted(34))
                                                SLENDBQuest.SetCurrentStageID(40)
                                                bCheckQuest = FALSE
                                        EndIf
                                EndIf
                        EndIf
                EndIf
        EndWhile

        Return (SLENRecentPartnersList.GetSize())
EndFunction

Function QueueModPlayerLove(Actor npc, Int chance, Int amount = 1)
        If (m_bProcessingLoveQueue)
                ModPlayerLove(npc, chance, amount)
        Else
                m_aLoveQueueActors[m_iLoveQueuePointer] = npc
                m_aLoveQueueValues[m_iLoveQueuePointer] = amount
                m_aLoveQueueChances[m_iLoveQueuePointer] = chance
                m_iLoveQueuePointer += 1
                If (m_iLoveQueuePointer < 30)
                        If (m_iLoveQueuePointer > 27)
                                ;Debug.Trace("SLEN Main - Info: Queueing " + (m_iLoveQueuePointer As String) + " ModPlayerLove calls for 1 second")
                                RegisterForSingleUpdate(1.0)
                        Else
                                Float fWait = 20.0 + ((m_iLoveQueuePointer / 3) As Float)
                                ;Debug.Trace("SLEN Main - Info: Queueing " + (m_iLoveQueuePointer As String) + " ModPlayerLove calls for " + (fWait As String) + " seconds")
                                RegisterForSingleUpdate(fWait)
                        EndIf
                Else
                        m_bProcessingLoveQueue = TRUE
                        UnregisterForUpdate()
                        Debug.Trace("SLEN Main - Warning: ModPlayerLove queue at 30+ depth, forcing OnUpdate()")
                        OnUpdate()
                EndIf
        EndIf
EndFunction

Function QueueModPlayerLoveA(Actor[] npcs, Int chance, Int amount = 1)
        Int i = npcs.Length
        While (i)
                i -= 1
                QueueModPlayerLove(npcs[i], chance, amount)
        EndWhile
EndFunction

Int[] Function GetSexOptionCounters(Int sex, Int gender)
        If ((sex) && (gender))  ; GG
                ;Debug.Trace("SLEN Main - Info: GetSexOptionCounters returning GG array: " + (m_aiOptionCountersGG As String))
                Return m_aiOptionCountersGG
        ElseIf (sex)            ; SM
                ;Debug.Trace("SLEN Main - Info: GetSexOptionCounters returning SM array: " + (m_aiOptionCountersSM As String))
                Return m_aiOptionCountersSM
        ElseIf (gender)         ; PM
                ;Debug.Trace("SLEN Main - Info: GetSexOptionCounters returning PM array: " + (m_aiOptionCountersPM As String))
                Return m_aiOptionCountersPM
        Else                    ; MM
                ;Debug.Trace("SLEN Main - Info: GetSexOptionCounters returning MM array: " + (m_aiOptionCountersMM As String))
                Return m_aiOptionCountersMM
        EndIf
EndFunction

Function SetSexOptionCounters(Int sex, Int gender, Int[] values)
        Int[] m_aiSource
        If ((sex) && (gender))  ; GG
                m_aiSource = m_aiOptionCountersGG
        ElseIf (sex)            ; SM
                m_aiSource = m_aiOptionCountersSM
        ElseIf (gender)         ; PM
                m_aiSource = m_aiOptionCountersPM
        Else                    ; MM
                m_aiSource = m_aiOptionCountersMM
        EndIf
        Int i = values.Length
        Int iLength = m_aiSource.Length
        While (i)
                i -= 1
                If (i < iLength)
                        If (((m_aiSource[i] >= 0) && (values[i] < 0)) || ((m_aiSource[i] < 0) && (values[i] >= 0)))
                                m_aiSource[i] = -1 - m_aiSource[i]
                        EndIf
                EndIf
        EndWhile
EndFunction

Int Function ModSexOptionCounter(Int sex, Int gender, Int optionIndex, Int modValue = 1)
        Int[] aiOC = GetSexOptionCounters(sex, gender)
        optionIndex -= 1
        modValue += aiOC[optionIndex]
        aiOC[optionIndex] = modValue
        ;Debug.Trace("SLEN Main - Info: ModOptionCounter increased counter(" + (sex As String) + "," + (gender As String) + ") for option " + ((optionIndex + 1) As String) + " to " + (modValue As String))
        Return modValue
EndFunction

Function InitSexOptionSettings()
        Debug.Trace("SLEN Main - Info: InitSexOptionSettings resetting counters and anim levels")
        m_aiOptionCountersGG = New Int[32]
        m_aiOptionCountersMM = New Int[32]
        m_aiOptionCountersSM = New Int[32]
        m_aiOptionCountersPM = New Int[32]
        m_aiOptionAnimLevels = New Int[32]
        m_aiOptionAnimLevels[0] =  0
        m_aiOptionAnimLevels[1] =  0
        m_aiOptionAnimLevels[2] =  0
        m_aiOptionAnimLevels[3] =  0
        m_aiOptionAnimLevels[4] =  0
        m_aiOptionAnimLevels[5] =  3
        m_aiOptionAnimLevels[6] =  1
        m_aiOptionAnimLevels[7] =  2
        m_aiOptionAnimLevels[8] =  0
        m_aiOptionAnimLevels[9] =  1
        m_aiOptionAnimLevels[10] = 2
        m_aiOptionAnimLevels[11] = 0
        m_aiOptionAnimLevels[12] = 6
        m_aiOptionAnimLevels[13] = 4
        m_aiOptionAnimLevels[14] = 7
        m_aiOptionAnimLevels[15] = 5
        m_aiOptionAnimLevels[16] = 10
        m_aiOptionAnimLevels[17] = 8
        m_aiOptionAnimLevels[18] = 5
        m_aiOptionAnimLevels[19] = 5
        m_aiOptionAnimLevels[20] = 5
        m_aiOptionAnimLevels[21] = 9
        m_aiOptionAnimLevels[22] = 7
        m_aiOptionAnimLevels[23] = 3
        m_aiOptionAnimLevels[24] = 7
        m_aiOptionAnimLevels[25] = 5
        m_aiOptionAnimLevels[26] = 5
        m_aiOptionAnimLevels[27] = 3
        m_aiOptionAnimLevels[28] = 6
        m_aiOptionAnimLevels[29] = 4
        m_aiOptionAnimLevels[30] = 11
        m_aiOptionAnimLevels[31] = 11
        m_iOptionPage1Length = 10
EndFunction

Int[] Function GetSexOptionAnimLevels()
        Return m_aiOptionAnimLevels
EndFunction

Int Function GetSexOptionPage1Length()
        Return (m_iOptionPage1Length - 2)
EndFunction

Float Function GetLastScanTime(Int locID)
        Int idx = m_aiLocationCache.Find(locID)
        If (idx >= 0)
                Return m_afScanTimesCache[idx]
        EndIf

        Return 0.0
EndFunction

Float Function SetLastScanTime(Int locID)
        Int idx = m_aiLocationCache.Find(locID)
        If (idx > 0)
                m_aiLocationCache = PapyrusUtil.MergeIntArray(PapyrusUtil.SliceIntArray(m_aiLocationCache, 0, idx - 1), PapyrusUtil.SliceIntArray(m_aiLocationCache, idx + 1))
                m_afScanTimesCache = PapyrusUtil.MergeFloatArray(PapyrusUtil.SliceFloatArray(m_afScanTimesCache, 0, idx - 1), PapyrusUtil.SliceFloatArray(m_afScanTimesCache, idx + 1))
        Else
                m_aiLocationCache = PapyrusUtil.SliceIntArray(m_aiLocationCache, 1)
                m_afScanTimesCache = PapyrusUtil.SliceFloatArray(m_afScanTimesCache, 1)
        EndIf
        m_aiLocationCache = Utility.ResizeIntArray(m_aiLocationCache, 128)
        m_afScanTimesCache = Utility.ResizeFloatArray(m_afScanTimesCache, 128)
        m_aiLocationCache[127] = locID
        m_afScanTimesCache[127] = Utility.GetCurrentGameTime()  ;Game.GetRealHoursPassed()
        Return m_afScanTimesCache[127]
EndFunction

Bool Function ScanTrackerCell()
        Cell curCell = SLENPCTrackerREF.GetParentCell()
        Int locID = (curCell As Form).GetFormID()
        If (m_iCurrentScanCellID == locID)
                Return FALSE
        Else
                m_iCurrentScanCellID = locID
        EndIf
        If (!SLENLocChangeArousalRecalcQuest.IsRunning())
                Float fCacheTime = 1.0 / (1.0 + sla_Framework.slaConfig.TimeRateHalfLife)
                Float fLastScanTime = GetLastScanTime(locID)
                If ((Utility.GetCurrentGameTime() - fLastScanTime) > fCacheTime)
                        ;Debug.Trace("SLEN Main - Info: Virtual SexLife cache miss cell=" + (curCell As String))
                        Int iWait = 4
                        While ((iWait) && (!SLENLocChangeArousalRecalcQuest.IsStopped()))
                                Debug.Trace("SLEN Main - Info: Virtual SexLife scan still shutting down, waiting " + (((iWait As Float) / 2.0) As String) + " seconds")
                                Utility.Wait(0.5)
                                iWait -= 1
                        EndWhile
                        If (SLENLocChangeArousalRecalcQuest.IsStopped())
                                SetLastScanTime(locID)
                                SLENLocChangeArousalRecalcQuest.Start()
                                m_iCurrentScanCellID = 0
                                Return TRUE
                        Else
                                Debug.Trace("SLEN Main - Warning: Virtual SexLife scan took too long to shut down, exiting")
                        EndIf
                ;Else
                ;       Debug.Trace("SLEN Main - Info: Virtual SexLife cache hit cell=" + (curCell As String) + ", exiting")
                EndIf
        Else
                Debug.Trace("SLEN Main - Info: Virtual SexLife scan already running, exiting")
        EndIf

        m_iCurrentScanCellID = 0
        Return FALSE
EndFunction

Int Function RefreshArousal(Actor npc, Int minArousal = 10, Float maxDrySpellMult = 6.33)
        If (npc)
                Float fSLATimerateHalflife = sla_Framework.slaConfig.TimeRateHalfLife
                String strName = npc.GetLeveledActorBase().GetName()
                Int iArousal = sla_Framework.GetActorArousal(npc)
                Debug.Trace("SLEN Main - Info: Arousal for actor " + strName + " is " + (iArousal As String))
                
                If (iArousal < minArousal)
                        ;/
                        Float fDaysSinceLastOrgasm = sla_Framework.GetActorDaysSinceLastOrgasm(npc)
                        If (fDaysSinceLastOrgasm > (fSLATimerateHalflife * maxDrySpellMult))
                                Float fCurrentTime = Utility.GetCurrentGameTime()
                                Float fExposureRate = sla_Framework.GetActorExposureRate(npc)
                                Float fTimeRate = StorageUtil.GetFloatValue(npc, "SLAroused.TimeRate", 10.0)
                                Debug.Trace("SLEN Main - Info: Generating virtual sexlife event for actor=" + strName + " with Exposure Rate=" + (fExposureRate As String))
                                Debug.Trace("SLEN Main - Info: Old values timerate=" + (fTimeRate As String) + ", last orgasm=" + (fDaysSinceLastOrgasm As String) + " days ago, arousal=" + (iArousal As String))
                                Int iExposure
                                If (fSLATimerateHalflife < 0.1) ; no decay
                                        fDaysSinceLastOrgasm = Utility.RandomFloat(0.0, 10.0)
                                        iExposure = (fDaysSinceLastOrgasm * fExposureRate * Utility.RandomFloat(1.0, 7.0)) As Int
                                Else
                                        fDaysSinceLastOrgasm = Utility.RandomFloat(0.0, 5.0 * fSLATimerateHalflife)
                                        iExposure = (fDaysSinceLastOrgasm * fExposureRate * Utility.RandomFloat(1.0, 7.0) * Math.pow(1.5, -fDaysSinceLastOrgasm / fSLATimerateHalflife)) As Int
                                EndIf
                                Float fLastOrgasmDate = fCurrentTime - fDaysSinceLastOrgasm
                                fTimeRate = Utility.RandomFloat(0.25, 1.0) * fTimeRate + Utility.RandomFloat(0.0, fExposureRate) * (sla_Framework.slaConfig.SexOveruseEffect As Float)

                                fTimeRate = sla_Framework.SetActorTimeRate(npc, fTimeRate)
                                StorageUtil.SetFloatValue(npc, "SLAroused.LastOrgasmDate", fLastOrgasmDate)
                                iExposure = sla_Framework.SetActorExposure(npc, iExposure)

                                ;fTimeRate = sla_Framework.GetActorTimeRate(npc)
                                iArousal = sla_Framework.GetActorArousal(npc)
                                Debug.Trace("SLEN Virtual SexLife - Info: New values timerate=" + (fTimeRate As String) + ", last orgasm=" + (fDaysSinceLastOrgasm As String) + " days ago, exposure=" + (iExposure As String) + ", arousal=" + (iArousal As String))
                        Else
                                Debug.Trace("SLEN Virtual SexLife - Info: Last orgasm for " + strName + " was " + (fDaysSinceLastOrgasm As String) + " days ago, not generating virtual sexlife event")
                        EndIf
                        /;
                EndIf
                Return iArousal
        Endif
        Return -1
EndFunction
