// 7.62x39mm
// Heavier intermediate round with stronger blunt transfer.

/obj/projectile/rimworld/bullet_762
	name = "7.62mm FMJ bullet"
	damage = 40
	speed = 5
	rw_caliber = RW_CALIBER_762
	rw_ammo_class = "FMJ"
	rw_ap_sharp = 14 MM_RHA
	rw_ap_blunt = 36 MPA
	rw_soft_damage_mult = 1.05
	rw_effective_range = 16 TILES

/obj/projectile/rimworld/bullet_762/ap
	name = "7.62mm AP bullet"
	damage = 30
	rw_ammo_class = "AP"
	rw_ap_sharp = 26 MM_RHA
	rw_ap_blunt = 22 MPA
	rw_soft_damage_mult = 0.85

/obj/projectile/rimworld/bullet_762/hv
	name = "7.62mm HV bullet"
	damage = 38
	speed = 7
	rw_ammo_class = "HV"
	rw_ap_sharp = 17 MM_RHA
	rw_ap_blunt = 32 MPA
	rw_effective_range = 20 TILES

/obj/projectile/rimworld/bullet_762/hp
	name = "7.62mm hollow-point bullet"
	damage = 54
	rw_ammo_class = "HP"
	rw_ap_sharp = 6 MM_RHA
	rw_ap_blunt = 48 MPA
	rw_soft_damage_mult = 1.5

/obj/projectile/rimworld/bullet_762/incendiary
	name = "7.62mm incendiary bullet"
	damage = 28
	rw_ammo_class = "Incendiary"
	rw_ap_sharp = 9 MM_RHA
	rw_ap_blunt = 24 MPA
	rw_fire_stacks = 4

/obj/projectile/rimworld/bullet_762/bops
	name = "7.62mm APFSDS dart"
	damage = 22
	speed = 10
	icon_state = "gaussweak"
	rw_ammo_class = "BOPS"
	rw_ap_sharp = 42 MM_RHA
	rw_ap_blunt = 12 MPA
	rw_soft_damage_mult = 0.55
	rw_effective_range = 22 TILES

/obj/projectile/rimworld/bullet_762/he
	name = "7.62mm HE bullet"
	damage = 20
	rw_ammo_class = "HE"
	rw_ap_sharp = 5 MM_RHA
	rw_ap_blunt = 16 MPA
	rw_he_radius = 1
	rw_he_heavy = 0
	rw_he_light = 2
	rw_he_flash = 2
