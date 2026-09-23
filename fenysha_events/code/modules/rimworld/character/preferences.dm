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
	var/biological_age = 21
	var/chronological_age = 21
	var/gender = MALE
	var/body_type = "Use gender"
	/// Typepath of the colonist's species, not an instance.
	var/species_type = /datum/species/human
	var/hairstyle = "Bald"
	var/hair_color = "#4a3728"
	var/facial_hairstyle = "Shaved"
	var/facial_hair_color = "#4a3728"
	var/underwear = "Nude"
	var/underwear_color = "#ffffff"
	var/undershirt = "Nude"
	var/undershirt_color = "#ffffff"
	var/bra = "Nude"
	var/bra_color = "#ffffff"
	var/socks = "Nude"
	var/socks_color = "#ffffff"
	var/jumpsuit_style = PREF_SUIT
	var/backpack = DBACKPACK
	var/skin_tone = "caucasian1"
	var/mutant_color = "#c0965f"
	var/mutant_color_2 = "#c0965f"
	var/mutant_color_3 = "#c0965f"
	var/eye_color = "#336699"
	var/eye_color_right = ""
	var/hair_gradient = "None"
	var/hair_gradient_color = "#ffffff"
	var/facial_gradient = "None"
	var/facial_gradient_color = "#ffffff"
	var/body_size = 1
	var/custom_species = ""
	var/custom_species_lore = ""
	var/flavor_text = ""
	var/flavor_text_nsfw = ""
	var/ooc_notes = ""
	var/headshot = ""
	var/character_scream = "Human Scream"
	var/character_laugh = "Human Laugh"
	var/chat_color = "#b0b0b0"
	var/blooper_choice = "none"
	var/blooper_speed = 50
	var/blooper_pitch = 50
	var/blooper_pitch_range = 30
	var/custom_taste = ""
	var/custom_smell = ""
	var/general_record = ""
	var/medical_record = ""
	var/security_record = ""
	var/exploitable_info = ""
	var/background_info = ""
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
	gender = pick(MALE, FEMALE)
	body_type = "Use gender"
	species_type = /datum/species/human
	randomize_names()
	biological_age = rand(AGE_MIN, 40)
	chronological_age = max(biological_age, biological_age + rand(0, 20))
	hair_color = ready_random_color()
	facial_hair_color = hair_color
	underwear_color = ready_random_color()
	undershirt_color = underwear_color
	bra_color = underwear_color
	socks_color = underwear_color
	jumpsuit_style = pick(PREF_SUIT, PREF_SKIRT)
	backpack = DBACKPACK
	skin_tone = length(GLOB.skin_tones) ? pick(GLOB.skin_tones) : "caucasian1"
	mutant_color = "#c0965f"
	mutant_color_2 = "#c0965f"
	mutant_color_3 = "#c0965f"
	eye_color = random_eye_color()
	eye_color_right = ""
	hair_gradient = "None"
	hair_gradient_color = "#ffffff"
	facial_gradient = "None"
	facial_gradient_color = "#ffffff"
	body_size = 1
	custom_species = ""
	custom_species_lore = ""
	flavor_text = ""
	flavor_text_nsfw = ""
	ooc_notes = ""
	headshot = ""
	character_scream = length(GLOB.scream_types) ? pick(GLOB.scream_types) : "Human Scream"
	character_laugh = length(GLOB.laugh_types) ? pick(GLOB.laugh_types) : "Human Laugh"
	chat_color = ready_random_color()
	blooper_choice = default_blooper_id()
	if(length(SSblooper.blooper_list) && prob(70))
		blooper_choice = pick(SSblooper.blooper_list)
	blooper_speed = rand(35, 70)
	blooper_pitch = rand(35, 70)
	blooper_pitch_range = rand(20, 40)
	randomize_appearance()
	custom_taste = ""
	custom_smell = ""
	general_record = ""
	medical_record = ""
	security_record = ""
	exploitable_info = ""
	background_info = ""
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
	reset_pref_bridge()

/datum/rimworld_preferences/proc/uses_skintones()
	var/datum/species/species = GLOB.species_prototypes[species_type]
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
	if(ispath(species_type, /datum/species))
		new_name = generate_random_name_species_based(gender, TRUE, species_type)
	if(!length(new_name))
		new_name = generate_random_name(gender, TRUE)
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
	hairstyle = "Bald"
	facial_hairstyle = "Shaved"
	underwear = "Nude"
	undershirt = "Nude"
	bra = "Nude"
	socks = "Nude"
	if(length(SSaccessories.hairstyles_list))
		hairstyle = random_hairstyle(gender) || "Bald"
	if(gender == MALE && prob(55) && length(SSaccessories.facial_hairstyles_list))
		facial_hairstyle = random_facial_hairstyle(gender) || "Shaved"
	if(length(SSaccessories.underwear_list))
		underwear = random_underwear(gender) || "Nude"
	if(length(SSaccessories.undershirt_list))
		undershirt = random_undershirt(gender) || "Nude"
	if(length(SSaccessories.bra_list))
		bra = random_bra(gender) || "Nude"
	if(length(SSaccessories.socks_list))
		socks = random_socks() || "Nude"

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
