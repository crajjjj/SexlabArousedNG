# Getting Started

A guide for players. If you're a mod author integrating with the arousal framework, start with the [Author Overview](../authors/overview.md) instead — that track covers the Papyrus / SKSE API in depth.

## What this mod actually does

SexLab Aroused NG is the underlying *arousal system* for a family of adult Skyrim mods. Every actor (you, every NPC) gets a single **arousal number** — a float typically in the 0–100 range — that goes up and down over time based on what's happening around them.

The mod by itself doesn't really *do* anything visible — it tracks the number and provides an MCM to inspect and curate it. The interesting behavior comes from **dependent mods** that read the number and react: dialogue changes, NPC approaches, animations, equipment behavior, magic effects, etc.

What this mod *does* give you directly:

- A persistent per-actor arousal value that survives saves.
- An MCM to inspect any actor's arousal and tweak how it's calculated for them.
- A per-armor flagging system — mark specific items as "naked", "bikini", "sexy", "slooty", "illegal", etc., and the mod takes those into account when computing exposure.
- The ability to register your own custom keywords and apply them to items, then **export everything to a KID file** so the curation survives new saves and can be shared.

See [How Arousal Works](how-arousal-works.md) for the model behind the number.

## Requirements

The only hard requirements are **SKSE64**, **Address Library**, and **PapyrusUtil SE**. Everything else is optional and unlocks the integration tied to it (SexLab, OStim, Devious Devices, KID export, aroused animations).

See the [Requirements](requirements.md) page for the full breakdown of hard requirements, soft dependencies, and what each one unlocks.

## Installation

Install via Mod Organizer 2 / Vortex and complete the FOMOD wizard. You'll be asked to pick:

- **Animation System** — Open Animation Replacer (recommended), FNIS, or None.
- **Patches** — Dummy ESPs (for backwards compatibility with mods expecting `OAroused.esp` / `OSLAroused.esp`), SexLab Eager NPCs patch, Paradise Halls Enhanced patch. Pick as appropriate to your modlist.

!!! tip "Coming from OSL Aroused?"
    Install the **Dummy ESPs** FOMOD option so mods that expect `OAroused.esp` / `OSLAroused.esp` keep resolving. Then read [Coming from OSL Aroused](tuning-recipes.md#coming-from-osl-aroused) — the passive "ticks up over time" behavior maps onto a *different* effect here and needs a one-time tweak.

## First-time setup

1. Install via mod manager, complete the FOMOD wizard.
2. Launch Skyrim and load a save (or new game).
3. Open the MCM: pause menu → **Mod Configuration** → **SLO Aroused NG**.
4. The first thing you'll see is a status splash. Click any tab on the left.
5. Walk through **System** (the General page) and read tooltips. Defaults are reasonable.
6. If you want exposure to depend on whether actors actually *see* nudity, leave **Use LOS** ON. If you want it to count any nearby nudity regardless of LOS, turn it OFF.
7. Set the **Notification Key** to a key that doesn't conflict with your other mods — pressing it shows your arousal value in the corner.

That's enough to start playing. Everything in the rest of the player docs is optional curation and tuning.

## Where to go next

- [How Arousal Works](how-arousal-works.md) — understand the number before you tune it.
- [MCM Reference](mcm-reference.md) — a tour of every page.
- [Armor Curation](armor-curation.md) — flag which outfits count as revealing.
- [Tuning Recipes](tuning-recipes.md) — make it behave the way you want.
- [Troubleshooting & Logs](troubleshooting.md) — when something isn't working.
