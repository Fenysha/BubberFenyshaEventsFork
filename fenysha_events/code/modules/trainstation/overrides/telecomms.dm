/**
 * The train only carries the "A" half of a standard telecomms stack - there is no
 * receiver B. Stock preset_left listens to five department channels and nothing
 * else, so common, command, engineering and security never reached the hub. The
 * train's receiver listens on every frequency instead; the buses still sort
 * traffic onto the right servers from there.
 */
/obj/machinery/telecomms/receiver/preset_left/trainstation
	freq_listening = list()
