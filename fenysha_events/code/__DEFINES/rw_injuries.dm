#define INJURY_SEVERITY_MINOR       1
#define INJURY_SEVERITY_MODERATE    2
#define INJURY_SEVERITY_SEVERE      3
#define INJURY_SEVERITY_CRITICAL    4
#define INJURY_SEVERITY_LOSS        5

#define INJURY_FLAG_EXTERNAL        (1<<0)
#define INJURY_FLAG_INTERNAL        (1<<1)
#define INJURY_FLAG_ACCEPTS_GAUZE   (1<<2)
#define INJURY_FLAG_ACCEPTS_SUTURE  (1<<3)
#define INJURY_FLAG_ACCEPTS_SPLINT  (1<<4)
#define INJURY_FLAG_BLEEDING        (1<<5)
#define INJURY_FLAG_PAINFUL         (1<<6)
#define INJURY_FLAG_DISABLING       (1<<7)
#define INJURY_FLAG_PROGRESSING     (1<<8)
#define INJURY_FLAG_SELF_HEALING    (1<<9)
#define INJURY_FLAG_TREATED         (1<<10)


#define INJURY_TYPE_LACERATION      "laceration"       // Cut
#define INJURY_TYPE_CONTUSION       "contusion"        // Bruise
#define INJURY_TYPE_DISLOCATION     "dislocation"      // Dislocation
#define INJURY_TYPE_SKIN_DAMAGE     "skin_damage"      // Skin damage
#define INJURY_TYPE_NERVE_DAMAGE    "nerve_damage"     // Nerve damage
#define INJURY_TYPE_ARTERIAL_BLEED  "arterial_bleed"   // Arterial bleeding
#define INJURY_TYPE_VENOUS_BLEED    "venous_bleed"     // Venous bleeding
#define INJURY_TYPE_BURN            "burn"             // Burn
#define INJURY_TYPE_FRACTURE        "fracture"         // Fracture
#define INJURY_TYPE_PUNCTURE        "puncture"         // Puncture wound
#define INJURY_TYPE_AVULSION        "avulsion"         // Soft tissue avulsion


#define PAIN_MAX                    200     // Absolute pain ceiling
#define PAIN_SHOCK_THRESHOLD        45      // Pain above this level starts increasing shock
#define PAIN_CRIT_THRESHOLD         90      // Severe pain that significantly impairs consciousness
#define PAIN_UNCONSCIOUS_THRESHOLD  140     // Pain level at which unconsciousness becomes likely

#define SHOCK_MAX                   100
#define SHOCK_MILD                  25
#define SHOCK_MODERATE              50
#define SHOCK_SEVERE                75
#define SHOCK_CRITICAL              90

#define CONSCIOUSNESS_MAX           100
#define CONSCIOUSNESS_IMPAIRED      70
#define CONSCIOUSNESS_HEAVY         40
#define CONSCIOUSNESS_CRITICAL      15


#define HEART_RATE_NORMAL 70

#define HEART_RATE_MAX_SURVIVABLE 240   // Above this, ventricular fibrillation or cardiac arrest may occur
#define HEART_RATE_MIN_SURVIVABLE 20    // Below this, asystole or cardiac arrest may occur

#define HEART_RATE_STROKE_LIMIT 150     // Above this, the chambers cannot fill properly and cardiac output decreases
#define HEART_RATE_DAMAGE_START 160     // Above this, the myocardium begins taking damage

#define HEART_RATE_SLEW 8               // Maximum heart rate change per second

#define HEART_CPR_OUTPUT 0.3            // Assumed cardiac output during effective CPR
#define HEART_CPR_DURATION (4 SECONDS)  // Duration of a single CPR compression


#define BP_NORMAL 100

#define BP_PERFUSION_MIN 45             // Below this, the brain receives insufficient blood flow
#define BP_PERFUSION_NONE 15            // Below this, effective perfusion is nearly absent

#define PERFUSION_SYNCOPE 0.45          // Below this perfusion level, syncope occurs


#define BRAIN_O2_MAX 100

#define BRAIN_O2_HYPOXIA 60             // Below this, consciousness begins to deteriorate
#define BRAIN_O2_SEVERE 30              // Below this, neuronal damage begins

#define BRAIN_O2_CONSUMPTION 1.0
#define BRAIN_O2_SUPPLY_MULT 2          // At 0.5 perfusion and 100% SpO2, oxygen supply equals consumption

#define BRAIN_O2_RATE 1.2
#define BRAIN_O2_RECOVERY_MULT 0.5      // Recovery is slower than oxygen depletion

#define BRAIN_HYPOXIA_DAMAGE_MAX 1.0    // Maximum brain damage per second at 0% brain oxygen


#define CONSCIOUSNESS_FALL_RATE  4		// How fast consciousness drops toward a worse target (points per second).
#define CONSCIOUSNESS_RISE_RATE   2		/// How fast it recovers when the target improves.


#define LUNG_FLUID_MAX 100
#define LUNG_FLUID_SEVERE 60

#define LUNG_FLUID_CHOKE_PER_BREATH 8   // Amount of fluid entering the lungs per breath while submerged
#define LUNG_FLUID_RESORB 0.15          // Fluid absorbed per second by healthy lungs

#define LUNG_GAS_EXCHANGE_UP 3          // SpO2 increase per second
#define LUNG_GAS_EXCHANGE_DOWN 6        // SpO2 decrease per second


#define CIRCULATION_TRAIT "circulation"


#define SHOCK_RECOVERY_RATE 14.0
#define ACUTE_PAIN_RECOVERY_RATE 12.0
#define CONSCIOUSNESS_STUN_RECOVERY_RATE 18.0

#define IMPACT_PAIN_THRESHOLD 2.0
#define IMPACT_PAIN_MULT 0.85

#define IMPACT_SHOCK_MULT 0.65

#define IMPACT_CONSCIOUSNESS_THRESHOLD 5.0
#define IMPACT_CONSCIOUSNESS_MULT 0.85

#define IMPACT_HEAD_MULT 2.25
#define IMPACT_CHEST_MULT 0.75
#define IMPACT_LIMB_MULT 0.45

#define INJURY_SHOCK_BASE 2.0
#define INJURY_SHOCK_PER_SEVERITY 2.5
#define INJURY_SHOCK_PAIN_FACTOR 0.10
#define INJURY_SHOCK_BLEED_FACTOR 0.35

#define INJURY_CONSCIOUSNESS_BASE 1.0
#define INJURY_CONSCIOUSNESS_PER_SEVERITY 1.5
#define INJURY_CONSCIOUSNESS_PAIN_FACTOR 0.035
#define INJURY_HEAD_CONSCIOUSNESS_MULT 2.0


#define INJURY_TREATMENT_NONE       0
#define INJURY_TREATMENT_POOR       1
#define INJURY_TREATMENT_ADEQUATE   2
#define INJURY_TREATMENT_EXCELLENT  3


#define INJURY_TREATMENT_EFFECTIVENESS_POOR 0.50
#define INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE 0.75
#define INJURY_TREATMENT_EFFECTIVENESS_NORMAL 1.0
#define INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT 1.25


// Visibility levels for injuries and medical data

#define INJURY_VISIBILITY_NONE          0   // Never shown
#define INJURY_VISIBILITY_SELF          1   // Only visible to the owner during self-examination
#define INJURY_VISIBILITY_MEDICAL       2   // Visible with a medical scanner or TRAIT_VIEW_FULL_HEALTH
#define INJURY_VISIBILITY_FULL          3   // Always visible during examination

// Traits

#define TRAIT_VIEW_FULL_HEALTH "always_full_healthpanel"
#define TRAIT_DISABLED_BY_INJURY "!disable_by_injury"


#define MAX_INJURIES_PER_LIMB 8
#define MAX_INJURY_DAMAGE_MULTIPLIER 2.5


/// Blood volume ratio at which visual blood-loss effects begin.
#define BLOOD_PALLOR_START 0.80

/// Blood volume ratio at which pallor reaches maximum.
#define BLOOD_PALLOR_FULL 0.35

/// Priority above normal bodypart color overrides.
#define BLOOD_PALLOR_COLOR_PRIORITY 60

/// Blood-loss screen grading begins here.
#define BLOOD_COLORGRADE_START 0.80

/// Maximum screen grading is reached here.
#define BLOOD_COLORGRADE_FULL 0.35


#define INJURY_MESSAGE_COOLDOWN (6 SECONDS)
#define INJURY_SOUND_BONE_CRACK pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg')
#define INJURY_SOUND_BLOOD pick('sound/effects/wounds/blood1.ogg', 'sound/effects/wounds/blood2.ogg', 'sound/effects/wounds/blood3.ogg')
#define INJURY_SOUND_PIERCE pick('sound/effects/wounds/pierce1.ogg', 'sound/effects/wounds/pierce2.ogg', 'sound/effects/wounds/pierce3.ogg')
#define INJURY_SOUND_SIZZLE pick('sound/effects/wounds/sizzle1.ogg', 'sound/effects/wounds/sizzle2.ogg')
