/datum/action/cooldown/mob_cooldown/faction_panel
	name = "Faction Panel"
	desc = "Open your faction management panel."

	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"

	click_to_activate = FALSE
	cooldown_time = 1 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

/datum/action/cooldown/mob_cooldown/faction_panel/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/user = owner
	if(user.stat || user.incapacitated)
		owner.balloon_alert(owner, "You cannot do that in your current state!")
		return FALSE
	if(!user?.rw_faction || !istype(user.rw_faction, /datum/rw_faction/player))
		if(feedback)
			owner.balloon_alert(owner, "No faction!")
		return FALSE
	return TRUE

/datum/action/cooldown/mob_cooldown/faction_panel/Activate(atom/target)
	var/mob/living/user = owner
	var/datum/rw_faction/player/F = user.rw_faction

	if(!F)
		return FALSE

	. = ..()
	F.ui_interact(user)
	return TRUE

/datum/action/cooldown/mob_cooldown/faction_invite
	name = "Invite to Faction"
	desc = "Invite the selected creature to join your faction."

	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "shield"

	click_to_activate = TRUE
	cooldown_time = 5 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/max_distance = 7

/datum/action/cooldown/mob_cooldown/faction_invite/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/user = owner
	if(!user?.rw_faction || !istype(user.rw_faction, /datum/rw_faction/player))
		if(feedback)
			owner.balloon_alert(owner, "No faction!")
		return FALSE
	var/datum/rw_faction/player/F = user.rw_faction
	if(!F.can_manage_members(user))
		if(feedback)
			owner.balloon_alert(owner, "Insufficient permissions!")
		return FALSE
	return TRUE

/datum/action/cooldown/mob_cooldown/faction_invite/PreActivate(atom/target)
	if(!isliving(target))
		owner.balloon_alert(owner, "A target is required!")
		return FALSE
	if(get_dist(owner, target) > max_distance)
		owner.balloon_alert(owner, "Too far away!")
		return FALSE
	if(!can_see(owner, target, max_distance))
		owner.balloon_alert(owner, "Cannot see the target!")
		return FALSE

	var/mob/living/L = target
	if(L == owner)
		owner.balloon_alert(owner, "You cannot invite yourself!")
		return FALSE
	if(L.rw_faction)
		owner.balloon_alert(owner, "Already in a faction!")
		return FALSE
	if(!owner.rw_faction?.is_alive(L))
		owner.balloon_alert(owner, "The target is dead!")
		return FALSE

	return ..()

/datum/action/cooldown/mob_cooldown/faction_invite/Activate(atom/target)
	var/mob/living/user = owner
	var/mob/living/invitee = target
	var/datum/rw_faction/player/F = user.rw_faction

	. = ..()

	// Send the invitation
	var/choice = tgui_alert(
		invitee,
		"[user.real_name] invites you to join faction «[F.name]». Accept?",
		"Faction Invitation",
		list("Accept", "Decline"),
		timeout = 30 SECONDS
	)

	if(choice != "Accept")
		to_chat(user, span_notice("[invitee.real_name] declined the invitation."))
		to_chat(invitee, span_notice("You declined the invitation to join faction «[F.name]»."))
		return TRUE

	// Validate the invitation at acceptance time
	if(QDELETED(user) || QDELETED(invitee) || QDELETED(F))
		return TRUE
	if(invitee.rw_faction)
		to_chat(user, span_warning("[invitee.real_name] is already in a faction."))
		return TRUE
	if(!F.can_manage_members(user))
		to_chat(user, span_warning("You no longer have permission to invite members."))
		return TRUE

	if(F.add_member(invitee))
		to_chat(user, span_notice("You accepted [invitee.real_name] into faction «[F.name]»."))
		to_chat(invitee, span_boldnotice("You joined faction «[F.name]»!"))

		// Notify all faction members
		for(var/mob/living/M in F.members)
			if(M == user || M == invitee)
				continue
			to_chat(M, span_notice("<b>[invitee.real_name]</b> joined the faction (invited by: [user.real_name])."))
	else
		to_chat(user, span_warning("Failed to add [invitee.real_name] to the faction."))

	return TRUE


/datum/action/cooldown/mob_cooldown/faction_kick
	name = "Kick from Faction"
	desc = "Kick the selected member from your faction."

	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "repulse"

	click_to_activate = TRUE
	cooldown_time = 3 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/max_distance = 7

/datum/action/cooldown/mob_cooldown/faction_kick/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/user = owner
	if(!user?.rw_faction || !istype(user.rw_faction, /datum/rw_faction/player))
		if(feedback)
			owner.balloon_alert(owner, "No faction!")
		return FALSE
	var/datum/rw_faction/player/F = user.rw_faction
	if(!F.can_manage_members(user))
		if(feedback)
			owner.balloon_alert(owner, "Insufficient permissions!")
		return FALSE
	return TRUE

/datum/action/cooldown/mob_cooldown/faction_kick/PreActivate(atom/target)
	if(!isliving(target))
		owner.balloon_alert(owner, "A target is required!")
		return FALSE
	if(get_dist(owner, target) > max_distance)
		owner.balloon_alert(owner, "Too far away!")
		return FALSE

	var/mob/living/L = target
	var/datum/rw_faction/player/F = owner.rw_faction

	if(L == owner)
		owner.balloon_alert(owner, "You cannot kick yourself!")
		return FALSE
	if(L.rw_faction != F)
		owner.balloon_alert(owner, "Not in your faction!")
		return FALSE
	if(!F.can_kick(owner, L))
		owner.balloon_alert(owner, "Insufficient permissions!")
		return FALSE

	return ..()

/datum/action/cooldown/mob_cooldown/faction_kick/Activate(atom/target)
	var/mob/living/user = owner
	var/mob/living/target_mob = target
	var/datum/rw_faction/player/F = user.rw_faction

	. = ..()

	if(!F.can_kick(user, target_mob))
		to_chat(user, span_warning("You can no longer kick this person."))
		return TRUE

	var/target_name = target_mob.real_name

	if(F.remove_member(target_mob))
		to_chat(user, span_notice("You kicked [target_name] from faction «[F.name]»."))
		to_chat(target_mob, span_userdanger("You were kicked from faction «[F.name]» ([user.real_name])."))

		// Notify all remaining faction members
		for(var/mob/living/M in F.members)
			if(M == user)
				continue
			to_chat(M, span_warning("<b>[target_name]</b> was kicked from the faction ([user.real_name])."))
	else
		to_chat(user, span_warning("Failed to kick [target_name]."))

	return TRUE



/datum/rw_faction/player
	player_faction = TRUE
	name = "Player Faction"
	desc = "A player-controlled faction"

	var/datum/techweb/faction/techweb

	var/list/member_roles = list()

	var/datum/faction_leadership_vote/active_vote

/datum/rw_faction/player/New(faction_id, faction_name)
	. = ..()
	techweb = new /datum/techweb/faction()
	techweb.owner_faction = src

/datum/rw_faction/player/Destroy()
	QDEL_NULL(techweb)
	QDEL_NULL(active_vote)
	member_roles.Cut()
	return ..()

/datum/rw_faction/player/add_member(mob/living/new_member, force = FALSE)
	. = ..()
	if(.)
		member_roles[new_member] = leader == new_member ? FACTION_ROLE_LEADER : FACTION_ROLE_MEMBER

/datum/rw_faction/player/remove_member(mob/living/member, force = FALSE)
	member_roles -= member
	if(active_vote)
		active_vote.remove_voter(member)
	. = ..()

/datum/rw_faction/player/set_leader(mob/living/new_leader)
	var/mob/living/old_leader = leader
	. = ..()
	if(.)
		for(var/mob/living/M in member_roles)
			if(member_roles[M] == FACTION_ROLE_LEADER && M != new_leader)
				member_roles[M] = FACTION_ROLE_MEMBER
		member_roles[new_leader] = FACTION_ROLE_LEADER

		if(old_leader && old_leader != new_leader)
			grant_faction_actions(old_leader)
		grant_faction_actions(new_leader)


/datum/rw_faction/player/proc/get_role(mob/living/M)
	ensure_valid_leader()
	return member_roles[M] || FACTION_ROLE_MEMBER

/datum/rw_faction/player/proc/set_role(mob/living/M, new_role)
	if(!(M in members) || !(new_role in list(FACTION_ROLE_MEMBER, FACTION_ROLE_CHIEF, FACTION_ROLE_LEADER)))
		return FALSE

	if(new_role == FACTION_ROLE_LEADER)
		return set_leader(M)

	member_roles[M] = new_role
	grant_faction_actions(M)
	return TRUE

/datum/rw_faction/player/proc/is_chief(mob/living/M)
	return get_role(M) == FACTION_ROLE_CHIEF

/datum/rw_faction/player/proc/can_manage_members(mob/living/M)
	if(!(M in members) || !is_alive(M))
		return FALSE
	var/role = get_role(M)
	return role == FACTION_ROLE_LEADER || role == FACTION_ROLE_CHIEF

/datum/rw_faction/player/proc/can_kick(mob/living/actor, mob/living/target)
	if(!can_manage_members(actor) || !(target in members) || actor == target)
		return FALSE
	if(is_leader(target))
		return FALSE
	if(is_chief(target) && !is_leader(actor))
		return FALSE
	return TRUE

/datum/rw_faction/player/proc/grant_faction_actions(mob/living/M)
	if(!istype(M))
		return

	revoke_faction_actions(M) // Clear existing faction actions first

	// Faction panel — available to all members
	var/datum/action/cooldown/mob_cooldown/faction_panel/panel = new
	panel.Grant(M)

	// Invite + Kick — only for members who can manage the faction
	if(can_manage_members(M))
		var/datum/action/cooldown/mob_cooldown/faction_invite/invite = new
		invite.Grant(M)

		var/datum/action/cooldown/mob_cooldown/faction_kick/kick = new
		kick.Grant(M)

/datum/rw_faction/player/proc/revoke_faction_actions(mob/living/M)
	if(!istype(M))
		return

	for(var/datum/action/cooldown/mob_cooldown/faction_panel/A in M.actions)
		A.Remove(M)
	for(var/datum/action/cooldown/mob_cooldown/faction_invite/A in M.actions)
		A.Remove(M)
	for(var/datum/action/cooldown/mob_cooldown/faction_kick/A in M.actions)
		A.Remove(M)

/datum/rw_faction/player/on_member_joined(mob/living/member)
	. = ..()
	grant_faction_actions(member)

/datum/rw_faction/player/on_member_left(mob/living/member)
	. = ..()
	revoke_faction_actions(member)



/datum/rw_faction/player/proc/can_promote_to_chief(mob/living/actor, mob/living/target)
	return is_leader(actor) && (target in members) && is_alive(target) && !is_leader(target) && get_role(target) != FACTION_ROLE_CHIEF

/datum/rw_faction/player/proc/can_demote_chief(mob/living/actor, mob/living/target)
	return is_leader(actor) && (target in members) && is_alive(target) && is_chief(target)

/datum/rw_faction/player/proc/research_tech(tech_id)
	return techweb?.research_node(tech_id)


/datum/rw_faction/player/proc/start_leadership_vote(mob/living/initiator, mob/living/candidate)
	ensure_valid_leader()
	if(active_vote)
		return FALSE
	if(!(initiator in members) || !(candidate in members))
		return FALSE
	if(!is_alive(initiator) || !is_alive(candidate) || candidate == leader)
		return FALSE

	active_vote = new(src, initiator, candidate)
	for(var/mob/living/M in get_alive_members())
		to_chat(M, span_notice("A leadership vote has started. Candidate: <b>[candidate.real_name]</b>. Initiator: [initiator.real_name]."))
	return TRUE

/datum/rw_faction/player/proc/end_vote(success)
	if(!active_vote)
		return
	var/mob/living/winner = active_vote.candidate
	QDEL_NULL(active_vote)

	if(success && istype(winner) && (winner in members) && is_alive(winner))
		set_leader(winner)
		for(var/mob/living/M in members)
			to_chat(M, span_boldnotice("Vote finished. The new faction leader is [winner.real_name]!"))
	else
		for(var/mob/living/M in members)
			to_chat(M, span_notice("The leadership vote failed."))


/datum/rw_faction/player/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FactionPanel", name)
		ui.open()

/datum/rw_faction/player/ui_state(mob/user)
	if(is_member(user))
		return GLOB.not_incapacitated_state
	return GLOB.never_state

/datum/rw_faction/player/ui_data(mob/user)
	ensure_valid_leader()
	var/list/data = list()
	data["faction_name"] = name
	data["faction_desc"] = desc
	data["leader_name"] = leader ? leader.real_name : "None"
	data["member_count"] = get_member_count()
	data["alive_count"] = get_member_count(alive_only = TRUE)
	data["is_leader"] = is_leader(user)
	data["is_chief"] = is_chief(user)
	data["can_manage"] = can_manage_members(user)
	data["user_ref"] = REF(user)


	data["has_active_vote"] = !!active_vote
	if(active_vote)
		data["vote_candidate"] = active_vote.candidate?.real_name
		data["vote_initiator"] = active_vote.initiator?.real_name
		data["vote_yes"] = length(active_vote.votes_yes)
		data["vote_no"] = length(active_vote.votes_no)
		data["vote_needed"] = active_vote.votes_needed
		data["user_voted"] = (user in active_vote.votes_yes) || (user in active_vote.votes_no)
		data["time_left"] = max(0, round((active_vote.end_time - world.time) / 10))


	var/list/members_data = list()
	for(var/mob/living/M in members)
		var/list/entry = list()
		entry["ref"] = REF(M)
		entry["name"] = M.real_name
		entry["role"] = get_role(M)
		entry["alive"] = is_alive(M)
		entry["is_self"] = (M == user)
		entry["can_kick"] = can_kick(user, M)
		entry["can_promote"] = can_promote_to_chief(user, M)
		entry["can_demote"] = can_demote_chief(user, M)
		entry["can_transfer_leadership"] = is_leader(user) && M != user && is_alive(M)
		entry["can_nominate"] = (M != leader) && is_alive(M) && !active_vote
		members_data += list(entry)
	data["members"] = members_data

	return data

/datum/rw_faction/player/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/user = ui.user
	if(!is_member(user) || !is_alive(user))
		return FALSE

	switch(action)
		if("kick")
			var/mob/living/target = locate(params["ref"])
			if(!can_kick(user, target))
				return FALSE
			if(!remove_member(target))
				return FALSE
			to_chat(user, span_notice("You kicked [target.real_name] from the faction."))
			to_chat(target, span_warning("You were kicked from faction [name]."))
			return TRUE

		if("promote_chief")
			var/mob/living/target = locate(params["ref"])
			if(!can_promote_to_chief(user, target))
				return FALSE
			set_role(target, FACTION_ROLE_CHIEF)
			to_chat(user, span_notice("[target.real_name] is now Chief."))
			to_chat(target, span_notice("You were appointed Chief of faction [name]. You can invite and kick members."))
			return TRUE

		if("demote_chief")
			var/mob/living/target = locate(params["ref"])
			if(!can_demote_chief(user, target))
				return FALSE
			set_role(target, FACTION_ROLE_MEMBER)
			to_chat(user, span_notice("[target.real_name] is no longer Chief."))
			to_chat(target, span_warning("You were removed from the Chief position."))
			return TRUE

		if("transfer_leadership")
			var/mob/living/target = locate(params["ref"])
			if(!is_leader(user) || !(target in members) || !is_alive(target) || target == user)
				return FALSE
			set_leader(target)
			to_chat(user, span_notice("You transferred leadership to [target.real_name]."))
			to_chat(target, span_boldnotice("You are the new faction leader [name]!"))
			return TRUE

		if("start_vote")
			var/mob/living/candidate = locate(params["ref"])
			if(active_vote || !(candidate in members) || !is_alive(candidate) || candidate == leader)
				return FALSE
			return start_leadership_vote(user, candidate)

		if("vote_yes")
			if(!active_vote || !is_alive(user) || (user in active_vote.votes_yes) || (user in active_vote.votes_no))
				return FALSE
			return active_vote.vote_yes(user)

		if("vote_no")
			if(!active_vote || !is_alive(user) || (user in active_vote.votes_yes) || (user in active_vote.votes_no))
				return FALSE
			return active_vote.vote_no(user)

		if("cancel_vote")
			if(!active_vote || !is_leader(user))
				return FALSE
			end_vote(FALSE)
			return TRUE

		if("leave_faction")
			if(!is_member(user))
				return FALSE
			if(is_leader(user) && get_member_count(alive_only = TRUE) > 1)
				to_chat(user, span_warning("Transfer leadership first or wait until you are the only living member."))
				return FALSE

			var/confirm = tgui_alert(user, "Are you sure you want to leave faction «[name]»?", "Leave Faction", list("Yes", "No"))
			if(confirm != "Yes" || !is_member(user))
				return FALSE

			var/leaver_name = user.real_name
			remove_member(user)

			to_chat(user, span_notice("You left faction «[name]»."))

			for(var/mob/living/M in members)
				to_chat(M, span_notice("<b>[leaver_name]</b> voluntarily left the faction."))

			return TRUE

	return FALSE



/datum/faction_leadership_vote
	var/datum/rw_faction/player/parent

	var/mob/living/initiator
	var/mob/living/candidate

	var/list/votes_yes = list()
	var/list/votes_no = list()

	var/votes_needed = 0
	var/end_time = 0
	var/vote_duration = 3 MINUTES

/datum/faction_leadership_vote/New(datum/rw_faction/player/faction, mob/living/init, mob/living/cand)
	parent = faction
	initiator = init
	candidate = cand
	votes_needed = max(2, floor(length(faction.get_alive_members()) / 2) + 1)
	end_time = world.time + vote_duration
	START_PROCESSING(SSprocessing, src)

/datum/faction_leadership_vote/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	parent = null
	initiator = null
	candidate = null
	votes_yes.Cut()
	votes_no.Cut()
	return ..()

/datum/faction_leadership_vote/process()
	if(world.time >= end_time)
		finish()

/datum/faction_leadership_vote/proc/vote_yes(mob/living/voter)
	if(!parent || !(voter in parent.members) || !parent.is_alive(voter))
		return FALSE
	if((voter in votes_yes) || (voter in votes_no))
		return FALSE
	votes_yes |= voter
	check_early_finish()
	return TRUE

/datum/faction_leadership_vote/proc/vote_no(mob/living/voter)
	if(!parent || !(voter in parent.members) || !parent.is_alive(voter))
		return FALSE
	if((voter in votes_yes) || (voter in votes_no))
		return FALSE
	votes_no |= voter
	check_early_finish()
	return TRUE

/datum/faction_leadership_vote/proc/remove_voter(mob/living/voter)
	votes_yes -= voter
	votes_no -= voter

/datum/faction_leadership_vote/proc/check_early_finish()
	if(parent)
		for(var/mob/living/M in votes_yes.Copy())
			if(!(M in parent.members) || !parent.is_alive(M))
				votes_yes -= M
		for(var/mob/living/M in votes_no.Copy())
			if(!(M in parent.members) || !parent.is_alive(M))
				votes_no -= M

	if(length(votes_yes) >= votes_needed)
		finish(TRUE)
	else if(length(votes_no) >= votes_needed)
		finish(FALSE)

/datum/faction_leadership_vote/proc/finish(forced_result = null)
	var/success = FALSE
	if(!isnull(forced_result))
		success = forced_result
	else
		success = length(votes_yes) >= votes_needed

	if(parent)
		parent.end_vote(success)
