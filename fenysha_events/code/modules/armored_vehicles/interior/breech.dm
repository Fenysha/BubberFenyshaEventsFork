/// Loads ammo into one of the vehicle's weapons from inside
/obj/structure/gun_breech
	name = "gun breech"
	desc = "Used for loading large caliber rounds into the main gun. Hit it with a shell to load, click it to unload."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	icon_state = "breech"
	resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	var/is_secondary = FALSE
	var/obj/vehicle/sealed/armored/owner

/obj/structure/gun_breech/Destroy()
	owner = null
	return ..()

/obj/structure/gun_breech/link_interior(datum/interior/link)
	if(!istype(link, /datum/interior/armored))
		CRASH("invalid interior [link.type] passed to [name]")
	var/datum/interior/armored/inside = link
	if(is_secondary)
		inside.secondary_breech = src
	else
		inside.breech = src
	owner = inside.container
	var/obj/item/armored_weapon/weapon = get_weapon()
	if(weapon)
		on_weapon_attach(weapon)

/obj/structure/gun_breech/proc/get_weapon()
	return is_secondary ? owner?.secondary_weapon : owner?.primary_weapon

/obj/structure/gun_breech/examine(mob/user)
	. = ..()
	var/obj/item/armored_weapon/weapon = get_weapon()
	if(!weapon)
		. += span_notice("Nothing is mounted to it.")
		return
	. += span_notice("It feeds \the [weapon], which is [weapon.ammo ? "loaded with \a [weapon.ammo] ([weapon.ammo.current_rounds] left)" : "empty"].")
	if(length(weapon.ammo_magazine))
		. += span_notice("[length(weapon.ammo_magazine)] more queued.")

/obj/structure/gun_breech/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	var/obj/item/armored_weapon/weapon = get_weapon()
	if(!weapon)
		balloon_alert(user, "no weapon!")
		return TRUE
	if(!weapon.ammo)
		balloon_alert(user, "breech empty!")
		return TRUE
	if(DOING_INTERACTION_WITH_TARGET(user, src) || !do_after(user, 1 SECONDS, src))
		return TRUE
	if(get_weapon() == weapon && weapon.ammo)
		do_unload(user, weapon)
	return TRUE

/obj/structure/gun_breech/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/tank_ammo))
		return NONE
	var/obj/item/tank_ammo/new_ammo = tool
	var/obj/item/armored_weapon/weapon = get_weapon()
	if(!reload_checks(user))
		return ITEM_INTERACT_BLOCKING
	if(!(new_ammo.type in weapon.accepted_ammo))
		balloon_alert(user, "wrong ammo!")
		return ITEM_INTERACT_BLOCKING
	if(DOING_INTERACTION_WITH_TARGET(user, src))
		return ITEM_INTERACT_BLOCKING
	if(new_ammo.loading_sound)
		playsound(src, new_ammo.loading_sound, 20)
	if(!do_after(user, weapon.rearm_time, src, extra_checks = CALLBACK(src, PROC_REF(reload_checks), user)))
		return ITEM_INTERACT_BLOCKING
	do_load(user, weapon, new_ammo)
	return ITEM_INTERACT_SUCCESS

/obj/structure/gun_breech/proc/do_load(mob/living/user, obj/item/armored_weapon/weapon, obj/item/tank_ammo/new_ammo)
	if(!user.temporarilyRemoveItemFromInventory(new_ammo))
		return
	var/was_empty = !weapon.ammo
	weapon.add_ammo(new_ammo)
	update_appearance()
	if(was_empty)
		user.say(is_secondary ? "Loaded!" : (new_ammo.callout_name ? "[new_ammo.callout_name], up!" : "Up!"), forced = "loading a tank gun")

/obj/structure/gun_breech/proc/do_unload(mob/living/user, obj/item/armored_weapon/weapon)
	var/obj/item/tank_ammo/removed = weapon.ammo
	weapon.ammo = null
	removed.update_appearance(UPDATE_ICON_STATE)
	user.put_in_hands(removed)
	weapon.reload()
	update_appearance()
	balloon_alert(user, "unloaded")

/obj/structure/gun_breech/proc/reload_checks(mob/user)
	var/obj/item/armored_weapon/weapon = get_weapon()
	if(!weapon)
		balloon_alert(user, "no weapon!")
		return FALSE
	if(weapon.ammo && length(weapon.ammo_magazine) >= weapon.maximum_magazines)
		balloon_alert(user, "already loaded!")
		return FALSE
	return TRUE

/// Called whenever the main gun fires
/obj/structure/gun_breech/proc/on_main_fire(obj/item/tank_ammo/fired_ammo)
	return

/obj/structure/gun_breech/proc/do_eject_ammo(obj/item/tank_ammo/old_ammo)
	old_ammo.forceMove(get_step(src, WEST))
	if(old_ammo.max_rounds != 1)
		return
	old_ammo.pixel_x = 20
	old_ammo.pixel_y = 4
	var/spin = rand(-90, 90)
	var/matrix/hit_back_transform = matrix()
	hit_back_transform.Turn(spin)
	var/matrix/rest_transform = matrix()
	rest_transform.Turn(spin + rand(-45, 45))
	animate(old_ammo, time = 3, easing = CUBIC_EASING|EASE_OUT, transform = hit_back_transform, pixel_x = 6 + rand(-1, 1), pixel_y = -4 + rand(-1, 1))
	animate(time = 3, easing = CUBIC_EASING|EASE_IN, transform = rest_transform, pixel_x = 3 + rand(0, 10), pixel_y = -17 + rand(-2, 2))
	var/obj/effect/abstract/particle_holder/smoke_visuals = new(src, /particles/breech_smoke)
	QDEL_IN(smoke_visuals, 0.7 SECONDS)

/obj/structure/gun_breech/proc/on_weapon_attach(obj/item/armored_weapon/new_weapon)
	return

/obj/structure/gun_breech/proc/on_weapon_detach(obj/item/armored_weapon/old_weapon)
	return

/particles/breech_smoke
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("smoke_1" = 1, "smoke_2" = 1, "smoke_3" = 2)
	width = 300
	height = 300
	count = 20
	spawning = 20
	lifespan = 1 SECONDS
	fade = 8 SECONDS
	grow = 0.1
	scale = 0.2
	spin = generator(GEN_NUM, -20, 20)
	velocity = list(-4, 0)
	position = list(-2, 2)
	gravity = list(0, 2)
	friction = generator(GEN_NUM, 0.1, 0.5)

/obj/structure/gun_breech/secondary
	name = "secondary loading mechanism"
	desc = "Feeds ammo into the secondary weapon. Hit it with ammo to load, click it to unload."
	icon_state = "secondary_breech"
	is_secondary = TRUE

/obj/structure/gun_breech/secondary/do_eject_ammo(obj/item/tank_ammo/old_ammo)
	old_ammo.forceMove(get_turf(src))
	old_ammo.pixel_x = rand(-10, 10)
	old_ammo.pixel_y = rand(-10, 10)

/obj/structure/gun_breech/lvrt
	icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt.dmi'
	icon_state = "lvrt_breech"

/obj/structure/gun_breech/secondary/lvrt
	name = "coaxial loading mechanism"
	icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt.dmi'
	icon_state = "lvrt_secondary_breech"

/// SOM breech, whose sprite changes with the mounted weapon
/obj/structure/gun_breech/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_breech.dmi'
	icon_state = null
	density = FALSE
	layer = ABOVE_OBJ_LAYER
	var/obj/item/armored_weapon/weapon_type
	var/atom/movable/vis_obj/internal_barrel/barrel_overlay
	var/atom/movable/vis_obj/som_tank_ammo/ammo_overlay

/obj/structure/gun_breech/som/Initialize(mapload)
	barrel_overlay = new
	barrel_overlay.icon = icon
	ammo_overlay = new
	ammo_overlay.icon = icon
	. = ..()
	vis_contents += barrel_overlay
	vis_contents += ammo_overlay

/obj/structure/gun_breech/som/Destroy()
	weapon_type = null
	vis_contents.Cut()
	QDEL_NULL(barrel_overlay)
	QDEL_NULL(ammo_overlay)
	return ..()

/obj/structure/gun_breech/som/update_icon_state()
	. = ..()
	icon_state = weapon_type?.icon_state

/obj/structure/gun_breech/som/update_overlays()
	. = ..()
	if(icon_state)
		. += mutable_appearance(icon, "[icon_state]_overlay", ABOVE_MOB_LAYER)

/obj/structure/gun_breech/som/on_weapon_attach(obj/item/armored_weapon/new_weapon)
	update_gun_appearance(new_weapon)

/obj/structure/gun_breech/som/on_weapon_detach(obj/item/armored_weapon/old_weapon)
	update_gun_appearance(null)

/obj/structure/gun_breech/som/do_load(mob/living/user, obj/item/armored_weapon/weapon, obj/item/tank_ammo/new_ammo)
	. = ..()
	update_gun_appearance(weapon)

/obj/structure/gun_breech/som/do_unload(mob/living/user, obj/item/armored_weapon/weapon)
	. = ..()
	update_gun_appearance(weapon)

/obj/structure/gun_breech/som/on_main_fire(obj/item/tank_ammo/fired_ammo)
	update_gun_appearance(weapon_type)
	if(istype(weapon_type, /obj/item/armored_weapon/coilgun))
		flick("[ammo_overlay.icon_state]_flick", ammo_overlay)

/obj/structure/gun_breech/som/proc/update_gun_appearance(obj/item/armored_weapon/current_weapon)
	weapon_type = current_weapon
	if(!weapon_type)
		density = FALSE
		barrel_overlay.icon_state = null
		ammo_overlay.icon_state = null
		update_appearance()
		return
	density = TRUE
	update_appearance()
	barrel_overlay.icon_state = "[icon_state]_barrel"
	if(istype(weapon_type, /obj/item/armored_weapon/volkite_carronade))
		pixel_x = 4
		pixel_y = -4
		barrel_overlay.pixel_y = 46
	else if(istype(weapon_type, /obj/item/armored_weapon/coilgun))
		pixel_x = -12
		pixel_y = -32
		barrel_overlay.pixel_y = 76
		ammo_overlay.icon_state = "[icon_state]_[length(weapon_type.ammo_magazine) + weapon_type.ammo?.current_rounds]"
	else if(istype(weapon_type, /obj/item/armored_weapon/particle_lance))
		pixel_x = -8
		pixel_y = -7
		barrel_overlay.pixel_y = 48

/atom/movable/vis_obj/internal_barrel
	name = "gun barrel"
	layer = ABOVE_ALL_MOB_LAYER
	vis_flags = VIS_INHERIT_PLANE

/atom/movable/vis_obj/som_tank_ammo
	name = "ammo feed"
	layer = ABOVE_MOB_LAYER
	vis_flags = VIS_INHERIT_PLANE

/// Shelf for spare ammo, shows how full it is
/obj/structure/ammo_rack
	name = "ammo rack"
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	var/storage_slots = 10
	var/list/allowed_ammo = list(/obj/item/tank_ammo)
	var/is_secondary = FALSE
	/// Filled with this many rounds of the mounted weapon's ammo when the interior loads
	var/prefill_count = 4

/obj/structure/ammo_rack/Initialize(mapload)
	. = ..()
	create_storage(max_slots = storage_slots, max_specific_storage = WEIGHT_CLASS_GIGANTIC, max_total_storage = storage_slots * WEIGHT_CLASS_GIGANTIC, canhold = allowed_ammo)
	update_appearance(UPDATE_OVERLAYS)
	RegisterSignals(src, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED), PROC_REF(on_contents_changed))

/obj/structure/ammo_rack/link_interior(datum/interior/link)
	var/obj/vehicle/sealed/armored/owner = link.container
	var/obj/item/armored_weapon/weapon = is_secondary ? owner.secondary_weapon : owner.primary_weapon
	if(!weapon || !length(weapon.accepted_ammo) || length(contents))
		return
	var/ammo_type = weapon.accepted_ammo[1]
	for(var/i in 1 to prefill_count)
		new ammo_type(src)

/obj/structure/ammo_rack/proc/on_contents_changed(datum/source)
	SIGNAL_HANDLER
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/ammo_rack/update_overlays()
	. = ..()
	if(!length(contents))
		return
	var/obj/item/bottommost = contents[1]
	var/thirds = clamp(round(3 * length(contents) / storage_slots, 1), 1, 3)
	. += mutable_appearance(icon, "[initial(bottommost.icon_state)]_[thirds]")

/obj/structure/ammo_rack/primary
	name = "primary ammo rack"
	icon_state = "primaryrack"
	storage_slots = 8

/obj/structure/ammo_rack/primary/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "primaryrack_overlay")

/obj/structure/ammo_rack/secondary
	name = "secondary ammo rack"
	icon_state = "secondaryrack"
	plane = WALL_PLANE
	storage_slots = 6
	is_secondary = TRUE
	prefill_count = 2

/obj/structure/ammo_rack/primary/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_ammo_rack.dmi'
	icon_state = "primary"
	pixel_y = -20
	pixel_x = -34

/obj/structure/ammo_rack/primary/som/update_overlays()
	. = list()
	if(!length(contents))
		return
	var/obj/item/bottommost = contents[1]
	var/thirds = clamp(round(3 * length(contents) / storage_slots, 1), 1, 3)
	. += mutable_appearance(icon, "[initial(bottommost.icon_state)]_[thirds]")

/obj/structure/ammo_rack/secondary/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_ammo_rack.dmi'
	icon_state = "secondary"
	pixel_x = -18
	pixel_y = -5

/obj/structure/ammo_rack/primary/icc
	icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt.dmi'
	icon_state = "primaryrack"
	pixel_y = -20
	pixel_x = -34

/obj/structure/ammo_rack/primary/icc/update_overlays()
	. = list()

/obj/structure/ammo_rack/secondary/icc
	icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt.dmi'
	icon_state = "secondaryrack"
	pixel_x = -18
	pixel_y = -5

/obj/structure/prop_som_tank_computer
	name = "console"
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_props.dmi'
	icon_state = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	pass_flags_self = PASSTABLE|LETPASSTHROW
	light_range = 1
	light_power = 0.5
	light_color = LIGHT_COLOR_GREEN

/obj/structure/prop_som_tank_computer/update_overlays()
	. = ..()
	if(icon_state)
		. += emissive_appearance(icon, "[icon_state]_emissive", src)

/obj/structure/prop_som_tank_computer/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/prop_som_tank_computer/gunner_console
	icon_state = "gunner_console"
	pixel_y = -32

/obj/structure/prop_som_tank_computer/front_left
	icon_state = "driver_left"
	pixel_y = -42

/obj/structure/prop_som_tank_computer/front_center
	icon_state = "driver_center"
	pixel_x = 4
	pixel_y = -74

/obj/structure/prop_som_tank_computer/front_right
	icon_state = "driver_right"
	pixel_x = -4
	pixel_y = -42

/obj/structure/prop_som_tank_computer/floating
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_small_props.dmi'
	icon_state = "computer_overhead"
	density = FALSE
	layer = ABOVE_ALL_MOB_LAYER
	pixel_x = -11
	pixel_y = -1

/obj/structure/prop_som_tank_computer/floating/alt
	icon_state = "computer_overhead_alt"
	pixel_x = 9
	pixel_y = 3
