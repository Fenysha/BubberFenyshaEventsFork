/**
 * Avali — RW base race (BODY_TYPE), not a xenotype.
 * Sprites reuse teshari limbs until unique avali assets exist.
 */
#define AVALI_TEMP_OFFSET -10 // K, shifts the body's own normal temperature
#define AVALI_COLDMOD 0.5
#define AVALI_HEATMOD 1.25
/// Above this ambient air temperature (K) an avali is uncomfortable. Station air is ~293K, so this is the normal case.
#define AVALI_COMFORT_MAX (T0C + 10)
/// Above this it is very uncomfortable (still never lethal by itself).
#define AVALI_HOT_THRESHOLD (T0C + 35)

/datum/species/avali
	name = "Avali"
	plural_form = "Avali"
	id = SPECIES_AVALI
	examine_limb_id = SPECIES_TESHARI
	no_gender_shaping = TRUE
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_LITERATE,
		TRAIT_MUTANT_COLORS,
		TRAIT_NO_UNDERWEAR,
	)
	digitigrade_customization = DIGITIGRADE_NEVER
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	payday_modifier = 1.0
	mutanttongue = /obj/item/organ/tongue/teshari
	mutanteyes = /obj/item/organ/eyes/teshari
	custom_worn_icons = list(
		OFFSET_HEAD = TESHARI_HEAD_ICON,
		OFFSET_FACEMASK = TESHARI_MASK_ICON,
		OFFSET_NECK = TESHARI_NECK_ICON,
		OFFSET_SUIT = TESHARI_SUIT_ICON,
		OFFSET_UNIFORM = TESHARI_UNIFORM_ICON,
		OFFSET_GLOVES = TESHARI_HANDS_ICON,
		OFFSET_SHOES = TESHARI_FEET_ICON,
		OFFSET_GLASSES = TESHARI_EYES_ICON,
		OFFSET_BELT = TESHARI_BELT_ICON,
		OFFSET_BACK = TESHARI_BACK_ICON,
		OFFSET_ACCESSORY = TESHARI_ACCESSORIES_ICON,
		OFFSET_EARS = TESHARI_EARS_ICON,
	)
	mutantears = /obj/item/organ/ears/teshari
	mutantlungs = /obj/item/organ/lungs/adaptive/cold
	species_language_holder = /datum/language_holder/avali
	meat = /obj/item/food/meat/slab/chicken/human
	coldmod = AVALI_COLDMOD
	heatmod = AVALI_HEATMOD
	bodytemp_normal = BODYTEMP_NORMAL + AVALI_TEMP_OFFSET
	body_size_restricted = TRUE
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/mutant/teshari/avali,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/mutant/teshari/avali,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/mutant/teshari/avali,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/mutant/teshari/avali,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/mutant/teshari/avali,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/mutant/teshari/avali,
	)
	rw_label = "Avali"
	rw_default_xenotype_id = "baseline_avali"
	rw_innate_xenogenes = list(
		RW_XENOGENE_AVALI_EYES,
		RW_XENOGENE_AVALI_BODY,
		RW_XENOGENE_AVALI_EARS,
		RW_XENOGENE_AVALI_TAIL,
		RW_XENOGENE_AVALI_LEGS,
		RW_XENOGENE_DELICATE,
		RW_XENOGENE_MUTANT_COLORS,
		RW_XENOGENE_HEAT_WEAKNESS,
		RW_XENOGENE_COLD_SUPER_TOLERANT,
	)
	rw_innate_xenogene_values = list(
		RW_XENOGENE_AVALI_EARS = "Avali Regular",
		RW_XENOGENE_AVALI_TAIL = "Avali (Default)",
	)


/// Tail and ears come ONLY from the avali_tail / avali_ears xenogenes (so the race stays restricted to its own
/// sets and they always take the mutant colors). Listing them here would add a white copy next to the gene.
/datum/species/avali/get_default_mutant_bodyparts()
	return list(
		"legs" = list("Normal Legs", FALSE),
	)

// Worn icons: same teshari-sized sprites and greyscale fallbacks as /datum/species/teshari (items store them in worn_icon_teshari).
/datum/species/avali/get_custom_worn_icon(item_slot, obj/item/item)
	return item.worn_icon_teshari

/datum/species/avali/set_custom_worn_icon(item_slot, obj/item/item, icon/icon)
	item.worn_icon_teshari = icon

/datum/species/avali/get_custom_worn_config_fallback(item_slot, obj/item/item)
	// skirt support
	if(istype(item, /obj/item/clothing/under) && !(item.body_parts_covered & LEGS))
		return item.greyscale_config_worn_teshari_fallback_skirt
	return item.greyscale_config_worn_teshari_fallback

/datum/species/avali/generate_custom_worn_icon(item_slot, obj/item/item, mob/living/carbon/human/human_owner)
	. = ..()
	if(.)
		return
	return generate_teshari_style_worn_icon(item_slot, item, human_owner)


/datum/species/avali/on_species_gain(mob/living/carbon/human/new_avali, datum/species/old_species, pref_load, regenerate_icons)
	. = ..()
	ADD_TRAIT(new_avali, TRAIT_PASSTABLE, SPECIES_TRAIT)

/datum/species/avali/on_species_loss(mob/living/carbon/human/old_avali, datum/species/new_species, pref_load)
	. = ..()
	REMOVE_TRAIT(old_avali, TRAIT_PASSTABLE, SPECIES_TRAIT)
	old_avali.clear_mood_event("avali_warm")


/datum/species/avali/create_pref_unique_perks()
	var/list/perk_descriptions = list()
	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_SNOWFLAKE,
		SPECIES_PERK_NAME = "Frozen World Native",
		SPECIES_PERK_DESC = "Avali are adapted to extreme cold and take much less damage from it.",
	))
	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_TEMPERATURE_HIGH,
		SPECIES_PERK_NAME = "Heat Discomfort",
		SPECIES_PERK_DESC = "Ordinary room temperature is unpleasant for an avali and drags their mood down. Hot places are worse.",
	))
	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_RUNNING,
		SPECIES_PERK_NAME = "Tablerunning",
		SPECIES_PERK_DESC = "Small and agile, you can jump on tables just by running into them!",
	))
	return perk_descriptions

/datum/species/avali/get_species_description()
	return list(
		"Avali are a small, highly social race of feathered raptors from a frozen world. \
		They live in tight-knit packs, possess advanced genetics and nanotechnology, \
		and their bodies are perfectly adapted to extreme cold."
	)

/datum/species/avali/get_species_lore()
	return list(
		"Avali originated on a frozen planet of endless snow and ice fields. \
		Harsh climate and scarce resources forced them to develop extreme social dependence — \
		an individual Avali can barely survive without their pack. Loyalty to the pack \
		overrides family, nation, and even self-preservation.",

		"Physically, Avali are light, fast, and extremely agile. Their bodies are covered \
		in dense feathers and down that provide excellent insulation, but make them highly \
		vulnerable to heat. Large eyes are adapted for twilight and blizzards, while long \
		feathered ears and tails serve both communication and balance.",

		"Technologically, Avali have always been ahead of most races. They were among the \
		first to master deep genetic engineering and nanotechnology, freely modifying their \
		own bodies. Many Avali consider an unmodified member of their species already outdated — \
		self-improvement through xenogenes is a normal part of life.",

		"Avali culture values quick thinking, absolute pack loyalty, and the ability to work \
		as a unit. Solitude is almost pathological to them. They are curious, talkative, \
		sometimes overly confident in their technological superiority, but rarely truly \
		malicious toward those they consider their own."
	)
