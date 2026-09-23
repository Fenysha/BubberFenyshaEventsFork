/datum/rimworld_preferences/ui_interact(mob/user, datum/tgui/ui)
	if(SSearly_assets.initialized != INITIALIZATION_INNEW_REGULAR)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ensure_all_slots_filled()
		update_preview()
		warm_portraits()
		ui = new(user, src, "RimworldCharacterEditor", "Prepare Colonist")
		ui.set_autoupdate(FALSE)
		ui.open()
		character_preview_view?.display_to(user, ui.window)

/datum/rimworld_preferences/ui_state(mob/user)
	return GLOB.always_state

/datum/rimworld_preferences/ui_status(mob/user, datum/ui_state/state)
	return user.client == parent ? UI_INTERACTIVE : UI_CLOSE

/datum/rimworld_preferences/ui_close(mob/user)
	save_character()
	QDEL_NULL(character_preview_view)
	QDEL_NULL(preview_dummy)
	return ..()

/datum/rimworld_preferences/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/preferences),
		get_asset_datum(/datum/asset/json/preferences),
	)

/datum/rimworld_preferences/proc/accessory_icon_pairs(preference_type)
	var/list/pairs = list()
	var/datum/preference/choiced/pref = GLOB.preference_entries[preference_type]
	if(!pref)
		return pairs
	for(var/choice in pref.get_choices())
		pairs += list(list("[choice]", pref.get_spritesheet_key(pref.serialize(choice))))
	return pairs

/datum/rimworld_preferences/proc/pref_choice_names(preference_type)
	var/list/names = list()
	var/datum/preference/choiced/pref = GLOB.preference_entries[preference_type]
	if(!pref)
		return names
	for(var/choice in pref.get_choices())
		if(istext(choice) && choice)
			names += choice
	return names

/datum/rimworld_preferences/proc/clothing_chooser_defs(list/hairstyles, list/facials)
	return list(
		list("id" = "hairstyle", "name" = "Hairstyle", "thumbs" = "hair", "hasColor" = TRUE, "choices" = hairstyles || list("Bald")),
		list("id" = "facial", "name" = "Facial hair", "thumbs" = "facial", "hasColor" = TRUE, "choices" = facials || list("Shaved")),
		list("id" = "bra", "name" = "Bra", "thumbs" = "bra", "hasColor" = TRUE, "choices" = pref_choice_names(/datum/preference/choiced/bra)),
		list("id" = "undershirt", "name" = "Undershirt", "thumbs" = "undershirt", "hasColor" = TRUE, "choices" = pref_choice_names(/datum/preference/choiced/undershirt)),
		list("id" = "underwear", "name" = "Underwear", "thumbs" = "underwear", "hasColor" = TRUE, "choices" = pref_choice_names(/datum/preference/choiced/underwear)),
		list("id" = "socks", "name" = "Socks", "thumbs" = "socks", "hasColor" = TRUE, "choices" = pref_choice_names(/datum/preference/choiced/socks)),
	)

/datum/rimworld_preferences/ui_static_data(mob/user)
	var/list/data = list()
	data["budgetMax"] = RW_CHARACTER_BUDGET
	data["skillManualMax"] = RW_SKILL_MANUAL_MAX
	data["skillMax"] = RW_SKILL_MAX
	var/list/hairstyles = list()
	for(var/hairstyle_name in SSaccessories.hairstyles_list)
		if(!istext(hairstyle_name) || !hairstyle_name)
			continue
		var/datum/sprite_accessory/hair/hair = SSaccessories.hairstyles_list[hairstyle_name]
		if(hair?.locked)
			continue
		hairstyles += hairstyle_name
	data["hairstyles"] = length(hairstyles) ? hairstyles : list("Bald")
	var/list/facials = list()
	for(var/facial_name in SSaccessories.facial_hairstyles_list)
		if(!istext(facial_name) || !facial_name)
			continue
		var/datum/sprite_accessory/facial_hair/beard = SSaccessories.facial_hairstyles_list[facial_name]
		if(beard?.locked)
			continue
		facials += facial_name
	data["facials"] = length(facials) ? facials : list("Shaved")
	data["hairIcons"] = accessory_icon_pairs(/datum/preference/choiced/hairstyle)
	data["underwearIcons"] = accessory_icon_pairs(/datum/preference/choiced/underwear)
	data["clothingDefs"] = clothing_chooser_defs(data["hairstyles"], data["facials"])
	data["clothingIcons"] = list(
		"hair" = accessory_icon_pairs(/datum/preference/choiced/hairstyle),
		"facial" = accessory_icon_pairs(/datum/preference/choiced/facial_hairstyle),
		"underwear" = accessory_icon_pairs(/datum/preference/choiced/underwear),
		"undershirt" = accessory_icon_pairs(/datum/preference/choiced/undershirt),
		"bra" = accessory_icon_pairs(/datum/preference/choiced/bra),
		"socks" = accessory_icon_pairs(/datum/preference/choiced/socks),
	)
	data["skinTones"] = GLOB.skin_tones.Copy()
	data["skinToneNames"] = GLOB.skin_tone_names.Copy()
	var/list/skin_hex = list()
	for(var/tone in data["skinTones"])
		skin_hex[tone] = skintone2hex(tone)
	data["skinToneHex"] = skin_hex
	data["tattoos"] = list("None")
	data["hairGradients"] = SSaccessories.hair_gradients_list ? assoc_to_keys(SSaccessories.hair_gradients_list) : list("None")
	data["facialGradients"] = SSaccessories.facial_hair_gradients_list ? assoc_to_keys(SSaccessories.facial_hair_gradients_list) : list("None")
	data["screamTypes"] = length(GLOB.scream_types) ? assoc_to_keys(GLOB.scream_types) : list("Human Scream")
	data["laughTypes"] = length(GLOB.laugh_types) ? assoc_to_keys(GLOB.laugh_types) : list("Human Laugh")
	var/list/blooper_ids = list()
	var/list/blooper_names = list()
	if(length(SSblooper.blooper_list))
		blooper_ids = assoc_to_keys(SSblooper.blooper_list)
		for(var/blooper_id in blooper_ids)
			var/datum/blooper/voice = SSblooper.blooper_list[blooper_id]
			blooper_names[blooper_id] = voice?.name || blooper_id
	else
		blooper_ids = list("none")
		blooper_names["none"] = "None"
	data["blooperTypes"] = blooper_ids
	data["blooperNames"] = blooper_names

	var/list/species = list()
	for(var/species_path as anything in GLOB.rw_base_species)
		var/datum/species/proto = GLOB.species_prototypes[species_path]
		if(!proto)
			continue
		species += list(list(
			"id" = proto.id,
			"name" = proto.name,
			"path" = "[species_path]",
			"usesSkintones" = (TRAIT_USES_SKINTONES in proto.inherent_traits),
		))
	data["speciesDefs"] = species

	var/list/skill_data = list()
	for(var/skill_id in GLOB.all_rw_skills)
		var/datum/rw_skill/skill = GLOB.all_rw_skills[skill_id]
		skill_data += list(list(
			"id" = skill.id,
			"name" = skill.name,
			"desc" = skill.desc,
			"editable" = skill.editable,
		))
	data["skillDefs"] = skill_data

	var/list/gene_data = list()
	for(var/gene_id in GLOB.all_rw_xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		gene_data += list(list(
			"id" = gene.id,
			"name" = gene.name,
			"desc" = gene.desc,
			"category" = gene.category,
			"supportedSpecies" = gene.supported_species || list(),
		))
	data["xenogeneDefs"] = gene_data

	var/list/childhoods = list()
	var/list/adulthoods = list()
	for(var/story_id in GLOB.all_rw_backstories)
		var/datum/rw_backstory/story = GLOB.all_rw_backstories[story_id]
		var/list/entry = list(
			"id" = story.id,
			"name" = story.name,
			"desc" = story.desc,
		)
		if(story.slot == RW_BACKSTORY_CHILDHOOD)
			childhoods += list(entry)
		else
			adulthoods += list(entry)
	data["childhoods"] = childhoods
	data["adulthoods"] = adulthoods

	var/list/trait_data = list()
	for(var/trait_id in GLOB.all_rw_traits)
		var/datum/rw_trait/trait = GLOB.all_rw_traits[trait_id]
		trait_data += list(list(
			"id" = trait.id,
			"name" = trait.name,
			"desc" = trait.desc,
			"cost" = trait.cost,
			"positive" = trait.positive,
		))
	data["traitDefs"] = trait_data

	var/list/loadout_data = list()
	for(var/item_id in GLOB.all_rw_loadout)
		var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
		loadout_data += list(list(
			"id" = item.id,
			"name" = item.name,
			"desc" = item.desc,
			"cost" = item.cost,
		))
	data["loadoutDefs"] = loadout_data
	data["characterPreviewView"] = character_preview_view?.assigned_map
	return data

/datum/rimworld_preferences/ui_data(mob/user)
	var/list/data = list()
	data["profiles"] = create_character_profiles()
	data["activeSlot"] = default_slot
	data["active_slot"] = default_slot
	data["firstName"] = first_name || ""
	data["nickname"] = nickname || ""
	data["lastName"] = last_name || ""
	data["biologicalAge"] = isnum(biological_age) ? biological_age : 21
	data["chronologicalAge"] = isnum(chronological_age) ? chronological_age : 21
	data["realName"] = real_name || ""
	data["gender"] = gender
	data["bodyType"] = body_type
	data["speciesPath"] = "[species_type]"
	data["hairstyle"] = hairstyle
	data["hairColor"] = hair_color
	data["facial"] = facial_hairstyle
	data["facialHairColor"] = facial_hair_color
	data["underwear"] = underwear
	data["underwearColor"] = underwear_color
	data["undershirt"] = undershirt
	data["undershirtColor"] = undershirt_color
	data["bra"] = bra
	data["braColor"] = bra_color
	data["socks"] = socks
	data["socksColor"] = socks_color
	data["jumpsuit"] = jumpsuit_style
	data["backpack"] = backpack
	data["clothing"] = list(
		"hairstyle" = hairstyle,
		"facial" = facial_hairstyle,
		"underwear" = underwear,
		"undershirt" = undershirt,
		"bra" = bra,
		"socks" = socks,
		"jumpsuit" = jumpsuit_style,
		"backpack" = backpack,
	)
	data["clothingColors"] = list(
		"hairstyle" = hair_color,
		"facial" = facial_hair_color,
		"underwear" = underwear_color,
		"undershirt" = undershirt_color,
		"bra" = bra_color,
		"socks" = socks_color,
	)
	data["skinTone"] = skin_tone
	data["mutantColor"] = mutant_color
	data["mutantColor2"] = mutant_color_2
	data["mutantColor3"] = mutant_color_3
	data["eyeColor"] = eye_color
	data["eyeColorRight"] = eye_color_right
	data["hairGradient"] = hair_gradient
	data["hairGradientColor"] = hair_gradient_color
	data["facialGradient"] = facial_gradient
	data["facialGradientColor"] = facial_gradient_color
	data["bodySize"] = body_size
	data["customSpecies"] = custom_species
	data["customSpeciesLore"] = custom_species_lore
	data["flavorText"] = flavor_text
	data["flavorTextNsfw"] = flavor_text_nsfw
	data["oocNotes"] = ooc_notes
	data["headshot"] = headshot
	data["characterScream"] = character_scream
	data["characterLaugh"] = character_laugh
	data["chatColor"] = chat_color
	data["blooperChoice"] = blooper_choice
	data["blooperSpeed"] = blooper_speed
	data["blooperPitch"] = blooper_pitch
	data["blooperPitchRange"] = blooper_pitch_range
	data["customTaste"] = custom_taste
	data["customSmell"] = custom_smell
	data["generalRecord"] = general_record
	data["medicalRecord"] = medical_record
	data["securityRecord"] = security_record
	data["exploitableInfo"] = exploitable_info
	data["backgroundInfo"] = background_info
	data["tattoo"] = tattoo
	data["xenogenes"] = xenogenes
	data["childhood"] = childhood_id
	data["adulthood"] = adulthood_id
	data["traits"] = traits
	data["loadout"] = loadout
	data["usesSkintones"] = uses_skintones()
	data["budgetSpent"] = points_spent()
	data["budgetRemaining"] = points_remaining()

	var/list/skill_rows = list()
	for(var/skill_id in GLOB.all_rw_skills)
		skill_rows += list(list(
			"id" = skill_id,
			"bought" = skills[skill_id] || 0,
			"bonus" = get_skill_bonus(skill_id),
			"level" = get_skill_level(skill_id),
			"passion" = passions[skill_id] || RW_PASSION_NONE,
		))
	data["skills"] = skill_rows
	return data

/datum/rimworld_preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	if(action == "play_blooper")
		return play_character_blooper(user)
	if(handle_pref_act(action, params, user))
		return TRUE
	switch(action)
		if("change_slot")
			var/wanted = text2num(params["slot"])
			if(wanted == default_slot)
				return TRUE
			switch_to_slot(wanted)
			return TRUE
		if("randomize")
			reset_to_defaults()
			preview_dir = SOUTH
			save_character()
			update_preview()
			return TRUE
		if("rotate")
			preview_dir = turn(preview_dir, params["left"] ? 90 : -90)
			if(preview_dummy && !QDELETED(preview_dummy))
				preview_dummy.setDir(preview_dir)
			else
				update_preview()
			return TRUE
		if("set_name")
			var/new_name = reject_bad_name(params["value"])
			if(new_name)
				split_real_name(new_name)
				rebuild_real_name()
				save_character()
			return TRUE
		if("set_first_name")
			var/new_name = reject_bad_name(params["value"])
			if(new_name)
				first_name = new_name
				rebuild_real_name()
				save_character()
			return TRUE
		if("set_nickname")
			if(!length(params["value"]))
				nickname = ""
			else
				nickname = reject_bad_name(params["value"]) || ""
			save_character()
			return TRUE
		if("set_last_name")
			var/new_name = reject_bad_name(params["value"])
			if(new_name)
				last_name = new_name
				rebuild_real_name()
				save_character()
			return TRUE
		if("randomize_names")
			randomize_names()
			save_character()
			return TRUE
		if("set_bio_age")
			biological_age = clamp(text2num(params["value"]) || AGE_MIN, AGE_MIN, AGE_MAX)
			if(chronological_age < biological_age)
				chronological_age = biological_age
			save_character()
			return TRUE
		if("set_chrono_age")
			chronological_age = clamp(text2num(params["value"]) || AGE_MIN, AGE_MIN, AGE_CHRONO_MAX)
			if(chronological_age < biological_age)
				chronological_age = biological_age
			save_character()
			return TRUE
		if("set_gender")
			var/new_gender = params["value"]
			if(new_gender == MALE || new_gender == FEMALE || new_gender == PLURAL || new_gender == NEUTER)
				gender = new_gender
				save_character()
				update_preview()
			return TRUE
		if("set_body_type")
			var/new_body = params["value"]
			if(new_body == "Use gender" || new_body == MALE || new_body == FEMALE)
				body_type = new_body
				save_character()
				update_preview()
			return TRUE
		if("set_species")
			var/new_species = text2path(params["value"])
			if(!(new_species in GLOB.rw_base_species))
				return TRUE
			species_type = new_species
			var/list/kept_genes = list()
			var/datum/species/proto = GLOB.species_prototypes[species_type]
			for(var/gene_id in xenogenes)
				var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
				if(gene?.is_supported(proto?.id))
					kept_genes += gene_id
			xenogenes = kept_genes
			save_character()
			update_preview()
			return TRUE
		if("set_hairstyle")
			return apply_clothing_choice("hairstyle", params["value"])
		if("pick_hair_color")
			return apply_clothing_color(user, "hairstyle")
		if("set_facial")
			return apply_clothing_choice("facial", params["value"])
		if("pick_facial_color")
			return apply_clothing_color(user, "facial")
		if("set_underwear")
			return apply_clothing_choice("underwear", params["value"])
		if("pick_underwear_color")
			return apply_clothing_color(user, "underwear")
		if("set_undershirt")
			return apply_clothing_choice("undershirt", params["value"])
		if("pick_undershirt_color")
			return apply_clothing_color(user, "undershirt")
		if("set_bra")
			return apply_clothing_choice("bra", params["value"])
		if("pick_bra_color")
			return apply_clothing_color(user, "bra")
		if("set_socks")
			return apply_clothing_choice("socks", params["value"])
		if("pick_socks_color")
			return apply_clothing_color(user, "socks")
		if("set_jumpsuit")
			return apply_clothing_choice("jumpsuit", params["value"])
		if("set_clothing")
			return apply_clothing_choice(params["id"], params["value"])
		if("pick_clothing_color")
			return apply_clothing_color(user, params["id"])
		if("set_hair_color")
			if(params["value"])
				hair_color = params["value"]
				save_character()
				update_preview()
			return TRUE
		if("set_skin_tone")
			if(params["value"] in GLOB.skin_tones)
				skin_tone = params["value"]
				save_character()
				update_preview()
			return TRUE
		if("pick_mutant_color")
			return pick_detail_color(user, "mutant_color")
		if("set_detail")
			return set_detail_field(params["id"], params["value"])
		if("pick_detail_color")
			return pick_detail_color(user, params["id"])
		if("set_tattoo")
			tattoo = params["value"] || "None"
			save_character()
			return TRUE
		if("toggle_xenogene")
			var/gene_id = params["id"]
			var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
			if(!gene)
				return TRUE
			var/datum/species/proto = GLOB.species_prototypes[species_type]
			if(!gene.is_supported(proto?.id))
				return TRUE
			if(gene_id in xenogenes)
				xenogenes -= gene_id
			else
				xenogenes += gene_id
			save_character()
			update_preview()
			return TRUE
		if("set_childhood")
			var/datum/rw_backstory/story = GLOB.all_rw_backstories[params["id"]]
			if(story && story.slot == RW_BACKSTORY_CHILDHOOD)
				childhood_id = story.id
				save_character()
				update_preview()
			return TRUE
		if("set_adulthood")
			var/datum/rw_backstory/story = GLOB.all_rw_backstories[params["id"]]
			if(story && story.slot == RW_BACKSTORY_ADULTHOOD)
				adulthood_id = story.id
				save_character()
				update_preview()
			return TRUE
		if("adjust_skill")
			var/skill_id = params["id"]
			var/datum/rw_skill/skill = GLOB.all_rw_skills[skill_id]
			if(!skill?.editable)
				return TRUE
			var/delta = text2num(params["delta"]) || 0
			var/current = skills[skill_id] || 0
			var/wanted = clamp(current + delta, RW_SKILL_MIN, RW_SKILL_MANUAL_MAX)
			if(wanted > current && !can_afford((wanted - current) * RW_SKILL_LEVEL_COST))
				return TRUE
			skills[skill_id] = wanted
			save_character()
			return TRUE
		if("cycle_passion")
			var/skill_id = params["id"]
			if(!(skill_id in GLOB.all_rw_skills))
				return TRUE
			var/current = passions[skill_id] || RW_PASSION_NONE
			passions[skill_id] = (current + 1) % 3
			save_character()
			return TRUE
		if("toggle_trait")
			var/trait_id = params["id"]
			var/datum/rw_trait/trait = GLOB.all_rw_traits[trait_id]
			if(!trait)
				return TRUE
			if(trait_id in traits)
				traits -= trait_id
			else if(can_afford(trait.cost))
				traits += trait_id
			save_character()
			return TRUE
		if("toggle_loadout")
			var/item_id = params["id"]
			var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
			if(!item)
				return TRUE
			if(item_id in loadout)
				loadout -= item_id
			else if(can_afford(item.cost))
				loadout += item_id
			save_character()
			update_preview()
			return TRUE
	return FALSE

/datum/rimworld_preferences/proc/resolve_list_choice(list/choices, value)
	if(!islist(choices) || isnull(value))
		return null
	value = "[value]"
	if(!value)
		return null
	if(choices[value])
		return value
	if(value in choices)
		return value
	var/suffix = value
	var/split_at = findlasttext(value, "___")
	if(split_at)
		suffix = copytext(value, split_at + 3)
		if(choices[suffix])
			return suffix
	var/value_lower = lowertext(value)
	var/suffix_lower = lowertext(suffix)
	var/value_css = lowertext(sanitize_css_class_name(value))
	var/suffix_css = lowertext(sanitize_css_class_name(suffix))
	for(var/choice_name in choices)
		var/as_text = "[choice_name]"
		if(as_text == value || as_text == suffix)
			return choice_name
		var/as_lower = lowertext(as_text)
		if(as_lower == value_lower || as_lower == suffix_lower)
			return choice_name
		var/as_css = lowertext(sanitize_css_class_name(as_text))
		if(as_css == value_css || as_css == suffix_css)
			return choice_name
		if(replacetext(as_lower, " ", "_") == suffix_lower)
			return choice_name
	return null

/datum/rimworld_preferences/proc/apply_clothing_choice(id, value)
	id = "[id]"
	value = "[value]"
	if(!length(id) || !length(value))
		return TRUE
	var/resolved
	switch(id)
		if("hairstyle")
			resolved = resolve_list_choice(SSaccessories.hairstyles_list, value)
			if(!resolved)
				return TRUE
			hairstyle = resolved
		if("facial")
			resolved = resolve_list_choice(SSaccessories.facial_hairstyles_list, value)
			if(!resolved)
				return TRUE
			facial_hairstyle = resolved
		if("underwear")
			resolved = resolve_list_choice(SSaccessories.underwear_list, value)
			if(!resolved)
				return TRUE
			underwear = resolved
		if("undershirt")
			resolved = resolve_list_choice(SSaccessories.undershirt_list, value)
			if(!resolved)
				return TRUE
			undershirt = resolved
		if("bra")
			resolved = resolve_list_choice(SSaccessories.bra_list, value)
			if(!resolved)
				return TRUE
			bra = resolved
		if("socks")
			resolved = resolve_list_choice(SSaccessories.socks_list, value)
			if(!resolved)
				return TRUE
			socks = resolved
		if("jumpsuit")
			if(value != PREF_SUIT && value != PREF_SKIRT)
				return TRUE
			jumpsuit_style = value
		if("backpack")
			var/datum/preference/choiced/backpack/bag_pref = GLOB.preference_entries[/datum/preference/choiced/backpack]
			if(!(bag_pref && (value in bag_pref.get_choices())))
				return TRUE
			backpack = value
		else
			return TRUE
	save_character()
	update_preview()
	return TRUE

/datum/rimworld_preferences/proc/apply_clothing_color(mob/user, id)
	id = "[id]"
	if(!length(id) || !user)
		return TRUE
	var/current
	var/title
	switch(id)
		if("hairstyle")
			current = hair_color
			title = "Hair color"
		if("facial")
			current = facial_hair_color
			title = "Facial hair color"
		if("underwear")
			current = underwear_color
			title = "Underwear color"
		if("undershirt")
			current = undershirt_color
			title = "Undershirt color"
		if("bra")
			current = bra_color
			title = "Bra color"
		if("socks")
			current = socks_color
			title = "Socks color"
		else
			return TRUE
	var/new_color = input(user, title, "Prepare Colonist", current) as color|null
	if(!new_color)
		return TRUE
	switch(id)
		if("hairstyle")
			hair_color = new_color
		if("facial")
			facial_hair_color = new_color
		if("underwear")
			underwear_color = new_color
		if("undershirt")
			undershirt_color = new_color
		if("bra")
			bra_color = new_color
		if("socks")
			socks_color = new_color
		else
			return TRUE
	save_character()
	update_preview()
	return TRUE

/datum/rimworld_preferences/proc/detail_needs_preview(id)
	switch(id)
		if("skin_tone", "mutant_color", "mutant_color_2", "mutant_color_3", "eye_color", "eye_color_right", "hair_gradient", "hair_gradient_color", "facial_gradient", "facial_gradient_color", "body_size")
			return TRUE
	return FALSE

/datum/rimworld_preferences/proc/set_detail_field(id, value)
	id = "[id]"
	switch(id)
		if("skin_tone")
			if(!(value in GLOB.skin_tones))
				return TRUE
			skin_tone = value
		if("mutant_color")
			mutant_color = sanitize_hexcolor(value, 6, TRUE, mutant_color)
		if("mutant_color_2")
			mutant_color_2 = sanitize_hexcolor(value, 6, TRUE, mutant_color_2)
		if("mutant_color_3")
			mutant_color_3 = sanitize_hexcolor(value, 6, TRUE, mutant_color_3)
		if("eye_color")
			eye_color = sanitize_hexcolor(value, 6, TRUE, eye_color)
		if("eye_color_right")
			if(!length(value))
				eye_color_right = ""
			else
				eye_color_right = sanitize_hexcolor(value, 6, TRUE, eye_color_right)
		if("hair_gradient")
			if(SSaccessories.hair_gradients_list && !(value in SSaccessories.hair_gradients_list))
				return TRUE
			hair_gradient = value || "None"
		if("hair_gradient_color")
			hair_gradient_color = sanitize_hexcolor(value, 6, TRUE, hair_gradient_color)
		if("facial_gradient")
			if(SSaccessories.facial_hair_gradients_list && !(value in SSaccessories.facial_hair_gradients_list))
				return TRUE
			facial_gradient = value || "None"
		if("facial_gradient_color")
			facial_gradient_color = sanitize_hexcolor(value, 6, TRUE, facial_gradient_color)
		if("body_size")
			body_size = clamp(text2num(value) || 1, BODY_SIZE_MIN, BODY_SIZE_MAX)
		if("custom_species")
			custom_species = copytext_char("[value]", 1, 101)
		if("custom_species_lore")
			custom_species_lore = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("flavor_text")
			flavor_text = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("flavor_text_nsfw")
			flavor_text_nsfw = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("ooc_notes")
			ooc_notes = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("headshot")
			headshot = copytext_char("[value]", 1, MAX_MESSAGE_LEN + 1)
		if("character_scream")
			if(!(value in GLOB.scream_types))
				return TRUE
			character_scream = value
		if("character_laugh")
			if(!(value in GLOB.laugh_types))
				return TRUE
			character_laugh = value
		if("blooper_choice")
			if(!length(SSblooper.blooper_list) || !(value in SSblooper.blooper_list))
				return TRUE
			blooper_choice = value
		if("blooper_speed")
			blooper_speed = clamp(text2num(value), 0, 100)
		if("blooper_pitch")
			blooper_pitch = clamp(text2num(value), 0, 100)
		if("blooper_pitch_range")
			blooper_pitch_range = clamp(text2num(value), 0, 100)
		if("chat_color")
			chat_color = sanitize_hexcolor(value, 6, TRUE, chat_color)
		if("custom_taste")
			custom_taste = copytext_char("[value]", 1, 101)
		if("custom_smell")
			custom_smell = copytext_char("[value]", 1, 101)
		if("general_record")
			general_record = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("medical_record")
			medical_record = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("security_record")
			security_record = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("exploitable_info")
			exploitable_info = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		if("background_info")
			background_info = copytext_char("[value]", 1, MAX_FLAVOR_LEN + 1)
		else
			return TRUE
	save_character()
	if(detail_needs_preview(id))
		update_preview()
	return TRUE

/datum/rimworld_preferences/proc/pick_detail_color(mob/user, id)
	id = "[id]"
	if(!user)
		return TRUE
	var/current
	var/title
	switch(id)
		if("mutant_color")
			current = mutant_color
			title = "Body color"
		if("mutant_color_2")
			current = mutant_color_2
			title = "Body color 2"
		if("mutant_color_3")
			current = mutant_color_3
			title = "Body color 3"
		if("eye_color")
			current = eye_color
			title = "Eye color"
		if("eye_color_right")
			current = eye_color_right || eye_color
			title = "Right eye color"
		if("hair_gradient_color")
			current = hair_gradient_color
			title = "Hair gradient color"
		if("facial_gradient_color")
			current = facial_gradient_color
			title = "Facial gradient color"
		if("chat_color")
			current = chat_color
			title = "Chat color"
		else
			return TRUE
	var/new_color = input(user, title, "Prepare Colonist", current) as color|null
	if(!new_color)
		return TRUE
	return set_detail_field(id, new_color)

/datum/rimworld_preferences/proc/play_character_blooper(mob/user)
	if(!user || !length(SSblooper.blooper_list))
		return TRUE
	var/datum/blooper/voice = SSblooper.blooper_list[blooper_choice]
	if(!voice)
		return TRUE
	voice.play_bloop(user, list(user), "This is a test message to hear a blooper.", 7, 70, blooper_speed, blooper_pitch, blooper_pitch_range)
	return TRUE
