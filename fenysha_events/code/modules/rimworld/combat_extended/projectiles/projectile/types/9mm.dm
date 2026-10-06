// 9x19mm Parabellum
// Soft pistol round with modest penetration and strong short-range trauma.
/obj/projectile/rimworld/bullet_9mm
	name = "9mm FMJ bullet"
	damage = 22
	speed = 4
	rw_caliber = RW_CALIBER_9MM
	rw_ammo_class = "FMJ"
	rw_ap_sharp = 5 MM_RHA
	rw_ap_blunt = 22 MPA
	rw_soft_damage_mult = 1
	rw_effective_range = 10 TILES

/obj/projectile/rimworld/bullet_9mm/ap
	name = "9mm AP bullet"
	damage = 16
	rw_ammo_class = "AP"
	rw_ap_sharp = 11 MM_RHA
	rw_ap_blunt = 14 MPA
	rw_soft_damage_mult = 0.85

/obj/projectile/rimworld/bullet_9mm/hv
	name = "9mm HV bullet"
	damage = 20
	speed = 6
	rw_ammo_class = "HV"
	rw_ap_sharp = 7 MM_RHA
	rw_ap_blunt = 20 MPA
	rw_effective_range = 12 TILES

/obj/projectile/rimworld/bullet_9mm/hp
	name = "9mm hollow-point bullet"
	damage = 30
	rw_ammo_class = "HP"
	rw_ap_sharp = 2 MM_RHA
	rw_ap_blunt = 28 MPA
	rw_soft_damage_mult = 1.45

/obj/projectile/rimworld/bullet_9mm/incendiary
	name = "9mm incendiary bullet"
	damage = 14
	rw_ammo_class = "Incendiary"
	rw_ap_sharp = 3 MM_RHA
	rw_ap_blunt = 16 MPA
	rw_fire_stacks = 2

/obj/projectile/rimworld/bullet_9mm/he
	name = "9mm HE bullet"
	damage = 12
	rw_ammo_class = "HE"
	rw_ap_sharp = 2 MM_RHA
	rw_ap_blunt = 12 MPA
	rw_he_radius = 1
	rw_he_light = 1
	rw_he_flash = 1
