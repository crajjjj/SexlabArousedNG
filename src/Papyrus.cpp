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

    uint32_t GetStaticEffectCount(StaticFunctionTag* base) {
        return ArousalManager::GetSingleton().GetStaticEffectCount();
    }
    uint32_t RegisterStaticEffect(StaticFunctionTag* base, std::string name) {
        return ArousalManager::GetSingleton().RegisterStaticEffect(name);
    }
    bool UnregisterStaticEffect(StaticFunctionTag* base, std::string name) {
        return ArousalManager::GetSingleton().UnregisterStaticEffect(name);
    }
    bool IsStaticEffectActive(StaticFunctionTag* base, Actor* who, int32_t effectIdx) {
        return ArousalManager::GetSingleton().IsStaticEffectActive(who, effectIdx);
    }
    int32_t GetDynamicEffectCount(StaticFunctionTag* base, Actor* who) {
        return ArousalManager::GetSingleton().GetDynamicEffectCount(who);
    }
    std::string GetDynamicEffect(StaticFunctionTag* base, Actor* who, int32_t number) {
        return ArousalManager::GetSingleton().GetDynamicEffect(who, number);
    }
    float GetDynamicEffectValueByName(StaticFunctionTag* base, Actor* who, std::string effectId) {
        return ArousalManager::GetSingleton().GetDynamicEffectValueByName(who, effectId);
    }
    float GetDynamicEffectValue(StaticFunctionTag* base, Actor* who, int32_t number) {
        return ArousalManager::GetSingleton().GetDynamicEffectValue(who, number);
    }
    float GetStaticEffectValue(StaticFunctionTag* base, Actor* who, int32_t effectIdx) {
        return ArousalManager::GetSingleton().GetStaticEffectValue(who, effectIdx);
    }
    float GetStaticEffectParam(StaticFunctionTag* base, Actor* who, int32_t effectIdx) {
        return ArousalManager::GetSingleton().GetStaticEffectParam(who, effectIdx);
    }
    int32_t GetStaticEffectAux(StaticFunctionTag* base, Actor* who, int32_t effectIdx) {
        return ArousalManager::GetSingleton().GetStaticEffectAux(who, effectIdx);
    }
    void SetStaticArousalEffect(StaticFunctionTag* base, Actor* who, int32_t effectIdx, int32_t functionId, float param,
                                float limit, int32_t auxilliary) {
        return ArousalManager::GetSingleton().SetStaticArousalEffect(who, effectIdx, functionId, param, limit,
                                                                     auxilliary);
    }
    void SetDynamicArousalEffect(StaticFunctionTag* base, Actor* who, std::string effectId, float initialValue,
                                 int32_t functionId, float param, float limit) {
        return ArousalManager::GetSingleton().SetDynamicArousalEffect(who, effectId, initialValue, functionId, param,
                                                                      limit);
    }
    void ModDynamicArousalEffect(StaticFunctionTag* base, Actor* who, std::string effectId, float modifier,
                                 float limit) {
        return ArousalManager::GetSingleton().ModDynamicArousalEffect(who, effectId, modifier, limit);
    }
    void SetStaticArousalValue(StaticFunctionTag* base, Actor* who, int32_t effectIdx, float value) {
        return ArousalManager::GetSingleton().SetStaticArousalValue(who, effectIdx, value);
    }
    void SetStaticAuxillaryFloat(StaticFunctionTag* base, Actor* who, int32_t effectIdx, float value) {
        return ArousalManager::GetSingleton().SetStaticAuxillaryFloat(who, effectIdx, value);
    }
    void SetStaticAuxillaryInt(StaticFunctionTag* base, Actor* who, int32_t effectIdx, int32_t value) {
        return ArousalManager::GetSingleton().SetStaticAuxillaryInt(who, effectIdx, value);
    }
    float ModStaticArousalValue(StaticFunctionTag* base, Actor* who, int32_t effectIdx, float diff, float limit) {
        return ArousalManager::GetSingleton().ModStaticArousalValue(who, effectIdx, diff, limit);
    }
    float GetArousal(StaticFunctionTag* base, Actor* who) { return ArousalManager::GetSingleton().GetArousal(who); }
    void UpdateSingleActorArousal(StaticFunctionTag* base, Actor* who, float GameDaysPassed) {
        return ArousalManager::GetSingleton().UpdateSingleActorArousal(who, GameDaysPassed);
    }
    bool GroupEffects(StaticFunctionTag* base, Actor* who, int32_t idx, int32_t idx2) {
        return ArousalManager::GetSingleton().GroupEffects(who, idx, idx2);
    }
    bool RemoveEffectGroup(StaticFunctionTag* base, Actor* who, int32_t idx) {
        return ArousalManager::GetSingleton().RemoveEffectGroup(who, idx);
    }
    int32_t CleanUpActors(StaticFunctionTag* base, float lastUpdateBefore) {
        return ArousalManager::GetSingleton().CleanUpActors(lastUpdateBefore);
    }
    bool TryLock(StaticFunctionTag* base, int32_t lock) { return ArousalManager::GetSingleton().TryLock(lock); }
    void Unlock(StaticFunctionTag* base, int32_t lock) { return ArousalManager::GetSingleton().Unlock(lock); }
    std::vector<Actor*> DuplicateActorArray(StaticFunctionTag* base, std::vector<Actor*> arr, int32_t count) {
        std::vector<Actor*> result;
        result.reserve(count);
        for (int32_t i = 0; i < count; ++i) {
            Actor* actor = arr[i];
            result.push_back(actor);
        }
        return result;
    }

    void AddKeywordToForm(StaticFunctionTag* base, RE::TESForm* form, RE::BGSKeyword* kwd) {
        if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
            keywordForm->AddKeyword(kwd);
        }
    }
    void AddKeywordToForms(StaticFunctionTag* base, std::vector<RE::TESForm*> forms, RE::BGSKeyword* kwd) {
        for (auto form : forms) {
            if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                keywordForm->AddKeyword(kwd);
            }
        }
    }
    void RemoveKeywordFromForm(StaticFunctionTag* base, RE::TESForm* form, RE::BGSKeyword* kwd) {
        if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
            keywordForm->RemoveKeyword(kwd);
        }
    }
    void RemoveKeywordFromForms(StaticFunctionTag* base, std::vector<RE::TESForm*> forms, RE::BGSKeyword* kwd) {
        for (auto form : forms) {
            if (const auto keywordForm = form->As<RE::BGSKeywordForm>(); keywordForm) {
                keywordForm->RemoveKeyword(kwd);
            }
        }
    }

    std::string FormatHex(StaticFunctionTag* base, int num) {
        return "0x" + std::format("{:x}", num);
    }

}  // namespace

bool SLA::RegisterFunctions(IVirtualMachine* vm) {
    BuildSinCosTable();

    vm->RegisterFunction("GetStaticEffectCount", PapyrusClass, GetStaticEffectCount);
    vm->RegisterFunction("RegisterStaticEffect", PapyrusClass, RegisterStaticEffect);
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