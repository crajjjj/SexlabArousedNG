# Armor Curation

The *Current Armor List* MCM page (shown as **Current Equipment** in-game) is the most player-facing feature of the mod. It does two things:

- **Rate** the worn items with the 8 built-in arousal properties (Naked, Bikini, Sexy, ...).
- **Tag** items with **custom keywords** from any loaded mod — Advanced Nudity Detection's coverage and exposure keywords being the flagship use.

Everything is per Armor *template*: any actor wearing the same armor inherits the curation. Once you're done, [Export to KID file](kid-export.md) makes it permanent and shareable.

## Page layout

Top controls:

| Control | What it does |
|---|---|
| **Enable detailed options** | Switches the 8 ratings between simple toggles and 0–100 sliders |
| **Select target actor** | Pick whose outfit to inspect (you, follower, puppet) |
| **Register Custom Keyword** | Type an EditorID to add it to your keyword set |
| **Remove Custom Keyword** | Pick a keyword to drop from the set (confirmed) |
| **Save Keywords to File** / **Load Keywords from File** | Sync your keyword set with [the keywords file](#the-keywords-file-save-load) |
| **Export to KID file** | Write the whole curation to a KID ini — see [Export to KID file](kid-export.md) |

Below that, **Equipped Items** lists the worn pieces:

- **Body armor** (slot 32) — all 8 ratings: **Naked, Bikini, Sexy, Slooty, Illegal, Respectable, Ragged** + **Counts as Clothing**.
- **Shoes/boots** (slot 37) — **High Heels**.
- **Items in bikini slots** (44, 45, 48, 49, 52, 56, 58) — **Bikini** rating + **Counts as Clothing** each.

Every body and bikini-slot item additionally gets three keyword menus:

- **Applied** — how many custom keywords the item carries; open it (or hover) to see the list. View-only.
- **Add keyword...** — apply one of your registered keywords to the item.
- **Remove keyword...** — take an applied keyword off.

The pick-lists scroll, so any number of registered keywords stays manageable; the first row, `(close)`, backs out without changing anything.

!!! tip "Toggle mode vs Slider mode"
    Each rating is stored as a value from 0–100, not a simple on/off. **Enable detailed options** switches to sliders for precise values; with it off, toggling ON writes a representative value (51 for most, 75 for High Heels) and OFF writes 0. Any non-zero value normally counts as "the property is present" — though some consumer mods threshold or scale on the exact number.

## The 8 built-in ratings

| Internal name | MCM label | What it represents | Affects naked detection? |
|---|---|---|---|
| `EroticArmor` | Naked | Body covering that exposes too much to count as "clothed" | Yes — directly triggers the naked state |
| `SLA_ArmorHalfNakedBikini` | Bikini | Bikini-style outfits (TAWoBA et al.) | Yes — soft naked |
| `SLA_ArmorPretty` | Sexy | Form-fitting, attractive but not revealing | Mild exposure |
| `SLA_ArmorHalfNaked` | Slooty | Revealing without being bikini-cut | Soft naked |
| `SLA_ArmorIllegal` | Illegal | Outfits forbidden in towns; some mods trigger guard reactions | No (but plugins react) |
| `ClothingRich` | Respectable | Fancy / high-status clothes (sometimes called "Posh") | Changes NPC reactions |
| `ClothingPoor` | Ragged | Beggar / worn attire | Changes NPC reactions |
| `SLA_KillerHeels` | High Heels | Heels / heeled boots | Affects walk animations |
| *(state-only)* | Counts as Clothing | Mark a revealing item as NOT triggering naked detection | Overrides naked state |

### "Counts as Clothing" specifically

This one's not a keyword — it's a state flag. It tells the naked-detection logic to treat the wearer as clothed even if they're showing skin. Useful for body suits, tights, see-through items, etc., that you don't want triggering the "naked" state.

!!! warning "Counts as Clothing is not exported to KID"
    Because it's a metadata flag and not a real Keyword, there's nothing for KID to distribute — it lives only in your cosave. See [what gets exported](kid-export.md#what-gets-exported).

## How curation persists

- Every rating and keyword assignment writes to the SKSE cosave via PapyrusUtil's StorageUtil, so it survives saves and quits.
- On every game reload, the mod re-applies the assigned keywords to their Armor records — the curation comes back even after you exit and relaunch Skyrim.
- If an Armor record **already has** one of the 8 built-in keywords baked into its source ESP (e.g. TAWoBA armors shipping with `SLA_ArmorHalfNakedBikini`), the toggle lights up automatically when you open the page, and the match is recorded so it appears in your [KID export](kid-export.md).

!!! note "ESP-baked keywords are not auto-detected for customs"
    That automatic pickup applies to the 8 built-ins only. **Applied** reflects just what you set through the menus — an ESP-baked custom keyword still works in-game (mods see it on the record), but it lists under *Add keyword...*, and removing it via the menu only lasts until the next game launch (the ESP puts it back).

## Custom keywords

Beyond the 8 built-ins, you can register **any keyword** from any loaded ESP and apply it per item.

### Registering a keyword

1. Find the keyword's **EditorID** — usually documented in the keyword-providing mod's description (e.g. `SLA_ArmorHalfNakedBondage`, `AND_Underwear`).
2. Click **Register Custom Keyword**, type the EditorID exactly and confirm. It must match a keyword in your load order — if not, you get an error popup.
3. The keyword now appears in every item's **Add keyword...** menu.

For EditorIDs too long for SkyUI's input box, put them in the keywords file and use **Load Keywords from File** instead.

### Unregistering a keyword

Click **Remove Custom Keyword** and pick it from the list (asks for confirmation). This only removes it from your registered set — per-armor assignments are kept and come back fully wired if you register it again. The keywords file is not touched.

### The keywords file (Save / Load)

Your keyword set can be stored in `Data\SKSE\Plugins\StorageUtilData\SLAX\Keywords.json`:

- **Load Keywords from File** registers every EditorID in the file's `customkeywords` list, **replacing** your registered set (asks for confirmation). Unknown EditorIDs (not in a loaded ESP) are skipped.
- **Save Keywords to File** writes your registered set to the top of `customkeywords`, skipping anything already in the file — use it to keep your set before a Load, or to carry it to another character.
- Registering/removing keywords in the MCM never modifies the file on its own.

The file ships pre-filled with **32 female-oriented defaults** from Advanced Nudity Detection: AND's coverage classifiers (`AND_CoversAll`, `AND_ArmorTop`/`Bottom`, `AND_Bra`, `AND_Underwear`, the `AND_*Curtain` family), `AND_Ignore` (make AND skip a misdetected accessory entirely), pasties/skimpy garments, graded exposure keywords, and the Modesty set. The rest of the AND set — including all male variants — waits in `copyuprespectlimit`; move IDs up into `customkeywords` and Load again to enable them.

!!! tip "Coverage keywords fix misdetected items"
    Tag an item with a coverage keyword to make AND count it as covering — e.g. `AND_Underwear` on panties clears the bottom-exposed state (and the Female Modesty covering animation driven by it). Escalate to `AND_ArmorBottom` if the item should count as a fully dressed bottom.

### Dynamic modesty — the Modesty set (setups without AND)

The shipped `Modesty`, `NoModesty`, `NoModestyTop`, `NoModestyBottom` and `NoModestyAll` keywords belong to [Dynamic Feminine — Female Modesty Animations](https://www.nexusmods.com/skyrimspecialedition/mods/104374) (they live in its `Modesty_Keyword.esp`). That mod's OAR conditions read them from the actor **and from worn items**, so you can steer the covering animations per piece of gear:

- `NoModestyBottom` on a worn item — no bottom-covering animation while it's worn.
- `NoModestyTop` — same for the top.
- `NoModestyAll` — suppresses covering entirely.
- `Modesty` — marks an item the covering logic should treat as modesty-relevant.

!!! warning "With AND installed, these keywords do nothing"
    Advanced Nudity Detection 3.x ships OAR overrides for the Female Modesty animations that **disable every keyword condition** and drive covering from AND's own modesty rank and presets instead. On an AND setup, use the coverage keywords above (`AND_Underwear`, `AND_ArmorBottom`, ...) — the Modesty set only works when AND is not installed (or if you re-enable the keyword conditions in the OAR in-game editor).

### Limits

There is no display cap — the pick-lists scroll, and even the full ~137-keyword AND set loads fine. Aim for roughly **40 registered keywords** anyway: every registered keyword lengthens the pick-lists and adds work to the keyword restore that runs on every game load.

## Common workflows

### "TAWoBA's armor already counts as Bikini but for this one outfit I want it not to"

- Open the page with that outfit equipped.
- Click the Bikini toggle OFF. The mod removes the keyword from the Armor record AND adds the item to its "off" persistence list, so it stays off across reloads.

### "My character covers herself in underwear and I don't want that"

- Register `AND_Underwear` (it's in the shipped keyword file — just **Load Keywords from File**).
- With the underwear equipped, use its **Add keyword...** menu to apply `AND_Underwear`, then re-equip the item so AND rescans.
- Still covering at high modesty ranks? Apply `AND_ArmorBottom` instead — the item then counts as a fully dressed bottom.

### "My follower's armor is missing from the list"

- Switch **Select target actor** to the follower — the page always operates on whichever actor is selected.
- The picker only includes the player, followers tracked via the SLA follower alias, the most recent puppet (NotificationKey crosshair pick), and the most-aroused NPC in the location. If your follower isn't appearing, press the NotificationKey while looking at them — they'll show up as a "Puppet" option.

For sharing your curation across saves and with other players, continue to [Export to KID File](kid-export.md).
