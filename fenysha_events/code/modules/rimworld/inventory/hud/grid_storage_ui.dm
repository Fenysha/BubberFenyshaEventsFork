#define GRID_UI_CELL_PLANE ABOVE_HUD_PLANE
#define GRID_UI_ITEM_PLANE (ABOVE_HUD_PLANE + 1)
#define GRID_UI_BG_COLOR "#121212"
#define GRID_UI_EMPTY_COLOR "#2a2a2a"
#define GRID_UI_OCCUPIED_COLOR "#3a3540"
#define GRID_UI_HOVER_COLOR "#3d5c3d"
#define GRID_UI_VALID_COLOR "#2e5c2e"
#define GRID_UI_INVALID_COLOR "#5c2e2e"

// ---------------------------------------------------------------------------
// Grid cell
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_cell
	name = ""
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "block"
	mouse_opacity = MOUSE_OPACITY_ICON
	plane = GRID_UI_CELL_PLANE
	appearance_flags = APPEARANCE_UI | TILE_BOUND | PIXEL_SCALE
	var/grid_x = 1
	var/grid_y = 1
	var/datum/storage/grid/parent_grid
	var/atom/movable/screen/grid_storage_panel/parent_panel
	base_color = GRID_UI_EMPTY_COLOR
	var/is_occupied = FALSE

/atom/movable/screen/grid_cell/Initialize(mapload, datum/hud/hud_owner, datum/storage/grid/grid, atom/movable/screen/grid_storage_panel/panel, x, y)
	. = ..()
	parent_grid = grid
	parent_panel = panel
	grid_x = x
	grid_y = y
	color = base_color
	// 32×32 icon → 16×16 visual. Scale around center; screen_loc compensates by -8.
	transform = matrix().Scale(GRID_CELL_SIZE / 32, GRID_CELL_SIZE / 32)

/atom/movable/screen/grid_cell/proc/set_occupied(occupied)
	is_occupied = occupied
	base_color = occupied ? GRID_UI_OCCUPIED_COLOR : GRID_UI_EMPTY_COLOR
	if(color == GRID_UI_EMPTY_COLOR || color == GRID_UI_OCCUPIED_COLOR)
		color = base_color

/atom/movable/screen/grid_cell/MouseEntered(location, control, params)
	. = ..()
	if(!parent_grid || !parent_panel)
		return

	var/mob/user = hud?.mymob
	if(!user)
		color = GRID_UI_HOVER_COLOR
		return

	var/obj/item/held = user.get_active_held_item()
	if(!held)
		color = GRID_UI_HOVER_COLOR
		return

	var/w = GRID_EFFECTIVE_WIDTH(held)
	var/h = GRID_EFFECTIVE_HEIGHT(held)
	// Green if free OR exactly one item to swap; red otherwise
	var/list/displaced = parent_grid.get_displaced_items(grid_x, grid_y, w, h, held)
	var/can_fit = (length(displaced) <= 1) && (grid_x >= 1 && grid_y >= 1 && grid_x + w - 1 <= parent_grid.grid_width && grid_y + h - 1 <= parent_grid.grid_height)
	parent_panel.preview_placement(grid_x, grid_y, w, h, can_fit)

/atom/movable/screen/grid_cell/MouseExited(location, control, params)
	. = ..()
	color = base_color
	parent_panel?.clear_preview()

/atom/movable/screen/grid_cell/Click(location, control, params)
	if(!parent_grid || !parent_panel)
		return TRUE
	var/mob/user = hud?.mymob
	if(!user || user != usr)
		return TRUE
	if(user.incapacitated)
		return TRUE

	var/list/modifiers = params2list(params)
	var/obj/item/held = user.get_active_held_item()

	var/obj/item/under = null
	if(grid_y >= 1 && grid_y <= parent_grid.grid_height && grid_x >= 1 && grid_x <= parent_grid.grid_width)
		under = parent_grid.grid_occupancy[grid_y][grid_x]

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(under)
			parent_panel.try_remove_item(user, under)
		return TRUE

	if(LAZYACCESS(modifiers, MIDDLE_CLICK) || LAZYACCESS(modifiers, ALT_CLICK))
		if(held)
			held.rotate_grid(90)
			to_chat(user, span_notice("Rotated [held] to [held.grid_rotation]°."))
			var/w = GRID_EFFECTIVE_WIDTH(held)
			var/h = GRID_EFFECTIVE_HEIGHT(held)
			var/list/displaced = parent_grid.get_displaced_items(grid_x, grid_y, w, h, held)
			var/can_fit = (length(displaced) <= 1) && (grid_x + w - 1 <= parent_grid.grid_width && grid_y + h - 1 <= parent_grid.grid_height)
			parent_panel.preview_placement(grid_x, grid_y, w, h, can_fit)
			return TRUE
		if(under)
			parent_grid.try_rotate_item(under, user)
			parent_panel.refresh_items()
		return TRUE

	if(held)
		parent_panel.try_insert_at(user, held, grid_x, grid_y)
		return TRUE

	if(under)
		parent_panel.try_remove_item(user, under)
	return TRUE


// ---------------------------------------------------------------------------
// Toolbar buttons
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_button
	name = ""
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "block"
	mouse_over_pointer = MOUSE_HAND_POINTER
	plane = GRID_UI_CELL_PLANE
	appearance_flags = APPEARANCE_UI
	var/atom/movable/screen/grid_storage_panel/parent_panel

/atom/movable/screen/grid_button/Initialize(mapload, datum/hud/hud_owner, atom/movable/screen/grid_storage_panel/panel, button_name)
	. = ..()
	parent_panel = panel
	name = button_name

/atom/movable/screen/grid_button/sort
	name = "Sort"
	icon = 'fenysha_events/icons/ui/storage_ui.dmi'
	icon_state = "sort"

/atom/movable/screen/grid_button/sort/Click()
	parent_panel?.parent_grid?.auto_sort(usr)
	parent_panel?.refresh_items()

/atom/movable/screen/grid_button/rotate
	name = "Rotate"
	icon = 'fenysha_events/icons/ui/storage_ui.dmi'
	icon_state = "rotate"

/atom/movable/screen/grid_button/rotate/Click()
	var/mob/user = usr
	var/obj/item/held = user.get_active_held_item()
	if(held)
		held.rotate_grid(90)
		to_chat(user, span_notice("Rotated [held] to [held.grid_rotation]°."))
		return
	to_chat(user, span_notice("Hold an item to rotate, or middle/alt-click an item in the grid."))

/atom/movable/screen/grid_button/close
	name = "Close"
	icon = 'fenysha_events/icons/ui/storage_ui.dmi'
	icon_state = "close"

/atom/movable/screen/grid_button/close/Click()
	parent_panel?.close_panel(usr)


// ---------------------------------------------------------------------------
// Main panel
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_storage_panel
	name = "storage"
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = HUD_PLANE
	appearance_flags = APPEARANCE_UI

	var/datum/storage/grid/parent_grid
	var/list/atom/movable/screen/grid_cell/cells = list()
	var/list/atom/movable/screen/item_on_grid = list()
	var/list/atom/movable/screen/grid_cell/preview_cells = list()

	var/atom/movable/screen/grid_button/sort_btn
	var/atom/movable/screen/grid_button/rotate_btn
	var/atom/movable/screen/grid_button/close_btn
	var/atom/movable/screen/grid_bg

	/// Anchor screen_loc tile coords (bottom-left of the grid area)
	var/anchor_x = 5
	var/anchor_y = 3
	var/anchor_px = 0
	var/anchor_py = 0

	/// Where to put the 16×16 control buttons
	var/toolbar_mode = GRID_TOOLBAR_RIGHT

	/// Pixel gap between grid edge and buttons
	var/toolbar_gap = 4

/atom/movable/screen/grid_storage_panel/Initialize(mapload, datum/hud/hud_owner, datum/storage/grid/grid)
	. = ..()
	parent_grid = grid
	if(istype(grid) && grid.toolbar_mode)
		toolbar_mode = grid.toolbar_mode
	build_ui()

/atom/movable/screen/grid_storage_panel/Destroy()
	QDEL_LIST(cells)
	QDEL_LIST(item_on_grid)
	preview_cells = null
	QDEL_NULL(sort_btn)
	QDEL_NULL(rotate_btn)
	QDEL_NULL(close_btn)
	QDEL_NULL(grid_bg)
	parent_grid = null
	return ..()

/atom/movable/screen/grid_storage_panel/proc/build_ui()
	if(!parent_grid)
		return
	var/gw = parent_grid.grid_width
	var/gh = parent_grid.grid_height
	var/grid_px_w = gw * GRID_CELL_SIZE
	var/grid_px_h = gh * GRID_CELL_SIZE

	// Background — slightly larger than the grid
	// Scale around icon center (16,16); place so visual center = grid center
	grid_bg = new /atom/movable/screen
	grid_bg.icon = 'icons/hud/screen_gen.dmi'
	grid_bg.icon_state = "block"
	grid_bg.color = GRID_UI_BG_COLOR
	grid_bg.plane = HUD_PLANE
	grid_bg.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	grid_bg.appearance_flags = APPEARANCE_UI
	var/bg_scale_x = (grid_px_w + 8) / 32
	var/bg_scale_y = (grid_px_h + 8) / 32
	grid_bg.transform = matrix().Scale(bg_scale_x, bg_scale_y)
	// visual center of scaled bg should sit at (grid_px_w/2, grid_px_h/2) relative to anchor
	var/bg_loc_px = round(grid_px_w / 2 - 16)
	var/bg_loc_py = round(grid_px_h / 2 - 16)
	grid_bg.screen_loc = "[anchor_x]:[anchor_px + bg_loc_px],[anchor_y]:[anchor_py + bg_loc_py]"

	// Buttons
	sort_btn = new /atom/movable/screen/grid_button/sort(null, hud, src, "Sort")
	rotate_btn = new /atom/movable/screen/grid_button/rotate(null, hud, src, "Rotate")
	close_btn = new /atom/movable/screen/grid_button/close(null, hud, src, "Close")

	place_toolbar_buttons(gw, gh, grid_px_w, grid_px_h)

	// Cells — row-major: y outer, x inner → index = (y-1)*gw + x
	// Scale is around center; compensate screen_loc by -8 so visual top-left matches intended cell origin
	for(var/y in 1 to gh)
		for(var/x in 1 to gw)
			var/atom/movable/screen/grid_cell/cell = new(null, hud, parent_grid, src, x, y)
			var/pixel_x_off = (x - 1) * GRID_CELL_SIZE
			var/pixel_y_off = (y - 1) * GRID_CELL_SIZE
			cell.screen_loc = "[anchor_x]:[anchor_px + pixel_x_off - 8],[anchor_y]:[anchor_py + pixel_y_off - 8]"
			cells += cell

/atom/movable/screen/grid_storage_panel/proc/place_toolbar_buttons(gw, gh, grid_px_w, grid_px_h)
	sort_btn.invisibility = 0
	rotate_btn.invisibility = 0
	close_btn.invisibility = 0

	var/btn_size = 16
	var/gap = toolbar_gap

	switch(toolbar_mode)
		if(GRID_TOOLBAR_RIGHT)
			var/base_px = anchor_px + grid_px_w + gap
			var/base_py = anchor_py + grid_px_h - btn_size
			sort_btn.screen_loc   = "[anchor_x]:[base_px],[anchor_y]:[base_py]"
			rotate_btn.screen_loc = "[anchor_x]:[base_px],[anchor_y]:[base_py - (btn_size + 2)]"
			close_btn.screen_loc  = "[anchor_x]:[base_px],[anchor_y]:[base_py - 2*(btn_size + 2)]"

		if(GRID_TOOLBAR_TOP_RIGHT)
			var/base_px = anchor_px + grid_px_w - btn_size
			var/base_py = anchor_py + grid_px_h + gap
			close_btn.screen_loc  = "[anchor_x]:[base_px],[anchor_y]:[base_py]"
			rotate_btn.screen_loc = "[anchor_x]:[base_px - (btn_size + 2)],[anchor_y]:[base_py]"
			sort_btn.screen_loc   = "[anchor_x]:[base_px - 2*(btn_size + 2)],[anchor_y]:[base_py]"

		if(GRID_TOOLBAR_BOTTOM_LEFT)
			var/base_px = anchor_px
			var/base_py = anchor_py - btn_size - gap
			sort_btn.screen_loc   = "[anchor_x]:[base_px],[anchor_y]:[base_py]"
			rotate_btn.screen_loc = "[anchor_x]:[base_px + (btn_size + 2)],[anchor_y]:[base_py]"
			close_btn.screen_loc  = "[anchor_x]:[base_px + 2*(btn_size + 2)],[anchor_y]:[base_py]"

		else
			var/base_px = anchor_px + grid_px_w + gap
			var/base_py = anchor_py + grid_px_h - btn_size
			sort_btn.screen_loc   = "[anchor_x]:[base_px],[anchor_y]:[base_py]"
			rotate_btn.screen_loc = "[anchor_x]:[base_px],[anchor_y]:[base_py - (btn_size + 2)]"
			close_btn.screen_loc  = "[anchor_x]:[base_px],[anchor_y]:[base_py - 2*(btn_size + 2)]"

/atom/movable/screen/grid_storage_panel/proc/rebuild_toolbar()
	if(!parent_grid)
		return
	var/gw = parent_grid.grid_width
	var/gh = parent_grid.grid_height
	place_toolbar_buttons(gw, gh, gw * GRID_CELL_SIZE, gh * GRID_CELL_SIZE)

/**
 * Reposition the entire panel (cells, bg, buttons, items).
 * anchor_tile_x/y are screen tile keywords or numbers (e.g. "CENTER", 5).
 */
/atom/movable/screen/grid_storage_panel/proc/set_anchor(new_x, new_y, px = 0, py = 0)
	anchor_x = new_x
	anchor_y = new_y
	anchor_px = px
	anchor_py = py

	if(!parent_grid)
		return

	var/gw = parent_grid.grid_width
	var/gh = parent_grid.grid_height
	var/grid_px_w = gw * GRID_CELL_SIZE
	var/grid_px_h = gh * GRID_CELL_SIZE

	// Background
	if(grid_bg)
		var/bg_loc_px = round(grid_px_w / 2 - 16)
		var/bg_loc_py = round(grid_px_h / 2 - 16)
		grid_bg.screen_loc = "[anchor_x]:[anchor_px + bg_loc_px],[anchor_y]:[anchor_py + bg_loc_py]"

	// Cells
	for(var/atom/movable/screen/grid_cell/cell in cells)
		var/pixel_x_off = (cell.grid_x - 1) * GRID_CELL_SIZE
		var/pixel_y_off = (cell.grid_y - 1) * GRID_CELL_SIZE
		cell.screen_loc = "[anchor_x]:[anchor_px + pixel_x_off - 8],[anchor_y]:[anchor_py + pixel_y_off - 8]"

	place_toolbar_buttons(gw, gh, grid_px_w, grid_px_h)
	refresh_items()

/atom/movable/screen/grid_storage_panel/proc/show_to(mob/user)
	if(!user?.client)
		return
	var/list/to_add = list(src, grid_bg)
	to_add += cells
	to_add += list(sort_btn, rotate_btn, close_btn)
	user.client.screen |= to_add
	refresh_items()
	if(user.hud_used)
		LAZYOR(user.hud_used.screen_groups[HUD_GROUP_STORAGE], to_add)

/atom/movable/screen/grid_storage_panel/proc/hide_from(mob/user)
	// Always clean up even without client (logout)
	var/list/to_remove = list(src, grid_bg) + cells + list(sort_btn, rotate_btn, close_btn) + item_on_grid
	if(user?.client)
		user.client.screen -= to_remove
	if(user?.hud_used)
		if(user.hud_used.screen_groups[HUD_GROUP_STORAGE])
			user.hud_used.screen_groups[HUD_GROUP_STORAGE] -= to_remove
	QDEL_LIST(item_on_grid)
	clear_preview()

/atom/movable/screen/grid_storage_panel/proc/close_panel(mob/user)
	parent_grid?.hide_contents(user)

// ---------------------------------------------------------------------------
// Insert / remove with do_after
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_storage_panel/proc/try_insert_at(mob/user, obj/item/held, x, y)
	if(QDELETED(src) || !parent_grid || !user || !held)
		return
	if(user.get_active_held_item() != held)
		return
	if(user.incapacitated)
		return

	var/rot = held.grid_rotation
	var/w = GRID_EFFECTIVE_WIDTH(held)
	var/h = GRID_EFFECTIVE_HEIGHT(held)
	if(x < 1 || y < 1 || x + w - 1 > parent_grid.grid_width || y + h - 1 > parent_grid.grid_height)
		to_chat(user, span_warning("Doesn't fit there."))
		return

	if(!do_after(user, GRID_INSERT_DELAY, target = parent_grid.parent, timed_action_flags = IGNORE_USER_LOC_CHANGE))
		return
	if(QDELETED(src) || !parent_grid)
		return
	if(user.get_active_held_item() != held)
		return
	if(parent_grid.attempt_insert_at(held, user, x, y, rot))
		refresh_items()

/atom/movable/screen/grid_storage_panel/proc/try_remove_item(mob/user, obj/item/item)
	if(QDELETED(src) || !parent_grid || !user || !item)
		return
	if(user.incapacitated)
		return
	if(!parent_grid.item_positions[item])
		return

	if(!do_after(user, GRID_REMOVE_DELAY, target = parent_grid.parent, timed_action_flags = IGNORE_USER_LOC_CHANGE))
		return
	if(QDELETED(src) || !parent_grid)
		return
	if(!parent_grid.item_positions[item])
		return

	parent_grid.attempt_remove(item, null)
	user.put_in_hands(item)
	refresh_items()

// ---------------------------------------------------------------------------
// Item rendering
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_storage_panel/proc/refresh_items()
	for(var/atom/movable/screen/S in item_on_grid)
		if(hud?.mymob?.client)
			hud.mymob.client.screen -= S
	QDEL_LIST(item_on_grid)
	clear_preview()

	if(!parent_grid)
		return

	for(var/atom/movable/screen/grid_cell/cell in cells)
		cell.set_occupied(FALSE)

	for(var/obj/item/I as anything in parent_grid.item_positions)
		var/list/pos = parent_grid.item_positions[I]
		var/gx = pos[1]
		var/gy = pos[2]
		var/rot = pos[3]

		var/old_rot = I.grid_rotation
		I.grid_rotation = rot
		var/w = GRID_EFFECTIVE_WIDTH(I)
		var/h = GRID_EFFECTIVE_HEIGHT(I)
		I.grid_rotation = old_rot

		for(var/cy in gy to (gy + h - 1))
			for(var/cx in gx to (gx + w - 1))
				var/idx = (cy - 1) * parent_grid.grid_width + cx
				if(idx >= 1 && idx <= length(cells))
					var/atom/movable/screen/grid_cell/cell = cells[idx]
					cell?.set_occupied(TRUE)

		var/atom/movable/screen/item_proxy = build_item_proxy(I, gx, gy, w, h, rot)
		item_on_grid += item_proxy
		if(hud?.mymob?.client)
			hud.mymob.client.screen |= item_proxy

/**
 * Creates a screen object that shows the item icon centered inside its
 * w×h cell footprint.
 *
 * BYOND Scale/Turn around icon center. screen_loc places bottom-left of
 * the untransformed 32×32 icon. After Scale the visual center stays at
 * loc+16, so we place at (footprint_center - 16).
 */
/atom/movable/screen/grid_storage_panel/proc/build_item_proxy(obj/item/I, gx, gy, w, h, rot)
	var/atom/movable/screen/item_proxy = new
	item_proxy.appearance = I.appearance
	item_proxy.plane = GRID_UI_ITEM_PLANE
	item_proxy.layer = 1
	item_proxy.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	item_proxy.appearance_flags = APPEARANCE_UI | TILE_BOUND | PIXEL_SCALE

	// Sanitize appearance for HUD display
	item_proxy.pixel_x = 0
	item_proxy.pixel_y = 0
	item_proxy.pixel_w = 0
	item_proxy.pixel_z = 0
	item_proxy.alpha = 255
	item_proxy.invisibility = 0
	item_proxy.filters = null

	var/foot_w = w * GRID_CELL_SIZE
	var/foot_h = h * GRID_CELL_SIZE

	// Source icon size — default 32, try to read actual
	var/src_w = 32
	var/src_h = 32
	if(I.icon)
		var/list/dims = get_icon_dimensions(I.icon)
		if(dims)
			src_w = dims["width"] || 32
			src_h = dims["height"] || 32

	var/margin = 2
	var/target_w = max(foot_w - margin * 2, 8)
	var/target_h = max(foot_h - margin * 2, 8)
	var/scale = min(target_w / src_w, target_h / src_h)

	var/foot_origin_px = (gx - 1) * GRID_CELL_SIZE
	var/foot_origin_py = (gy - 1) * GRID_CELL_SIZE
	var/center_px = foot_origin_px + foot_w / 2
	var/center_py = foot_origin_py + foot_h / 2

	// Untransformed icon center is at loc + src/2; after Scale it stays there
	var/loc_px = round(center_px - src_w / 2)
	var/loc_py = round(center_py - src_h / 2)

	item_proxy.screen_loc = "[anchor_x]:[anchor_px + loc_px],[anchor_y]:[anchor_py + loc_py]"

	var/matrix/M = matrix()
	M.Scale(scale, scale)
	if(rot)
		M.Turn(rot)
	item_proxy.transform = M

	return item_proxy

// ---------------------------------------------------------------------------
// Preview tint
// ---------------------------------------------------------------------------

/atom/movable/screen/grid_storage_panel/proc/preview_placement(x, y, w, h, can_fit)
	clear_preview()
	if(!parent_grid)
		return

	var/color_to_use = can_fit ? GRID_UI_VALID_COLOR : GRID_UI_INVALID_COLOR
	var/gw = parent_grid.grid_width

	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			if(cx < 1 || cy < 1 || cx > gw || cy > parent_grid.grid_height)
				continue
			var/idx = (cy - 1) * gw + cx
			if(idx < 1 || idx > length(cells))
				continue
			var/atom/movable/screen/grid_cell/cell = cells[idx]
			if(!cell)
				continue
			cell.color = color_to_use
			preview_cells += cell

/atom/movable/screen/grid_storage_panel/proc/clear_preview()
	for(var/atom/movable/screen/grid_cell/cell in preview_cells)
		cell.color = cell.base_color
	preview_cells.Cut()

#undef GRID_UI_CELL_PLANE
#undef GRID_UI_ITEM_PLANE
#undef GRID_UI_BG_COLOR
#undef GRID_UI_EMPTY_COLOR
#undef GRID_UI_OCCUPIED_COLOR
#undef GRID_UI_HOVER_COLOR
#undef GRID_UI_VALID_COLOR
#undef GRID_UI_INVALID_COLOR
