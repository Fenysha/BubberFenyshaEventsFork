/obj/item/gun/rimworld
	name = "rimworld gun"
	desc = "A firearm with a biometric lock."
	abstract_type = /obj/item/gun/rimworld
	parent_type = /obj/item/gun/ballistic

	// Biocode replaces the normal firing pin.
	pin = null
	pinless = TRUE

	/// Current aim mode: snap / aimed / suppress.
	var/rw_aim_mode = RW_AIM_SNAP
	/// Current fire mode: single / burst / auto.
	var/rw_fire_mode = RW_FIRE_SINGLE
	/// Which fire modes this gun type may select.
	var/list/rw_allowed_fire_modes = list(RW_FIRE_SINGLE, RW_FIRE_BURST)

	/// TRUE while the two_handed component reports the gun as wielded.
	var/rw_wielded = FALSE
	/// TRUE while the do_after for gripping is running (blocks re-entry).
	var/rw_wield_busy = FALSE
	/// Base time to bring the gun into a two-handed grip (scaled by skill/manip).
	var/rw_wield_time = 0.8 SECONDS

	/// Distance (tiles) at which range falloff starts to dominate miss chance.
	var/rw_effective_range = 12 TILES

	/// Intrinsic angular spread of this gun before skill/mode modifiers.
	var/rw_base_spread = 2 DEGREES
	/// Base inter-shot cooldown (single-fire) before skill/mode/manip scaling.
	var/rw_cooldown = 0.7 SECONDS
	/// Rounds fired in one burst.
	var/rw_burst_size_rw = 3
	/// Delay between individual shots inside a burst.
	var/rw_burst_delay = 0.15 SECONDS
	/// Rounds fired in one full-auto sequence.
	var/rw_auto_rounds = 8
	/// Delay between individual shots in full-auto.
	var/rw_auto_delay = 0.1 SECONDS
	/// Extra spread added per consecutive shot (recoil build-up).
	var/rw_recoil_spread = 0.8 DEGREES

	/// Peak extra spread while the shooter is still "moving" (decays over settle time).
	var/rw_moving_spread = 20 DEGREES
	/// How long the shooter must stand still before moving penalty fully disappears.
	var/rw_settle_time = 1.5 SECONDS
	/// world.time of the last movement of the current holder.
	var/rw_last_move = 0

	/// Earliest world.time the gun may fire again.
	var/rw_next_fire = 0
	/// Consecutive shots without a long pause (feeds recoil spread + miss).
	var/rw_shots_in_row = 0
	/// world.time of the most recent live shot.
	var/rw_last_shot = 0
	/// Transient bag of aim data copied onto the projectile for the current shot.
	var/list/rw_current_shot

	/// If FALSE, biocode is completely disabled for this gun type.
	var/rw_biocode_enabled = TRUE
	/// If TRUE, the gun auto-binds to the first living mind that equips it.
	var/rw_biocode_on_equip = FALSE
	/// Weakref to the mind the gun is locked to (null = unbound).
	var/datum/weakref/rw_biocode_mind
	/// Cached real_name of the biocoded owner (for examine / alerts).
	var/rw_biocode_name

	/// HUD component that draws ammo / aim / fire-mode buttons.
	var/datum/component/rw_gun_hud/rw_hud

/obj/item/gun/rimworld/Initialize(mapload)
	. = ..()
	rw_hud = AddComponent(/datum/component/rw_gun_hud)
	AddComponent(/datum/component/two_handed, \
		require_twohands = FALSE, \
		wield_callback = CALLBACK(src, PROC_REF(rw_on_wield)), \
		unwield_callback = CALLBACK(src, PROC_REF(rw_on_unwield)))
	rw_init_attachments()

/// Subtypes override to report current magazine / internal ammo count.
/obj/item/gun/rimworld/proc/rw_get_ammo_count()
	return 0

/// Subtypes override to report magazine capacity.
/obj/item/gun/rimworld/proc/rw_get_ammo_max()
	return 0

/// Returns the user's ranged skill.
/obj/item/gun/rimworld/proc/rw_ranged_skill(mob/living/user)
	if(!user)
		return 0
	return RW_GET_SKILL(user, RW_SKILL_RANGED)

/// Returns the user's manipulation capacity.
/obj/item/gun/rimworld/proc/rw_manipulation(mob/living/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		return C.get_manipulation_capacity()
	return 1

/obj/item/gun/rimworld/update_icon_state()
	inhand_icon_state = "[base_icon_state][rw_wielded ? "_w" : ""]"
	. = ..()

/// TRUE when the gun is gripped and not on cooldown / mid-burst.
/obj/item/gun/rimworld/proc/rw_can_fire_now()
	return rw_wielded && !firing_burst && world.time >= rw_next_fire

/// Ready for the next trigger pull (ignores wield state — used by overlay).
/obj/item/gun/rimworld/proc/rw_is_ready()
	return !firing_burst && world.time >= rw_next_fire

/obj/item/gun/rimworld/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!(slot & ITEM_SLOT_HANDS) || !isliving(user))
		rw_unwield(null, silent = TRUE)
		return
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(rw_on_user_moved), override = TRUE)
	rw_last_move = world.time
	if(rw_biocode_enabled && rw_biocode_on_equip && !rw_is_biocoded())
		rw_biocode_to(user)
	rw_sanitize_modes(user)
	rw_recalc_attachments(user)
	rw_refresh_hud()

/obj/item/gun/rimworld/dropped(mob/user, silent = FALSE)
	. = ..()
	rw_wield_busy = FALSE
	rw_unwield(user, silent = TRUE)
	if(user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)

/obj/item/gun/rimworld/proc/rw_on_user_moved(datum/source)
	SIGNAL_HANDLER
	rw_last_move = world.time

/obj/item/gun/rimworld/examine(mob/user)
	. = ..()
	if(rw_is_biocoded())
		. += span_notice("It is biocoded to <b>[rw_biocode_name]</b>. Right-click it in hand to re-code or clear.")
	else if(rw_biocode_enabled)
		. += span_notice("It is not biocoded. Right-click it in hand to bind it to yourself.")
	. += span_notice("Press <b>Z</b> to grip it with both hands. Effective range: <b>[rw_effective_range] tiles</b>.")
	. += span_notice("Aimed mode needs Shooting [RW_REQ_SKILL_AIMED]+, suppression needs [RW_REQ_SKILL_SUPPRESS]+, limb targeting needs [RW_REQ_SKILL_LIMB]+.")
	. += span_notice("Tactical reload (mag on loaded gun / gun on mag) needs Shooting [RW_REQ_SKILL_TACTICAL_RELOAD]+.")
	. += rw_attachment_examine_lines(user)
