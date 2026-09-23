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
		"hair_gradient",
		"hair_gradient_color",
		"facial_hair_gradient",
		"facial_hair_gradient_color",
		"flavor_text",
		"flavor_text_nsfw",
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
	)

/datum/rimworld_preferences/proc/identity_pref_categories()
	return list(
		PREFERENCE_CATEGORY_NON_CONTEXTUAL,
		PREFERENCE_CATEGORY_OOC_PREFS,
	)

/datum/rimworld_preferences/proc/bridge_write(preference_type, value)
	var/datum/preferences/bridge = ensure_pref_bridge()
	var/datum/preference/pref = GLOB.preference_entries[preference_type]
	if(!bridge || !pref)
		return
	bridge.value_cache[preference_type] = value
	if(!islist(bridge.character_data))
		bridge.character_data = list()
	bridge.character_data[pref.savefile_key] = pref.serialize(value)

/datum/rimworld_preferences/proc/sync_owned_to_bridge()
	var/datum/preferences/bridge = ensure_pref_bridge()
	if(!bridge)
		return
	bridge_write(/datum/preference/name/real_name, real_name)
	bridge_write(/datum/preference/numeric/age, biological_age)
	if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
		bridge_write(/datum/preference/numeric/chronological_age, chronological_age)
	bridge_write(/datum/preference/choiced/gender, gender)
	bridge_write(/datum/preference/choiced/body_type, body_type)
	bridge_write(/datum/preference/choiced/species, species_type)
	bridge_write(/datum/preference/choiced/hairstyle, hairstyle)
	bridge_write(/datum/preference/color/hair_color, hair_color)
	bridge_write(/datum/preference/choiced/facial_hairstyle, facial_hairstyle)
	bridge_write(/datum/preference/color/facial_hair_color, facial_hair_color)
	bridge_write(/datum/preference/choiced/underwear, underwear)
	bridge_write(/datum/preference/color/underwear_color, underwear_color)
	bridge_write(/datum/preference/choiced/undershirt, undershirt)
	if(GLOB.preference_entries[/datum/preference/color/undershirt_color])
		bridge_write(/datum/preference/color/undershirt_color, undershirt_color)
	bridge_write(/datum/preference/choiced/bra, bra)
	if(GLOB.preference_entries[/datum/preference/color/bra_color])
		bridge_write(/datum/preference/color/bra_color, bra_color)
	bridge_write(/datum/preference/choiced/socks, socks)
	if(GLOB.preference_entries[/datum/preference/color/socks_color])
		bridge_write(/datum/preference/color/socks_color, socks_color)
	bridge_write(/datum/preference/choiced/jumpsuit, jumpsuit_style)
	bridge_write(/datum/preference/choiced/backpack, backpack)
	bridge_write(/datum/preference/choiced/skin_tone, skin_tone)
	bridge_write(/datum/preference/color/eye_color, eye_color)
	bridge_write(/datum/preference/choiced/hair_gradient, hair_gradient)
	bridge_write(/datum/preference/color/hair_gradient, hair_gradient_color)
	bridge_write(/datum/preference/choiced/facial_hair_gradient, facial_gradient)
	bridge_write(/datum/preference/color/facial_hair_gradient, facial_gradient_color)
	if(GLOB.preference_entries[/datum/preference/numeric/body_size])
		bridge_write(/datum/preference/numeric/body_size, body_size)
	if(GLOB.preference_entries[/datum/preference/text/custom_species])
		bridge_write(/datum/preference/text/custom_species, custom_species)
	if(GLOB.preference_entries[/datum/preference/text/custom_species_lore])
		bridge_write(/datum/preference/text/custom_species_lore, custom_species_lore)
	if(GLOB.preference_entries[/datum/preference/text/flavor_text])
		bridge_write(/datum/preference/text/flavor_text, flavor_text)
	if(GLOB.preference_entries[/datum/preference/text/flavor_text_nsfw])
		bridge_write(/datum/preference/text/flavor_text_nsfw, flavor_text_nsfw)
	if(GLOB.preference_entries[/datum/preference/text/ooc_notes])
		bridge_write(/datum/preference/text/ooc_notes, ooc_notes)
	if(GLOB.preference_entries[/datum/preference/text/headshot])
		bridge_write(/datum/preference/text/headshot, headshot)
	if(GLOB.preference_entries[/datum/preference/choiced/scream])
		bridge_write(/datum/preference/choiced/scream, character_scream)
	if(GLOB.preference_entries[/datum/preference/choiced/laugh])
		bridge_write(/datum/preference/choiced/laugh, character_laugh)
	if(GLOB.preference_entries[/datum/preference/color/chat_color])
		bridge_write(/datum/preference/color/chat_color, chat_color)
	if(GLOB.preference_entries[/datum/preference/choiced/blooper])
		bridge_write(/datum/preference/choiced/blooper, blooper_choice)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_speed])
		bridge_write(/datum/preference/numeric/blooper_speed, blooper_speed)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch])
		bridge_write(/datum/preference/numeric/blooper_pitch, blooper_pitch)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch_range])
		bridge_write(/datum/preference/numeric/blooper_pitch_range, blooper_pitch_range)
	if(GLOB.preference_entries[/datum/preference/text/taste])
		bridge_write(/datum/preference/text/taste, custom_taste)
	if(GLOB.preference_entries[/datum/preference/text/smell])
		bridge_write(/datum/preference/text/smell, custom_smell)
	if(GLOB.preference_entries[/datum/preference/text/general])
		bridge_write(/datum/preference/text/general, general_record)
	if(GLOB.preference_entries[/datum/preference/text/medical])
		bridge_write(/datum/preference/text/medical, medical_record)
	if(GLOB.preference_entries[/datum/preference/text/security])
		bridge_write(/datum/preference/text/security, security_record)
	if(GLOB.preference_entries[/datum/preference/text/exploitable])
		bridge_write(/datum/preference/text/exploitable, exploitable_info)
	if(GLOB.preference_entries[/datum/preference/text/background])
		bridge_write(/datum/preference/text/background, background_info)
	if(ispath(species_type, /datum/species) && bridge.pref_species?.type != species_type)
		QDEL_NULL(bridge.pref_species)
		bridge.pref_species = new species_type()

/datum/rimworld_preferences/proc/sync_bridge_to_owned()
	var/datum/preferences/bridge = pref_bridge
	if(!bridge)
		return
	var/new_name = bridge.read_preference(/datum/preference/name/real_name)
	if(new_name && new_name != real_name)
		split_real_name(new_name)
		rebuild_real_name()
	var/new_age = bridge.read_preference(/datum/preference/numeric/age)
	if(isnum(new_age))
		biological_age = clamp(new_age, AGE_MIN, AGE_MAX)
		if(chronological_age < biological_age)
			chronological_age = biological_age
	if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
		var/new_chrono = bridge.read_preference(/datum/preference/numeric/chronological_age)
		if(isnum(new_chrono))
			chronological_age = clamp(max(new_chrono, biological_age), AGE_MIN, AGE_CHRONO_MAX)
	var/new_gender = bridge.read_preference(/datum/preference/choiced/gender)
	if(new_gender == MALE || new_gender == FEMALE || new_gender == PLURAL || new_gender == NEUTER)
		gender = new_gender
	var/new_body = bridge.read_preference(/datum/preference/choiced/body_type)
	if(new_body == "Use gender" || new_body == MALE || new_body == FEMALE)
		body_type = new_body
	var/new_species = bridge.read_preference(/datum/preference/choiced/species)
	if(ispath(new_species, /datum/species) && (new_species in GLOB.rw_base_species))
		species_type = new_species
	hairstyle = bridge.read_preference(/datum/preference/choiced/hairstyle) || hairstyle
	hair_color = bridge.read_preference(/datum/preference/color/hair_color) || hair_color
	facial_hairstyle = bridge.read_preference(/datum/preference/choiced/facial_hairstyle) || facial_hairstyle
	facial_hair_color = bridge.read_preference(/datum/preference/color/facial_hair_color) || facial_hair_color
	underwear = bridge.read_preference(/datum/preference/choiced/underwear) || underwear
	underwear_color = bridge.read_preference(/datum/preference/color/underwear_color) || underwear_color
	undershirt = bridge.read_preference(/datum/preference/choiced/undershirt) || undershirt
	bra = bridge.read_preference(/datum/preference/choiced/bra) || bra
	socks = bridge.read_preference(/datum/preference/choiced/socks) || socks
	jumpsuit_style = bridge.read_preference(/datum/preference/choiced/jumpsuit) || jumpsuit_style
	backpack = bridge.read_preference(/datum/preference/choiced/backpack) || backpack
	skin_tone = bridge.read_preference(/datum/preference/choiced/skin_tone) || skin_tone
	eye_color = bridge.read_preference(/datum/preference/color/eye_color) || eye_color
	hair_gradient = bridge.read_preference(/datum/preference/choiced/hair_gradient) || hair_gradient
	hair_gradient_color = bridge.read_preference(/datum/preference/color/hair_gradient) || hair_gradient_color
	facial_gradient = bridge.read_preference(/datum/preference/choiced/facial_hair_gradient) || facial_gradient
	facial_gradient_color = bridge.read_preference(/datum/preference/color/facial_hair_gradient) || facial_gradient_color
	if(GLOB.preference_entries[/datum/preference/numeric/body_size])
		body_size = bridge.read_preference(/datum/preference/numeric/body_size) || body_size
	if(GLOB.preference_entries[/datum/preference/text/custom_species])
		custom_species = bridge.read_preference(/datum/preference/text/custom_species) || ""
	if(GLOB.preference_entries[/datum/preference/text/custom_species_lore])
		custom_species_lore = bridge.read_preference(/datum/preference/text/custom_species_lore) || ""
	if(GLOB.preference_entries[/datum/preference/text/flavor_text])
		flavor_text = bridge.read_preference(/datum/preference/text/flavor_text) || ""
	if(GLOB.preference_entries[/datum/preference/text/flavor_text_nsfw])
		flavor_text_nsfw = bridge.read_preference(/datum/preference/text/flavor_text_nsfw) || ""
	if(GLOB.preference_entries[/datum/preference/text/ooc_notes])
		ooc_notes = bridge.read_preference(/datum/preference/text/ooc_notes) || ""
	if(GLOB.preference_entries[/datum/preference/text/headshot])
		headshot = bridge.read_preference(/datum/preference/text/headshot) || ""
	if(GLOB.preference_entries[/datum/preference/choiced/scream])
		character_scream = bridge.read_preference(/datum/preference/choiced/scream) || character_scream
	if(GLOB.preference_entries[/datum/preference/choiced/laugh])
		character_laugh = bridge.read_preference(/datum/preference/choiced/laugh) || character_laugh
	if(GLOB.preference_entries[/datum/preference/color/chat_color])
		chat_color = bridge.read_preference(/datum/preference/color/chat_color) || chat_color
	if(GLOB.preference_entries[/datum/preference/choiced/blooper])
		blooper_choice = bridge.read_preference(/datum/preference/choiced/blooper) || blooper_choice
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_speed])
		var/new_speed = bridge.read_preference(/datum/preference/numeric/blooper_speed)
		if(isnum(new_speed))
			blooper_speed = new_speed
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch])
		var/new_pitch = bridge.read_preference(/datum/preference/numeric/blooper_pitch)
		if(isnum(new_pitch))
			blooper_pitch = new_pitch
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch_range])
		var/new_range = bridge.read_preference(/datum/preference/numeric/blooper_pitch_range)
		if(isnum(new_range))
			blooper_pitch_range = new_range
	if(GLOB.preference_entries[/datum/preference/text/taste])
		custom_taste = bridge.read_preference(/datum/preference/text/taste) || ""
	if(GLOB.preference_entries[/datum/preference/text/smell])
		custom_smell = bridge.read_preference(/datum/preference/text/smell) || ""
	if(GLOB.preference_entries[/datum/preference/text/general])
		general_record = bridge.read_preference(/datum/preference/text/general) || ""
	if(GLOB.preference_entries[/datum/preference/text/medical])
		medical_record = bridge.read_preference(/datum/preference/text/medical) || ""
	if(GLOB.preference_entries[/datum/preference/text/security])
		security_record = bridge.read_preference(/datum/preference/text/security) || ""
	if(GLOB.preference_entries[/datum/preference/text/exploitable])
		exploitable_info = bridge.read_preference(/datum/preference/text/exploitable) || ""
	if(GLOB.preference_entries[/datum/preference/text/background])
		background_info = bridge.read_preference(/datum/preference/text/background) || ""

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
	if(bridge.pref_species)
		QDEL_NULL(bridge.pref_species)
	sync_owned_to_bridge()

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
	sync_owned_to_bridge()

/datum/rimworld_preferences/proc/compile_character_pref_ui(mob/user)
	var/datum/preferences/bridge = ensure_pref_bridge()
	sync_owned_to_bridge()
	var/list/compiled = bridge.compile_character_preferences(user)
	var/list/hidden = hidden_pref_keys()
	var/list/basics = list()
	var/list/visual = list()
	var/list/identity = list()
	var/list/entries
	entries = compiled[PREFERENCE_CATEGORY_CHARACTER_BASICS]
	if(islist(entries))
		for(var/key in entries)
			if(!(key in hidden))
				basics[key] = entries[key]
	entries = compiled[PREFERENCE_CATEGORY_SECONDARY_FEATURES]
	if(islist(entries))
		for(var/key in entries)
			if(!(key in hidden))
				visual[key] = entries[key]
	for(var/category in identity_pref_categories())
		entries = compiled[category]
		if(!islist(entries))
			continue
		for(var/key in entries)
			if(!(key in hidden))
				identity[key] = entries[key]
	var/datum/species/proto = GLOB.species_prototypes[species_type]
	return list(
		"clothing" = list(),
		"features" = list(),
		"game_preferences" = list(),
		"non_contextual" = identity,
		"secondary_features" = visual,
		"character_basics" = basics,
		"ooc_preferences" = list(),
		"silicon_preferences" = list(),
		"supplemental_features" = list(),
		"manually_rendered_features" = list(),
		"names" = list(),
		"misc" = list(
			"gender" = gender,
			"species" = proto?.id || "human",
		),
		"randomization" = list(),
		"basics" = basics,
		"visual" = visual,
		"identity" = identity,
	)

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
					sync_bridge_to_owned()
					save_character()
					update_preview()
					return TRUE
			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(isnull(requested_preference))
				return FALSE
			if(!bridge.update_preference(requested_preference, value))
				return FALSE
			bridge.update_body_parts(requested_preference)
			for(var/datum/preference_middleware/preference_middleware as anything in bridge.middleware)
				preference_middleware.post_set_preference(user, requested_preference_key, value)
			sync_bridge_to_owned()
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
			if(!bridge.update_preference(requested_preference, new_color))
				return FALSE
			bridge.update_body_parts(requested_preference)
			sync_bridge_to_owned()
			save_character()
			update_preview()
			return TRUE
		if("set_tricolor_preference")
			var/requested_preference_key = params["preference"]
			var/index_key = params["value"]
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
			if(!bridge.update_preference(requested_preference, default_value_list))
				return FALSE
			bridge.update_body_parts(requested_preference)
			sync_bridge_to_owned()
			save_character()
			update_preview()
			return TRUE
	for(var/datum/preference_middleware/preference_middleware as anything in bridge.middleware)
		var/delegation = preference_middleware.action_delegations[action]
		if(isnull(delegation))
			continue
		. = call(preference_middleware, delegation)(params, user)
		if(.)
			sync_bridge_to_owned()
			save_character()
			update_preview()
		return .
	return FALSE
