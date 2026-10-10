// ============================================================================
// Cordon ("absolute") shadow chain
//
// Ghosts and mesons see the normal shadows dimmed (plane11 alpha / mask strength). The normal chain mixes the shadows of every
// caster together, so the cordon's shadow cannot be kept at full strength in there. This is a second, independent copy of the
// displace chain that only contains the cordon: it is picked out of the shadow source plane by its red mark (CORDON_MARK_COLOR)
// and is drawn on top, fully black and opaque.
//
// It is only built for viewers that need it (ghosts / mesons, see shadows_plane/update_shadow_modes) and removed again afterwards,
// so for normal players these planes do not exist at all.
//
// These are plane MASTERS only (nothing is ever drawn on them), so they sit on half-integer planes just above their
// WALLS_FOV_PLANE_x twins and need no new constants in layers.dm.
// ============================================================================

/// state, displace size of the map used by each stage 0..11 (identical to WALLS_FOV_PLANE_0..11)
/proc/get_cordon_stage_displace(stage)
	var/static/list/stages = list(
		list("1", 1), list("1", 1), list("2", 2), list("3", 4), list("4", 8), list("5", 16),
		list("6", 32), list("7", 64), list("8", 96), list("8", 128), list("9", 192), list("9", 256),
	)
	return stages[stage + 1]

/// The WALLS_FOV_PLANE_x each stage mirrors
/proc/get_cordon_stage_main_plane(stage)
	var/static/list/planes = list(
		WALLS_FOV_PLANE_0, WALLS_FOV_PLANE_1, WALLS_FOV_PLANE_2, WALLS_FOV_PLANE_3, WALLS_FOV_PLANE_4,
		WALLS_FOV_PLANE_5, WALLS_FOV_PLANE_6, WALLS_FOV_PLANE_7, WALLS_FOV_PLANE_8, WALLS_FOV_PLANE_9,
		WALLS_FOV_PLANE_10, WALLS_FOV_PLANE_11, WALLS_FOV_PLANE_12,
	)
	return planes[stage + 1]

/proc/get_cordon_stage_target(stage, offset)
	return OFFSET_RENDER_TARGET("*CORDON_FOV_STAGE_[stage]", offset)

/datum/plane_master_group/proc/has_cordon_chain(offset)
	return !!get_plane(GET_NEW_PLANE(CORDON_FOV_PLANE(WALLS_FOV_PLANE_12), offset))

/// Builds the cordon chain for ONE z offset and shows it to the viewer. Called only for ghosts and meson wearers, nobody else ever has these planes.
/datum/plane_master_group/proc/add_cordon_chain(offset, mob/viewer)
	if(has_cordon_chain(offset))
		return
	for(var/stage in 0 to CORDON_CHAIN_STAGES - 1)
		var/atom/movable/screen/plane_master/wall_fov/cordon_stage/instance = new(null, null, src, offset, stage)
		plane_masters["[instance.plane]"] = instance
		prep_plane_instance(instance)
		instance.show_to(viewer)
	// the visual stage must follow the same "only the viewed z level" alpha rule as the normal mask
	var/atom/movable/screen/plane_master/wall_fov/plane11/mask_base = get_plane(GET_NEW_PLANE(WALLS_FOV_PLANE_11, offset))
	if(mask_base)
		mask_base?.offset_change(0)

/// Removes the cordon chain of one z offset again, so the planes cost nothing for a viewer that does not need them
/datum/plane_master_group/proc/remove_cordon_chain(offset, mob/viewer)
	for(var/stage in 0 to CORDON_CHAIN_STAGES - 1)
		var/stage_plane = GET_NEW_PLANE(CORDON_FOV_PLANE(get_cordon_stage_main_plane(stage)), offset)
		var/atom/movable/screen/plane_master/doomed = plane_masters["[stage_plane]"]
		if(!doomed)
			continue
		// Destroy() does not clear client screens by itself
		doomed.hide_from(viewer)
		qdel(doomed)

/atom/movable/screen/plane_master/wall_fov/cordon_stage
	name = "Cordon FOV stage"
	documentation = "One stage of the cordon shadow chain, a copy of the matching Wall Fov plane that only carries /turf/cordon/absolute. \
		Only exists while the viewer is a ghost or wears mesons, where it draws the cordon shadow fully black on top of the dimmed normal shadows."
	/// 0..11 displace stages, 12 is the visual plane
	var/stage = 0

/atom/movable/screen/plane_master/wall_fov/cordon_stage/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0, stage = 0)
	src.stage = stage
	plane = CORDON_FOV_PLANE(get_cordon_stage_main_plane(stage))
	if(stage == CORDON_CHAIN_STAGES - 1)
		render_relay_planes = list(RENDER_PLANE_GAME)
	if(stage >= CORDON_CHAIN_STAGES - 2)
		color = null
	. = ..(mapload, hud_owner, home, offset)
	build_stage_filters()

/// Own version: the base one would use lookup tables that only know integer planes and would reset our render target
/atom/movable/screen/plane_master/wall_fov/cordon_stage/update_offset()
	name = "[initial(name)] [stage] #[offset]"
	plane = GET_NEW_PLANE(real_plane, offset)
	for(var/i in 1 to length(render_relay_planes))
		render_relay_planes[i] = GET_NEW_PLANE(render_relay_planes[i], offset)
	render_target = get_cordon_stage_target(stage, offset)
	offset_already_updated = TRUE

/atom/movable/screen/plane_master/wall_fov/cordon_stage/proc/build_stage_filters()
	var/map_icon = SHADOW_MAP_ICON
	if(stage == 0)
		var/shadow_source = OFFSET_RENDER_TARGET(ATOMS_FOV_SHADOWS_RENDER_TARGET, offset)
		var/list/map_data = get_cordon_stage_displace(0)
		// only the tinted cordon mask is taken from the shadow source, as a black shape
		add_filter("wall_underlay", 1, list(type = "layer", render_source = shadow_source, flags = FILTER_UNDERLAY, color = CORDON_EXTRACT_COLOR))
		add_filter("wall_displace", 2, list(type = "displace", icon = icon(map_icon, map_data[1]), size = map_data[2]))
		add_filter("wall_alpha", 3, list(type = "alpha", render_source = shadow_source, flags = MASK_INVERSE))
		return

	var/previous = get_cordon_stage_target(stage - 1, offset)
	if(stage < CORDON_CHAIN_STAGES - 1)
		var/list/map_data = get_cordon_stage_displace(stage)
		add_filter("wall_underlay", 1, list(type = "layer", render_source = previous, flags = FILTER_UNDERLAY))
		add_filter("wall_displace", 2, list(type = "displace", icon = icon(map_icon, map_data[1]), size = map_data[2]))
		add_filter("wall_overlay", 3, list(type = "layer", render_source = previous))
		if(stage == CORDON_CHAIN_STAGES - 2)
			add_filter("wall_soften", 4, list(type = "blur", size = SHADOW_BLUR_BASE))
		return

	// visual stage: same soft cascade as the normal shadows, but never dimmed
	add_filter("shadow_halo", 1, list(type = "layer", render_source = previous, flags = FILTER_UNDERLAY))
	add_filter("shadow_halo_blur_a", 2, list(type = "blur", size = SHADOW_BLUR_HALO_A))
	add_filter("shadow_halo_blur_b", 3, list(type = "blur", size = SHADOW_BLUR_HALO_B))
	add_filter("shadow_core", 4, list(type = "layer", render_source = previous))
	add_filter("shadow_core_blur_a", 5, list(type = "blur", size = SHADOW_BLUR_CORE_A))
