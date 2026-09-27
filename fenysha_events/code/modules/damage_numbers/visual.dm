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

#undef BODYPART_SET
#undef DAMAGE_ICON_SET
#undef MAPTEXT_PEEPER_NOT_SMALL
