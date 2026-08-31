/**
 * # Say pipeline integration
 *
 * The decision half of the Hear() hook. The core edits in
 * code/modules/mob/living/living_say.dm are kept to three marked blocks by
 * putting all the actual logic here.
 *
 * Every one of these gates exists for a reason - see the comments. The cheap
 * ones are checked first so the common case (an English speaker hearing
 * English on a server with the feature off) costs almost nothing.
 */

/**
 * Decides whether this listener should get a translation of this line, and if
 * so builds the handle for it.
 *
 * Returns a /datum/translated_speech, or null to leave the message alone.
 * The caller must then, in order: swap raw_message for wrapped_text(), build
 * the runechat bubble, attach_runechat() it, and finally begin().
 */
/mob/living/proc/try_begin_translation(atom/movable/speaker, raw_message, is_custom_emote, understood, message_obscured)
	// Emotes are not speech and are already excluded from IC language
	// handling upstream.
	if(is_custom_emote)
		return null

	// The listener does not know the IC language, so raw_message is already
	// scrambled gibberish. Translating it produces nonsense and burns backend
	// quota on garbage.
	if(!understood)
		return null

	// Eavesdropped speech has been through stars() and reads like
	// "s..eth.ng l..e th.s". Nothing useful survives translation.
	if(message_obscured)
		return null

	// Radio arrives through a virtualspeaker standing in for whoever is on the
	// other end, so resolve that before deciding anything about the speaker.
	var/atom/movable/actual_speaker = speaker?.GetSource() || speaker

	// Player speech only. Announcement computers, bots, NPC mobs and the
	// station's automated chatter are all in English already and none of it is
	// worth spending backend quota on.
	if(!ismob(actual_speaker))
		return null
	var/mob/speaking_mob = actual_speaker
	if(!GET_CLIENT(speaking_mob))
		return null

	// Watching your own words rewrite themselves is disorienting. Drop this
	// check if you would rather see what everyone else sees.
	if(speaking_mob == src)
		return null

	var/client/listener = client
	if(isnull(listener))
		return null

	var/target_language = autotranslate_pref_to_code(listener.prefs?.read_preference(/datum/preference/choiced/autotranslate_target))
	if(isnull(target_language))
		return null

	if(!length(raw_message))
		return null

	// Script detection. Free, and it filters out the large majority of lines
	// before anything is dispatched - an English reader on an English server
	// only ever pays for the occasional Russian line.
	var/source_language = autotranslate_detect_language(raw_message)
	if(source_language == target_language)
		return null

	if(!SSautotranslate.can_translate(source_language, target_language))
		return null

	return new /datum/translated_speech(listener, raw_message, source_language, target_language)

/**
 * Chat-only translation for communication that is not mob speech.
 *
 * Returns the text to actually send: wrapped for the panel if a translation
 * is on its way, unchanged otherwise. Safe to call with any client and any
 * text - every gate is checked internally.
 *
 * Dispatch is deferred a tick so the caller's own to_chat is queued into
 * SSchat first, keeping the line ahead of its translation notice.
 *
 * `author` is whoever wrote the line, when there is one. A player watching
 * their own words rewrite themselves is disorienting and tells them nothing,
 * so the writer always sees exactly what they typed - the same rule
 * try_begin_translation() applies to speech.
 *
 * Use for announcements, narrations, admin PMs and similar. Speech goes
 * through try_begin_translation() instead, since that also drives runechat.
 */
/**
 * Translation for surfaces that render once and cannot animate - the ticket panels, which are
 * plain browse() windows with none of the chat panel's morph script behind them.
 *
 * Returns a finished translation when one is already cached, otherwise the original text, and
 * requests it so the panel's own Refresh link has it a moment later. Never wraps or defers,
 * because there is nothing on the other end to resolve a pending marker.
 */
/proc/translated_panel_text(client/target, text)
	if(isnull(target) || !istext(text) || !length(text))
		return text

	var/target_language = autotranslate_pref_to_code(target.prefs?.read_preference(/datum/preference/choiced/autotranslate_target))
	if(isnull(target_language))
		return text

	var/source_language = autotranslate_detect_language(text)
	if(source_language == target_language)
		return text

	if(!SSautotranslate.can_translate(source_language, target_language))
		return text

	var/cached = SSautotranslate.cached_translation(text, source_language, target_language)
	if(!isnull(cached))
		return cached

	// Warm the cache for the next render. request_translation() stores the result itself, so the
	// callback has nothing to do - it exists only because a request with no subscriber is rejected.
	SSautotranslate.request_translation(text, source_language, target_language, CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(translation_noop)))
	return text

/// Subscriber for requests made purely to populate the cache.
/proc/translation_noop(result, success)
	return

/**
 * Swaps a known prose fragment inside an already-formatted line for its translation.
 *
 * Returns the line unchanged when there is nothing to swap, so callers can use it unconditionally.
 * Only the fragment is ever sent to a translator; timestamps, names and links stay untouched.
 */
/proc/translated_panel_line(client/target, line, body)
	if(!istext(body) || !length(body))
		return line
	var/translated = translated_panel_text(target, body)
	if(translated == body)
		return line
	return replacetext(line, body, translated)

/proc/translated_chat_text(client/target, text, client/author)
	if(isnull(target) || !istext(text) || !length(text))
		return text

	if(!isnull(author) && target == author)
		return text

	var/target_language = autotranslate_pref_to_code(target.prefs?.read_preference(/datum/preference/choiced/autotranslate_target))
	if(isnull(target_language))
		return text

	var/source_language = autotranslate_detect_language(text)
	if(source_language == target_language)
		return text

	if(!SSautotranslate.can_translate(source_language, target_language))
		return text

	var/datum/translated_speech/handle = new(target, text, source_language, target_language)
	var/wrapped = handle.wrapped_text()
	addtimer(CALLBACK(handle, TYPE_PROC_REF(/datum/translated_speech, begin)), 0)
	return wrapped
