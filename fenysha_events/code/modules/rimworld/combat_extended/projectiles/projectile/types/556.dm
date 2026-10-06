// 5.56x45mm NATO
// Intermediate rifle round with balanced penetration and range.

/obj/projectile/rimworld/bullet_556
	name = "5.56mm FMJ bullet"
	damage = 32
	speed = 5.1
	rw_caliber = RW_CALIBER_556
	rw_ammo_class = "FMJ"
	rw_ap_sharp = 12 MM_RHA
	rw_ap_blunt = 28 MPA
	rw_soft_damage_mult = 1
	rw_effective_range = 18 TILES

/obj/projectile/rimworld/bullet_556/ap
	name = "5.56mm AP bullet"
	damage = 24
	rw_ammo_class = "AP"
	rw_ap_sharp = 22 MM_RHA
	rw_ap_blunt = 18 MPA
	rw_soft_damage_mult = 0.8

/obj/projectile/rimworld/bullet_556/hv
	name = "5.56mm HV bullet"
	damage = 30
	speed = 7
	rw_ammo_class = "HV"
	rw_ap_sharp = 15 MM_RHA
	rw_ap_blunt = 26 MPA
	rw_effective_range = 22 TILES

/obj/projectile/rimworld/bullet_556/hp
	name = "5.56mm hollow-point bullet"
	damage = 44
	rw_ammo_class = "HP"
	rw_ap_sharp = 5 MM_RHA
	rw_ap_blunt = 36 MPA
	rw_soft_damage_mult = 1.4

/obj/projectile/rimworld/bullet_556/incendiary
	name = "5.56mm incendiary bullet"
	damage = 22
	rw_ammo_class = "Incendiary"
	rw_ap_sharp = 8 MM_RHA
	rw_ap_blunt = 20 MPA
	rw_fire_stacks = 3

/// Saboted dart: very high sharp penetration with reduced tissue damage.
/obj/projectile/rimworld/bullet_556/bops
	name = "5.56mm APFSDS dart"
	damage = 18
	speed = 4.5
	icon_state = "gaussweak"
	rw_ammo_class = "BOPS"
	rw_ap_sharp = 35 MM_RHA
	rw_ap_blunt = 10 MPA
	rw_soft_damage_mult = 0.6
	rw_effective_range = 24 TILES

/obj/projectile/rimworld/bullet_556/he
	name = "5.56mm HE bullet"
	damage = 16
	rw_ammo_class = "HE"
	rw_ap_sharp = 4 MM_RHA
	rw_ap_blunt = 14 MPA
	rw_he_radius = 1
	rw_he_heavy = 0
	rw_he_light = 1
	rw_he_flash = 2
