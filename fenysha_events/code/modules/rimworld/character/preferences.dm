/datum/rimworld_preferences
	var/client/parent
	var/datum/json_savefile/savefile
	var/path
	var/load_and_save = TRUE
	var/default_slot = 1
	var/max_save_slots = RW_CHARACTER_MAX_SLOTS
	var/list/character_data
	var/mob/living/carbon/human/dummy/preview_dummy
	var/atom/movable/screen/map_view/rw_char_preview/character_preview_view
	var/preview_dir = SOUTH
	var/preview_png
	/// slot index (as text) -> base64 bust png
	var/list/portrait_cache

	var/real_name = "Colonist"
	var/first_name = "Colonist"
	var/nickname = ""
	var/last_name = ""
	var/tattoo = "None"
	var/list/xenogenes
	var/childhood_id = "childhood_none"
	var/adulthood_id = "adulthood_none"
	/// SKILL_ID -> bought levels (0-10)
	var/list/skills
	/// SKILL_ID -> RW_PASSION_*
	var/list/passions
	var/list/traits
	var/list/loadout
	var/datum/preferences/rimworld_bridge/pref_bridge

GLOBAL_LIST_INIT(rw_nicknames, world.file2list("strings/names/rw_nicknames.txt"))

/datum/rimworld_preferences/New(client/owner)
	parent = owner
	xenogenes = list()
	skills = list()
	passions = list()
	traits = list()
	loadout = list()
	portrait_cache = list()
	ensure_pref_bridge()
	reset_to_defaults()
	if(owner && !is_guest_key(owner.key))
		load_path(owner.ckey)
		load_savefile()
		load_preferences()
		if(!load_character(default_slot))
			save_character()
		ensure_all_slots_filled()
	else if(owner?.is_localhost())
		load_and_save = FALSE

/datum/rimworld_preferences/Destroy(force)
	parent = null
	QDEL_NULL(character_preview_view)
	QDEL_NULL(preview_dummy)
	QDEL_NULL(pref_bridge)
	QDEL_NULL(savefile)
	return ..()

/datum/rimworld_preferences/proc/rebuild_real_name()
	real_name = trim("[first_name] [last_name]")
	if(!length(real_name))
		real_name = first_name || last_name || "Colonist"
	rw_set_pref(/datum/preference/name/real_name, real_name, force = TRUE)

/datum/rimworld_preferences/proc/split_real_name(full_name)
	full_name = trim("[full_name]")
	if(!length(full_name))
		first_name = ""
		last_name = ""
		return
	var/space = findlasttext_char(full_name, " ")
	if(space)
		first_name = copytext_char(full_name, 1, space)
		last_name = copytext_char(full_name, space + 1)
	else
		first_name = full_name
		last_name = ""

/datum/rimworld_preferences/proc/reset_to_defaults()
	reset_pref_bridge()
	rw_set_pref(/datum/preference/choiced/gender, pick(MALE, FEMALE), force = TRUE)
	rw_set_pref(/datum/preference/choiced/body_type, USE_GENDER, force = TRUE)
	rw_set_species(/datum/species/human)
	randomize_names()
	rw_set_pref(/datum/preference/numeric/age, rand(AGE_MIN, 40), force = TRUE)
	var/bio_age = rw_pref(/datum/preference/numeric/age) || AGE_MIN
	if(GLOB.preference_entries[/datum/preference/numeric/chronological_age])
		rw_set_pref(/datum/preference/numeric/chronological_age, max(bio_age, bio_age + rand(0, 20)), force = TRUE)
	var/shared_color = ready_random_color()
	rw_set_pref(/datum/preference/color/hair_color, shared_color, force = TRUE)
	rw_set_pref(/datum/preference/color/facial_hair_color, shared_color, force = TRUE)
	rw_set_pref(/datum/preference/color/underwear_color, shared_color, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/color/undershirt_color])
		rw_set_pref(/datum/preference/color/undershirt_color, shared_color, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/color/bra_color])
		rw_set_pref(/datum/preference/color/bra_color, shared_color, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/color/socks_color])
		rw_set_pref(/datum/preference/color/socks_color, shared_color, force = TRUE)
	rw_set_pref(/datum/preference/choiced/jumpsuit, pick(PREF_SUIT, PREF_SKIRT), force = TRUE)
	rw_set_pref(/datum/preference/choiced/backpack, DBACKPACK, force = TRUE)
	rw_set_pref(/datum/preference/choiced/skin_tone, length(GLOB.skin_tones) ? pick(GLOB.skin_tones) : "caucasian1", force = TRUE)
	if(GLOB.preference_entries[/datum/preference/tri_color/mutant_colors])
		rw_set_pref(/datum/preference/tri_color/mutant_colors, list("#c0965f", "#c0965f", "#c0965f"), force = TRUE)
	rw_set_pref(/datum/preference/color/eye_color, random_eye_color(), force = TRUE)
	rw_set_pref(/datum/preference/choiced/hair_gradient, "None", force = TRUE)
	rw_set_pref(/datum/preference/color/hair_gradient, "#ffffff", force = TRUE)
	rw_set_pref(/datum/preference/choiced/facial_hair_gradient, "None", force = TRUE)
	rw_set_pref(/datum/preference/color/facial_hair_gradient, "#ffffff", force = TRUE)
	if(GLOB.preference_entries[/datum/preference/numeric/body_size])
		rw_set_pref(/datum/preference/numeric/body_size, 1, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/choiced/scream])
		rw_set_pref(/datum/preference/choiced/scream, length(GLOB.scream_types) ? pick(assoc_to_keys(GLOB.scream_types)) : "Human Scream", force = TRUE)
	if(GLOB.preference_entries[/datum/preference/choiced/laugh])
		rw_set_pref(/datum/preference/choiced/laugh, length(GLOB.laugh_types) ? pick(assoc_to_keys(GLOB.laugh_types)) : "Human Laugh", force = TRUE)
	if(GLOB.preference_entries[/datum/preference/color/chat_color])
		rw_set_pref(/datum/preference/color/chat_color, ready_random_color(), force = TRUE)
	if(GLOB.preference_entries[/datum/preference/choiced/blooper])
		var/blooper_id = default_blooper_id()
		if(length(SSblooper.blooper_list) && prob(70))
			blooper_id = pick(SSblooper.blooper_list)
		rw_set_pref(/datum/preference/choiced/blooper, blooper_id, force = TRUE)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_speed])
		rw_set_pref(/datum/preference/numeric/blooper_speed, rand(35, 70), force = TRUE)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch])
		rw_set_pref(/datum/preference/numeric/blooper_pitch, rand(35, 70), force = TRUE)
	if(GLOB.preference_entries[/datum/preference/numeric/blooper_pitch_range])
		rw_set_pref(/datum/preference/numeric/blooper_pitch_range, rand(20, 40), force = TRUE)
	randomize_appearance()
	tattoo = "None"
	xenogenes = list()
	childhood_id = "childhood_none"
	adulthood_id = "adulthood_none"
	skills = list()
	passions = list()
	for(var/skill_id in GLOB.all_rw_skills)
		skills[skill_id] = 0
		passions[skill_id] = RW_PASSION_NONE
	traits = list()
	loadout = list()

/datum/rimworld_preferences/proc/uses_skintones()
	var/datum/species/species = GLOB.species_prototypes[rw_species()]
	return species && (TRAIT_USES_SKINTONES in species.inherent_traits)

/datum/rimworld_preferences/proc/get_skill_bonus(skill_id)
	. = 0
	var/datum/rw_backstory/childhood = GLOB.all_rw_backstories[childhood_id]
	if(childhood?.skill_bonuses)
		. += childhood.skill_bonuses[skill_id] || 0
	var/datum/rw_backstory/adulthood = GLOB.all_rw_backstories[adulthood_id]
	if(adulthood?.skill_bonuses)
		. += adulthood.skill_bonuses[skill_id] || 0
	for(var/trait_id in traits)
		var/datum/rw_trait/trait = GLOB.all_rw_traits[trait_id]
		if(trait?.skill_bonuses)
			. += trait.skill_bonuses[skill_id] || 0
	for(var/gene_id in xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(gene?.skill_bonuses)
			. += gene.skill_bonuses[skill_id] || 0

/datum/rimworld_preferences/proc/get_skill_level(skill_id)
	return clamp((skills[skill_id] || 0) + get_skill_bonus(skill_id), RW_SKILL_MIN, RW_SKILL_MAX)

/datum/rimworld_preferences/proc/points_spent()
	. = 0
	for(var/skill_id in skills)
		. += (skills[skill_id] || 0) * RW_SKILL_LEVEL_COST
	for(var/trait_id in traits)
		var/datum/rw_trait/trait = GLOB.all_rw_traits[trait_id]
		. += trait?.cost || 0
	for(var/item_id in loadout)
		var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
		. += item?.cost || 0

/datum/rimworld_preferences/proc/points_remaining()
	return RW_CHARACTER_BUDGET - points_spent()

/datum/rimworld_preferences/proc/default_blooper_id()
	if(!length(SSblooper.blooper_list))
		return "none"
	var/list/ids = assoc_to_keys(SSblooper.blooper_list)
	return ids[1]

/datum/rimworld_preferences/proc/can_afford(cost)
	return points_remaining() >= cost

/datum/rimworld_preferences/proc/randomize_names()
	var/new_name
	var/species_path = rw_species()
	var/used_gender = rw_gender()
	if(ispath(species_path, /datum/species))
		new_name = generate_random_name_species_based(used_gender, TRUE, species_path)
	if(!length(new_name))
		new_name = generate_random_name(used_gender, TRUE)
	if(length(new_name))
		split_real_name(new_name)
	if(length(GLOB.rw_nicknames) && prob(RW_NICKNAME_CHANCE))
		var/picked_nick
		for(var/attempt in 1 to 8)
			picked_nick = pick(GLOB.rw_nicknames)
			if(length(picked_nick))
				break
		nickname = picked_nick || ""
	else
		nickname = ""
	rebuild_real_name()

/datum/rimworld_preferences/proc/randomize_appearance()
	var/used_gender = rw_gender()
	rw_set_pref(/datum/preference/choiced/hairstyle, "Bald", force = TRUE)
	rw_set_pref(/datum/preference/choiced/facial_hairstyle, "Shaved", force = TRUE)
	rw_set_pref(/datum/preference/choiced/underwear, "Nude", force = TRUE)
	rw_set_pref(/datum/preference/choiced/undershirt, "Nude", force = TRUE)
	if(GLOB.preference_entries[/datum/preference/choiced/bra])
		rw_set_pref(/datum/preference/choiced/bra, "Nude", force = TRUE)
	rw_set_pref(/datum/preference/choiced/socks, "Nude", force = TRUE)
	if(length(SSaccessories.hairstyles_list))
		rw_set_pref(/datum/preference/choiced/hairstyle, random_hairstyle(used_gender) || "Bald", force = TRUE)
	if(used_gender == MALE && prob(55) && length(SSaccessories.facial_hairstyles_list))
		rw_set_pref(/datum/preference/choiced/facial_hairstyle, random_facial_hairstyle(used_gender) || "Shaved", force = TRUE)
	if(length(SSaccessories.underwear_list))
		rw_set_pref(/datum/preference/choiced/underwear, random_underwear(used_gender) || "Nude", force = TRUE)
	if(length(SSaccessories.undershirt_list))
		rw_set_pref(/datum/preference/choiced/undershirt, random_undershirt(used_gender) || "Nude", force = TRUE)
	if(length(SSaccessories.bra_list) && GLOB.preference_entries[/datum/preference/choiced/bra])
		rw_set_pref(/datum/preference/choiced/bra, random_bra(used_gender) || "Nude", force = TRUE)
	if(length(SSaccessories.socks_list))
		rw_set_pref(/datum/preference/choiced/socks, random_socks() || "Nude", force = TRUE)

/datum/rimworld_preferences/proc/ensure_all_slots_filled()
	if(!savefile || !load_and_save)
		return
	var/saved_slot = default_slot
	var/list/saved_current = serialize_character()
	var/filled_any = FALSE
	for(var/index in 1 to max_save_slots)
		if(savefile.get_entry(slot_key(index)))
			continue
		default_slot = index
		reset_to_defaults()
		save_character()
		filled_any = TRUE
	default_slot = saved_slot
	if(filled_any)
		deserialize_character(saved_current)
