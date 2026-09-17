/mob/living/proc/alien_talk(message, list/spans = list(), list/message_mods = list(), shown_name = real_name, big_voice = FALSE)
	log_sayverb_talk(message, message_mods, tag = "alien hivemind")
	message = trim(message)
	if(!message)
		return

	var/message_a = generate_messagepart(message, spans, message_mods)
	var/hivemind_spans = "alien"
	if(big_voice)
		hivemind_spans += " big"
	var/rendered = "<i><span class='[hivemind_spans]'>Hivemind, [span_name("[shown_name]")] <span class='message'>[message_a]</span></span></i>"
	// FENYSHA EDIT CHANGE BEGIN - AUTOTRANSLATE - ORIGINAL: both to_chat calls sent `rendered` unchanged
	for(var/mob/player in GLOB.player_list)
		var/shown = translated_line(player.client, rendered, message, client)
		if(!IS_UNCONSCIOUS_OR_CRIT(player) && player.hivecheck())
			to_chat(player, shown, type = MESSAGE_TYPE_RADIO, avoid_highlighting = player == src)
		else if(player in GLOB.dead_mob_list)
			var/link = FOLLOW_LINK(player, src)
			to_chat(player, "[link] [shown]", type = MESSAGE_TYPE_RADIO)
	// FENYSHA EDIT CHANGE END

/mob/living/carbon/alien/adult/royal/queen/alien_talk(message, list/spans = list(), list/message_mods = list(), shown_name = name, big_voice = TRUE)
	..(message, spans, message_mods, shown_name, TRUE)

/mob/living/carbon/hivecheck()
	var/obj/item/organ/alien/hivenode/N = get_organ_by_type(/obj/item/organ/alien/hivenode)
	if(N && !N.recent_queen_death) //Mob has alien hive node and is not under the dead queen special effect.
		return TRUE
