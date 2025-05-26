#include "ArousalData.h"
#include "CosSin.h"

namespace SLA {
    uint32_t staticEffectCount = 0;

    void ArousalData::OnRegisterStaticEffect() {
        staticEffects.emplace_back();
        staticEffectGroups.emplace_back(nullptr);
    }
    void ArousalData::OnUnregisterStaticEffect(uint32_t id) {
        try {
            SetStaticArousalValue(id, 0.f);
            SetStaticArousalEffect(id, 0, 0.f, 0.f, 0);
            if (staticEffectGroups[id]) RemoveEffectGroup(id);
        } catch (std::exception ex) {
            SKSE::log::info("Unexpected exception in OnUnregisterStaticEffect: {}", ex.what());
        }
    }
    bool ArousalData::IsStaticEffectActive(int32_t effectIdx) {
        return staticEffectsToUpdate.find(effectIdx) != staticEffectsToUpdate.end();
    }

    int32_t ArousalData::GetDynamicEffectCount() const { return dynamicEffects.size(); }
    std::string ArousalData::GetDynamicEffect(int32_t number) const {
        if (number >= dynamicEffects.size()) return "";
        auto itr = dynamicEffects.begin();
        std::advance(itr, number);
        return itr->first.c_str();
    }
    float ArousalData::GetDynamicEffectValue(int32_t number) const {
        if (number >= dynamicEffects.size()) return std::numeric_limits<float>::lowest();
        auto itr = dynamicEffects.begin();
        std::advance(itr, number);
        return itr->second.value;
    }
    float ArousalData::GetDynamicEffectValueByName(std::string effectId) const {
        std::string effectName(effectId);

        auto itr = dynamicEffects.find(effectName);
        if (itr != dynamicEffects.end())
            return itr->second.value;
        else
            return 0.f;
    }
    ArousalEffectGroupPtr ArousalData::GetEffectGroup(int32_t effectIdx) {
        if (effectIdx < 0 || effectIdx >= staticEffects.size())
            throw std::invalid_argument("Invalid static effect index");
        return staticEffectGroups[effectIdx];
    }
    ArousalEffectData& ArousalData::GetStaticArousalEffect(int32_t effectIdx) {
        if (effectIdx < 0 || effectIdx >= staticEffects.size())
            throw std::invalid_argument("Invalid static effect index");
        return staticEffects[effectIdx];
    }
    void ArousalData::SetStaticArousalEffect(int32_t effectIdx, int32_t functionId, float param, float limit,
                                             int32_t auxilliary) {
        ArousalEffectData& effect = GetStaticArousalEffect(effectIdx);

        if (functionId && !effect.function)
            staticEffectsToUpdate.insert(effectIdx);
        else if (!functionId && effect.function)
            staticEffectsToUpdate.erase(effectIdx);

        effect.Set(functionId, param, limit, auxilliary);
    }

    void ArousalData::RemoveDynamicEffectIfNeeded(std::string effectName, ArousalEffectData& effect) {
        if (effect.function == 0 && effect.value == 0.f) dynamicEffects.erase(effectName);
    }

    void ArousalData::SetDynamicArousalEffect(std::string effectId, float initialValue, int32_t functionId, float param,
                                              float limit) {
        std::string effectName(effectId);
        ArousalEffectData& effect = dynamicEffects[effectName];

        if (functionId && !effect.function)
            dynamicEffectsToUpdate.insert(effectName);
        else if (!functionId && effect.function)
            dynamicEffectsToUpdate.erase(effectName);

        effect.Set(functionId, param, limit, 0);
        if (initialValue) {
            arousal += initialValue - effect.value;
            effect.value = initialValue;
        }
        RemoveDynamicEffectIfNeeded(std::move(effectName), effect);
    }
    void ArousalData::ModDynamicArousalEffect(std::string effectId, float modifier, float limit) {
        std::string effectName(effectId);
        ArousalEffectData& effect = dynamicEffects[effectName];

        float value = effect.value + modifier;
        float actualDiff = modifier;
        if ((modifier < 0 && limit > value) || (modifier > 0 && limit < value)) {
            value = limit;
            actualDiff = limit - value;
        }
        arousal += actualDiff;
        effect.value = value;
        RemoveDynamicEffectIfNeeded(std::move(effectName), effect);
    }
    void ArousalData::SetStaticArousalValue(int32_t effectIdx, float value) {
        ArousalEffectData& effect = GetStaticArousalEffect(effectIdx);

        float diff = value - effect.value;
        effect.value = value;
        if (!staticEffectGroups[effectIdx]) arousal += diff;
    }
    float ArousalData::ModStaticArousalValue(int32_t effectIdx, float diff, float limit) {
        ArousalEffectData& effect = GetStaticArousalEffect(effectIdx);

        float value = effect.value + diff;
        float actualDiff = diff;
        if ((diff < 0 && limit > value) || (diff > 0 && limit < value)) {
            value = limit;
            actualDiff = limit - value;
        }
        effect.value = value;
        if (!staticEffectGroups[effectIdx]) arousal += actualDiff;
        return actualDiff;
    }

    float ArousalData::GetArousal() { 
        float recalculated = 0.f;
        for (uint32_t i = 0; i < staticEffects.size(); ++i) {
            if (!staticEffectGroups[i]) recalculated += staticEffects[i].value;
        }
        for (auto const& eff : dynamicEffects) recalculated += eff.second.value;
        for (auto const& grp : groupsToUpdate) recalculated += grp->value;
    
        arousal = recalculated;

        return arousal; 
    }

    void ArousalData::UpdateGroupFactor(ArousalEffectGroup& group, float oldFactor, float newFactor) {
        float value = group.value / oldFactor * newFactor;
        float diff = value - group.value;
        arousal += diff;
        group.value = value;
    }

    bool ArousalData::CalculateArousalEffect(ArousalEffectData& effect, float timeDiff, RE::Actor* who) {
        enum class LimitCheck { None, UpperBound, LowerBound };
        bool isDone = true;
        LimitCheck checkLimit = LimitCheck::None;
        float value;
        switch (effect.function) {
            case 1:
                value = effect.value * std::pow(0.5f, timeDiff / effect.param);
                checkLimit = effect.param * effect.value < 0.f ? LimitCheck::UpperBound : LimitCheck::LowerBound;
                break;
            case 2:
                value = effect.value + timeDiff * effect.param;
                checkLimit = effect.param >= 0.f ? LimitCheck::UpperBound : LimitCheck::LowerBound;
                break;
            case 3:
                value = (fastsin(float(who->formID % 7919) * 0.01f + lastUpdate * effect.param) + 1.f) * effect.limit;
                break;
            case 4:
                value = lastUpdate < effect.param ? 0.f : effect.limit;
                break;
            default:
                return true;
        }

        switch (checkLimit) {
            case LimitCheck::UpperBound:
                if (effect.limit < value)
                    value = effect.limit + GetEffectLimitOffset(effect.function);
                else
                    isDone = false;
                break;
            case LimitCheck::LowerBound:
                if (effect.limit > value)
                    value = effect.limit - GetEffectLimitOffset(effect.function);
                else
                    isDone = false;
                break;
            default:
                break;
        }

        effect.value = value;
        return isDone;
    }
    bool ArousalData::UpdateArousalEffect(ArousalEffectData& effect, float timeDiff, RE::Actor* who) {
        float oldValue = effect.value;
        bool isDone = CalculateArousalEffect(effect, timeDiff, who);
        float diff = effect.value - oldValue;
        arousal += diff;
        return isDone;
    }

    void ArousalData::UpdateGroup(ArousalEffectGroup& group, float timeDiff, RE::Actor* who) {
        float value = 1.f;
        for (uint32_t id : group.staticEffectIds) {
            ArousalEffectData& eff = GetStaticArousalEffect(id);
            CalculateArousalEffect(eff, timeDiff, who);
            value *= eff.value;
        }
        float diff = value - group.value;
        arousal += diff;
        group.value = value;
    }

    void ArousalData::UpdateSingleActorArousal(RE::Actor* who, float GameDaysPassed) {
        if (!lastUpdate) {
            std::random_device rd;
            std::default_random_engine gen{rd()};
            std::normal_distribution<> d{0.5, 2.0};
            float randomTimeDiff = std::abs(float(d(gen)));
            lastUpdate = GameDaysPassed - randomTimeDiff;
        }

        float diff = GameDaysPassed - lastUpdate;
        lastUpdate = GameDaysPassed;

        for (auto group : groupsToUpdate) UpdateGroup(*group, diff, who);

        for (auto itr = staticEffectsToUpdate.begin(); itr != staticEffectsToUpdate.end();) {
            if (staticEffectGroups[*itr])
                ++itr;
            else {
                ArousalEffectData& effect = staticEffects[*itr];
                if (UpdateArousalEffect(effect, diff, who)) {
                    effect.function = 0;
                    itr = staticEffectsToUpdate.erase(itr);
                } else
                    ++itr;
            }
        }

        for (auto itr = dynamicEffectsToUpdate.begin(); itr != dynamicEffectsToUpdate.end();) {
            ArousalEffectData& effect = dynamicEffects[*itr];
            if (UpdateArousalEffect(effect, diff, who)) {
                effect.function = 0;
                RemoveDynamicEffectIfNeeded(*itr, effect);
                itr = dynamicEffectsToUpdate.erase(itr);
            } else
                ++itr;
        }

        float recalculated = 0.f;
        for (uint32_t i = 0; i < staticEffects.size(); ++i) {
            if (!staticEffectGroups[i]) recalculated += staticEffects[i].value;
        }
        for (auto const& eff : dynamicEffects) recalculated += eff.second.value;
        for (auto const& grp : groupsToUpdate) recalculated += grp->value;

        arousal = recalculated;

    }
    bool ArousalData::GroupEffects(RE::Actor* who, int32_t idx, int32_t idx2) {
        ArousalEffectData& first = GetStaticArousalEffect(idx);
        ArousalEffectData& second = GetStaticArousalEffect(idx2);
        ArousalEffectGroupPtr targetGrp = staticEffectGroups[idx];
        ArousalEffectGroupPtr otherGrp = staticEffectGroups[idx2];
        if (!targetGrp)
            targetGrp = otherGrp;
        else if (otherGrp)
            return targetGrp == otherGrp;
        if (!targetGrp) {
            targetGrp = std::make_shared<ArousalEffectGroup>();
            groupsToUpdate.push_back(targetGrp);
        }

        if (!staticEffectGroups[idx]) {
            staticEffectGroups[idx] = targetGrp;
            targetGrp->staticEffectIds.push_back(idx);
            staticEffectsToUpdate.erase(idx);
            arousal -= first.value;
        }
        if (!staticEffectGroups[idx2]) {
            staticEffectGroups[idx2] = targetGrp;
            targetGrp->staticEffectIds.push_back(idx2);
            staticEffectsToUpdate.erase(idx2);
            arousal -= second.value;
        }

        UpdateGroup(*targetGrp, 0.f, who);
        return true;
    }
    void ArousalData::RemoveEffectGroup(int32_t idx) {
        ArousalEffectGroupPtr group = staticEffectGroups[idx];
        auto itr = std::find(groupsToUpdate.begin(), groupsToUpdate.end(), group);
        if (itr == groupsToUpdate.end()) throw std::logic_error("Error while removing group: group does not exist!");
        groupsToUpdate.erase(itr);
        arousal -= group->value;
        for (uint32_t id : group->staticEffectIds) {
            ArousalEffectData& eff = GetStaticArousalEffect(id);
            staticEffectGroups[id] = nullptr;
            arousal += eff.value;
            if (eff.function) staticEffectsToUpdate.insert(id);
        }
    }
    float ArousalData::GetLastUpdate() const { return lastUpdate; }
}