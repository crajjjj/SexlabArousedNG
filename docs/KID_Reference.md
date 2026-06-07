# Keyword Item Distributor (KID) — Reference

SKSE utility plugin by powerof3 that distributes keywords to items at game load, driven by `*_KID.ini` config files in `Data\`. No quest/script required — keywords are attached during `kDataLoaded` before any save state matters.

- **Nexus:** https://www.nexusmods.com/skyrimspecialedition/mods/55728
- **Source:** `C:\Playground\Keyword-Item-Distributor`
- **DLL:** `po3_KeywordItemDistributor.dll` (log: `Documents\My Games\Skyrim Special Edition\SKSE\po3_KeywordItemDistributor.log`)
- **CMake version constant:** 3.5.0 (`CMakeLists.txt`)
- **License:** MIT
- **Requires:** SKSE64, Skyrim SE 1.5.39+ or Skyrim VR, Address Library for SKSE / VR Address Library
- **C++23, CommonLibSSE-NG**, supports MergeMapper (auto-rewrites formIDs/esp for merged plugins)

---

## 1. How it works (pipeline)

Entry: `src/main.cpp`. SKSE messaging callbacks drive everything:

| SKSE message | What happens |
|---|---|
| `kPostLoad` | Scan `Data\*_KID.ini`, parse all lines, install `TESObjectBOOK::InitItem` vfunc hook |
| `kPostPostLoad` | Request the MergeMapper interface (optional dependency) |
| `kDataLoaded` | Resolve forms, resolve `ExclusiveGroups`, sort keywords by dependency graph, then distribute. Fires `KID_KeywordDistributionDone` mod event when finished |

Distribution itself is multi-threaded — one `std::jthread` per item type, except `MagicEffect` which runs first on the main thread (`Distribute.cpp` → `ForEachDistributable_MT`).

Books also get a runtime hook: `Hooks::InitItemImpl` patches `TESObjectBOOK` vfunc index `0x13` to re-distribute keywords if a book's `InitItem` fires after `kDataLoaded` (e.g., dynamically created books). Books are the only type whose `Distributable` is **not** cleared after the initial pass.

---

## 2. INI file convention

- File must be in `Data\`
- Filename must end with the suffix **`_KID`** (case-sensitive substring match against the path), e.g. `MyMod_KID.ini`, `ArmorPatches_KID.ini`
- Single `[]` (empty) section. All entries are multi-key — the same key (`Keyword` or `ExclusiveGroup`) can repeat.
- Unicode (CSimpleIniA with `SetUnicode()` + `SetMultiKey()`)
- Files are sorted alphabetically before processing — order matters when keywords depend on each other (see §10)

---

## 3. Line format

```
Keyword = formID~esp(OR)keywordEditorID|type|strings,formIDs(OR)editorIDs|traits|chance
```

Five `|`-separated sections (any trailing section may be omitted):

| Idx | Section | Description |
|---|---|---|
| 0 | **Keyword identifier** | `0xFORMID~Plugin.esp` **or** `KeywordEditorID`. If EDID lookup fails, KID dynamically creates a new `BGSKeyword` with that EDID and pushes it into the data handler's keyword array — discoverable in-game via SKSE `GetKeywordString`. |
| 1 | **Type** | One of the 19 supported item types (case-sensitive, see §4) |
| 2 | **Filters** | Comma-separated. Each entry can be a form (`0xID~plugin.esp`), an EditorID, or a string. Operator prefixes/infixes modify behaviour (see §5). Use `NONE` (or leave empty) for no filter. |
| 3 | **Traits** | Per-type extra filters (see §7). `NONE` or empty = no traits. |
| 4 | **Chance** | Float 0.0–100.0. Default `100` if blank or `NONE`. Seed is `szudzik(fnv1a(keyword_EDID), item_FormID)`, so the outcome is deterministic per (keyword, item) — same across game sessions. |

Whitespace inside the value is preserved; parser splits on `|` and `,`.

---

## 4. Supported types

Enum order from `include/Cache.h::Cache::Item::TYPE`:

| Type string | Underlying form type |
|---|---|
| `Armor` | `TESObjectARMO` |
| `Weapon` | `TESObjectWEAP` |
| `Ammo` | `TESAmmo` |
| `Magic Effect` | `EffectSetting` (MGEF) |
| `Potion` | `AlchemyItem` (includes food/poison) |
| `Scroll` | `ScrollItem` |
| `Location` | `BGSLocation` |
| `Ingredient` | `IngredientItem` |
| `Book` | `TESObjectBOOK` |
| `Misc Item` | `TESObjectMISC` |
| `Key` | `TESKey` |
| `Soul Gem` | `TESSoulGem` |
| `Spell` | `SpellItem` |
| `Activator` | `TESObjectACTI` |
| `Flora` | `TESFlora` |
| `Furniture` | `TESFurniture` |
| `Race` | `TESRace` |
| `Talking Activator` | `BGSTalkingActivator` |
| `Enchantment` | `EnchantmentItem` |

Distribute the same keyword multiple times to target different types — each line is independent.

---

## 5. Filter operators

Filters live in section 2. The parser ([src/LookupConfigs.cpp:42-60](file:///C:/Playground/Keyword-Item-Distributor/src/LookupConfigs.cpp#L42-L60)) recognises:

| Operator | Bucket | Meaning |
|---|---|---|
| `A+B+C` | `ALL` | Item must satisfy every entry. Mix string+form freely. |
| `-X` | `NOT` | Exclude items matching `X`. |
| `*sub` | `ANY` | Wildcard / "contains" match against name, EDID, or any of the item's existing keyword EDIDs. Strings only. |
| `X` (no prefix) | `MATCH` | OR — item passes if it matches any entry in this bucket. |

Evaluation order: **ALL → NOT → MATCH → ANY (wildcard)**. All applicable buckets must pass.

### What counts as "match" for forms

`Item::Data::HasFormFilter` ([src/LookupFilters.cpp:144-342](file:///C:/Playground/Keyword-Item-Distributor/src/LookupFilters.cpp#L144-L342)) routes by form type:

- **Weapon/Ammo/Scroll/Book/Key/SoulGem/Flora/Activator/Furniture/Race/TalkingActivator** — direct identity (item == filter)
- **Armor** — identity; for `Race` items, matches if the race's skin equals the filter
- **Keyword** — item already has it, OR the item's costliest MGEF / book-taught spell MGEF / armor or weapon enchantment MGEF has it
- **Location** — same location or the item is a child of the filter location (`IsParent`)
- **Projectile** — for `Ammo`, matches `data.projectile`; for `MGEF`, `data.projectileBase`
- **MagicEffect** — for a `MagicItem`, any of its effects' `baseEffect` matches; otherwise identity
- **EffectShader / ReferenceEffect / ArtObject** — checks MGEF's various shader/visual/art slots; ArtObject also matches `Race::dismemberBlood`
- **MusicType / Faction** — checks Location's `musicType` / `unreportedCrimeFaction`
- **AlchemyItem / Ingredient / Misc** — for `Flora`, matches `produceItem`; else identity
- **Spell** — Book teaches it / Race has it in `actorEffects` / Furniture's `associatedForm` / identity
- **Enchantment** — Weapon/Armor's `formEnchanting`, or the enchantment itself / its `baseEnchantment`
- **EquipSlot** — `BGSEquipType::GetEquipSlot`
- **VoiceType** — TalkingActivator's voice type
- **LeveledItem** — `Flora::produceItem`
- **Water** — Activator's water type
- **Perk** — Spell's `castingPerk`, MGEF's `data.perk`
- **FormList** — recurses into list contents; for `EnchantmentItem`, also matches `wornRestrictions`

If you pass a **whole plugin name only** (no formID), the filter matches any record from that file (`TESFile::IsFormInMod`).

### What counts as "match" for strings

`Item::Data::HasStringFilter` ([src/LookupFilters.cpp:344-412](file:///C:/Playground/Keyword-Item-Distributor/src/LookupFilters.cpp#L344-L412)):

1. Exact (case-insensitive) match against EditorID or item name.
2. If the string is a known **Actor Value** (see §9), checks the item's skill/AV slot per type:
   - Weapon → `weaponData.skill`
   - MGEF → `associatedSkill`, `primaryAV`, `secondaryAV`, `resistVariable`
   - Book → `teaches.actorValueToAdvance` or the AV associated with the taught spell
   - Alchemy/Ingredient/Scroll/Spell/Enchantment → costliest MGEF's AVs
3. If the string is a known **Effect Archetype** (see §8), checks the item's (or its costliest MGEF's) `data.archetype`.
4. If the string ends with `.nif`, compares against the model path (case-insensitive, normalised: backslashes, leading `meshes\` stripped). **Note: nif paths do not work for armor** (per Nexus docs).

Wildcard (`*foo`) uses `ContainsStringFilter`: substring match against EDID, name, or any of the item's existing keyword EDIDs. (`.nif` substrings are also checked against the model path.)

---

## 6. Per-type Traits

From `include/Traits.h`. Combine with `,` inside section 3. Single-letter flags can be negated with `-`.

### Armor (`ArmorTraits`)
| Trait | Meaning |
|---|---|
| `HEAVY` / `LIGHT` / `CLOTHING` | Armor type |
| `E` / `-E` | Enchanted / not |
| `T` / `-T` | Has template / not |
| `AR(min max)` | Armor rating range (max optional) |
| `W(min max)` | Weight range |
| `<digits>` | Biped slot number 30–61, e.g. `32` for body, `41` for amulet |

### Weapon (`WeaponTraits`)
| Trait | Meaning |
|---|---|
| `HandToHandMelee`, `OneHandSword`, `OneHandDagger`, `OneHandAxe`, `OneHandMace`, `TwoHandSword`, `TwoHandAxe`, `Bow`, `Staff`, `Crossbow` | Animation type |
| `E` / `-E`, `T` / `-T` | Enchanted / templated flags |
| `W(...)` | Weight range |
| `D(...)` | Damage range |

### Ammo (`AmmoTraits`)
| Trait | Meaning |
|---|---|
| `B` / `-B` | Bolt / not bolt (arrow) |
| `D(...)` | Damage range |

### Magic Effect (`MagicEffectTraits`)
| Trait | Meaning |
|---|---|
| `H` / `-H` | Hostile / not |
| `D(<delivery>)` | Delivery int (Self=0, Touch=1, Aimed=2, TargetActor=3, TargetLocation=4) |
| `CT(<castingType>)` | Casting type (ConstantEffect=0, FireAndForget=1, Concentration=2) |
| `R(<av>)` | Resistance AV index |
| `(<av> <min> [max])` | Magick skill + minimum skill level range |
| `DISPEL` / `-DISPEL` | `kDispelWithKeywords` flag |

### Potion (`PotionTraits`)
`P` / `-P` (poison), `F` / `-F` (food)

### Ingredient (`IngredientTraits`)
`F` / `-F` (food)

### Book (`BookTraits`)
| Trait | Meaning |
|---|---|
| `S` / `-S` | Teaches a spell / not |
| `AV` / `-AV` | Teaches a skill / not |
| `<int>` | Specific ActorValue index — matches taught skill OR the AV associated with the taught spell |

### Soul Gem (`SoulGemTraits`)
| Trait | Meaning |
|---|---|
| `BLACK` / `-BLACK` | Can hold NPC soul / not |
| `SOUL(<level>)` | Currently contained soul size |
| `GEM(<level>)` or bare `<level>` | Maximum capacity |

`SOUL_LEVEL`: None=0, Petty=1, Lesser=2, Common=3, Greater=4, Grand=5.

### Spell / Enchantment / Scroll (`SpellTraits`)
| Trait | Meaning |
|---|---|
| `ST(<spellType>)` | Spell type |
| `CT(<castingType>)` / `D(<delivery>)` | As MGEF |
| `H` / `-H` | Hostile |
| `<av>` | Associated skill (via costliest effect) |

### Furniture (`FurnitureTraits`)
| Trait | Meaning |
|---|---|
| `T(<int>)` | Furniture type: 0=Perch, 1=CanLean, 2=CanSit, 3=CanSleep |
| `BT(<int>)` | WorkBench bench type |
| `US(<av>)` | WorkBench `usesSkill` AV |

Negative pattern matching (`-H`, `-E`, etc.) is supported wherever single-letter flags exist.

---

## 7. Chance

- Float 0.0–100.0, default 100.
- Deterministic per (keyword EditorID, item FormID) pair via Szudzik pairing + FNV-1a hash + `RNG`. Same seed → same result across saves and sessions.
- Evaluated **before** filters to short-circuit unnecessary checks ([src/LookupFilters.cpp:58-69](file:///C:/Playground/Keyword-Item-Distributor/src/LookupFilters.cpp#L58-L69)).

---

## 8. Effect Archetypes (string filter or trait)

From `Cache::Archetype::map`. Use the bare name as a string filter on MGEF / Spell / Scroll / Enchantment / Potion:

```
None, ValueMod, Script, Dispel, CureDisease, Absorb, DualValueMod, Calm,
Demoralize, Frenzy, Disarm, CommandSummoned, Invisibility, Light, Darkness,
NightEye, Lock, Open, BoundWeapon, SummonCreature, DetectLife, Telekinesis,
Paralysis, Reanimate, SoulTrap, TurnUndead, Guide, WerewolfFeed,
CureParalysis, CureAddiction, CurePoison, Concussion, ValueAndParts,
AccumulateMagnitude, Stagger, PeakValueMod, Cloak, Werewolf, SlowTime, Rally,
EnhanceWeapon, SpawnHazard, Etherealize, Banish, SpawnScriptedRef, Disguise,
GrabActor, VampireLord
```

---

## 9. Actor Values (string filter)

`Cache::ActorValue::map` covers the full canonical list (~150 entries). Notable spellings used by KID specifically:

- Skills: `OneHanded`, `TwoHanded`, `Marksman` (archery), `Block`, `Smithing`, `HeavyArmor`, `LightArmor`, `Pickpocket`, `Lockpicking`, `Sneak`, `Alchemy`, `Speechcraft`, `Alteration`, `Conjuration`, `Destruction`, `Illusion`, `Restoration`, `Enchanting`
- Stats: `Health`, `Magicka`, `Stamina`, `HealRate`, `MagickaRate`, `StaminaRate`, `SpeedMult`, `CarryWeight`, `CritChance`, `MeleeDamage`, `UnarmedDamage`
- Resists: `DamageResist`, `PoisonResist`, `FireResist`, `ElectricResist`, `FrostResist`, `MagicResist`, `DiseaseResist`
- Variables: `Variable01..10`, `BowSpeedBonus`, `WardPower`, `WardDeflection`, etc.

Full list lives in [include/Cache.h:157-322](file:///C:/Playground/Keyword-Item-Distributor/include/Cache.h#L157-L322).

---

## 10. ExclusiveGroup directive

Second supported INI key besides `Keyword`. Lets you declare that a set of keywords are mutually exclusive — an item that already has one of them will not receive any other from the same group via KID.

```ini
ExclusiveGroup = GroupName|KeywordA, KeywordB, 0x1234~MyMod.esp, -KeywordToRemove
```

- Section 0: group name (string).
- Section 1: comma-separated keyword formIDs / EditorIDs. Prefix `-` removes a keyword that would otherwise be in the group (lets you build a group then trim it).
- `ALL` and wildcards have no meaning here; only MATCH and NOT.
- A single keyword may appear in multiple groups; KID unions all groups it belongs to when checking exclusivity.
- Implemented by `ExclusiveGroups::Manager` and queried during `Item::Data::PassedFilters` via `HasMutuallyExclusiveKeyword` ([src/LookupFilters.cpp:95-104](file:///C:/Playground/Keyword-Item-Distributor/src/LookupFilters.cpp#L95-L104)).

---

## 11. Keyword dependency sort

KID builds a dependency graph between keywords whose filters reference other keywords (`KeywordDependencies.h::ResolveKeywords`). It runs a topological sort before distribution so a keyword like `MagicDamageSun` (filter mentions `MagicDamageFire`) is processed after the keyword it depends on. Wildcard `*` filters also count as dependencies if any existing keyword EDID contains the wildcard substring.

Ties broken by config-file appearance order, fallback to alphabetical EDID order.

---

## 12. MergeMapper integration

If MergeMapper is installed, every `0xID~PluginName.esp` reference in keyword IDs **and** filter IDs is rewritten through `IMergeMapperInterface001::GetNewFormID` at lookup time. Conversion is logged as `0xOld->0xNew` / `OldName->NewName`. Required for KID INIs to keep working after a Mator Smash / zMerge merge.

---

## 13. Mod event

After distribution finishes, KID fires the SKSE mod event **`KID_KeywordDistributionDone`** (no args). Use this in Papyrus if you need to wait for keywords to be applied before scanning:

```papyrus
Event OnInit()
    RegisterForModEvent("KID_KeywordDistributionDone", "OnKIDDone")
EndEvent

Event OnKIDDone(string evt, string s, float f, Form sender)
    ; safe to enumerate keyword-tagged items now
EndEvent
```

---

## 14. Examples (from Nexus + source)

```ini
; Add MysticismSpells to every Magic Effect in Mysticism.esp
Keyword = MysticismSpells|Magic Effect|MysticismMagic.esp

; 20% chance, only Destruction magic effects
Keyword = NoviceDestruction|Magic Effect|Destruction|NONE|20

; Poisonous foods only
Keyword = PoisonousFood|Potion|NONE|P,F

; Non-enchanted heavy gauntlets
Keyword = 0x1234~MyArmorMod.esp|Armor|ArmorHeavy+ArmorGauntlet|-E

; Wildcard - any ammo whose name/EDID/existing keyword contains "Bound"
Keyword = MysticalAmmo|Ammo|*Bound

; Match by specific formIDs (sun hit art)
Keyword = MagicDamageSun|Magic Effect|0x02019C9D,0x0200A3BB,0x0200A3BC

; Books that teach Destruction
Keyword = SpellTomeDestruction|Book|Destruction|S

; Match by archetype
Keyword = MagicAbsorb|Magic Effect|Absorb

; Match by mesh path
Keyword = SteelMace|Weapon|*steelmace.nif

; Mutually exclusive damage types
ExclusiveGroup = WeaponDamageType|WeaponDamageTypeFire, WeaponDamageTypeFrost, WeaponDamageTypeShock
```

---

## 15. Logging

`po3_KeywordItemDistributor.log` in `Documents\My Games\Skyrim Special Edition\SKSE\`:

- `**INI**` block — list of parsed INIs
- `**MERGES**` — MergeMapper detection
- `**HOOKS**` — book vfunc hook
- `**LOOKUP**` — per-type form resolution, per-keyword `[path] EDID` lines, skipped invalid filters
- `**EXCLUSIVE GROUPS**` — groups built
- `**PROCESSING**` — `Adding N/M keywords to <type>` summary
- `**RESULT**` — per keyword: `EDID [0xID~plugin] added to <count>/<total form count>`
- `**STATS**` — distribution timing (μs / ms)

Common failure modes you'll see in the log:
- `keyword doesn't exist` — formID/plugin lookup miss (case sensitivity matters on plugin name)
- `keyword editorID is empty!` — formID resolved but the keyword has no EDID; KID rejects these to avoid invisible keywords
- `Filter [0xID] SKIP - invalid formtype (...)` — filter form is not in `Cache::FormType::set`
- `couldn't create keyword` — out of slots / form factory failed when KID tried to mint a new keyword
- `[KID] Errors found when reading configs. Check ...log` — printed to in-game console at startup when any line failed to parse

---

## 16. SLArousedNG: "Export to KID file" MCM button

The MCM `Current Armor List` page exposes an **Export to KID file** action ([slaconfigscr.psc](../dist/Core/Source/Scripts/slaconfigscr.psc) — see `ExportToKID()`, `BuildLinesFor()`, `FormToKidFilter()`). It writes `Data\SLArousedNG_Custom_KID.ini` containing one `Keyword = <EDID>|Armor|0x<localID>~<plugin>|NONE|100` line for every currently-toggled (keyword, armor) pair — both the 8 built-in arousal keywords and any user-registered custom keywords.

- **Dependency:** [PapyrusExtenderSSE](https://www.nexusmods.com/skyrimspecialedition/mods/22854) (`PO3_SKSEFunctions.GetFormModName` for plugin name; `PO3_SKSEFunctions.IntToString` for ESL-safe hex FormID without Papyrus signed-int overflow). PapyrusUtil SE is already a project-wide hard dependency.
- **ESL-safe**: FormIDs with top byte `FE` use the lower 12 bits (last 3 hex chars); regular ESM/ESP use the lower 24 bits (last 6 hex chars). Algorithm in `FormToKidFilter`.
- **Re-export** after merging or reordering plugins — the file stores load-order-current IDs. MergeMapper at the KID consumer side handles further load-order shuffling automatically.
- **Skipped automatically:** dynamically-created forms (no `GetFile(0)`) — they can't be referenced from an INI.
- **Missing PE detection:** the button probes `GetFormModName(self, false)` first; an empty result triggers a "PapyrusExtenderSSE required" message instead of writing a partial file.

## 17. Source layout

```
include/
  Cache.h                  Item type enum + Archetype + ActorValue maps
  Defs.h                   Filter<T>, RawVec, FormOrString variants
  Distribute.h             distribute() template, log_keyword_count
  ExclusiveGroups.h        Mutually-exclusive keyword sets
  Hooks.h                  Book InitItem vfunc thunk
  KeywordData.h            Distributable<T> per item type, LookupForms
  KeywordDependencies.h    Dependency resolver for keyword sort order
  LookupConfigs.h          INI parser entry (parse_config)
  LookupFilters.h          Filter::Data + Item::Data::PassedFilters
  LookupForms.h            Top-level form lookup
  Traits.h                 Per-type Traits classes (Armor/Weapon/MGEF/...)
src/
  main.cpp                 SKSE entry, message handler
  Cache.cpp, ExclusiveGroups.cpp, Distribute.cpp, Hooks.cpp,
  KeywordData.cpp, LookupConfigs.cpp, LookupFilters.cpp, LookupForms.cpp
```

Pipeline at a glance:

```
kPostLoad        -> INI::GetConfigs()   (parse all *_KID.ini)
                 -> Hooks::Install()
kPostPostLoad    -> MergeMapper hookup
kDataLoaded      -> Forms::LookupForms()                  // resolve keywords + filters
                 -> Dependencies::ResolveKeywords()        // topo sort
                 -> ExclusiveGroups::LookupExclusiveGroups
                 -> Distribute::AddKeywords()              // MT distribute, log
                 -> SendModEvent("KID_KeywordDistributionDone")
```
