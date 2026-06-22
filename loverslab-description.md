SLO Aroused NG

Next-generation arousal for SexLab and OStim, based on SL Aroused NG 0.2.2 by ponzi with an NG plugin. Arousal is calculated dynamically from MCM-configurable effects and updates smoothly on request — no external heavy state updating needed. Solves the problem of other mods competing for the state.

A modern, high-performance rewrite of SL Aroused.


⚡ MIRROR

This is a mirror of the Nexus mod page:
https://www.nexusmods.com/skyrimspecialedition/mods/151502


✨ FEATURES

- Full support for: SexLab, SLP+, SLSO, OStim, OAroused bridge
- Devious Devices integration
- Aroused animations (optional) – Thanks to kzrp
- Masturbation hotkey (OStim uses furniture if nearby)
- Improved performance: native arousal calculations, no state-changing overhead. NG-based native SKSE plugin.
- More realistic arousal model – avoids nympho behavior by default (toggleable)
- Includes Baka + SLAX keywords
- Advanced Nudity support: Nude / Bottomless / Topless / Genitals factions
- SLAM effects (active/passive) + mod event hooks (e.g., CEE)
- In-game keyword editor (with optional export to KID file)
- Soft compatibility with many external mods
- Creature support
- SLP+ stats integration
- Arousal notifications (optional)
- Fully replaces all versions of SL Aroused – requires new game unless you're on NG 0.2.2
- User guide: https://crajjjj.github.io/SexlabArousedNG/


🔥 BUILT-IN EFFECTS (all configurable in MCM)

- Naked Exposure: Gain arousal from seeing nudity (up to 50 / 15 for non-preferred gender)
- Sex: Arousal rises from participating in or witnessing sex
- Satisfaction: Post-orgasm relief, decays quickly
- Exhaustion: Reduces arousal after each SexLab scene
- Timed: Gradual increase after long abstinence (accounts for belts/plugs)
- Trauma: Lowers arousal after rough encounters (unless extremely lewd)
- Sleep: Some arousal is added after sleep for PC
- Conditional Expressions Extended has lots of dynamic effects - cold, pain, headache etc.
  https://www.nexusmods.com/skyrimspecialedition/mods/91438


🔄 COMPATIBILITY

- Works with Skyrim SE / AE / VR


📦 REQUIREMENTS

Hard Requirements:
- Address Library — https://www.nexusmods.com/skyrimspecialedition/mods/32444
- PapyrusUtil SE — https://www.nexusmods.com/skyrimspecialedition/mods/13048

Soft Dependencies (for full features):
- powerofthree's Papyrus Extender — https://www.nexusmods.com/skyrimspecialedition/mods/22854
- SexLab
- OStim Standalone — https://www.nexusmods.com/skyrimspecialedition/mods/98163
- Milk Mod Economy
- Devious Devices / NG
- SLEN
- FNIS, Nemesis, or Open Animation Replacer – if enabling aroused animations


📝 NOTES

- This mod replaces all previous SL Aroused versions
- Uninstall older versions before installing
- Requires a new save unless already using SexLab Aroused NG 0.2.2
- Join the dev chat here: https://discord.com/invite/mycaxFPSeV
- View the source code on GitHub: https://github.com/crajjjj/SexlabArousedNG

For mod authors – How to integrate?:
https://crajjjj.github.io/SexlabArousedNG/authors/compatibility/


❓ FAQ

Q: Do I really need a new game?
A: Yes, unless you were already using SexLab Aroused NG 0.2.2. Earlier versions used a different system for storing arousal data, which is incompatible. MCM won't initialise either.

Q: Can I disable specific effects like Trauma or Timed arousal?
A: Yes. All effects are fully configurable through the mod's MCM menu.

Q: Does it support XXX?
A: Short answer - yes. Long answer: It uses the same interface as other SLA mods + optional OSLAroused bridge. Sometimes, mods like SLEN implement complicated logic on top of old interfaces to do what the SLOANG mod does. It will still work for those, but patches make it more correct and efficient.

Q: Is this compatible with CBBE/3BA/BHUNP bodies?
A: Yes. Body type does not affect arousal calculations. This mod focuses on logic and stat tracking, not body mesh handling.

Q: Do I need animations?
A: No, but if you want visual feedback (e.g., aroused idles or masturbation), you'll need to enable animations and use a compatible engine (FNIS, Nemesis, or OAR).

Q: Is this safe to uninstall mid-playthrough?
A: No. This mod creates persistent native forms and hooks. You should uninstall it only if you're starting a new game or using a save that has never seen it.

Q: The MCM menu isn't showing up. What should I do?
A:
- Double-check requirements – ensure Address Library, PapyrusUtil SE, and soft dependencies are correctly installed.
- Check if SexLabAroused.esm is already present in your load order. If it exists from an older mod, it may block initialization. Remove/disable it.
- Check that plugins are enabled.
- Use Papyrus Tweaks NG – it can help resolve MCM registration issues by fixing script load order or timing.
  https://www.nexusmods.com/skyrimspecialedition/mods/77779
- Try MCM Menu Maid 2 – it forces stuck MCM entries to initialize.
  https://www.nexusmods.com/skyrimspecialedition/mods/67556
- Wait in-game or save & reload – sometimes the MCM loads after a scene transition.

Q: Any way to disable notifications?
A: Disable notifications in MCM. Also consider the Notification Filter mod:
   https://www.nexusmods.com/skyrimspecialedition/mods/67925


SubscribeStar: https://subscribestar.adult/crajjjj


🎉 CREDITS

- ponzi – Core rewrite & NG overhaul
- Contributors to Aroused, Baka, SLAX, SLAM


Enjoy your immersive, dynamic arousal system!
