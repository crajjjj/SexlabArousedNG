#include "Papyrus.h"
#include "ArousalManager.h"
#include "CosSin.h"

using namespace RE;
using namespace RE::BSScript;
using namespace REL;
using namespace SKSE;
using namespace SLA;

namespace {
    constexpr std::string_view PapyrusClass = "slaInternalModules";
    constexpr std::string_view KWDPapyrusClass = "KeywordUtil";

#define VALIDATE_ACTOR_OR_RETURN(who, ret)                       \
    if (!(who)) {                                                \
        SKSE::log::warn(__FUNCTION__ " called with null actor"); \
        return ret;                                              \
    }

    uint32_t GetStaticEffectCount(StaticFunctionTag*) { return ArousalManager::GetSingleton().GetStaticEffectCount(); }

    uint32_t RegisterStaticEffect(StaticFunctionTag*, std::string name) {
        return ArousalManager::GetSingleton().RegisterStaticEffect(name);
    }

    uint32_t GetStaticEffectId(StaticFunctionTag*, std::string name) {
        return ArousalManager::GetSingleton().GetStaticEffectId(name);
    }

    bool UnregisterStaticEffect(StaticFunctionTag*, std::string name) {
        return ArousalManager::GetSingleton().UnregisterStaticEffect(name);
    }

    bool IsStaticEffectActive(StaticFunctionTag*, Actor* who, int32_t effectIdx) {
        VALIDATE_ACTOR_OR_RETURN(who, false);
        return ArousalManager::GetSingleton().IsStaticEffectActive(who, effectIdx);
    }

    int32_t GetDynamicEffectCount(StaticFunctionTag*, Actor* who) {
        VALIDATE_ACTOR_OR_RETURN(who, 0);
        return ArousalManager::GetSingleton().GetDynamicEffectCount(who);
    }

    std::string GetDynamicEffect(StaticFunctionTag*, Actor* who, int32_t number) {
        VALIDATE_ACTOR_OR_RETURN(who, "");
        return ArousalManager::GetSingleton().GetDynamicEffect(who, number);
    }

    float GetDynamicEffectValueByName(StaticFunctionTag*, Actor* who, std::string effectId) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().GetDynamicEffectValueByName(who, effectId);
    }

    float GetDynamicEffectValue(StaticFunctionTag*, Actor* who, int32_t number) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().GetDynamicEffectValue(who, number);
    }

    float GetStaticEffectValue(StaticFunctionTag*, Actor* who, int32_t effectIdx) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().GetStaticEffectValue(who, effectIdx);
    }

    float GetStaticEffectParam(StaticFunctionTag*, Actor* who, int32_t effectIdx) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().GetStaticEffectParam(who, effectIdx);
    }

    int32_t GetStaticEffectAux(StaticFunctionTag*, Actor* who, int32_t effectIdx) {
        VALIDATE_ACTOR_OR_RETURN(who, 0);
        return ArousalManager::GetSingleton().GetStaticEffectAux(who, effectIdx);
    }

    void SetStaticArousalEffect(StaticFunctionTag*, Actor* who, int32_t effectIdx, int32_t functionId, float param,
                                float limit, int32_t auxilliary) {
        if (!who) return;
        ArousalManager::GetSingleton().SetStaticArousalEffect(who, effectIdx, functionId, param, limit, auxilliary);
    }

    void SetDynamicArousalEffect(StaticFunctionTag*, Actor* who, std::string effectId, float initialValue,
                                 int32_t functionId, float param, float limit) {
        if (!who) return;
        ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, initialValue, functionId, param, limit);
    }

    void ModDynamicArousalEffect(StaticFunctionTag*, Actor* who, std::string effectId, float modifier, float limit) {
        if (!who) return;
        ArousalManager::GetSingleton().ModDynamicArousalEffect(who, effectId, modifier, limit);
    }

    void SetStaticArousalValue(StaticFunctionTag*, Actor* who, int32_t effectIdx, float value) {
        if (!who) return;
        ArousalManager::GetSingleton().SetStaticArousalValue(who, effectIdx, value);
    }

    void SetStaticAuxillaryFloat(StaticFunctionTag*, Actor* who, int32_t effectIdx, float value) {
        if (!who) return;
        ArousalManager::GetSingleton().SetStaticAuxillaryFloat(who, effectIdx, value);
    }

    void SetStaticAuxillaryInt(StaticFunctionTag*, Actor* who, int32_t effectIdx, int32_t value) {
        if (!who) return;
        ArousalManager::GetSingleton().SetStaticAuxillaryInt(who, effectIdx, value);
    }

    float ModStaticArousalValue(StaticFunctionTag*, Actor* who, int32_t effectIdx, float diff, float limit) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().ModStaticArousalValue(who, effectIdx, diff, limit);
    }

    float GetArousal(StaticFunctionTag*, Actor* who) {
        VALIDATE_ACTOR_OR_RETURN(who, 0.f);
        return ArousalManager::GetSingleton().GetArousal(who);
    }

    void UpdateSingleActorArousal(StaticFunctionTag*, Actor* who, float GameDaysPassed) {
        if (!who) return;
        ArousalManager::GetSingleton().UpdateSingleActorArousal(who, GameDaysPassed);
    }

    bool GroupEffects(StaticFunctionTag*, Actor* who, int32_t idx, int32_t idx2) {
        VALIDATE_ACTOR_OR_RETURN(who, false);
        return ArousalManager::GetSingleton().GroupEffects(who, idx, idx2);
    }

    bool RemoveEffectGroup(StaticFunctionTag*, Actor* who, int32_t idx) {
        VALIDATE_ACTOR_OR_RETURN(who, false);
        return ArousalManager::GetSingleton().RemoveEffectGroup(who, idx);
    }

    int32_t CleanUpActors(StaticFunctionTag*, float lastUpdateBefore) {
        return ArousalManager::GetSingleton().CleanUpActors(lastUpdateBefore);
    }

    bool TryLock(StaticFunctionTag*, int32_t lock) { return ArousalManager::GetSingleton().TryLock(lock); }

    void Unlock(StaticFunctionTag*, int32_t lock) { ArousalManager::GetSingleton().Unlock(lock); }

    std::vector<Actor*> DuplicateActorArray(StaticFunctionTag*, std::vector<Actor*> arr, int32_t count) {
        std::vector<Actor*> result;
        int32_t maxCount = std::min<int32_t>(count, static_cast<int32_t>(arr.size()));
        result.reserve(maxCount);
        for (int32_t i = 0; i < maxCount; ++i) {
            result.push_back(arr[i]);
        }
        return result;
    }

    void AddKeywordToForm(StaticFunctionTag*, RE::TESForm* form, RE::BGSKeyword* kwd) {
        if (form && kwd) {
            if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                keywordForm->AddKeyword(kwd);
            }
        }
    }

    void AddKeywordToForms(StaticFunctionTag*, std::vector<RE::TESForm*> forms, RE::BGSKeyword* kwd) {
        for (auto form : forms) {
            if (form && kwd) {
                if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                    keywordForm->AddKeyword(kwd);
                }
            }
        }
    }

    void RemoveKeywordFromForm(StaticFunctionTag*, RE::TESForm* form, RE::BGSKeyword* kwd) {
        if (form && kwd) {
            if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                keywordForm->RemoveKeyword(kwd);
            }
        }
    }

    void RemoveKeywordFromForms(StaticFunctionTag*, std::vector<RE::TESForm*> forms, RE::BGSKeyword* kwd) {
        for (auto form : forms) {
            if (form && kwd) {
                if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                    keywordForm->RemoveKeyword(kwd);
                }
            }
        }
    }

    std::string FormatHex(StaticFunctionTag*, int num) { return "0x" + std::format("{:x}", num); }

}  // namespace

bool SLA::RegisterFunctions(IVirtualMachine* vm) {
    BuildSinCosTable();

    vm->RegisterFunction("GetStaticEffectCount", PapyrusClass, GetStaticEffectCount);
    vm->RegisterFunction("RegisterStaticEffect", PapyrusClass, RegisterStaticEffect);
    vm->RegisterFunction("GetStaticEffectId", PapyrusClass, GetStaticEffectId);
    vm->RegisterFunction("UnregisterStaticEffect", PapyrusClass, UnregisterStaticEffect);
    vm->RegisterFunction("IsStaticEffectActive", PapyrusClass, IsStaticEffectActive);
    vm->RegisterFunction("GetDynamicEffectCount", PapyrusClass, GetDynamicEffectCount);
    vm->RegisterFunction("GetDynamicEffect", PapyrusClass, GetDynamicEffect);
    vm->RegisterFunction("GetDynamicEffectValueByName", PapyrusClass, GetDynamicEffectValueByName);
    vm->RegisterFunction("GetDynamicEffectValue", PapyrusClass, GetDynamicEffectValue);
    vm->RegisterFunction("GetStaticEffectValue", PapyrusClass, GetStaticEffectValue);
    vm->RegisterFunction("GetStaticEffectParam", PapyrusClass, GetStaticEffectParam);
    vm->RegisterFunction("GetStaticEffectAux", PapyrusClass, GetStaticEffectAux);
    vm->RegisterFunction("SetStaticArousalEffect", PapyrusClass, SetStaticArousalEffect);
    vm->RegisterFunction("SetDynamicArousalEffect", PapyrusClass, SetDynamicArousalEffect);
    vm->RegisterFunction("ModDynamicArousalEffect", PapyrusClass, ModDynamicArousalEffect);
    vm->RegisterFunction("SetStaticArousalValue", PapyrusClass, SetStaticArousalValue);
    vm->RegisterFunction("SetStaticAuxillaryFloat", PapyrusClass, SetStaticAuxillaryFloat);
    vm->RegisterFunction("SetStaticAuxillaryInt", PapyrusClass, SetStaticAuxillaryInt);
    vm->RegisterFunction("ModStaticArousalValue", PapyrusClass, ModStaticArousalValue);
    vm->RegisterFunction("GetArousal", PapyrusClass, GetArousal);
    vm->RegisterFunction("UpdateSingleActorArousal", PapyrusClass, UpdateSingleActorArousal);

    vm->RegisterFunction("GroupEffects", PapyrusClass, GroupEffects);
    vm->RegisterFunction("RemoveEffectGroup", PapyrusClass, RemoveEffectGroup);

    vm->RegisterFunction("CleanUpActors", PapyrusClass, CleanUpActors);

    vm->RegisterFunction("TryLock", PapyrusClass, TryLock);
    vm->RegisterFunction("Unlock", PapyrusClass, Unlock);
    vm->RegisterFunction("DuplicateActorArray", PapyrusClass, DuplicateActorArray);

    vm->RegisterFunction("AddKeywordToForm", KWDPapyrusClass, AddKeywordToForm);
    vm->RegisterFunction("AddKeywordToForms", KWDPapyrusClass, AddKeywordToForms);
    vm->RegisterFunction("RemoveKeywordFromForm", KWDPapyrusClass, RemoveKeywordFromForm);
    vm->RegisterFunction("RemoveKeywordFromForms", KWDPapyrusClass, RemoveKeywordFromForms);

    //misc
    vm->RegisterFunction("FormatHex", PapyrusClass, FormatHex);

    return true;
}