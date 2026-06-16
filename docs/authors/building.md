# Building from Source

This project uses **CMake** and **vcpkg** for dependency management. **MSVC or Clang-CL on Windows is required** — GCC and MinGW are not supported because SKSE plugins must be Windows DLLs built against the Windows SDK.

For where everything lives in the tree, see the [repo layout](overview.md#repo-layout) in the Author Overview.

## Prerequisites

- [CMake 3.21+](https://cmake.org/download/)
- [vcpkg](https://github.com/microsoft/vcpkg)
- MSVC (Visual Studio 2022) or Clang-CL

## Build steps

1. **Clone the repository:**

   ```sh
   git clone https://github.com/crajjjj/SexlabArousedNG.git
   cd SexlabArousedNG
   ```

2. **Bootstrap vcpkg (Windows):**

   ```bat
   git clone https://github.com/microsoft/vcpkg.git
   .\vcpkg\bootstrap-vcpkg.bat
   .\vcpkg\vcpkg install --triplet x64-windows-skse
   ```

3. **Set `VCPKG_ROOT`:**

   ```powershell
   # PowerShell
   $env:VCPKG_ROOT = "C:\path\to\vcpkg"
   ```
   ```cmd
   :: Command Prompt
   set VCPKG_ROOT=C:\path\to\vcpkg
   ```

4. **Configure and build:**

   | Preset (configure) | Preset (build) | Compiler |
   |-|-|-|
   | `build-release-msvc` | `release-msvc` | MSVC |
   | `build-debug-msvc` | `debug-msvc` | MSVC |
   | `build-release-clang` | `release-clang` | Clang-CL |
   | `build-debug-clang` | `debug-clang` | Clang-CL |

   ```sh
   cmake --preset build-release-msvc
   cmake --build --preset release-msvc
   ```

   The output DLL is placed under `build/<preset>/` and deployed to `dist/Core/SKSE/Plugins/SexlabArousedNG.dll`.

## Tests

The C++ math is covered by Catch2 tests in `test/ArousalMath.cpp`:

```sh
cmake --preset build-debug-msvc -DBUILD_TESTS=ON
cmake --build --preset debug-msvc
```

## Papyrus scripts

Papyrus **sources** live in `dist/Core/Source/Scripts/*.psc`; compiled bytecode lands in `dist/Core/Scripts/*.pex`. Compile the `.psc` files with the Creation Kit's `PapyrusCompiler.exe` (or your editor's Papyrus integration) against the SKSE/SkyUI/PapyrusUtil script headers. Never hand-edit the `.pex` files — they are build output.

## Bumping the version

Three files hold version strings — keep them in sync:

1. **`dist/fomod/info.xml`** — the FOMOD installer version shown in mod managers (`<Version>`). This is the canonical user-facing version.
2. **`dist/Core/Source/Scripts/slaconfigscr.psc`** — `GetVersionString()` is the display string shown in MCM; `GetVersion()` is the integer form using the `MMmmppp` packing scheme documented in the function (e.g. `30100009` for 3.1.9). The **integer** also drives `OnVersionUpdate()` migration paths — only the integer triggers migrations, the string is display-only. Recompile `slaconfigscr.pex` after editing.
3. **`CMakeLists.txt`** — `project(... VERSION X.Y.Z ...)` controls the DLL's resource version. Synced to the fomod version since 3.1.11; bump when cutting a release that includes C++ changes.

!!! warning "Cosave ID is stable"
    The cosave ID `SLAN` (`0x4E414C53`) is stable across versions — do **not** change it without a save-compatibility strategy. On load, per-actor arousal is validated against the sum of its effects (a checksum), and Revert clears all data.
