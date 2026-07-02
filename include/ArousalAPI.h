#pragma once

#include <cstdint>

namespace RE {
    class Actor;
}

// ======================================================================================
// SLO Aroused NG - native C++ inter-plugin API
// ======================================================================================
//
// A C++ mirror of the `SloangNative` Papyrus API (the canonical modder interface), for
// SKSE plugins that want to read/drive arousal directly in C++ - same function names,
// units and semantics as the script API, no Papyrus round-trip.
//
// Consumers do NOT link against this plugin - resolve the exports at runtime:
//
//     auto h = GetModuleHandleA("SexlabArousedNG.dll");            // null if not installed
//     if (h) {
//         auto getArousal = reinterpret_cast<float(*)(RE::Actor*)>(
//                               GetProcAddress(h, "SLA_GetArousal"));
//         if (getArousal) float a = getArousal(actor);
//     }
//
// SCOPE: this covers the parts of SloangNative backed by the SKSE plugin's ArousalManager
// - version, arousal reads, and the full dynamic-effects section (convenience wrappers +
// low-level primitives). The SloangNative functions backed by Papyrus quest scripts
// (GetExposure, ModArousal/SetArousal exposure writes, IsActorNaked, exhibitionist /
// arousal-locked / blocked / gender-preference flags, orgasm tracking) are NOT here:
// they live in script, not the DLL. Use the SloangNative Papyrus API for those.
//
// UNITS: arousal is one float per actor, conventionally 0-100 but unclamped (use
// SLA_GetArousalInt for a clamped 0-100). The Add* wrappers take time in IN-GAME HOURS;
// the raw SLA_SetDynamicEffect param is in GAME DAYS (matching SloangNative).
//
// -------------------------------------------------------------------------------------
// THREADING
// -------------------------------------------------------------------------------------
// Thread-safe: call from any thread. The backing per-actor store is guarded by a single
// mutex taken for each operation, held only for pure in-memory work (never across a call
// back into the Papyrus VM), so there is no deadlock/hang risk.
// -------------------------------------------------------------------------------------
//
// ABI: strings cross as `const char*`; actors as `RE::Actor*`; everything else is POD.
// All functions are null-safe. Reads create/track the actor (pull-based, as in Papyrus);
// idle actors are reclaimed by the built-in cleanup. This header is self-contained; a
// consumer including it directly can predefine SLA_API to nothing (they only need the
// signatures for GetProcAddress casts).
// ======================================================================================

#ifndef SLA_API
#    define SLA_API __declspec(dllexport)
#endif

// Timed-function IDs for SLA_SetDynamicEffect (mirror of SloangNative.FuncX()).
//   None        value stays put forever
//   Decay       value halves every `param` game days, stops at `limit` (negative param grows)
//   Linear      value changes by `param` per game day, stops at `limit`
//   Sine        value = (sin(time * param) + 1) * limit, oscillates forever
//   DelayedStep value = 0 until `param` days elapse, then jumps to `limit`
enum SLA_Func : int32_t {
    SLA_FuncNone        = 0,
    SLA_FuncDecay       = 1,
    SLA_FuncLinear      = 2,
    SLA_FuncSine        = 3,
    SLA_FuncDelayedStep = 4,
};

extern "C" {

// ------------------------------------------------------------------------------- Meta
// Packed DLL version, MMmmppp (e.g. 30300000 for 3.3.0). Feature-gate with it:
//   if (SLA_GetVersion() >= 30300000u) { ... }
// Source is the DLL build version (CMakeLists project VERSION). It may lag the Papyrus
// SloangNative.GetVersion() on content-only releases; do not rely on exact equality.
SLA_API uint32_t SLA_GetVersion();
// Version of THIS C++ interface, packed MMmmpp (e.g. 10000 == 1.0.0). Independent of the
// mod version; bumped only when exports are added. New functions are appended, never
// reordered/removed, so a check here is enough to feature-detect the C API surface.
SLA_API uint32_t SLA_GetInterfaceVersion();

// ---------------------------------------------------------------------------- Reading
// Total arousal (sum of every effect), unclamped. 0.0 for a null actor.
SLA_API float   SLA_GetArousal(RE::Actor* who);
// Same, rounded/clamped to 0-100. 0 for a null actor.
SLA_API int32_t SLA_GetArousalInt(RE::Actor* who);

// -------------------------------------------------------- Dynamic effects: convenience
// Named, per-actor, time-aware contributions to arousal. effectId should be namespaced
// with your mod prefix ("MyMod_..."). Each Add* CREATES or REFRESHES the effect (it does
// not stack - use SLA_ModDynamicEffect to accumulate). Time args are IN-GAME HOURS.
// Values may be negative (a negative effect lowers total arousal).

// Constant, non-decaying contribution. Remove with SLA_ClearDynamicEffect.
SLA_API void SLA_AddFlatEffect(RE::Actor* who, const char* effectId, float amount);
// One-shot `amount` that halves every `halveEveryHours` toward 0 (negative amount climbs to 0).
SLA_API void SLA_AddDecayingEffect(RE::Actor* who, const char* effectId, float amount, float halveEveryHours);
// Starts at `startAmount`, changes by `ratePerHour` until it reaches `cap`, then holds.
SLA_API void SLA_AddLinearEffect(RE::Actor* who, const char* effectId, float startAmount, float ratePerHour, float cap);
// Contributes nothing for `delayHours`, then jumps to `amount` and holds.
SLA_API void SLA_AddDelayedEffect(RE::Actor* who, const char* effectId, float amount, float delayHours);
// Removes the named effect entirely (value -> 0, entry dropped). Safe if it doesn't exist.
SLA_API void SLA_ClearDynamicEffect(RE::Actor* who, const char* effectId);
// TRUE if the named effect currently has a non-zero value on `who`.
SLA_API bool SLA_HasDynamicEffect(RE::Actor* who, const char* effectId);

// -------------------------------------------------------- Dynamic effects: low-level
// Only when no convenience wrapper fits; you manage functionId/param/limit yourself.

// Current value of one named effect on `who` (0.0 if absent). Reads back only your effect.
SLA_API float SLA_GetDynamicEffectValue(RE::Actor* who, const char* effectId);
// Create/REPLACE `effectId`. initialValue is SET (absolute); NOTE initialValue == 0 is
// ignored by the engine (use SLA_ClearDynamicEffect to zero/remove). functionId is one of
// SLA_Func*; param/limit are interpreted per function (param in GAME DAYS).
SLA_API void  SLA_SetDynamicEffect(RE::Actor* who, const char* effectId, float initialValue,
                                   int32_t functionId, float param, float limit);
// Add `modifier` to the effect's current value (creating it at `modifier` if absent),
// clamped at `limit` (lower bound if modifier < 0, upper bound if > 0).
SLA_API void  SLA_ModDynamicEffect(RE::Actor* who, const char* effectId, float modifier, float limit);

}  // extern "C"
