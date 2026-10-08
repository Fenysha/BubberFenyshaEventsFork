#define MAPTEXT_PEEPER_NOT_SMALL(text) MAPTEXT("<span style='font-size:100%;-dm-text-outline: 0.5px black;color: #FFF;'>[text]</span>")
#define DAMAGE_ICON_SET 'fenysha_events/icons/hud/icons_damage.dmi'
#define BODYPART_SET 'icons/hud/screen_gen.dmi'

/obj/effect/temp_visual/damage_numbers
	icon = null
	icon_state = ""
	duration = 4 SECONDS
	plane = BALLOON_CHAT_PLANE

/obj/effect/temp_visual/damage_numbers/Initialize(mapload, damage_amount, body_zone_name = null, damagetype = null)
	. = ..()

	var/display_text = ""
	if(damagetype)
		display_text += "<img src='[DAMAGE_ICON_SET]' iconstate='[damagetype]' style='vertical-align:middle;'> "
	display_text += "[damage_amount]" // debug:[body_zone_name]

	maptext = MAPTEXT_PEEPER_NOT_SMALL(display_text)
	maptext_y = 16
	maptext_x = 16
	maptext_width = 96
	var/xofs = rand(16, 32) * (prob(50) ? 1 : -1)
	var/yofs = rand(20, 40)
	animate(src, maptext_y = yofs, time = 8, easing = EASE_OUT | QUAD_EASING, flags = ANIMATION_RELATIVE)
	animate(alpha = -255, maptext_y = yofs * -1, time = 8, easing = EASE_IN | QUAD_EASING, flags = ANIMATION_RELATIVE)
	animate(maptext_x = xofs * 1.5, time = 16, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
	if(body_zone_name)
		var/damage_icon = image(BODYPART_SET, body_zone_name)
		overlays += damage_icon

/// Floating text effect for combat callouts such as a perfect parry.
/obj/effect/temp_visual/combat_text
	icon = null
	icon_state = ""
	duration = 4 SECONDS
	plane = BALLOON_CHAT_PLANE


/obj/effect/temp_visual/combat_text/Initialize(mapload, display_text, text_color = "#FFFFFF")
	. = ..()
	maptext = MAPTEXT("<span style='text-align:center; -dm-text-outline: 1px #000; color: [text_color];'>[html_encode(display_text)]</span>")
	maptext_y = 16
	maptext_x = -16
	maptext_width = 128
	var/y_offset = rand(24, 36)
	animate(src, maptext_y = y_offset, time = 8, easing = EASE_OUT | QUAD_EASING, flags = ANIMATION_RELATIVE)
	animate(alpha = -255, maptext_y = -y_offset, time = 8, easing = EASE_IN | QUAD_EASING, flags = ANIMATION_RELATIVE)
	animate(maptext_x = rand(-12, 12), time = 16, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)

/// Creates floating combat text at an atom's turf.
/proc/create_floating_combat_text(atom/location, display_text, text_color = "#FFFFFF")
	if(!location || !length(display_text))
		return

	var/turf/text_turf = get_turf(location)
	if(!text_turf)
		return

	return new /obj/effect/temp_visual/combat_text(text_turf, display_text, text_color)

#undef BODYPART_SET
#undef DAMAGE_ICON_SET
#undef MAPTEXT_PEEPER_NOT_SMALL
