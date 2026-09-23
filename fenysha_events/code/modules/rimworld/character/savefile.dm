/datum/rimworld_preferences/proc/load_path(ckey, filename = "rimworld_preferences.json")
	if(!ckey || !load_and_save)
		return
	path = "data/player_saves/[ckey[1]]/[ckey]/[filename]"

/datum/rimworld_preferences/proc/load_savefile()
	savefile = new /datum/json_savefile(load_and_save ? path : null)

/datum/rimworld_preferences/proc/load_preferences()
	if(!savefile)
		load_savefile()
	if(!savefile)
		return FALSE
	savefile.load()
	default_slot = savefile.get_entry("default_slot", 1)
	return TRUE

/datum/rimworld_preferences/proc/save_preferences()
	if(!load_and_save || !savefile)
		return
	savefile.set_entry("version", RW_CHARACTER_SAVE_VERSION)
	savefile.set_entry("default_slot", default_slot)
	savefile.save()

/datum/rimworld_preferences/proc/slot_key(slot)
	return "character[slot]"

/datum/rimworld_preferences/proc/serialize_character()
	return list(
		"version" = RW_CHARACTER_SAVE_VERSION,
		"real_name" = real_name,
		"first_name" = first_name,
		"nickname" = nickname,
		"last_name" = last_name,
		"biological_age" = biological_age,
		"chronological_age" = chronological_age,
		"gender" = gender,
		"body_type" = body_type,
		"species" = "[species_type]",
		"hairstyle" = hairstyle,
		"hair_color" = hair_color,
		"facial_hairstyle" = facial_hairstyle,
		"facial_hair_color" = facial_hair_color,
		"underwear" = underwear,
		"underwear_color" = underwear_color,
		"undershirt" = undershirt,
		"undershirt_color" = undershirt_color,
		"bra" = bra,
		"bra_color" = bra_color,
		"socks" = socks,
		"socks_color" = socks_color,
		"jumpsuit_style" = jumpsuit_style,
		"backpack" = backpack,
		"skin_tone" = skin_tone,
		"mutant_color" = mutant_color,
		"mutant_color_2" = mutant_color_2,
		"mutant_color_3" = mutant_color_3,
		"eye_color" = eye_color,
		"eye_color_right" = eye_color_right,
		"hair_gradient" = hair_gradient,
		"hair_gradient_color" = hair_gradient_color,
		"facial_gradient" = facial_gradient,
		"facial_gradient_color" = facial_gradient_color,
		"body_size" = body_size,
		"custom_species" = custom_species,
		"custom_species_lore" = custom_species_lore,
		"flavor_text" = flavor_text,
		"flavor_text_nsfw" = flavor_text_nsfw,
		"ooc_notes" = ooc_notes,
		"headshot" = headshot,
		"character_scream" = character_scream,
		"character_laugh" = character_laugh,
		"chat_color" = chat_color,
		"blooper_choice" = blooper_choice,
		"blooper_speed" = blooper_speed,
		"blooper_pitch" = blooper_pitch,
		"blooper_pitch_range" = blooper_pitch_range,
		"custom_taste" = custom_taste,
		"custom_smell" = custom_smell,
		"general_record" = general_record,
		"medical_record" = medical_record,
		"security_record" = security_record,
		"exploitable_info" = exploitable_info,
		"background_info" = background_info,
		"tattoo" = tattoo,
		"xenogenes" = xenogenes?.Copy() || list(),
		"childhood" = childhood_id,
		"adulthood" = adulthood_id,
		"skills" = skills?.Copy() || list(),
		"passions" = passions?.Copy() || list(),
		"traits" = traits?.Copy() || list(),
		"loadout" = loadout?.Copy() || list(),
	) + export_pref_bridge()

/datum/rimworld_preferences/proc/deserialize_character(list/data)
	if(!data)
		reset_to_defaults()
		return FALSE
	if(data["first_name"] || data["last_name"])
		first_name = data["first_name"] || ""
		last_name = data["last_name"] || ""
		nickname = data["nickname"] || ""
		rebuild_real_name()
	else
		split_real_name(data["real_name"] || real_name)
		nickname = data["nickname"] || ""
		rebuild_real_name()
	if(!length(first_name) && !length(last_name) && length(data["real_name"] || real_name))
		split_real_name(data["real_name"] || real_name)
		rebuild_real_name()
	biological_age = text2num(data["biological_age"]) || AGE_MIN
	chronological_age = text2num(data["chronological_age"]) || biological_age
	gender = data["gender"] || MALE
	body_type = data["body_type"] || "Use gender"
	var/species_path = text2path(data["species"])
	if(ispath(species_path, /datum/species) && (species_path in GLOB.rw_base_species))
		species_type = species_path
	else
		species_type = /datum/species/human
	hairstyle = data["hairstyle"] || "Bald"
	hair_color = data["hair_color"] || "#4a3728"
	facial_hairstyle = data["facial_hairstyle"] || "Shaved"
	facial_hair_color = data["facial_hair_color"] || hair_color
	underwear = data["underwear"] || "Nude"
	underwear_color = data["underwear_color"] || "#ffffff"
	undershirt = data["undershirt"] || "Nude"
	undershirt_color = data["undershirt_color"] || "#ffffff"
	bra = data["bra"] || "Nude"
	bra_color = data["bra_color"] || "#ffffff"
	socks = data["socks"] || "Nude"
	socks_color = data["socks_color"] || "#ffffff"
	jumpsuit_style = data["jumpsuit_style"] || PREF_SUIT
	backpack = data["backpack"] || DBACKPACK
	skin_tone = data["skin_tone"] || "caucasian1"
	mutant_color = data["mutant_color"] || "#c0965f"
	mutant_color_2 = data["mutant_color_2"] || mutant_color
	mutant_color_3 = data["mutant_color_3"] || mutant_color
	eye_color = data["eye_color"] || random_eye_color()
	eye_color_right = data["eye_color_right"] || ""
	hair_gradient = data["hair_gradient"] || "None"
	hair_gradient_color = data["hair_gradient_color"] || "#ffffff"
	facial_gradient = data["facial_gradient"] || "None"
	facial_gradient_color = data["facial_gradient_color"] || "#ffffff"
	body_size = text2num(data["body_size"]) || 1
	custom_species = data["custom_species"] || ""
	custom_species_lore = data["custom_species_lore"] || ""
	flavor_text = data["flavor_text"] || ""
	flavor_text_nsfw = data["flavor_text_nsfw"] || ""
	ooc_notes = data["ooc_notes"] || ""
	headshot = data["headshot"] || ""
	character_scream = data["character_scream"] || "Human Scream"
	character_laugh = data["character_laugh"] || "Human Laugh"
	chat_color = data["chat_color"] || "#b0b0b0"
	blooper_choice = data["blooper_choice"] || default_blooper_id()
	blooper_speed = text2num(data["blooper_speed"])
	if(isnull(blooper_speed))
		blooper_speed = 50
	blooper_pitch = text2num(data["blooper_pitch"])
	if(isnull(blooper_pitch))
		blooper_pitch = 50
	blooper_pitch_range = text2num(data["blooper_pitch_range"])
	if(isnull(blooper_pitch_range))
		blooper_pitch_range = 30
	custom_taste = data["custom_taste"] || ""
	custom_smell = data["custom_smell"] || ""
	general_record = data["general_record"] || ""
	medical_record = data["medical_record"] || ""
	security_record = data["security_record"] || ""
	exploitable_info = data["exploitable_info"] || ""
	background_info = data["background_info"] || ""
	tattoo = data["tattoo"] || "None"
	xenogenes = data["xenogenes"]?.Copy() || list()
	childhood_id = data["childhood"] || "childhood_none"
	adulthood_id = data["adulthood"] || "adulthood_none"
	skills = data["skills"]?.Copy() || list()
	passions = data["passions"]?.Copy() || list()
	traits = data["traits"]?.Copy() || list()
	loadout = data["loadout"]?.Copy() || list()
	for(var/skill_id in GLOB.all_rw_skills)
		if(!(skill_id in skills))
			skills[skill_id] = 0
		if(!(skill_id in passions))
			passions[skill_id] = RW_PASSION_NONE
	sanitize_character()
	import_pref_bridge(data)
	return TRUE

/datum/rimworld_preferences/proc/sanitize_character()
	first_name = reject_bad_name(first_name) || first_name
	last_name = reject_bad_name(last_name) || last_name
	if(length(nickname))
		nickname = reject_bad_name(nickname) || ""
	rebuild_real_name()
	if(!length(first_name) && length(real_name))
		split_real_name(real_name)
		rebuild_real_name()
	if(!length(real_name))
		split_real_name(generate_random_name(gender, unique = TRUE))
		rebuild_real_name()
	biological_age = clamp(biological_age, AGE_MIN, AGE_MAX)
	chronological_age = clamp(max(chronological_age, biological_age), AGE_MIN, AGE_CHRONO_MAX)
	if(gender != MALE && gender != FEMALE && gender != PLURAL && gender != NEUTER)
		gender = MALE
	if(body_type != "Use gender" && body_type != MALE && body_type != FEMALE)
		body_type = "Use gender"
	if(!(species_type in GLOB.rw_base_species))
		species_type = /datum/species/human
	if(SSaccessories.hairstyles_list && !(hairstyle in SSaccessories.hairstyles_list))
		hairstyle = "Bald"
	if(SSaccessories.facial_hairstyles_list && !(facial_hairstyle in SSaccessories.facial_hairstyles_list))
		facial_hairstyle = "Shaved"
	if(SSaccessories.underwear_list && !(underwear in SSaccessories.underwear_list))
		underwear = "Nude"
	if(SSaccessories.undershirt_list && !(undershirt in SSaccessories.undershirt_list))
		undershirt = "Nude"
	if(SSaccessories.bra_list && !(bra in SSaccessories.bra_list))
		bra = "Nude"
	if(SSaccessories.socks_list && !(socks in SSaccessories.socks_list))
		socks = "Nude"
	if(jumpsuit_style != PREF_SUIT && jumpsuit_style != PREF_SKIRT)
		jumpsuit_style = PREF_SUIT
	eye_color = sanitize_hexcolor(eye_color, 6, TRUE, random_eye_color())
	if(length(eye_color_right))
		eye_color_right = sanitize_hexcolor(eye_color_right, 6, TRUE, "")
	mutant_color = sanitize_hexcolor(mutant_color, 6, TRUE, "#c0965f")
	mutant_color_2 = sanitize_hexcolor(mutant_color_2, 6, TRUE, mutant_color)
	mutant_color_3 = sanitize_hexcolor(mutant_color_3, 6, TRUE, mutant_color)
	hair_gradient_color = sanitize_hexcolor(hair_gradient_color, 6, TRUE, "#ffffff")
	facial_gradient_color = sanitize_hexcolor(facial_gradient_color, 6, TRUE, "#ffffff")
	if(SSaccessories.hair_gradients_list && !(hair_gradient in SSaccessories.hair_gradients_list))
		hair_gradient = "None"
	if(SSaccessories.facial_hair_gradients_list && !(facial_gradient in SSaccessories.facial_hair_gradients_list))
		facial_gradient = "None"
	body_size = clamp(body_size, BODY_SIZE_MIN, BODY_SIZE_MAX)
	custom_species = copytext_char("[custom_species]", 1, 101)
	custom_taste = copytext_char("[custom_taste]", 1, 101)
	custom_smell = copytext_char("[custom_smell]", 1, 101)
	flavor_text = copytext_char("[flavor_text]", 1, MAX_FLAVOR_LEN + 1)
	flavor_text_nsfw = copytext_char("[flavor_text_nsfw]", 1, MAX_FLAVOR_LEN + 1)
	ooc_notes = copytext_char("[ooc_notes]", 1, MAX_FLAVOR_LEN + 1)
	custom_species_lore = copytext_char("[custom_species_lore]", 1, MAX_FLAVOR_LEN + 1)
	general_record = copytext_char("[general_record]", 1, MAX_FLAVOR_LEN + 1)
	medical_record = copytext_char("[medical_record]", 1, MAX_FLAVOR_LEN + 1)
	security_record = copytext_char("[security_record]", 1, MAX_FLAVOR_LEN + 1)
	exploitable_info = copytext_char("[exploitable_info]", 1, MAX_FLAVOR_LEN + 1)
	background_info = copytext_char("[background_info]", 1, MAX_FLAVOR_LEN + 1)
	headshot = copytext_char("[headshot]", 1, MAX_MESSAGE_LEN + 1)
	if(!(character_scream in GLOB.scream_types))
		character_scream = "Human Scream"
	if(!(character_laugh in GLOB.laugh_types))
		character_laugh = "Human Laugh"
	chat_color = sanitize_hexcolor(chat_color, 6, TRUE, "#b0b0b0")
	if(length(SSblooper.blooper_list))
		if(!(blooper_choice in SSblooper.blooper_list))
			blooper_choice = default_blooper_id()
	else
		blooper_choice = "none"
	blooper_speed = clamp(blooper_speed, 0, 100)
	blooper_pitch = clamp(blooper_pitch, 0, 100)
	blooper_pitch_range = clamp(blooper_pitch_range, 0, 100)
	var/datum/preference/choiced/backpack/bag_pref = GLOB.preference_entries[/datum/preference/choiced/backpack]
	if(bag_pref && !(backpack in bag_pref.get_choices()))
		backpack = DBACKPACK
	if(!(childhood_id in GLOB.all_rw_backstories))
		childhood_id = "childhood_none"
	if(!(adulthood_id in GLOB.all_rw_backstories))
		adulthood_id = "adulthood_none"
	var/datum/rw_backstory/childhood = GLOB.all_rw_backstories[childhood_id]
	if(childhood && childhood.slot != RW_BACKSTORY_CHILDHOOD)
		childhood_id = "childhood_none"
	var/datum/rw_backstory/adulthood = GLOB.all_rw_backstories[adulthood_id]
	if(adulthood && adulthood.slot != RW_BACKSTORY_ADULTHOOD)
		adulthood_id = "adulthood_none"
	var/list/valid_genes = list()
	for(var/gene_id in xenogenes)
		if(GLOB.all_rw_xenogenes[gene_id])
			valid_genes += gene_id
	xenogenes = valid_genes
	var/list/valid_traits = list()
	for(var/trait_id in traits)
		if(GLOB.all_rw_traits[trait_id])
			valid_traits += trait_id
	traits = valid_traits
	var/list/valid_loadout = list()
	for(var/item_id in loadout)
		if(GLOB.all_rw_loadout[item_id])
			valid_loadout += item_id
	loadout = valid_loadout
	for(var/skill_id in skills)
		skills[skill_id] = clamp(skills[skill_id] || 0, RW_SKILL_MIN, RW_SKILL_MANUAL_MAX)
	if(points_spent() > RW_CHARACTER_BUDGET)
		skills = list()
		traits = list()
		loadout = list()
		for(var/skill_id in GLOB.all_rw_skills)
			skills[skill_id] = 0

/datum/rimworld_preferences/proc/load_character(slot)
	if(!savefile)
		load_savefile()
	if(!savefile)
		return FALSE
	slot = slot || default_slot
	default_slot = slot
	var/list/data = savefile.get_entry(slot_key(slot))
	if(!data)
		reset_to_defaults()
		return FALSE
	return deserialize_character(data)

/datum/rimworld_preferences/proc/save_character()
	if(!load_and_save || !savefile)
		return
	savefile.set_entry(slot_key(default_slot), serialize_character())
	save_preferences()

/datum/rimworld_preferences/proc/switch_to_slot(slot)
	save_character()
	if(preview_dummy && !QDELETED(preview_dummy))
		cache_portrait_for_slot(default_slot, preview_dummy)
	if(slot < 1 || slot > max_save_slots)
		return FALSE
	default_slot = slot
	if(!load_character(slot))
		reset_to_defaults()
		save_character()
	preview_dir = SOUTH
	update_preview()
	return TRUE

/datum/rimworld_preferences/proc/create_character_profiles()
	var/list/profiles = list()
	for(var/index in 1 to max_save_slots)
		if(index == default_slot)
			profiles += list(list(
				"slot" = index,
				"name" = real_name,
				"firstName" = first_name,
				"lastName" = last_name,
				"nickname" = nickname,
				"empty" = FALSE,
				"role" = backstory_display_name(adulthood_id),
				"portrait" = portrait_cache["[index]"],
			))
			continue
		var/list/data = savefile?.get_entry(slot_key(index))
		if(!data)
			profiles += list(list(
				"slot" = index,
				"name" = "Empty",
				"firstName" = "Empty",
				"lastName" = "",
				"nickname" = "",
				"empty" = TRUE,
				"role" = "",
				"portrait" = null,
			))
			continue
		var/saved_first = data["first_name"]
		var/saved_last = data["last_name"]
		if(!saved_first && data["real_name"])
			var/full_name = data["real_name"]
			var/space = findlasttext_char(full_name, " ")
			if(space)
				saved_first = copytext_char(full_name, 1, space)
				saved_last = copytext_char(full_name, space + 1)
			else
				saved_first = full_name
				saved_last = ""
		profiles += list(list(
			"slot" = index,
			"name" = data["real_name"] || "Colonist",
			"firstName" = saved_first || "Colonist",
			"lastName" = saved_last || "",
			"nickname" = data["nickname"] || "",
			"empty" = FALSE,
			"role" = backstory_display_name(data["adulthood"]),
			"portrait" = portrait_cache["[index]"],
		))
	return profiles
