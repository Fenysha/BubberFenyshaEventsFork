// 12 gauge

/obj/projectile/rimworld/shotgun_slug
	name = "12 gauge slug"
	damage = 55
	speed = 1.0
	rw_caliber = RW_CALIBER_12G
	rw_ammo_class = "Slug"
	rw_ap_sharp = 10 MM_RHA
	rw_ap_blunt = 55 MPA
	rw_soft_damage_mult = 1.2
	rw_effective_range = 8 TILES

/obj/projectile/rimworld/shotgun_slug/ap
	name = "12 gauge AP slug"
	damage = 40
	rw_ammo_class = "AP Slug"
	rw_ap_sharp = 20 MM_RHA
	rw_ap_blunt = 32 MPA
	rw_soft_damage_mult = 0.9

/obj/projectile/rimworld/shotgun_slug/hv
	name = "12 gauge HV slug"
	damage = 50
	speed = 1.25
	rw_ammo_class = "HV Slug"
	rw_ap_sharp = 13 MM_RHA
	rw_ap_blunt = 48 MPA
	rw_effective_range = 11 TILES

/obj/projectile/rimworld/shotgun_slug/hp
	name = "12 gauge hollow-point slug"
	damage = 72
	rw_ammo_class = "HP Slug"
	rw_ap_sharp = 4 MM_RHA
	rw_ap_blunt = 70 MPA
	rw_soft_damage_mult = 1.6

/obj/projectile/rimworld/shotgun_slug/incendiary
	name = "12 gauge dragon's breath"
	damage = 28
	rw_ammo_class = "Incendiary"
	rw_ap_sharp = 3 MM_RHA
	rw_ap_blunt = 25 MPA
	rw_fire_stacks = 6

/obj/projectile/rimworld/shotgun_slug/he
	name = "12 gauge HE slug"
	damage = 30
	rw_ammo_class = "HE"
	rw_ap_sharp = 6 MM_RHA
	rw_ap_blunt = 28 MPA
	rw_he_radius = 1
	rw_he_heavy = 1
	rw_he_light = 2
	rw_he_flash = 3
