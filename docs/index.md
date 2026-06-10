# SexLab Aroused NG

A persistent, per-actor arousal system for Skyrim SE/AE, packaged as an SKSE C++ plugin with a Papyrus script API.

Every tracked actor has a single arousal float (typically 0–100) that other mods read and react to. The framework handles storage, decay, scanning, line-of-sight evaluation, and MCM curation — your scripts and other adult-mod integrations stay focused on the *behavior* triggered by arousal, not the bookkeeping.

## Who's this for?

<div class="grid cards" markdown>

- :material-account: **Players**
  Install it, open MCM, tune the sliders to taste, curate which armors count as "naked" / "bikini" / "sexy" on a per-item basis, and (optionally) export your curation to a KID file that survives new saves.

  [→ User Guide](UserGuide.md)

- :material-file-document-edit: **Players sharing curation**
  Export the keyword/armor pairs you've toggled to a plain-text KID file. Send it to friends, drop it on Nexus, back it up alongside your modlist.

  [→ KID Reference](KID_Reference.md)

- :material-code-tags: **Mod authors**
  Register your own arousal effects (static or dynamic), read arousal on any actor, and plug into the multi-fork compatibility shim so consumer mods written against OSL Aroused work unchanged.

  [→ API Reference (GitHub)](https://github.com/crajjjj/SexlabArousedNG/blob/master/README.md)

</div>

## At a glance

- **Single float per actor**, calculated as the sum of all active effects.
- **Five built-in effect categories** (Naked, Timed, Sleep, Satisfaction, Legacy) shipped by the Default plugin, each with its own MCM page.
- **Plugins** for SexLab, Devious Devices, and OStim register additional effects when those mods are present.
- **Per-armor keyword curation** in MCM with on-disk persistence and KID export.
- **Cosave-backed state** that survives across saves, with a configurable scan/update loop and full LOS evaluation.

## Quick links

- [How arousal actually works](UserGuide.md#how-arousal-works)
- [MCM page-by-page tour](UserGuide.md#the-mcm-page-by-page)
- [I want my arousal to climb faster — MCM tuning recipe](UserGuide.md#i-want-my-arousal-to-climb-faster-mcm-tuning-by-source)
- [Coming from OSL Aroused?](UserGuide.md#im-coming-from-osl-aroused-and-nothing-is-happening)
- [Troubleshooting](UserGuide.md#troubleshooting)

## Project

- **Source / issues**: [github.com/crajjjj/SexlabArousedNG](https://github.com/crajjjj/SexlabArousedNG)
- **License**: Apache-2.0
