#pragma once

#include <cstdint>
#include <vector>

namespace RE {
    class Actor;
    class TESFaction;
}

// Native replacements for the two expensive parts of slaMainScr.UpdateActorArousals:
// finding the actors near the player and the observer/observed pair pass. Both run on
// the game thread (plain Papyrus natives, not tasklet-callable), touch no ArousalManager
// state and take no lock.
namespace SLA::Scan {
    // Loaded, AI-active actors within a_radius units of a_origin, nearest first, capped at
    // a_maxCount (1..127, the Papyrus array limit). Skips a_origin itself, dead, disabled,
    // deleted, unloaded and child actors, chickens and mannequins, and creatures unless
    // a_includeCreatures. Mirrors the alias conditions of the retired slaScanAll quest.
    std::vector<RE::Actor*> ScanActors(RE::Actor* a_origin, float a_radius, std::int32_t a_maxCount,
                                       bool a_includeCreatures);

    // Per-actor input flags for ComputeObservations (bitmask, one int per actor).
    enum Flags : std::int32_t {
        kNaked = 1,       // slaMainScr.IsActorNaked was true this cycle
        kExhibiting = 2,  // in the sla_Exhibitionist faction
        kInOStim = 4,     // in a running OStim scene (SexLab is read natively from the animating faction)
    };

    // Per-actor output columns; the result is a flat float array, kStride values per actor.
    enum Obs : std::size_t {
        kNakedWeight = 0,   // sum over naked actors in view: exposure x 2 (preferred gender) or x 1
        kNakedMaxExposure,  // most exposed naked actor in view, 0..1
        kSeesNaked,         // 1 when any naked actor (or, for creature lovers, any creature) is in view
        kSeesNakedPref,     // 1 when one of them is of the observer's preferred gender
        kExhibCount,        // onlookers in view while the observer exhibits: 2 per attracted onlooker, else 1
        kSeesSexLab,        // 1 when an actor in the SexLab animating faction is in view
        kSeesOStim,         // 1 when an actor flagged kInOStim is in view
        kVisible,           // actors that passed the relevance filter and the LOS test (diagnostics)
        kStride
    };

    // One pass over every ordered (observer, observed) pair of a_actors. Implements the
    // rules of sla_DefaultPlugin.UpdateObserver and the sex plugins' "sees sex" check:
    //   - a creature counts for an observer only if that observer is a creature or in
    //     a_creatureLover; nobody else sees creatures at all
    //   - exhibitionist onlookers are counted for non-creature observed actors only
    //   - a_genderPref: 0 male, 1 female, 2 both (anything else = both), per actor
    //   - a_exposure: the naked actor's exposure scale (1.0 when not scaling)
    // LOS (Actor::HasLineOfSight) is only tested for pairs the rules care about, so a town
    // with nobody naked costs no raycasts. a_useLOS false skips the test entirely.
    std::vector<float> ComputeObservations(const std::vector<RE::Actor*>& a_actors,
                                           const std::vector<std::int32_t>& a_flags,
                                           const std::vector<float>& a_exposure,
                                           const std::vector<std::int32_t>& a_genderPref, bool a_useLOS,
                                           RE::TESFaction* a_creatureLover, RE::TESFaction* a_animating);
}
