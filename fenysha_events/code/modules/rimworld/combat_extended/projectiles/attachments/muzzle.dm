/obj/item/rw_attachment/muzzle
	icon = RW_ICON_ATT_MUZZLE
	slot = RW_ATT_SLOT_MUZZLE

/obj/item/rw_attachment/muzzle/suppressor
	name = "suppressor"
	desc = "A small tube with exhaust ports to expel noise and gas. Does not make the weapon silent, but it is much quieter, more stable and hides the muzzle flash, at the cost of bullet speed and reach."
	icon_state = "suppressor"
	pixel_shift_y = 16
	silencer = TRUE
	spread_mod = -0.2 DEGREES
	camera_recoil_mod = -1
	speed_mod = -0.1
	range_mod = -0.1
	miss_mod = -0.02

/obj/item/rw_attachment/muzzle/suppressor/integral
	name = "integral suppressor"
	attach_flags = NONE

/obj/item/rw_attachment/muzzle/compensator
	name = "recoil compensator"
	desc = "A muzzle device that diverts expelled gas upwards. Greatly reduces recoil build-up and weapon kick."
	icon_state = "comp"
	pixel_shift_x = 17
	recoil_spread_mod = -0.35
	camera_recoil_mod = -1.5
	spread_mod = -0.1 DEGREES

/obj/item/rw_attachment/muzzle/extended_barrel
	name = "extended barrel"
	desc = "A lengthened barrel for tighter grouping and higher muzzle velocity."
	icon_state = "ebarrel"
	speed_mod = 0.15
	range_mod = 0.15
	spread_mod = -0.4 DEGREES
	miss_mod = -0.03
	size_mod = 1

/obj/item/rw_attachment/muzzle/heavy_barrel
	name = "barrel charger"
	desc = "A barrel extender with a small shaped charge that propels the bullet much faster. Great reach and punch, slightly less steady."
	icon_state = "hbarrel"
	speed_mod = 0.35
	range_mod = 0.25
	damage_mod = 0.05
	miss_mod = 0.03

/obj/item/rw_attachment/muzzle/bayonet
	name = "bayonet"
	desc = "A sharp blade that mounts under the muzzle. Makes the gun a decent spear, and the front a little heavier."
	icon_state = "bayonetknife"
	attach_delay = 1 SECONDS
	detach_delay = 1 SECONDS
	pixel_shift_x = 14
	pixel_shift_y = 18
	melee_mod = 20
	miss_mod = 0.02
	size_mod = 1
