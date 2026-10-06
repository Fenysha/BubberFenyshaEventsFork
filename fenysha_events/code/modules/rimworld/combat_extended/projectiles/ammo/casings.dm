// MARK: Ammo casing
// Cartridge casings, one subtype per ammunition variant.
/obj/item/ammo_casing/rimworld
	name = "rimworld casing"
	desc = "A cartridge for a RimWorld-style firearm."
	projectile_type = /obj/projectile/rimworld
	/// Caliber tag — must match the gun and the magazine.
	var/rw_caliber = RW_CALIBER_9MM

// --- 9mm ---
/obj/item/ammo_casing/rimworld/c9mm
	name = "9x19mm FMJ casing"
	desc = "A 9x19mm full metal jacket cartridge."
	rw_caliber = RW_CALIBER_9MM
	projectile_type = /obj/projectile/rimworld/bullet_9mm

/obj/item/ammo_casing/rimworld/c9mm/ap
	name = "9x19mm AP casing"
	desc = "A 9x19mm armor-piercing cartridge."
	projectile_type = /obj/projectile/rimworld/bullet_9mm/ap

/obj/item/ammo_casing/rimworld/c9mm/hv
	name = "9x19mm HV casing"
	desc = "A 9x19mm high-velocity cartridge."
	projectile_type = /obj/projectile/rimworld/bullet_9mm/hv

/obj/item/ammo_casing/rimworld/c9mm/hp
	name = "9x19mm HP casing"
	desc = "A 9x19mm hollow-point cartridge."
	projectile_type = /obj/projectile/rimworld/bullet_9mm/hp

/obj/item/ammo_casing/rimworld/c9mm/incendiary
	name = "9x19mm incendiary casing"
	desc = "A 9x19mm incendiary cartridge."
	projectile_type = /obj/projectile/rimworld/bullet_9mm/incendiary

/obj/item/ammo_casing/rimworld/c9mm/he
	name = "9x19mm HE casing"
	desc = "A 9x19mm high-explosive cartridge."
	projectile_type = /obj/projectile/rimworld/bullet_9mm/he


// --- .45 ---
/obj/item/ammo_casing/rimworld/c45
	name = ".45 ACP FMJ casing"
	desc = "A .45 ACP full metal jacket cartridge."
	rw_caliber = RW_CALIBER_45ACP
	projectile_type = /obj/projectile/rimworld/bullet_45

/obj/item/ammo_casing/rimworld/c45/ap
	name = ".45 ACP AP casing"
	projectile_type = /obj/projectile/rimworld/bullet_45/ap

/obj/item/ammo_casing/rimworld/c45/hv
	name = ".45 ACP HV casing"
	projectile_type = /obj/projectile/rimworld/bullet_45/hv

/obj/item/ammo_casing/rimworld/c45/hp
	name = ".45 ACP HP casing"
	projectile_type = /obj/projectile/rimworld/bullet_45/hp

/obj/item/ammo_casing/rimworld/c45/incendiary
	name = ".45 ACP incendiary casing"
	projectile_type = /obj/projectile/rimworld/bullet_45/incendiary

/obj/item/ammo_casing/rimworld/c45/he
	name = ".45 ACP HE casing"
	projectile_type = /obj/projectile/rimworld/bullet_45/he


// --- 5.56 ---
/obj/item/ammo_casing/rimworld/a556
	name = "5.56x45mm FMJ casing"
	desc = "A 5.56x45mm full metal jacket cartridge."
	rw_caliber = RW_CALIBER_556
	projectile_type = /obj/projectile/rimworld/bullet_556

/obj/item/ammo_casing/rimworld/a556/ap
	name = "5.56x45mm AP casing"
	projectile_type = /obj/projectile/rimworld/bullet_556/ap

/obj/item/ammo_casing/rimworld/a556/hv
	name = "5.56x45mm HV casing"
	projectile_type = /obj/projectile/rimworld/bullet_556/hv

/obj/item/ammo_casing/rimworld/a556/hp
	name = "5.56x45mm HP casing"
	projectile_type = /obj/projectile/rimworld/bullet_556/hp

/obj/item/ammo_casing/rimworld/a556/incendiary
	name = "5.56x45mm incendiary casing"
	projectile_type = /obj/projectile/rimworld/bullet_556/incendiary

/obj/item/ammo_casing/rimworld/a556/bops
	name = "5.56x45mm APFSDS casing"
	desc = "A saboted armor-piercing fin-stabilized dart in 5.56 form factor."
	projectile_type = /obj/projectile/rimworld/bullet_556/bops

/obj/item/ammo_casing/rimworld/a556/he
	name = "5.56x45mm HE casing"
	projectile_type = /obj/projectile/rimworld/bullet_556/he


// --- .303 British ---
// Type path kept as brtish303 for compatibility with existing maps/spawns.
/obj/item/ammo_casing/rimworld/brtish303
	name = ".303 British FMJ casing"
	desc = "A .303 British full metal jacket cartridge."
	rw_caliber = RW_CALIBER_303BRITISH
	projectile_type = /obj/projectile/rimworld/bullet_303british

/obj/item/ammo_casing/rimworld/brtish303/ap
	name = ".303 British AP casing"
	projectile_type = /obj/projectile/rimworld/bullet_303british/ap

/obj/item/ammo_casing/rimworld/brtish303/hp
	name = ".303 British HP casing"
	projectile_type = /obj/projectile/rimworld/bullet_303british/hp


// --- 7.62 ---
/obj/item/ammo_casing/rimworld/a762
	name = "7.62x39mm FMJ casing"
	desc = "A 7.62x39mm full metal jacket cartridge."
	rw_caliber = RW_CALIBER_762
	projectile_type = /obj/projectile/rimworld/bullet_762

/obj/item/ammo_casing/rimworld/a762/ap
	name = "7.62x39mm AP casing"
	projectile_type = /obj/projectile/rimworld/bullet_762/ap

/obj/item/ammo_casing/rimworld/a762/hv
	name = "7.62x39mm HV casing"
	projectile_type = /obj/projectile/rimworld/bullet_762/hv

/obj/item/ammo_casing/rimworld/a762/hp
	name = "7.62x39mm HP casing"
	projectile_type = /obj/projectile/rimworld/bullet_762/hp

/obj/item/ammo_casing/rimworld/a762/incendiary
	name = "7.62x39mm incendiary casing"
	projectile_type = /obj/projectile/rimworld/bullet_762/incendiary

/obj/item/ammo_casing/rimworld/a762/bops
	name = "7.62x39mm APFSDS casing"
	desc = "A saboted armor-piercing fin-stabilized dart in 7.62 form factor."
	projectile_type = /obj/projectile/rimworld/bullet_762/bops

/obj/item/ammo_casing/rimworld/a762/he
	name = "7.62x39mm HE casing"
	projectile_type = /obj/projectile/rimworld/bullet_762/he


// --- 12 gauge ---
/obj/item/ammo_casing/rimworld/shotgun
	name = "12 gauge slug"
	desc = "A 12-gauge rifled slug."
	rw_caliber = RW_CALIBER_12G
	projectile_type = /obj/projectile/rimworld/shotgun_slug

/obj/item/ammo_casing/rimworld/shotgun/ap
	name = "12 gauge AP slug"
	projectile_type = /obj/projectile/rimworld/shotgun_slug/ap

/obj/item/ammo_casing/rimworld/shotgun/hv
	name = "12 gauge HV slug"
	projectile_type = /obj/projectile/rimworld/shotgun_slug/hv

/obj/item/ammo_casing/rimworld/shotgun/hp
	name = "12 gauge HP slug"
	projectile_type = /obj/projectile/rimworld/shotgun_slug/hp

/obj/item/ammo_casing/rimworld/shotgun/incendiary
	name = "12 gauge dragon's breath"
	projectile_type = /obj/projectile/rimworld/shotgun_slug/incendiary

/obj/item/ammo_casing/rimworld/shotgun/he
	name = "12 gauge HE slug"
	projectile_type = /obj/projectile/rimworld/shotgun_slug/he
