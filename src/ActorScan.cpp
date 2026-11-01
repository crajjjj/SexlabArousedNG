#include "ActorScan.h"

namespace {
    // Keyword test that matches the Papyrus Actor.HasKeyword / alias HasKeyword condition:
    // the race carries ActorTypeNPC / ActorTypeCreature for vanilla actors, the base can add
    // either. Both lookups are null-safe (TESObjectREFR::IsHumanoid is not; see CLAUDE.md).
    bool HasKeywordOnRaceOrBase(RE::Actor* a_actor, std::string_view a_keyword) {
        if (const auto race = a_actor->GetRace(); race && race->HasKeywordString(a_keyword)) return true;
        if (const auto base = a_actor->GetActorBase(); base && base->HasKeywordString(a_keyword)) return true;
        return false;
    }

    bool IsCreature(RE::Actor* a_actor) { return HasKeywordOnRaceOrBase(a_actor, "ActorTypeCreature"sv); }

    // The slaScanAll aliases excluded these two races explicitly (chickens wander through
    // every farm, mannequins are actors that never move). Matched by FormID, as the alias
    // GetIsRace conditions did: an override can rename a race's editor ID (one patch ships
    // ManakinRace as "ManikinRace"), and Skyrim.esm always loads at index 00.
    constexpr RE::FormID kChickenRace = 0x000A919D;
    constexpr RE::FormID kManakinRace = 0x0010760A;

    bool IsExcludedRace(RE::Actor* a_actor) {
        const auto race = a_actor->GetRace();
        if (!race) return false;
        const auto id = race->GetFormID();
        return id == kChickenRace || id == kManakinRace;
    }

    int SexOf(RE::Actor* a_actor) {
        const auto base = a_actor->GetActorBase();
        return base ? static_cast<int>(base->GetSex()) : -1;
    }
}

namespace SLA::Scan {

    std::vector<RE::Actor*> ScanActors(RE::Actor* a_origin, float a_radius, std::int32_t a_maxCount,
                                       bool a_includeCreatures) {
        std::vector<RE::Actor*> result;
        if (!a_origin) return result;
        const auto lists = RE::ProcessLists::GetSingleton();
        if (!lists) return result;

        a_maxCount = std::clamp<std::int32_t>(a_maxCount, 1, 127);
        if (a_radius <= 0.f) a_radius = 1024.f;
        const auto origin = a_origin->GetPosition();
        const float radiusSq = a_radius * a_radius;

        std::vector<std::pair<float, RE::Actor*>> found;
        lists->ForEachHighActor([&](RE::Actor* a) {
            if (a && a != a_origin && !a->IsDeleted() && !a->IsDisabled() && !a->IsDead() && a->Is3DLoaded() &&
                !a->IsChild()) {
                const float distSq = origin.GetSquaredDistance(a->GetPosition());
                if (distSq <= radiusSq) {
                    const bool npc = HasKeywordOnRaceOrBase(a, "ActorTypeNPC"sv);
                    const bool creature = !npc && IsCreature(a);
                    if ((npc || (creature && a_includeCreatures)) && !IsExcludedRace(a)) found.emplace_back(distSq, a);
                }
            }
            return RE::BSContainer::ForEachResult::kContinue;
        });

        std::sort(found.begin(), found.end(), [](const auto& l, const auto& r) { return l.first < r.first; });
        const std::size_t count = std::min<std::size_t>(found.size(), static_cast<std::size_t>(a_maxCount));
        result.reserve(count);
        for (std::size_t i = 0; i < count; ++i) result.push_back(found[i].second);
        return result;
    }

    std::vector<float> ComputeObservations(const std::vector<RE::Actor*>& a_actors,
                                           const std::vector<std::int32_t>& a_flags,
                                           const std::vector<float>& a_exposure,
                                           const std::vector<std::int32_t>& a_genderPref, bool a_useLOS,
                                           RE::TESFaction* a_creatureLover, RE::TESFaction* a_animating,
                                           std::int32_t a_firstObserver, std::int32_t a_observerCount) {
        const std::size_t n = a_actors.size();
        const std::size_t first = static_cast<std::size_t>(std::max<std::int32_t>(a_firstObserver, 0));
        const std::size_t last = std::min(n, first + static_cast<std::size_t>(std::max<std::int32_t>(a_observerCount, 0)));
        // Always kStride values per REQUESTED observer, so the caller can index by position
        // even when the range runs past the end (a non-empty array also never reaches Papyrus
        // as None).
        std::vector<float> out(static_cast<std::size_t>(std::max<std::int32_t>(a_observerCount, 1)) * kStride, 0.f);
        if (first >= last) return out;

        const auto flag = [&](std::size_t i, std::int32_t bit) { return i < a_flags.size() && (a_flags[i] & bit) != 0; };
        const auto exposure = [&](std::size_t i) { return i < a_exposure.size() ? a_exposure[i] : 1.f; };
        const auto pref = [&](std::size_t i) { return i < a_genderPref.size() ? a_genderPref[i] : 2; };
        // Exactly the old sla_DefaultPlugin.UpdateObserver test: 2 (both) or the exact sex.
        // Any other rank (an out-of-range faction rank, -2 for None) counts as not preferred.
        const auto prefers = [](std::int32_t a_pref, int a_sex) { return a_pref == 2 || a_pref == a_sex; };

        // Per-actor facts, read once per call instead of once per pair. An actor that lost its
        // 3D or left high process since the scan (a load door during the Papyrus pre-pass, or
        // a GetNearbyActors list up to 10 s old) is skipped on both sides: the engine LOS
        // routine expects a loaded, high-process actor.
        std::vector<std::uint8_t> usable(n, 0), creature(n, 0), inSexLab(n, 0), creatureLover(n, 0);
        std::vector<int> sex(n, -1);
        for (std::size_t i = 0; i < n; ++i) {
            const auto a = a_actors[i];
            if (!a || !a->Is3DLoaded()) continue;
            const auto process = a->GetActorRuntimeData().currentProcess;  // SE/AE/VR layout-safe accessor
            if (!process || !process->InHighProcess()) continue;
            usable[i] = 1;
            creature[i] = IsCreature(a);
            sex[i] = SexOf(a);
            if (a_animating) inSexLab[i] = a->IsInFaction(a_animating);
            if (a_creatureLover)
                creatureLover[i] = a->GetFactionRank(a_creatureLover, a == RE::PlayerCharacter::GetSingleton()) > -1;
        }

        for (std::size_t i = first; i < last; ++i) {
            if (!usable[i]) continue;
            const auto observer = a_actors[i];
            float* o = &out[(i - first) * kStride];
            const bool observerExhibits = flag(i, kExhibiting);
            const bool observerSeesCreatures = creature[i] || creatureLover[i];

            for (std::size_t j = 0; j < n; ++j) {
                if (j == i || !usable[j]) continue;
                const auto observed = a_actors[j];

                const bool naked = flag(j, kNaked);
                const bool sexLab = inSexLab[j] != 0;
                const bool ostim = flag(j, kInOStim);
                // What sla_DefaultPlugin.UpdateObserver would have done with this pair:
                // a creature is invisible to anyone but creatures and creature lovers; a
                // clothed non-creature contributes nothing to the naked effect.
                const bool nudityRelevant = creature[j] ? observerSeesCreatures : naked;
                const bool exhibRelevant = observerExhibits && !creature[j];
                if (!nudityRelevant && !exhibRelevant && !sexLab && !ostim) continue;

                if (a_useLOS) {
                    bool unused = false;
                    if (!observer->HasLineOfSight(observed, unused)) continue;
                }
                o[kVisible] += 1.f;

                if (exhibRelevant) o[kExhibCount] += prefers(pref(j), sex[i]) ? 2.f : 1.f;
                if (sexLab) o[kSeesSexLab] = 1.f;
                if (ostim) o[kSeesOStim] = 1.f;
                if (!nudityRelevant) continue;

                // Creature-lover path: the sight alone counts as "sees naked" even when the
                // creature is not in the naked faction.
                if (creature[j]) o[kSeesNaked] = 1.f;
                if (!naked) continue;

                const float scale = exposure(j);
                o[kSeesNaked] = 1.f;
                if (scale > o[kNakedMaxExposure]) o[kNakedMaxExposure] = scale;
                if (prefers(pref(i), sex[j])) {
                    o[kSeesNakedPref] = 1.f;
                    o[kNakedWeight] += 2.f * scale;
                } else {
                    o[kNakedWeight] += scale;
                }
            }
        }
        return out;
    }

}  // namespace SLA::Scan
