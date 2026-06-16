# MCM Reference

Open the MCM from the pause menu → **Mod Configuration** → **SLO Aroused NG**. This page walks every tab.

## General Settings

Home page. Key controls:

- **Notification Key** ("Status Notification Key") — press in-game to print your arousal to the corner. With crosshair on an NPC, also pins that NPC as your "Puppet" for inspection (see [Puppet Master](#puppet-master)).
- **Enable Desire Spell** — gives you a power that displays your own arousal as a buff/debuff.
- **Enable for Male/Female Animation** — whether arousal animations play for each gender.
- **Use LOS** ("Require Line of Sight for arousal") — whether actors need line-of-sight on a naked actor to gain exposure.
- **Naked Only** ("Require naked actors to change arousal") — when ON, an actor's arousal is only updated while at least one naked actor is nearby. It's a **performance switch**, not a keyword filter — turning it ON skips updates (including passive/timed gains) when no naked actor is present. Some mods require it OFF.
- **Enable Notifications** — corner messages from the mod.
- **Disabled** — full off switch.

At the bottom is the **Plugin List** showing which integrations are active. The four built-in ones:

| Plugin | Drives |
|---|---|
| **Default** | Naked exposure, post-orgasm satisfaction decay, chastity denial buildup, sleep arousal decay |
| **SexLab** | Per-stage arousal during SexLab animations, animation-tag scoring |
| **Devious Devices** | Device-equipped arousal, belt/plug denial modifiers, device-stacking multiplier |
| **OStim** | OStim NG (and legacy v<29) thread tracking, observer LOS arousal scaling |

!!! note "Two different Import/Export buttons"
    The **Import** / **Export** buttons here save and restore your *MCM settings* — sliders, toggles, key bindings — as JSON via PapyrusUtil (`SLAX/Settings.json`). This is **not** the same as the per-armor [Export to KID file](kid-export.md) button on the *Current Armor List* page.

## Status

Real-time arousal numbers for actors the mod is tracking, plus a summary of recent events.

## Puppet Master

Inspect any actor's arousal effects in detail. Pick them from the **Select Puppet** dropdown — by default you can see yourself, your follower, and the actor you last pinned with the NotificationKey.

- **Is Arousal Blocked** — force this actor's arousal to a fixed `-2` (used to exclude them entirely).
- **Is Arousal Locked** — keep their arousal pinned at the current value; exposure and time no longer change it.
- **Is Exhibitionist** — flag them as getting aroused when *they* are seen naked. Changes some plugin calculations.
- **Gender Preference** — what this actor finds arousing.

The list below shows every static arousal effect on this actor with the current value, the timed function (if any), and parameters. You can edit values directly via input fields on each row. This is the page to open first when arousal isn't behaving — see [Troubleshooting](troubleshooting.md).

## Current Armor List

Per-item keyword curation — covered fully in [Armor Curation](armor-curation.md), including the [Export to KID file](kid-export.md) button at the top.

## Plugins

Each integration plugin has its own MCM page with settings specific to that integration: the Default plugin has sliders for nudity rate, orgasm satiation, sleep decay, etc. Devious Devices has device-rate sliders. SexLab has per-stage bonuses. OStim has thread / observer toggles and rate scaling.

You don't normally need to touch these unless you want to tune the feel — see [Tuning Recipes](tuning-recipes.md) for which sliders to reach for.
