# C++ API (SKSE plugins)

For **SKSE plugins written in C++**, SLA NG exposes a native inter-plugin API — the same read/write-arousal operations as the Papyrus [`SloangNative`](native-api.md) API, callable directly in C++ with no Papyrus round-trip. Use it when you want native-speed arousal access from your own DLL (an ImGui overlay, a combat/AI plugin, a widget) instead of going through scripts.

The single consumer header is **`include/ArousalAPI.h`** (self-contained — copy it into your project).

!!! info "How to use the header"
    `ArousalAPI.h` is a **reference, not a library**: it gives you the documented signatures to cast `GetProcAddress` results to, plus the `SLA_Func` enum. There is no `.lib` and no import library anywhere, so copying it into your project adds **zero** build-time dependency on SLA NG. (Including it is optional — hand-writing the few signatures you use works identically.)

    Never call the `SLA_*` names directly: they're declarations of functions that live in *our* DLL, so a direct call is an unresolved-external link error. Always call through a function pointer obtained from `GetProcAddress`, as shown below.

    In SLA NG 3.3.1 and earlier the header defaulted `SLA_API` to `__declspec(dllexport)`, so a plain `#include` made *your* plugin try to export our symbols. Use the current header, or `#define SLA_API` to nothing before including an older one.

!!! danger "`SloangNative` ≠ this API — but they mirror each other"
    This C++ API covers the subset of `SloangNative` backed by the SKSE plugin's `ArousalManager`: **version, arousal reads, and the whole dynamic-effects section**. Every export is `SLA_<SloangNativeName>` with the same units and semantics. The `SloangNative` functions backed by Papyrus quest scripts — `GetExposure`, exposure-based `ModArousal`/`SetArousal`, `IsActorNaked`, the exhibitionist / arousal-locked / blocked / gender-preference flags, and orgasm tracking — are **not** exported (they live in script, not the DLL). For those, call the Papyrus [`SloangNative`](native-api.md) API.

## Resolving the exports

Consumers do **not** link against SLA NG. Resolve the exports at runtime with `GetProcAddress`; a null module handle means SLA is not installed, so treat the integration as optional.

```cpp
#include <Windows.h>       // GetModuleHandleA, GetProcAddress
#include "ArousalAPI.h"    // declares SLA_GetArousal, ... and the SLA_Func enum

// One holder for the exports you actually call. Each pointer's TYPE is taken
// straight from the header via decltype(&SLA_Xxx) -- that is the whole point of
// copying ArousalAPI.h: you never hand-retype a signature, and if ours ever
// changed, your build would flag the mismatch instead of crashing at runtime.
// (decltype only inspects the declaration; it creates no link dependency.)
struct SLA {
    decltype(&SLA_GetVersion)         GetVersion         = nullptr;
    decltype(&SLA_GetArousal)         GetArousal         = nullptr;
    decltype(&SLA_AddDecayingEffect)  AddDecayingEffect  = nullptr;
    decltype(&SLA_ClearDynamicEffect) ClearDynamicEffect = nullptr;
    // add only the exports you use

    bool available() const { return GetVersion != nullptr; }
};

// Call once, after SLA's DLL has loaded (see the tip below). If SLA isn't
// installed every pointer stays null and available() returns false, so the
// whole integration is opt-in with no hard dependency.
inline SLA LoadSLA() {
    SLA sla;
    HMODULE h = GetModuleHandleA("SexlabArousedNG.dll");   // null => SLA absent
    if (!h) return sla;

    // Resolve each export BY NAME and store it as a callable pointer. The
    // reinterpret_cast target is the pointer's own type, so the string name
    // and the signature always agree. (C4191 is MSVC's expected warning for a
    // FARPROC->function-pointer cast; the push/disable/pop lets /W4 /WX pass.)
#pragma warning(push)
#pragma warning(disable : 4191)
    sla.GetVersion         = reinterpret_cast<decltype(sla.GetVersion)>        (GetProcAddress(h, "SLA_GetVersion"));
    sla.GetArousal         = reinterpret_cast<decltype(sla.GetArousal)>        (GetProcAddress(h, "SLA_GetArousal"));
    sla.AddDecayingEffect  = reinterpret_cast<decltype(sla.AddDecayingEffect)> (GetProcAddress(h, "SLA_AddDecayingEffect"));
    sla.ClearDynamicEffect = reinterpret_cast<decltype(sla.ClearDynamicEffect)>(GetProcAddress(h, "SLA_ClearDynamicEffect"));
#pragma warning(pop)
    return sla;
}
```

Then call **through the pointer**, never the `SLA_*` name directly:

```cpp
// Store the result once (e.g. in a global or your plugin's state object).
SLA sla = LoadSLA();

if (sla.available() && sla.GetVersion() >= 30300000u) {   // installed AND new enough
    RE::Actor* player = RE::PlayerCharacter::GetSingleton();

    float a = sla.GetArousal(player);                       // read
    sla.AddDecayingEffect(player, "MyMod_Thrill", 40.0f, 2.0f);  // +40, halves every 2h
    // ... later ...
    sla.ClearDynamicEffect(player, "MyMod_Thrill");         // remove
}
```

`sla.GetArousal(player)` calls the resolved pointer. Writing `SLA_GetArousal(player)` instead would be an unresolved-external link error — that name only exists inside *our* DLL.

!!! tip "Resolve after SLA has loaded"
    `GetModuleHandleA` only sees SLA NG once its DLL is loaded. Call `LoadSLA()` on or after SKSE's `kPostLoad`/`kPostPostLoad` message (or lazily on first use) — not from a static initializer, which runs too early.

## Version gating

Gate on both presence and version before using any export — `sla.available() && sla.GetVersion() >= 30300000u`, as in the usage block above. `available()` catches "SLA not installed"; the version compare catches "installed but too old for the export you need".

- **`SLA_GetVersion()`** — packed `MMmmppp` mod/DLL version (e.g. `30300000` for 3.3.0), the C++ counterpart of `SloangNative.GetVersion()`. Read from the DLL's own build version. See the header for the caveat about content-only releases.
- **`SLA_GetInterfaceVersion()`** — the C API surface version, packed `MMmmpp` (`10000` == 1.0.0), bumped only when exports are added. Exports are append-only, so a value check is enough to feature-detect.

## Threading

!!! note "Thread-safe — call from any thread"
    Every export forwards through `ArousalManager`, whose per-actor store is guarded by a single mutex held only for in-memory work (never across a call back into the Papyrus VM). Concurrent queries, the mod's own scan/cleanup, and cosave save/load are all serialized, so there is no data race and no deadlock/hang risk. You do not need to marshal calls onto the main thread.

## Units & behaviour

Identical to the Papyrus API, so the [`SloangNative` reference](native-api.md) is the source of truth for the details:

- Arousal is one float per actor, conventionally 0–100 but **unclamped**. `SLA_GetArousalInt` clamps to 0–100.
- The `SLA_Add*` convenience wrappers take time in **in-game hours**; the low-level `SLA_SetDynamicEffect` `param` is in **game days**.
- `cap`/`limit` is always **per-effect**, never a global ceiling — see [What happens when a cap is reached](native-api.md#what-happens-when-a-cap-is-reached).
- Each `SLA_Add*` **creates or refreshes** the named effect (it does not stack — use `SLA_ModDynamicEffect` to accumulate).

!!! warning "`amount`/`startAmount` of `0` is a no-op"
    A dynamic effect's `initialValue == 0` is ignored by the engine, so `SLA_AddFlatEffect(who, id, 0.0f)` and `SLA_AddLinearEffect(who, id, /*start*/0.0f, …)` do nothing. To remove an effect use `SLA_ClearDynamicEffect`; to start near zero, pass a tiny non-zero value.

## Function reference

Every function is null-safe (a null actor or null `effectId` returns `0`/`false`/no-op). Effect IDs should be namespaced with your mod prefix (`"MyMod_..."`).

### Meta

| Export | Returns |
|--------|---------|
| `uint32_t SLA_GetVersion()` | Packed mod/DLL version (`MMmmppp`) |
| `uint32_t SLA_GetInterfaceVersion()` | Packed C API version (`MMmmpp`) |

### Reading

| Export | Returns |
|--------|---------|
| `float SLA_GetArousal(RE::Actor* who)` | Current arousal (unclamped; re-summed each call) |
| `int32_t SLA_GetArousalInt(RE::Actor* who)` | Current arousal clamped to 0–100 |

### Dynamic effects — convenience (recommended)

Time arguments in **in-game hours**. Amounts may be negative.

| Export | Effect |
|--------|--------|
| `void SLA_AddFlatEffect(who, effectId, amount)` | Constant, non-decaying contribution |
| `void SLA_AddDecayingEffect(who, effectId, amount, halveEveryHours)` | One-shot bump halving every `halveEveryHours` toward 0 |
| `void SLA_AddLinearEffect(who, effectId, startAmount, ratePerHour, cap)` | Ramps by `ratePerHour` (negative to ramp down) until `cap` |
| `void SLA_AddDelayedEffect(who, effectId, amount, delayHours)` | Contributes 0 for `delayHours`, then jumps to `amount` |
| `void SLA_ClearDynamicEffect(who, effectId)` | Removes the effect entirely (safe if absent) |
| `bool SLA_HasDynamicEffect(who, effectId)` | True if the effect has a non-zero value |

### Dynamic effects — low-level

Reach for these only when a wrapper doesn't fit; you manage `functionId`/`param`/`limit` yourself (use the `SLA_Func*` enum, not bare ints). `param` is in **game days**.

| Export | Effect |
|--------|--------|
| `void SLA_SetDynamicEffect(who, effectId, initialValue, functionId, param, limit)` | Create/replace an effect. `initialValue` is **absolute**; `initialValue == 0` is **ignored** — use `SLA_ClearDynamicEffect` to remove |
| `void SLA_ModDynamicEffect(who, effectId, modifier, limit)` | Add `modifier`, clamped at `limit` (lower bound if `modifier < 0`, upper if `> 0`) |
| `float SLA_GetDynamicEffectValue(who, effectId)` | Read a single effect's value (`0` if absent) |

### Timed-function IDs (`SLA_Func` enum)

Pass these as `functionId` to `SLA_SetDynamicEffect`. See [Timed function IDs](overview.md#timed-function-ids) for behaviour.

| Enumerator | ID | Behaviour |
|-----------|----|-----------|
| `SLA_FuncNone` | 0 | Static value |
| `SLA_FuncDecay` | 1 | Halves every `param` game days |
| `SLA_FuncLinear` | 2 | Changes by `param` per game day |
| `SLA_FuncSine` | 3 | Oscillates |
| `SLA_FuncDelayedStep` | 4 | Jumps to `limit` after `param` days |

## Reacting to changes

There is no C++ event callback. To react to arousal changes rather than polling, register for the **`sla_UpdateComplete`** ModEvent (a `SKSE::ModCallbackEvent`) — see [Reacting to updates](native-api.md#reacting-to-updates-dont-poll). Between cycles, `SLA_GetArousal` is a cheap re-sum you can call any time.
