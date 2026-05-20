# SexLab Aroused NG -- AI Smoke Tests

Pre-release checklist. Each scenario should be verified in-game or by code inspection before tagging a release.

**Priority key:** P0 = blocker, P1 = high, P2 = medium

---

## 1. SKSE Plugin Load & Initialization

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 1.1 | P0 | Fresh install -- new save, no prior SLA data | `SKSEPluginLoad` succeeds, cosave ID `SLAN` registered, Papyrus natives available, sine table built | Main.cpp |
| 1.2 | P0 | Existing save -- reload with active arousal data | Cosave deserialized, per-actor arousal/effects restored, checksum validates against effect sum | ArousalManager, SerializationHelper |
| 1.3 | P0 | Missing SKSE or version mismatch | Plugin reports error via spdlog, does not crash game | Main.cpp |
| 1.4 | P1 | Main quest script initialization | `slamainscr` starts, plugins checked via `CheckDependencies`, installed plugins enter `"Installed"` state | slamainscr, sla_PluginBase |
| 1.5 | P1 | Save/load cycle -- cosave round-trip | All static effects, dynamic effects, groups, and aux data survive save/load without corruption | ArousalManager |
| 1.6 | P1 | Revert (new game / load different save) | `OnRevert` clears all actor data, effect registrations, groups | ArousalManager |

## 2. Arousal Calculation

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 2.1 | P0 | Sum of static effects (no groups) | `arousal = sum(staticEffects[i].value)` for ungrouped effects | ArousalData |
| 2.2 | P0 | Sum with dynamic effects | Dynamic effect values added to total | ArousalData |
| 2.3 | P0 | Grouped effects multiply | Group contribution = `product(member values)`, not sum | ArousalData |
| 2.4 | P1 | Mixed: ungrouped static + dynamic + groups | All three contributions sum correctly | ArousalData |
| 2.5 | P1 | Negative arousal values | No crash or UB; values can go below 0 (mod authors clamp in their plugins) | ArousalData |
| 2.6 | P1 | Very large arousal (>100) | No overflow; float handles gracefully | ArousalData |
| 2.7 | P2 | Zero effects registered | Arousal = 0, no division errors | ArousalData |

## 3. Timed Effect Functions

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 3.1 | P0 | Decay (ID=1) -- positive half-life | `value * 0.5^(dt/param)`, approaches limit, effect removed when reached | ArousalData |
| 3.2 | P0 | Decay (ID=1) -- negative param (growth) | Value grows toward limit instead of decaying | ArousalData |
| 3.3 | P1 | Linear (ID=2) -- positive rate | `value + dt * param`, stops at limit | ArousalData |
| 3.4 | P1 | Linear (ID=2) -- negative rate | Value decreases toward limit | ArousalData |
| 3.5 | P1 | Sine (ID=3) -- oscillation | `(sin(formID*0.01 + t*param) + 1) * limit`, cycles continuously | ArousalData, CosSin |
| 3.6 | P2 | Delayed Step (ID=4) | Value = 0 before param days elapsed, then = limit | ArousalData |
| 3.7 | P1 | Function ID=0 (None) | Value stays constant, no update processing | ArousalData |
| 3.8 | P2 | dt = 0 (same game time) | No change applied, no division by zero | ArousalData |
| 3.9 | P2 | Very large dt (long AFK / timescale abuse) | No overflow or extreme values; decay should reach limit, linear should clamp | ArousalData |

## 4. Static Effect Management

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 4.1 | P0 | RegisterStaticEffect | New slot allocated, index returned, existing actors get expanded arrays | ArousalManager |
| 4.2 | P0 | GetStaticEffectId | Returns correct index for registered name, -1 for unknown | ArousalManager |
| 4.3 | P0 | UnregisterStaticEffect | Slot marked "Unused", value zeroed on all actors, slot reusable | ArousalManager |
| 4.4 | P1 | SetStaticArousalValue | Absolute value set on correct slot | Papyrus |
| 4.5 | P1 | ModStaticArousalValue | Delta applied, clamped by limit, returns actual change | Papyrus |
| 4.6 | P1 | SetStaticArousalEffect (timed function) | Function ID, param, limit stored; effect added to update set | Papyrus |
| 4.7 | P1 | DisableArousalEffect | Value zeroed, function cleared, removed from update set | Papyrus |
| 4.8 | P2 | Auxiliary int/float storage | `SetStaticAuxillaryInt`/`Float` persists across updates, survives save/load | Papyrus, ArousalManager |
| 4.9 | P2 | Multiple plugins registering concurrently | No race conditions; mutex protects registration | ArousalManager |

## 5. Dynamic Effect Management

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 5.1 | P0 | SetDynamicArousalEffect -- new effect | Effect created with initial value, function applied | Papyrus, ArousalManager |
| 5.2 | P0 | SetDynamicArousalEffect -- replace existing | Delta applied relative to current value, function updated | Papyrus |
| 5.3 | P0 | SetDynamicArousalEffect -- remove (fnc=0, val=0) | Effect deleted from map | Papyrus |
| 5.4 | P1 | ModDynamicArousalEffect | Modifier added to existing, clamped by limit; direction inferred from sign | Papyrus |
| 5.5 | P1 | ModDynamicArousalEffect on nonexistent effect | No crash, no-op or creates with modifier as initial | Papyrus |
| 5.6 | P1 | GetDynamicEffectCount / GetDynamicEffect / GetDynamicEffectValue | Correct enumeration for debugging/UI | Papyrus |
| 5.7 | P2 | GetDynamicEffectValueByName | Returns value for named effect, 0 if not found | Papyrus |
| 5.8 | P2 | Many dynamic effects on one actor (50+) | No performance cliff; map operations remain fast | ArousalManager |

## 6. Effect Groups

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 6.1 | P0 | GroupEffects -- merge two ungrouped effects | New group created, effects multiply instead of sum | ArousalManager |
| 6.2 | P1 | GroupEffects -- add to existing group | Third effect joins existing group | ArousalManager |
| 6.3 | P1 | GroupEffects -- both already in different groups | Returns false, no merge | ArousalManager |
| 6.4 | P1 | RemoveEffectGroup | Group dissolved, members return to summing | ArousalManager |
| 6.5 | P2 | Group with timed function members | Timed functions update within group, product recalculated | ArousalData |
| 6.6 | P2 | Group member unregistered | Group adjusts or dissolves cleanly | ArousalManager |

## 7. Plugin Lifecycle (sla_PluginBase)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 7.1 | P0 | CheckDependencies returns true | `EnablePlugin()` called, state -> `"Installed"`, `OnInstalled()` registers with framework | sla_PluginBase |
| 7.2 | P0 | CheckDependencies returns false (missing dep) | Plugin stays uninstalled, no errors, graceful skip | sla_PluginBase |
| 7.3 | P1 | Dependency removed mid-playthrough | Next check -> `DisablePlugin()` -> `OnUninstalled()`, effects unregistered | sla_PluginBase |
| 7.4 | P1 | Update() called with actor list | All tracked actors passed; plugin iterates and updates effects | sla_PluginBase |
| 7.5 | P1 | ClearActor() on tracking removal | Plugin zeroes its effects for that actor | sla_PluginBase |
| 7.6 | P2 | LOS updates | `RegisterForLOSUpdates` -> `UpdateObserver()` fires when actor gains LOS | sla_PluginBase |

## 8. Default Plugin (sla_defaultplugin)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 8.1 | P0 | Nudity arousal -- nearby naked actor | Arousal increases based on proximity, gender preference, rate setting | sla_defaultplugin |
| 8.2 | P1 | Nudity arousal -- non-preferred gender | Lower cap applied (`nakedMax_nonpref`) | sla_defaultplugin |
| 8.3 | P1 | Nudity arousal decay | Decays with configured half-life when naked actors leave | sla_defaultplugin |
| 8.4 | P1 | Orgasm satisfaction penalty | Post-orgasm: negative effect applied, decays over time | sla_defaultplugin |
| 8.5 | P1 | Chastity denial cycle | Linear buildup when belted, capped at configured max | sla_defaultplugin |
| 8.6 | P1 | Sleep arousal decay | Arousal decays during sleep; configurable range and minimum hours | sla_defaultplugin |
| 8.7 | P2 | All MCM options respected | Changing nudity max/rate/decay in MCM takes effect on next update | sla_defaultplugin |

## 9. SexLab Integration (sla_sexlabplugin)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 9.1 | P0 | SexLab.esm present -- plugin installs | `CheckDependencies` finds SexLab, registers effects, hooks events | sla_sexlabplugin |
| 9.2 | P0 | SexLab.esm absent -- graceful skip | Plugin stays uninstalled, no script errors | sla_sexlabplugin |
| 9.3 | P0 | OnAnimationEnd -- orgasm detection | Determines if actor orgasmed based on animation tags and gender; applies satisfaction effect | sla_sexlabplugin |
| 9.4 | P1 | Per-stage arousal boost | +5 arousal per stage, decays over 1 hour | sla_sexlabplugin |
| 9.5 | P1 | Animation tag analysis | Oral, Anal, Vaginal, Masturbation tags parsed correctly | sla_sexlabplugin |
| 9.6 | P1 | Trauma effect | Applied based on animation context, decays with half-life | sla_sexlabplugin |
| 9.7 | P2 | Fatigue effect | Post-scene fatigue, configurable base and half-life | sla_sexlabplugin |
| 9.8 | P2 | Always-check-orgasm toggle | When enabled, checks orgasm regardless of animation tags | sla_sexlabplugin |

## 10. Devious Devices Integration (sla_ddplugin)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 10.1 | P0 | DD Integration.esm present -- plugin installs | Effects registered, device events hooked | sla_ddplugin |
| 10.2 | P0 | DD Integration.esm absent -- graceful skip | No errors, plugin stays uninstalled | sla_ddplugin |
| 10.3 | P1 | OnDeviceEquipped | Device arousal effect applied with linear decay | sla_ddplugin |
| 10.4 | P1 | OnDeviceRemoved | Device effect cleared | sla_ddplugin |
| 10.5 | P1 | Belt/plug denial modifier | Multiplier applied based on equipped devices | sla_ddplugin |
| 10.6 | P2 | Device stacking | Multiple devices multiply arousal contribution | sla_ddplugin |
| 10.7 | P2 | Chastity orgasm blocking | Orgasm blocked when belt equipped | sla_ddplugin |

## 11. OStim Integration (sla_ostimplugin)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 11.1 | P0 | Ostim.esp present -- plugin installs | Effects registered, thread events hooked | sla_ostimplugin |
| 11.2 | P0 | Ostim.esp absent -- graceful skip | No errors | sla_ostimplugin |
| 11.3 | P1 | Legacy API (v<29) | Falls back to legacy event names | sla_ostimplugin |
| 11.4 | P1 | OStim NG (v29+) | Uses new thread event API | sla_ostimplugin |
| 11.5 | P1 | Thread start/end | Actors tracked during scene, cleared on end | sla_ostimplugin |
| 11.6 | P1 | Actor orgasm | Satisfaction/trauma/fatigue effects applied | sla_ostimplugin |
| 11.7 | P2 | Per-thread observer handling | Observers tracked separately from participants | sla_ostimplugin |

## 12. Actor Scanning & Tracking

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 12.1 | P0 | Nearby actors discovered | Scan scripts populate tracked actor list | slanakedscript, slascanallscript |
| 12.2 | P1 | Player tracked | `slaplayeraliasscr` keeps player in tracked list | slaplayeraliasscr |
| 12.3 | P1 | Actor leaves area | `ClearActor` called on all plugins, data optionally pruned | slamainscr |
| 12.4 | P1 | Naked detection | Armor keyword/slot checks correctly identify naked actors | slaConfigScr, slaFrameworkScr |
| 12.5 | P2 | Gender preference | Male/female/both preference applied per actor | slaFrameworkScr |

## 13. MCM Configuration

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 13.1 | P0 | MCM pages render | All pages load without script errors | slaConfigScr |
| 13.2 | P1 | Settings persist across save/load | SKSE-persistent properties survive | slaConfigScr |
| 13.3 | P1 | Plugin options | Each plugin's `AddOptions` contributes to MCM | sla_PluginBase, slaConfigScr |
| 13.4 | P2 | Armor keyword config | Naked detection keywords configurable | slaConfigScr |
| 13.5 | P2 | Scan frequency setting | Changing frequency affects update timer | slaConfigScr |

## 14. ModEvent API (External Mods)

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 14.1 | P0 | `slaSetArousalEffect` event received | Dynamic effect created/replaced on target actor | Papyrus |
| 14.2 | P0 | `slaModArousalEffect` event received | Existing effect modified with clamping | Papyrus |
| 14.3 | P1 | Effect ID collision between mods | Last writer wins (replace semantics); mod authors should namespace IDs | Papyrus |
| 14.4 | P1 | Rapid-fire ModEvents | No crash; performance degrades gracefully for dynamic effects | ArousalManager |
| 14.5 | P2 | ModEvent with None actor | No crash, no-op | Papyrus |

## 15. Maintenance & Cleanup

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 15.1 | P1 | CleanUpActors | Actors not updated since `lastUpdateBefore` removed asynchronously | ArousalManager |
| 15.2 | P1 | Cleanup during active updates | Atomic flag prevents concurrent modification | ArousalManager |
| 15.3 | P2 | Reset script | `slaresetscr` clears all data cleanly | slaresetscr |
| 15.4 | P2 | Unregister effect during gameplay | Slot marked unused, no orphaned data on actors | ArousalManager |

## 16. Thread Safety

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 16.1 | P0 | Concurrent arousal reads | Mutex protects ArousalManager, no data races | ArousalManager |
| 16.2 | P1 | Concurrent effect registration | Mutex serializes, no corruption | ArousalManager |
| 16.3 | P1 | Cleanup + read race | Atomic flag prevents use-after-free | ArousalManager |
| 16.4 | P2 | Papyrus TryLock/Unlock | Script-side synchronization works correctly | Papyrus |

## 17. Translation Files

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 17.1 | P1 | English strings load | MCM labels display correctly | translations/ |
| 17.2 | P2 | Non-English locale | Correct translation file loaded by game engine | translations/ |
| 17.3 | P2 | UTF-16 LE BOM preserved | Translation files maintain encoding after edits | translations/ |

## 18. Compatibility Wrappers

| # | P | Scenario | Expected | Code |
|---|---|----------|----------|------|
| 18.1 | P1 | OAroused legacy API | `OArousedScript` wrapper returns correct arousal values | OArousedScript |
| 18.2 | P2 | MME/Lovers Desire integration | `MME_SLA` bridge functions correctly | MME_SLA |
| 18.3 | P2 | Patch ESPs | DummyESP/SLEN/PAHE patches apply without conflicts | dist/Patches/ |

---

## 19. Known Fragile Areas

These areas are architecturally sensitive and should receive extra attention during changes.

| # | P | Area | Risk | Code |
|---|---|------|------|------|
| 19.1 | P0 | Cosave serialization format | Any change to ArousalData layout breaks existing saves | ArousalManager, SerializationHelper |
| 19.2 | P1 | Static effect slot reuse | Unregistered slot indices may be cached by plugin scripts | ArousalManager |
| 19.3 | P1 | Dynamic effect map iteration order | Serialization must not depend on map ordering | ArousalManager |
| 19.4 | P1 | Group membership after effect unregister | Dissolved groups must not leave orphaned references | ArousalManager |
| 19.5 | P2 | Fast trig table precision | 512-entry sine table introduces quantization; acceptable for game effects | CosSin.h |
| 19.6 | P2 | Plugin Update() frequency | Too-frequent updates with many tracked actors may cause frame drops | sla_PluginBase |

---

*Last updated: 2026-05-01*
