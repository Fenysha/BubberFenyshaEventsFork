/mob
	var/datum/rw_faction/rw_faction


SUBSYSTEM_DEF(factions)
	name = "\[RW\] factions"
	ss_flags = SS_NO_FIRE

	VAR_PRIVATE/list/known_fractions


/datum/controller/subsystem/factions/Initialize()
	known_fractions = list()

	ensure_default_factions()
	rebuild_raid_faction_defs()
	return SS_INIT_SUCCESS


/datum/controller/subsystem/factions/proc/ensure_default_factions()
	ensure_initialized()

	var/static/list/default_factions = list(
		RW_FACTION_OUTLANDERS = /datum/rw_faction/outlanders,
		RW_FACTION_ROUGH_OUTLANDERS = /datum/rw_faction/rough_outlanders,

		RW_FACTION_GENTLE_TRIBE = /datum/rw_faction/tribals,
		RW_FACTION_FIERCE_TRIBE = /datum/rw_faction/fierce_tribes,
		RW_FACTION_SAVAGE_TRIBE = /datum/rw_faction/savage_tribes,

		RW_FACTION_PIRATES = /datum/rw_faction/pirates,

		RW_FACTION_MECHANOIDS = /datum/rw_faction/mechanoids,
		RW_FACTION_INSECTOIDS = /datum/rw_faction/insectoids,

		RW_FACTION_ANCIENTS_NEUTRAL = /datum/rw_faction/ancients/neutral,
		RW_FACTION_ANCIENTS_HOSTILE = /datum/rw_faction/ancients/hostile,
		"admin" = /datum/rw_faction/player/admin,
	)

	for(var/faction_id in default_factions)
		if(get_faction(faction_id))
			continue

		create_faction(
			default_factions[faction_id],
			faction_id,
		)

	return TRUE


/datum/controller/subsystem/factions/proc/register_faction(datum/rw_faction/faction)
	if(!istype(faction))
		return FALSE

	ensure_initialized()

	if(!faction.id)
		return FALSE

	var/datum/rw_faction/existing = known_fractions[faction.id]
	if(existing && existing != faction)
		return FALSE

	known_fractions[faction.id] = faction
	return TRUE


/datum/controller/subsystem/factions/proc/unregister_faction(datum/rw_faction/faction)
	if(!istype(faction))
		return FALSE

	ensure_initialized()

	if(known_fractions[faction.id] != faction)
		return FALSE

	known_fractions -= faction.id
	return TRUE


/datum/controller/subsystem/factions/proc/ensure_initialized()
	if(!islist(known_fractions))
		known_fractions = list()


/datum/controller/subsystem/factions/proc/create_faction(
	faction_type = /datum/rw_faction,
	faction_id = null,
	faction_name = null,
)
	if(!ispath(faction_type, /datum/rw_faction))
		faction_type = /datum/rw_faction

	if(faction_id && get_faction(faction_id))
		return null

	var/datum/rw_faction/faction = new faction_type(
		faction_id,
		faction_name,
	)

	if(QDELETED(faction))
		return null

	if(!register_faction(faction))
		qdel(faction)
		return null

	return faction


/datum/controller/subsystem/factions/proc/create_player_faction(
	faction_id = null,
	faction_name = null,
)
	return create_faction(
		/datum/rw_faction/player,
		faction_id,
		faction_name,
	)


/datum/controller/subsystem/factions/proc/get_or_create_faction(
	faction_id,
	faction_type = /datum/rw_faction,
	faction_name = null,
)
	var/datum/rw_faction/faction = get_faction(faction_id)
	if(faction)
		return faction

	return create_faction(
		faction_type,
		faction_id,
		faction_name,
	)


/datum/controller/subsystem/factions/proc/get_or_create_player_faction(
	faction_id,
	faction_name = null,
)
	return get_or_create_faction(
		faction_id,
		/datum/rw_faction/player,
		faction_name,
	)


/datum/controller/subsystem/factions/proc/get_faction(target)
	ensure_initialized()

	if(!target)
		return null

	if(istype(target, /datum/rw_faction))
		return target

	return known_fractions[target]


/datum/controller/subsystem/factions/proc/get_faction_by_id(faction_id)
	return get_faction(faction_id)


/datum/controller/subsystem/factions/proc/get_faction_by_name(faction_name)
	if(!faction_name)
		return null

	ensure_initialized()

	for(var/id in known_fractions)
		var/datum/rw_faction/faction = known_fractions[id]
		if(QDELETED(faction))
			continue

		if(faction.name == faction_name)
			return faction

	return null


/datum/controller/subsystem/factions/proc/has_faction(faction_id)
	return !!get_faction(faction_id)


/datum/controller/subsystem/factions/proc/delete_faction(target)
	var/datum/rw_faction/faction = get_faction(target)
	if(!faction)
		return FALSE

	qdel(faction)
	return TRUE


/datum/controller/subsystem/factions/proc/get_all_factions()
	ensure_initialized()

	var/list/result = list()

	for(var/id in known_fractions)
		var/datum/rw_faction/faction = known_fractions[id]
		if(QDELETED(faction))
			continue

		result += faction

	return result


/datum/controller/subsystem/factions/proc/get_all_player_factions()
	ensure_initialized()

	var/list/result = list()

	for(var/id in known_fractions)
		var/datum/rw_faction/player/faction = known_fractions[id]
		if(QDELETED(faction) || !faction.player_faction)
			continue

		result += faction

	return result


/datum/controller/subsystem/factions/proc/get_faction_count()
	ensure_initialized()

	var/count = 0

	for(var/id in known_fractions)
		var/datum/rw_faction/faction = known_fractions[id]
		if(QDELETED(faction))
			continue

		count++

	return count


/datum/controller/subsystem/factions/proc/get_faction_for(mob/living/M)
	if(!istype(M))
		return null

	var/datum/rw_faction/faction = M.rw_faction

	if(!istype(faction) || QDELETED(faction))
		return null

	if(get_faction(faction.id) != faction)
		return null

	return faction


/datum/controller/subsystem/factions/proc/is_member_of(mob/living/M, target)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction || !istype(M))
		return FALSE

	return faction.is_member(M)


/datum/controller/subsystem/factions/proc/add_member(
	target,
	mob/living/M,
	force = FALSE,
)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction || !istype(M))
		return FALSE

	return faction.add_member(M, force)


/datum/controller/subsystem/factions/proc/remove_member(
	target,
	mob/living/M,
	force = FALSE,
)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction || !istype(M))
		return FALSE

	return faction.remove_member(M, force)


/datum/controller/subsystem/factions/proc/get_member_faction(mob/living/M)
	return get_faction_for(M)


/datum/controller/subsystem/factions/proc/get_faction_members(target, alive_only = FALSE)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction)
		return list()

	return alive_only ? faction.get_alive_members() : faction.members.Copy()


/datum/controller/subsystem/factions/proc/get_faction_member_count(target, alive_only = FALSE)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction)
		return 0

	return faction.get_member_count(alive_only)


/datum/controller/subsystem/factions/proc/get_faction_leader(target)
	var/datum/rw_faction/faction = get_faction(target)

	if(!faction)
		return null

	return faction.ensure_valid_leader()


/datum/controller/subsystem/factions/proc/set_faction_relationship(
	source,
	target,
	value,
)
	var/datum/rw_faction/source_faction = get_faction(source)
	var/datum/rw_faction/target_faction = get_faction(target)

	if(!source_faction || !target_faction)
		return FALSE

	return source_faction.set_relationship(target_faction, value)


/datum/controller/subsystem/factions/proc/adjust_faction_relationship(
	source,
	target,
	amount,
)
	var/datum/rw_faction/source_faction = get_faction(source)
	var/datum/rw_faction/target_faction = get_faction(target)

	if(!source_faction || !target_faction)
		return FALSE

	return source_faction.adjust_relationship(target_faction, amount)


/datum/controller/subsystem/factions/proc/get_faction_relationship(
	source,
	target,
)
	var/datum/rw_faction/source_faction = get_faction(source)
	var/datum/rw_faction/target_faction = get_faction(target)

	if(!source_faction || !target_faction)
		return 0

	return source_faction.get_relationship(target_faction)


/datum/controller/subsystem/factions/proc/factions_are_allied(
	source,
	target,
)
	var/datum/rw_faction/source_faction = get_faction(source)
	var/datum/rw_faction/target_faction = get_faction(target)

	if(!source_faction || !target_faction)
		return FALSE

	return source_faction.is_ally(target_faction)


/datum/controller/subsystem/factions/proc/factions_are_enemies(
	source,
	target,
)
	var/datum/rw_faction/source_faction = get_faction(source)
	var/datum/rw_faction/target_faction = get_faction(target)

	if(!source_faction || !target_faction)
		return FALSE

	return source_faction.is_enemy(target_faction)


/datum/controller/subsystem/factions/proc/clear_factions()
	ensure_initialized()

	var/list/factions = known_fractions.Copy()

	for(var/id in factions)
		var/datum/rw_faction/faction = factions[id]
		if(!QDELETED(faction))
			qdel(faction)

	known_fractions.Cut()


/datum/controller/subsystem/factions/proc/get_factions_with_player_members()
	ensure_initialized()

	var/list/result = list()

	for(var/id in known_fractions)
		var/datum/rw_faction/faction = known_fractions[id]
		if(QDELETED(faction))
			continue

		var/has_player = FALSE

		for(var/mob/living/M in faction.members)
			if(M.client)
				has_player = TRUE
				break

		if(has_player)
			result += faction

	return result

/datum/rw_faction
	var/name = "Faction"
	var/desc = "Unknown faction"
	var/id = null

	var/icon
	var/icon_state

	var/player_faction = FALSE

	/// Current living leader
	var/mob/living/leader

	/// list(mob/living)
	var/list/members = list()

	/// FACTION_ID = number (-100 … +100)
	var/list/relationships = list()

	var/color = "#FFFFFF"

	/// TRUE if this faction can launch storyteller raids.
	var/can_raid = FALSE
	/// Raid event id key (also used in GLOB.raid_faction_defs). Defaults to id when empty.
	var/raid_id
	/// list of /datum/raid_pawn_kind typepaths this faction may spawn.
	var/list/raid_kinds = list()
	var/raid_min_points = STORYTELLER_THREAT_MIN
	var/raid_max_points = 0
	var/raid_strategy = RAID_STRATEGY_ASSAULT
	var/raid_retreat_fraction = 0.5
	var/raid_max_duration = 10 MINUTES
	var/raid_requires_settlement = TRUE
	var/raid_faction_tag = "rw_raiders"
	var/raid_announce_text = "Raiders are approaching from the %DIR%!"
	var/raid_staged_text = "The raiders have finished preparing. They are coming!"
	var/raid_retreat_text = "The raiders are retreating."
	var/raid_defeat_text = "The raid has been defeated."
	/// Static tech level used when the faction has no techweb (NPC factions).
	/// 0 = neolithic … 5 = ultratech. Player factions derive this from researched nodes.
	var/base_tech_level = 0


/datum/rw_faction/New(faction_id, faction_name)
	..()

	id = faction_id || "faction_[REF(src)]"

	if(faction_name)
		name = faction_name
	else
		name = generate_name()

	desc = generate_desc()

	SSfactions.register_faction(src)


/datum/rw_faction/Destroy()
	for(var/mob/living/M in members.Copy())
		remove_member(M, force = TRUE)

	leader = null

	SSfactions.unregister_faction(src)

	return ..()


/datum/rw_faction/proc/generate_name()
	return name


/datum/rw_faction/proc/generate_desc()
	return desc


/datum/rw_faction/proc/add_member(mob/living/new_member, force = FALSE)
	if(!istype(new_member) || (new_member in members))
		return FALSE

	if(new_member.rw_faction && !force)
		return FALSE

	if(new_member.rw_faction)
		new_member.rw_faction.remove_member(new_member, force = TRUE)

	members += new_member
	new_member.rw_faction = src

	if((!leader && is_alive(new_member)) && id != "admin")
		set_leader(new_member)

	on_member_joined(new_member)

	return TRUE


/datum/rw_faction/proc/remove_member(mob/living/member, force = FALSE)
	if(!(member in members))
		return FALSE

	members -= member

	if(member.rw_faction == src)
		member.rw_faction = null

	if(leader == member)
		leader = null
		elect_new_leader()

	on_member_left(member)

	return TRUE


/datum/rw_faction/proc/is_member(mob/living/M)
	return M in members


/datum/rw_faction/proc/get_alive_members()
	. = list()

	for(var/mob/living/M in members)
		if(is_alive(M))
			. += M


/datum/rw_faction/proc/get_member_count(alive_only = FALSE)
	return alive_only ? length(get_alive_members()) : length(members)


/datum/rw_faction/proc/set_leader(mob/living/new_leader)
	if(!istype(new_leader) || !(new_leader in members) || !is_alive(new_leader))
		return FALSE

	var/mob/living/old = leader

	leader = new_leader

	on_leader_changed(old, new_leader)

	return TRUE


/datum/rw_faction/proc/elect_new_leader()
	var/list/candidates = get_alive_members()

	if(!length(candidates))
		leader = null
		return FALSE

	return set_leader(candidates[1])


/datum/rw_faction/proc/ensure_valid_leader()
	if(leader && !is_alive(leader))
		elect_new_leader()

	return leader


/datum/rw_faction/proc/is_leader(mob/living/M)
	ensure_valid_leader()
	return leader == M


/datum/rw_faction/proc/is_alive(mob/living/M)
	return M && !QDELETED(M) && M.stat != DEAD


/datum/rw_faction/proc/get_relationship(datum/rw_faction/target)
	var/target_id = istype(target, /datum/rw_faction) ? target.id : target
	return relationships[target_id] || 0


/datum/rw_faction/proc/set_relationship(datum/rw_faction/target, value)
	var/target_id = istype(target, /datum/rw_faction) ? target.id : target

	if(!target_id)
		return FALSE

	relationships[target_id] = clamp(value, -100, 100)

	return TRUE


/datum/rw_faction/proc/adjust_relationship(target, amount)
	return set_relationship(
		target,
		get_relationship(target) + amount,
	)


/datum/rw_faction/proc/is_ally(target)
	return get_relationship(target) >= 80


/datum/rw_faction/proc/is_enemy(target)
	return get_relationship(target) <= -80


/datum/rw_faction/proc/on_member_joined(mob/living/member)
	return


/datum/rw_faction/proc/on_member_left(mob/living/member)
	return


/datum/rw_faction/proc/on_leader_changed(mob/living/old_leader, mob/living/new_leader)
	return


// -------------------------------------------------------------------------
// Tech level & raid profile helpers
// -------------------------------------------------------------------------

/// Integer tech level 0–5 for raid scaling / pawn filtering.
/// Player factions with a techweb take the highest unlocked era; others use base_tech_level.
/datum/rw_faction/proc/get_tech_level()
	return base_tech_level

/datum/rw_faction/player/get_tech_level()
	if(!techweb)
		return base_tech_level
	var/highest = base_tech_level
	var/list/era_rank = list(
		RW_TECH_ERA_NEOLITHIC = 0,
		RW_TECH_ERA_MEDIEVAL = 1,
		RW_TECH_ERA_INDUSTRIAL = 2,
		RW_TECH_ERA_SPACER = 3,
		RW_TECH_ERA_ULTRATECH = 4,
	)
	for(var/node_id in techweb.researched_nodes)
		var/datum/techweb_node/rw/node = SSresearch.techweb_node_by_id(node_id)
		if(!istype(node))
			continue
		var/rank = era_rank[node.tech_era]
		if(!isnull(rank))
			highest = max(highest, rank)
	return highest

/// Build a transient /datum/raid_faction_def from this faction's raid profile.
/datum/rw_faction/proc/build_raid_def()
	if(!can_raid || !length(raid_kinds))
		return null
	var/datum/raid_faction_def/def = new
	def.id = raid_id || id
	def.name = name
	def.faction_id = id
	def.faction_tag = raid_faction_tag
	def.kinds = raid_kinds.Copy()
	def.min_points = raid_min_points
	def.max_points = raid_max_points
	def.strategy = raid_strategy
	def.retreat_fraction = raid_retreat_fraction
	def.max_duration = raid_max_duration
	def.requires_settlement = raid_requires_settlement
	def.announce_text = raid_announce_text
	def.staged_text = raid_staged_text
	def.retreat_text = raid_retreat_text
	def.defeat_text = raid_defeat_text
	def.source_faction = src
	return def
