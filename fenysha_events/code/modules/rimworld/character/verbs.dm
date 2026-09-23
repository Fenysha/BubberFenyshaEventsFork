GAME_VERB_DESC(/client, open_rimworld_character_editor, "Prepare Colonist", "Open the Rimworld character editor.", "OOC")
	if(!rw_prefs)
		rw_prefs = new /datum/rimworld_preferences(src)
	rw_prefs.ui_interact(usr)

GAME_VERB_DESC(/client, apply_rimworld_character, "Apply Rimworld Character", "Apply the active Rimworld colonist prefs to your current human mob.", "OOC")
	if(!rw_prefs)
		return
	if(!ishuman(usr))
		to_chat(src, span_warning("You need a human body."))
		return
	rw_prefs.apply_to_human(usr)
	to_chat(src, span_notice("Rimworld character applied."))
