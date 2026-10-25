#define get_planet_cell(A) rw_planet_cell_of(A)

/// Enclosed rooms are /area/rimworld/zone, which carry the cell only through their parent area.
/proc/rw_planet_cell_of(atom/A)
	var/area/rimworld/area = isarea(A) ? A : get_area(A)
	if(!istype(area))
		return null
	if(istype(area, /area/rimworld/zone))
		var/area/rimworld/zone/zone = area
		return zone.parent_cell_area?.cell
	return area.cell

#define is_planet_level(A) (!!get_planet_cell(A))

#define is_rimworld_area(A) (istype(A, /area/rimworld))

