/// Full-map interfaces (the planet map) render in this browser inside the map pane rather than
/// in a pop-up window, so they belong to the game window: no taskbar entry, and they move and
/// resize with it.

#define MAP_UI_BROWSER "map_ui_browser"

/datum/tgui_panel
	/// tgui window bound to the map UI host control
	var/datum/tgui_window/map_ui_window

/**
 * Builds the hidden host control. Runtime children of the map pane draw in creation order, so
 * this runs just before the chat is created, keeping the chat overlay on top of it. Layout
 * switches rebuild only the chat, which stays newer.
 */
/datum/tgui_panel/proc/ensure_map_ui_host()
	if(winexists(client, MAP_UI_BROWSER))
		return
	// Bare create, then a rect: pos/size in the creating call makes parent fall back
	winset(client, MAP_UI_BROWSER, list(
		"parent" = SKIN_MAPWINDOW,
		"type" = "BROWSER",
	))
	var/map_size = winget(client, SKIN_MAPWINDOW, "size")
	winset(client, MAP_UI_BROWSER, list(
		"is-visible" = FALSE,
		"pos" = "0,0",
		"size" = map_size,
		"anchor1" = "0,0",
		"anchor2" = "100,100",
	))

/datum/tgui_panel/proc/get_map_ui_window()
	ensure_map_ui_host()
	if(!map_ui_window)
		map_ui_window = new(client, MAP_UI_BROWSER)
	// One full-map interface at a time
	map_ui_window.locked_by?.close()
	return map_ui_window

/// A tgui that renders inside the map area instead of a pop-up. Falls back to a pop-up without a chat panel.
/datum/tgui/map_embedded
	/// Id of the map pane control this renders into
	var/host_id = MAP_UI_BROWSER

/datum/tgui/map_embedded/proc/get_host_window(datum/tgui_panel/panel)
	return panel.get_map_ui_window()

/datum/tgui/map_embedded/open()
	var/datum/tgui_panel/panel = user.client?.tgui_panel
	if(!panel)
		return ..()
	if(window)
		return FALSE
	process_status()
	if(status < UI_UPDATE)
		return FALSE
	// Mirrors /datum/tgui/open(), with the host window in place of a pooled one
	window = get_host_window(panel)
	opened_at = world.time
	window.acquire_lock(src)
	if(!window.is_ready())
		window.initialize(
			strict_mode = TRUE,
			assets = list(
				get_asset_datum(/datum/asset/simple/tgui),
			))
	else
		window.send_message("ping")
	send_assets()
	window.send_message("update", get_payload(
		with_data = TRUE,
		with_static_data = TRUE))
	SStgui.on_open(src)
	winset(user.client, host_id, "is-visible=true;focus=true")
	return TRUE

/datum/tgui/map_embedded/close(can_be_suspended = TRUE)
	var/client/viewer = user?.client
	var/embedded = window?.id == host_id
	. = ..()
	if(!embedded || !viewer)
		return
	winset(viewer, host_id, "is-visible=false")
	winset(viewer, SKIN_MAPWINDOW_MAP, "focus=true")
	// Keys released while the map UI had focus never reached the map
	viewer.reset_held_keys()

#undef MAP_UI_BROWSER
