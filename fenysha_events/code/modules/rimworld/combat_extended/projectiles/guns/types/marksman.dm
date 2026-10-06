/obj/item/gun/rimworld/ballistic/marksman
	name = "marksman rifle"
	icon = 'fenysha_events/icons/items/gun/marksman64.dmi'
	righthand_file = 'fenysha_events/icons/items/inhand/guns/marksman_right_64.dmi'
	lefthand_file = 'fenysha_events/icons/items/inhand/guns/marksman_left_64.dmi'

	inhand_x_dimension = 64

	bolt_type = BOLT_TYPE_LOCKING
	abstract_type = /obj/item/gun/rimworld/ballistic/marksman
	rw_allowed_fire_modes = list(RW_FIRE_SINGLE)
	rw_wield_time = 2 SECONDS
	rw_base_spread = 1.5 DEGREES
	rw_cooldown = 3 SECONDS
	rw_effective_range = 26 TILES
	rw_moving_spread = 60 DEGREES
	rw_settle_time = 4 SECONDS


/obj/item/gun/rimworld/ballistic/marksman/british
	name = "Rifle"
	desc = "A rifle that has seen more than one war, \
			with its simple lever-action mechanism and reliable automatic firing mechanism, \
			remains a formidable weapon even today."

	icon_state = "garand"
	base_icon_state = "garand"

	rw_caliber = RW_CALIBER_303BRITISH
	rw_starting_attachments = list(/obj/item/rw_attachment/stock/british_rifle)
	rw_attachable_allowed = list(
		/obj/item/rw_attachment/stock/british_rifle,
		/obj/item/rw_attachment/muzzle/bayonet,
		/obj/item/rw_attachment/rail/scope,
	)

	rw_allowed_fire_modes = list(RW_FIRE_SINGLE)
	rw_wield_time = 3 SECONDS
	rw_base_spread = 1 DEGREES
	rw_cooldown = 4.5 SECONDS
	rw_effective_range = 32 TILES
	rw_moving_spread = 60 DEGREES
	rw_settle_time = 5 SECONDS

	rw_mag_display = FALSE
	rw_biocode_enabled = FALSE

/obj/item/gun/rimworld/ballistic/marksman/british/loaded
	rw_spawn_magazine_type = /obj/item/ammo_box/magazine/rimworld/british_303
