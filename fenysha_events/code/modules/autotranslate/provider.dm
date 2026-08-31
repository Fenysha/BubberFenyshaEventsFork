/**
 * # Translation providers
 *
 * A provider is the thing that actually turns text in one language into text
 * in another. Nothing in this module knows how that happens - swap the
 * provider and the whole feature retargets.
 *
 * The contract is deliberately poll-based rather than callback-based, because
 * that is what rustg's async HTTP looks like: you kick a request off, then ask
 * every tick whether it is done. A future CTranslate2 provider fills in
 * begin() with a request to the local service and poll() with
 * request.is_complete().
 *
 * Providers must never block. begin() kicks work off, poll() reports on it.
 */

/**
 * Fragments a translator must hand back untouched.
 *
 * Order matters: markup first, so the token patterns below run against text where every tag has
 * already become a placeholder and cannot be swallowed by a greedy match.
 *
 *   markup   linkifiers wrap mentions and names before we ever see the body; a transliterated
 *            <a href> is broken markup
 *   @word    admin pings and datum refs - check_asay_links() resolves these by exact ckey, so a
 *            translated one pings nobody
 *   #123     ticket references, likewise looked up by exact id
 */
GLOBAL_LIST_INIT(translation_protected_patterns, list(
	regex("<\[^>\]*>", "g"),
	regex(@"@[^\s{}]+", "g"),
	regex(@"#[0-9]+", "g"),
))

/**
 * Swaps every protected fragment for a numbered placeholder.
 *
 * Placeholders are `{0}`-style: ASCII, no letters for an engine to transliterate, and short enough
 * that it will not split them across a sentence boundary. Found fragments are appended to `tokens`
 * in placeholder order.
 */
/proc/translation_protect(text, list/tokens)
	if(!istext(text) || !length(text))
		return text
	for(var/regex/pattern as anything in GLOB.translation_protected_patterns)
		var/rebuilt = ""
		var/last = 1
		pattern.index = 1
		while(pattern.Find(text))
			rebuilt += copytext(text, last, pattern.index)
			rebuilt += "{[length(tokens)]}"
			tokens += pattern.match
			last = pattern.next
		if(last == 1)
			continue
		text = rebuilt + copytext(text, last)
	return text

/**
 * Puts the protected fragments back.
 *
 * Returns null if the translator dropped or mangled any placeholder. That is deliberate: a caller
 * that cannot restore a mention must show the untranslated original rather than a line where the
 * ping silently went missing.
 */
/proc/translation_restore(text, list/tokens)
	if(!length(tokens))
		return text
	if(!istext(text))
		return null
	// Tolerant of an engine padding the braces out to "{ 0 }".
	var/static/regex/placeholder = regex(@"\{\s*([0-9]+)\s*\}", "g")
	// Pre-sized, because seen[n] on an empty list is a positional write and runtimes out of bounds
	// rather than making an associative entry.
	var/list/seen = new /list(length(tokens))
	var/rebuilt = ""
	var/last = 1
	placeholder.index = 1
	while(placeholder.Find(text))
		var/index = text2num(placeholder.group[1])
		if(isnull(index) || index < 0 || index >= length(tokens))
			return null
		rebuilt += copytext(text, last, placeholder.index)
		rebuilt += tokens[index + 1]
		seen[index + 1] = TRUE
		last = placeholder.next
	for(var/i in 1 to length(tokens))
		if(!seen[i])
			return null
	return rebuilt + copytext(text, last)

/// One unit of work. Created by SSautotranslate, handed to the provider.
/datum/translation_request
	/// Cache key this request was filed under.
	var/key
	/// Text as spoken, already html_encode()'d by the say pipeline.
	var/source_text
	var/source_language
	var/target_language
	/// Filled in by the provider on success.
	var/result
	/// Set by the provider (or the subsystem, on timeout) on failure.
	var/errored = FALSE
	var/error_reason
	/// world.time the request was dispatched.
	var/started_at = 0
	/// Callbacks waiting on this exact text. Invoked with (result, success).
	var/list/datum/callback/subscribers
	/// Free-form scratch space for the provider (an http_request, a job id...).
	var/provider_state
	/// Fragments held back from the translator, in placeholder order. See translation_protect().
	var/list/protected_tokens = list()

/datum/translation_request/New(key, source_text, source_language, target_language)
	. = ..()
	src.key = key
	src.source_text = source_text
	src.source_language = source_language
	src.target_language = target_language
	src.subscribers = list()

/datum/translation_request/Destroy(force)
	subscribers = null
	provider_state = null
	return ..()

/// Marks the request finished. Providers call one of these two from poll().
/datum/translation_request/proc/succeed(translated_text)
	result = translated_text
	errored = FALSE

/datum/translation_request/proc/fail(reason)
	errored = TRUE
	error_reason = reason


/**
 * Abstract provider. Subclass this to add a backend.
 */
/datum/translation_provider
	/// Shown in the subsystem stat entry and admin output.
	var/name = "Abstract"

/// Whether this provider is configured and usable right now.
/datum/translation_provider/proc/is_available()
	return FALSE

/// Whether this provider can handle a given direction.
/datum/translation_provider/proc/supports(source_language, target_language)
	return FALSE

/// Kick off the work. Must not block.
/datum/translation_provider/proc/begin(datum/translation_request/request)
	CRASH("begin() not implemented on [type]")

/// Called every subsystem tick for every in-flight request.
/// Return TRUE once the request is resolved, having called succeed() or fail().
/datum/translation_provider/proc/poll(datum/translation_request/request)
	CRASH("poll() not implemented on [type]")

/// Called when the subsystem gives up on a request, so the provider can clean
/// up whatever begin() allocated.
/datum/translation_provider/proc/abort(datum/translation_request/request)
	return


/**
 * The default. Does nothing, reports unavailable. With this installed the
 * whole feature is inert: messages display normally and no pending indicator
 * is ever shown.
 */
/datum/translation_provider/none
	name = "None"

/datum/translation_provider/none/is_available()
	return FALSE

/datum/translation_provider/none/supports(source_language, target_language)
	return FALSE


/**
 * Fake backend for working on the presentation layer without a model.
 *
 * Resolves after a configurable delay with a deterministic mangling of the
 * input, which is enough to exercise the pending indicator, the morph, and
 * the length-change handling. Never ship with this selected.
 */
/datum/translation_provider/debug
	name = "Debug (fake)"
	/// How long to pretend the backend took.
	var/latency = 0.4 SECONDS
	/// If set, every request resolves to exactly this string.
	var/forced_result
	/// Percentage of requests that fail, for exercising the failure path.
	var/failure_chance = 0

/datum/translation_provider/debug/is_available()
	return TRUE

/datum/translation_provider/debug/supports(source_language, target_language)
	return TRUE

/datum/translation_provider/debug/begin(datum/translation_request/request)
	// "Scheduling" is just remembering when we are allowed to answer.
	request.provider_state = world.time + latency

/datum/translation_provider/debug/poll(datum/translation_request/request)
	if(world.time < request.provider_state)
		return FALSE
	if(failure_chance && prob(failure_chance))
		request.fail("debug provider synthetic failure")
		return TRUE
	request.succeed(forced_result || autotranslate_fake_translation(request.source_text))
	return TRUE

/**
 * Produces something visibly different from the input, with a different
 * length, so the morph has something to chew on.
 *
 * Global rather than a provider method because the presentation test verb
 * needs it too, and that verb deliberately does not go near a provider.
 */
/proc/autotranslate_fake_translation(text)
	var/list/words = splittext(text, " ")
	var/list/out = list()
	for(var/word in words)
		if(!length(word))
			continue
		// Reverse each word. Uses the char list so multi-byte input survives.
		var/list/units = translation_charlist(word)
		var/list/reversed = list()
		for(var/i in length(units) to 1 step -1)
			reversed += units[i]
		out += jointext(reversed, "")
	return jointext(out, " ")
