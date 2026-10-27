/obj/item/clothing/glasses/meson/equipped(mob/living/user, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_EYES))
		return
	ADD_TRAIT(user, TRAIT_MESON_VISION, CLOTHING_TRAIT)
	user.update_sight()

/obj/item/clothing/glasses/meson/dropped(mob/living/user)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.glasses == src)
			REMOVE_TRAIT(user, TRAIT_MESON_VISION, CLOTHING_TRAIT)
			user.update_sight()

/mob
	plane = MOB_PLANE
	sight = SEE_MOBS|SEE_OBJS|SEE_TURFS

// The client is sent everything (SEE_TURFS etc. above); the darkness is only the shadow shader.
// Don't name what the wall shadows hide.
/atom/on_mouse_enter(client/client)
	. = ..()
	var/mob/user = client?.mob
	var/datum/hud/active_hud = user?.hud_used
	if(!active_hud?.screentip_text.maptext || !hidden_by_wall_shadows(user))
		return
	active_hud.screentip_text.maptext = ""

/atom/proc/hidden_by_wall_shadows(mob/user)
	// HUD elements and anything held or inside something are never shadowed
	if(!isturf(src) && !isturf(loc))
		return FALSE
	return !rust_dm_can_see(user, src, rust_effective_sight_flags(user, RUST_SEE_DEFAULT))

/obj/structure/cable
	plane = ABOVE_FLOOR_PLANE
