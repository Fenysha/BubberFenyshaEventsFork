/datum/rimworld_planet/proc/get_settlement_plan()
	return list(
		list("kind" = RW_SETTLEMENT_OUTLANDER, "faction" = RW_FACTION_OUTLANDERS, "weight" = 0.20, "min_score" = 0.48, "settlement_type" = "town"),
		list("kind" = RW_SETTLEMENT_ROUGH_OUTLANDER, "faction" = RW_FACTION_ROUGH_OUTLANDERS, "weight" = 0.10, "min_score" = 0.40, "settlement_type" = "town"),
		list("kind" = RW_SETTLEMENT_GENTLE_TRIBE, "faction" = RW_FACTION_GENTLE_TRIBE, "weight" = 0.14, "min_score" = 0.42, "settlement_type" = "village"),
		list("kind" = RW_SETTLEMENT_FIERCE_TRIBE, "faction" = RW_FACTION_FIERCE_TRIBE, "weight" = 0.12, "min_score" = 0.40, "settlement_type" = "village"),
		list("kind" = RW_SETTLEMENT_SAVAGE_TRIBE, "faction" = RW_FACTION_SAVAGE_TRIBE, "weight" = 0.08, "min_score" = 0.38, "settlement_type" = "camp"),
		list("kind" = RW_SETTLEMENT_PIRATE, "faction" = RW_FACTION_PIRATES, "weight" = 0.14, "min_score" = 0.35, "settlement_type" = "camp"),
		list("kind" = RW_SETTLEMENT_MECHANOID, "faction" = RW_FACTION_MECHANOIDS, "weight" = 0.08, "min_score" = 0.40, "settlement_type" = "complex"),
		list("kind" = RW_SETTLEMENT_INSECTOID, "faction" = RW_FACTION_INSECTOIDS, "weight" = 0.10, "min_score" = 0.38, "settlement_type" = "hive"),
		list("kind" = RW_SETTLEMENT_ANCIENT, "faction" = RW_FACTION_ANCIENTS_NEUTRAL, "weight" = 0.02, "min_score" = 0.35, "settlement_type" = RW_SETTLEMENT_TYPE_RUINS),
		list("kind" = RW_SETTLEMENT_ANCIENT, "faction" = RW_FACTION_ANCIENTS_HOSTILE, "weight" = 0.02, "min_score" = 0.35, "settlement_type" = RW_SETTLEMENT_TYPE_RUINS),
	)

/datum/rimworld_planet/proc/query_settlement_candidates(list/plan)
	var/list/plan_json = list()
	var/list/seen = list()
	for(var/entry in plan)
		var/kind = entry["kind"]
		if(seen[kind])
			continue
		seen[kind] = TRUE
		plan_json += list(list("kind" = kind, "min_score" = entry["min_score"], "max_candidates" = 300))

	var/list/config = list(
		"seed" = seed,
		"frequency" = grid_frequency,
		"output_dir" = "data/rimworld_planets/[seed]",
		"plan" = plan_json,
	)

	var/result = rustg_tp_planet_settlement_candidates(json_encode(config))
	if(!result || findtext(result, "ERROR:") == 1)
		log_world("[name] settlement candidate query failed: [result]")
		return null

	var/list/decoded
	try
		decoded = json_decode(result)
	catch
		log_world("[name] settlement candidate query returned invalid JSON.")
		return null

	if(!decoded || decoded["status"] != "ok")
		return null
	return decoded["candidates"]


/datum/rimworld_planet/proc/get_min_population(kind)
	switch(kind)
		if(RW_SETTLEMENT_PIRATE)
			return 8

		if(RW_SETTLEMENT_MECHANOID)
			return 0

		if(RW_SETTLEMENT_INSECTOID)
			return 20

		if(RW_SETTLEMENT_GENTLE_TRIBE, RW_SETTLEMENT_FIERCE_TRIBE)
			return 15

		if(RW_SETTLEMENT_SAVAGE_TRIBE)
			return 10

		if(RW_SETTLEMENT_ROUGH_OUTLANDER)
			return 25

	return 40


/datum/rimworld_planet/proc/get_max_population(kind)
	switch(kind)
		if(RW_SETTLEMENT_PIRATE)
			return 30

		if(RW_SETTLEMENT_MECHANOID)
			return 0

		if(RW_SETTLEMENT_INSECTOID)
			return 0

		if(RW_SETTLEMENT_GENTLE_TRIBE, RW_SETTLEMENT_FIERCE_TRIBE)
			return 40

		if(RW_SETTLEMENT_SAVAGE_TRIBE)
			return 40

		if(RW_SETTLEMENT_ROUGH_OUTLANDER)
			return 40

	return 40

/datum/rimworld_planet/proc/generate_settlements()
	if(!maps_generated())
		if(!ensure_maps())
			log_world("[name] generate_settlements aborted: maps not available.")
			return FALSE

	SSfactions.ensure_default_factions()

	for(var/id in settlements.Copy())
		var/datum/rimworld_planet_object/settlement/existing = settlements[id]
		if(!existing)
			continue
		if(existing.is_player_settlement())
			continue
		remove_object(id)

	var/pop_factor = (slider_population - RW_SLIDER_MIN) / (RW_SLIDER_MAX - RW_SLIDER_MIN)
	var/base_count = round(8 + pop_factor * 28)

	var/list/plan = get_settlement_plan()
	var/list/candidates_by_kind = query_settlement_candidates(plan)
	if(!candidates_by_kind)
		log_world("[name] generate_settlements aborted: no candidates from Rust.")
		return FALSE

	var/list/targets = get_settlement_targets(plan, base_count)
	var/list/occupied = list()
	// Roughly half the spacing base_count settlements would have spread evenly over the land
	var/tile_count = 10 * grid_frequency * grid_frequency + 2
	var/min_distance = max(3, sqrt(tile_count * RW_SETTLEMENT_LAND_FRACTION / max(base_count, 1)) * 0.5)
	var/total_placed = 0
	var/list/placed_points = list()

	for(var/plan_index in 1 to length(plan))
		var/list/entry = plan[plan_index]
		var/kind = entry["kind"]
		var/faction_id = entry["faction"]
		var/settlement_type = entry["settlement_type"]

		var/target = targets[plan_index]
		if(target <= 0)
			continue

		var/list/candidates = candidates_by_kind[kind]
		if(!islist(candidates))
			continue

		var/placed = 0
		for(var/list/cand in candidates)
			if(placed >= target)
				break

			var/cx = cand["x"]
			var/cy = cand["y"]
			var/key = "[cx]:[cy]"

			if(occupied[key])
				continue

			var/too_close = FALSE
			for(var/oid in settlements)
				var/datum/rimworld_planet_object/settlement/other = settlements[oid]
				if(!other)
					continue
				if(get_tile_distance(cx, cy, other.x, other.y) < min_distance)
					too_close = TRUE
					break
			if(too_close)
				continue

			var/settlement_name = generate_settlement_name(faction_id)
			var/datum/rimworld_planet_object/settlement/obj = create_settlement(cx, cy, settlement_name)
			if(!obj)
				continue

			obj.set_faction(faction_id)
			obj.data["settlement_type"] = settlement_type
			obj.data["kind"] = kind
			obj.set_population(rand(get_min_population(kind), get_max_population(kind)))

			occupied[key] = TRUE
			placed++
			total_placed++
			placed_points += list(list("x" = cx, "y" = cy, "tier" = get_road_tier(kind)))

	log_world("[name] generated [total_placed] settlements (slider_population = [slider_population], base_count = [base_count], min_distance = [round(min_distance)]).")

	generate_roads(placed_points)
	return TRUE

/// Best road a settlement of this kind builds; a road takes the lesser of its two ends
/datum/rimworld_planet/proc/get_road_tier(kind)
	switch(kind)
		if(RW_SETTLEMENT_OUTLANDER)
			return RW_ROAD_ASPHALT
		if(RW_SETTLEMENT_ROUGH_OUTLANDER)
			return RW_ROAD_STONE
	return RW_ROAD_DIRT

/// Splits base_count across the plan by weight (largest remainder), so small weights still get their share.
/datum/rimworld_planet/proc/get_settlement_targets(list/plan, base_count)
	var/total_weight = 0
	for(var/list/entry as anything in plan)
		total_weight += entry["weight"]
	var/list/targets = list()
	var/list/remainders = list()
	var/assigned = 0
	for(var/list/entry as anything in plan)
		var/exact = total_weight ? base_count * entry["weight"] / total_weight : 0
		targets += floor(exact)
		remainders += exact - floor(exact)
		assigned += floor(exact)
	while(assigned < base_count)
		var/best = 1
		for(var/index in 2 to length(remainders))
			if(remainders[index] > remainders[best])
				best = index
		targets[best]++
		remainders[best] = -1
		assigned++
	return targets


/datum/rimworld_planet/proc/generate_settlement_name(faction_id)
	var/datum/rw_faction/faction = SSfactions.get_faction(faction_id)
	if(faction)
		return faction.generate_name()
	return "Settlement"
