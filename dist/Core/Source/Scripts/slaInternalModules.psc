Scriptname slaInternalModules Hidden

int function GetStaticEffectCount() global native
int function RegisterStaticEffect(string id) global native
int function GetStaticEffectId(string effectId) global native
bool function UnregisterStaticEffect(string id) global native
bool function IsStaticEffectActive(Actor who, int effectIdx) global native
int function GetDynamicEffectCount(Actor who) global native
string function GetDynamicEffect(Actor who, int number) global native
float function GetDynamicEffectValueByName(Actor who, string effectId) global native
float function GetDynamicEffectValue(Actor who, int number) global native
float function GetStaticEffectValue(Actor who, int effectIdx) global native
float function GetStaticEffectParam(Actor who, int effectIdx) global native
float function GetStaticEffectLimit(Actor who, int effectIdx) global native
int function GetStaticEffectAux(Actor who, int effectIdx) global native
float function GetStaticEffectAuxFloat(Actor who, int effectIdx) global native
function SetDynamicArousalEffect(Actor who, string effectId, float initialValue, int functionId, float param, float limit) global native
function ModDynamicArousalEffect(Actor who, string effectId, float modifier, float limit) global native
function SetStaticArousalEffect(Actor who, int effectIdx, int functionId, float param, float limit, int auxilliary) global native
function SetStaticArousalValue(Actor who, int effectIdx, float value) global native
function SetStaticAuxillaryFloat(Actor who, int effectIdx, float value) global native
function SetStaticAuxillaryInt(Actor who, int effectIdx, int value) global native
float function ModStaticArousalValue(Actor who, int effectIdx, float diff, float limit) global native
float function GetArousal(Actor who) global native
function UpdateSingleActorArousal(Actor who, float GameDaysPassed) global native

int function CleanUpActors(float lastUpdateBefore) global native

bool function GroupEffects(Actor who, int effIdx1, int effIdx2) global native
bool function RemoveEffectGroup(Actor who, int effIdx1) global native

bool function TryLock(int lockID) global native
function Unlock(int lockID) global native
Actor[] function DuplicateActorArray(Actor[] actors, int count) global native

; 3.4.0 -- native actor discovery and observer pass (see slaMainScr.UpdateActorArousals).
; Loaded, AI-active actors within radius units of origin, nearest first, at most maxCount
; (1..127); origin itself, children, dead, disabled and unloaded actors, chickens and
; mannequins are skipped, creatures too unless includeCreatures. An empty result arrives
; as None in Papyrus.
Actor[] function ScanActors(Actor origin, float radius, int maxCount, bool includeCreatures) global native
; One pass over every observer/observed pair. flags per actor: 1 naked, 2 exhibiting,
; 4 in an OStim scene (SexLab is read from the animating faction). exposure per actor
; (1.0 when not scaling), genderPref per actor (0 male, 1 female, 2 both). Returns 8
; floats per actor: [0] naked weight, [1] max exposure seen, [2] sees naked, [3] sees
; naked of preferred gender, [4] exhibitionist onlooker count, [5] sees SexLab scene,
; [6] sees OStim scene, [7] actors in view that passed the relevance filter.
float[] function ComputeObservations(Actor[] actors, int[] flags, float[] exposure, int[] genderPref, bool useLOS, Faction creatureLover, Faction animating) global native

String function FormatHex(int formId) global native