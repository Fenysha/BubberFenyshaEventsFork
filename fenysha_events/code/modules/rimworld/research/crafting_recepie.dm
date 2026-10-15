/datum/rw_crafting_recipe
	var/id
	var/name = "Unnamed Recipe"
	var/desc = ""

	/// Display category shown in the crafting UI and used for workbench filtering.
	var/category = "General"

	var/result_path
	var/result_amount = 1

	/// Item typepath => quantity consumed per craft.
	var/list/requirements = list()

	var/crafting_time = 3 SECONDS

	/// Optional workbench type restriction. If unset, the bench's category/ID filter applies.
	var/required_bench

	var/required_skill
	var/skill_level = 0


/// Returns a PNG base64 string for an item's icon, cached by typepath for TGUI use.
/proc/rw_get_recipe_item_icon_src(item_path)
	if(!ispath(item_path, /obj/item))
		return null

	var/static/list/icon_cache = list()
	var/cache_key = "[item_path]"
	if(!isnull(icon_cache[cache_key]))
		return icon_cache[cache_key]

	var/obj/item/item_type = item_path
	var/icon/item_icon = icon(initial(item_type.icon), initial(item_type.icon_state), SOUTH, 1)
	if(!item_icon)
		icon_cache[cache_key] = ""
		return null

	var/icon_src = icon2base64(item_icon)
	icon_cache[cache_key] = icon_src
	return icon_src
