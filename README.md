
## Build Instructions

This project uses **CMake** and **vcpkg** for dependency management and building. These instructions assume a recent version of CMake and a C++ compiler installed on your system.

### Prerequisites

* [CMake](https://cmake.org/download/)
* [vcpkg](https://github.com/microsoft/vcpkg)
* C++ compiler (MSVC, Clang, GCC, etc.)

### Build Steps

1. **Clone the repository** (if not already):

   ```sh
   git clone <your-repo-url>
   cd <your-repo-folder>
   ```
2. **Install dependencies using vcpkg:**

   ```sh
   git clone https://github.com/microsoft/vcpkg.git
   ./vcpkg/bootstrap-vcpkg.sh    # or .bat on Windows
   ./vcpkg/vcpkg install --triplet x64-windows-skse
   ```
3. **Set `VCPKG_ROOT` for CMake presets (Windows):**

   PowerShell:
   ```powershell
   $env:VCPKG_ROOT="C:\path\to\vcpkg"
   ```
   Command Prompt:
   ```cmd
   set VCPKG_ROOT=C:\path\to\vcpkg
   ```
4. **Configure with CMake (preset):**

   ```sh
   cmake --preset build-release-msvc
   ```
5. **Build the project:**

   ```sh
   cmake --build --preset release-msvc
   ```
---

## Papyrus Modding

This project includes integration points and event interfaces for Skyrim modding using Papyrus scripts.

* **Event-based arousal effect management** allows mod authors to trigger or modify effects on actors dynamically.
* **Integration**: You can hook into these systems via Papyrus scripts to implement your own logic or enhance existing gameplay.
* **See examples below** for event signatures and usage patterns.

**For more, see:**

* [Creation Kit Documentation](https://www.creationkit.com/index.php?title=Category:Papyrus)
* Papyrus script samples further down this document.

---

## Static Effects

**Static effects** are always present on every character and require implementation via a plugin quest script.
They are highly performant and ideal for common/global effects.
For usage, refer to plugins like `sla_sexlabplugin.psc` (SexLab) or `sla_ddplugin.psc` (Devious Devices).
Required function documentation can be found in `sla_pluginbase.psc`.

---

## Dynamic Effects

**Dynamic effects** are managed at runtime and triggered via events.
They are easy to implement and ideal for temporary or rare effects.
Note: They may be less performant if changed very frequently.

---

### Adding Dynamic Effects

#### Event Handler Signature

```papyrus
SetDynamicArousalEffect(Form whoF, string effectId, float initialValue, int functionId, float param, float limit)
```

#### Example: Sending the Event (Papyrus)

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)             ; The affected actor
ModEvent.PushString(handle, "DDTeasing")   ; Internal identification
ModEvent.PushFloat(handle, 50.0)           ; Initial value
ModEvent.PushInt(handle, 1)                ; Timed function to use (see table below)
ModEvent.PushFloat(handle, 1.0 / 24.0)     ; Parameter ($param) for timed function
ModEvent.PushFloat(handle, 0.0)            ; Stop at this value
ModEvent.Send(handle)
```

---

### Timed Function IDs

| ID | Description                                            |
| -- | ------------------------------------------------------ |
| 0  | None (no timed effect)                                 |
| 1  | Reduce by 50% after `$param` in-game days              |
| 2  | Change effect value by `$param` per day                |
| 3  | Effect value = `(sin(days * $param) + 1.0) * limit`    |
| 4  | Effect value = 0 if time < `$param`, otherwise `limit` |

---

### Sample Dynamic Effect Events

#### Negative arousal fading (linear increase)

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, act)
ModEvent.PushString(handle, "Negative Arousal fading")
ModEvent.PushFloat(handle, -100.0)         ; Start negative
ModEvent.PushInt(handle, 2)                ; Linear increase
ModEvent.PushFloat(handle, 60 * 24.0)      ; +60 each hour
ModEvent.PushFloat(handle, 0.0)            ; Remove when cap reached
ModEvent.Send(handle)
```

#### Teasing effect with maximum cap

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "Teasing")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 2)                ; Linear increase
ModEvent.PushFloat(handle, 400.0 * 24.0)   ; +400 arousal per hour
ModEvent.PushFloat(handle, 100.0)          ; Max value
ModEvent.Send(handle)
```

#### Teasing effect with decay

```papyrus
int handle = ModEvent.Create("slaSetArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "Teasing")
ModEvent.PushFloat(handle, 0.0)
ModEvent.PushInt(handle, 1)                ; Decay
ModEvent.PushFloat(handle, 2.0 / 24.0)     ; 50% every other hour
ModEvent.PushFloat(handle, 0.0)            ; Remove at zero
ModEvent.Send(handle)
```

---

## Modifying Dynamic Effects

To modify an existing dynamic effect, use:

#### Event Handler Signature

```papyrus
ModDynamicArousalEffect(Form whoF, string effectId, float modifier, float limit)
```

#### Example: Sending the Event

```papyrus
int handle = ModEvent.Create("slaModArousalEffect")
ModEvent.PushForm(handle, who)
ModEvent.PushString(handle, "Teasing")
ModEvent.PushFloat(handle, -20.0)         ; Modifier value
ModEvent.PushFloat(handle, 0.0)           ; Remove at zero
ModEvent.Send(handle)
```

---

## Summary

* **Use static effects** for always-on, common, or global effects.
* **Use dynamic effects** for temporary, mod-specific, or rare effects.

See script headers and `sla_pluginbase.psc` for more advanced usage and plugin integration details.

### Randomness

The initial arousal update uses a global `std::mt19937` engine seeded during plugin initialization.  
With the default seed from `std::random_device` the offset remains nondeterministic, but providing a fixed seed in `InitializeRandomEngine` will make it deterministic across runs.
