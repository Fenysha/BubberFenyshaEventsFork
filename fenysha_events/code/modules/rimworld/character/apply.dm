/datum/rimworld_preferences/proc/apply_to_human(mob/living/carbon/human/target, visuals_only = FALSE)
	if(!istype(target))
		return FALSE
	sanitize_character()
	target.real_name = real_name
	target.name = real_name
	target.gender = gender
	target.set_species(species_type, icon_update = FALSE, pref_load = FALSE)
	if(hairstyle)
		target.set_hairstyle(hairstyle, update = FALSE)
	if(hair_color)
		target.set_haircolor(hair_color, update = FALSE)
	if(facial_hairstyle)
		target.set_facial_hairstyle(facial_hairstyle, update = FALSE)
	if(facial_hair_color)
		target.set_facial_haircolor(facial_hair_color, update = FALSE)
	target.underwear = underwear || "Nude"
	target.underwear_color = underwear_color || "#ffffff"
	target.undershirt = undershirt || "Nude"
	target.undershirt_color = undershirt_color || "#ffffff"
	target.bra = bra || "Nude"
	target.bra_color = bra_color || "#ffffff"
	target.socks = socks || "Nude"
	target.socks_color = socks_color || "#ffffff"
	target.jumpsuit_style = jumpsuit_style || PREF_SUIT
	target.backpack = backpack || DBACKPACK
	var/used_physique = body_type
	if(used_physique == "Use gender")
		used_physique = gender
	if(used_physique != MALE && used_physique != FEMALE)
		used_physique = FEMALE
	target.physique = used_physique
	if(istype(target, /mob/living/carbon/human/dummy))
		target.underwear_visibility = NONE
	sync_owned_to_bridge()
	if(pref_bridge)
		pref_bridge.apply_prefs_to(target, icon_updates = FALSE, visuals_only = visuals_only)
	else
		apply_details_to_human(target)
	target.dna.set_rw_xenogenes(xenogenes, apply = TRUE)
	var/list/final_skills = list()
	for(var/skill_id in GLOB.all_rw_skills)
		final_skills[skill_id] = get_skill_level(skill_id)
	var/datum/component/rw_skills/skill_comp = target.GetComponent(/datum/component/rw_skills)
	if(skill_comp)
		skill_comp.set_levels(final_skills)
	else
		target.AddComponent(/datum/component/rw_skills, final_skills)
	for(var/item_id in loadout)
		var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
		item?.equip_to(target)
	target.icon_render_keys = list()
	target.update_body(TRUE)
	if(istype(target, /mob/living/carbon/human/dummy))
		apply_dummy_clothes(target)
	target.update_hair()
	target.update_eyes()
	return TRUE

/datum/rimworld_preferences/proc/apply_saved_look(mob/living/carbon/human/target, list/data)
	if(!istype(target) || !data)
		return FALSE
	target.real_name = data["real_name"] || "Colonist"
	target.name = target.real_name
	var/new_gender = data["gender"]
	if(new_gender == MALE || new_gender == FEMALE || new_gender == PLURAL || new_gender == NEUTER)
		target.gender = new_gender
	var/species_path = text2path(data["species"])
	if(!(species_path in GLOB.rw_base_species))
		species_path = /datum/species/human
	target.set_species(species_path, icon_update = FALSE, pref_load = FALSE)
	if(data["hairstyle"])
		target.set_hairstyle(data["hairstyle"], update = FALSE)
	if(data["hair_color"])
		target.set_haircolor(data["hair_color"], update = FALSE)
	if(data["facial_hairstyle"])
		target.set_facial_hairstyle(data["facial_hairstyle"], update = FALSE)
	if(data["facial_hair_color"])
		target.set_facial_haircolor(data["facial_hair_color"], update = FALSE)
	target.underwear = data["underwear"] || "Nude"
	target.underwear_color = data["underwear_color"] || "#ffffff"
	target.undershirt = data["undershirt"] || "Nude"
	target.undershirt_color = data["undershirt_color"] || "#ffffff"
	target.bra = data["bra"] || "Nude"
	target.bra_color = data["bra_color"] || "#ffffff"
	target.socks = data["socks"] || "Nude"
	target.socks_color = data["socks_color"] || "#ffffff"
	target.jumpsuit_style = data["jumpsuit_style"] || PREF_SUIT
	target.backpack = data["backpack"] || DBACKPACK
	var/used_physique = data["body_type"] || "Use gender"
	if(used_physique == "Use gender")
		used_physique = target.gender
	if(used_physique != MALE && used_physique != FEMALE)
		used_physique = FEMALE
	target.physique = used_physique
	if(istype(target, /mob/living/carbon/human/dummy))
		target.underwear_visibility = NONE
	apply_details_to_human(target, data)
	target.dna.set_rw_xenogenes(data["xenogenes"] || list(), apply = TRUE)
	for(var/item_id in data["loadout"])
		var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
		item?.equip_to(target)
	target.icon_render_keys = list()
	target.update_body(TRUE)
	if(istype(target, /mob/living/carbon/human/dummy))
		apply_dummy_clothes(target)
	target.update_hair()
	target.update_eyes()
	return TRUE

/datum/rimworld_preferences/proc/detail_value(list/data, key, fallback)
	if(data && !isnull(data[key]))
		return data[key]
	return fallback

/datum/rimworld_preferences/proc/apply_details_to_human(mob/living/carbon/human/target, list/data)
	if(!istype(target) || !target.dna)
		return
	var/used_skin = detail_value(data, "skin_tone", skin_tone) || "caucasian1"
	var/used_mcolor = detail_value(data, "mutant_color", mutant_color) || "#c0965f"
	var/used_mcolor2 = detail_value(data, "mutant_color_2", mutant_color_2) || used_mcolor
	var/used_mcolor3 = detail_value(data, "mutant_color_3", mutant_color_3) || used_mcolor
	var/datum/species/proto = target.dna.species
	if(proto && (TRAIT_USES_SKINTONES in proto.inherent_traits))
		target.skin_tone = used_skin
	target.dna.features[FEATURE_MUTANT_COLOR] = used_mcolor
	target.dna.features[FEATURE_MUTANT_COLOR_TWO] = used_mcolor2
	target.dna.features[FEATURE_MUTANT_COLOR_THREE] = used_mcolor3

	var/used_eye = detail_value(data, "eye_color", eye_color) || random_eye_color()
	var/used_eye_right = detail_value(data, "eye_color_right", eye_color_right)
	if(length(used_eye_right) && lowertext(used_eye_right) != lowertext(used_eye))
		target.eye_color_heterochromatic = TRUE
		target.set_eye_color(used_eye, used_eye_right)
	else
		target.eye_color_heterochromatic = FALSE
		target.set_eye_color(used_eye)

	var/used_grad = detail_value(data, "hair_gradient", hair_gradient) || "None"
	var/used_grad_color = detail_value(data, "hair_gradient_color", hair_gradient_color) || "#ffffff"
	target.set_hair_gradient_style(used_grad, update = FALSE)
	target.set_hair_gradient_color(used_grad_color, update = FALSE)
	var/used_fgrad = detail_value(data, "facial_gradient", facial_gradient) || "None"
	var/used_fgrad_color = detail_value(data, "facial_gradient_color", facial_gradient_color) || "#ffffff"
	target.set_facial_hair_gradient_style(used_fgrad, update = FALSE)
	target.set_facial_hair_gradient_color(used_fgrad_color, update = FALSE)

	var/used_size = text2num(detail_value(data, "body_size", body_size)) || 1
	used_size = clamp(used_size, BODY_SIZE_MIN, BODY_SIZE_MAX)
	if(target.current_size && abs(target.current_size - used_size) > 0.001)
		target.update_transform(used_size / target.current_size)

	target.dna.features["flavor_text"] = detail_value(data, "flavor_text", flavor_text) || ""
	target.dna.features["flavor_text_nsfw"] = detail_value(data, "flavor_text_nsfw", flavor_text_nsfw) || ""
	target.dna.features["ooc_notes"] = detail_value(data, "ooc_notes", ooc_notes) || ""
	target.dna.features["custom_species"] = detail_value(data, "custom_species", custom_species) || ""
	target.dna.features["custom_species_lore"] = detail_value(data, "custom_species_lore", custom_species_lore) || ""
	target.dna.features["headshot"] = detail_value(data, "headshot", headshot) || ""

	var/used_scream = detail_value(data, "character_scream", character_scream) || "Human Scream"
	var/scream_path = GLOB.scream_types[used_scream]
	if(scream_path)
		target.selected_scream = new scream_path
	var/used_laugh = detail_value(data, "character_laugh", character_laugh) || "Human Laugh"
	var/laugh_path = GLOB.laugh_types[used_laugh]
	if(laugh_path)
		target.selected_laugh = new laugh_path
	var/used_chat = detail_value(data, "chat_color", chat_color) || "#b0b0b0"
	target.apply_preference_chat_color(used_chat)
	var/used_blooper = detail_value(data, "blooper_choice", blooper_choice)
	if(used_blooper && length(SSblooper.blooper_list) && (used_blooper in SSblooper.blooper_list))
		target.blooper = SSblooper.blooper_list[used_blooper]
	var/used_speed = text2num(detail_value(data, "blooper_speed", blooper_speed))
	target.blooper_speed = clamp(isnull(used_speed) ? blooper_speed : used_speed, 0, 100)
	var/used_pitch = text2num(detail_value(data, "blooper_pitch", blooper_pitch))
	target.blooper_pitch = clamp(isnull(used_pitch) ? blooper_pitch : used_pitch, 0, 100)
	var/used_range = text2num(detail_value(data, "blooper_pitch_range", blooper_pitch_range))
	target.blooper_pitch_range = clamp(isnull(used_range) ? blooper_pitch_range : used_range, 0, 100)

	target.dna.features["taste"] = detail_value(data, "custom_taste", custom_taste) || ""
	target.dna.features["smell"] = detail_value(data, "custom_smell", custom_smell) || ""
	target.dna.features["general_record"] = detail_value(data, "general_record", general_record) || ""
	target.dna.features["medical_record"] = detail_value(data, "medical_record", medical_record) || ""
	target.dna.features["security_record"] = detail_value(data, "security_record", security_record) || ""
	target.dna.features["exploitable_info"] = detail_value(data, "exploitable_info", exploitable_info) || ""
	target.dna.features["background_info"] = detail_value(data, "background_info", background_info) || ""
