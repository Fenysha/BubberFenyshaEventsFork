//Separate dm because it relates to two types of atoms + ease of removal in case it's needed.
//Also assemblies.dm for falsewall checking for this when used.
//I should really make the shuttle wall check run every time it's moved, but centcom uses unsimulated floors so !effort
/atom
	//A list of paths only that each turf should tile with
	var/list/tiles_with

/atom/proc/relativewall()
	var/junction = 0
	var/turf/turf_check

	for(var/first_iterator in GLOB.cardinals)
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue

		for(var/second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(var/atom/third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	handle_icon_junction(junction)

/atom/proc/relativewall_neighbours()
	var/turf/turf_check

	for(var/first_iterator in GLOB.cardinals)
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue

		for(var/second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				if(turf_check.tiles_with)
					turf_check.relativewall()
				break

			for(var/atom/third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					if(third_iterator.tiles_with)
						third_iterator.relativewall()
					break


/atom/movable/atom_shadow/relativewall_neighbours()
	for(var/direction in GLOB.cardinals)
		var/turf/turf_check = get_step(src, direction)
		if(!turf_check)
			continue

		for(var/atom/movable/atom_shadow/shadow in turf_check)
			if(!QDELETED(shadow))
				shadow.relativewall()


/atom/proc/handle_icon_junction(junction)
	return
