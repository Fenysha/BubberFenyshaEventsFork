/datum/rw_crafting_recipe
	var/id
	var/name = "Unnamed Recipe"
	var/desc = ""

	var/category = "General"

	var/result_path
	var/result_amount = 1

	var/list/requirements = list()

	var/crafting_time = 3 SECONDS

	var/required_bench

	var/required_skill
	var/skill_level = 0
