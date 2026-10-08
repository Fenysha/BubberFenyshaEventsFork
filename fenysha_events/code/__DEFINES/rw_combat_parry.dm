// === Parry ===
#define RW_PARRY_DURATION (1 SECONDS)
#define RW_PERFECT_PARRY_WINDOW (0.75 SECONDS)
#define RW_PARRY_COOLDOWN (4.5 SECONDS)
#define RW_PARRY_FAIL_STUN (0.6 SECONDS)
/// Fraction of an attack absorbed by a late, non-perfect parry.
#define RW_PARRY_PARTIAL_DAMAGE_REDUCTION 0.35
/// Distinguishes a partial parry from SUCCESSFUL_BLOCK (which completely cancels an attack).
#define RW_PARRY_PARTIAL_BLOCK 2

// === Traits ===
#define TRAIT_COMBAT_SLOWDOWN_RESISTANT "combat_slowdown_resistant"
#define TRAIT_COMBAT_SLOWDOWN_IMMUNE "combat_slowdown_immune"

// === Movespeed IDs ===
#define MOVESPEED_ID_RW_MELEE_RECOIL "rw_melee_recoil"
#define MOVESPEED_ID_RW_BLOCKING "rw_blocking"
#define MOVESPEED_ID_RW_MOVEMENT_CAPACITY "rw_movement_capacity"
