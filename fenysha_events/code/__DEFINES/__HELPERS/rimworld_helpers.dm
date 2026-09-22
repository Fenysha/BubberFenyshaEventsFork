#define get_planet_cell(A) \
	(istype((isarea(A) ? A : get_area(A)), /area/rimworld) \
		? ((isarea(A) ? A : get_area(A)):cell) \
		: null)

#define is_planet_level(A) (!!get_planet_cell(A))

#define is_rimworld_area(A) (istype(A, /area/rimworld))

