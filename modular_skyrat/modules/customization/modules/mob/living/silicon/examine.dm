/**
 *  Returns a list of lines containing silicon flavourtext, temporary flavourtext, ERP preferences and a link to "look closer" and open the examine panel.
 *  Intended to be appended at the end of examine() result.
 */
// FENYSHA EDIT CHANGE - takes the examiner, as /mob/living/carbon/get_flavor_text() does.
// ORIGINAL: /mob/living/silicon/proc/get_silicon_flavortext()
/mob/living/silicon/proc/get_silicon_flavortext(mob/user)
	. = list()
	var/flavor_text_link
	var/silicon_full_text = client?.prefs.read_preference(/datum/preference/text/silicon_flavor_text)

#if defined(NOERP)
	// FENYSHA EDIT ADDITION - no examine panel on these builds, so a long description collapses in chat
	if(length(silicon_full_text))
		flavor_text_link = span_notice(collapsed_chat_text(user?.client, silicon_full_text, client))
#else
	/// The first 1-FLAVOR_PREVIEW_LIMIT characters in the mob's client's silicon_flavor_text preference datum. FLAVOR_PREVIEW_LIMIT is defined in flavor_defines.dm.
	var/silicon_preview_text = copytext_char(silicon_full_text, 1, FLAVOR_PREVIEW_LIMIT)
	flavor_text_link = span_notice("[translated_chat_text(user?.client, silicon_preview_text, client)]... <a href='byond://?src=[REF(src)];lookup_info=open_examine_panel'>Look closer?</a>")
#endif

	if (flavor_text_link)
		. += flavor_text_link

	if(client)
#if !defined(NOERP)
		var/erp_status_pref = client.prefs.read_preference(/datum/preference/choiced/erp_status)
		var/free_use_pref = client.prefs.read_preference(/datum/preference/toggle/erp_free_use)
		if(erp_status_pref && !CONFIG_GET(flag/disable_erp_preferences))
			. += span_info("ERP Status: [span_revenboldnotice(erp_status_pref)][free_use_pref ? "[span_revenboldnotice(" - Free Use")]" : ""]")
#endif
		var/line = get_gender_attraction_string(client.prefs.read_preference(/datum/preference/choiced/display_gender), client.prefs.read_preference(/datum/preference/choiced/attraction))
		if(line)
			. += span_info(line)
	if(temporary_flavor_text)
		if(length_char(temporary_flavor_text) <= 40)
			. += span_notice("<b>They look different than usual:</b> [temporary_flavor_text]")
		else
			. += span_notice("<b>They look different than usual:</b> [copytext_char(temporary_flavor_text, 1, 37)]... <a href='byond://?src=[REF(src)];temporary_flavor=1'>More...</a>")

/mob/living/silicon/get_chat_examine_headshot(mob/user)
	if(!client?.prefs || !user?.client?.prefs)
		return null
	if(!user.client.prefs.read_preference(/datum/preference/toggle/chat_examine_headshot))
		return null

	var/headshot = client.prefs.read_preference(/datum/preference/text/headshot/silicon)
	if(!length(headshot))
		return null

	return "<div class='chat_headshot_top chat_headshot_frame'>[chat_headshot(html_encode(headshot))]</div>"
