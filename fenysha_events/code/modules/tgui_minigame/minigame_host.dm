/// Minigames render in a transparent browser over the map pane, so the dimmed map shows through.

#define MINIGAME_BROWSER "minigame_browser"

/datum/tgui_panel
	/// tgui window bound to the minigame host control
	var/datum/tgui_window/minigame_window

/**
 * Builds the hidden host. It is made on first use, after the chat overlay, so it draws above the
 * chat too. Transparency only takes when set in the creating winset.
 */
/datum/tgui_panel/proc/ensure_minigame_host()
	if(winexists(client, MINIGAME_BROWSER))
		return
	winset(client, MINIGAME_BROWSER, list(
		"parent" = SKIN_MAPWINDOW,
		"type" = "BROWSER",
		"background-color" = "none",
		"inner-background-color" = "transparent",
	))
	var/map_size = winget(client, SKIN_MAPWINDOW, "size")
	winset(client, MINIGAME_BROWSER, list(
		"is-visible" = FALSE,
		"pos" = "0,0",
		"size" = map_size,
		"anchor1" = "0,0",
		"anchor2" = "100,100",
	))

/datum/tgui_panel/proc/get_minigame_window()
	ensure_minigame_host()
	if(!minigame_window)
		minigame_window = new(client, MINIGAME_BROWSER)
	minigame_window.locked_by?.close()
	return minigame_window

/// Renders into the transparent minigame host; falls back to a pop-up without a chat panel.
/datum/tgui/map_embedded/minigame
	host_id = MINIGAME_BROWSER

/datum/tgui/map_embedded/minigame/get_host_window(datum/tgui_panel/panel)
	return panel.get_minigame_window()

/// Greys the map behind an open minigame
/datum/client_colour/minigame_backdrop
	color = COLOR_MATRIX_GRAYSCALE
	priority = CLIENT_COLOR_FILTER_PRIORITY
	split_filters = TRUE
	fade_in = 0.4 SECONDS
	fade_out = 0.4 SECONDS

#undef MINIGAME_BROWSER
