/// Loads our fork of the say popup (tgui/packages/tartarus-say) instead of the upstream bundle.
/datum/tgui_say/initialize()
	set waitfor = FALSE
	// Deferred past the client constructor, as the parent does
	sleep(3 SECONDS)
	window.initialize(
		strict_mode = TRUE,
		inline_css = file("tgui/public/tartarus-say.bundle.css"),
		inline_js = file("tgui/public/tartarus-say.bundle.js"),
	)
