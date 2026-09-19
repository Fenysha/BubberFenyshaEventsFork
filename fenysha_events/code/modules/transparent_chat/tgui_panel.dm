// 516.1680 gave browser controls inner-background-color and transparency, and 516.1683 fixed a
// crash when removing a focused runtime-created browser - which is what switching layouts does.

#if !defined(SPACEMAN_DMM) && !defined(OPENDREAM) && (DM_VERSION < 516 || (DM_VERSION == 516 && DM_BUILD < 1683))
#warn Chat layouts other than the docked panel need BYOND 516.1683 or later. The floating chat will render opaque and switching layouts may crash the client.
#endif
#define TGPANEL_POPUP_WINDOW "tgui_panel_popup"
/// Shell page for the detached chat window. A string define keeps the quotes out of the
/// browse() call - a quoted macro inside an embedded expression desyncs DM's string parser,
/// and it reports the damage in whatever unrelated file it happens to land on.
#define POPUP_CHAT_HTML {"<html><head><title>Chat</title></head><body style='margin:0;background:#202020'></body></html>"}

/datum/tgui_panel
	/// Which TGPANEL_* layout the browser control is currently parented for
	var/current_layout
	/// Splitter id -> position from before we collapsed the pane on its right
	var/list/saved_splitters = list()

/**
 * Builds the chat browser control under the window the layout wants, and puts the input bar
 * next to it. skin.dmf deliberately does not declare browseroutput: winset only honours
 * `parent` while *creating* a control, so the control is destroyed and rebuilt to move it.
 *
 * Over the map it is parented straight to mapwindow. Transparency composites against the
 * control's immediate parent, and the colours have to be part of the creating winset so the
 * webview is built see-through rather than repainted afterwards.
 *
 * The input bar is a pane rather than a control, so that one is hosted in a CHILD instead.
 */
/datum/tgui_panel/proc/create_browser(layout = TGPANEL_PANEL, reload = FALSE)
	log_tgui(client, "create_browser: [current_layout] -> [layout], reload=[reload]", context = "tgui_panel")

	if(current_layout == TGPANEL_WINDOW && layout != TGPANEL_WINDOW)
		var/closing_id = TGPANEL_POPUP_WINDOW
		client << browse(null, "window=[closing_id]")

	var/previous_layout = current_layout

	// Delete the old control, otherwise the create below is a no-op and nothing moves.
	// Focus leaves it first - removing a focused runtime browser crashed clients before 516.1683.
	if(!isnull(previous_layout))
		winset(client, SKIN_MAPWINDOW_MAP, "focus=true")
		winset(client, "browseroutput", list("parent" = "none"))

	current_layout = layout
	// Before the chat, so the chat overlay draws over full-map interfaces
	ensure_map_ui_host()

	switch(layout)
		if(TGPANEL_ONMAP)
			collapse_pane(SKIN_MAINWINDOW_SPLIT)
			// Two winsets on purpose. Including pos/size in the creating call makes `parent`
			// silently fall back to output_browser, and the colours only take in the creating
			// call - so create bare, then give it a rect. tgchat resizes it once it boots;
			// this is only so the chat is visible if that never happens.
			winset(client, "browseroutput", list(
				"parent" = SKIN_MAPWINDOW,
				"type" = "BROWSER",
				"background-color" = "none",
				"inner-background-color" = "transparent",
			))
			winset(client, "browseroutput", list(
				"pos" = "0,0",
				"size" = "640x456",
			))

		if(TGPANEL_WINDOW)
			var/popup_id = TGPANEL_POPUP_WINDOW
			client << browse(POPUP_CHAT_HTML, "window=[popup_id];size=640x456;can_close=0;titlebar=0")
			winset(client, TGPANEL_POPUP_WINDOW, list("background-color" = "#202020"))
			collapse_pane(SKIN_MAINWINDOW_SPLIT)
			winset(client, "browseroutput", list(
				"parent" = TGPANEL_POPUP_WINDOW,
				"type" = "BROWSER",
				"pos" = "0,0",
				"size" = "640x456",
				"anchor1" = "0,0",
				"anchor2" = "100,100",
			))

		else // TGPANEL_PANEL - tgchat sizes it from the pane once it boots
			restore_pane(SKIN_MAINWINDOW_SPLIT, "info_and_buttons")
			// The pane shows output_legacy until tgchat swaps it, and an undisplayed pane
			// can't take a new child, so put it on screen before parenting into it
			winset(client, OUTPUT_SELECTOR_LEGACY_OUTPUT_SELECTOR, list("left" = "output_browser"))
			winset(client, "browseroutput", list(
				"parent" = "output_browser",
				"type" = "BROWSER",
				"pos" = "0,0",
				"size" = "640x456",
				"anchor1" = "0,0",
				"anchor2" = "100,100",
			))

	if(layout != TGPANEL_ONMAP)
		client.mob?.hud_used?.displace_hud_for_chat(null)

	client.view_size?.setDefault(VIEWPORT_USE_PREF)
	// The admin say macro bakes in the open command, which depends on the layout
	client.update_special_keybinds()

	// A rebuilt control is an empty webview, so reload tgchat into it. It asks for the layout
	// again once it's ready, which covers the message below arriving before it can listen.
	send_layout()
	if(!isnull(previous_layout) || reload)
		initialize(force = TRUE)

/// Frees the pane on a splitter's right, remembering where the splitter sat.
/datum/tgui_panel/proc/collapse_pane(splitter_id)
	if(isnull(saved_splitters[splitter_id]))
		saved_splitters[splitter_id] = winget(client, splitter_id, "splitter")
	winset(client, splitter_id, list("right" = ""))

/datum/tgui_panel/proc/restore_pane(splitter_id, pane)
	var/list/params = list("right" = pane)
	// The splitter is a saved-param, so without this it stays wherever collapsing left it
	if(!isnull(saved_splitters[splitter_id]))
		params["splitter"] = saved_splitters[splitter_id]
		saved_splitters -= splitter_id
	winset(client, splitter_id, params)

/// Tells tgchat which layout it is in. Sniffing the control's parent from JS proved unreliable.
/datum/tgui_panel/proc/send_layout()
	window.send_message("panel/layout", list("layout" = current_layout))

/// tgchat asks for this on mount, since it can come up after create_browser has already run.
/datum/tgui_panel/proc/on_request_layout()
	send_layout()
	return TRUE

/datum/tgui_panel/proc/on_toggle_layout()
	var/next = current_layout == TGPANEL_ONMAP ? TGPANEL_PANEL : TGPANEL_ONMAP
	// update_preference() refuses unless the prefs menu is open on the matching tab, so write directly
	client.prefs.write_preference(GLOB.preference_entries[/datum/preference/choiced/tgpanel_layout], next)
	create_browser(next)
	return TRUE

/// Receives the chat browser's rect from tgchat and hands it to the HUD so screen objects can move clear of it.
/datum/tgui_panel/proc/on_chat_bounds(list/payload)
	var/datum/hud/hud = client.mob?.hud_used
	if(!hud)
		return TRUE

	var/x = payload["x"]
	var/y = payload["y"]
	var/w = payload["w"]
	var/h = payload["h"]
	if(isnull(x) || isnull(y) || isnull(w) || isnull(h))
		hud.displace_hud_for_chat(null)
		return TRUE

	// The map is letterboxed inside its element, so the chat rect has to be rebased onto the rendered area
	var/map_view_size = winget(client, SKIN_MAPWINDOW_MAP, "view-size")
	var/map_elem_size = winget(client, SKIN_MAPWINDOW_MAP, "size")
	var/list/view_parts = splittext("[map_view_size]", "x")
	var/list/elem_parts = splittext("[map_elem_size]", "x")
	if(length(view_parts) < 2 || length(elem_parts) < 2)
		return TRUE
	var/view_w = text2num(view_parts[1])
	var/view_h = text2num(view_parts[2])
	var/elem_w = text2num(elem_parts[1])
	var/elem_h = text2num(elem_parts[2])
	if(!view_w || !view_h)
		return TRUE
	hud.cached_map_view_size = list(view_w, view_h)

	var/adj_x = x - (elem_w - view_w) / 2
	var/adj_y = y - (elem_h - view_h) / 2
	var/adj_right = min(adj_x + w, view_w)
	var/adj_bottom = min(adj_y + h, view_h)
	adj_x = max(adj_x, 0)
	adj_y = max(adj_y, 0)

	if(adj_right - adj_x > 0 && adj_bottom - adj_y > 0)
		hud.displace_hud_for_chat(list(adj_x, adj_y, adj_right - adj_x, adj_bottom - adj_y))
	else
		hud.displace_hud_for_chat(null)
	return TRUE

#undef TGPANEL_POPUP_WINDOW
