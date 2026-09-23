/datum/rw_loadout_item
	abstract_type = /datum/rw_loadout_item
	var/id
	var/name = "Item"
	var/desc = "A starting item stub."
	var/cost = 0
	var/obj/item/item_path

/datum/rw_loadout_item/proc/equip_to(mob/living/carbon/human/target)
	if(!item_path || !target)
		return
	var/obj/item/item = new item_path(target)
	if(!target.equip_to_appropriate_slot(item, qdel_on_fail = FALSE))
		target.put_in_hands(item)

/datum/rw_loadout_item/flak_jacket
	id = "flak_jacket"
	name = "Flak Jacket"
	desc = "Stub starting armor."
	cost = 150
	item_path = /obj/item/clothing/suit/armor/vest
