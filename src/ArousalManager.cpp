#include "ArousalManager.h"

#include "SerializationHelper.h"

namespace SLA {

    class AtomicFlagGuard {
    public:
        explicit AtomicFlagGuard(std::atomic_flag& flag) : _flag(flag), _owns(false) {
            _owns = !_flag.test_and_set(std::memory_order_acquire);
            SKSE::log::info("AtomicFlagGuard cleanupLock set.");
        }
        ~AtomicFlagGuard() {
            if (_owns) {
                _flag.clear(std::memory_order_release);
                SKSE::log::info("AtomicFlagGuard cleanupLock removed.");
            }
        }
        bool owns_lock() const { return _owns; }

    private:
        std::atomic_flag& _flag;
        bool _owns;
    };

    ArousalManager& ArousalManager::GetSingleton() noexcept {
        static ArousalManager instance;
        return instance;
    }

    int ArousalManager::GetStaticEffectCount() {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("GetStaticEffectCount called during cleanup, skipping.");
            return 0;
        }
        return staticEffectCount;
    }

    int32_t ArousalManager::RegisterStaticEffect(std::string name) {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("RegisterStaticEffect called during cleanup, skipping.");
            return -2;
        }
        auto itr = staticEffectIds.find(name);
        if (itr != staticEffectIds.end()) return itr->second;

        int32_t unusedId = GetHighestUnusedEffectId();
        if (unusedId != -1) {
            auto itr2 = staticEffectIds.find(GetUnusedEffectId(unusedId));
            if (itr2 == staticEffectIds.end()) {
                SKSE::log::warn("Unused ID lookup failed in RegisterStaticEffect");
                return 0;
            }
            int32_t effectId = static_cast<int32_t>(itr2->second);
            staticEffectIds.erase(itr2);
            staticEffectIds[name] = static_cast<uint32_t>(effectId);
            return effectId;
        }

        staticEffectIds[name] = static_cast<uint32_t>(staticEffectCount);
        for (auto& data : arousalData) data.second.OnRegisterStaticEffect();
        const auto result = staticEffectCount;
        staticEffectCount++;
        return result;
    }
    int32_t ArousalManager::GetStaticEffectId(std::string name) {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("GetStaticEffectId called during cleanup, skipping.");
            return -2;
        }
        auto itr = staticEffectIds.find(name);
        if (itr != staticEffectIds.end()) return static_cast<int32_t>(itr->second);
        return -1;  // Not found, return -1 to indicate error
    }
    
    std::string ArousalManager::GetUnusedEffectId(int32_t id) { return "Unused" + std::to_string(id); }

    int32_t ArousalManager::GetHighestUnusedEffectId() {
        int32_t result = -1;
        while (staticEffectIds.find(GetUnusedEffectId(result + 1)) != staticEffectIds.end()) result += 1;
        return result;
    }

    bool ArousalManager::UnregisterStaticEffect(std::string name) {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("UnregisterStaticEffect called during cleanup, skipping.");
            return false;
        }
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

    // Use this private helper to avoid code duplication
    ArousalData* ArousalManager::TryGetArousalData(RE::Actor* who) {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("TryGetArousalData: locked for cleanup, skipping actor {}", who ? who->formID : 0);
            return nullptr;
        }
        if (!who) {
            SKSE::log::warn("TryGetArousalData called with nullptr actor");
            return nullptr;
        }
       
        RE::FormID formId = who->formID;
        // if (lastLookup == formId && lastData) return *lastData; //to not mutex it
        auto& result = arousalData[formId];
        lastLookup = formId;
        lastData = &result;
        return &result;
    }

    ArousalData* ArousalManager::GetArousalData(RE::Actor* who) {
        if (cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("TryGetArousalData: locked for cleanup, skipping actor {}", who ? who->formID : 0);
            return nullptr;
        }
        // For internal use, you can assume this is not called during cleanup
        if (!who) throw std::invalid_argument("Attempt to get arousal data for none actor");
        RE::FormID formId = who->formID;
        //if (lastLookup == formId && lastData) return *lastData; //to not mutex it
        auto& result = arousalData[formId];
        lastLookup = formId;
        lastData = &result;
        return &result;
    }

    bool ArousalManager::IsStaticEffectActive(RE::Actor* who, int32_t effectIdx) {
        auto data = TryGetArousalData(who);
        if (!data) return false;
        try {
            return data->IsStaticEffectActive(effectIdx);
        } catch (std::exception& e) {
            SKSE::log::warn("IsStaticEffectActive: {}", e.what());
            return false;
        }
    }

    int32_t ArousalManager::GetDynamicEffectCount(RE::Actor* who) {
        auto data = TryGetArousalData(who);
        if (!data) return 0;
        try {
            return data->GetDynamicEffectCount();
        } catch (std::exception& e) {
            SKSE::log::warn("GetDynamicEffectCount: {}", e.what());
            return 0;
        }
    }

    std::string ArousalManager::GetDynamicEffect(RE::Actor* who, int32_t number) {
        auto data = TryGetArousalData(who);
        if (!data) return "";
        try {
            return data->GetDynamicEffect(number);
        } catch (std::exception& e) {
            SKSE::log::warn("GetDynamicEffect: {}", e.what());
            return "";
        }
    }

    float ArousalManager::GetDynamicEffectValueByName(RE::Actor* who, std::string effectId) {
        auto data = TryGetArousalData(who);
        if (!data) return 0.0f;
        try {
            return data->GetDynamicEffectValueByName(effectId);
        } catch (std::exception& e) {
            SKSE::log::warn("GetDynamicEffectValueByName: {}", e.what());
            return 0.0f;
        }
    }

    float ArousalManager::GetDynamicEffectValue(RE::Actor* who, int32_t number) {
        auto data = TryGetArousalData(who);
        if (!data) return std::numeric_limits<float>::lowest();
        try {
            return data->GetDynamicEffectValue(number);
        } catch (std::exception& e) {
            SKSE::log::warn("GetDynamicEffectValue: {}", e.what());
            return std::numeric_limits<float>::lowest();
        }
    }

    float ArousalManager::GetStaticEffectValue(RE::Actor* who, int32_t effectIdx) {
        auto data = TryGetArousalData(who);
        if (!data) return 0.0f;
        try {
            if (auto group = data->GetEffectGroup(effectIdx)) return group->value;
            ArousalEffectData& effect = data->GetStaticArousalEffect(effectIdx);
            return effect.value;
        } catch (std::exception& e) {
            SKSE::log::warn("GetStaticEffectValue: {}", e.what());
            return 0.0f;
        }
    }

    float ArousalManager::GetStaticEffectParam(RE::Actor* who, int32_t effectIdx) {
        auto data = TryGetArousalData(who);
        if (!data) return 0.0f;
        try {
            ArousalEffectData& effect = data->GetStaticArousalEffect(effectIdx);
            return effect.param;
        } catch (std::exception& e) {
            SKSE::log::warn("GetStaticEffectParam: {}", e.what());
            return 0.0f;
        }
    }

    int32_t ArousalManager::GetStaticEffectAux(RE::Actor* who, int32_t effectIdx) {
        auto data = TryGetArousalData(who);
        if (!data) return 0;
        try {
            ArousalEffectData& effect = data->GetStaticArousalEffect(effectIdx);
            return effect.intAux;
        } catch (std::exception& e) {
            SKSE::log::warn("GetStaticEffectAux: {}", e.what());
            return 0;
        }
    }

    ArousalEffectData& ArousalManager::GetStaticArousalEffect(RE::Actor* who, int32_t effectIdx) {
        ArousalData* data = GetArousalData(who);
        if (!data) {
            static ArousalEffectData dummy;  // or handle this better if needed
            SKSE::log::warn("GetStaticArousalEffect: No arousal data for actor {}", who ? who->formID : 0);
            return dummy;
        }
        return data->GetStaticArousalEffect(effectIdx);
    }

    void ArousalManager::SetStaticArousalEffect(RE::Actor* who, int32_t effectIdx, int32_t functionId, float param,
                                                float limit, int32_t auxilliary) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            data->SetStaticArousalEffect(effectIdx, functionId, param, limit, auxilliary);
        } catch (std::exception& e) {
            SKSE::log::warn("SetStaticArousalEffect: {}", e.what());
        }
    }

    void ArousalManager::SetDynamicArousalEffect(RE::Actor* who, std::string effectId, float initialValue,
                                                 int32_t functionId, float param, float limit) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            data->SetDynamicArousalEffect(effectId, initialValue, functionId, param, limit);
        } catch (std::exception& e) {
            SKSE::log::warn("SetDynamicArousalEffect: {}", e.what());
        }
    }

    void ArousalManager::ModDynamicArousalEffect(RE::Actor* who, std::string effectId, float modifier, float limit) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            data->ModDynamicArousalEffect(effectId, modifier, limit);
        } catch (std::exception& e) {
            SKSE::log::warn("ModDynamicArousalEffect: {}", e.what());
        }
    }

    void ArousalManager::SetStaticArousalValue(RE::Actor* who, int32_t effectIdx, float value) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            data->SetStaticArousalValue(effectIdx, value);
        } catch (std::exception& e) {
            SKSE::log::warn("SetStaticArousalValue: {}", e.what());
        }
    }

    void ArousalManager::SetStaticAuxillaryFloat(RE::Actor* who, int32_t effectIdx, float value) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            ArousalEffectData& effect = data->GetStaticArousalEffect(effectIdx);
            effect.floatAux = value;
        } catch (std::exception& e) {
            SKSE::log::warn("SetStaticAuxillaryFloat: {}", e.what());
        }
    }

    void ArousalManager::SetStaticAuxillaryInt(RE::Actor* who, int32_t effectIdx, int32_t value) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            ArousalEffectData& effect = data->GetStaticArousalEffect(effectIdx);
            effect.intAux = value;
        } catch (std::exception& e) {
            SKSE::log::warn("SetStaticAuxillaryInt: {}", e.what());
        }
    }

    float ArousalManager::ModStaticArousalValue(RE::Actor* who, int32_t effectIdx, float diff, float limit) {
        auto data = TryGetArousalData(who);
        if (!data) return 0.0f;
        try {
            return data->ModStaticArousalValue(effectIdx, diff, limit);
        } catch (std::exception& e) {
            SKSE::log::warn("ModStaticArousalValue: {}", e.what());
            return 0.0f;
        }
    }

    float ArousalManager::GetArousal(RE::Actor* who) {
        auto data = TryGetArousalData(who);
        if (!data) return 0.0f;
        try {
            return data->GetArousal();
        } catch (std::exception& e) {
            SKSE::log::warn("GetArousal: {}", e.what());
            return 0.0f;
        }
    }

    void ArousalManager::UpdateSingleActorArousal(RE::Actor* who, float GameDaysPassed) {
        auto data = TryGetArousalData(who);
        if (!data) return;
        try {
            data->UpdateSingleActorArousal(who, GameDaysPassed);
        } catch (std::exception& e) {
            SKSE::log::warn("UpdateSingleActorArousal: {}", e.what());
        }
    }

    bool ArousalManager::GroupEffects(RE::Actor* who, int32_t idx, int32_t idx2) {
        auto data = TryGetArousalData(who);
        if (!data) return false;
        try {
            return data->GroupEffects(who, idx, idx2);
        } catch (std::exception& e) {
            SKSE::log::warn("GroupEffects: {}", e.what());
            return false;
        }
    }

    bool ArousalManager::RemoveEffectGroup(RE::Actor* who, int32_t idx) {
        auto data = TryGetArousalData(who);
        if (!data) return false;
        try {
            data->RemoveEffectGroup(idx);
            return true;
        } catch (std::exception& e) {
            SKSE::log::warn("RemoveEffectGroup: {}", e.what());
            return false;
        }
    }

    int32_t ArousalManager::CleanUpActors(float lastUpdateBefore) {
        SKSE::log::info("ArousalManager::CleanUpActors scheduled for async execution ({} cutoff)", lastUpdateBefore);
        auto* cleanupFlag = &cleanupLock;

        SKSE::GetTaskInterface()->AddTask([lastUpdateBefore]() {
            auto& mgr = ArousalManager::GetSingleton();
            AtomicFlagGuard cleanupGuard(mgr.cleanupLock);
            if (!cleanupGuard.owns_lock()) {
                SKSE::log::warn("Cleanup already running, skipping");
                return;
            }
            int removed = 0;
            {
                auto& data = ArousalManager::GetSingleton().arousalData;
                for (auto itr = data.begin(); itr != data.end();) {
                    if (itr->second.GetLastUpdate() < lastUpdateBefore) {
                        itr = data.erase(itr);
                        ++removed;
                    } else {
                        ++itr;
                    }
                }
            }
            SKSE::log::info("ArousalManager::CleanUpActors finished, removed {}", removed);
        });

        return 0;
    }

    bool ArousalManager::TryLock(int32_t lock) {
        if (lock < 0 || lock >= locks.size()) return false;
        if (cleanupLock.test(std::memory_order_relaxed)) return false;
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
        if (inst.cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("cleanupLock is set OnRevert, removing");
            inst.cleanupLock.clear();
        }
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
        
        if (inst.cleanupLock.test(std::memory_order_relaxed)) {
            SKSE::log::warn("cleanupLock is set ongameload, removing");
            inst.cleanupLock.clear();
        }
     
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
                        } catch (std::exception&) {
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

}  // namespace SLA
