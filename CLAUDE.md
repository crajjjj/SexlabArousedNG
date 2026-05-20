# SexLab Aroused NG

Skyrim SE mod: persistent per-actor arousal system as an SKSE C++ plugin with Papyrus script API. Other mods register static/dynamic effects that sum into a single arousal float per actor.

## Build

```sh
# C++ plugin (CMake 3.21+, MSVC v143 or Clang-CL, vcpkg)
cmake --preset build-release-msvc && cmake --build --preset release-msvc
# Output: dist/Core/SKSE/Plugins/SexlabArousedNG.dll

# Tests (Catch2)
cmake --preset build-debug-msvc -DBUILD_TESTS=ON && cmake --build --preset debug-msvc
```

## Papyrus Language Notes

### Control flow
- No `break` or `continue` -- use flags or early `return` to exit loops.
- Only `if/elseif/else/endif` and `while/endwhile`. No for-loops, switch, or do-while.

### Arrays
- Max 128 elements. `array[i] += 5` does NOT compile -- use `array[i] = array[i] + 5`.

### Threading
- Only one thread can run a script instance at a time. Any external call (including `Debug.Trace()`, property access on other objects) unlocks the script, allowing other threads in.

## Code Conventions

- Keep UTF-16 LE BOM encoding for translation files (`dist/Core/Interface/translations/`).
- Keep edits ASCII unless the file already contains non-ASCII.
- Papyrus source: `dist/Core/Source/Scripts/*.psc`, compiled: `dist/Core/Scripts/*.pex`.
- C++ uses C++23, CommonLibSSE-NG, precompiled headers (`PCH.h`).

## Project Structure

```
src/                              C++ SKSE plugin source
  Main.cpp                        Entry point, SKSE registration, cosave setup
  ArousalManager.cpp              Singleton: effect registry, arousal calculation, serialization
  ArousalData.cpp                 Per-actor data: static/dynamic effects, groups, timed functions
  Papyrus.cpp                     Native function bindings (slaInternalModules)
  SerializationHelper.cpp         Cosave read/write templates
include/                          C++ headers
  CosSin.h                        Pre-computed sine/cosine table (512 entries)
dist/Core/
  Source/Scripts/                  Papyrus source files (.psc)
  Scripts/                        Compiled bytecode (.pex)
  SKSE/Plugins/                   Output DLL
  Interface/translations/         Localized strings (10+ languages, UTF-16 LE BOM)
dist/OAR/                         Open Animation Replacer meshes
dist/Traditional/                 FNIS meshes
dist/Patches/                     Optional patches (DummyESPs, SLEN, PAHE)
test/                             Catch2 tests (ArousalMath.cpp)
```

## Core Systems & Code Paths

### 1. SKSE Plugin Load (`Main.cpp`)

`SKSEPluginLoad()` ->
- spdlog init (file + MSVC debugger)
- Random engine init (mt19937)
- Cosave registration (ID `SLAN` / 0x4E414C53): Save/Load/Revert callbacks on ArousalManager
- Papyrus native function registration (21 functions on `slaInternalModules`)
- Sine/cosine lookup table build

### 2. Arousal Model (`ArousalManager`, `ArousalData`)

Each tracked actor has an `ArousalData` containing:
- `staticEffects[]` -- one slot per registered effect (pre-allocated, plugin-managed)
- `dynamicEffects{}` -- string-keyed map (event-driven, temporary)
- `staticEffectGroups[]` -- multiplicative grouping of static effects
- `arousal` float -- cached sum of all effects

**Formula:**
```
arousal = sum(static effects not in a group)
        + sum(dynamic effects)
        + sum(effect group products)
```

**Timed Functions (ArousalEffectData):**
| ID | Name | Behaviour |
|----|------|-----------|
| 0 | None | Static value, no change |
| 1 | Decay | `value * 0.5^(dt/param)` -- exponential decay/growth |
| 2 | Linear | `value + dt * param` -- constant rate |
| 3 | Sine | `(sin(formID*0.01 + t*param) + 1) * limit` -- oscillation |
| 4 | Delayed Step | `0` until `t >= param`, then `limit` |

Thread safety: mutex on ArousalManager, atomic flags for cleanup.

### 3. Plugin System (`sla_PluginBase`)

Two-state machine: `""` (not installed) / `"Installed"`.
- `CheckDependencies()` -> `EnablePlugin()` / `DisablePlugin()`
- Plugins register static effects via `RegisterEffect(id, name, desc)`
- `Update(actors[], nakedActors[])` called on timer
- `UpdateActor(who, fullUpdate)` per-actor logic
- `ClearActor(who)` on tracking removal
- LOS updates via `RegisterForLOSUpdates()`
- MCM options via `AddOptions()` / `OnUpdateOption()`

### 4. Built-in Plugins

**Default Plugin (`sla_defaultplugin`):**
- Nudity arousal (nearby naked actors, gender preference)
- Orgasm satisfaction (post-orgasm penalty with decay)
- Chastity denial cycle (linear buildup when belted)
- Sleep arousal (decay during sleep, configurable range)

**SexLab Plugin (`sla_sexlabplugin`):**
- Hooks: OnAnimationEnd, OnSexLabOrgasm, OnStageStart
- Animation tag analysis (Oral, Anal, Vaginal, Masturbation)
- Per-stage arousal boost (+5, decays over 1 hour)
- Trauma and fatigue effects

**Devious Devices Plugin (`sla_ddplugin`):**
- OnDeviceEquipped/Removed events
- Device arousal with linear decay
- Denial modifier from belt/plug
- Device-stacking multiplier

**OStim Plugin (`sla_ostimplugin`):**
- Legacy API (v<29) and OStim NG (v29+) support
- Thread start/end, actor orgasm events
- Per-thread observer handling
- Sex arousal, trauma, fatigue effects

### 5. Dynamic Effects API (ModEvent)

External mods fire ModEvents -- no quest script needed:
- `slaSetArousalEffect(Actor, effectId, initialValue, functionId, param, limit)`
- `slaModArousalEffect(Actor, effectId, modifier, limit)`

### 6. Actor Scanning & Tracking

- `slanakedscript` / `slascanallscript` / `slascanallnpcscript` -- NPC discovery
- `slaplayeraliasscr` -- player reference tracking
- `slamainscr` -- main quest, plugin lifecycle, tracked actor list
- `slaFrameworkScr` -- gender preferences, faction helpers, utility wrappers

### 7. MCM Configuration (`slaConfigScr`)

- General: enable/disable, notifications, scan frequency
- Naked detection: keywords, armor slots
- Per-plugin options contributed via `AddOptions()`
- Gender preference, exhibitionist status

### 8. Serialization (Cosave)

- ID: `SLAN` (0x4E414C53)
- Per-actor: arousal, lastUpdate, static effects, static groups, dynamic effects
- Checksum: arousal validated against sum of effects on load
- Revert clears all data

## Key Scripts by Role

| Script | Role |
|--------|------|
| `slamainscr` | Main quest, plugin lifecycle, actor tracking |
| `slaInternalModules` | Native bridge to C++ (hidden) |
| `sla_PluginBase` | Base class for all plugins |
| `sla_defaultplugin` | Nudity, orgasm, denial, sleep effects |
| `sla_sexlabplugin` | SexLab integration |
| `sla_ddplugin` | Devious Devices integration |
| `sla_ostimplugin` | OStim integration |
| `slaConfigScr` | MCM configuration |
| `slaFrameworkScr` | Framework utilities, gender, factions |
| `slax` | Logging utilities |

## C++ Native Functions (`Papyrus.cpp`)

21 functions registered on `slaInternalModules`:
- Arousal: `GetArousal`, `UpdateSingleActorArousal`
- Static effects: `RegisterStaticEffect`, `GetStaticEffectId`, `UnregisterStaticEffect`, `GetStaticEffectCount`, `GetStaticEffectValue`, `SetStaticArousalValue`, `ModStaticArousalValue`, `SetStaticArousalEffect`, `GetStaticEffectParam`, `GetStaticEffectAux`, `IsStaticEffectActive`, `SetStaticAuxillaryFloat`, `SetStaticAuxillaryInt`
- Dynamic effects: `SetDynamicArousalEffect`, `ModDynamicArousalEffect`, `GetDynamicEffectCount`, `GetDynamicEffect`, `GetDynamicEffectValue`, `GetDynamicEffectValueByName`
- Maintenance: `CleanUpActors`
- Groups: `GroupEffects`, `RemoveEffectGroup`

## Version

3.0.6 (from CMakeLists.txt), cosave ID `SLAN`, Apache-2.0 license.
