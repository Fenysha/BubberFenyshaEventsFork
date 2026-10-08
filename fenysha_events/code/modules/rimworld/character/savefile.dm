/// Xenogene save layout. 1 = whole gene list incl. race genes (values were clobbered by the race baseline).
/// 2 = acquired genes only + option values that differ from the race baseline. Race genes are derived.
#define RW_XENOGENE_SCHEMA 2

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

/// Compact form of the xenogene state: race genes are implied by the race, values equal to the
/// race default are implied too. Only what the player actually chose gets saved.
/datum/rimworld_preferences/proc/compact_xenogene_save()
	var/list/baseline = get_species_baseline()
	var/list/baseline_genes = baseline["genes"]
	var/list/baseline_values = baseline["values"]
	var/list/acquired = list()
	var/list/overrides = list()
	for(var/gene_id in xenogenes)
		var/is_race_gene = (gene_id in baseline_genes)
		if(!is_race_gene)
			acquired += gene_id
		if(!islist(xenogene_values) || isnull(xenogene_values[gene_id]))
			continue
		var/value = xenogene_values[gene_id]
		if(is_race_gene && xenogene_values_equal(value, baseline_values[gene_id]))
			continue
		if(islist(value))
			var/list/value_list = value
			value = value_list.Copy()
		overrides[gene_id] = value
	return list("genes" = acquired, "values" = overrides)

/datum/rimworld_preferences/proc/serialize_character()
	var/list/xenogene_save = compact_xenogene_save()
	var/list/data = list(
		"version" = RW_CHARACTER_SAVE_VERSION,
		"real_name" = real_name,
		"first_name" = first_name,
		"nickname" = nickname,
		"last_name" = last_name,
		"tattoo" = tattoo,
		"xenogene_schema" = RW_XENOGENE_SCHEMA,
		"xenogenes" = xenogene_save["genes"],
		"xenogene_values" = xenogene_save["values"],
		"xenogene_inheritable" = copy_list(xenogene_inheritable),
		"xenotype_id" = xenotype_id,
		"xenotype_name" = xenotype_name,
		"xenotype_description" = xenotype_description,
		"xenotype_icon_gene" = xenotype_icon_gene,
		"childhood" = childhood_id,
		"adulthood" = adulthood_id,
		"skills" = copy_list(skills),
		"passions" = copy_list(passions),
		"traits" = copy_list(traits),
		"loadout" = copy_list(loadout),
	)
	return data + export_pref_bridge()

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
	tattoo = data["tattoo"] || "None"
	xenogenes = copy_list(data["xenogenes"])
	xenogene_values = copy_list(data["xenogene_values"])
	xenogene_inheritable = copy_list(data["xenogene_inheritable"])
	xenotype_id = data["xenotype_id"]
	xenotype_name = data["xenotype_name"] || "Custom xenotype"
	xenotype_description = data["xenotype_description"] || "A unique combination of xenogenes."
	xenotype_icon_gene = data["xenotype_icon_gene"]
	childhood_id = data["childhood"] || "childhood_none"
	adulthood_id = data["adulthood"] || "adulthood_none"
	skills = copy_list(data["skills"])
	passions = copy_list(data["passions"])
	traits = copy_list(data["traits"])
	loadout = copy_list(data["loadout"])
	for(var/skill_id in GLOB.all_rw_skills)
		if(!(skill_id in skills))
			skills[skill_id] = 0
		if(!(skill_id in passions))
			passions[skill_id] = RW_PASSION_NONE
	import_pref_bridge(data)
	migrate_legacy_appearance(data)
	migrate_xenogene_schema(data["xenogene_schema"])
	sanitize_character()
	return TRUE

/// Runs after the race is known and before sanitize_character() rebuilds the baseline.
/datum/rimworld_preferences/proc/migrate_xenogene_schema(schema)
	if(!islist(xenogenes))
		xenogenes = list()
	if(!islist(xenogene_values))
		xenogene_values = list()
	if(isnum(schema) && schema >= RW_XENOGENE_SCHEMA)
		return
	// Schema 1 stored race genes and their values, but every sanitize pass overwrote those values
	// with the race defaults, so none of them is a real player choice. Drop them; the current race
	// baseline refills them (and picks up any later balance changes to the race).
	var/datum/species/proto = GLOB.species_prototypes[rw_species()]
	if(!islist(proto?.rw_innate_xenogenes))
		return
	for(var/gene_id in proto.rw_innate_xenogenes)
		xenogene_values -= gene_id

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
		split_real_name(generate_random_name(rw_gender(), TRUE))
		rebuild_real_name()
	var/bio_age = rw_pref(/datum/preference/numeric/age)
	if(!isnum(bio_age))
		bio_age = AGE_MIN
	bio_age = clamp(bio_age, AGE_MIN, AGE_MAX)
	rw_set_pref(/datum/preference/numeric/age, bio_age, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
		var/chrono_age = rw_pref(/datum/preference/numeric/chronological_age)
		if(!isnum(chrono_age))
			chrono_age = bio_age
		rw_set_pref(/datum/preference/numeric/chronological_age, clamp(max(chrono_age, bio_age), AGE_MIN, AGE_CHRONO_MAX), force = TRUE)
	if(!(rw_species() in GLOB.rw_base_species))
		rw_set_species(/datum/species/human)
	if(!(childhood_id in GLOB.all_rw_backstories))
		adulthood_id = "adulthood_none"
	var/datum/rw_backstory/childhood = GLOB.all_rw_backstories[childhood_id]
	if(childhood && childhood.slot != RW_BACKSTORY_CHILDHOOD)
		childhood_id = "childhood_none"
	var/datum/rw_backstory/adulthood = GLOB.all_rw_backstories[adulthood_id]
	if(adulthood && adulthood.slot != RW_BACKSTORY_ADULTHOOD)
		adulthood_id = "adulthood_none"
	migrate_legacy_xenogenes()
	var/list/valid_genes = list()
	for(var/gene_id in xenogenes)
		if(GLOB.all_rw_xenogenes[gene_id])
			valid_genes += gene_id
	xenogenes = valid_genes
	sync_species_xenogenes()
	sync_xenotype_identity()
	ensure_hair_preferences()
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
		// Drop non-innate xenogenes so a legacy/corrupt save cannot stay over budget.
		var/datum/species/proto = GLOB.species_prototypes[rw_species()]
		var/list/innate = proto?.rw_innate_xenogenes
		if(!islist(innate))
			innate = list()
		var/list/kept_genes = list()
		for(var/gene_id in xenogenes)
			if(gene_id in innate)
				kept_genes += gene_id
		xenogenes = kept_genes
		xenogene_inheritable = list()
		sync_species_xenogenes()
		sync_xenotype_identity()
		ensure_hair_preferences()

/datum/rimworld_preferences/proc/migrate_legacy_xenogenes()
	if(!islist(xenogenes))
		xenogenes = list()
	if(!islist(xenogene_values))
		xenogene_values = list()
	if(!islist(xenogene_inheritable))
		xenogene_inheritable = list()
	var/static/list/legacy = list(
		"vulp_ears" = list(RW_XENOGENE_EARS, "Fox"),
		"teshari_ears" = list(RW_XENOGENE_EARS, "Teshari Regular"),
		"teshari_tail" = list(RW_XENOGENE_TAIL, "Teshari (Default)"),
		"lizard_tail" = list(RW_XENOGENE_TAIL, "Smooth"),
		"lizard_snout" = list(RW_XENOGENE_SNOUT, "Sharp + Light"),
		"lizard_horns" = list(RW_XENOGENE_HORNS, "Simple"),
		"small_frame" = list(RW_XENOGENE_BODY_SIZE, BODY_SIZE_MIN),
		"feathered" = list(RW_XENOGENE_FLUFF, null),
		"scaled_skin" = list(RW_XENOGENE_SCALED_SKIN, null),
	)
	var/static/list/dropped = list(
		"lizard_frills" = TRUE,
		"lizard_spines" = TRUE,
		"standard_metabolism" = TRUE,
	)
	var/list/migrated = list()
	for(var/gene_id in xenogenes)
		if(dropped[gene_id])
			continue
		var/list/mapped = legacy[gene_id]
		if(islist(mapped))
			var/new_id = mapped[1]
			if(!(new_id in migrated))
				migrated += new_id
			if(!isnull(mapped[2]) && isnull(xenogene_values[new_id]))
				xenogene_values[new_id] = mapped[2]
			continue
		if(!(gene_id in migrated))
			migrated += gene_id
	xenogenes = migrated

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
				"lost" = slot_is_lost(index),
			))
			continue
		var/list/data
		if(savefile)
			data = savefile.get_entry(slot_key(index))
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
				"lost" = slot_is_lost(index),
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
			"lost" = slot_is_lost(index),
		))
	return profiles
