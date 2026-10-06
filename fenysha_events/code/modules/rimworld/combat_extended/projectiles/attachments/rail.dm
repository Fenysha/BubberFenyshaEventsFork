/obj/item/rw_attachment/rail
	icon = RW_ICON_ATT_RAIL
	slot = RW_ATT_SLOT_RAIL

/obj/item/rw_attachment/rail/reddot
	name = "red-dot sight"
	desc = "A red-dot sight for short to medium range. No zoom, but noticeably steadier aim and better limb accuracy on the move."
	icon_state = "reddot"
	miss_mod = -0.06
	zone_accuracy_mod = 5
	moving_spread_mod = -0.1

/obj/item/rw_attachment/rail/scope
	name = "rail scope"
	desc = "A rail-mounted zoom scope. Grip the weapon with both hands to look through it. Great reach and grouping, but slow to bring up and harsh on a shooter who moves. Needs trained eyes to use well."
	icon_state = "sniper"
	scope_zoom = 1.3
	req_skill = 6
	range_mod = 0.6
	spread_mod = -0.5 DEGREES
	miss_mod = -0.04
	zone_accuracy_mod = 6
	wield_time_mod = 0.4
	moving_spread_mod = 0.25

/obj/item/rw_attachment/rail/quickfire
	name = "quickfire adapter"
	desc = "An upgraded autoloading mechanism that cycles rounds faster. Costs accuracy and one round per burst."
	icon_state = "autoloader"
	cooldown_mod = -0.15
	burst_delay_mod = -0.15
	burst_size_mod = -1
	miss_mod = 0.04

/obj/item/rw_attachment/rail/flashlight
	name = "rail flashlight"
	desc = "A simple flashlight for mounting on a firearm. Use it from the Alt-click menu."
	icon_state = "flashlight"
	attach_flags = RW_ATT_REMOVABLE|RW_ATT_ACTIVATION
	gun_light_range = 6
	/// Whether the light is currently on.
	var/lit = FALSE

/obj/item/rw_attachment/rail/flashlight/accumulate_mods(obj/item/gun/rimworld/gun, skill)
	. = ..()
	if(lit)
		gun.rw_att_light_range = max(gun.rw_att_light_range, gun_light_range)

/obj/item/rw_attachment/rail/flashlight/get_overlay_state()
	. = ..()
	if(. && lit)
		. = "[.]_on"

/obj/item/rw_attachment/rail/flashlight/activate(mob/living/user)
	lit = !lit
	playsound(src, 'sound/machines/click.ogg', 25, TRUE)
	master_gun?.rw_recalc_attachments(user)
	master_gun?.update_appearance()
	return TRUE

/obj/item/rw_attachment/rail/flashlight/on_detach(obj/item/gun/rimworld/gun, mob/living/user)
	lit = FALSE // Ensure the gun cannot retain the light after removal.
