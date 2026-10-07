# Combat Extended Medical Rework — Health System

The old percentage-based soft/hard crit system has been removed. Incapacitation and loss of consciousness are determined by **consciousness**, **pain**, and **shock**.

---

## 1. General Architecture

The system is built around several independent but interconnected layers:

| Layer                            | What it represents                           | Where it lives                    |
| -------------------------------- | -------------------------------------------- | --------------------------------- |
| **Structural damage**            | Brute / Burn damage on a bodypart            | `bodypart.brute_dam` / `burn_dam` |
| **Injuries**                     | Specific medical conditions                  | `/datum/injury` on the bodypart   |
| **Pain / Shock / Consciousness** | The body's physiological response            | `/mob/living/carbon`              |
| **Circulation**                  | Blood pressure, blood volume, heart function | heart + blood system              |
| **Brain oxygenation**            | Oxygen available to brain tissue             | `/obj/item/organ/brain`           |
| **Capacities**                   | RimWorld-style functional capabilities       | getters on carbon                 |

The old `health` variable still combines brute/burn/oxy/tox damage for the HUD and death threshold, but it is **not** used for soft/hard crits anymore.

---

## 2. Penetration and Damage — Combat Extended Style

### 2.1. Damage Flow

```text
apply_damage() / projectile / melee
        ↓
apply_penetrating_damage()          ← entry point for BRUTE damage
        ↓
pen_packet_from_attack()             ← creates the damage packet
        ↓
run_armor_penetration()              ← clothing + natural bodypart armor
        ↓
BP.take_penetrating_hit()
        ├─ receive_damage()           ← structural damage + injury generation
        ├─ pen_apply_body_density()   ← tissue density reduces remaining AP
        └─ damage_organs_from_packet()← damages organs if AP remains
```

### 2.2. Armor and AP

- **Sharp armor / AP** is measured in mm RHA, following the Combat Extended approach.
- **Blunt armor / AP** is measured in MPa.
- If `sharp_armor > sharp_ap`, the attack fully deflects. Only blunt trauma from the stopped energy remains.
- Otherwise, damage is multiplied by `RemainingAP / AP`, while the stopped portion is converted into blunt damage.

Macros (see `rw_combat_extended.dm`):

```dm
PEN_REMAINING_AP(ap, armor)
PEN_DAMAGE_MULT(ap, armor)
PEN_SHARP_DEFLECTED(ap, armor)
PEN_BLUNT_DAMAGE_FROM_AP(blunt_ap)
```

### 2.3. Organ Damage on Full Penetration

After passing through the body's tissue density, any remaining AP can be transferred to internal organs.

- Preferred targets:
  - Brain for head hits
  - Heart / lungs for chest hits
- The damage multiplier depends on the remaining AP:
  - Base: ~0.55
  - High AP: up to 0.95–1.35
  - Head + brain: an additional ×1.6–×2.2
- Significant organ damage immediately generates additional shock and a consciousness impulse.

**Practical effect:** a shot to the head that penetrates the helmet and skull can destroy the brain within fractions of a second and immediately send the victim into severe shock or unconsciousness.

---

## 3. Injuries

### 3.1. Design Philosophy

Injuries are **medical conditions**, not just numbers.

They:

- Are attached to `/obj/item/bodypart`
- Have a **series**, allowing injuries of the same type to upgrade or absorb each other instead of simply stacking
- Generate pain, bleeding, damage multipliers, and limb impairment
- Can be treated with gauze, sutures, splints, and skill-based medicine
- Can either heal naturally or require treatment

### 3.2. Main Injury Types

| Type                            | Description                                    |
| ------------------------------- | ---------------------------------------------- |
| Laceration                      | Cuts caused by edged weapons                   |
| Puncture / Avulsion             | Puncture wounds / tissue tearing               |
| Contusion                       | Blunt-force trauma                             |
| Fracture / Compound             | Fractures                                      |
| Burn                            | Burns                                          |
| Arterial / Venous bleed         | Arterial / venous bleeding                     |
| Internal bleeding               | Internal hemorrhage                            |
| Pneumothorax / Hemothorax       | Collapsed lung / blood in the pleural cavity   |
| Cardiac trauma / Spleen rupture | Heart trauma / ruptured spleen                 |
| Concussion / Skull fracture     | Concussion / skull fracture                    |
| Nerve damage / Dislocation      | Nerve damage / dislocation                     |
| **Stump**                       | Remaining tissue after a limb has been severed |

### 3.3. Injury Generation

`try_generate_injuries()` is called after damage is dealt and evaluates:

1. **Accumulated physical ratio** = `brute_dam / max_damage`
2. **Kinetic impact energy** = `(brute + burn) / max_damage`

Heavy individual hits can therefore produce severe injuries even when the victim has only accumulated a moderate amount of total damage.

Thresholds depend on the affected zone — head, chest, or limbs — as well as the sharpness/type of the weapon.

### 3.4. Dismemberment and Stumps

When `dismember()` succeeds:

1. A `/datum/injury/stump` is applied to the chest, using a series such as `stump_l_arm`.
2. The stump causes heavy bleeding, extreme acute pain, and severe shock.
3. Injuries belonging to the severed limb are removed **while the owner is still valid**, after which pain and shock are forcibly recalculated.

This fixes the old issue where pain and shock could remain stuck at their previous values after an amputation.

### 3.5. Treatment

Injuries have:

- `treatment_quality` — None / Poor / Adequate / Excellent
- Treatment multipliers:
  - `treated_bleed_mult`
  - `treated_heal_mult`
  - `treated_pain_mult`
- `treatment_effectiveness`, determined by skill-based medicine
- `base_healing_rate` — `0` means the injury does not heal on its own

Once an injury has fully healed, it removes itself.

---

## 4. Pain, Shock, and Consciousness

### 4.1. Pain

```text
pain = clamp(
    (pain_base + pain_misc + acute_pain) * pain_mod,
    0,
    pain_limit
)
```

- **`pain_base`** — the sum of `current_pain` from all bodyparts and their injuries
- **`acute_pain`** — a temporary spike caused by fresh damage; it fades relatively quickly
- **`pain_misc`** — pain coming from non-injury sources through `adjust_pain`

Thresholds based on `PAIN_MAX = 200`:

| Threshold                     | Value | Effect                                      |
| ----------------------------- | ----: | ------------------------------------------- |
| `PAIN_BLUR_THRESHOLD`         |    40 | Blurred vision                              |
| `PAIN_SPOTS_THRESHOLD`        |   100 | Visual spots / floaters                     |
| `PAIN_SHOCK_THRESHOLD`        |   130 | Pain begins contributing to unconsciousness |
| `PAIN_SHOCK_PUSH_THRESHOLD`   |   150 | Pain actively increases shock               |
| `PAIN_CRIT_THRESHOLD`         |   150 | Severe loss of consciousness                |
| `PAIN_DROP_THRESHOLD`         |   140 | Further impairment                          |
| `PAIN_UNCONSCIOUS_THRESHOLD`  |   160 | Near-blackout state                         |
| `PAIN_FIBRILLATION_THRESHOLD` |   180 | Risk of ventricular fibrillation            |

### 4.2. Shock

```text
shock = clamp(
    shock_base * shock_mod,
    0,
    shock_limit
)
```

Sources of `shock_base` include:

- Injury impulses (`initial_shock`)
- Sudden heavy impacts (`apply_combat_impact_response`)
- Continuous buildup from severe pain (`PAIN_SHOCK_RATE`)
- **Hypovolemia** — shock cannot fall below a certain floor while blood volume remains critically low

Shock recovers at `SHOCK_RECOVERY_RATE` per second, modified by the relevant modifiers.

### 4.3. Consciousness

Consciousness is the system's **primary measure of functional capability**.

The target consciousness value is calculated in two layers:

1. **Physiological ceiling** (`get_physiological_consciousness_cap`)
   - Depends only on brain oxygenation and perfusion.
   - You cannot remain more conscious than your brain's current physiological condition allows.

2. **Soft losses** (`get_consciousness_soft_loss`)
   - Pain + shock.
   - Pain is accounted for exactly once.

`step_consciousness()` then smoothly moves the current value toward its target:

- Falling consciousness uses `CONSCIOUSNESS_FALL_RATE`
- Recovery uses `CONSCIOUSNESS_RISE_RATE`, which is intentionally slower

#### Blackout Hysteresis

- `consciousness ≤ CONSCIOUSNESS_BLACKOUT` (`8`) → `blackout = TRUE`
- Blackout ends only when `consciousness ≥ CONSCIOUSNESS_WAKE` (`20`)

This prevents rapid flickering between being conscious and unconscious.

#### Consciousness Effects

| Level                    | Value | State             |
| ------------------------ | ----: | ----------------- |
| `CONSCIOUSNESS_IMPAIRED` |    70 | Impaired          |
| `CONSCIOUSNESS_HEAVY`    |    40 | Severe impairment |
| `CONSCIOUSNESS_CRITICAL` |    15 | Critical          |
| `CONSCIOUSNESS_BLACKOUT` |     8 | Unconscious       |
| `CONSCIOUSNESS_WAKE`     |    20 | Wake-up threshold |

---

## 5. Circulation and Organs

### 5.1. Heart

The heart tracks:

- `rate` / `rate_target` — current and target heart rate
- `get_cardiac_output()` takes into account:
  - Contractility, including heart damage
  - Preload and blood volume through the Frank-Starling mechanism
  - Reduced filling efficiency at very high heart rates
- `fibrillating` → cardiac output is approximately zero
- CPR provides artificial cardiac output through `HEART_CPR_OUTPUT`

### 5.2. Blood Pressure and Perfusion

`blood_pressure` is updated from cardiac output and blood volume.

`get_brain_perfusion()` determines how much blood actually reaches the brain.

When perfusion falls to or below `PERFUSION_SYNCOPE`, the physiological consciousness ceiling drops to zero.

### 5.3. Brain and Oxygen

`/obj/item/organ/brain` contains:

- `oxygen` (`0…BRAIN_O2_MAX`) — oxygen currently available to brain tissue
- Oxygen supply is calculated as:

```text
supply = perfusion × SpO₂ × BRAIN_O2_SUPPLY_MULT
```

- When `oxygen < BRAIN_O2_SEVERE`, hypoxic neuronal damage begins.
- When `damage ≥ maxHealth`, cerebral hypoxia becomes fatal.

### 5.4. Lungs

The lungs track:

- `fluid` — fluid accumulated in the lungs, such as from drowning or pulmonary edema
- Lung fluid affects `blood_oxygenation` (SpO₂)
- High fluid levels reduce oxygenation, which in turn reduces oxygen available to the brain

---

## 6. Capacities — RimWorld-style Functional Capabilities

The following getters are available on `/mob/living/carbon`. They generally return values between `0.0` and `1.0`:

| Getter                         | What it measures                                    |
| ------------------------------ | --------------------------------------------------- |
| `get_consciousness_capacity()` | How conscious and mentally capable the character is |
| `get_pain_capacity()`          | `1 −` normalized pain                               |
| `get_shock_capacity()`         | `1 −` normalized shock                              |
| `get_blood_pumping()`          | Overall circulatory efficiency                      |
| `get_breathing_capacity()`     | Respiratory efficiency                              |
| `get_manipulation_capacity()`  | Ability to use the hands                            |
| `get_moving_capacity()`        | Ability to move                                     |
| `get_work_capacity()`          | Overall ability to perform work                     |
| `get_sight_capacity()`         | Vision capability, currently simplified             |
| `get_talking_capacity()`       | Speech capability, currently simplified             |

These values can be used by:

- Work and crafting speed calculations
- AI behavior
- Movement speed modifiers
- Medical UI
- Any other system that needs a RimWorld-style measure of functional capability

---

## 7. Per-Tick Life Cycle

The simplified order inside `Life()` / `process_medical_response()` is:

1. Process injuries (`injury.handle_process`)
2. Update blood pressure
3. Process blood loss (`handle_blood`)
4. Update injury effects (`update_injury_effects`), including `total_bleed_rate`
5. Process cerebral oxygenation (`process_cerebral_oxygenation`)
6. Process the overall medical response (`process_medical_response`):
   - Decay `acute_pain`
   - Recover / build up shock
   - Recalculate the medical state
   - Step consciousness toward its target
   - Apply pain effects such as blur and visual spots

Acute pain, impact shock, and new-injury impulses **do not advance time themselves**. They only modify the relevant values.

Only `Life()` advances the simulation.

---

## 8. Key Constants

See:

- `rw_injuries.dm` — pain, shock, consciousness, circulation, and thresholds
- `rw_combat_extended.dm` — armor, AP, tissue density, and dodge

Important default values:

```text
PAIN_MAX                 = 200
SHOCK_MAX                = 100
CONSCIOUSNESS_MAX        = 100
CONSCIOUSNESS_BLACKOUT   = 8
CONSCIOUSNESS_WAKE       = 20

SHOCK_BLOOD_START        = 0.80   // hypovolemic shock begins
SHOCK_BLOOD_FULL         = 0.35   // maximum hypovolemic shock floor

BODYPART_DENSITY_SHARP   = 0.22
BODYPART_DENSITY_BLUNT   = 0.72
```

---

## 9. Differences from Vanilla TG

| Vanilla TG                                                 | This System                                                                                              |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Soft/Hard crit based on % health                           | Incapacitation is determined by consciousness                                                            |
| Wounds represented mainly by numbers + wound datums        | Full `/datum/injury` system with series and treatment                                                    |
| Armor works primarily as percentage-based damage reduction | CE-style sharp/blunt AP using mm RHA / MPa                                                               |
| Pain is mostly absent                                      | Pain is a central mechanic with visual and physiological effects                                         |
| Simple bleeding                                            | Blood pressure + heart rate + vessel type + treatment                                                    |
| Death is primarily based on health                         | Death can result from cerebral hypoxia, cardiac arrest, exsanguination, and other physiological failures |

---
