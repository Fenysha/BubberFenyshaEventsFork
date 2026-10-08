/datum/rw_xenogene/cosmetic/hair
	id = RW_XENOGENE_HAIR
	name = "Hair"
	desc = "Grows scalp hair. Style is chosen in Persona."
	option_kind = RW_XENOGENE_OPTION_NONE
	ui_icon = RW_XENOGENE_ICON_FILE
	icon_bg = "bg"
	icon_state = "hair"

/datum/rw_xenogene/cosmetic/smooth_skin
	id = RW_XENOGENE_SMOOTH_SKIN
	name = "Smooth skin"
	desc = "Typical human skin. Uses skin tones."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_SKIN

/datum/rw_xenogene/cosmetic/scaled_skin
	id = RW_XENOGENE_SCALED_SKIN
	name = "Scaled skin"
	desc = "Overlapping scales. Uses mutant colors instead of skin tones."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_SKIN

/datum/rw_xenogene/cosmetic/human_eyes
	id = RW_XENOGENE_HUMAN_EYES
	name = "Human eyes"
	desc = "Round primate eyes. Color is chosen in Persona."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_EYES

/datum/rw_xenogene/cosmetic/lizard_eyes
	id = RW_XENOGENE_LIZARD_EYES
	name = "Lizard eyes"
	desc = "Slit reptilian eyes. Color is chosen in Persona."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_EYES

/datum/rw_xenogene/cosmetic/avali_eyes
	id = RW_XENOGENE_AVALI_EYES
	name = "Avali eyes"
	desc = "Large avian eyes. Color is chosen in Persona."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_EYES

/datum/rw_xenogene/cosmetic/ears
	id = RW_XENOGENE_EARS
	name = "Ears"
	desc = "External ears. Right-click to pick a style."
	option_key = FEATURE_EARS
	default_option = "Fox"
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/ears
	value_pref_type = /datum/preference/choiced/mutant_choice/ears

/datum/rw_xenogene/cosmetic/tail
	id = RW_XENOGENE_TAIL
	name = "Tail"
	desc = "A tail. Right-click to pick a style."
	option_key = FEATURE_TAIL_GENERIC
	default_option = "Smooth"
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/tail
	value_pref_type = /datum/preference/choiced/mutant_choice/tail

/datum/rw_xenogene/cosmetic/wings
	id = RW_XENOGENE_WINGS
	name = "Wings"
	desc = "A pair of wings. Right-click to pick a style."
	option_key = FEATURE_WINGS
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/wings
	value_pref_type = /datum/preference/choiced/mutant_choice/wings

/datum/rw_xenogene/cosmetic/fluff
	id = RW_XENOGENE_FLUFF
	name = "Body fur"
	desc = "Fluff, fur or down covering the body. Right-click to pick a style."
	option_key = FEATURE_FLUFF
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/fluff
	value_pref_type = /datum/preference/choiced/mutant_choice/fluff

/datum/rw_xenogene/cosmetic/legs
	id = RW_XENOGENE_LEGS
	name = "Leg type"
	desc = "Plantigrade or digitigrade legs."
	option_kind = RW_XENOGENE_OPTION_CHOICED
	option_key = FEATURE_LEGS
	option_choices = list(NORMAL_LEGS, DIGITIGRADE_LEGS)
	default_option = NORMAL_LEGS
	value_pref_type = /datum/preference/choiced/digitigrade_legs

/datum/rw_xenogene/cosmetic/legs/apply_to_preferences(datum/rimworld_preferences/prefs, enabled, value)
	if(!prefs || !value_pref_type)
		return
	prefs.rw_set_pref(value_pref_type, enabled ? sanitize_option(value) : NORMAL_LEGS, force = TRUE)

/datum/rw_xenogene/cosmetic/legs/apply_visual(mob/living/new_holder, adding, forced_style)
	if(!ishuman(new_holder))
		return
	var/mob/living/carbon/human/human_holder = new_holder
	if(!human_holder.dna)
		return
	var/style_name = adding ? sanitize_option(isnull(forced_style) ? option_value : forced_style) : NORMAL_LEGS
	if(human_holder.dna.features[FEATURE_LEGS] == style_name)
		return
	human_holder.dna.features[FEATURE_LEGS] = style_name
	if(istype(human_holder, /mob/living/carbon/human/dummy))
		return
	if(style_name == DIGITIGRADE_LEGS)
		if(human_holder.dna.species)
			human_holder.dna.species.try_make_digitigrade(human_holder)
		return
	if(!human_holder.dna.species)
		return
	var/datum/species/reset_species = new human_holder.dna.species.type
	human_holder.dna.species.bodypart_overrides = reset_species.bodypart_overrides
	qdel(reset_species)
	human_holder.dna.species.replace_body(human_holder, human_holder.dna.species)

/datum/rw_xenogene/cosmetic/mutant_colors
	id = RW_XENOGENE_MUTANT_COLORS
	name = "Mutant colors"
	desc = "Three colors used by xenogene parts. Right-click to paint them."
	option_kind = RW_XENOGENE_OPTION_TRICOLOR
	default_option = list("#C0965F", "#C0965F", "#C0965F")
	value_pref_type = /datum/preference/tri_color/mutant_colors

/datum/rw_xenogene/cosmetic/mutant_colors/apply_visual(mob/living/new_holder, adding, forced_style)
	if(!adding || !ishuman(new_holder))
		return
	var/mob/living/carbon/human/human_holder = new_holder
	if(!human_holder.dna)
		return
	var/list/colors = sanitize_option(isnull(forced_style) ? option_value : forced_style)
	if(!islist(human_holder.dna.features))
		human_holder.dna.features = list()
	human_holder.dna.features[FEATURE_MUTANT_COLOR] = colors[1]
	human_holder.dna.features[FEATURE_MUTANT_COLOR_TWO] = colors[2]
	human_holder.dna.features[FEATURE_MUTANT_COLOR_THREE] = colors[3]

/datum/rw_xenogene/cosmetic/snout
	id = RW_XENOGENE_SNOUT
	name = "Snout"
	desc = "A muzzle. Right-click to pick a style."
	option_key = FEATURE_SNOUT
	default_option = "Sharp + Light"
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/snout
	value_pref_type = /datum/preference/choiced/mutant_choice/snout

/datum/rw_xenogene/cosmetic/horns
	id = RW_XENOGENE_HORNS
	name = "Horns"
	desc = "Head horns. Right-click to pick a style."
	option_key = FEATURE_HORNS
	default_option = "Simple"
	toggle_pref_type = /datum/preference/toggle/mutant_toggle/horns
	value_pref_type = /datum/preference/choiced/mutant_choice/horns

/datum/rw_xenogene/cosmetic/body_hulk
	id = RW_XENOGENE_BODY_HULK
	name = "Hulk body"
	desc = "Large, muscular body type."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_BODY_TYPE

/datum/rw_xenogene/cosmetic/body_fat
	id = RW_XENOGENE_BODY_FAT
	name = "Fat body"
	desc = "Heavy body type."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_BODY_TYPE

/datum/rw_xenogene/cosmetic/body_thin
	id = RW_XENOGENE_BODY_THIN
	name = "Thin body"
	desc = "Slender body type."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_BODY_TYPE

/datum/rw_xenogene/cosmetic/body_standard
	id = RW_XENOGENE_BODY_STANDARD
	name = "Standard body"
	desc = "Average body type."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_BODY_TYPE

/datum/rw_xenogene/cosmetic/no_hair
	id = RW_XENOGENE_NO_HAIR
	name = "No hair"
	desc = "Grows no scalp hair."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_HAIR_STYLE

/datum/rw_xenogene/cosmetic/short_hair_only
	id = RW_XENOGENE_SHORT_HAIR_ONLY
	name = "Short-haired"
	desc = "Can only grow short hair."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_HAIR_STYLE

/datum/rw_xenogene/cosmetic/long_hair_only
	id = RW_XENOGENE_LONG_HAIR_ONLY
	name = "Long-haired"
	desc = "Hair grows very quickly."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_HAIR_STYLE
