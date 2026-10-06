#define SHARP "shr"
#define BLUNT "blt"


/// Usage:
///   armour_penetration_sharp = 8 MM_RHA
///   armour_penetration_blunt = 25 MPA
///   armor.sharp = 12 MM_RHA
///   armor.blunt = 40 MPA
///   natural_sharp_armor = 3 MM_RHA

#define RHA *1
/// Sharp protection / penetration in millimetres of RHA (Rolled Homogeneous Armor)
#define MM_RHA RHA

/// Blunt protection / penetration in megapascals
#define MPA *1

/// Alias
#define MEGAPASCAL MPA



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
#define BODYPART_DENSITY_SHARP_DEFAULT (0.22 MM_RHA)
#define BODYPART_DENSITY_BLUNT_DEFAULT (0.72 MPA)


#define DODGE_BASE_CHANCE 5
#define DODGE_PER_DEFENDER_MELEE 2.5
#define DODGE_PER_ATTACKER_MELEE 2
#define DODGE_CHANCE_MIN 0
#define DODGE_CHANCE_MAX 60
#define DODGE_DEFAULT_ATTACKER_SKILL 3
#define DODGE_PROJECTILE_MULT 0.15
#define DODGE_THROWN_MULT 0.5



#define DEGREES *1
#define TILES *1
/// Converts a PERCENTS into a 0-1 probability fraction: (30 PERCENTS) == 0.3. Always wrap in parentheses inside expressions.
#define PERCENTS *0.01


/// Aim modes
#define RW_AIM_SNAP 1       // snap shot (default)
#define RW_AIM_AIMED 2      // aimed
#define RW_AIM_SUPPRESS 3   // suppressive

/// Fire modes
#define RW_FIRE_SINGLE 1
#define RW_FIRE_BURST 2
#define RW_FIRE_AUTO 3

/// Aim areas on the paper doll
#define RW_AREA_HEAD "rw_head"
#define RW_AREA_TORSO "rw_torso"
#define RW_AREA_LEGS "rw_legs"

/// Ranged skill level requirements (levels)
#define RW_REQ_SKILL_SUPPRESS 7
#define RW_REQ_SKILL_AIMED 10
#define RW_REQ_SKILL_LIMB 15

/// Projectile size classes
#define RW_SIZE_SMALL 1   // flies past if it was not the aimed target
#define RW_SIZE_LARGE 2   // always catches the projectile (walls, structures, big mobs)

/// Spread multipliers per aim mode (unitless, multiply the gun's base spread)
#define RW_SPREAD_MULT_AIMED 1
#define RW_SPREAD_MULT_SNAP 2.5
#define RW_SPREAD_MULT_SUPPRESS 8
/// Flat extra spread while suppressing - "completely inaccurate"
#define RW_SUPPRESS_FLAT_SPREAD (6 DEGREES)

/// Delay multipliers per aim mode (unitless, multiply the gun's base cooldown)
#define RW_DELAY_MULT_AIMED 2.2
#define RW_DELAY_MULT_SNAP 1
#define RW_DELAY_MULT_SUPPRESS 0.1

/// Pause between shots (world.time ds) after which the "shots in a row" counter resets
#define RW_SHOT_STREAK_RESET (1.5 SECONDS)

/// Manipulation capacity (0-1) below which the user cannot hold the gun at all
#define RW_MIN_MANIPULATION 0.1


/// Miss chance of a level 0 shooter at point-blank-ish range
#define RW_MISS_UNSKILLED (35 PERCENTS)
/// Miss chance removed per ranged skill level
#define RW_MISS_PER_SKILL_LEVEL (1.4 PERCENTS)
/// Best possible base miss chance
#define RW_MISS_MIN (3 PERCENTS)
/// Extra miss chance when suppressing
#define RW_MISS_SUPPRESS_BONUS (55 PERCENTS)
/// Extra miss chance at 0 manipulation (scaled by lost manipulation)
#define RW_MISS_MANIP_FACTOR (40 PERCENTS)
/// Extra miss chance when fully "in motion"
#define RW_MISS_MOVING_FACTOR (25 PERCENTS)
/// Extra miss chance reached exactly at effective range (grows with the square of distance)
#define RW_MISS_RANGE_FALLOFF (25 PERCENTS)
/// Miss chance right past effective range
#define RW_MISS_BEYOND_RANGE_MIN (85 PERCENTS)
/// Miss chance at twice the effective range and beyond
#define RW_MISS_BEYOND_RANGE_MAX (97 PERCENTS)
/// Miss chance multiplier at point-blank (<= 1 tile)
#define RW_MISS_POINT_BLANK_MULT 0.25
#define RW_MISS_SUPPRESS_POINT_BLANK_MULT 0.85

/// Movespeed slowdown applied after each shot (decays)
#define RW_FIRE_SLOWDOWN 0.35
/// How long the fire slowdown lasts (ds)
#define RW_FIRE_SLOWDOWN_DURATION (1.2 SECONDS)
/// Max stacks of fire slowdown
#define RW_FIRE_SLOWDOWN_MAX 3

#define RW_COOLDOWN_FLOOR (0.35 SECONDS)
#define RW_POST_BURST_MULT 1.35

/// Base time to eject / insert magazine (ds), scaled by skill + manip
#define RW_MAG_SWAP_TIME (1.5 SECONDS)
/// Skill level required for tactical reload (click mag on loaded gun / gun on mag)
#define RW_REQ_SKILL_TACTICAL_RELOAD 10

#define MOVESPEED_ID_RW_FIRE_RECOIL "rw_fire_recoil"

#define ui_rw_ammo "EAST-0.5:-32,CENTER-4:5"
#define ui_rw_aim_button "EAST-4:12,CENTER-4:-10"
#define ui_rw_fire_button "EAST-4:-32,CENTER-4:-10"

#define RW_ATT_SLOT_MUZZLE "muzzle"
#define RW_ATT_SLOT_RAIL "rail"
#define RW_ATT_SLOT_UNDER "under"
#define RW_ATT_SLOT_STOCK "stock"

// attach_flags
#define RW_ATT_REMOVABLE (1<<0)
#define RW_ATT_ACTIVATION (1<<1)

#define RW_ATT_BASE_TIME (1.5 SECONDS)
#define RW_ATT_MIN_EFFECT 0.25
#define RW_ATT_UNHELD_SKILL 99


#define RW_ICON_ATT_MUZZLE 'fenysha_events/icons/items/gun/attachments/muzzle.dmi'
#define RW_ICON_ATT_RAIL 'fenysha_events/icons/items/gun/attachments/rail.dmi'
#define RW_ICON_ATT_UNDER 'fenysha_events/icons/items/gun/attachments/underbarrel.dmi'
#define RW_ICON_ATT_STOCK 'fenysha_events/icons/items/gun/attachments/stock.dmi'
#define RW_ICON_ATT_SCOPE 'fenysha_events/icons/items/gun/attachments/scope.dmi'

#define RW_ICON_ATT_STOCK64 'fenysha_events/icons/items/gun/attachments/stock_64.dmi'
#define RW_ICON_ATT_SCOPE64 'fenysha_events/icons/items/gun/attachments/scope_64.dmi'

#define RW_ICON_MUZZLE_FLASH 'fenysha_events/icons/items/projectiles.dmi'



GLOBAL_LIST_INIT(rw_attachment_slots, list(
	RW_ATT_SLOT_STOCK,
	RW_ATT_SLOT_UNDER,
	RW_ATT_SLOT_RAIL,
	RW_ATT_SLOT_MUZZLE,
))


/proc/rw_signed_pct(value)
	return "[value > 0 ? "+" : ""][round(value * 100)]%"


/proc/rw_signed_num(value, accuracy = 0.1)
	return "[value > 0 ? "+" : ""][round(value, accuracy)]"


#define RW_CALIBER_303BRITISH 	".303 British"
#define RW_CALIBER_9MM      	"9x19mm"
#define RW_CALIBER_45ACP    	".45 ACP"
#define RW_CALIBER_556      	"5.56x45mm"
#define RW_CALIBER_762      	"7.62x39mm"
#define RW_CALIBER_12G      	"12 gauge"
#define RW_CALIBER_308      	".308 Win"
