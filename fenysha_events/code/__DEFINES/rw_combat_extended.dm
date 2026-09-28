#define SHARP "shr"
#define BLUNT "blt"

/// Sharp armor / AP units (mm RHA equivalent)
/// Blunt armor / AP units (MPa equivalent)
#define PENETRATION_MIN 0.01

/**
 * Remaining AP after one armor layer.
 */
#define PEN_REMAINING_AP(ap, armor) (max(0, (ap) - (armor)))

/**
 * Damage multiplier through a layer.
 */
#define PEN_DAMAGE_MULT(ap, armor) \
	((ap) <= PENETRATION_MIN ? 0 : clamp(PEN_REMAINING_AP(ap, armor) / (ap), 0, 1))

/**
 * Sharp fully deflected when armor exceeds AP.
 */
#define PEN_SHARP_DEFLECTED(ap, armor) ((armor) > (ap))

/**
 * Blunt damage from stopped sharp energy.
 */
#define PEN_BLUNT_DAMAGE_FROM_AP(blunt_ap) \
	((blunt_ap) <= 0 ? 0 : (blunt_ap * 10) ** (1 / 3))

/// Default humanoid tissue density per layer (sharp mm RHA / blunt MPa)
#define BODYPART_DENSITY_SHARP_DEFAULT 0.22
#define BODYPART_DENSITY_BLUNT_DEFAULT 0.72


#define DODGE_BASE_CHANCE 5
#define DODGE_PER_DEFENDER_MELEE 2.5
#define DODGE_PER_ATTACKER_MELEE 2
#define DODGE_CHANCE_MIN 0
#define DODGE_CHANCE_MAX 60
#define DODGE_DEFAULT_ATTACKER_SKILL 3
#define DODGE_PROJECTILE_MULT 0.15
#define DODGE_THROWN_MULT 0.5
