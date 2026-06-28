# How Arousal Works

## In 30 seconds

- Each actor has a single arousal number.
- It rises when arousing things happen: seeing nudity, having sex, wearing certain armor types, being trapped in devices.
- It falls passively over time, and drops fast after orgasm.
- Dependent mods react when it crosses thresholds.

## In a bit more depth

- Each actor's number is the **sum of all currently-active effects** — both built-in (the Default plugin contributes nudity exposure, sleep decay, orgasm cooldown, denial buildup) and from any other plugin (SexLab, Devious Devices, OStim).
- Most timed effects use **game days** as the time unit (one in-game day = 24 in-game hours).
- The arousal value isn't clamped to 0–100 by default — it's just a float. The convention is 0–100 and most consumer mods assume that range, but individual effects can push outside it.

!!! note "The formula"
    ```
    arousal = sum(static effects not in a group)
            + sum(dynamic effect values)
            + sum(effect group products)
    ```
    For the full math and the timed-function table, see the author track's [Overview](../authors/overview.md).

## The six built-in effect categories

The **Default plugin** ships six categories of effect, each with its own page under **Plugins** in the MCM. These are the knobs most players reach for:

| Category | What it represents | Climbs when… |
|---|---|---|
| **Naked** | Exposure from nearby nudity | A naked (or revealingly-dressed) actor is in view — optionally requiring line-of-sight |
| **Exhibitionist** | Arousal from *being seen* naked | The actor is flagged an exhibitionist (see "Is Exhibitionist" in the MCM), is naked, and has onlookers in view |
| **Timed** | Passive "haven't had sex in a while" buildup | Time passes — this is the OSL-Aroused-style tick |
| **Sleep** | Morning arousal | The actor wakes from a long enough sleep |
| **Satisfaction** | Post-orgasm cooldown (a *penalty*) | Resets downward after orgasm, then decays back |
| **Legacy** | Boosts pushed by older mods via the `ModExposure` API | Mods like SLEN / SL Survival fire exposure events |

Other plugins add their own effects on top when their host mod is installed:

| Plugin | Drives |
|---|---|
| **SexLab** | Per-stage arousal during SexLab animations, animation-tag scoring |
| **Devious Devices** | Device-equipped arousal, belt/plug denial modifiers, device-stacking multiplier |
| **OStim** | OStim NG (and legacy v<29) thread tracking, observer LOS arousal scaling |

To see exactly which effects are active on any actor and their current values, open the **Puppet Master** page — see the [MCM Reference](mcm-reference.md#puppet-master).

To change how fast any of these climb, see [Tuning Recipes](tuning-recipes.md).
