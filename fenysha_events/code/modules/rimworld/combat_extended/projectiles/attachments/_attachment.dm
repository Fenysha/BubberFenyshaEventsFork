/// Base attachment for /obj/item/gun/rimworld.
/// The gun recalculates all attachment modifiers from scratch, so installation
/// order never changes the final result.
/obj/item/rw_attachment
	name = "gun attachment"
	desc = "A weapon attachment. You should never see this."
	icon = null
	icon_state = null
	w_class = WEIGHT_CLASS_SMALL
	force = 1

	/// One RW_ATT_SLOT_* value.
	var/slot
	var/pixel_shift_x = 0
	var/pixel_shift_y = 0
	/// RW_ATT_REMOVABLE / RW_ATT_ACTIVATION
	var/attach_flags = RW_ATT_REMOVABLE
	var/attach_delay = RW_ATT_BASE_TIME
	var/detach_delay = RW_ATT_BASE_TIME
	var/attach_sound = 'sound/machines/click.ogg'
	/// Shooting skill at which the attachment reaches full effectiveness.
	/// Lower skill scales numeric modifiers down to RW_ATT_MIN_EFFECT.
	var/req_skill = 0

	/// Flat spread adjustment in degrees.
	var/spread_mod = 0
	/// Recoil buildup multiplier delta.
	var/recoil_spread_mod = 0
	/// Moving spread multiplier delta.
	var/moving_spread_mod = 0
	/// Fire cooldown multiplier delta.
	var/cooldown_mod = 0
	/// Burst delay multiplier delta.
	var/burst_delay_mod = 0
	/// Flat burst-size adjustment.
	var/burst_size_mod = 0
	/// Two-handed grip time multiplier delta.
	var/wield_time_mod = 0
	/// Effective range multiplier delta.
	var/range_mod = 0
	/// Projectile damage multiplier delta.
	var/damage_mod = 0
	/// Projectile speed multiplier delta.
	var/speed_mod = 0
	/// Flat miss-chance adjustment.
	var/miss_mod = 0
	/// Flat zone-accuracy adjustment in percentage points.
	var/zone_accuracy_mod = 0
	/// Flat camera-recoil adjustment.
	var/camera_recoil_mod = 0
	/// Flat melee-force adjustment.
	var/melee_mod = 0
	/// Weapon weight-class adjustment.
	var/size_mod = 0
	/// Suppresses the muzzle flash and switches to the suppressed firing sound.
	var/silencer = FALSE
	/// Fire modes granted by the attachment.
	var/list/fire_modes_add
	/// Scope zoom range modifier.
	var/scope_zoom = 0
	/// Light radius provided while the attachment is active.
	var/gun_light_range = 0

	/// Weapon typepath -> overlay icon state.
	var/list/variants_by_gun_type

	/// Gun this attachment is currently mounted on.
	var/obj/item/gun/rimworld/master_gun


/obj/item/rw_attachment/Destroy()
	master_gun = null
	return ..()


/obj/item/rw_attachment/examine(mob/user)
	. = ..()
	. += span_notice("Fits the <b>[slot]</b> slot.")
	var/list/lines = get_modifier_lines()
	if(length(lines))
		. += span_notice("Modifiers: [english_list(lines)].")
	if(req_skill)
		. += span_notice("Works at full effect with Shooting [req_skill]+.")
	if(!(attach_flags & RW_ATT_REMOVABLE))
		. += span_warning("It is permanently fixed in place.")


/// Build human-readable modifier descriptions.
/obj/item/rw_attachment/proc/get_modifier_lines()
	. = list()
	if(spread_mod)
		. += "spread [rw_signed_num(spread_mod)]°"
	if(recoil_spread_mod)
		. += "recoil spread [rw_signed_pct(recoil_spread_mod)]"
	if(moving_spread_mod)
		. += "moving penalty [rw_signed_pct(moving_spread_mod)]"
	if(cooldown_mod)
		. += "fire delay [rw_signed_pct(cooldown_mod)]"
	if(burst_size_mod)
		. += "burst size [rw_signed_num(burst_size_mod, 1)]"
	if(burst_delay_mod)
		. += "burst delay [rw_signed_pct(burst_delay_mod)]"
	if(wield_time_mod)
		. += "grip time [rw_signed_pct(wield_time_mod)]"
	if(range_mod)
		. += "range [rw_signed_pct(range_mod)]"
	if(damage_mod)
		. += "damage [rw_signed_pct(damage_mod)]"
	if(speed_mod)
		. += "bullet speed [rw_signed_pct(speed_mod)]"
	if(miss_mod)
		. += "miss chance [rw_signed_pct(miss_mod)]"
	if(zone_accuracy_mod)
		. += "limb accuracy [rw_signed_num(zone_accuracy_mod, 1)]%"
	if(camera_recoil_mod)
		. += "kick [rw_signed_num(camera_recoil_mod)]"
	if(melee_mod)
		. += "melee [rw_signed_num(melee_mod, 1)]"
	if(size_mod)
		. += "bulk [rw_signed_num(size_mod, 1)]"
	if(silencer)
		. += "suppressed"
	if(scope_zoom)
		. += "magnified optics"
	if(gun_light_range)
		. += "illumination"


/// Return 0..1 effectiveness for the user's skill.
/obj/item/rw_attachment/proc/get_effectiveness(skill)
	if(req_skill <= 0)
		return 1
	return clamp(skill / req_skill, RW_ATT_MIN_EFFECT, 1)


/// Add this attachment's modifiers to the gun's aggregate values.
/obj/item/rw_attachment/proc/accumulate_mods(obj/item/gun/rimworld/gun, skill)
	var/eff = get_effectiveness(skill)
	gun.rw_att_spread += spread_mod * eff
	gun.rw_att_recoil_spread_mult *= max(0.05, 1 + recoil_spread_mod * eff)
	gun.rw_att_moving_spread_mult *= max(0.05, 1 + moving_spread_mod * eff)
	gun.rw_att_cooldown_mult *= max(0.05, 1 + cooldown_mod * eff)
	gun.rw_att_burst_delay_mult *= max(0.05, 1 + burst_delay_mod * eff)
	gun.rw_att_burst_add += burst_size_mod
	gun.rw_att_wield_mult *= max(0.05, 1 + wield_time_mod * eff)
	gun.rw_att_range_mult *= max(0.05, 1 + range_mod * eff)
	gun.rw_att_damage_mult *= max(0.05, 1 + damage_mod * eff)
	gun.rw_att_speed_mult *= max(0.05, 1 + speed_mod * eff)
	gun.rw_att_miss_add += miss_mod * eff
	gun.rw_att_zone_acc_add += zone_accuracy_mod * eff
	gun.rw_att_camera_recoil += camera_recoil_mod * eff
	gun.rw_att_melee += melee_mod
	gun.rw_att_size += size_mod
	if(silencer)
		gun.rw_att_silenced = TRUE
	if(length(fire_modes_add))
		LAZYOR(gun.rw_att_fire_modes, fire_modes_add)
	if(scope_zoom)
		gun.rw_att_scope_zoom = max(gun.rw_att_scope_zoom, scope_zoom)


/// Return a rejection reason, or null if the attachment can be installed.
/obj/item/rw_attachment/proc/can_attach_reason(obj/item/gun/rimworld/gun, mob/living/user)
	return null

/// Called after mounting, before the gun recalculates its modifiers.
/obj/item/rw_attachment/proc/on_attach(obj/item/gun/rimworld/gun, mob/living/user)
	return

/// Called before unmounting.
/obj/item/rw_attachment/proc/on_detach(obj/item/gun/rimworld/gun, mob/living/user)
	return

/// Activate the attachment. Return TRUE on success.
/obj/item/rw_attachment/proc/activate(mob/living/user)
	return FALSE


/// Return the overlay icon state, or null to draw nothing.
/obj/item/rw_attachment/proc/get_overlay_state()
	if(master_gun)
		for(var/gun_path in variants_by_gun_type)
			if(istype(master_gun, gun_path))
				return variants_by_gun_type[gun_path]
	return icon_state


/obj/item/rw_attachment/proc/build_gun_overlay(obj/item/gun/rimworld/gun)
	var/state = get_overlay_state()
	if(!state)
		return null
	var/mutable_appearance/overlay = mutable_appearance(icon, state)
	// Without a slot anchor, keep the attachment at its native position.
	var/anchor_x = gun.rw_attachable_offset?["[slot]_x"] ? gun.rw_attachable_offset?["[slot]_x"] : 0
	var/anchor_y = gun.rw_attachable_offset?["[slot]_y"] ? gun.rw_attachable_offset?["[slot]_y"] : 0

	overlay.pixel_x = (isnull(anchor_x) ? pixel_shift_x : anchor_x) - pixel_shift_x
	overlay.pixel_y = (isnull(anchor_y) ? pixel_shift_y : anchor_y) - pixel_shift_y
	return overlay
