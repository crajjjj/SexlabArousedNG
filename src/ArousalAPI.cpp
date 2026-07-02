#include "ArousalAPI.h"

#include "ArousalManager.h"

// Native C++ exports for other SKSE plugins - a mirror of the SloangNative Papyrus API
// for the parts backed by ArousalManager (version, arousal reads, dynamic effects). Thin,
// null-safe forwarders onto the same ArousalManager methods the Papyrus bindings use, so
// these are thread-safe and callable from any thread. See include/ArousalAPI.h for scope
// and the consumer contract.
//
// The convenience wrappers replicate SloangNative's hour->game-day conversions and
// timed-function choices exactly, so C++ and Papyrus callers get identical behaviour.

using SLA::ArousalManager;

extern "C" {

// ------------------------------------------------------------------------------- Meta

uint32_t SLA_GetVersion() {
    // Packed from the DLL's own version resource (CMakeLists project VERSION), so it
    // tracks the release automatically. MMmmppp: major*1e7 + minor*1e5 + patch.
    const auto v = SKSE::PluginDeclaration::GetSingleton()->GetVersion();
    return static_cast<uint32_t>(v[0]) * 10000000u +
           static_cast<uint32_t>(v[1]) * 100000u +
           static_cast<uint32_t>(v[2]);
}

uint32_t SLA_GetInterfaceVersion() {
    return 10000;  // 1.0.0
}

// ---------------------------------------------------------------------------- Reading

float SLA_GetArousal(RE::Actor* who) {
    if (!who) return 0.0f;
    return ArousalManager::GetSingleton().GetArousal(who);
}

int32_t SLA_GetArousalInt(RE::Actor* who) {
    if (!who) return 0;
    // Truncate toward zero (matches Papyrus `float as int`), then clamp to 0-100.
    const int32_t v = static_cast<int32_t>(ArousalManager::GetSingleton().GetArousal(who));
    return std::clamp(v, 0, 100);
}

// -------------------------------------------------------- Dynamic effects: convenience

void SLA_AddFlatEffect(RE::Actor* who, const char* effectId, float amount) {
    if (!who || !effectId) return;
    ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, amount, SLA_FuncNone, 0.0f, 0.0f);
}

void SLA_AddDecayingEffect(RE::Actor* who, const char* effectId, float amount, float halveEveryHours) {
    if (!who || !effectId) return;
    ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, amount, SLA_FuncDecay,
                                                           halveEveryHours / 24.0f, 0.0f);
}

void SLA_AddLinearEffect(RE::Actor* who, const char* effectId, float startAmount, float ratePerHour, float cap) {
    if (!who || !effectId) return;
    ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, startAmount, SLA_FuncLinear,
                                                           ratePerHour * 24.0f, cap);
}

void SLA_AddDelayedEffect(RE::Actor* who, const char* effectId, float amount, float delayHours) {
    if (!who || !effectId) return;
    // Value starts at 0 (a new effect defaults to 0; initialValue 0 is ignored) and the
    // step function drives it to `amount` (the limit) after the delay.
    ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, 0.0f, SLA_FuncDelayedStep,
                                                           delayHours / 24.0f, amount);
}

void SLA_ClearDynamicEffect(RE::Actor* who, const char* effectId) {
    if (!who || !effectId) return;
    auto& mgr = ArousalManager::GetSingleton();
    // Drive the value to the 0 floor, then set function None with value 0 so the engine drops it.
    mgr.ModDynamicArousalEffect(who, effectId, -1000000.0f, 0.0f);
    mgr.SetDynamicArousalEffect(who, effectId, 0.0f, SLA_FuncNone, 0.0f, 0.0f);
}

bool SLA_HasDynamicEffect(RE::Actor* who, const char* effectId) {
    if (!who || !effectId) return false;
    return ArousalManager::GetSingleton().GetDynamicEffectValueByName(who, effectId) != 0.0f;
}

// -------------------------------------------------------- Dynamic effects: low-level

float SLA_GetDynamicEffectValue(RE::Actor* who, const char* effectId) {
    if (!who || !effectId) return 0.0f;
    return ArousalManager::GetSingleton().GetDynamicEffectValueByName(who, effectId);
}

void SLA_SetDynamicEffect(RE::Actor* who, const char* effectId, float initialValue,
                          int32_t functionId, float param, float limit) {
    if (!who || !effectId) return;
    ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, initialValue, functionId, param, limit);
}

void SLA_ModDynamicEffect(RE::Actor* who, const char* effectId, float modifier, float limit) {
    if (!who || !effectId) return;
    ArousalManager::GetSingleton().ModDynamicArousalEffect(who, effectId, modifier, limit);
}

}  // extern "C"
