# SexLab Aroused NG

Skyrim SE mod: persistent per-actor arousal system as an SKSE C++ plugin with Papyrus script API. Other mods register static/dynamic effects that sum into a single arousal float per actor.

## Build

**Do NOT compile. The user compiles Papyrus scripts and the C++ plugin themselves — never invoke `cmake`, `PapyrusCompiler.exe`, or any build tool to verify changes.** Edit `.psc` / C++ sources, then stop. Verify correctness by reading the code, not by building.

```sh
# C++ plugin (CMake 3.21+, MSVC v143 or Clang-CL, vcpkg) -- user-run only
cmake --preset build-release-msvc && cmake --build --preset release-msvc
# Output: dist/Core/SKSE/Plugins/SexlabArousedNG.dll

# Tests (Catch2) -- user-run only
cmake --preset build-debug-msvc -DBUILD_TESTS=ON && cmake --build --preset debug-msvc
```

## Bumping the Version

Three files hold version strings — keep them in sync:

1. **`dist/fomod/info.xml`** — FOMOD installer version displayed in mod managers. Update `<Version>` (e.g. `3.1.9`). This is the canonical user-facing version.
2. **`dist/Core/Source/Scripts/slaconfigscr.psc`** — `GetVersionString()` (e.g. `"3.1.9"`) is shown in MCM; `GetVersion()` is the integer form using the `MMmmppp` packing scheme documented in the function (e.g. `30100009` for 3.1.9). Bumping the integer also drives `OnVersionUpdate()` migration paths — only the **integer** triggers migrations, the string is display-only. Recompile `slaconfigscr.pex` after editing.
3. **`CMakeLists.txt`** — `project(... VERSION X.Y.Z ...)` controls the DLL's resource version. Synced to the fomod version since 3.1.11; bump when cutting a release that includes C++ changes.

Cosave ID `SLAN` is stable across versions — do not change it without a save-compat strategy.

## Papyrus Language Notes

### Control flow
- No `break` or `continue` -- use flags or early `return` to exit loops.
- Only `if/elseif/else/endif` and `while/endwhile`. No for-loops, switch, or do-while.
- Logical `||` and `&&` short-circuit.

### Variables & types
- Five base types: `Bool`, `Int`, `Float`, `String`, plus object references and arrays.
- Value types copied on assignment; objects/arrays are by reference.
- **Locals are function-scoped, not block-scoped.** Declaring the same name in sibling `if` branches (`float rate = ...` twice) is a compile error — hoist the declaration above the branches.
- Variables inside `while` loops persist across iterations (NOT reset each iteration). Initialize explicitly.
- Script-level variables can only be initialized with literals; function-level can use expressions.

### Arrays
- Max 128 elements. Size must be an integer literal (`new int[128]`), not a variable.
- `array[i] += 5` does NOT compile -- use `array[i] = array[i] + 5`.
- No arrays of arrays. Passed/assigned by reference.
- `Find()` / `RFind()` and SKSE string functions are case-insensitive; `==` string comparison is case-sensitive.

### States
- Script can be in only one state at a time. `GotoState("")` returns to empty state.
- State function signatures must exactly match the empty-state definition (see `isInScene` / `UpdateActor` overrides in `sla_OStimPlugin.psc`).
- State transitions fire `OnEndState()` → change → `OnBeginState()`.

### Threading
- Only one thread can run a script instance at a time. Any external call (including `Debug.Trace()`, property access on other objects) unlocks the script, allowing other threads in.
- After an external call returns, local assumptions about script state may be stale.

### Misc gotchas
- Compiler does not check all code paths for return values -- missing returns cause undefined behavior.
- `parent.FunctionName()` calls one level up, not necessarily the base definition.
- Unary minus can misbehave without spaces: write `x = y - 1` not `x = y-1`.

## Code Conventions

- Keep UTF-16 LE BOM encoding for translation files (`dist/Core/Interface/translations/`).
- Keep edits ASCII unless the file already contains non-ASCII.
- Papyrus source: `dist/Core/Source/Scripts/*.psc`, compiled: `dist/Core/Scripts/*.pex`.
- C++ uses C++23, CommonLibSSE-NG, precompiled headers (`PCH.h`).

## Commit Conventions

- **Never include a `Co-Authored-By: Claude ...` trailer** in commit messages. Commits should look authored solely by the human user.

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

(The sine/cosine lookup table in `CosSin.h` is a shared `inline` variable built at static initialization, not in `SKSEPluginLoad`.)

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

**Thread safety / locking invariant (read before editing `ArousalManager`):**

A single `std::mutex _lock` guards `arousalData` / `staticEffectIds` / `staticEffectCount`. Every **public** `ArousalManager` method takes `std::scoped_lock lock(_lock)` at entry; the `CleanUpActors` erase task and all three cosave callbacks lock too. This makes the maps safe under concurrent Papyrus threads **and** the native C++ API (see below). `cleanupLock` (atomic flag) remains as a belt-and-suspenders cleanup guard.

The lock is intentionally **non-recursive**, which stays deadlock-free only while these rules hold:
- **Never call one public `ArousalManager` method from another** (a "public→public call") — the second `scoped_lock` on the same thread self-deadlocks. Put shared logic in a **private, non-locking helper** (`TryGetArousalData` / `GetArousalData` are the pattern) and call that from both.
- **Never hold `_lock` across a call back into the Papyrus VM / a ModEvent dispatch / `AddTask`-then-wait.** Locked sections must stay pure in-memory work (map ops + arithmetic). `ArousalData` must remain a leaf (it must not call back into `ArousalManager`).

Reads still **create/track** the actor on access (pull-based tracking, by design — do not change get to non-inserting); idle actors are reclaimed by `CleanUpActors`.

### Native C++ inter-plugin API (`ArousalAPI.h` / `ArousalAPI.cpp`)

`extern "C"` `SLA_*` exports let other SKSE plugins drive arousal in C++ via `GetModuleHandle`+`GetProcAddress` — no linking, no Papyrus round-trip. They are a **C++ mirror of the `SloangNative` Papyrus API** (same names/units/semantics) for the subset backed by `ArousalManager`: `SLA_GetVersion`, `SLA_GetArousal`/`SLA_GetArousalInt`, the dynamic-effect convenience wrappers (`SLA_AddFlatEffect` / `AddDecayingEffect` / `AddLinearEffect` / `AddDelayedEffect` / `ClearDynamicEffect` / `HasDynamicEffect`, time args in **in-game hours**), and the low-level `SLA_GetDynamicEffectValue` / `SLA_SetDynamicEffect` / `SLA_ModDynamicEffect` (`SLA_Func*` enum for functionId). All are thin, null-safe forwarders onto the locked `ArousalManager` methods — thread-safe, callable from any thread.

Deliberately **not** exported: the `SloangNative` functions backed by Papyrus quest scripts (`GetExposure`, exposure-based `ModArousal`/`SetArousal`, `IsActorNaked`, exhibitionist / arousal-locked / blocked / gender-preference flags, orgasm tracking) — those live in `slaFrameworkScr` / `slaMainScr` / `defaultPlugin`, not the DLL, so they can't be forwarded without the plugin calling back into Papyrus. Use the Papyrus `SloangNative` API for those.

`include/ArousalAPI.h` is the shippable consumer header; keep it self-contained. `SLA_GetVersion` packs the DLL's own resource version (CMake `project VERSION`); the C-API-surface version is the separate `SLA_GetInterfaceVersion` — append new exports (never reorder/remove) and bump that.

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

3.3.0 (canonical: `dist/fomod/info.xml`), cosave ID `SLAN`, Apache-2.0 license. `CMakeLists.txt` is bumped only on releases with C++ changes; it was synced to `3.3.0` for this release (native C++ API + `ArousalManager` locking) after trailing at `3.1.11` — see *Bumping the Version* above.
