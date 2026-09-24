/datum/rw_xenogene
	abstract_type = /datum/rw_xenogene

	var/id
	var/name = "Xenogene"
	var/desc = "A xenogene stub."

	var/category = RW_XENOGENE_CATEGORY_COSMETIC
	var/xenogen_flags = NONE

	/// Sources currently keeping this xenogene on its owner.
	var/xenogen_source_flags = NONE

	var/mob/living/holder

	/// Kept for save compatibility. Xenogenes are available to every RW race.
	var/list/supported_species

	var/list/skill_bonuses

	/// RimWorld-style gene complexity. Summed on the colonist.
	var/complexity = 1
	/// Positive = eats less. Negative = eats more. Summed on the colonist.
	var/metabolic_efficiency = 0
	/// Red decagon in the editor. Neutral/positive genes are blue hexagons.
	var/negative = FALSE

	/// Character-point cost to add this gene. 0 = free until a gene is priced for balance.
	var/point_cost = 0
	/// Extra character-point cost to mark this pawn's copy inheritable (gray). 0 = not priced yet.
	var/inheritable_cost = 0
	/// Instance: this pawn's copy is passed to children. New genes start not inheritable.
	var/inheritable = FALSE
	/// Gene ids that cannot coexist with this one. Checked both ways.
	var/list/incompatible_with
	/// Genes sharing this tag cannot coexist. See RW_XENOGENE_GROUP_SKIN / EYES.
	var/incompatibility_group

	/// TGUI DmIcon file path, e.g. RW_XENOGENE_ICON_FILE. Do not name this `icon` — that is the /icon type.
	/// Background and glyph are separate 64x64 states, stacked as two DmIcons.
	/// Copy Hair: ui_icon, icon_bg, icon_state after adding a state to xenogenes.dmi.
	var/ui_icon
	var/icon_state
	var/icon_bg

	var/option_kind = RW_XENOGENE_OPTION_NONE
	var/option_key
	var/default_option
	var/option_min
	var/option_max
	var/option_step = 1
	var/list/option_choices
	/// Instance-only: currently selected style / number / colors.
	var/option_value
	var/toggle_pref_type
	var/value_pref_type


/datum/rw_xenogene/proc/is_supported(species_id)
	return TRUE


/datum/rw_xenogene/proc/is_innate()
	return !!(xenogen_source_flags & RW_XENOGEN_SOURCE_INNATE)


/datum/rw_xenogene/proc/is_acquired()
	return !!(xenogen_source_flags & RW_XENOGEN_SOURCE_ACQUIRED)


/datum/rw_xenogene/proc/get_option_choices()
	if(option_kind == RW_XENOGENE_OPTION_CHOICED)
		if(!islist(option_choices))
			return list()
		return option_choices.Copy()
	if(option_kind != RW_XENOGENE_OPTION_ACCESSORY || !option_key)
		return list()
	if(!SSaccessories?.sprite_accessories)
		return list()
	var/list/accessories = SSaccessories.sprite_accessories[option_key]
	if(!islist(accessories))
		return list()
	var/list/names = list()
	for(var/acc_name in accessories)
		if(acc_name == SPRITE_ACCESSORY_NONE || acc_name == "None")
			continue
		var/datum/sprite_accessory/accessory = accessories[acc_name]
		if(accessory?.locked)
			continue
		names += acc_name
	return names


/datum/rw_xenogene/proc/sanitize_option(value)
	switch(option_kind)
		if(RW_XENOGENE_OPTION_ACCESSORY, RW_XENOGENE_OPTION_CHOICED)
			var/list/choices = get_option_choices()
			if(value in choices)
				return value
			if(default_option in choices)
				return default_option
			if(length(choices))
				return choices[1]
			return default_option
		if(RW_XENOGENE_OPTION_NUMERIC)
			var/num_value = text2num(value)
			if(!isnum(num_value))
				num_value = text2num(default_option)
			if(!isnum(num_value))
				num_value = option_min
			return clamp(num_value, option_min, option_max)
		if(RW_XENOGENE_OPTION_TRICOLOR)
			var/list/colors = islist(value) ? value : list()
			var/fallback = islist(default_option) ? default_option : list("#FFFFFF", "#FFFFFF", "#FFFFFF")
			var/list/clean = list()
			for(var/index in 1 to 3)
				var/piece = (index <= length(colors)) ? colors[index] : fallback[index]
				if(!istext(piece) || !length(piece))
					piece = fallback[index]
				if(copytext(piece, 1, 2) != "#")
					piece = "#[piece]"
				clean += piece
			return clean
	return value


/datum/rw_xenogene/proc/compile_option_ui()
	if(option_kind == RW_XENOGENE_OPTION_NONE)
		return null
	var/list/data = list(
		"kind" = option_kind,
		"defaultOption" = default_option,
	)
	if(option_kind == RW_XENOGENE_OPTION_ACCESSORY || option_kind == RW_XENOGENE_OPTION_CHOICED)
		data["choices"] = get_option_choices()
	if(option_kind == RW_XENOGENE_OPTION_NUMERIC)
		data["min"] = option_min
		data["max"] = option_max
		data["step"] = option_step
	return data


/datum/rw_xenogene/proc/apply_to_preferences(datum/rimworld_preferences/prefs, enabled, value)
	if(!prefs)
		return
	if(toggle_pref_type)
		prefs.rw_set_pref(toggle_pref_type, enabled, force = TRUE)
	if(!enabled || !value_pref_type)
		return
	prefs.rw_set_pref(value_pref_type, sanitize_option(value), force = TRUE)


/datum/rw_xenogene/proc/create_instance(mob/living/new_holder, source_flags = RW_XENOGEN_SOURCE_ACQUIRED)
	SHOULD_CALL_PARENT(TRUE)

	var/datum/rw_xenogene/instance = new type

	instance.holder = new_holder
	instance.xenogen_source_flags = source_flags
	instance.option_value = option_value

	if(supported_species)
		instance.supported_species = supported_species.Copy()

	if(skill_bonuses)
		instance.skill_bonuses = skill_bonuses.Copy()
	if(incompatible_with)
		instance.incompatible_with = incompatible_with.Copy()
	instance.inheritable = inheritable

	return instance


/datum/rw_xenogene/proc/compile_icon_png(state)
	if(!length(state))
		return null
	switch(state)
		if("bg")
			return RW_XENOGENE_PNG_BG
		if("hair")
			return RW_XENOGENE_PNG_HAIR
	if(!length(ui_icon))
		return null
	var/icon/sheet = icon(RW_XENOGENE_ICONS, state, SOUTH, 1)
	if(!icon_has_pixels(sheet) && ui_icon != RW_XENOGENE_ICON_FILE)
		sheet = icon(file(ui_icon), state, SOUTH, 1)
	if(!icon_has_pixels(sheet))
		return null
	var/encoded = icon2base64(sheet)
	if(!istext(encoded) || !length(encoded))
		return null
	return encoded


/datum/rw_xenogene/proc/icon_has_pixels(icon/sheet)
	if(!isicon(sheet) || !sheet.Width() || !sheet.Height())
		return FALSE
	var/mid_x = max(1, sheet.Width() / 2)
	var/mid_y = max(1, sheet.Height() / 2)
	if(sheet.GetPixel(mid_x, mid_y))
		return TRUE
	if(sheet.GetPixel(mid_x, max(1, mid_y - 8)))
		return TRUE
	if(sheet.GetPixel(max(1, mid_x - 8), mid_y))
		return TRUE
	if(sheet.GetPixel(min(sheet.Width(), mid_x + 8), mid_y))
		return TRUE
	return FALSE


/datum/rw_xenogene/proc/apply_visual(mob/living/new_holder, adding = FALSE, forced_style = null)
	return


/datum/rw_xenogene/proc/on_gain(mob/living/new_holder)
	SHOULD_CALL_PARENT(TRUE)

	holder = new_holder

	if(xenogen_flags & RW_XENOGEN_PROCESSING)
		START_PROCESSING(SSxenogenes, src)

	return


/datum/rw_xenogene/proc/on_life(seconds_per_tick, mob/living/new_holder)
	SHOULD_CALL_PARENT(FALSE)

	return PROCESS_KILL


/datum/rw_xenogene/proc/on_lose(mob/living/new_holder)
	SHOULD_CALL_PARENT(TRUE)

	STOP_PROCESSING(SSxenogenes, src)
	holder = null

	return


/datum/rw_xenogene/proc/modify_skills(list/skill_levels)
	if(!skill_bonuses)
		return skill_levels

	for(var/skill_id in skill_bonuses)
		skill_levels[skill_id] = (skill_levels[skill_id] || 0) + skill_bonuses[skill_id]

	return skill_levels


/datum/rw_xenogene/proc/compile_effect_lines()
	var/list/lines = list()
	if(length(desc))
		lines += desc
	if(option_kind != RW_XENOGENE_OPTION_NONE)
		lines += "Right-click to choose a variant."
	if(complexity)
		lines += "Complexity [complexity]"
	if(metabolic_efficiency)
		lines += "Metabolic efficiency [metabolic_efficiency > 0 ? "+" : ""][metabolic_efficiency]"
	if(negative)
		lines += "Negative gene."
	if(point_cost)
		lines += "Point cost [point_cost]"
	if(inheritable_cost)
		lines += "Inheritable cost [inheritable_cost]"
	lines += inheritable ? "Inheritable." : "Not inheritable."
	var/list/incompat_names = compile_incompatibility_names()
	if(length(incompat_names))
		lines += "Incompatible with [jointext(incompat_names, ", ")]."
	if(skill_bonuses)
		for(var/skill_id in skill_bonuses)
			var/datum/rw_skill/skill = GLOB.all_rw_skills[skill_id]
			var/delta = skill_bonuses[skill_id]
			lines += "[skill?.name || skill_id]: [delta > 0 ? "+" : ""][delta]"
	if(!length(lines))
		lines += "No mechanical effect yet."
	return lines


/// True if this gene and other cannot be on the same pawn.
/datum/rw_xenogene/proc/is_incompatible_with(datum/rw_xenogene/other)
	if(!other || other == src || other.id == id)
		return FALSE
	if(incompatibility_group && incompatibility_group == other.incompatibility_group)
		return TRUE
	if(islist(incompatible_with) && (other.id in incompatible_with))
		return TRUE
	if(islist(other.incompatible_with) && (id in other.incompatible_with))
		return TRUE
	return FALSE


/// Gene ids from owned_ids that conflict with this gene.
/datum/rw_xenogene/proc/conflicts_with_ids(list/owned_ids)
	var/list/hits = list()
	if(!islist(owned_ids))
		return hits
	for(var/other_id in owned_ids)
		if(other_id == id)
			continue
		var/datum/rw_xenogene/other = GLOB.all_rw_xenogenes[other_id]
		if(other && is_incompatible_with(other))
			hits += other_id
	return hits


/datum/rw_xenogene/proc/compile_incompatibility_names()
	var/list/names = list()
	var/list/seen = list()
	if(incompatibility_group)
		for(var/gene_id in GLOB.all_rw_xenogenes)
			if(gene_id == id)
				continue
			var/datum/rw_xenogene/other = GLOB.all_rw_xenogenes[gene_id]
			if(!other || other.incompatibility_group != incompatibility_group)
				continue
			names += other.name
			seen[gene_id] = TRUE
	if(islist(incompatible_with))
		for(var/gene_id in incompatible_with)
			if(seen[gene_id])
				continue
			var/datum/rw_xenogene/listed = GLOB.all_rw_xenogenes[gene_id]
			names += listed ? listed.name : gene_id
			seen[gene_id] = TRUE
	for(var/gene_id in GLOB.all_rw_xenogenes)
		if(seen[gene_id] || gene_id == id)
			continue
		var/datum/rw_xenogene/other = GLOB.all_rw_xenogenes[gene_id]
		if(other && islist(other.incompatible_with) && (id in other.incompatible_with))
			names += other.name
	return names


/datum/rw_xenogene/Destroy()
	STOP_PROCESSING(SSxenogenes, src)
	holder = null

	return ..()


/datum/rw_xenogene/cosmetic
	abstract_type = /datum/rw_xenogene/cosmetic
	category = RW_XENOGENE_CATEGORY_COSMETIC
	xenogen_flags = RW_XENOGEN_VISUAL
	option_kind = RW_XENOGENE_OPTION_ACCESSORY

/datum/rw_xenogene/cosmetic/on_gain(mob/living/new_holder)
	. = ..()
	apply_visual(new_holder, TRUE)

/datum/rw_xenogene/cosmetic/on_lose(mob/living/new_holder)
	apply_visual(new_holder, FALSE)
	return ..()

/datum/rw_xenogene/cosmetic/apply_visual(mob/living/new_holder, adding = FALSE, forced_style = null)
	if(!option_key || !ishuman(new_holder))
		return
	var/mob/living/carbon/human/human_holder = new_holder
	if(!human_holder.dna)
		return
	if(!islist(human_holder.dna.mutant_bodyparts))
		human_holder.dna.mutant_bodyparts = list()
	var/style_name = sanitize_option(isnull(forced_style) ? option_value : forced_style)
	if(adding && style_name)
		var/list/colors = list("#FFFFFF", "#FFFFFF", "#FFFFFF")
		var/main_color
		if(islist(human_holder.dna.features))
			main_color = human_holder.dna.features[FEATURE_MUTANT_COLOR]
		if(main_color)
			colors = list(
				main_color,
				human_holder.dna.features[FEATURE_MUTANT_COLOR_TWO] || main_color,
				human_holder.dna.features[FEATURE_MUTANT_COLOR_THREE] || main_color,
			)
		human_holder.dna.mutant_bodyparts[option_key] = list(
			MUTANT_INDEX_NAME = style_name,
			MUTANT_INDEX_COLOR_LIST = colors,
			MUTANT_INDEX_EMISSIVE_LIST = list(FALSE, FALSE, FALSE),
		)
		if(option_key == FEATURE_SNOUT)
			var/obj/item/bodypart/head/head = human_holder.get_bodypart(BODY_ZONE_HEAD)
			if(head)
				head.bodyshape |= BODYSHAPE_SNOUTED
				human_holder.synchronize_bodytypes()
				human_holder.synchronize_bodyshapes()
		return
	var/list/defaults
	if(human_holder.dna.species)
		defaults = human_holder.dna.species.get_default_mutant_bodyparts()
	if(islist(defaults) && defaults[option_key])
		var/list/part_info = defaults[option_key]
		if(islist(part_info) && length(part_info) && part_info[1] && part_info[1] != SPRITE_ACCESSORY_NONE)
			human_holder.dna.mutant_bodyparts[option_key] = list(
				MUTANT_INDEX_NAME = part_info[1],
				MUTANT_INDEX_COLOR_LIST = list("#FFFFFF", "#FFFFFF", "#FFFFFF"),
				MUTANT_INDEX_EMISSIVE_LIST = list(FALSE, FALSE, FALSE),
			)
			return
	human_holder.dna.mutant_bodyparts -= option_key
	if(option_key == FEATURE_SNOUT)
		var/obj/item/bodypart/head/head = human_holder.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			head.bodyshape &= ~BODYSHAPE_SNOUTED
			human_holder.synchronize_bodytypes()
			human_holder.synchronize_bodyshapes()

/datum/rw_xenogene/stat
	abstract_type = /datum/rw_xenogene/stat
	category = RW_XENOGENE_CATEGORY_STAT

/datum/rw_xenogene/ability
	abstract_type = /datum/rw_xenogene/ability
	category = RW_XENOGENE_CATEGORY_ABILITY

/datum/rw_xenogene/cosmetic/hair
	id = RW_XENOGENE_HAIR
	name = "Hair"
	desc = "Grows scalp hair. Style is chosen in Persona."
	option_kind = RW_XENOGENE_OPTION_NONE
	// Copy this onto another gene after adding a 64x64 state to xenogenes.dmi:
	ui_icon = RW_XENOGENE_ICON_FILE
	icon_bg = "bg"
	icon_state = "hair"

/datum/rw_xenogene/cosmetic/smooth_skin
	id = RW_XENOGENE_SMOOTH_SKIN
	name = "Smooth skin"
	desc = "Typical human skin. Uses skin tones."
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

/datum/rw_xenogene/cosmetic/scaled_skin
	id = RW_XENOGENE_SCALED_SKIN
	name = "Scaled skin"
	desc = "Overlapping scales. Uses mutant colors instead of skin tones."
	option_kind = RW_XENOGENE_OPTION_NONE
	incompatibility_group = RW_XENOGENE_GROUP_SKIN

/datum/rw_xenogene/stat/cold_blooded
	id = RW_XENOGENE_COLD_BLOODED
	name = "Cold-blooded"
	desc = "Poor internal temperature regulation. Hungrier in the cold."
	metabolic_efficiency = -1

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

/datum/rw_xenogene/stat/body_size
	id = RW_XENOGENE_BODY_SIZE
	name = "Body size"
	desc = "Overall scale. Right-click to set a size."
	xenogen_flags = RW_XENOGEN_VISUAL
	option_kind = RW_XENOGENE_OPTION_NUMERIC
	default_option = RESIZE_DEFAULT_SIZE
	option_min = BODY_SIZE_MIN
	option_max = BODY_SIZE_MAX
	option_step = 0.01
	value_pref_type = /datum/preference/numeric/body_size

/datum/rw_xenogene/stat/body_size/apply_to_preferences(datum/rimworld_preferences/prefs, enabled, value)
	if(!prefs || !value_pref_type)
		return
	prefs.rw_set_pref(value_pref_type, enabled ? sanitize_option(value) : RESIZE_DEFAULT_SIZE, force = TRUE)

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

/datum/rw_xenogene/stat/frail
	id = RW_XENOGENE_FRAIL
	name = "Frail"
	desc = "Test negative gene. Weak constitution."
	negative = TRUE
	complexity = 1
	metabolic_efficiency = -1
