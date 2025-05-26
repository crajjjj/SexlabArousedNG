#pragma once

#include "ArousalData.h"

namespace SLA {
#pragma warning(push)
#pragma warning(disable : 4251)

    class __declspec(dllexport) ArousalManager {
    public:
        [[nodiscard]] static ArousalManager& GetSingleton() noexcept;
        int GetStaticEffectCount();
        uint32_t RegisterStaticEffect(std::string name);
        bool UnregisterStaticEffect(std::string name);
        bool IsStaticEffectActive(RE::Actor* who, int32_t effectIdx);
        int32_t GetDynamicEffectCount(RE::Actor* who);
        std::string GetDynamicEffect(RE::Actor* who, int32_t number);
        float GetDynamicEffectValueByName(RE::Actor* who, std::string effectId);
        float GetDynamicEffectValue(RE::Actor* who, int32_t number);
        float GetStaticEffectValue(RE::Actor* who, int32_t number);
        float GetStaticEffectParam(RE::Actor* who, int32_t effectIdx);
        int32_t GetStaticEffectAux(RE::Actor* who, int32_t effectIdx);
        void SetStaticArousalEffect(RE::Actor* who, int32_t effectIdx, int32_t functionId,
                                    float param, float limit, int32_t auxilliary);
        void SetDynamicArousalEffect(RE::Actor* who, std::string effectId, float initialValue,
                                     int32_t functionId, float param, float limit);
        void ModDynamicArousalEffect(RE::Actor* who, std::string effectId, float modifier,
                                     float limit);
        void SetStaticArousalValue(RE::Actor* who, int32_t effectIdx, float value);
        void SetStaticAuxillaryFloat(RE::Actor* who, int32_t effectIdx, float value);
        void SetStaticAuxillaryInt(RE::Actor* who, int32_t effectIdx, int32_t value);
        float ModStaticArousalValue(RE::Actor* who, int32_t effectIdx, float diff, float limit);
        float GetArousal(RE::Actor* who);
        void UpdateSingleActorArousal(RE::Actor* who, float GameDaysPassed);
        bool GroupEffects(RE::Actor* who, int32_t idx, int32_t idx2);
        bool RemoveEffectGroup(RE::Actor* who, int32_t idx);
        int32_t CleanUpActors(float lastUpdateBefore);
        bool TryLock(int32_t lock);
        void Unlock(int32_t lock);

        static void OnRevert(SKSE::SerializationInterface*);
        static void OnGameSaved(SKSE::SerializationInterface* serde);
        static void OnGameLoaded(SKSE::SerializationInterface* serde);

    private:
        int32_t GetHighestUnusedEffectId();
        std::string GetUnusedEffectId(int32_t id);
        ArousalEffectData& GetStaticArousalEffect(RE::Actor* who, int32_t effectIdx);
        ArousalData& GetArousalData(RE::Actor* who);

        ArousalManager() = default;
        mutable std::mutex _lock;
        std::unordered_map<std::string, uint32_t> staticEffectIds;
        std::unordered_map<uint32_t, ArousalData> arousalData;

        uint32_t lastLookup;
        ArousalData* lastData = nullptr;

        std::array<std::atomic_flag, 3> locks;
    };

#pragma warning(pop)
}

