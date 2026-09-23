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
	data["biologicalAge"] = rw_pref(/datum/preference/numeric/age) || 21
	data["chronologicalAge"] = rw_pref(/datum/preference/numeric/chronological_age)
	if(!isnum(data["chronologicalAge"]))
		data["chronologicalAge"] = data["biologicalAge"]
	data["realName"] = real_name || ""
	data["gender"] = rw_gender()
	data["bodyType"] = rw_pref(/datum/preference/choiced/body_type) || USE_GENDER
	data["speciesPath"] = "[rw_species()]"
	data["hairstyle"] = rw_pref(/datum/preference/choiced/hairstyle) || "Bald"
	data["hairColor"] = rw_hex(/datum/preference/color/hair_color, "#4a3728")
	data["facial"] = rw_pref(/datum/preference/choiced/facial_hairstyle) || "Shaved"
	data["facialHairColor"] = rw_hex(/datum/preference/color/facial_hair_color, data["hairColor"])
	data["underwear"] = rw_pref(/datum/preference/choiced/underwear) || "Nude"
	data["underwearColor"] = rw_hex(/datum/preference/color/underwear_color)
	data["undershirt"] = rw_pref(/datum/preference/choiced/undershirt) || "Nude"
	data["undershirtColor"] = rw_hex(/datum/preference/color/undershirt_color)
	data["bra"] = rw_pref(/datum/preference/choiced/bra) || "Nude"
	data["braColor"] = rw_hex(/datum/preference/color/bra_color)
	data["socks"] = rw_pref(/datum/preference/choiced/socks) || "Nude"
	data["socksColor"] = rw_hex(/datum/preference/color/socks_color)
	data["jumpsuit"] = rw_pref(/datum/preference/choiced/jumpsuit) || PREF_SUIT
	data["backpack"] = rw_pref(/datum/preference/choiced/backpack) || DBACKPACK
	data["clothing"] = list(
		"hairstyle" = data["hairstyle"],
		"facial" = data["facial"],
		"underwear" = data["underwear"],
		"undershirt" = data["undershirt"],
		"bra" = data["bra"],
		"socks" = data["socks"],
		"jumpsuit" = data["jumpsuit"],
		"backpack" = data["backpack"],
	)
	data["clothingColors"] = list(
		"hairstyle" = data["hairColor"],
		"facial" = data["facialHairColor"],
		"underwear" = data["underwearColor"],
		"undershirt" = data["undershirtColor"],
		"bra" = data["braColor"],
		"socks" = data["socksColor"],
	)
	data["skinTone"] = rw_pref(/datum/preference/choiced/skin_tone) || "caucasian1"
	var/list/mutant_colors = rw_pref(/datum/preference/tri_color/mutant_colors)
	if(!islist(mutant_colors) || length(mutant_colors) < 3)
		mutant_colors = list("#c0965f", "#c0965f", "#c0965f")
	data["mutantColor"] = mutant_colors[1]
	data["mutantColor2"] = mutant_colors[2]
	data["mutantColor3"] = mutant_colors[3]
	data["eyeColor"] = rw_hex(/datum/preference/color/eye_color, "#336699")
	data["eyeColorRight"] = rw_hex(/datum/preference/color/heterochromatic, "")
	data["hairGradient"] = rw_pref(/datum/preference/choiced/hair_gradient) || "None"
	data["hairGradientColor"] = rw_hex(/datum/preference/color/hair_gradient)
	data["facialGradient"] = rw_pref(/datum/preference/choiced/facial_hair_gradient) || "None"
	data["facialGradientColor"] = rw_hex(/datum/preference/color/facial_hair_gradient)
	data["bodySize"] = rw_pref(/datum/preference/numeric/body_size) || 1
	data["customSpecies"] = rw_pref(/datum/preference/text/custom_species) || ""
	data["customSpeciesLore"] = rw_pref(/datum/preference/text/custom_species_lore) || ""
	data["flavorText"] = rw_pref(/datum/preference/text/flavor_text) || ""
	data["flavorTextNsfw"] = rw_pref(/datum/preference/text/flavor_text_nsfw) || ""
	data["oocNotes"] = rw_pref(/datum/preference/text/ooc_notes) || ""
	data["headshot"] = rw_pref(/datum/preference/text/headshot) || ""
	data["characterScream"] = rw_pref(/datum/preference/choiced/scream) || "Human Scream"
	data["characterLaugh"] = rw_pref(/datum/preference/choiced/laugh) || "Human Laugh"
	data["chatColor"] = rw_hex(/datum/preference/color/chat_color, "#b0b0b0")
	data["blooperChoice"] = rw_pref(/datum/preference/choiced/blooper) || default_blooper_id()
	data["blooperSpeed"] = rw_pref(/datum/preference/numeric/blooper_speed)
	if(!isnum(data["blooperSpeed"]))
		data["blooperSpeed"] = 50
	data["blooperPitch"] = rw_pref(/datum/preference/numeric/blooper_pitch)
	if(!isnum(data["blooperPitch"]))
		data["blooperPitch"] = 50
	data["blooperPitchRange"] = rw_pref(/datum/preference/numeric/blooper_pitch_range)
	if(!isnum(data["blooperPitchRange"]))
		data["blooperPitchRange"] = 30
	data["customTaste"] = rw_pref(/datum/preference/text/taste) || ""
	data["customSmell"] = rw_pref(/datum/preference/text/smell) || ""
	data["generalRecord"] = rw_pref(/datum/preference/text/general) || ""
	data["medicalRecord"] = rw_pref(/datum/preference/text/medical) || ""
	data["securityRecord"] = rw_pref(/datum/preference/text/security) || ""
	data["exploitableInfo"] = rw_pref(/datum/preference/text/exploitable) || ""
	data["backgroundInfo"] = rw_pref(/datum/preference/text/background) || ""
	data["tattoo"] = tattoo
	data["character_preferences"] = compile_character_pref_ui(user)
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
			rw_set_pref(/datum/preference/numeric/age, clamp(text2num(params["value"]) || AGE_MIN, AGE_MIN, AGE_MAX), force = TRUE)
			var/bio_age = rw_pref(/datum/preference/numeric/age)
			if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
				var/chrono_age = rw_pref(/datum/preference/numeric/chronological_age)
				if(!isnum(chrono_age) || chrono_age < bio_age)
					rw_set_pref(/datum/preference/numeric/chronological_age, bio_age, force = TRUE)
			save_character()
			return TRUE
		if("set_chrono_age")
			if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
				var/bio_age = rw_pref(/datum/preference/numeric/age) || AGE_MIN
				rw_set_pref(/datum/preference/numeric/chronological_age, clamp(max(text2num(params["value"]) || bio_age, bio_age), AGE_MIN, AGE_CHRONO_MAX), force = TRUE)
			save_character()
			return TRUE
		if("set_gender")
			var/new_gender = params["value"]
			if(new_gender == MALE || new_gender == FEMALE || new_gender == PLURAL || new_gender == NEUTER)
				rw_set_pref(/datum/preference/choiced/gender, new_gender, force = TRUE)
				save_character()
				update_preview()
			return TRUE
		if("set_body_type")
			var/new_body = params["value"]
			if(new_body == USE_GENDER || new_body == MALE || new_body == FEMALE)
				rw_set_pref(/datum/preference/choiced/body_type, new_body, force = TRUE)
				save_character()
				update_preview()
			return TRUE
		if("set_species")
			var/new_species = text2path(params["value"])
			if(!rw_set_species(new_species))
				return TRUE
			var/list/kept_genes = list()
			var/datum/species/proto = GLOB.species_prototypes[rw_species()]
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
				rw_set_pref(/datum/preference/color/hair_color, params["value"], force = TRUE)
				save_character()
				update_preview()
			return TRUE
		if("set_skin_tone")
			if(params["value"] in GLOB.skin_tones)
				rw_set_pref(/datum/preference/choiced/skin_tone, params["value"], force = TRUE)
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
			var/datum/species/proto = GLOB.species_prototypes[rw_species()]
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

/datum/rimworld_preferences/proc/clothing_choice_pref(id)
	switch(id)
		if("hairstyle")
			return /datum/preference/choiced/hairstyle
		if("facial")
			return /datum/preference/choiced/facial_hairstyle
		if("underwear")
			return /datum/preference/choiced/underwear
		if("undershirt")
			return /datum/preference/choiced/undershirt
		if("bra")
			return /datum/preference/choiced/bra
		if("socks")
			return /datum/preference/choiced/socks
		if("jumpsuit")
			return /datum/preference/choiced/jumpsuit
		if("backpack")
			return /datum/preference/choiced/backpack
	return null

/datum/rimworld_preferences/proc/clothing_color_pref(id)
	switch(id)
		if("hairstyle")
			return /datum/preference/color/hair_color
		if("facial")
			return /datum/preference/color/facial_hair_color
		if("underwear")
			return /datum/preference/color/underwear_color
		if("undershirt")
			return /datum/preference/color/undershirt_color
		if("bra")
			return /datum/preference/color/bra_color
		if("socks")
			return /datum/preference/color/socks_color
	return null

/datum/rimworld_preferences/proc/clothing_choice_list(id)
	switch(id)
		if("hairstyle")
			return SSaccessories.hairstyles_list
		if("facial")
			return SSaccessories.facial_hairstyles_list
		if("underwear")
			return SSaccessories.underwear_list
		if("undershirt")
			return SSaccessories.undershirt_list
		if("bra")
			return SSaccessories.bra_list
		if("socks")
			return SSaccessories.socks_list
	return null

/datum/rimworld_preferences/proc/apply_clothing_choice(id, value)
	id = "[id]"
	value = "[value]"
	if(!length(id) || !length(value))
		return TRUE
	var/preference_type = clothing_choice_pref(id)
	if(!preference_type)
		return TRUE
	var/list/choices = clothing_choice_list(id)
	var/resolved = choices ? resolve_list_choice(choices, value) : value
	if(!resolved)
		return TRUE
	if(!rw_set_pref(preference_type, resolved, force = TRUE))
		return TRUE
	save_character()
	update_preview()
	return TRUE

/datum/rimworld_preferences/proc/apply_clothing_color(mob/user, id)
	id = "[id]"
	var/preference_type = clothing_color_pref(id)
	if(!length(id) || !user || !preference_type)
		return TRUE
	var/current = rw_hex(preference_type)
	var/new_color = input(user, "Select color", "Prepare Colonist", current) as color|null
	if(!new_color)
		return TRUE
	rw_set_pref(preference_type, new_color, force = TRUE)
	save_character()
	update_preview()
	return TRUE

/datum/rimworld_preferences/proc/detail_needs_preview(id)
	switch(id)
		if("skin_tone", "mutant_color", "mutant_color_2", "mutant_color_3", "eye_color", "eye_color_right", "hair_gradient", "hair_gradient_color", "facial_gradient", "facial_gradient_color", "body_size")
			return TRUE
	return FALSE

/datum/rimworld_preferences/proc/set_mutant_color_index(index, value)
	var/list/colors = rw_pref(/datum/preference/tri_color/mutant_colors)
	if(!islist(colors) || length(colors) < 3)
		colors = list("#c0965f", "#c0965f", "#c0965f")
	else
		colors = colors.Copy()
	colors[index] = sanitize_hexcolor(value, 6, TRUE, colors[index])
	rw_set_pref(/datum/preference/tri_color/mutant_colors, colors, force = TRUE)

/datum/rimworld_preferences/proc/detail_pref_type(id)
	switch(id)
		if("skin_tone")
			return /datum/preference/choiced/skin_tone
		if("eye_color")
			return /datum/preference/color/eye_color
		if("eye_color_right")
			return /datum/preference/color/heterochromatic
		if("hair_gradient")
			return /datum/preference/choiced/hair_gradient
		if("hair_gradient_color")
			return /datum/preference/color/hair_gradient
		if("facial_gradient")
			return /datum/preference/choiced/facial_hair_gradient
		if("facial_gradient_color")
			return /datum/preference/color/facial_hair_gradient
		if("body_size")
			return /datum/preference/numeric/body_size
		if("custom_species")
			return /datum/preference/text/custom_species
		if("custom_species_lore")
			return /datum/preference/text/custom_species_lore
		if("flavor_text")
			return /datum/preference/text/flavor_text
		if("flavor_text_nsfw")
			return /datum/preference/text/flavor_text_nsfw
		if("ooc_notes")
			return /datum/preference/text/ooc_notes
		if("headshot")
			return /datum/preference/text/headshot
		if("character_scream")
			return /datum/preference/choiced/scream
		if("character_laugh")
			return /datum/preference/choiced/laugh
		if("blooper_choice")
			return /datum/preference/choiced/blooper
		if("blooper_speed")
			return /datum/preference/numeric/blooper_speed
		if("blooper_pitch")
			return /datum/preference/numeric/blooper_pitch
		if("blooper_pitch_range")
			return /datum/preference/numeric/blooper_pitch_range
		if("chat_color")
			return /datum/preference/color/chat_color
		if("custom_taste")
			return /datum/preference/text/taste
		if("custom_smell")
			return /datum/preference/text/smell
		if("general_record")
			return /datum/preference/text/general
		if("medical_record")
			return /datum/preference/text/medical
		if("security_record")
			return /datum/preference/text/security
		if("exploitable_info")
			return /datum/preference/text/exploitable
		if("background_info")
			return /datum/preference/text/background
	return null

/datum/rimworld_preferences/proc/set_detail_field(id, value)
	id = "[id]"
	switch(id)
		if("mutant_color")
			set_mutant_color_index(1, value)
		if("mutant_color_2")
			set_mutant_color_index(2, value)
		if("mutant_color_3")
			set_mutant_color_index(3, value)
		else
			var/preference_type = detail_pref_type(id)
			if(!preference_type)
				return TRUE
			if(!rw_set_pref(preference_type, value, force = TRUE))
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
	var/list/mutant_colors = rw_pref(/datum/preference/tri_color/mutant_colors)
	if(!islist(mutant_colors) || length(mutant_colors) < 3)
		mutant_colors = list("#c0965f", "#c0965f", "#c0965f")
	switch(id)
		if("mutant_color")
			current = mutant_colors[1]
			title = "Body color"
		if("mutant_color_2")
			current = mutant_colors[2]
			title = "Body color 2"
		if("mutant_color_3")
			current = mutant_colors[3]
			title = "Body color 3"
		if("eye_color")
			current = rw_hex(/datum/preference/color/eye_color, "#336699")
			title = "Eye color"
		if("eye_color_right")
			current = rw_hex(/datum/preference/color/heterochromatic, rw_hex(/datum/preference/color/eye_color, "#336699"))
			title = "Right eye color"
		if("hair_gradient_color")
			current = rw_hex(/datum/preference/color/hair_gradient)
			title = "Hair gradient color"
		if("facial_gradient_color")
			current = rw_hex(/datum/preference/color/facial_hair_gradient)
			title = "Facial gradient color"
		if("chat_color")
			current = rw_hex(/datum/preference/color/chat_color, "#b0b0b0")
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
	var/choice = rw_pref(/datum/preference/choiced/blooper)
	var/datum/blooper/voice = SSblooper.blooper_list[choice]
	if(!voice)
		return TRUE
	var/speed = rw_pref(/datum/preference/numeric/blooper_speed)
	var/pitch = rw_pref(/datum/preference/numeric/blooper_pitch)
	var/range = rw_pref(/datum/preference/numeric/blooper_pitch_range)
	voice.play_bloop(user, list(user), "This is a test message to hear a blooper.", 7, 70, isnum(speed) ? speed : 50, isnum(pitch) ? pitch : 50, isnum(range) ? range : 30)
	return TRUE
