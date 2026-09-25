/atom/movable/screen/map_view/rw_char_preview
	name = "rw_character_preview"
	var/datum/rimworld_preferences/preferences

/atom/movable/screen/map_view/rw_char_preview/Initialize(mapload, datum/hud/hud_owner, datum/rimworld_preferences/new_prefs)
	. = ..()
	preferences = new_prefs

/atom/movable/screen/map_view/rw_char_preview/Destroy()
	vis_contents.Cut()
	preferences?.character_preview_view = null
	preferences = null
	return ..()

/atom/movable/screen/map_view/rw_char_preview/proc/show_dummy(mob/living/carbon/human/dummy/body)
	if(!body)
		vis_contents.Cut()
		return
	vis_contents.Cut()
	vis_contents += body

/datum/rimworld_preferences/proc/ensure_preview_dummy()
	if(preview_dummy && !QDELETED(preview_dummy))
		return preview_dummy
	preview_dummy = new /mob/living/carbon/human/dummy
	ADD_TRAIT(preview_dummy, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	STOP_FLOATING_ANIM(preview_dummy)
	return preview_dummy

/datum/rimworld_preferences/proc/ensure_preview_map()
	if(character_preview_view && !QDELETED(character_preview_view))
		return character_preview_view
	character_preview_view = new(null, null, src)
	character_preview_view.generate_view("rwcharacterpreview")
	return character_preview_view

/datum/rimworld_preferences/proc/update_preview()
	var/mob/living/carbon/human/dummy/mannequin = ensure_preview_dummy()
	mannequin.wipe_state()
	apply_to_human(mannequin, TRUE)
	mannequin.setDir(preview_dir)
	STOP_FLOATING_ANIM(mannequin)
	mannequin.pixel_z = 0
	var/atom/movable/screen/map_view/rw_char_preview/preview = ensure_preview_map()
	preview.show_dummy(mannequin)
	cache_portrait_for_slot(default_slot, mannequin)

/datum/rimworld_preferences/proc/clothing_overlay_for(datum/sprite_accessory/accessory, color, mob/living/carbon/human/target)
	if(!istype(accessory))
		return null
	if(lowertext(accessory.name) == "nude")
		return null
	if(istype(accessory, /datum/sprite_accessory/clothing))
		var/datum/sprite_accessory/clothing/clothes = accessory
		var/mutable_appearance/drawn = clothes.make_appearance(color || COLOR_WHITE, target.physique, target.bodyshape)
		if(!drawn)
			return null
		drawn.dir = SOUTH
		return drawn
	if(!accessory.icon || !accessory.icon_state)
		return null
	var/mutable_appearance/fallback = mutable_appearance(accessory.icon, accessory.icon_state, -BODY_LAYER)
	fallback.appearance_flags |= RESET_COLOR|KEEP_APART
	fallback.dir = SOUTH
	if(!accessory.use_static && color)
		fallback.color = color
	return fallback

/datum/rimworld_preferences/proc/apply_dummy_clothes(mob/living/carbon/human/target)
	if(!istype(target))
		return
	target.underwear_visibility = NONE
	target.remove_overlay(BODY_LAYER)
	var/list/clothes = list()
	var/mutable_appearance/piece
	if(SSaccessories.underwear_list)
		piece = clothing_overlay_for(SSaccessories.underwear_list[target.underwear], target.underwear_color, target)
		if(piece)
			clothes += piece
	if(SSaccessories.bra_list)
		piece = clothing_overlay_for(SSaccessories.bra_list[target.bra], target.bra_color, target)
		if(piece)
			clothes += piece
	if(SSaccessories.undershirt_list)
		piece = clothing_overlay_for(SSaccessories.undershirt_list[target.undershirt], target.undershirt_color, target)
		if(piece)
			clothes += piece
	if(SSaccessories.socks_list)
		piece = clothing_overlay_for(SSaccessories.socks_list[target.socks], target.socks_color, target)
		if(piece)
			clothes += piece
	if(length(clothes))
		target.overlays_standing[BODY_LAYER] = clothes
		target.apply_overlay(BODY_LAYER)

/datum/rimworld_preferences/proc/cache_portrait_for_slot(slot, mob/living/carbon/human/mannequin)
	if(!istype(mannequin))
		portrait_cache -= "[slot]"
		return
	var/old_dir = mannequin.dir
	mannequin.setDir(SOUTH)
	var/icon/flat = getFlatIcon(mannequin, SOUTH, null, null, null, TRUE, TRUE)
	mannequin.setDir(old_dir)
	if(!flat)
		portrait_cache -= "[slot]"
		return
	var/width = flat.Width()
	var/height = flat.Height()
	if(width > 0 && height > 1)
		var/keep_top = max(1, round(height * (1 - RW_BUST_CROP)))
		var/y1 = max(1, height - keep_top + 1)
		flat.Crop(1, y1, width, height)
	portrait_cache["[slot]"] = icon2base64(flat)

/datum/rimworld_preferences/proc/warm_portraits()
	for(var/index in 1 to max_save_slots)
		if(portrait_cache["[index]"])
			continue
		if(index == default_slot)
			if(preview_dummy && !QDELETED(preview_dummy))
				cache_portrait_for_slot(index, preview_dummy)
			continue
		var/list/data
		if(savefile)
			data = savefile.get_entry(slot_key(index))
		if(!data)
			continue
		var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(RW_PORTRAIT_DUMMY)
		apply_saved_look(mannequin, data)
		mannequin.setDir(SOUTH)
		STOP_FLOATING_ANIM(mannequin)
		cache_portrait_for_slot(index, mannequin)
		unset_busy_human_dummy(RW_PORTRAIT_DUMMY)

/datum/rimworld_preferences/proc/backstory_display_name(story_id)
	var/datum/rw_backstory/story = GLOB.all_rw_backstories[story_id]
	if(!story || story.id == "adulthood_none" || story.id == "childhood_none")
		return ""
	return story.name
