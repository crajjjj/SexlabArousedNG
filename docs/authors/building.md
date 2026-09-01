# Building from Source

This project builds with **[xmake](https://xmake.io/) 3.0+**. **MSVC on Windows is required** — GCC and MinGW are not supported because SKSE plugins must be Windows DLLs built against the Windows SDK.

For where everything lives in the tree, see the [repo layout](overview.md#repo-layout) in the Author Overview.

## Prerequisites

- [xmake 3.0+](https://xmake.io/#/guide/installation)
- MSVC (Visual Studio 2022 Build Tools or newer)

## Build steps

1. **Clone the repository (with submodules):**

   ```sh
   git clone --recurse-submodules https://github.com/crajjjj/SexlabArousedNG.git
   cd SexlabArousedNG
   ```

   [CommonLibSSE-NG](https://github.com/alandtse/CommonLibSSE-NG) (alandtse fork, pinned to v7.0.0 — required for Skyrim 1.7.99 / Address Library format 5) is vendored as a git submodule at `lib/commonlibsse-ng`. If you cloned without `--recurse-submodules`, run:

   ```sh
   git submodule update --init --recursive
   ```

2. **Configure and build:**

   ```sh
   xmake f -m releasedbg   # configure; use -m debug for a debug build
   xmake                   # build
   ```

   CommonLibSSE-NG's dependencies (spdlog, directxtk, …) are fetched from xmake-repo automatically. The first configure compiles CommonLibSSE-NG from source (~15 min, cached afterwards); set `COMMONLIB_PREBUILT=1` in the environment before configuring to download its prebuilt release bundle instead.

   The output DLL lands under `build/` and is deployed to `dist/Core/SKSE/Plugins/SexlabArousedNG.dll`.

> **Note:** up to 3.3.4 this project built with CMake + vcpkg; that path was removed in favor of xmake. If you have an old checkout, delete stale `build/` and `vcpkg_installed/` directories.

## Papyrus scripts

Papyrus **sources** live in `dist/Core/Source/Scripts/*.psc`; compiled bytecode lands in `dist/Core/Scripts/*.pex`. Compile the `.psc` files with the Creation Kit's `PapyrusCompiler.exe` (or your editor's Papyrus integration) against the SKSE/SkyUI/PapyrusUtil script headers. Never hand-edit the `.pex` files — they are build output.

## Bumping the version

Three files hold version strings — keep them in sync:

1. **`dist/fomod/info.xml`** — the FOMOD installer version shown in mod managers (`<Version>`). This is the canonical user-facing version.
2. **`dist/Core/Source/Scripts/slaconfigscr.psc`** — `GetVersionString()` is the display string shown in MCM; `GetVersion()` is the integer form using the `MMmmppp` packing scheme documented in the function (e.g. `30100009` for 3.1.9). The **integer** also drives `OnVersionUpdate()` migration paths — only the integer triggers migrations, the string is display-only. Recompile `slaconfigscr.pex` after editing.
3. **`xmake.lua`** — `set_version("X.Y.Z")` controls the DLL's resource version and the generated `SKSEPluginInfo` version. Synced to the fomod version; bump when cutting a release that includes C++ changes.

!!! warning "Cosave ID is stable"
    The cosave ID `SLAN` (`0x4E414C53`) is stable across versions — do **not** change it without a save-compatibility strategy. On load, per-actor arousal is validated against the sum of its effects (a checksum), and Revert clears all data.
