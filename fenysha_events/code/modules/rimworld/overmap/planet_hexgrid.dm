/**
 * Geodesic hex grid: the dual of a subdivided icosahedron. Every tile is a hexagon except the
 * 12 on the icosahedron's corners, which are pentagons.
 *
 * The icosahedron is cut into 10 diamonds (5 around each pole), each an n x n patch of the
 * triangular lattice. Tile (x, y): diamond d, lattice (i, j) lives at x = d * n + i + 1,
 * y = j. The poles sit alone in row y = n + 1: north at x = 1, south at x = 2. Layers are
 * (10n) x (n + 1).
 *
 * tgui (generation/hexGrid.ts) and rust-g (tp_hexgrid.rs) implement this same scheme; keep
 * all three in step.
 */

/datum/rimworld_planet
	/// Hex grid frequency n: 10n^2 + 2 tiles
	var/grid_frequency = RW_PLANET_GRID_FREQUENCY

/// Diamond corners A, B, C, D; triangles (A, B, D) and (C, D, B) share the B-D diagonal.
/proc/rw_hex_diamonds()
	var/static/list/diamonds
	if(diamonds)
		return diamonds
	var/lat = arctan(0.5)
	var/list/north = list(0, 1, 0)
	var/list/south = list(0, -1, 0)
	var/list/upper = list()
	var/list/lower = list()
	for(var/k in 0 to 4)
		upper += list(list(cos(lat) * cos(72 * k), sin(lat), cos(lat) * sin(72 * k)))
		lower += list(list(cos(-lat) * cos(72 * k + 36), sin(-lat), cos(-lat) * sin(72 * k + 36)))
	diamonds = list()
	for(var/k in 1 to 5)
		diamonds += list(list(north, upper[k], lower[k], upper[(k % 5) + 1]))
	for(var/k in 1 to 5)
		diamonds += list(list(upper[(k % 5) + 1], lower[k], south, lower[(k % 5) + 1]))
	return diamonds

/// The 20 faces as list(diamond, upper, origin, e1, e2, outward normal).
/proc/rw_hex_faces()
	var/static/list/faces
	if(faces)
		return faces
	faces = list()
	var/list/diamonds = rw_hex_diamonds()
	for(var/d in 1 to 10)
		var/list/corners = diamonds[d]
		// Lower: p = A + u(B-A) + v(D-A). Upper: p = C + u(D-C) + v(B-C).
		for(var/upper in list(FALSE, TRUE))
			var/list/origin = upper ? corners[3] : corners[1]
			var/list/e1 = rw_vec_sub(upper ? corners[4] : corners[2], origin)
			var/list/e2 = rw_vec_sub(upper ? corners[2] : corners[4], origin)
			var/list/normal = rw_vec_normalize(rw_vec_cross(e1, e2))
			if(rw_vec_dot(normal, origin) < 0)
				normal = rw_vec_scale(normal, -1)
			faces += list(list(d - 1, upper, origin, e1, e2, normal))
	return faces

/proc/rw_vec_add(list/a, list/b)
	return list(a[1] + b[1], a[2] + b[2], a[3] + b[3])

/proc/rw_vec_sub(list/a, list/b)
	return list(a[1] - b[1], a[2] - b[2], a[3] - b[3])

/proc/rw_vec_scale(list/a, s)
	return list(a[1] * s, a[2] * s, a[3] * s)

/proc/rw_vec_dot(list/a, list/b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]

/proc/rw_vec_cross(list/a, list/b)
	return list(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])

/proc/rw_vec_normalize(list/a)
	var/length = sqrt(a[1] * a[1] + a[2] * a[2] + a[3] * a[3])
	if(!length)
		return a.Copy()
	return list(a[1] / length, a[2] / length, a[3] / length)

/// Unnormalised point on a diamond's folded surface for lattice (i, j), diamond 0-based.
/datum/rimworld_planet/proc/hex_flat_point(diamond, i, j)
	var/list/corners = rw_hex_diamonds()[diamond + 1]
	var/n = grid_frequency
	if(i + j <= n)
		return rw_vec_add(rw_vec_add(rw_vec_scale(corners[1], 1 - (i + j) / n), rw_vec_scale(corners[2], i / n)), rw_vec_scale(corners[4], j / n))
	return rw_vec_add(rw_vec_add(rw_vec_scale(corners[3], (i + j) / n - 1), rw_vec_scale(corners[2], 1 - j / n)), rw_vec_scale(corners[4], 1 - i / n))

/// Unit vector to a tile's centre.
/datum/rimworld_planet/proc/get_tile_center(x, y)
	if(y == grid_frequency + 1)
		return x == 1 ? list(0, 1, 0) : list(0, -1, 0)
	var/diamond = floor((x - 1) / grid_frequency)
	var/i = (x - 1) % grid_frequency
	return rw_vec_normalize(hex_flat_point(diamond, i, y))

/**
 * The owner of a lattice point given in some diamond's frame (0-based diamond, i and j in
 * 0..n). Points on the edges a diamond does not own are handed to the neighbour that does.
 */
/datum/rimworld_planet/proc/hex_canonical(diamond, i, j)
	var/n = grid_frequency
	var/d = diamond
	for(var/guard in 1 to 4)
		if(j >= 1 && i <= n - 1)
			return list(d * n + i + 1, j)
		var/north = d < 5
		var/k = d % 5
		if(j == 0)
			if(i == 0)
				if(north)
					return list(1, n + 1)
				// Upper-ring corner: owned as north diamond k's D corner
				return list(k * n + 1, n)
			if(north)
				d = (k + 4) % 5
				j = i
				i = 0
			else
				d = k
				j = n
			continue
		// i == n
		if(north)
			d = 5 + ((k + 4) % 5)
			i = 0
		else
			if(j == n)
				return list(2, n + 1)
			d = 5 + ((k + 4) % 5)
			i = j
			j = n
	CRASH("Could not canonicalise hex lattice point [diamond]:[i],[j]")

/// The tile whose centre is nearest a direction, as list(x, y).
/datum/rimworld_planet/proc/get_tile_from_direction(list/direction)
	var/list/dir = rw_vec_normalize(direction)
	var/n = grid_frequency
	if(dir[2] >= 1)
		return list(1, n + 1)
	if(dir[2] <= -1)
		return list(2, n + 1)

	var/list/face
	var/best = -INFINITY
	for(var/list/candidate as anything in rw_hex_faces())
		var/alignment = rw_vec_dot(dir, candidate[6])
		if(alignment > best)
			best = alignment
			face = candidate

	// Where the ray meets the face's plane, in the face's (u, v) coordinates
	var/list/origin = face[3]
	var/list/e1 = face[4]
	var/list/e2 = face[5]
	var/list/normal = face[6]
	var/list/hit = rw_vec_scale(dir, rw_vec_dot(origin, normal) / rw_vec_dot(dir, normal))
	var/list/q = rw_vec_sub(hit, origin)
	var/a11 = rw_vec_dot(e1, e1)
	var/a12 = rw_vec_dot(e1, e2)
	var/a22 = rw_vec_dot(e2, e2)
	var/b1 = rw_vec_dot(q, e1)
	var/b2 = rw_vec_dot(q, e2)
	var/det = a11 * a22 - a12 * a12
	var/u = (b1 * a22 - b2 * a12) / det
	var/v = (b2 * a11 - b1 * a12) / det

	// Upper face: u weighs D (1 - i/n) and v weighs B (1 - j/n)
	var/fi = face[2] ? n * (1 - u) : n * u
	var/fj = face[2] ? n * (1 - v) : n * v

	var/best_dot = -INFINITY
	var/best_i = 0
	var/best_j = 0
	var/base_i = floor(fi)
	var/base_j = floor(fj)
	for(var/di in -1 to 2)
		for(var/dj in -1 to 2)
			var/i = base_i + di
			var/j = base_j + dj
			if(i < 0 || j < 0 || i > n || j > n)
				continue
			var/alignment = rw_vec_dot(dir, rw_vec_normalize(hex_flat_point(face[1], i, j)))
			if(alignment > best_dot)
				best_dot = alignment
				best_i = i
				best_j = j
	return hex_canonical(face[1], best_i, best_j)

/// Adjacent tiles as a list of list(x, y): 6, or 5 around the 12 pentagons.
/datum/rimworld_planet/proc/get_neighbors(x, y)
	var/list/result = list()
	for(var/list/tile as anything in get_neighbors_with_bits(x, y))
		result += list(list(tile[1], tile[2]))
	return result

/**
 * Adjacent tiles as list(list(x, y, bit), ...). bit is the tile's index in the six lattice
 * steps (1,0) (-1,0) (0,1) (0,-1) (1,-1) (-1,1) of this tile's own diamond, or the spoke 0..4
 * at a pole. River masks use it, so it matches rust-g's NEIGHBOUR_OFFSETS and the shader.
 */
/datum/rimworld_planet/proc/get_neighbors_with_bits(x, y)
	var/n = grid_frequency
	var/list/found = list()
	var/list/result = list()

	var/list/candidates = list()
	if(y == n + 1)
		for(var/k in 0 to 4)
			var/list/spoke = x == 1 ? hex_canonical(k, 1, 0) : hex_canonical(5 + k, n - 1, n)
			candidates += list(list(spoke[1], spoke[2], k))
	else
		var/diamond = floor((x - 1) / n)
		var/i = (x - 1) % n
		var/static/list/offsets = list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1), list(1, -1), list(-1, 1))
		for(var/bit in 0 to 5)
			var/list/offset = offsets[bit + 1]
			var/ni = i + offset[1]
			var/nj = y + offset[2]
			if(ni >= 0 && nj >= 0 && ni <= n && nj <= n)
				var/list/owner = hex_canonical(diamond, ni, nj)
				candidates += list(list(owner[1], owner[2], bit))
				continue
			// Off this diamond: step the same distance along the surface and look it up
			var/list/here = get_tile_center(x, y)
			var/list/step = rw_vec_sub(rw_vec_normalize(hex_flat_point(diamond, i + offset[1] * 0.5, y + offset[2] * 0.5)), rw_vec_normalize(hex_flat_point(diamond, i, y)))
			var/list/stepped = get_tile_from_direction(rw_vec_add(here, rw_vec_scale(step, 2)))
			// At a pentagon one step points into the gap where a sixth cell would be, and the
			// lookup there lands on a cell that isn't adjacent. Adjacent cells share an edge, so
			// the point halfway between their centres belongs to one of the two.
			var/list/midway = get_tile_from_direction(rw_vec_add(here, get_tile_center(stepped[1], stepped[2])))
			if((midway[1] == x && midway[2] == y) || (midway[1] == stepped[1] && midway[2] == stepped[2]))
				candidates += list(list(stepped[1], stepped[2], bit))

	for(var/list/tile as anything in candidates)
		var/key = "[tile[1]],[tile[2]]"
		if((tile[1] == x && tile[2] == y) || found[key])
			continue
		found[key] = TRUE
		result += list(tile)
	return result

/**
 * Neighbours with their compass bearing from this tile, in degrees clockwise from north, as
 * list(list("x", "y", "bearing"), ...).
 */
/datum/rimworld_planet/proc/get_neighbor_ring(x, y)
	var/list/center = get_tile_center(x, y)
	var/list/east = rw_vec_normalize(rw_vec_cross(center, list(0, 1, 0)))
	// At a pole every direction is south; any fixed east keeps the ring consistent
	if(!(east[1] || east[2] || east[3]))
		east = list(0, 0, 1)
	var/list/north = rw_vec_cross(east, center)
	var/list/ring = list()
	for(var/list/tile as anything in get_neighbors(x, y))
		var/list/offset = rw_vec_sub(get_tile_center(tile[1], tile[2]), center)
		var/bearing = arctan(rw_vec_dot(offset, north), rw_vec_dot(offset, east))
		if(bearing < 0)
			bearing += 360
		ring += list(list("x" = tile[1], "y" = tile[2], "bearing" = bearing))
	return ring

/// Latitude and longitude of a tile's centre in degrees, as list(lat, lon).
/datum/rimworld_planet/proc/get_tile_lat_lon(x, y)
	var/list/center = get_tile_center(x, y)
	return list(arcsin(clamp(center[2], -1, 1)), arctan(center[1], center[3]))

/// Mean angular distance between neighbouring tile centres, in degrees.
/datum/rimworld_planet/proc/get_tile_spacing()
	return sqrt(4 * PI / (10 * grid_frequency * grid_frequency + 2)) * 180 / PI

/// Great-circle distance between two tiles, in tile steps.
/datum/rimworld_planet/proc/get_tile_distance(x1, y1, x2, y2)
	var/cosine = clamp(rw_vec_dot(get_tile_center(x1, y1), get_tile_center(x2, y2)), -1, 1)
	return arccos(cosine) / get_tile_spacing()
