/datum/rw_loadout_item
	abstract_type = /datum/rw_loadout_item
	var/id
	var/name = "Item"
	var/desc = "A starting item."
	var/cost = 0
	var/obj/item/item_path

/datum/rw_loadout_item/proc/equip_to(mob/living/carbon/human/target)
	if(!item_path || !target)
		return
	var/obj/item/item = new item_path(target)
	if(!target.equip_to_appropriate_slot(item, qdel_on_fail = FALSE))
		target.put_in_hands(item)

/datum/rw_loadout_item/bolt_rifle
	id = "bolt_rifle"
	name = "Bolt-Action Rifle"
	desc = "A reliable long gun and a box of rounds."
	cost = 250
	item_path = /obj/item/gun/ballistic/rifle/boltaction

/datum/rw_loadout_item/autopistol
	id = "autopistol"
	name = "Autopistol"
	desc = "Sidearm for when the rifle is empty."
	cost = 120
	item_path = /obj/item/gun/ballistic/automatic/pistol

/datum/rw_loadout_item/knife
	id = "knife"
	name = "Combat Knife"
	desc = "Short blade. Useful for more than fighting."
	cost = 40
	item_path = /obj/item/knife/combat

/datum/rw_loadout_item/spear
	id = "spear"
	name = "Spear"
	desc = "A long stick with a point."
	cost = 35
	item_path = /obj/item/spear

/datum/rw_loadout_item/flak_vest
	id = "flak_vest"
	name = "Flak Vest"
	desc = "Light armor over the ribs."
	cost = 160
	item_path = /obj/item/clothing/suit/armor/vest

/datum/rw_loadout_item/helmet
	id = "simple_helmet"
	name = "Simple Helmet"
	desc = "Keeps rocks and glances off the skull."
	cost = 80
	item_path = /obj/item/clothing/head/helmet

/datum/rw_loadout_item/medkit
	id = "medkit"
	name = "Medicine"
	desc = "A kit of real medicine, not herbal."
	cost = 180
	item_path = /obj/item/storage/medkit/regular

/datum/rw_loadout_item/bruise_pack
	id = "bruise_pack"
	name = "Bruise Pack"
	desc = "Enough to stop a bleed in the field."
	cost = 50
	item_path = /obj/item/stack/medical/bruise_pack

/datum/rw_loadout_item/meals
	id = "packaged_meals"
	name = "Packaged Meals"
	desc = "Food that survives a bad week."
	cost = 50
	item_path = /obj/item/food/rationpack

/datum/rw_loadout_item/bedroll
	id = "bedroll"
	name = "Bedroll"
	desc = "Somewhere to sleep that is not the floor."
	cost = 30
	item_path = /obj/item/bedsheet

/datum/rw_loadout_item/toolbox
	id = "toolbox"
	name = "Toolbox"
	desc = "Tools for the first machines and repairs."
	cost = 100
	item_path = /obj/item/storage/toolbox/mechanical

/datum/rw_loadout_item/flashlight
	id = "flashlight"
	name = "Flashlight"
	desc = "Light when the power fails."
	cost = 25
	item_path = /obj/item/flashlight

/datum/rw_loadout_item/radio
	id = "radio"
	name = "Radio"
	desc = "A way to hear who else is out there."
	cost = 75
	item_path = /obj/item/radio

/datum/rw_loadout_item/duster
	id = "duster"
	name = "Duster"
	desc = "Coat against weather and light hits."
	cost = 90
	item_path = /obj/item/clothing/suit/jacket

/datum/rw_loadout_item/crowbar
	id = "crowbar"
	name = "Crowbar"
	desc = "Pry, smash, survive."
	cost = 20
	item_path = /obj/item/crowbar

/datum/rw_loadout_item/extinguisher
	id = "extinguisher"
	name = "Fire Extinguisher"
	desc = "For when the pyromaniac has a bad day."
	cost = 60
	item_path = /obj/item/extinguisher
