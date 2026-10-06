/obj/item/ammo_box/magazine/rimworld
	name = "rimworld magazine"
	desc = "A detachable magazine for a firearm."
	abstract_type = /obj/item/ammo_box/magazine/rimworld
	multiple_sprites = AMMO_BOX_FULL_EMPTY
	/// Caliber tag — must match the gun.
	var/rw_caliber = RW_CALIBER_9MM

// MARK: 303british stock

/obj/item/ammo_box/magazine/rimworld/british_303
	name = ".303 british bullet stock (FMJ)"
	rw_caliber = RW_CALIBER_303BRITISH
	icon = 'fenysha_events/icons/items/ammo/rifle.dmi'
	icon_state = "clip-full"
	base_icon_state = "clip-full"

	ammo_type = /obj/item/ammo_casing/rimworld/brtish303
	max_ammo = 4

/obj/item/ammo_box/magazine/rimworld/british_303/ap
	name = ".303 british bullet stock (AP)"
	ammo_type = /obj/item/ammo_casing/rimworld/brtish303/ap

/obj/item/ammo_box/magazine/rimworld/british_303/hp
	name = ".303 british bullet stock (HP)"
	ammo_type = /obj/item/ammo_casing/rimworld/brtish303/hp


/obj/item/ammo_box/magazine/rimworld/pistol_9mm/ap
	name = "9mm pistol magazine (AP)"
	ammo_type = /obj/item/ammo_casing/rimworld/c9mm/ap

/obj/item/ammo_box/magazine/rimworld/pistol_9mm/hp
	name = "9mm pistol magazine (HP)"
	ammo_type = /obj/item/ammo_casing/rimworld/c9mm/hp

/obj/item/ammo_box/magazine/rimworld/smg_9mm/ap
	name = "9mm SMG magazine (AP)"
	ammo_type = /obj/item/ammo_casing/rimworld/c9mm/ap

/obj/item/ammo_box/magazine/rimworld/rifle_556/ap
	name = "5.56 rifle magazine (AP)"
	ammo_type = /obj/item/ammo_casing/rimworld/a556/ap

/obj/item/ammo_box/magazine/rimworld/rifle_556/bops
	name = "5.56 rifle magazine (APFSDS)"
	ammo_type = /obj/item/ammo_casing/rimworld/a556/bops

/obj/item/ammo_box/magazine/rimworld/rifle_762/ap
	name = "7.62 rifle magazine (AP)"
	ammo_type = /obj/item/ammo_casing/rimworld/a762/ap

/obj/item/ammo_box/magazine/rimworld/rifle_762/bops
	name = "7.62 rifle magazine (APFSDS)"
	ammo_type = /obj/item/ammo_casing/rimworld/a762/bops
