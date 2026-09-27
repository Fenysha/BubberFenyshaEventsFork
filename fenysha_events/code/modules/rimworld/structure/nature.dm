/obj/structure/rimworld/flora/grayscale/grass
	name = "Grass"
	desc = "Ordinary grass"

	icon = 'fenysha_events/icons/structures/nature/grass_grayscale.dmi'
	icon_state = "sparsegrass_1"
	base_icon_state = "sparsegrass"

	foliage_color = GRASS_COLOR_FOREST
	var/variant_amount = 3


/obj/structure/rimworld/flora/grayscale/grass/Initialize(mapload)
	if(!visual_ready)
		icon_state = "[base_icon_state]_[rand(1, variant_amount)]"
	. = ..()

/obj/structure/rimworld/flora/grayscale/grass/alt
	icon_state = "fullgrass_1"
	base_icon_state = "fullgrass"
	foliage_color = GRASS_COLOR_FOREST_TALL

/obj/structure/rimworld/flora/grayscale/grass/jungle
	icon_state = "leafybush_1"
	base_icon_state = "leafybush"
	foliage_color = GRASS_COLOR_JUNGLE






/obj/structure/rimworld/flora/grayscale/bush
	name = "bush"
	desc = "A leafy bush."
	icon = 'icons/obj/fluff/flora/snowflora.dmi'
	icon_state = "snowgrass1gb"
	density = FALSE
	harvestable = TRUE
	harvest_with_hands = TRUE
	harvest_verb = "forage"
	foliage_color = GRASS_COLOR_FOREST
	harvest_products = list() // fill with berries/herbs as needed

/obj/structure/rimworld/flora/grayscale/bush/forest
	name = "forest bush"
	foliage_color = GRASS_COLOR_FOREST

/obj/structure/rimworld/flora/grayscale/bush/forest/light
	name = "light forest bush"
	foliage_color = GRASS_COLOR_FOREST_LIGHT


// --- Jungle / rainforest ---
/obj/structure/rimworld/flora/grayscale/tree/jungle
	name = "jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE
	max_integrity = 200

/obj/structure/rimworld/flora/grayscale/tree/jungle/tall
	name = "tall jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE_TALL
	max_integrity = 260
	destroy_amount_low = 10
	destroy_amount_high = 16

/obj/structure/rimworld/flora/grayscale/bush/jungle
	name = "jungle undergrowth"
	foliage_color = GRASS_COLOR_JUNGLE_LIGHT


// --- Savanna ---
/obj/structure/rimworld/flora/grayscale/tree/savanna
	name = "savanna tree"
	desc = "A sparse, hardy tree of the open plains."
	foliage_color = GRASS_COLOR_SAVANNA
	max_integrity = 140
	destroy_amount_low = 4
	destroy_amount_high = 8

/obj/structure/rimworld/flora/grayscale/bush/savanna
	name = "dry scrub"
	foliage_color = GRASS_COLOR_SAVANNA_LIGHT
	// Milder fall tint feels odd on already-yellow foliage; still seasonal
	seasonal_color = TRUE


// --- Taiga / snow ---
/obj/structure/rimworld/flora/grayscale/tree/taiga
	name = "pine tree"
	desc = "A needle-leaf tree adapted to cold climates."
	icon = 'icons/obj/fluff/flora/pinetrees.dmi'
	icon_state = "pine_1"
	foliage_color = "#3D6B4F"
	// Evergreens: weak seasonal shift
	seasonal_color = TRUE

/obj/structure/rimworld/flora/grayscale/tree/taiga/update_season_visual(atom/host, hemisphere, old_season, new_season, quadrum, year)
	// Evergreen: only a slight winter desaturation
	if(!seasonal_color || !base_color)
		return
	var/tint
	var/amount
	switch(new_season)
		if(RW_SEASON_WINTER)
			tint = RW_SEASON_TINT_WINTER
			amount = 0.2
		if(RW_SEASON_FALL)
			tint = RW_SEASON_TINT_FALL
			amount = 0.08
		else
			reset_to_base_color()
			refresh_grayscale_overlay_color()
			return
	modulate_color_towards(tint, amount)
	refresh_grayscale_overlay_color()


/obj/structure/rimworld/flora/grayscale/cactus
	name = "cactus"
	desc = "A spiny desert plant."
	foliage_color = "#6B8F5E"
	seasonal_color = FALSE
	can_uproot = TRUE
	harvestable = FALSE
	density = FALSE


/obj/structure/rimworld/flora/grayscale/bush/tundra
	name = "tundra shrub"
	foliage_color = "#7A8B6A"
	seasonal_color = TRUE

