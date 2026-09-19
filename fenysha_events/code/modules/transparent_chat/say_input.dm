/// While the chat floats over the map, the speech hotkeys type into its input bar instead of
/// popping the tgui-say modal. The modal datum still does all the work - channels, typing
/// indicators, force-say, logging - it just talks to the chat panel instead of its own window.

/datum/tgui_say
	/// Whether the overlay chat's input bar is standing in for the modal right now
	var/panel_input = FALSE

/client/tgui_say_create_open_command(channel)
	if(tgui_panel?.current_layout != TGPANEL_ONMAP)
		return ..()
	var/message = TGUI_CREATE_MESSAGE("say/open", list("channel" = channel))
	// The chat also keeps claiming focus for a moment, since BYOND hands it back to the map
	// while the hotkey is still down
	return "\".output browseroutput:update [message]\\n.winset \\\"browseroutput.focus=true\\\"\""

/// The speech keybinds' focus step. Over the map the open command has already focused the
/// chat, and focusing the hidden modal here would steal it straight back.
/client/proc/focus_say_input()
	if(tgui_panel?.current_layout == TGPANEL_ONMAP)
		return
	winset(src, SKIN_TGUISAY_BROWSER, "focus=true")

/// Sends a server-to-input message to wherever the player is actually typing.
/datum/tgui_say/proc/message_input(type)
	if(panel_input && client.tgui_panel)
		client.tgui_panel.window.send_message("say/[type]")
		return
	window.send_message(type)

/// The chat panel's say messages, relayed with their "say/" prefix stripped.
/datum/tgui_say/proc/on_panel_message(type, payload)
	switch(type)
		if("open")
			panel_input = TRUE
			client.tgui_panel.window.send_message("say/props", list("maxLength" = max_length))
		if("close")
			panel_input = FALSE
	return on_message(type, payload)
