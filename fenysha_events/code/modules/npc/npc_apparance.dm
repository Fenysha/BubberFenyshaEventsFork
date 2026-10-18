#define ARGS_FEATURES "mut_features"
#define ARGS_COLORS "mut_colors"
#define ARG_FEATURE "mut_feature"
#define ARG_FEATURE_NAME "mut_feat_name"

/mob/living/basic/npc/proc/generate_species_default_features()
	var/list/features = list()
	switch(species)
		if(/datum/species/teshari)
			features = list(
					list(
						ARG_FEATURE = FEATURE_EARS,
						ARG_FEATURE_NAME = "Teshari Feathers Upright",
					),
					list(
						ARG_FEATURE = FEATURE_TAIL_GENERIC,
						ARG_FEATURE_NAME = "Avali (Default)",
					),
				)
			add_hair = FALSE
		if(/datum/species/vulpkanin)
			features = list(
					list(
						ARG_FEATURE = FEATURE_EARS,
						ARG_FEATURE_NAME = "Fox",
					),
					list(
						ARG_FEATURE = FEATURE_TAIL_GENERIC,
						ARG_FEATURE_NAME = "Fox",
					),
					list(
						ARG_FEATURE = FEATURE_SNOUT,
						ARG_FEATURE_NAME = "Mammal, Long",
					),
					list(
						ARG_FEATURE = FEATURE_LEGS,
						ARG_FEATURE_NAME = "Normal Legs",
					),
				)
		if(/datum/species/tajaran)
			features = list(
					list(
						ARG_FEATURE = FEATURE_EARS,
						ARG_FEATURE_NAME = "Cat, normal",
					),
					list(
						ARG_FEATURE = FEATURE_TAIL_GENERIC,
						ARG_FEATURE_NAME = "Cat (Big)",
					),
					list(
						ARG_FEATURE = FEATURE_SNOUT,
						ARG_FEATURE_NAME = "Cat, normal",
					),
					list(
						ARG_FEATURE = FEATURE_LEGS,
						ARG_FEATURE_NAME = "Normal Legs",
					),
				)
		if(/datum/species/lizard, /datum/species/unathi, /datum/species/lizard/ashwalker)
			features = list(
					list(
						ARG_FEATURE = FEATURE_EARS,
						ARG_FEATURE_NAME = "Cat, normal",
					),
					list(
						ARG_FEATURE = FEATURE_TAIL_GENERIC,
						ARG_FEATURE_NAME = "Smooth",
					),
					list(
						ARG_FEATURE = FEATURE_SNOUT,
						ARG_FEATURE_NAME = "Sharp + Light",
					),
					list(
						ARG_FEATURE = FEATURE_LEGS,
						ARG_FEATURE_NAME = "Normal Legs",
					),
					list(
						ARG_FEATURE = FEATURE_SPINES,
						ARG_FEATURE_NAME = "None",
					),
					list(
						ARG_FEATURE = FEATURE_FRILLS,
						ARG_FEATURE_NAME = "None",
					),
					list(
						ARG_FEATURE = FEATURE_HORNS,
						ARG_FEATURE_NAME = "Curled",
					),
					list(
						ARG_FEATURE = "body_markings",
						ARG_FEATURE_NAME = "Smooth Belly",
					),
				)
	return features

/mob/living/basic/npc/proc/randomize_colors()
	var/preset = rand(1, 7)
	switch(preset)
		if(1)
			mutant_color_1 = pick("#2F2F2F", "#3D3D3D", "#505050", "#6B6B6B", "#8C8C8C")
			mutant_color_2 = "#C8C8C8"
			mutant_color_3 = "#1A1A1A"
		if(2)
			mutant_color_1 = pick("#C9B8A0", "#B89F7E", "#A67C52", "#D2B48C", "#E0C9A0")
			mutant_color_2 = "#F4E4C9"
			mutant_color_3 = "#5C4633"
		if(3)
			mutant_color_1 = pick("#3F2A1E", "#523B2A", "#664B38", "#8B6647", "#A37F5E")
			mutant_color_2 = "#C9A37A"
			mutant_color_3 = "#2C2118"
		if(4)
			mutant_color_1 = pick("#9F3A1F", "#BF4F22", "#E07035", "#FF9F4F", "#D96F1F")
			mutant_color_2 = "#FFCC99"
			mutant_color_3 = "#5C2F1A"
		if(5)
			mutant_color_1 = pick("#48689E", "#334C7A", "#263B5E", "#6A8A9E", "#7E9EB0")
			mutant_color_2 = "#B0CDE8"
			mutant_color_3 = "#1F2F4A"
		if(6)
			mutant_color_1 = pick("#1E3F2B", "#2A5A3C", "#3A7A52", "#6E9B6E", "#8FBC8F")
			mutant_color_2 = "#A8D4B5"
			mutant_color_3 = "#13261F"
		if(7)
			mutant_color_1 = pick("#3A2A5C", "#4A3A78", "#5F4A96", "#7E6EB8", "#9B79C4")
			mutant_color_2 = "#D4B8F0"
			mutant_color_3 = "#2A1F3F"
	if(prob(40))
		mutant_color_1 = color_interpolate(mutant_color_1, "#FFFFFF", 0.12)
	else if(prob(30))
		mutant_color_1 = color_interpolate(mutant_color_1, "#000000", 0.08)

/mob/living/basic/npc/proc/generate_dynamic_appearance()
	var/skin_tone = pick(GLOB.skin_tones)
	var/eye_color = random_eye_color()
	var/hair_color = random_hair_color()
	var/list/features = list(
		ARGS_FEATURES = get_default_features() || generate_species_default_features(),
		ARGS_COLORS = get_mutant_colors(),
	)
	var/dynamic_appearance

	var/mob/living/carbon/human/dummy = new()
	dummy.set_species(species)
	dummy.stat = DEAD
	dummy.underwear = "Nude"
	dummy.undershirt = "Nude"
	dummy.socks = "Nude"
	dummy.set_combat_mode(combat_mode)
	dummy.set_eye_color(eye_color)
	if(species == /datum/species/human)
		dummy.physique = gender
		dummy.skin_tone = skin_tone
	if(add_hair)
		var/datum/sprite_accessory/hairstyle = SSaccessories.hairstyles_list[random_hairstyle(gender)]
		if(hairstyle && hairstyle.natural_spawn && !hairstyle.locked)
			dummy.set_hairstyle(hairstyle.name, update = FALSE)
		dummy.set_haircolor(hair_color, update = FALSE)
		dummy.updateappearance(TRUE, FALSE, FALSE)
	else
		dummy.set_hairstyle("Bald", update = TRUE)
	if(outfit)
		var/datum/outfit/dummy_outfit = new outfit()
		if(item_r_hand != NO_REPLACE)
			dummy_outfit.r_hand = item_r_hand
		if(item_l_hand != NO_REPLACE)
			dummy_outfit.l_hand = item_l_hand
		dummy.equipOutfit(dummy_outfit, visuals_only = TRUE)
	else if(mob_type)
		var/obj/effect/mob_spawn/spawner = new mob_type(null, TRUE)
		spawner.outfit_override = list()
		if(item_r_hand != NO_REPLACE)
			spawner.outfit_override["r_hand"] = item_r_hand
		if(item_l_hand != NO_REPLACE)
			spawner.outfit_override["l_hand"] = item_l_hand
		spawner.special(dummy, dummy)
		spawner.equip(dummy)
	for(var/obj/item/carried_item in dummy)
		if(dummy.is_holding(carried_item))
			var/datum/component/two_handed/twohanded = carried_item.GetComponent(/datum/component/two_handed)
			if(twohanded)
				twohanded.wield(dummy)
			var/datum/component/transforming/transforming = carried_item.GetComponent(/datum/component/transforming)
			if(transforming)
				transforming.set_active(carried_item)
	if(length(features[ARGS_FEATURES]))
		for(var/list/special in features[ARGS_FEATURES])
			dummy.dna.mutant_bodyparts[special[ARG_FEATURE]] = list(
				MUTANT_INDEX_NAME = special[ARG_FEATURE_NAME],
				MUTANT_INDEX_COLOR_LIST = features[ARGS_COLORS],
			)
	dummy.dna.features[FEATURE_MUTANT_COLOR] = features[ARGS_COLORS][1]
	dummy.dna.species.regenerate_organs(dummy, dummy.dna.species, visual_only = TRUE)
	dummy.update_body(TRUE)
	dummy.update_held_items()
	dynamic_appearance = dummy.appearance
	icon = 'icons/mob/human/human.dmi'
	icon_state = ""
	appearance_flags |= KEEP_TOGETHER
	copy_overlays(dynamic_appearance, cut_old = TRUE)

	if(save_data)
		saved_skin_tone = dummy.skin_tone
		saved_physique = dummy.physique
		saved_eye_color_left = dummy.eye_color_left
		saved_eye_color_right = dummy.eye_color_right
		saved_hairstyle = dummy.hairstyle
		saved_hair_color = hair_color
		saved_facial_hairstyle = dummy.facial_hairstyle
		saved_facial_hair_color = hair_color
		saved_dna_features = dummy.dna.features.Copy()
		saved_mutant_bodypart = dummy.dna.mutant_bodyparts.Copy()
	qdel(dummy)


/mob/living/basic/npc/proc/spawn_real_corpse_and_destroy()
	if(!save_data)
		qdel(src)
		return
	var/mob/living/carbon/human/corpse = new(loc)
	corpse.gender = gender
	corpse.set_species(species)
	corpse.physique = saved_physique
	corpse.skin_tone = saved_skin_tone
	corpse.eye_color_left = saved_eye_color_left
	corpse.eye_color_right = saved_eye_color_right
	corpse.dna.features = saved_dna_features.Copy()
	corpse.dna.mutant_bodyparts = saved_mutant_bodypart.Copy()
	corpse.dna.species.regenerate_organs(corpse, corpse.dna.species, visual_only = TRUE)
	if(saved_hairstyle)
		corpse.set_hairstyle(saved_hairstyle, update = FALSE)
	if(saved_hair_color)
		corpse.set_haircolor(saved_hair_color, update = FALSE)
	if(saved_facial_hairstyle)
		corpse.set_facial_hairstyle(saved_facial_hairstyle, update = FALSE)
	if(saved_facial_hair_color)
		corpse.set_facial_haircolor(saved_facial_hair_color, update = FALSE)
	corpse.underwear = "Nude"
	corpse.undershirt = "Nude"
	corpse.socks = "Nude"
	corpse.update_body(TRUE)
	var/drop_right = prob(50)
	var/drop_left = prob(50)

	if(outfit)
		var/datum/outfit/corpse_outfit = new outfit()
		if(!drop_right && item_r_hand != NO_REPLACE)
			corpse_outfit.r_hand = item_r_hand
		if(!drop_left && item_l_hand != NO_REPLACE)
			corpse_outfit.l_hand = item_l_hand
		corpse.equipOutfit(corpse_outfit)

	if(drop_right && item_r_hand && item_r_hand != NO_REPLACE)
		new item_r_hand(loc)
	if(drop_left && item_l_hand && item_l_hand != NO_REPLACE)
		new item_l_hand(loc)
	var/obj/item/clothing/under/sensor_clothes = corpse.w_uniform
	if(istype(sensor_clothes))
		sensor_clothes.set_sensor_mode(SENSOR_OFF)
	corpse.fully_replace_character_name(null, name)
	corpse.death(TRUE)
	qdel(src)

/mob/living/basic/npc/proc/get_mutant_colors()
	return list(mutant_color_1, mutant_color_2, mutant_color_3)


/mob/living/basic/npc/proc/get_default_features()
	return null


#undef ARGS_FEATURES
#undef ARGS_COLORS
#undef ARG_FEATURE
#undef ARG_FEATURE_NAME

