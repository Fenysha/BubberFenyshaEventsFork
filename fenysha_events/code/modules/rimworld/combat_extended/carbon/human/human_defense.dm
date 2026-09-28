/**
 * Apparel covering this bodypart, outermost first.
 */
/mob/living/carbon/human/proc/get_armor_layers_for_part(obj/item/bodypart/BP)
	var/list/layers = list()
	var/list/ordered = list(
		wear_suit,
		w_uniform,
		back,
		belt,
		gloves,
		shoes,
		wear_neck,
		wear_mask,
		head,
		glasses,
		ears,
	)
	for(var/obj/item/clothing/C in ordered)
		if(!C?.get_armor())
			continue
		if(C.body_parts_covered & BP.body_part)
			layers += C
	return layers

/mob/living/carbon/human/run_armor_penetration(obj/item/bodypart/BP, list/packet)
	if(!BP || !packet)
		return packet

	for(var/obj/item/clothing/layer as anything in get_armor_layers_for_part(BP))
		var/datum/armor/A = layer.get_armor()
		if(!A)
			continue
		packet = pen_apply_armor_layer(packet, A.get_sharp_rating(), A.get_blunt_rating())
		if(packet["damage"] <= 0 && !pen_can_penetrate_deeper(packet))
			return packet

	if(physiology?.armor)
		packet = pen_apply_armor_layer(
			packet,
			physiology.armor.get_sharp_rating(),
			physiology.armor.get_blunt_rating(),
		)

	if(BP.natural_sharp_armor || BP.natural_blunt_armor)
		packet = pen_apply_armor_layer(packet, BP.natural_sharp_armor, BP.natural_blunt_armor)

	return packet
