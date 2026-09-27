SUBSYSTEM_DEF(flora)
	name = "\[RW\] Flora"
	wait = 1 MINUTES


	var/list/registered_flora = list()


/datum/controller/subsystem/flora/Initialize()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/flora/fire(resumed)
	for(var/i = length(registered_flora), i >= 1, i--)
		var/obj/structure/rimworld/flora/flora = registered_flora[i]

		if(QDELETED(flora))
			registered_flora.Cut(i, i + 1)
			continue

		flora.process_flora()


/datum/controller/subsystem/flora/proc/register_flora(
	obj/structure/rimworld/flora/flora
)
	if(!flora)
		return

	if(flora in registered_flora)
		return

	registered_flora += flora


/datum/controller/subsystem/flora/proc/unregister_flora(
	obj/structure/rimworld/flora/flora
)
	if(!flora)
		return

	registered_flora -= flora
