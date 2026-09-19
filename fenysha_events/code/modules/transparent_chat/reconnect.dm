// The skin's Reconnect button is hidden while the chat floats over the map
GAME_VERB(/client, reconnect_to_server, "Reconnect", "OOC")
	winset(src, null, "command=.reconnect")
