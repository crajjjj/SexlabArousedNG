# Armor Curation

The *Current Armor List* MCM page is the most player-facing feature of the mod. It lets you mark specific armor items with arousal-relevant keywords, on a per-piece basis. Once you've curated your outfits, you can make the curation permanent and shareable with [Export to KID file](kid-export.md).

## Layout

- **Select Actor** picker at the top — pick whose outfit you want to inspect (you, follower, puppet).
- **Equipped Items** column on the left shows their currently-worn pieces:
  - **Body armor** (slot 32) — toggles for **Naked, Bikini, Sexy, Slooty, Illegal, Respectable, Ragged, Counts as Clothing**.
  - **Shoes/boots** (slot 37) — **High Heels** toggle.
  - **Items in bikini slots** (44, 45, 48, 49, 52, 56, 58) — **Bikini** + **Counts as Clothing** toggle per item, plus your custom keyword toggles.

Toggle ON to apply the property to that Armor template (it's per-template, so every actor wearing the same Armor template inherits the toggle). Toggle OFF to remove it.

!!! tip "Toggle mode vs Slider mode"
    Each property is stored as a value from 0–100, not a simple on/off. **Slider Mode** (a toggle at the top of the page) lets you set those values precisely with sliders; with it off you get the simple controls, where toggling a property ON writes a representative value (51 for most, 75 for High Heels) and OFF writes 0. Any non-zero value is normally treated as "the property is present" — though some consumer mods threshold or scale on the exact number.

!!! info "The 8 toggles only show on body-slot armor"
    The full set of toggles appears for the **body slot (32)** armor you're wearing. Items in other slots (foot, bikini slots) show only the relevant subset.

## How toggles persist

- Each toggle writes to the SKSE cosave via PapyrusUtil's StorageUtil. The flag survives saves and quits.
- On every game reload, the mod re-applies the toggled keywords to their Armor records — so the curation comes back even after you exit and relaunch Skyrim.
- If an Armor record **already has** the keyword baked into its source ESP (e.g. TAWoBA armors that ship with `SLA_ArmorHalfNakedBikini` pre-applied), the toggle lights up automatically when you open the page, AND the mod silently records that match so it shows up in your [Export to KID file](kid-export.md) output.

## "Counts as Clothing" specifically

This one's not a keyword — it's a state flag. Marking an item "Counts as Clothing" tells the naked-detection logic to treat the wearer as clothed even if they're showing skin. Useful for body suits, tights, see-through items, etc., that you don't want triggering the "naked" state.

!!! warning "Counts as Clothing is not exported to KID"
    Because it's a metadata flag and not a real Keyword, there's nothing for KID to distribute — it lives only in your cosave. See [what gets exported](kid-export.md#what-gets-exported).

## Custom keywords

Beyond the 8 built-in keywords, you can register **any keyword** from any loaded ESP as a custom toggle.

### Adding a custom keyword

1. Find the keyword's **EditorID** — usually documented in the keyword-providing mod's description (e.g. `SLA_ArmorHalfNakedBondage`, `BHUNP_SkinTight`).
2. On the *Current Armor List* page, click **Register Custom Keyword**.
3. Type the EditorID exactly and confirm.
4. The keyword now appears as a toggle on every body-slot armor and every item in the bikini slots.

### Removing a custom keyword

Click **Remove Custom Keyword** and type the EditorID. It's removed from the registry; previously toggled items keep the keyword unless you toggle them off individually first.

### Limits

- Maximum ~18 custom keywords are visible on a bikini-slot item simultaneously (Papyrus has a 128-element array limit; we use `bikini_count × keyword_count` for the toggle grid). With 7 worn bikini-slot items you can show ~18 per item. The actual StorageUtil data is unlimited — only the on-screen toggles are capped.
- The EditorID must exactly match a keyword in your load order — if not, you get an error popup.

## Built-in arousal keywords cheat sheet

| Internal name | MCM toggle label | What it represents | Affects naked detection? |
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

## Common armor workflows

### "TAWoBA's armor already counts as Bikini but for this one outfit I want it not to"

- Open *Current Armor List* with that outfit equipped.
- Click the Bikini toggle OFF. The mod removes the keyword from the Armor record AND adds the item to its "off" persistence list, so it stays off across reloads.

### "My follower's armor is missing from the list"

- Switch the **Select Actor** picker to the follower. The Current Armor List always operates on whichever actor is selected.
- The picker only includes the player, followers tracked via the SLA follower alias, the most recent puppet (NotificationKey crosshair pick), and the most-aroused NPC in the location. If your follower isn't appearing, press the NotificationKey while looking at them — they'll show up as a "Puppet" option.

For sharing your curation across saves and with other players, continue to [Export to KID File](kid-export.md).
