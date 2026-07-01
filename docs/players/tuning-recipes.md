# Tuning Recipes

Default values are tuned so a fully-clothed character idling in town hits maybe 30–40 over a day. If you want a different curve, the Default plugin's MCM pages have every knob you need. This page collects the most common tuning goals and the exact sliders to reach for. For what each effect category means, see [How Arousal Works](how-arousal-works.md).

## Make my arousal climb faster

Pick the sources you want to lean on.

!!! warning "Coming from OSL Aroused?"
    OSL's "arousal slowly ticks up over time" maps onto SLA NG's **Timed Arousal** effect — *not* the Naked one. Naked here is event-based (you must *see* someone naked in LOS), so turning up its sliders won't do anything when no naked NPCs are around. If you want passive-tick behavior, raise *Timed Rate* and *Maximum Timed arousal* below.

### Faster nudity gains (Naked Effect category)

- **Naked increase per actor** (default `25`/hour) — direct multiplier on how fast `Naked Exposure` climbs while a naked NPC is in view. Bump to `50–100` for a much steeper ramp. Preferred-gender actors count twice; non-preferred count once.
- **Maximum Naked** (default `50`) — hard cap. The effect *will not exceed this number* regardless of rate. If you want nudity alone to push you to high arousal, raise this to `80–100`.
- **Maximum Naked (Non-Preferred)** (default `15`) — same cap for non-preferred-gender exposure. Raise if you want the "wrong" gender to also contribute meaningfully.
- **Naked Half-Time** (default `1` hour) — decay speed once nudity is no longer in view. Raise to `4–8` hours if you want exposure to linger after the naked NPC walks away.
- **Use LOS** (General page, default ON) — turn OFF if you want every nearby naked actor to count whether or not the player can see them.
- **Naked Only** (General page, "Require naked actors to change arousal") — leave OFF (the default). When ON it's a performance switch that skips *all* arousal updates unless a naked actor is nearby, which suppresses passive gains.

### Faster passive buildup (Timed Effect category) — the OSL analogue

This is the "I haven't had sex in a while" rising effect. Fires on every tracked actor regardless of nudity.

- **Timed Rate** (default `12.5`/day) — base rate. Raise to `25–50` for a clearly noticeable hourly climb. Capped by *Maximum Timed arousal*.
- **Maximum Timed arousal** (default `60`) — cap. Raise to `100` if you want the timed effect alone to push the value to its maximum.
- **Use timed cycle** (default ON) — modulates the timed rate with a per-actor daily sine wave (so the actor has higher- and lower-arousal phases across a day). Turn OFF if you want a flat, predictable rise — useful if you found the cycle made gains feel inconsistent.

### Faster sleep gains (Sleep Effect category)

- **Sleep Minimum** / **Sleep Maximum** (default `5` / `15`) — random range added at wake-up. Raise to `15` / `30` for a stronger morning bump.
- **Sleep Min Time** (default `3` hours) — minimum in-game hours of sleep required to trigger *any* sleep arousal. **Catnaps under this threshold add nothing** — most common cause of "sleep doesn't work". Drop to `1` if you want short rests to count.
- **Sleep Half-Time** (default `5` hours) — how fast the post-sleep bump decays. Raise to keep morning arousal lingering longer into the day.

### Stronger orgasm reset (Satisfaction Effect category)

If post-orgasm cooldown is too long and is masking other gains:

- **Base Satisfaction** (default `50`) — the flat post-orgasm penalty. Lower to `20–30` so you bounce back faster.
- **Satisfaction Half-Time** (default `1` hour) — how fast the penalty decays. Lower to `0.25` (15 min) for a near-instant rebound.
- **Satisfaction Rate** / **Satisfaction Female Rate** — multipliers; lower if female PCs feel stuck post-orgasm.

### Legacy / API-driven boosts (Legacy Effect category)

If other mods in your load order push arousal via the old `ModExposure` API (SLEN, SL Survival, etc.) and you want their boosts amplified or longer-lasting:

- **Legacy Exposure Rate** (default `1.0×`) — multiplier on every Legacy ModExposure call. Raise to `2.0–3.0×` to double/triple SLEN's per-event bumps.
- **Legacy Exposure Half-Time** (default `1` hour) — decay. Raise to keep Legacy boosts lingering.

## Quick recipe: "rises noticeably over an in-game day with no setup"

If you just want the OSL-style passive-rise behavior without micromanaging the rest:

1. **Default plugin → Timed Effect:** *Timed Rate* `30/day`, *Maximum Timed arousal* `100`, *Use timed cycle* OFF.
2. **Default plugin → Sleep Effect:** *Sleep Min Time* `1` hour, *Sleep Minimum* `10`, *Sleep Maximum* `25`.
3. **Default plugin → Satisfaction:** *Satisfaction Half-Time* `0.5` hours so post-orgasm penalty fades fast.
4. **General page:** *Naked Only* OFF (so updates run even with no naked actor around), and optionally *Use LOS* OFF (makes nudity easier to trigger).

You should see ~1–2 arousal/hour even fully clothed and alone, climbing to ~100 after a day or two without orgasm, with bumps from nudity / sleep / sex on top.

## Coming from OSL Aroused

OSL ticks arousal up just because time passed. SLA NG's Default plugin only ticks passively via the **Timed Arousal** effect (which is off-feeling by default — low rate, modulated by a daily cycle). Everything else (Naked, Sleep, Sex) is event-driven and requires the trigger to actually fire. If you don't see climbs:

- Open **Puppet Master** on yourself and look at the effect list. If *Timed Arousal* shows `0.0` with no function, the periodic update isn't running for you — toggle *Disabled* off and on in General.
- Naked exposure requires (a) a tracked NPC nearby (b) flagged into the naked faction by the detection scan (c) in LOS if *Use LOS* is on (d) a "full update" tick — these happen every ~2 minutes by default, and only every Nth tick is a full LOS pass. Don't expect instant feedback.
- Apply the *Quick recipe* above to get OSL-like passive behavior.

## Back up or reset

### "I want to back up my settings (sliders, toggles, plugin options) — not the armor flags"

- Go to **General Settings** → **Export Settings**. Writes `SLAX/Settings.json` via PapyrusUtil's JsonUtil.
- Restore via **Import Settings**.

### "I want to nuke everything and start over"

- **Clear selected actor** on General page wipes data for the currently-selected actor.
- **Clear all data** wipes the entire mod's persistent state.
