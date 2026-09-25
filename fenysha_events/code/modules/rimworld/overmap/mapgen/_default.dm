/datum/controller/subsystem/atoms/proc/NewUninitialized(atom_path, atom/newloc)
	if(!ispath(atom_path, /atom))
		CRASH("NewUninitialized: [atom_path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)

	var/source = "NewUninitialized [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)

	var/atom/created = new atom_path(newloc)

	clear_tracked_initalize(source)

	return created


/datum/controller/subsystem/atoms/proc/NewUninitializedArgs(
	atom_path,
	atom/newloc,
	list/extra_args
)
	if(!ispath(atom_path, /atom))
		CRASH("NewUninitializedArgs: [atom_path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)

	var/source = "NewUninitializedArgs [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)

	var/atom/created

	if(length(extra_args))
		created = new atom_path(arglist(list(newloc) + extra_args))
	else
		created = new atom_path(newloc)

	clear_tracked_initalize(source)

	return created



/datum/map_generator/sub_level
	var/datum/rimworld_planet/planet
	var/datum/planet_cell/cell

	var/planet_x = 1
	var/planet_y = 1

	/// The planet tile's hex ring: list(list("elevation", "bearing"), ...), bearing clockwise from north
	var/list/hex_neighbourhood

	var/generate_caves = TRUE

	var/list/heights
	var/list/cave_mask

	var/width = 0
	var/height = 0

	var/datum/biome/rimworld/target_biome
	var/sub_biome = RW_SUBBIOME_PLAINS
	var/area/rimworld/rimworld_area

	var/origin_x = 1
	var/origin_y = 1
	var/origin_z = 1
	var/list/transition_mask
	var/list/content_plan
	var/has_content_plan = FALSE
	var/has_stamp = FALSE
	var/list/stamp_turf_palette
	var/list/stamp_content_palette
	var/list/stamp_turf_ids
	var/list/stamp_content_ids
	var/list/stamp_colors
	var/list/stamp_content_colors
	var/list/stamp_icon_states
	var/list/stamp_content_variants
	var/stamp_rock_name
	var/stamp_rock_hp = 1
	var/datum/material/rimworld_material/stamp_rock_material
	var/list/stamp_edges
	var/list/stamp_junctions
	var/stamp_edge_cursor = 1
	var/stamp_hemisphere = "north"
	var/list/stamp_path_cache

	var/list/generated_turfs = list()
	var/list/generated_open_turfs = list()
	/// Parallel to generated_open_turfs: TRUE if that open turf is a cave tile.
	var/list/generated_open_is_cave = list()
	/// Parallel to generated_open_turfs. 0 empty, 1 flora, 2 feature, 3 fauna.
	var/list/generated_open_content = list()
	var/list/pending_init = list()

	var/turfs_initialized = FALSE


/datum/map_generator/sub_level/proc/setup_planet_context(
	datum/rimworld_planet/P,
	px,
	py,
	datum/planet_cell/C
)
	planet = P
	planet_x = px
	planet_y = py
	cell = C
	cache_planetary_neighborhood()


/datum/map_generator/sub_level/proc/cache_planetary_neighborhood()
	if(!planet)
		return FALSE

	hex_neighbourhood = list()
	for(var/list/neighbour as anything in planet.get_neighbor_ring(planet_x, planet_y))
		// Locals, not neighbour["x"] inline: quotes nested in an embedded expression break DM's parser
		var/neighbour_x = neighbour["x"]
		var/neighbour_y = neighbour["y"]
		var/elevation_text = planet.get_elevation_level(neighbour_x, neighbour_y)
		var/value = text2num("[elevation_text]")
		if(isnull(value))
			log_world(
				"RimWorld sub-level: invalid elevation value for planetary coordinate [neighbour_x],[neighbour_y]."
			)
			return FALSE
		hex_neighbourhood += list(list(
			"elevation" = clamp(round(value), 0, 5),
			"bearing" = neighbour["bearing"],
		))

	return TRUE


/datum/map_generator/sub_level/proc/get_target_biome(
	elevation = null,
	heat = null,
	humidity = null,
	biome = null
)
	if(!planet)
		return null

	var/macro_elevation = isnull(elevation) \
		? planet.get_elevation_level(planet_x, planet_y) \
		: elevation

	var/macro_heat = isnull(heat) \
		? planet.get_heat_level(planet_x, planet_y) \
		: heat

	var/macro_humidity = isnull(humidity) \
		? planet.get_humidity_level(planet_x, planet_y) \
		: humidity

	var/macro_biome = isnull(biome) \
		? planet.get_biome(
			planet_x,
			planet_y,
			macro_elevation,
			macro_heat,
			macro_humidity
		) \
		: biome

	var/biome_type = planet.get_possible_biomes()[macro_biome]

	var/datum/biome/rimworld/resolved_biome

	if(biome_type)
		resolved_biome = SSmapping.biomes[biome_type]

	if(!istype(resolved_biome, /datum/biome/rimworld))
		resolved_biome = SSmapping.biomes[/datum/biome/rimworld/grassland]

	return resolved_biome


/datum/map_generator/sub_level/proc/is_geological_transition_xy(
	local_x,
	local_y
)
	if(!length(heights))
		return FALSE

	if(local_x < 1 || local_x > width)
		return FALSE

	if(local_y < 1 || local_y > height)
		return FALSE

	var/index = width * (local_y - 1) + local_x
	var/current_height = heights[index]

	if(local_x > 1)
		if(abs(current_height - heights[index - 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_x < width)
		if(abs(current_height - heights[index + 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_y > 1)
		if(abs(current_height - heights[index - width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_y < height)
		if(abs(current_height - heights[index + width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	return FALSE


/datum/map_generator/sub_level/proc/prepare_sub_level_terrain(
	datum/turf_reservation/sub_level/reservation
)
	if(!planet || !cell || !reservation)
		return FALSE

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()

	if(!BL || !TR)
		return FALSE

	width = reservation.inner_width
	height = reservation.inner_height

	if(
		width != RW_SUBLEVEL_INNER_WIDTH \
		|| height != RW_SUBLEVEL_INNER_HEIGHT
	)
		return FALSE

	/*
	 * Resolve the macro planetary context once.
	 */
	var/macro_elevation = planet.get_elevation_level(
		planet_x,
		planet_y
	)

	var/macro_heat = planet.get_heat_level(
		planet_x,
		planet_y
	)

	var/macro_humidity = planet.get_humidity_level(
		planet_x,
		planet_y
	)

	var/macro_biome = planet.get_biome(
		planet_x,
		planet_y,
		macro_elevation,
		macro_heat,
		macro_humidity
	)

	target_biome = get_target_biome(
		macro_elevation,
		macro_heat,
		macro_humidity,
		macro_biome
	)

	if(!target_biome)
		log_world(
			"RimWorld sub-level: unable to resolve biome for [planet_x],[planet_y]."
		)
		return FALSE

	/*
	 * Resolve the current planetary sub-biome.
	 *
	 * This is deliberately the sub-biome of the current macro tile,
	 * not one of the neighbouring tiles.
	 */
	sub_biome = planet.get_sub_biome(
		planet_x,
		planet_y,
		macro_biome,
		macro_elevation
	)

	if(!sub_biome)
		sub_biome = RW_SUBBIOME_PLAINS

	if(!length(hex_neighbourhood))
		cache_planetary_neighborhood()

	if(!length(hex_neighbourhood))
		return FALSE

	var/centre_elevation = clamp(round(text2num("[planet.get_elevation_level(planet_x, planet_y)]")), 0, 5)

	// Планетарная река на этом тайле (слой rivers из tp_planet.rs)
	var/has_river = planet.has_river(planet_x, planet_y)

	var/list/config = list(
		"planet_seed" = planet.seed,
		"planet_x" = planet_x,
		"planet_y" = planet_y,
		"width" = width,
		"height" = height,

		"centre_elevation" = centre_elevation,
		"neighbourhood_hex" = hex_neighbourhood,
		"biome" = macro_biome,
		"sub_biome" = sub_biome,
		"has_river" = has_river,

		"local_seed" = 0,
		"density_bias" = 0.0,
		"smooth_passes" = 1,          // 0..=5 — how many times we smooth height


		"relief_scale" = 1.0,
		"detail_scale" = 1.0,
		"river_strength" = 1.0,
		"lake_strength" = 1.0,
		"cave_strength" = 1.0,
		"water_bias" = 0.0,

		"flora_density" = target_biome.flora_density,
		"feature_density" = target_biome.feature_density,
		"fauna_density" = target_biome.fauna_density,
		"flora_radius" = target_biome.flora_soft_radius,
		"feature_radius" = target_biome.feature_exclusion_radius,
		"fauna_radius" = target_biome.mob_exclusion_radius,
		"flora_penalty" = target_biome.flora_soft_penalty,
		"stamp" = stamp_config(target_biome.stamp_rules(sub_biome)),

		"caves" = generate_caves \
			? RW_CAVEGUN_TRUE \
			: RW_CAVEGUN_FALSE
	)

	var/result = rustg_tp_sublevel_generate(
		json_encode(config)
	)

	if(!result || findtext(result, "ERROR:") == 1)
		log_world(
			"Sub-level heightmap generation failed for [planet_x],[planet_y]: [result]"
		)
		return FALSE

	var/list/export = json_decode(result)

	if(!islist(export) || export["status"] != "ok")
		log_world(
			"Sub-level generation returned bad payload for [planet_x],[planet_y]."
		)
		return FALSE

	heights = export["heights"]

	if(!islist(heights))
		log_world(
			"Sub-level generation returned no heightmap."
		)
		return FALSE

	if(length(heights) != width * height)
		log_world(
			"Sub-level heightmap size mismatch. Expected [width * height], got [length(heights)]."
		)
		return FALSE

	cave_mask = export["cave_mask"]

	if(!islist(cave_mask))
		cave_mask = list()

	else if(generate_caves && (length(cave_mask) != width * height))
		log_world(
			"Sub-level cave mask size mismatch."
		)
		return FALSE

	content_plan = export["content"]
	has_content_plan = islist(content_plan) && length(content_plan) == width * height
	if(!has_content_plan)
		content_plan = null

	stamp_turf_palette = export["turf_palette"]
	stamp_content_palette = export["content_palette"]
	stamp_turf_ids = export["turf_ids"]
	stamp_content_ids = export["content_ids"]
	stamp_colors = export["colors"]
	stamp_edges = export["edges"]
	stamp_junctions = export["junctions"]
	stamp_edge_cursor = 1
	has_stamp = islist(stamp_turf_palette) \
		&& islist(stamp_turf_ids) \
		&& length(stamp_turf_ids) == width * height \
		&& length(stamp_turf_palette)
	stamp_content_colors = export["content_colors"]
	stamp_icon_states = export["icon_states"]
	stamp_content_variants = export["content_variants"]
	stamp_rock_name = export["rock_name"]
	stamp_rock_hp = export["rock_hp"]
	if(!isnum(stamp_rock_hp))
		stamp_rock_hp = text2num("[stamp_rock_hp]")
	if(!isnum(stamp_rock_hp))
		stamp_rock_hp = 1
	var/rock_path = text2path("[export["rock_path"]]")
	if(ispath(rock_path))
		stamp_rock_material = SSmaterials.get_material(rock_path)
	if(!has_stamp)
		log_world("Sub-level stamp missing for [planet_x],[planet_y]. Refusing the multi-pass generator.")
		return FALSE

	/*
	rimworld_area = SSatoms.NewUninitialized(
		/area/rimworld,
		null
	)
	*/
	rimworld_area = new()

	if(!rimworld_area)
		return FALSE

	rimworld_area.cell = cell
	rimworld_area.name = "Rim ([planet_x],[planet_y])"
	rimworld_area.daylight = TRUE
	rimworld_area.cell_loading = TRUE
	rimworld_area.outdoors = TRUE
	stamp_hemisphere = "north"
	if(cell?.planet && cell.planet.get_latitude(cell.x, cell.y) < 0)
		stamp_hemisphere = "south"

	origin_x = BL.x
	origin_y = BL.y
	origin_z = BL.z

	pending_init = list()
	generated_turfs = list()
	generated_open_turfs = list()
	generated_open_is_cave = list()
	generated_open_content = list()
	turfs_initialized = FALSE

	return TRUE


/datum/map_generator/sub_level/proc/decode_heights_step(start_index, budget)
	if(!islist(heights))
		return -1

	var/count = length(heights)
	var/idx = start_index
	var/processed = 0

	while(idx <= count && processed < budget)
		var/value = heights[idx]

		if(!isnum(value))
			value = text2num("[value]")

		if(isnull(value))
			log_world(
				"Sub-level heightmap contains a non-numeric value at index [idx]."
			)
			return -1

		heights[idx] = clamp(value, 0, 1)

		idx++
		processed++

	return idx


/datum/map_generator/sub_level/proc/build_transition_mask()
	transition_mask = list()
	transition_mask.len = width * height

	for(var/local_y in 1 to height)
		for(var/local_x in 1 to width)
			var/index = width * (local_y - 1) + local_x
			transition_mask[index] = is_geological_transition_xy(local_x, local_y)


/datum/map_generator/sub_level/proc/decode_cave_mask_step(start_index, budget)
	if(!islist(cave_mask) || !length(cave_mask))
		return 1

	var/count = length(cave_mask)
	var/idx = start_index
	var/processed = 0

	while(idx <= count && processed < budget)
		var/value = cave_mask[idx]

		if(!isnum(value))
			value = text2num("[value]")

		cave_mask[idx] = !isnull(value) && value != 0

		idx++
		processed++

	return idx


/datum/map_generator/sub_level/proc/stamp_config(list/rules)
	stamp_hemisphere = "north"
	if(cell?.planet && cell.planet.get_latitude(cell.x, cell.y) < 0)
		stamp_hemisphere = "south"
	if(!islist(rules) || !SSrimworld_planetmap)
		return rules
	var/season = SSrimworld_planetmap.get_season_for_hemisphere(stamp_hemisphere)
	switch(season)
		if(RW_SEASON_SPRING)
			rules["season_tint"] = RW_SEASON_TINT_SPRING
			rules["season_amount"] = RW_SEASON_TINT_AMOUNT_SPRING
		if(RW_SEASON_SUMMER)
			rules["season_tint"] = RW_SEASON_TINT_SUMMER
			rules["season_amount"] = RW_SEASON_TINT_AMOUNT_SUMMER
		if(RW_SEASON_FALL)
			rules["season_tint"] = RW_SEASON_TINT_FALL
			rules["season_amount"] = RW_SEASON_TINT_AMOUNT_FALL
		if(RW_SEASON_WINTER)
			rules["season_tint"] = RW_SEASON_TINT_WINTER
			rules["season_amount"] = RW_SEASON_TINT_AMOUNT_WINTER
	var/mat_path = cell ? RW_MATERIAL_NAME_TO_TYPE[cell.material] : null
	if(ispath(mat_path))
		var/datum/material/rimworld_material/mat = SSmaterials.get_material(mat_path)
		if(mat)
			rules["rock_color"] = "[mat.color]"
			rules["rock_name"] = mat.name
			rules["rock_path"] = "[mat_path]"
			rules["rock_hp"] = mat.get_hp_factor()
	return rules


/datum/map_generator/sub_level/proc/place_sub_level_turf(
	datum/turf_reservation/sub_level/reservation,
	local_x,
	local_y
)
	if(!reservation || !target_biome)
		return null

	if(local_x < 1 || local_x > width)
		return null

	if(local_y < 1 || local_y > height)
		return null

	var/turf/source_turf = locate(origin_x + local_x - 1, origin_y + local_y - 1, origin_z)
	if(!source_turf)
		return null

	source_turf.change_area(source_turf.loc, rimworld_area)

	var/index = width * (local_y - 1) + local_x
	if(index < 1 || index > length(heights))
		return null

	var/terrain_height = heights[index]

	var/is_cave = FALSE
	if(length(cave_mask))
		is_cave = cave_mask[index]

	var/is_transition = FALSE
	if(length(transition_mask) >= index)
		is_transition = transition_mask[index]

	var/stamp_content_id = 0
	var/stamp_color = null
	var/turf_type
	if(has_stamp)
		turf_type = stamp_type(stamp_turf_palette, stamp_turf_ids[index])
		if(islist(stamp_content_ids) && length(stamp_content_ids) >= index)
			stamp_content_id = stamp_content_ids[index]
			if(!isnum(stamp_content_id))
				stamp_content_id = text2num(stamp_content_id)
		if(islist(stamp_colors) && length(stamp_colors) >= index)
			stamp_color = stamp_colors[index]
	else
		turf_type = target_biome.get_turf_for_height(
			terrain_height,
			sub_biome,
			is_cave,
			is_transition
		)

	if(!turf_type)
		turf_type = /turf/open/genturf

	var/turf/new_turf = SSatoms.NewUninitialized(turf_type, source_turf)
	if(!new_turf)
		return null

	if(SSmapping.used_turfs[source_turf] == reservation)
		SSmapping.used_turfs -= source_turf

	SSmapping.used_turfs[new_turf] = reservation

	new_turf.turf_flags = \
		(new_turf.turf_flags | RESERVATION_TURF) \
		& ~UNUSED_RESERVATION_TURF

	generated_turfs += new_turf
	if(!has_stamp)
		pending_init += new_turf

	if(has_stamp && istype(new_turf, /turf/open/rimworld))
		var/turf/open/rimworld/rw_turf = new_turf
		rw_turf.stamp_visual = TRUE
		if(istext(stamp_color) && length(stamp_color) >= 7)
			rw_turf.base_color = stamp_color
			rw_turf.color = stamp_color
		if(islist(stamp_icon_states) && index <= length(stamp_icon_states))
			var/sprite = stamp_icon_states[index]
			if(isnum(sprite) && sprite >= 0)
				rw_turf.icon_state = "[sprite]"
		if(istype(rw_turf, /turf/open/rimworld/rock))
			apply_stamp_rock(rw_turf)
	if(has_stamp && istype(new_turf, /turf/closed/rw_wall/rock))
		var/turf/closed/rw_wall/rock/rock_wall = new_turf
		rock_wall.stamp_visual = TRUE
		if(istext(stamp_color) && length(stamp_color) >= 7)
			rock_wall.color = stamp_color
		apply_stamp_rock(rock_wall)

	if(has_stamp)
		apply_stamp_junction(new_turf, index)

	if(has_stamp && stamp_content_id > 0 && islist(stamp_content_palette))
		var/content_type = stamp_type(stamp_content_palette, stamp_content_id)
		if(content_type)
			var/atom/spawned = SSatoms.NewUninitialized(content_type, new_turf)
			if(spawned)
				if(istype(spawned, /obj/structure/rimworld/flora/grayscale))
					var/obj/structure/rimworld/flora/grayscale/plant = spawned
					var/sprite = 0
					if(islist(stamp_content_variants) && index <= length(stamp_content_variants))
						sprite = stamp_content_variants[index]
					if(istype(plant, /obj/structure/rimworld/flora/grayscale/grass))
						var/obj/structure/rimworld/flora/grayscale/grass/tuft = plant
						if(!isnum(sprite) || sprite < 1)
							sprite = 1
						tuft.icon_state = "[tuft.base_icon_state]_[sprite]"
					else if(istype(plant, /obj/structure/rimworld/flora/grayscale/tree))
						var/obj/structure/rimworld/flora/grayscale/tree/tree = plant
						if(!isnum(sprite) || sprite < 1)
							sprite = 1
						tree.icon_state = "[tree.base_icon_state][sprite]"
					var/foliage = null
					if(islist(stamp_content_colors) && stamp_content_id <= length(stamp_content_colors))
						foliage = stamp_content_colors[stamp_content_id]
					if(istext(foliage) && length(foliage) >= 7)
						plant.base_color = plant.foliage_color
						plant.foliage_color = foliage
						plant.color = foliage
					plant.setup_grayscale_visuals()
					plant.visual_ready = TRUE
				if(!has_stamp)
					pending_init += spawned

	if(!istype(new_turf, /turf/closed))
		generated_open_turfs += new_turf
		generated_open_is_cave += is_cave
		var/content_kind = 0
		if(!has_stamp && has_content_plan)
			var/planned = content_plan[index]
			if(isnum(planned))
				content_kind = planned
			else
				content_kind = text2num(planned)
		generated_open_content += content_kind

	return new_turf


/datum/map_generator/sub_level/proc/apply_stamp_rock(turf/rock_turf)
	if(stamp_rock_name)
		rock_turf.name = "[stamp_rock_name] [initial(rock_turf.name)]"
	if(istype(rock_turf, /turf/open/rimworld/rock))
		var/turf/open/rimworld/rock/open_rock = rock_turf
		open_rock.material = stamp_rock_material
		return
	if(!istype(rock_turf, /turf/closed/rw_wall/rock))
		return
	var/turf/closed/rw_wall/rock/wall = rock_turf
	wall.material = stamp_rock_material
	if(stamp_rock_hp == 1)
		return
	wall.max_integrity = wall.max_integrity * stamp_rock_hp
	wall.mine_steps = round(wall.mine_steps * stamp_rock_hp)


/datum/map_generator/sub_level/proc/apply_stamp_junction(turf/new_turf, index)
	if(!islist(stamp_junctions) || index > length(stamp_junctions))
		return
	if(!istype(new_turf, /turf/closed))
		return
	var/junction = stamp_junctions[index]
	if(!isnum(junction))
		junction = text2num(junction)
	if(isnull(junction) || junction < 0)
		return
	var/turf/closed/wall = new_turf
	if(!wall.base_icon_state)
		return
	wall.smoothing_junction = junction
	wall.icon_state = "[wall.base_icon_state]-[junction]"


/datum/map_generator/sub_level/proc/apply_stamp_edges(turf/new_turf, index)
	if(!islist(stamp_edges) || !istype(new_turf, /turf/open))
		return
	var/list/overlays = list()
	while(stamp_edge_cursor + 2 <= length(stamp_edges))
		var/edge_tile = stamp_edges[stamp_edge_cursor]
		if(!isnum(edge_tile))
			edge_tile = text2num(edge_tile)
		if(edge_tile != index)
			break
		var/direction = stamp_edges[stamp_edge_cursor + 1]
		var/neighbor_index = stamp_edges[stamp_edge_cursor + 2]
		stamp_edge_cursor += 3
		if(!isnum(direction))
			direction = text2num(direction)
		if(!isnum(neighbor_index))
			neighbor_index = text2num(neighbor_index)
		if(!neighbor_index || neighbor_index > length(stamp_turf_ids))
			continue
		var/neighbor_type = stamp_type(stamp_turf_palette, stamp_turf_ids[neighbor_index])
		if(!ispath(neighbor_type, /turf/open))
			continue
		var/turf/open/neighbor = neighbor_type
		var/bleed_dir = REVERSE_DIR(direction)
		var/edge_state = TURF_EDGE_STATE_FOR_DIR(bleed_dir)
		var/neighbor_icon = initial(neighbor.icon)
		if(!edge_state || !neighbor_icon)
			continue
		var/neighbor_color = null
		if(islist(stamp_colors) && neighbor_index <= length(stamp_colors))
			neighbor_color = stamp_colors[neighbor_index]
		if(!istext(neighbor_color) || length(neighbor_color) < 7)
			neighbor_color = initial(neighbor.color)
		var/mutable_appearance/edge = mutable_appearance(
			neighbor_icon,
			edge_state,
			new_turf.layer + 0.01 + (initial(neighbor.edge_priority) * 0.0001),
			appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART
		)
		edge.color = neighbor_color
		overlays += edge
	if(!length(overlays))
		return
	new_turf.add_overlay(overlays)
	var/turf/open/open_turf = new_turf
	open_turf.store_edge_overlays(overlays)


/proc/rw_season_color(base, hemisphere = "north")
	if(!istext(base) || !SSrimworld_planetmap)
		return base
	var/season = SSrimworld_planetmap.get_season_for_hemisphere(hemisphere)
	var/tint
	var/amount
	switch(season)
		if(RW_SEASON_SPRING)
			tint = RW_SEASON_TINT_SPRING
			amount = RW_SEASON_TINT_AMOUNT_SPRING
		if(RW_SEASON_SUMMER)
			tint = RW_SEASON_TINT_SUMMER
			amount = RW_SEASON_TINT_AMOUNT_SUMMER
		if(RW_SEASON_FALL)
			tint = RW_SEASON_TINT_FALL
			amount = RW_SEASON_TINT_AMOUNT_FALL
		if(RW_SEASON_WINTER)
			tint = RW_SEASON_TINT_WINTER
			amount = RW_SEASON_TINT_AMOUNT_WINTER
		else
			return base
	return blend_towards(base, tint, amount)


/datum/map_generator/sub_level/proc/stamp_type(list/palette, index)
	if(!isnum(index))
		index = text2num(index)
	if(!index || index < 1 || index > length(palette))
		return null
	var/path_text = palette[index]
	if(!istext(path_text))
		return path_text
	if(!stamp_path_cache)
		stamp_path_cache = list()
	if(stamp_path_cache[path_text])
		return stamp_path_cache[path_text]
	var/path = text2path(path_text)
	stamp_path_cache[path_text] = path
	return path


/datum/map_generator/sub_level/proc/populate_turf(
	turf/target_turf,
	flora_allowed,
	features_allowed,
	fauna_allowed,
	is_cave = FALSE,
	open_index = 0
)
	if(!target_turf || !target_biome)
		return FALSE

	if(istype(target_turf, /turf/closed))
		return TRUE

	var/planned_kind = null
	if(has_content_plan && open_index >= 1 && open_index <= length(generated_open_content))
		planned_kind = generated_open_content[open_index]

	return target_biome.populate_turf(
		target_turf,
		flora_allowed,
		features_allowed,
		fauna_allowed,
		is_cave,
		sub_biome,
		pending_init,
		planned_kind
	)


/datum/map_generator/sub_level/proc/get_generated_turf(index)
	if(index < 1 || index > length(generated_turfs))
		return null

	return generated_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_open_turf(index)
	if(index < 1 || index > length(generated_open_turfs))
		return null

	return generated_open_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_turf_count()
	return length(generated_turfs)

/datum/map_generator/sub_level/proc/get_generated_open_is_cave(index)
	if(index < 1 || index > length(generated_open_is_cave))
		return FALSE
	return generated_open_is_cave[index]

/datum/map_generator/sub_level/proc/get_generated_open_turf_count()
	return length(generated_open_turfs)
