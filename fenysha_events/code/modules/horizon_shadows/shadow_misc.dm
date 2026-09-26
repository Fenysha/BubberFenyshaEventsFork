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

/obj/structure/cable
	plane = ABOVE_FLOOR_PLANE
