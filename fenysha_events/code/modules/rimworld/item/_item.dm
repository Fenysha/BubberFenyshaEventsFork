/obj/item
	/// Degrees (C) this item extends the comfortable range DOWNWARD. null = derive from vanilla.
	var/rw_cold_insulation = null
	/// Degrees (C) this item extends the comfortable range UPWARD. null = derive from vanilla.
	var/rw_heat_insulation = null

	/// Cells occupied on the X axis (before rotation)
	var/grid_width = 1
	/// Cells occupied on the Y axis (before rotation)
	var/grid_height = 1
	/// Current rotation in degrees: 0, 90, 180, 270
	var/grid_rotation = GRID_ROT_0
	/// Physical weight in kilograms
	var/weight_kg = 0.1
	/// Logical volume units (independent of grid size)
	var/rw_volume = 1
