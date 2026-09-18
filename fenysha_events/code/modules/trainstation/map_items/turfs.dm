/turf/open/indestructible/grass
	name = "grass patch"
	desc = "It's reall grass, touch it."
	icon_state = "grass"

	baseturfs = /turf/open/indestructible/grass
	planetary_atmos = TRUE

	flags_1 = NONE
	bullet_bounce_sound = null
	footstep = FOOTSTEP_GRASS
	barefootstep = FOOTSTEP_GRASS
	clawfootstep = FOOTSTEP_GRASS
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_turf = FALSE
	rust_resistance = RUST_RESISTANCE_ORGANIC

/turf/open/indestructible/grass/Initialize(mapload)
	. = ..()
	spawniconchange()
	AddElement(/datum/element/diggable, /obj/item/stack/ore/glass, 2, worm_chance = 50, \
		action_text = "uproot", action_text_third_person = "uproots")

/turf/open/indestructible/grass/proc/spawniconchange()
	icon_state = "grass[rand(0,3)]"

/turf/open/indestructible/asphalt
	name = "asphalt"
	desc = "Melted down oil can, in some cases, be used to pave road surfaces."
	icon_state = "asphalt"
