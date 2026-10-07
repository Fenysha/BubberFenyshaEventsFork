#ifndef OLD_COMBAT_SYSTEM
/**
 * Returns the combined structural failure score of injuries on this bodypart.
 *
 * This represents actual anatomical destruction rather than generic damage.
 */
/obj/item/bodypart/proc/get_dismemberment_injury_score()
	var/score = 0

	for(var/datum/injury/injury as anything in injuries)
		if(injury.dismemberment_weight <= 0)
			continue
		score += injury.dismemberment_weight

	return score

/obj/item/bodypart/proc/has_dismemberment_injury()
	for(var/datum/injury/injury as anything in injuries)
		if(injury.dismemberment_weight > 0)
			return TRUE
	return FALSE

/obj/item/bodypart/proc/try_dismember_from_damage(brute, burn, sharpness = NONE)
	if(!owner || (body_zone in list(BODY_ZONE_HEAD, BODY_ZONE_CHEST)))
		return FALSE

	if(HAS_TRAIT(owner, TRAIT_NODISMEMBER) || !sharpness)
		return FALSE

	if(brute <= 0)
		return FALSE

	var/physical_ratio = clamp(brute_dam / max_damage, 0, 1)
	var/injury_score = get_dismemberment_injury_score()

	if(physical_ratio < 0.70)
		return FALSE

	if(injury_score <= 0)
		return FALSE

	var/chance = (physical_ratio - 0.70) * 170
	chance += injury_score * 7
	chance += clamp(brute / max_damage * 100, 0, 25)

	if(sharpness & SHARP_EDGED)
		chance += 20
	else if(sharpness & SHARP_POINTY)
		chance += 10

	chance = clamp(chance, 0, 100)

	if(physical_ratio >= 0.92 && injury_score >= 3.0)
		chance = 100

	if(!prob(chance))
		return FALSE

	return dismember(BRUTE, FALSE)

///Remove target limb from its owner, with side effects.
/obj/item/bodypart/proc/dismember(dam_type = BRUTE, silent=TRUE, wounding_type)
	if(!owner || (bodypart_flags & BODYPART_UNREMOVABLE))
		return FALSE
	var/mob/living/carbon/limb_owner = owner
	if(HAS_TRAIT(limb_owner, TRAIT_GODMODE) || HAS_TRAIT(limb_owner, TRAIT_NODISMEMBER))
		return FALSE

	var/obj/item/bodypart/affecting = limb_owner.get_bodypart(BODY_ZONE_CHEST)
	if(affecting)
		affecting.receive_damage(clamp(brute_dam/2 * affecting.body_damage_coeff, 15, 50), clamp(burn_dam/2 * affecting.body_damage_coeff, 0, 50), wound_bonus=CANT_WOUND)
		var/datum/injury/stump/stump_injury = new /datum/injury/stump()
		stump_injury.lost_zone = body_zone
		stump_injury.apply_to_limb(affecting, silent = silent, source = "dismemberment")

	if(!silent)
		limb_owner.visible_message(span_danger("<B>[limb_owner]'s [name] is violently dismembered!</B>"))
	INVOKE_ASYNC(limb_owner, TYPE_PROC_REF(/mob, emote), "scream")
	playsound(limb_owner, 'sound/effects/dismember.ogg', 80, TRUE)
	limb_owner.add_mood_event("dismembered_[body_zone]", /datum/mood_event/dismembered, src)
	limb_owner.add_mob_memory(/datum/memory/was_dismembered, lost_limb = src)

	if (wounding_type)
		LAZYSET(limb_owner.body_zone_dismembered_by, body_zone, wounding_type)

	drop_limb(dismembered = TRUE)
	limb_owner.update_equipment_speed_mods()

	// Immediate medical state refresh after the stump is applied and the limb is gone.
	limb_owner.recalculate_medical_state()
	limb_owner.updatehealth()

	if(QDELETED(src)) //Could have dropped into lava/explosion/chasm/whatever
		return TRUE
	if(dam_type == BURN)
		burn()
		return TRUE

	// Residual arterial spray from the open stump (stump injury already has its own bleed_rate).
	if(can_bleed())
		limb_owner.bleed(rand(15, 30))
	return TRUE

/obj/item/bodypart/chest/dismember(dam_type = BRUTE, silent=TRUE, wounding_type)
	if(!owner)
		return FALSE
	var/mob/living/carbon/chest_owner = owner
	if(bodypart_flags & BODYPART_UNREMOVABLE)
		return FALSE
	if(HAS_TRAIT(chest_owner, TRAIT_NODISMEMBER))
		return FALSE

	. = list()
	if(wounding_type != WOUND_BURN && isturf(chest_owner.loc) && can_bleed())
		chest_owner.add_splatter_floor(chest_owner.loc)
	playsound(get_turf(chest_owner), 'sound/misc/splort.ogg', 80, TRUE)
	var/list/droppable_organs= list()
	for(var/obj/item/organ/droppable in contents)
		droppable_organs |= droppable
	var/obj/item/organ/organ = pick(droppable_organs)
	if(organ)
		if(!organ.drop_when_organ_spilling)
			return
		var/org_zone = check_zone(organ.zone)
		if(org_zone != BODY_ZONE_CHEST)
			return
		organ.Remove(chest_owner)
		if(chest_owner.loc)
			organ.forceMove(chest_owner.loc)
		. += organ

	if(cavity_item)
		cavity_item.forceMove(chest_owner.loc)
		. += cavity_item
		cavity_item = null

/obj/item/bodypart/proc/drop_limb(special, dismembered, move_to_floor = TRUE)
	if(!owner)
		return
	var/atom/drop_loc = owner.drop_location()
	var/mob/living/carbon/limb_owner = owner

	// Clean injuries WHILE owner is still valid so pain/shock totals update correctly.
	// remove_from_limb() calls update_injuries() which needs a live owner reference.
	for(var/datum/injury/injury as anything in injuries)
		injury.remove_from_limb()

	SEND_SIGNAL(limb_owner, COMSIG_CARBON_REMOVE_LIMB, src, special, dismembered)
	SEND_SIGNAL(src, COMSIG_BODYPART_REMOVED, limb_owner, special, dismembered)
	bodypart_flags &= ~BODYPART_IMPLANTED //limb is out and about, it can't really be considered an implant
	add_mob_blood(limb_owner)
	limb_owner.remove_bodypart(src, special)

	for(var/datum/scar/scar as anything in scars)
		scar.victim = null
		LAZYREMOVE(limb_owner.all_scars, scar)

	var/mob/living/carbon/phantom_owner = update_owner(null) // so we can still refer to the guy who lost their limb after said limb forgets 'em
	update_limb(dropping_limb = TRUE)

	// Force a full pain rebuild now that this limb is gone from bodyparts.
	if(phantom_owner)
		phantom_owner.update_pain_from_limb(null)
		phantom_owner.recalculate_medical_state()

	if(!phantom_owner.has_embedded_objects())
		phantom_owner.clear_alert(ALERT_EMBEDDED_OBJECT)
		phantom_owner.clear_mood_event("embedded")

	if(!special)
		if(phantom_owner.dna)
			for(var/datum/mutation/mutation as anything in phantom_owner.dna.mutations) //some mutations require having specific limbs to be kept.
				if(mutation.limb_req && (mutation.limb_req == body_zone))
					to_chat(phantom_owner, span_warning("You feel your [mutation] deactivating from the loss of your [body_zone]!"))
					phantom_owner.dna.remove_mutation(mutation, mutation.sources)

	update_icon_dropped()
	phantom_owner.update_health_hud() //update the healthdoll
	phantom_owner.update_body()
	if(!special)
		phantom_owner.hud_used?.update_locked_slots()

	if(bodypart_flags & (BODYPART_PSEUDOPART|BODYPART_STUMP))
		drop_organs(phantom_owner) //Psuedoparts shouldn't have organs, but just in case
		if(!QDELING(src)) // we might be removed as a part of something qdeling us
			qdel(src)
		return

	if(move_to_floor)
		if(!drop_loc) // drop_loc = null happens when a "dummy human" used for rendering icons on prefs screen gets its limbs replaced.
			qdel(src)
			return
		forceMove(drop_loc)

	SEND_SIGNAL(phantom_owner, COMSIG_CARBON_POST_REMOVE_LIMB, src, special, dismembered)

/obj/item/bodypart/proc/dismemberable_by_total_damage()
	return FALSE
#endif
