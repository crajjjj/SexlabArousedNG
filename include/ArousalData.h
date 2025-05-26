#pragma once
#include "SerializationHelper.h"
#include <SKSE/SKSE.h>

namespace SLA {
    extern uint32_t staticEffectCount;
    struct ArousalEffectGroup {
        ArousalEffectGroup() : value(0.f) {}
        std::vector<uint32_t> staticEffectIds;
        float value;
    };

    using ArousalEffectGroupPtr = std::shared_ptr<ArousalEffectGroup>;
   
    static float GetEffectLimitOffset(uint32_t effectIdx) {
        if (effectIdx == 1) return 0.5;
        return 0.0;
    }

    struct ArousalEffectData {
        ArousalEffectData() : value(0.f), function(0), param(0.f), limit(0.f), intAux(0) {}

        float value;
        int32_t function;
        float param;
        float limit;
        union {
            float floatAux;
            int32_t intAux;
        };

        void Set(int32_t functionId, float param, float limit, int32_t auxilliary) {
            this->function = functionId;
            this->param = param;
            this->limit = limit + GetEffectLimitOffset(functionId);
            this->intAux = auxilliary;
        }
    };

    class ArousalData {
    public:
        ArousalData()
            : staticEffects(staticEffectCount),
              staticEffectGroups(staticEffectCount),
              arousal(0.f),
              lastUpdate(0.f),
              lockedArousal(std::numeric_limits<float>::quiet_NaN()) {}
        ArousalData(SKSE::SerializationInterface* intfc, uint32_t& length) : ArousalData() {
            using namespace Serialization;
            arousal = ReadDataHelper<float>(intfc, length);
            lastUpdate = ReadDataHelper<float>(intfc, length);
            uint32_t count = ReadDataHelper<uint32_t>(intfc, length);
            for (uint32_t j = 0; j < count; ++j) staticEffects[j] = ReadDataHelper<ArousalEffectData>(intfc, length);

            count = ReadDataHelper<uint8_t>(intfc, length);
            for (uint32_t j = 0; j < count; ++j) {
                auto grp = std::make_shared<ArousalEffectGroup>();
                uint32_t grpEntiryCount = ReadDataHelper<uint32_t>(intfc, length);
                for (uint32_t k = 0; k < grpEntiryCount; ++k) {
                    uint32_t effIdx = ReadDataHelper<uint32_t>(intfc, length);
                    grp->staticEffectIds.emplace_back(effIdx);
                    staticEffectGroups[effIdx] = grp;
                }
                grp->value = ReadDataHelper<float>(intfc, length);
                if (std::abs(grp->value) > 10000.f) {
                    SKSE::log::info("Possibly corrupted data reseting to zero");
                    grp->value = 0.f;
                }
                groupsToUpdate.emplace_back(std::move(grp));
            }
            count = ReadDataHelper<uint32_t>(intfc, length);
            for (uint32_t j = 0; j < count; ++j) staticEffectsToUpdate.insert(ReadDataHelper<uint32_t>(intfc, length));
            count = ReadDataHelper<uint32_t>(intfc, length);
            for (uint32_t j = 0; j < count; ++j) {
                std::string name = ReadString(intfc, length);
                dynamicEffects[name] = ReadDataHelper<ArousalEffectData>(intfc, length);
            }
            count = ReadDataHelper<uint32_t>(intfc, length);
            for (uint32_t j = 0; j < count; ++j) dynamicEffectsToUpdate.insert(ReadString(intfc, length));

            float recalculated = 0.f;
            for (uint32_t i = 0; i < staticEffects.size(); ++i) {
                if (!staticEffectGroups[i]) recalculated += staticEffects[i].value;
            }
            for (auto const& eff : dynamicEffects) recalculated += eff.second.value;
            for (auto const& grp : groupsToUpdate) recalculated += grp->value;
            if (std::abs(recalculated - arousal) > 0.5)
                SKSE::log::info("Arousal data mismatch: Expected: {} Got: {}", recalculated, arousal);
            arousal = recalculated;
        }
        ArousalData& operator=(ArousalData&& other) = default;

        void Serialize(SKSE::SerializationInterface* intfc) const {
            using namespace Serialization;
            intfc->WriteRecordData(&arousal, sizeof(arousal));
            intfc->WriteRecordData(&lastUpdate, sizeof(lastUpdate));
            WriteContainerData<std::vector<ArousalEffectData>>(intfc, staticEffects);
            uint8_t groupCount = groupsToUpdate.size();
            intfc->WriteRecordData(&groupCount, sizeof(groupCount));
            for (auto& group : groupsToUpdate) {
                WriteContainerData<std::vector<uint32_t>>(intfc, group->staticEffectIds);
                intfc->WriteRecordData(&group->value, sizeof(group->value));
            };
           WriteContainerData<std::unordered_set<int32_t>>(intfc, staticEffectsToUpdate);
            uint32_t size = static_cast<uint32_t>(dynamicEffects.size());
            intfc->WriteRecordData(&size, sizeof(size));
            for (auto const& kvp : dynamicEffects) {
                WriteString(intfc, kvp.first);
                intfc->WriteRecordData(&kvp.second, sizeof(kvp.second));
            }
            size = static_cast<uint32_t>(dynamicEffectsToUpdate.size());
            intfc->WriteRecordData(&size, sizeof(size));
            for (auto const& toUpdate : dynamicEffectsToUpdate) WriteString(intfc, toUpdate);
        }

        void OnRegisterStaticEffect();
        void OnUnregisterStaticEffect(uint32_t id);
        bool IsStaticEffectActive(int32_t effectIdx);
        int32_t GetDynamicEffectCount() const;
        std::string GetDynamicEffect(int32_t number) const;
        float GetDynamicEffectValue(int32_t number) const;
        float GetDynamicEffectValueByName(std::string number) const;
        ArousalEffectGroupPtr GetEffectGroup(int32_t effectIdx);
        ArousalEffectData& GetStaticArousalEffect(int32_t effectIdx);
        void SetStaticArousalEffect(int32_t effectIdx, int32_t functionId, float param, float limit,
                                    int32_t auxilliary);
        void SetDynamicArousalEffect(std::string effectId, float initialValue, int32_t functionId,
                                     float param, float limit);
        void ModDynamicArousalEffect(std::string effectId, float modifier, float limit);
        void SetStaticArousalValue(int32_t effectIdx, float value);
        float ModStaticArousalValue(int32_t effectIdx, float diff, float limit);
        float GetArousal();
        void UpdateSingleActorArousal(RE::Actor* who, float GameDaysPassed);
        bool GroupEffects(RE::Actor* who, int32_t idx, int32_t idx2);
        void RemoveEffectGroup(int32_t idx);
        float GetLastUpdate() const;

    private:
        ArousalData& operator=(const ArousalData&) = delete;
        ArousalData(const ArousalData&) = delete;

        void RemoveDynamicEffectIfNeeded(std::string effectName, ArousalEffectData& effect);
        void UpdateGroupFactor(ArousalEffectGroup& group, float oldFactor, float newFactor);
        void UpdateGroup(ArousalEffectGroup& group, float timeDiff, RE::Actor* who);
        bool CalculateArousalEffect(ArousalEffectData& effect, float timeDiff, RE::Actor* who);
        bool UpdateArousalEffect(ArousalEffectData& effect, float timeDiff, RE::Actor* who);

        std::unordered_set<int32_t> staticEffectsToUpdate;
        std::vector<ArousalEffectData> staticEffects;
        std::vector<ArousalEffectGroupPtr> staticEffectGroups;
        std::unordered_set<std::string> dynamicEffectsToUpdate;
        std::unordered_map<std::string, ArousalEffectData> dynamicEffects;
        std::vector<ArousalEffectGroupPtr> groupsToUpdate;
        float arousal;
        float lastUpdate;
        float lockedArousal;
    };

    
}
