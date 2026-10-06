/obj/item/rw_attachment/under
	icon = RW_ICON_ATT_UNDER
	slot = RW_ATT_SLOT_UNDER

/obj/item/rw_attachment/under/vertical_grip
	name = "vertical grip"
	desc = "An improved foregrip: less recoil build-up, tighter grouping and better control on the move. Makes the weapon bulkier and slower to grip."
	icon_state = "verticalgrip"
	pixel_shift_x = 20
	recoil_spread_mod = -0.25
	spread_mod = -0.3 DEGREES
	moving_spread_mod = -0.15
	camera_recoil_mod = -1
	wield_time_mod = 0.2
	size_mod = 1

/obj/item/rw_attachment/under/angled_grip
	name = "angled grip"
	desc = "A foregrip that lets you bring the weapon up much faster, with a little less recoil. Makes the weapon bulkier."
	icon_state = "angledgrip"
	pixel_shift_x = 20
	wield_time_mod = -0.25
	recoil_spread_mod = -0.1
	camera_recoil_mod = -0.5
	size_mod = 1

/obj/item/rw_attachment/under/gyro
	name = "gyroscopic stabilizer"
	desc = "Weights and balances that steady the weapon while the shooter moves and during sustained fire. Needs some training to use properly."
	icon_state = "gyro"
	req_skill = 4
	moving_spread_mod = -0.5
	recoil_spread_mod = -0.2
	camera_recoil_mod = -1

/obj/item/rw_attachment/under/lasersight
	name = "laser sight"
	desc = "A laser sight under the barrel. Helps with placing the shot: better chance to hit exactly the limb you aim at."
	icon_state = "lasersight"
	pixel_shift_x = 17
	pixel_shift_y = 17
	miss_mod = -0.05
	zone_accuracy_mod = 8

/obj/item/rw_attachment/under/burstfire_assembly
	name = "burst fire assembly"
	desc = "A mechanism re-assembly kit that adds two rounds to every burst. Increases recoil build-up and costs accuracy."
	icon_state = "rapidfire"
	burst_size_mod = 2
	recoil_spread_mod = 0.25
	miss_mod = 0.03
