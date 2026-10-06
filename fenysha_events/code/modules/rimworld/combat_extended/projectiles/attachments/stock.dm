/obj/item/rw_attachment/stock
	icon = RW_ICON_ATT_STOCK
	slot = RW_ATT_SLOT_STOCK
	pixel_shift_x = 30
	pixel_shift_y = 14
	size_mod = 1

/obj/item/rw_attachment/stock/standard
	name = "shoulder stock"
	desc = "A rigid stock. Steadier aim and less kick, but takes a little longer to shoulder."
	icon_state = "generic"
	spread_mod = -0.4 DEGREES
	recoil_spread_mod = -0.2
	camera_recoil_mod = -1
	wield_time_mod = 0.2

/obj/item/rw_attachment/stock/british_rifle
	name = "Wooden stock"
	icon_state = "garand_a"

	spread_mod = -0.4 DEGREES
	recoil_spread_mod = -0.2
	camera_recoil_mod = -1
	wield_time_mod = 0.2

/// Integral stock: part of the weapon rather than a removable attachment.
/obj/item/rw_attachment/stock/integral
	name = "integral stock"
	icon_state = "generic"
	attach_flags = NONE
	size_mod = 0

/// Foldable stock. Its modifiers are active only while deployed.
/obj/item/rw_attachment/stock/foldable
	name = "foldable stock"
	desc = "A wire stock that folds away. Unfold it from the Alt-click menu for steadier aim; fold it for a compact weapon."
	icon_state = "foldable"
	attach_flags = RW_ATT_REMOVABLE|RW_ATT_ACTIVATION
	size_mod = 0
	spread_mod = -0.5 DEGREES
	recoil_spread_mod = -0.25
	camera_recoil_mod = -1.2
	wield_time_mod = 0.1
	/// Time required to fold or unfold.
	var/deploy_time = 0.8 SECONDS
	var/folded = TRUE

/obj/item/rw_attachment/stock/foldable/accumulate_mods(obj/item/gun/rimworld/gun, skill)
	if(folded)
		return
	return ..()

/obj/item/rw_attachment/stock/foldable/get_overlay_state()
	. = ..()
	if(. && !folded)
		. = "[.]_open"

/obj/item/rw_attachment/stock/foldable/activate(mob/living/user)
	if(user && deploy_time && !do_after(user, deploy_time, master_gun))
		return FALSE
	folded = !folded
	playsound(src, 'sound/machines/click.ogg', 25, TRUE)
	master_gun?.rw_recalc_attachments(user)
	master_gun?.update_appearance()
	return TRUE
