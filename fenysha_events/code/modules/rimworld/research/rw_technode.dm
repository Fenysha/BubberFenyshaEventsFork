/datum/techweb_node/rw
	category = "RimWorld"
	show_on_wiki = FALSE

	var/research_cost = 50


	var/list/workbench_types = list()
	var/list/required_attachments = list()

	var/rw_flags = NONE

	var/list/blueprint_ids = list()
	var/list/recipe_ids = list()

	var/tech_era = RW_TECH_ERA_NEOLITHIC
	var/group_id = "general"

	var/ui_depth = 0
	var/ui_x = 0
	var/ui_y = 0

/datum/techweb_node/rw/proc/get_workbench_names()
	return path_list_to_names(workbench_types)

/datum/techweb_node/rw/proc/get_attachment_names()
	return path_list_to_names(required_attachments)

/datum/techweb_node/rw/proc/path_list_to_names(list/paths)
	var/list/names = list()
	for(var/path in paths)
		var/atom/A = path
		names += initial(A.name)
	return names

/datum/techweb_node/rw/error
	id = "RW_ERROR"
	display_name = "Error Node"
	description = "Something went wrong with faction research database."
	rw_flags = RW_RESEARCH_DISABLED
