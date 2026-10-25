/**
 * ============================================================================
 * Raid content: pawn kinds + faction raid profiles
 * ============================================================================
 *
 * Raid profiles live on /datum/rw_faction (can_raid, raid_kinds, strategy, texts…).
 * GLOB.raid_faction_defs is still populated for backwards compatibility with events
 * that look up by id; the source of truth is the faction datum itself.
 *
 * All pawn kinds below use RAID_FALLBACK_MOB / no outfit as placeholders. Set mob_type
 * and outfit_type on the kinds when real mobs exist.
 */

GLOBAL_LIST_INIT(raid_pawn_kinds, init_raid_pawn_kinds())
/// id -> /datum/raid_faction_def (thin wrapper around the live /datum/rw_faction).
/// Filled by SSfactions.Initialize(): factions don't exist yet when globals initialise.
GLOBAL_LIST_EMPTY(raid_faction_defs)

/proc/init_raid_pawn_kinds()
	var/list/result = list()
	for(var/kind_type in subtypesof(/datum/raid_pawn_kind))
		result[kind_type] = new kind_type
	return result

/proc/init_raid_faction_defs()
	var/list/result = list()


	SSfactions.ensure_default_factions()
	for(var/datum/rw_faction/fac as anything in SSfactions.get_all_factions())
		if(!fac?.can_raid || !length(fac.raid_kinds))
			continue
		var/datum/raid_faction_def/def = fac.build_raid_def()
		if(def?.id)
			result[def.id] = def
	return result

/// Rebuild the global lookup after factions change (e.g. runtime registration).
/proc/rebuild_raid_faction_defs()
	GLOB.raid_faction_defs = init_raid_faction_defs()

// ---------------------------------------------------------------------------
// Pawn kinds
// ---------------------------------------------------------------------------

/datum/raid_pawn_kind
	var/name = "raider"
	/// Body of the raider.
	var/mob_type = RAID_FALLBACK_MOB
	/// Outfit datum equipped on humans, if any.
	var/outfit_type
	/// Points this raider costs.
	var/combat_power = 30
	/// Not used in raids smaller than this many points.
	var/min_points = 0
	/// Relative chance among affordable kinds.
	var/weight = 10
	/// 0 = unlimited.
	var/max_per_raid = 0
	/// Minimum tech level of the *attacking* faction required to spawn this kind.
	var/min_tech_level = 0
	/// Maximum tech level (0 = no cap). Higher-tech factions stop using primitive units.
	var/max_tech_level = 0

/datum/raid_pawn_kind/proc/spawn_pawn(turf/where, datum/raid_group/group)
	var/mob/living/pawn = new mob_type(where)
	if(outfit_type && ishuman(pawn))
		var/mob/living/carbon/human/human_pawn = pawn
		human_pawn.equipOutfit(outfit_type)
	// Tag the pawn as belonging to the attacking faction when possible.
	if(group?.def?.faction_id)
		var/datum/rw_faction/fac = SSfactions.get_faction(group.def.faction_id)
		if(fac)
			fac.add_member(pawn, force = TRUE)
	return pawn

/datum/raid_pawn_kind/proc/is_allowed_for_tech(tech_level)
	if(min_tech_level && tech_level < min_tech_level)
		return FALSE
	if(max_tech_level && tech_level > max_tech_level)
		return FALSE
	return TRUE

/datum/raid_pawn_kind/pirate_grunt
	name = "pirate grunt"
	combat_power = 35
	weight = 20

/datum/raid_pawn_kind/pirate_gunner
	name = "pirate gunner"
	combat_power = 55
	weight = 15
	min_points = 90
	min_tech_level = 1

/datum/raid_pawn_kind/pirate_heavy
	name = "pirate heavy"
	combat_power = 95
	weight = 8
	min_points = 260
	max_per_raid = 6
	min_tech_level = 2

/datum/raid_pawn_kind/tribal_warrior
	name = "tribal warrior"
	combat_power = 30
	weight = 20
	max_tech_level = 2

/datum/raid_pawn_kind/tribal_hunter
	name = "tribal hunter"
	combat_power = 40
	weight = 12
	min_points = 70
	max_tech_level = 2

/datum/raid_pawn_kind/tribal_berserker
	name = "tribal berserker"
	combat_power = 75
	weight = 6
	min_points = 220
	max_per_raid = 5
	max_tech_level = 3

/datum/raid_pawn_kind/mech_light
	name = "light mechanoid"
	combat_power = 50
	weight = 15
	min_points = 60
	min_tech_level = 2

/datum/raid_pawn_kind/mech_heavy
	name = "heavy mechanoid"
	combat_power = 160
	weight = 6
	min_points = 380
	max_per_raid = 4
	min_tech_level = 3

/datum/raid_pawn_kind/insect_small
	name = "megascarab"
	combat_power = 25
	weight = 25

/datum/raid_pawn_kind/insect_large
	name = "spelopede"
	combat_power = 70
	weight = 10
	min_points = 140
	max_per_raid = 8
	min_tech_level = 1



/datum/raid_faction_def
	var/id
	var/name = "Raiders"
	var/faction_id
	var/faction_tag = "rw_raiders"
	var/list/kinds = list()
	var/min_points = STORYTELLER_THREAT_MIN
	var/max_points = 0
	var/strategy = RAID_STRATEGY_ASSAULT
	var/retreat_fraction = 0.5
	var/max_duration = 10 MINUTES
	var/requires_settlement = TRUE
	var/announce_text = "Raiders are approaching from the %DIR%!"
	var/staged_text = "The raiders have finished preparing. They are coming!"
	var/retreat_text = "The raiders are retreating."
	var/defeat_text = "The raid has been defeated."
	/// Live faction this def was built from (may be null if standalone).
	var/datum/rw_faction/source_faction

/datum/raid_faction_def/proc/find_origin(datum/planet_cell/cell)
	if(!cell?.planet || !faction_id)
		return null
	return cell.planet.get_nearest_settlement(cell.x, cell.y, 0, faction_id, FALSE)

/datum/raid_faction_def/proc/is_available_for(datum/planet_cell/cell)
	if(!length(kinds))
		return FALSE
	if(requires_settlement && !find_origin(cell))
		return FALSE
	return TRUE

/// Tech level of the attacking faction (settlement-based or faction default).
/datum/raid_faction_def/proc/get_attacker_tech_level(datum/planet_cell/cell)
	if(source_faction)
		return source_faction.get_tech_level()
	var/datum/rw_faction/fac = SSfactions.get_faction(faction_id)
	if(fac)
		return fac.get_tech_level()
	return 0

/// Optional member count of the attacking faction near the origin (boosts points slightly).
/datum/raid_faction_def/proc/get_attacker_member_bonus(datum/planet_cell/cell)
	var/datum/rw_faction/fac = source_faction || SSfactions.get_faction(faction_id)
	if(!fac)
		return 0
	var/alive = fac.get_member_count(alive_only = TRUE)
	// Each living faction member contributes a small flat boost to the raid budget.
	return min(alive * 8, 120)

/// Spends the points on pawn kinds, filtered by attacker tech level.
/datum/raid_faction_def/proc/roll_pawn_kinds(points, tech_level = 0)
	var/list/result = list()
	var/list/pool = list()
	var/datum/raid_pawn_kind/cheapest
	for(var/kind_type in kinds)
		var/datum/raid_pawn_kind/kind = GLOB.raid_pawn_kinds[kind_type]
		if(!kind || kind.min_points > points)
			continue
		if(!kind.is_allowed_for_tech(tech_level))
			continue
		pool += kind
		if(!cheapest || kind.combat_power < cheapest.combat_power)
			cheapest = kind
	if(!length(pool))
		// Fallback: ignore tech filter so a raid always has something.
		for(var/kind_type in kinds)
			var/datum/raid_pawn_kind/kind = GLOB.raid_pawn_kinds[kind_type]
			if(!kind || kind.min_points > points)
				continue
			pool += kind
			if(!cheapest || kind.combat_power < cheapest.combat_power)
				cheapest = kind
	if(!length(pool))
		return result

	var/budget = points
	var/list/counts = list()
	while(length(result) < RAID_MAX_PAWNS)
		var/list/options = list()
		for(var/datum/raid_pawn_kind/kind as anything in pool)
			if(kind.combat_power > budget)
				continue
			if(kind.max_per_raid > 0 && (counts[kind] || 0) >= kind.max_per_raid)
				continue
			options[kind] = kind.weight
		if(!length(options))
			break
		var/datum/raid_pawn_kind/chosen = pick_weight(options)
		result += chosen.type
		counts[chosen] = (counts[chosen] || 0) + 1
		budget -= chosen.combat_power

	if(!length(result) && cheapest)
		result += cheapest.type
	return result
