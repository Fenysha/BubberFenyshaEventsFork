//Separate dm because it relates to two types of atoms + ease of removal in case it's needed.
//Also assemblies.dm for falsewall checking for this when used.
//I should really make the shuttle wall check run every time it's moved, but centcom uses unsimulated floors so !effort
/atom
	//A list of paths only that each turf should tile with
	var/list/tiles_with

/atom/proc/relativewall() //atom because it should be useable both for walls, false walls, doors, windows, etc
	var/junction = 0 //flag used for icon_state
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.cardinals) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	handle_icon_junction(junction)

/atom/proc/relativewall_neighbours()
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/atom/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.cardinals) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				turf_check.relativewall() //If we tile this type, junction it
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall() //get_dir to first_iterator, since third_iterator is something inside the turf turf_check
					break

/atom/proc/handle_icon_junction(junction)
	return
