ADMIN_VERB(cmd_admin_say, R_NONE, "ASay", "Send a message to other admins", ADMIN_CATEGORY_MAIN, message as text)
	message = emoji_parse(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return

	if(findtext(message, "@") || findtext(message, "#"))
		var/list/link_results = check_asay_links(message)
		if(length(link_results))
			message = link_results[ASAY_LINK_NEW_MESSAGE_INDEX]
			link_results[ASAY_LINK_NEW_MESSAGE_INDEX] = null
			var/list/pinged_admin_clients = link_results[ASAY_LINK_PINGED_ADMINS_INDEX]
			for(var/iter_ckey in pinged_admin_clients)
				var/client/iter_admin_client = pinged_admin_clients[iter_ckey]
				if(!iter_admin_client?.holder)
					continue
				window_flash(iter_admin_client)
				SEND_SOUND(iter_admin_client.mob, sound('sound/misc/asay_ping.ogg'))

	user.mob.log_talk(message, LOG_ASAY)
	message = keywords_lookup(message)
	send_asay_to_other_server(user.ckey, message) //SKYRAT EDIT ADDITION
	var/asay_color = user.prefs.read_preference(/datum/preference/color/asay_color)
	var/custom_asay_color = (CONFIG_GET(flag/allow_admin_asaycolor) && asay_color) ? "<font color=[asay_color]>" : "<font color='[DEFAULT_ASAY_COLOR]'>"
	// FENYSHA EDIT ADDITION - AUTOTRANSLATE - the body as it is about to be embedded, so a reader
	// who wants it translated gets just that part swapped and keeps the header, colour and links.
	var/asay_body = message
	// FENYSHA EDIT ADDITION END
	message = "[span_adminsay("[span_prefix("ADMIN:")] <EM>[key_name_admin(user)]</EM> [ADMIN_FLW(user.mob)]: [custom_asay_color]<span class='message linkify'>[message]")]</span>[custom_asay_color ? "</font>":null]"
	for(var/client/admin as anything in GLOB.admins)
		// FENYSHA EDIT ADDITION - AUTOTRANSLATE
		var/shown_message = message
		var/translated_asay = translated_chat_text(admin, asay_body, user)
		if(translated_asay != asay_body)
			shown_message = replacetext(message, asay_body, translated_asay)
		// FENYSHA EDIT ADDITION END
		to_chat(admin,
			type = MESSAGE_TYPE_ADMINCHAT,
			html = shown_message,
			avoid_highlighting = (admin == user),
			confidential = TRUE,
		)

	BLACKBOX_LOG_ADMIN_VERB("Asay")

/client/proc/get_admin_say()
	var/msg = input(src, null, "asay \"text\"") as text|null
	SSadmin_verbs.dynamic_invoke_verb(src, /datum/admin_verb/cmd_admin_say, msg)
