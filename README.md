# SexLab Aroused NG

A persistent, per-actor **arousal system** for Skyrim SE/AE, packaged as an SKSE C++ plugin (CommonLibSSE-NG) with a Papyrus script API. Every tracked actor has a single arousal float (typically 0–100); other mods register static or dynamic effects that sum into it, and read it back to drive behavior.

## Documentation

Full documentation lives on the docs site: **https://crajjjj.github.io/SexlabArousedNG/**

**For players**
- [Getting Started](https://crajjjj.github.io/SexlabArousedNG/players/getting-started/) — requirements, installation, FOMOD options, first-time setup
- [How Arousal Works](https://crajjjj.github.io/SexlabArousedNG/players/how-arousal-works/) — the single-float model and the five effect categories
- [MCM Reference](https://crajjjj.github.io/SexlabArousedNG/players/mcm-reference/), [Armor Curation](https://crajjjj.github.io/SexlabArousedNG/players/armor-curation/), [Export to KID File](https://crajjjj.github.io/SexlabArousedNG/players/kid-export/)
- [Tuning Recipes](https://crajjjj.github.io/SexlabArousedNG/players/tuning-recipes/) — make it climb faster, coming from OSL Aroused
- [Troubleshooting & Logs](https://crajjjj.github.io/SexlabArousedNG/players/troubleshooting/)

**For mod authors**
- [Overview](https://crajjjj.github.io/SexlabArousedNG/authors/overview/) — the model, repo layout, and choosing an integration approach
- [Dynamic Effects](https://crajjjj.github.io/SexlabArousedNG/authors/dynamic-effects/) — fire a ModEvent from any script
- [Static Effects (Plugin Quests)](https://crajjjj.github.io/SexlabArousedNG/authors/static-effects/) — `sla_PluginBase`, lifecycle, LOS, MCM options
- [Papyrus API Reference](https://crajjjj.github.io/SexlabArousedNG/authors/papyrus-api/) — every `slaInternalModules` native function
- [Compatibility (OSL Aroused & SLA NG)](https://crajjjj.github.io/SexlabArousedNG/authors/compatibility/)
- [Building from Source](https://crajjjj.github.io/SexlabArousedNG/authors/building/)

## Building

See [Building from Source](https://crajjjj.github.io/SexlabArousedNG/authors/building/). In short, with CMake 3.21+ and vcpkg on Windows (MSVC or Clang-CL):

```sh
cmake --preset build-release-msvc
cmake --build --preset release-msvc
# Output: dist/Core/SKSE/Plugins/SexlabArousedNG.dll
```

Papyrus sources in `dist/Core/Source/Scripts/*.psc` compile to `dist/Core/Scripts/*.pex`.

## License & changelog

Apache-2.0. Release notes are published on the [GitHub releases page](https://github.com/crajjjj/SexlabArousedNG/releases).
