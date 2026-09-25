/datum/settlement_setup/proc/do_create()
	if(!planet || !viewer || isnull(target_x) || isnull(target_y))
		return FALSE

	// Создаём фракцию игрока
	var/faction_id = "player_[viewer.ckey || REF(viewer)]"
	var/datum/rw_faction/player/player_faction = SSfactions.get_or_create_player_faction(faction_id, faction_name)
	if(!player_faction)
		return FALSE

	player_faction.name = faction_name
	player_faction.desc = faction_desc
	// TODO: icon / ideology

	SSfactions.add_member(player_faction, viewer, force = TRUE)

	// Создаём поселение
	var/datum/rimworld_planet_object/settlement/settlement = planet.create_settlement(target_x, target_y, faction_name)
	if(!settlement)
		return FALSE

	settlement.set_faction(player_faction.id)
	settlement.set_population(1)

	// Загружаем клетку
	var/datum/planet_cell/cell = planet.get_or_create_cell(target_x, target_y, FALSE)
	if(cell)
		cell.ensure_loaded(settlement.name)

	// TODO: реальный спавн игрока в клетку
	// spawn_player_at(viewer, cell) ...

	finish_and_close()
	return TRUE


/datum/settlement_setup/proc/do_join()
	if(!planet || !viewer || !join_settlement_id)
		return FALSE

	var/datum/rimworld_planet_object/settlement/sett = planet.get_object(join_settlement_id)
	if(!sett)
		return FALSE

	var/faction_id = sett.data["faction"]
	var/datum/rw_faction/fac = faction_id ? SSfactions.get_faction(faction_id) : null
	if(!fac || !fac.player_faction)
		return FALSE

	SSfactions.add_member(fac, viewer, force = TRUE)

	// Увеличиваем население
	sett.set_population((sett.data["population"] || 0) + 1)

	// Загружаем клетку если нужно
	var/datum/planet_cell/cell = planet.get_or_create_cell(sett.x, sett.y, FALSE)
	if(cell)
		cell.ensure_loaded(sett.name)

	// TODO: реальный спавн игрока

	finish_and_close()
	return TRUE
