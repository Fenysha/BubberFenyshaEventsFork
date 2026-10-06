// .303 british
/obj/projectile/rimworld/bullet_303british
	name = ".303 British FMJ bullet"
	damage = 20
	speed = 5
	rw_caliber = RW_CALIBER_303BRITISH
	rw_ammo_class = "FMJ"
	rw_ap_sharp = 6 MM_RHA
	rw_ap_blunt = 1 MPA
	rw_soft_damage_mult = 1.05
	rw_effective_range = 16 TILES


/obj/projectile/rimworld/bullet_303british/ap
	name = ".303 British AP bullet"
	damage = 18
	rw_ammo_class = "AP"
	rw_ap_sharp = 7.4 MM_RHA
	rw_ap_blunt = 0.74 MPA
	rw_soft_damage_mult = 0.75


/obj/projectile/rimworld/bullet_303british/hp
	name = ".303 British hollow-point bullet"
	damage = 26
	rw_ammo_class = "HP"
	rw_ap_sharp = 4.4 MM_RHA
	rw_ap_blunt = 0.44 MPA
	rw_soft_damage_mult = 1.5
