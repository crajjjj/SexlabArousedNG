#include "ArousalManager.h"
#include "SerializationHelper.h"

namespace SLA {
    
    ArousalManager& ArousalManager::GetSingleton() noexcept {
        static ArousalManager instance;
        return instance;
    }

    int ArousalManager::GetStaticEffectCount() { return staticEffectCount; }

    uint32_t ArousalManager::RegisterStaticEffect(std::string name) {
        auto itr = staticEffectIds.find(name);
        if (itr != staticEffectIds.end()) return itr->second;

        int32_t unusedId = GetHighestUnusedEffectId();
        if (unusedId != -1) {
            auto itr = staticEffectIds.find(GetUnusedEffectId(unusedId));
            assert(itr != staticEffectIds.end());
            int32_t effectId = itr->second;
            staticEffectIds.erase(itr);
            staticEffectIds[name] = effectId;
            return effectId;
        }

        staticEffectIds[name] = staticEffectCount;
        for (auto& data : arousalData) data.second.OnRegisterStaticEffect();
        const auto result = staticEffectCount;
        staticEffectCount++;
        return result;
    }

    std::string ArousalManager::GetUnusedEffectId(int32_t id) { return "Unused" + std::to_string(id); }

    int32_t ArousalManager::GetHighestUnusedEffectId() {
        int32_t result = -1;
        while (staticEffectIds.find(GetUnusedEffectId(result + 1)) != staticEffectIds.end()) result += 1;
        return result;
    }

    bool ArousalManager::UnregisterStaticEffect(std::string name) {
        auto itr = staticEffectIds.find(name);
        if (itr != staticEffectIds.end()) {
            uint32_t id = itr->second;
            staticEffectIds.erase(itr);
            int32_t unusedId = GetHighestUnusedEffectId();
            staticEffectIds[GetUnusedEffectId(unusedId + 1)] = id;
            for (auto& data : arousalData) data.second.OnUnregisterStaticEffect(id);
            return true;
        }
        return false;
    }

    ArousalData& ArousalManager::GetArousalData(RE::Actor* who) {
        if (!who) throw std::invalid_argument("Attempt to get arousal data for none actor");
        RE::FormID formId = who->formID;
        if (lastLookup == formId && lastData) return *lastData;
        auto& result = arousalData[formId];
        lastLookup = formId;
        lastData = &result;
        return result;
    }

    bool ArousalManager::IsStaticEffectActive(RE::Actor* who, int32_t effectIdx) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.IsStaticEffectActive(effectIdx);
        } catch (std::exception) {
            return false;
        }
    }

    int32_t ArousalManager::GetDynamicEffectCount(RE::Actor* who) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.GetDynamicEffectCount();
        } catch (std::exception) {
            return 0;
        }
    }

    std::string ArousalManager::GetDynamicEffect(RE::Actor* who, int32_t number) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.GetDynamicEffect(number);
        } catch (std::exception) {
            return "";
        }
    }

    float ArousalManager::GetDynamicEffectValueByName(RE::Actor* who, std::string effectId) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.GetDynamicEffectValueByName(effectId);
        } catch (std::exception) {
            return 0.0;
        }
    }

    float ArousalManager::GetDynamicEffectValue(RE::Actor* who, int32_t number) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.GetDynamicEffectValue(number);
        } catch (std::exception) {
            return std::numeric_limits<float>::lowest();
        }
    }

    float ArousalManager::GetStaticEffectValue(RE::Actor* who, int32_t effectIdx) {
        try {
            ArousalData& data = GetArousalData(who);
            if (auto group = data.GetEffectGroup(effectIdx)) 
                return group->value;
            ArousalEffectData& effect = data.GetStaticArousalEffect(effectIdx);
            return effect.value;
        } catch (std::exception) {
            return 0.f;
        }
    }

    float ArousalManager::GetStaticEffectParam(RE::Actor* who, int32_t effectIdx) {
        try {
            ArousalEffectData& effect = GetStaticArousalEffect(who, effectIdx);
            return effect.param;
        } catch (std::exception) {
            return 0.f;
        }
    }

    int32_t ArousalManager::GetStaticEffectAux(RE::Actor* who, int32_t effectIdx) {
        try {
            ArousalEffectData& effect = GetStaticArousalEffect(who, effectIdx);
            return effect.intAux;
        } catch (std::exception) {
            return 0;
        }
    }

    ArousalEffectData& ArousalManager::GetStaticArousalEffect(RE::Actor* who, int32_t effectIdx) {
        ArousalData& data = GetArousalData(who);
        return data.GetStaticArousalEffect(effectIdx);
    }

    void ArousalManager::SetStaticArousalEffect(RE::Actor* who, int32_t effectIdx, int32_t functionId, float param,
                                float limit, int32_t auxilliary) {
        try {
            ArousalData& data = GetArousalData(who);
            data.SetStaticArousalEffect(effectIdx, functionId, param, limit, auxilliary);
        } catch (std::exception) {
        }
    }
    void ArousalManager::SetDynamicArousalEffect(RE::Actor* who, std::string effectId, float initialValue,
                                 int32_t functionId, float param, float limit) {
        try {
            ArousalData& data = GetArousalData(who);
            data.SetDynamicArousalEffect(effectId, initialValue, functionId, param, limit);
        } catch (std::exception) {
        }
    }
    void ArousalManager::ModDynamicArousalEffect(RE::Actor* who, std::string effectId, float modifier,
                                 float limit) {
        try {
            ArousalData& data = GetArousalData(who);
            data.ModDynamicArousalEffect(effectId, modifier, limit);
        } catch (std::exception) {
        }
    }
    void ArousalManager::SetStaticArousalValue(RE::Actor* who, int32_t effectIdx, float value) {
        try {
            ArousalData& data = GetArousalData(who);
            data.SetStaticArousalValue(effectIdx, value);
        } catch (std::exception) {
        }
    }
    void ArousalManager::SetStaticAuxillaryFloat(RE::Actor* who, int32_t effectIdx, float value) {
        try {
            ArousalData& data = GetArousalData(who);
            ArousalEffectData& effect = data.GetStaticArousalEffect(effectIdx);

            effect.floatAux = value;
        } catch (std::exception) {
        }
    }
    void ArousalManager::SetStaticAuxillaryInt(RE::Actor* who, int32_t effectIdx, int32_t value) {
        try {
            ArousalData& data = GetArousalData(who);
            ArousalEffectData& effect = data.GetStaticArousalEffect(effectIdx);

            effect.intAux = value;
        } catch (std::exception) {
        }
    }
    float ArousalManager::ModStaticArousalValue(RE::Actor* who, int32_t effectIdx, float diff, float limit) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.ModStaticArousalValue(effectIdx, diff, limit);
        } catch (std::exception) {
            return 0.f;
        }
    }
    float ArousalManager::GetArousal(RE::Actor* who) {
        try {
            return GetArousalData(who).GetArousal();
        } catch (std::exception) {
            return 0.f;
        }
    }
    void ArousalManager::UpdateSingleActorArousal(RE::Actor* who, float GameDaysPassed) {
        try {
            ArousalData& data = GetArousalData(who);
            data.UpdateSingleActorArousal(who, GameDaysPassed);
        } catch (std::exception) {
        }
    }

    bool ArousalManager::GroupEffects(RE::Actor* who, int32_t idx, int32_t idx2) {
        try {
            ArousalData& data = GetArousalData(who);
            return data.GroupEffects(who, idx, idx2);
        } catch (std::exception) {
            return false;
        }
    }

    bool ArousalManager::RemoveEffectGroup(RE::Actor* who, int32_t idx) {
        try {
            ArousalData& data = GetArousalData(who);
            data.RemoveEffectGroup(idx);
            return true;
        } catch (std::exception) {
            return false;
        }
    }

    int32_t ArousalManager::CleanUpActors(float lastUpdateBefore) {
        int32_t removed = 0;
        for (auto itr = arousalData.begin(); itr != arousalData.end();) {
            if (itr->second.GetLastUpdate() < lastUpdateBefore) {
                itr = arousalData.erase(itr);
                ++removed;
            } else
                ++itr;
        }
        return removed;
    }

    bool ArousalManager::TryLock(int32_t lock) {
        if (lock < 0 || lock >= locks.size()) return false;
        if (locks[lock].test_and_set()) return false;
        return true;
    }

    void ArousalManager::Unlock(int32_t lock) {
        if (lock < 0 || lock >= locks.size()) return;

        locks[lock].clear();
    }

    const uint32_t kSerializationDataVersion = 1;
    void ArousalManager::OnRevert(SKSE::SerializationInterface*) {
        ArousalManager& inst = ArousalManager::GetSingleton();
        SKSE::log::info("revert");

        staticEffectCount = 0;
        inst.staticEffectIds.clear();

        inst.lastLookup = 0;
        inst.lastData = nullptr;
        inst.arousalData.clear();

        for (auto& lock : inst.locks) lock.clear();
    }
    void ArousalManager::OnGameSaved(SKSE::SerializationInterface* serde) {
        using namespace Serialization;

        ArousalManager& inst = ArousalManager::GetSingleton();
        SKSE::log::info("save");

        if (serde->OpenRecord('DATA', kSerializationDataVersion)) {
            serde->WriteRecordData(&staticEffectCount, sizeof(staticEffectCount));
            for (auto const& kvp : inst.staticEffectIds) {
                WriteString(serde, kvp.first);
                int32_t id = kvp.second;
                serde->WriteRecordData(&id, sizeof(id));
            }
            uint32_t entryCount = static_cast<uint32_t>(inst.arousalData.size());
            serde->WriteRecordData(&entryCount, sizeof(entryCount));
            for (auto const& entry : inst.arousalData) {
                ArousalData const& data = entry.second;
                uint32_t formId = entry.first;
                serde->WriteRecordData(&formId, sizeof(formId));
                data.Serialize(serde);
            }
        }
        SKSE::log::info("finished saving");

    }
    void ArousalManager::OnGameLoaded(SKSE::SerializationInterface* serde) {
        ArousalManager& inst = ArousalManager::GetSingleton();

        SKSE::log::info("load");

        uint32_t type;
        uint32_t version;
        uint32_t length;
        bool error = false;

        while (!error && serde->GetNextRecordInfo(type, version, length)) {
            switch (type) {
                case 'DATA': {
                    if (version == kSerializationDataVersion) {
                        SKSE::log::info("Version correct");
                        try {
                            staticEffectCount = Serialization::ReadDataHelper<uint32_t>(serde, length);
                            SKSE::log::info("Loading {} effects... ", staticEffectCount);
                            for (uint32_t i = 0; i < staticEffectCount; ++i) {
                                std::string effect = Serialization::ReadString(serde, length);
                                uint32_t id = Serialization::ReadDataHelper<uint32_t>(serde, length);
                                inst.staticEffectIds[effect] = id;
                            }
                            uint32_t entryCount = Serialization::ReadDataHelper<uint32_t>(serde, length);
                            SKSE::log::info("Loading {} data sets... ", entryCount);
                            for (uint32_t i = 0; i < entryCount; ++i) {
                                uint32_t formId = Serialization::ReadDataHelper<uint32_t>(serde, length);
                                ArousalData data(serde, length);
                                uint32_t newFormId;
                                if (!serde->ResolveFormID(formId, newFormId)) continue;
                                inst.arousalData[newFormId] = std::move(data);
                            }
                        } catch (std::exception) {
                            error = true;
                        }
                    } else
                        error = true;
                } break;

                default:
                    SKSE::log::info("unhandled type {}", type);
                    error = true;
                    break;
            }
        }

        if (error) SKSE::log::info("Encountered error while loading data");

        SKSE::log::info("finished loading");

    }
}
