/// Lightweight /datum/preferences used by the Rimworld editor so we can reuse
/// GLOB.preference_entries, accessibility, compile_ui_data, and apply_prefs_to.
/datum/preferences/rimworld_bridge
	var/datum/rimworld_preferences/rw_owner

/datum/preferences/rimworld_bridge/New(client/owner, datum/rimworld_preferences/rw)
	parent = owner
	rw_owner = rw
	load_and_save = FALSE
	path = null
	savefile = null
	current_window = PREFERENCE_TAB_CHARACTER_PREFERENCES
	character_data = list()
	value_cache = list()
	features = MANDATORY_FEATURE_LIST
	mutant_bodyparts = list()
	body_markings = list()
	augments = list()
	augment_limb_styles = list()
	languages = list()
	all_quirks = list()
	randomise = list()
	for(var/middleware_type in subtypesof(/datum/preference_middleware))
		middleware += new middleware_type(src)
	character_preview_view = new /atom/movable/screen/map_view/char_preview/rw_hook(null, null, src)

/datum/preferences/rimworld_bridge/Destroy(force)
	rw_owner = null
	return ..()

/datum/preferences/rimworld_bridge/get_save_data_for_savefile_identifier(savefile_identifier)
	if(savefile_identifier == PREFERENCE_CHARACTER)
		if(!islist(character_data))
			character_data = list()
		return character_data
	return list()

/datum/preferences/rimworld_bridge/save_character(update, override_slot)
	return

/datum/preferences/rimworld_bridge/save_preferences()
	return

/atom/movable/screen/map_view/char_preview/rw_hook

/atom/movable/screen/map_view/char_preview/rw_hook/update_body()
	var/datum/preferences/rimworld_bridge/bridge = preferences
	if(istype(bridge))
		bridge.rw_owner?.update_preview()

/datum/rimworld_preferences/proc/ensure_pref_bridge()
	if(pref_bridge && !QDELETED(pref_bridge))
		return pref_bridge
	pref_bridge = new /datum/preferences/rimworld_bridge(parent, src)
	return pref_bridge

/datum/rimworld_preferences/proc/rw_pref(preference_type)
	if(!GLOB.preference_entries[preference_type])
		return null
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return null
	return bridge.read_preference(preference_type)

/datum/rimworld_preferences/proc/rw_set_pref(preference_type, value, force = FALSE)
	if(!GLOB.preference_entries[preference_type])
		return FALSE
	var/datum/preferences/bridge = ensure_pref_bridge()
	var/datum/preference/pref = GLOB.preference_entries[preference_type]
	if(!bridge || !pref)
		return FALSE
	var/success
	if(force)
		success = bridge.write_preference(pref, value)
	else
		success = bridge.update_preference(pref, value)
	if(success)
		bridge.update_body_parts(pref)
	return success

/datum/rimworld_preferences/proc/pin_rw_species(species_path)
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return FALSE
	if(!(species_path in GLOB.rw_base_species))
		species_path = /datum/species/human
	var/datum/species/proto = GLOB.species_prototypes[species_path]
	if(!proto)
		return FALSE
	if(!islist(bridge.character_data))
		bridge.character_data = list()
	bridge.character_data["species"] = proto.id
	bridge.value_cache[/datum/preference/choiced/species] = species_path
	return TRUE

/datum/rimworld_preferences/proc/rw_species()
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(bridge)
		var/cached = bridge.value_cache[/datum/preference/choiced/species]
		if(cached in GLOB.rw_base_species)
			return cached
		if(islist(bridge.character_data))
			var/stored = bridge.character_data["species"]
			var/species_path = ispath(stored, /datum/species) ? stored : GLOB.species_list[stored]
			if(species_path in GLOB.rw_base_species)
				bridge.value_cache[/datum/preference/choiced/species] = species_path
				return species_path
	return /datum/species/human

/datum/rimworld_preferences/proc/rw_gender()
	var/new_gender = rw_pref(/datum/preference/choiced/gender)
	if(new_gender == MALE || new_gender == FEMALE || new_gender == PLURAL || new_gender == NEUTER)
		return new_gender
	return MALE

/datum/rimworld_preferences/proc/rw_hex(preference_type, fallback = "#ffffff")
	var/value = rw_pref(preference_type)
	if(!istext(value) || !length(value))
		return fallback
	if(copytext(value, 1, 2) != "#")
		return "#[value]"
	return value

/datum/rimworld_preferences/proc/refresh_pref_species()
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return
	var/species_path = /datum/species/human
	if(islist(bridge.character_data))
		var/stored = bridge.character_data["species"]
		if(ispath(stored, /datum/species))
			species_path = stored
		else if(istext(stored))
			species_path = GLOB.species_list[stored]
	if(!(species_path in GLOB.rw_base_species))
		species_path = /datum/species/human
	pin_rw_species(species_path)
	if(bridge.pref_species?.type == species_path)
		return
	QDEL_NULL(bridge.pref_species)
	if(ispath(species_path, /datum/species))
		bridge.pref_species = new species_path()

/datum/rimworld_preferences/proc/rw_set_species(species_path)
	if(!(species_path in GLOB.rw_base_species))
		return FALSE
	if(!pin_rw_species(species_path))
		return FALSE
	refresh_pref_species()
	var/datum/preferences/bridge = pref_bridge
	var/datum/species/proto = GLOB.species_prototypes[species_path]
	if(bridge && proto)
		var/list/defaults = proto.get_default_mutant_bodyparts()
		if(islist(defaults))
			bridge.mutant_bodyparts = list()
			for(var/part_key in defaults)
				var/list/part_info = defaults[part_key]
				if(!islist(part_info) || !length(part_info))
					continue
				var/part_name = part_info[1]
				bridge.mutant_bodyparts[part_key] = list(
					MUTANT_INDEX_NAME = part_name,
					MUTANT_INDEX_COLOR_LIST = list("#FFFFFF", "#FFFFFF", "#FFFFFF"),
					MUTANT_INDEX_EMISSIVE_LIST = list(FALSE, FALSE, FALSE),
				)
				var/datum/preference/toggle_pref = GLOB.preference_entries_by_key["[part_key]_toggle"]
				if(istype(toggle_pref, /datum/preference/toggle))
					rw_set_pref(toggle_pref.type, TRUE, force = TRUE)
				var/datum/preference/choice_pref = GLOB.preference_entries_by_key["feature_[part_key]"]
				if(istype(choice_pref, /datum/preference/choiced) && part_name)
					rw_set_pref(choice_pref.type, part_name, force = TRUE)
	return TRUE

/datum/rimworld_preferences/proc/hidden_pref_keys()
	return list(
		"real_name",
		"age",
		"chrono_age",
		"gender",
		"body_type",
		"species",
		"hairstyle_name",
		"hair_color",
		"facial_style_name",
		"facial_hair_color",
		"underwear",
		"underwear_color",
		"undershirt",
		"undershirt_color",
		"bra",
		"bra_color",
		"socks",
		"socks_color",
		"jumpsuit_style",
		"backpack",
		"random_body",
		"random_name",
		"random_hardcore",
		"joblessrole",
		"pda_ringtone",
		"pda_theme",
		"uplink_loc",
		"preferred_security_department",
		"prisoner_crime",
		"background_state",
		"loadout_list",
		"loadout_index",
		"loadout_override_preference",
		"job_clothes",
		"playtime_reward_cloak",
		"operative_species",
		"skin_tone",
		"eye_color",
		"heterochromatic",
		"hair_gradient",
		"hair_gradient_color",
		"facial_hair_gradient",
		"facial_hair_gradient_color",
		"flavor_text",
		"flavor_text_nsfw",
		"ooc_notes",
		"eye_emissives",
		"blooper_send",
		"blooper_hear",
		"allow_genitals_toggle",
		"art_ref_nsfw",
		"cursekin_char_slot",
		"body_size",
		"custom_species",
		"custom_species_lore",
		"headshot",
		"headshot_nsfw",
		"character_scream",
		"character_laugh",
		"ic_chat_color",
		"blooper_choice",
		"blooper_speed",
		"blooper_pitch",
		"blooper_pitch_range",
		"custom_taste",
		"custom_smell",
		"general_record",
		"medical_record",
		"security_record",
		"exploitable_info",
		"background_info",
		"mutant_colors_color",
		"mismatched_customization",
		"allow_mismatched_parts_toggle",
		"allow_emissives_toggle",
		"allow_mismatched_hair_color_toggle",
	)

/datum/rimworld_preferences/proc/reset_pref_bridge()
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return
	bridge.character_data = list()
	bridge.value_cache = list()
	bridge.features = MANDATORY_FEATURE_LIST
	bridge.mutant_bodyparts = list()
	bridge.body_markings = list()
	bridge.augments = list()
	bridge.augment_limb_styles = list()
	bridge.languages = list()
	bridge.all_quirks = list()
	QDEL_NULL(bridge.pref_species)

/datum/rimworld_preferences/proc/export_pref_bridge()
	var/datum/preferences/bridge = pref_bridge
	if(!bridge)
		return list()
	return list(
		"pref_values" = islist(bridge.character_data) ? bridge.character_data.Copy() : list(),
		"mutant_bodyparts" = islist(bridge.mutant_bodyparts) ? deep_copy_list(bridge.mutant_bodyparts) : list(),
		"body_markings" = islist(bridge.body_markings) ? deep_copy_list(bridge.body_markings) : list(),
		"features" = islist(bridge.features) ? deep_copy_list(bridge.features) : list(),
		"augments" = islist(bridge.augments) ? deep_copy_list(bridge.augments) : list(),
		"augment_limb_styles" = islist(bridge.augment_limb_styles) ? deep_copy_list(bridge.augment_limb_styles) : list(),
		"languages" = islist(bridge.languages) ? bridge.languages.Copy() : list(),
	)

/datum/rimworld_preferences/proc/import_pref_bridge(list/data)
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge || !data)
		return
	bridge.character_data = islist(data["pref_values"]) ? data["pref_values"].Copy() : list()
	bridge.value_cache = list()
	bridge.mutant_bodyparts = islist(data["mutant_bodyparts"]) ? deep_copy_list(data["mutant_bodyparts"]) : list()
	bridge.body_markings = islist(data["body_markings"]) ? deep_copy_list(data["body_markings"]) : list()
	bridge.features = islist(data["features"]) ? deep_copy_list(data["features"]) : MANDATORY_FEATURE_LIST
	bridge.augments = islist(data["augments"]) ? deep_copy_list(data["augments"]) : list()
	bridge.augment_limb_styles = islist(data["augment_limb_styles"]) ? deep_copy_list(data["augment_limb_styles"]) : list()
	bridge.languages = islist(data["languages"]) ? data["languages"].Copy() : list()
	refresh_pref_species()

/datum/rimworld_preferences/proc/migrate_legacy_appearance(list/data)
	if(!data || length(data["pref_values"]))
		return
	var/static/list/legacy_map = list(
		"gender" = /datum/preference/choiced/gender,
		"body_type" = /datum/preference/choiced/body_type,
		"hairstyle" = /datum/preference/choiced/hairstyle,
		"hair_color" = /datum/preference/color/hair_color,
		"facial_hairstyle" = /datum/preference/choiced/facial_hairstyle,
		"facial_hair_color" = /datum/preference/color/facial_hair_color,
		"underwear" = /datum/preference/choiced/underwear,
		"underwear_color" = /datum/preference/color/underwear_color,
		"undershirt" = /datum/preference/choiced/undershirt,
		"undershirt_color" = /datum/preference/color/undershirt_color,
		"bra" = /datum/preference/choiced/bra,
		"bra_color" = /datum/preference/color/bra_color,
		"socks" = /datum/preference/choiced/socks,
		"socks_color" = /datum/preference/color/socks_color,
		"jumpsuit_style" = /datum/preference/choiced/jumpsuit,
		"backpack" = /datum/preference/choiced/backpack,
		"skin_tone" = /datum/preference/choiced/skin_tone,
		"eye_color" = /datum/preference/color/eye_color,
		"eye_color_right" = /datum/preference/color/heterochromatic,
		"hair_gradient" = /datum/preference/choiced/hair_gradient,
		"hair_gradient_color" = /datum/preference/color/hair_gradient,
		"facial_gradient" = /datum/preference/choiced/facial_hair_gradient,
		"facial_gradient_color" = /datum/preference/color/facial_hair_gradient,
		"body_size" = /datum/preference/numeric/body_size,
		"custom_species" = /datum/preference/text/custom_species,
		"custom_species_lore" = /datum/preference/text/custom_species_lore,
		"flavor_text" = /datum/preference/text/flavor_text,
		"flavor_text_nsfw" = /datum/preference/text/flavor_text_nsfw,
		"ooc_notes" = /datum/preference/text/ooc_notes,
		"headshot" = /datum/preference/text/headshot,
		"character_scream" = /datum/preference/choiced/scream,
		"character_laugh" = /datum/preference/choiced/laugh,
		"chat_color" = /datum/preference/color/chat_color,
		"blooper_choice" = /datum/preference/choiced/blooper,
		"blooper_speed" = /datum/preference/numeric/blooper_speed,
		"blooper_pitch" = /datum/preference/numeric/blooper_pitch,
		"blooper_pitch_range" = /datum/preference/numeric/blooper_pitch_range,
		"custom_taste" = /datum/preference/text/taste,
		"custom_smell" = /datum/preference/text/smell,
		"general_record" = /datum/preference/text/general,
		"medical_record" = /datum/preference/text/medical,
		"security_record" = /datum/preference/text/security,
		"exploitable_info" = /datum/preference/text/exploitable,
		"background_info" = /datum/preference/text/background,
		"biological_age" = /datum/preference/numeric/age,
		"chronological_age" = /datum/preference/numeric/chronological_age,
	)
	for(var/old_key in legacy_map)
		if(isnull(data[old_key]))
			continue
		rw_set_pref(legacy_map[old_key], data[old_key], force = TRUE)
	var/species_path = text2path(data["species"])
	if(ispath(species_path, /datum/species))
		rw_set_species(species_path)
	var/m1 = data["mutant_color"]
	var/m2 = data["mutant_color_2"] || m1
	var/m3 = data["mutant_color_3"] || m1
	if(m1 && GLOB.preference_entries[/datum/preference/tri_color/mutant_colors])
		rw_set_pref(/datum/preference/tri_color/mutant_colors, list(m1, m2, m3), force = TRUE)
	if(data["real_name"])
		rw_set_pref(/datum/preference/name/real_name, data["real_name"], force = TRUE)

/datum/rimworld_preferences/proc/pref_field_kind(datum/preference/pref)
	if(istype(pref, /datum/preference/choiced))
		return "choiced"
	if(istype(pref, /datum/preference/color))
		return "color"
	if(istype(pref, /datum/preference/tri_color))
		return "tricolor"
	if(istype(pref, /datum/preference/toggle))
		return "toggle"
	if(istype(pref, /datum/preference/numeric))
		return "numeric"
	if(istype(pref, /datum/preference/text))
		return "text"
	return null

/datum/rimworld_preferences/proc/pref_field_name(datum/preference/pref)
	if(istype(pref, /datum/preference/choiced))
		var/datum/preference/choiced/choiced = pref
		if(choiced.main_feature_name)
			return choiced.main_feature_name
	var/list/constant = pref.compile_constant_data()
	if(islist(constant) && constant["name"])
		return constant["name"]
	return capitalize(replacetext("[pref.savefile_key]", "_", " "))

/datum/rimworld_preferences/proc/compile_pref_field(datum/preference/pref, value)
	var/kind = pref_field_kind(pref)
	if(!kind)
		return null
	var/list/entry = list(
		"key" = pref.savefile_key,
		"name" = pref_field_name(pref),
		"kind" = kind,
		"value" = pref.serialize(value),
	)
	if(kind == "choiced")
		var/datum/preference/choiced/choiced = pref
		entry["choices"] = choiced.get_choices_serialized()
		var/list/constant = choiced.compile_constant_data()
		if(islist(constant) && constant[CHOICED_PREFERENCE_DISPLAY_NAMES])
			entry["displayNames"] = constant[CHOICED_PREFERENCE_DISPLAY_NAMES]
	if(kind == "numeric")
		var/datum/preference/numeric/numeric = pref
		entry["min"] = numeric.minimum
		entry["max"] = numeric.maximum
		entry["step"] = numeric.step
	if(kind == "color" && istext(entry["value"]) && copytext(entry["value"], 1, 2) != "#")
		entry["value"] = "#[entry["value"]]"
	if(kind == "tricolor" && islist(entry["value"]))
		var/list/colors = entry["value"]
		var/list/hexed = list()
		for(var/index in 1 to length(colors))
			var/piece = colors[index]
			if(istext(piece) && copytext(piece, 1, 2) != "#")
				hexed += "#[piece]"
			else
				hexed += piece
		entry["value"] = hexed
	return entry

/datum/rimworld_preferences/proc/compile_character_pref_ui(mob/user)
	var/datum/preferences/bridge = ensure_pref_bridge()
	refresh_pref_species()
	var/list/hidden = hidden_pref_keys()
	var/list/species_fields = list()
	var/static/list/species_categories = list(
		PREFERENCE_CATEGORY_CHARACTER_BASICS,
		PREFERENCE_CATEGORY_FEATURES,
		PREFERENCE_CATEGORY_SECONDARY_FEATURES,
		PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES,
	)
	for(var/datum/preference/pref as anything in get_preferences_in_priority_order())
		if(pref.savefile_identifier != PREFERENCE_CHARACTER)
			continue
		if(pref.savefile_key in hidden)
			continue
		if(is_genital_pref(pref))
			continue
		if(!(pref.category in species_categories))
			continue
		if(!pref.is_accessible(bridge))
			continue
		var/list/entry = compile_pref_field(pref, bridge.read_preference(pref.type))
		if(entry)
			species_fields += list(entry)
	return list("species" = species_fields)

/datum/rimworld_preferences/proc/is_genital_pref(datum/preference/pref)
	if(istype(pref, /datum/preference/choiced/genital) || istype(pref, /datum/preference/toggle/allow_genitals))
		return TRUE
	var/key = pref.savefile_key
	return findtext(key, "penis") || findtext(key, "testicle") || findtext(key, "vagina") || findtext(key, "womb") || findtext(key, "breast") || findtext(key, "butt") || findtext(key, "belly") || findtext(key, "anus") || findtext(key, "genital")

/datum/rimworld_preferences/proc/handle_pref_act(action, list/params, mob/user)
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return FALSE
	switch(action)
		if("set_preference")
			var/requested_preference_key = params["preference"]
			var/value = params["value"]
			for(var/datum/preference_middleware/preference_middleware as anything in bridge.middleware)
				if(preference_middleware.pre_set_preference(user, requested_preference_key, value))
					save_character()
					update_preview()
					return TRUE
			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(isnull(requested_preference))
				return FALSE
			if(!bridge.update_preference(requested_preference, value) && !bridge.write_preference(requested_preference, value))
				return FALSE
			bridge.update_body_parts(requested_preference)
			for(var/datum/preference_middleware/preference_middleware as anything in bridge.middleware)
				preference_middleware.post_set_preference(user, requested_preference_key, value)
			if(requested_preference.type == /datum/preference/choiced/species)
				refresh_pref_species()
			save_character()
			update_preview()
			return TRUE
		if("set_color_preference")
			var/requested_preference_key = params["preference"]
			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(isnull(requested_preference) || !istype(requested_preference, /datum/preference/color))
				return FALSE
			var/default_value = bridge.read_preference(requested_preference.type)
			var/new_color = tgui_color_picker(user, "Select new color", "Prepare Colonist", default_value || COLOR_WHITE)
			if(!new_color)
				return TRUE
			if(!bridge.update_preference(requested_preference, new_color) && !bridge.write_preference(requested_preference, new_color))
				return FALSE
			bridge.update_body_parts(requested_preference)
			save_character()
			update_preview()
			return TRUE
		if("set_tricolor_preference")
			var/requested_preference_key = params["preference"]
			var/index_key = text2num(params["value"])
			if(!index_key)
				index_key = params["value"]
			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(isnull(requested_preference) || !istype(requested_preference, /datum/preference/tri_color))
				return FALSE
			var/list/default_value_list = bridge.read_preference(requested_preference.type)
			if(!islist(default_value_list))
				return FALSE
			var/default_value = default_value_list[index_key]
			var/new_color = tgui_color_picker(user, "Select new color", "Prepare Colonist", default_value || COLOR_WHITE)
			if(!new_color)
				return TRUE
			default_value_list[index_key] = new_color
			if(!bridge.update_preference(requested_preference, default_value_list) && !bridge.write_preference(requested_preference, default_value_list))
				return FALSE
			bridge.update_body_parts(requested_preference)
			save_character()
			update_preview()
			return TRUE
	for(var/datum/preference_middleware/preference_middleware as anything in bridge.middleware)
		var/delegation = preference_middleware.action_delegations[action]
		if(isnull(delegation))
			continue
		. = call(preference_middleware, delegation)(params, user)
		if(.)
			save_character()
			update_preview()
		return .
	return FALSE
