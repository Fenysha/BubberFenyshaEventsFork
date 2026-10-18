/**
 * Avali — RW base race (BODY_TYPE), not a xenotype.
 * Sprites reuse teshari limbs until unique avali assets exist.
 */
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
	body_size_restricted = TRUE
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/mutant/teshari,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/mutant/teshari,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/mutant/teshari,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/mutant/teshari,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/mutant/teshari,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/mutant/teshari,
	)
	rw_label = "Avali"
	rw_default_xenotype_id = "baseline_avali"
	rw_innate_xenogenes = list(
		RW_XENOGENE_AVALI_EYES,
		RW_XENOGENE_AVALI_BODY,
		RW_XENOGENE_AVALI_EYES,
		RW_XENOGENE_AVALI_TAIL,
		RW_XENOGENE_AVALI_LEGS,
		RW_XENOGENE_DELICATE,
		RW_XENOGENE_MUTANT_COLORS,
		RW_XENOGENE_HEAT_WEAKNESS,
		RW_XENOGENE_COLD_SUPER_TOLERANT,
	)
	rw_innate_xenogene_values = list(
		RW_XENOGENE_AVALI_EYES = "Avali Regular",
		RW_XENOGENE_AVALI_TAIL = "Avali (Default)",
	)

/datum/species/avali/get_default_mutant_bodyparts()
	return list(
		"tail" = list("Avali (Default)", TRUE),
		"ears" = list("Avali Regular", TRUE),
		"legs" = list("Normal Legs", FALSE),
	)

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
