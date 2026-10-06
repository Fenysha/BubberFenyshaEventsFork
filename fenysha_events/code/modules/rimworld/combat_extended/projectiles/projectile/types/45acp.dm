// .45 ACP
// Heavy, slow pistol round with high blunt transfer.

/obj/projectile/rimworld/bullet_45
	name = ".45 ACP FMJ bullet"
	damage = 28
	speed = 4.5
	rw_caliber = RW_CALIBER_45ACP
	rw_ammo_class = "FMJ"
	rw_ap_sharp = 4 MM_RHA
	rw_ap_blunt = 30 MPA
	rw_soft_damage_mult = 1.1
	rw_effective_range = 8 TILES

/obj/projectile/rimworld/bullet_45/ap
	name = ".45 ACP AP bullet"
	damage = 20
	rw_ammo_class = "AP"
	rw_ap_sharp = 9 MM_RHA
	rw_ap_blunt = 18 MPA
	rw_soft_damage_mult = 0.9

/obj/projectile/rimworld/bullet_45/hv
	name = ".45 ACP HV bullet"
	damage = 26
	speed = 6
	rw_ammo_class = "HV"
	rw_ap_sharp = 6 MM_RHA
	rw_ap_blunt = 26 MPA
	rw_effective_range = 10 TILES

/obj/projectile/rimworld/bullet_45/hp
	name = ".45 ACP hollow-point bullet"
	damage = 38
	rw_ammo_class = "HP"
	rw_ap_sharp = 1.5 MM_RHA
	rw_ap_blunt = 38 MPA
	rw_soft_damage_mult = 1.55

/obj/projectile/rimworld/bullet_45/incendiary
	name = ".45 ACP incendiary bullet"
	damage = 18
	rw_ammo_class = "Incendiary"
	rw_ap_sharp = 2.5 MM_RHA
	rw_ap_blunt = 20 MPA
	rw_fire_stacks = 3

/obj/projectile/rimworld/bullet_45/he
	name = ".45 ACP HE bullet"
	damage = 14
	rw_ammo_class = "HE"
	rw_ap_sharp = 2 MM_RHA
	rw_ap_blunt = 14 MPA
	rw_he_radius = 1
	rw_he_light = 1
	rw_he_flash = 2
