// armored_flags
#define ARMORED_HAS_PRIMARY_WEAPON (1<<0)
#define ARMORED_HAS_SECONDARY_WEAPON (1<<1)
#define ARMORED_HAS_UNDERLAY (1<<2)
#define ARMORED_HAS_HEADLIGHTS (1<<3)
#define ARMORED_WRECKABLE (1<<4)
#define ARMORED_IS_WRECK (1<<5)
#define ARMORED_SELF_WALL_DAMAGE (1<<6)

// facing_modifiers keys
#define VEHICLE_FRONT_ARMOUR "front"
#define VEHICLE_SIDE_ARMOUR "side"
#define VEHICLE_BACK_ARMOUR "back"

// armored_weapon_flags
#define MODULE_PRIMARY (1<<0)
#define MODULE_SECONDARY (1<<1)
#define MODULE_FIXED_FIRE_ARC (1<<2)

#define ARMORED_FIRE_SEMIAUTO 0
#define ARMORED_FIRE_BURST 1
#define ARMORED_FIRE_AUTOMATIC 2

/// Width in degrees of the arc a fixed-arc weapon can fire into, centred on the turret
#define ARMORED_FIRE_CONE_ALLOWED 110

#define COOLDOWN_TANK_SWIVEL "tank_swivel"
#define COOLDOWN_VEHICLE_CRUSHSOUND "vehicle_crushsound"
#define COOLDOWN_ARMORED_WEAPON(weapon_type) "armored_weapon_[weapon_type]"

#define TRAIT_HAS_INTERIOR "has_interior"
