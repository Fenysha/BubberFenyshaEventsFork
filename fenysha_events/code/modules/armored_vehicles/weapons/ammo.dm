/// Ammunition for vehicle weapons: a shell, belt or cell holding rounds of a projectile type
/obj/item/tank_ammo
	name = "tank ammunition"
	desc = "Ammunition for a vehicle mounted weapon."
	icon = 'fenysha_events/icons/vehicles/armored/ammo.dmi'
	icon_state = "ltb"
	w_class = WEIGHT_CLASS_HUGE
	throwforce = 10
	var/projectile_type = /obj/projectile/bullet/armored
	var/max_rounds = 1
	var/current_rounds
	/// Played when loaded into a breech or the vehicle
	var/loading_sound = 'fenysha_events/sounds/vehicles/armored/weapons/ltb_reload.ogg'
	/// Shouted by the loader, as in "HE, Up!"
	var/callout_name
	/// Pellets fired per round, for canister shot
	var/projectiles_per_round = 1
	var/pellet_spread = 0

/obj/item/tank_ammo/Initialize(mapload)
	. = ..()
	if(isnull(current_rounds))
		current_rounds = max_rounds
	update_appearance(UPDATE_ICON_STATE)

/obj/item/tank_ammo/update_icon_state()
	. = ..()
	icon_state = current_rounds > 0 ? initial(icon_state) : "[initial(icon_state)]_e"

/obj/item/tank_ammo/examine(mob/user)
	. = ..()
	if(max_rounds > 1)
		. += span_notice("It has [current_rounds]/[max_rounds] rounds left.")
	else if(current_rounds <= 0)
		. += span_notice("It's spent.")

/obj/item/tank_ammo/ltb
	name = "LTB HE shell (105mm)"
	desc = "A 105mm high explosive shell filled with a deadly explosive payload."
	icon_state = "ltb"
	w_class = WEIGHT_CLASS_GIGANTIC
	projectile_type = /obj/projectile/bullet/armored/explosive/ltb
	callout_name = "HE"

/obj/item/tank_ammo/ltb/heavy
	name = "LTB HE+ shell (105mm)"
	desc = "A 105mm high explosive shell filled with an incredibly explosive payload."
	projectile_type = /obj/projectile/bullet/armored/explosive/ltb/heavy

/obj/item/tank_ammo/ltb/apfds
	name = "LTB APFDS round (105mm)"
	desc = "A 105mm armor piercing shell with exceptional velocity and penetrating characteristics. Will pierce through walls and targets."
	icon_state = "ltb_apfds"
	projectile_type = /obj/projectile/bullet/armored/apfds
	callout_name = "Sabot"

/obj/item/tank_ammo/ltb/canister
	name = "LTB canister round (105mm)"
	desc = "A 105mm canister shell for demolishing soft targets. The payload of hundreds of small metal balls imitates a shotgun blast."
	icon_state = "ltb_canister"
	projectile_type = /obj/projectile/bullet/armored/canister
	projectiles_per_round = 12
	pellet_spread = 25
	callout_name = "Canister"

/obj/item/tank_ammo/ltb/canister/incendiary
	name = "LTB incendiary canister round (105mm)"
	desc = "A 105mm canister shell for demolishing soft targets. The payload of incendiary shrapnel imitates a shotgun blast."
	icon_state = "ltb_canister_incend"
	projectile_type = /obj/projectile/bullet/armored/canister/incendiary
	callout_name = "Incendiary"

/obj/item/tank_ammo/ltaap
	name = "\improper LTA-AP chaingun magazine"
	desc = "A primary armament chaingun magazine."
	icon_state = "ltaap"
	w_class = WEIGHT_CLASS_GIGANTIC
	max_rounds = 150
	projectile_type = /obj/projectile/bullet/armored/ltaap
	loading_sound = 'sound/items/weapons/gun/general/bolt_rack.ogg'

/obj/item/tank_ammo/ltaap/hv
	name = "\improper LTA-AP HV chaingun magazine"
	desc = "A primary armament chaingun magazine loaded with high velocity rounds."
	icon_state = "ltaap_hv"
	max_rounds = 200
	projectile_type = /obj/projectile/bullet/armored/ltaap/hv

/obj/item/tank_ammo/autocannon
	name = "Bushwhacker autocannon APDS box (30mm)"
	desc = "A box of armor piercing rounds for a vehicle autocannon."
	icon_state = "tank_autocannon_ap"
	max_rounds = 50
	projectile_type = /obj/projectile/bullet/armored/autocannon
	loading_sound = 'fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_reload.ogg'
	callout_name = "Sabot"

/obj/item/tank_ammo/autocannon/high_explosive
	name = "Bushwhacker autocannon high explosive box (30mm)"
	desc = "A box of high explosive rounds for a vehicle autocannon."
	icon_state = "tank_autocannon_he"
	projectile_type = /obj/projectile/bullet/armored/autocannon/high_explosive
	callout_name = "HE"

/obj/item/tank_ammo/cupola
	name = "HSG-102 cupola magazine"
	desc = "A secondary armament machine gun magazine."
	icon_state = "cupola"
	w_class = WEIGHT_CLASS_GIGANTIC
	max_rounds = 75
	projectile_type = /obj/projectile/bullet/armored/cupola
	loading_sound = 'sound/items/weapons/gun/general/bolt_rack.ogg'

/obj/item/tank_ammo/secondary_flamer
	name = "napalm stream tank"
	desc = "Fuel for a secondary vehicle mounted flamer."
	icon_state = "sflamer"
	max_rounds = 150
	projectile_type = /obj/projectile/bullet/incendiary/fire/armored
	loading_sound = 'sound/items/weapons/gun/general/bolt_rack.ogg'

/obj/item/tank_ammo/tow_missile
	name = "\improper TOW-III missile"
	desc = "A homing missile for the TOW launcher."
	icon_state = "seekerammo"
	w_class = WEIGHT_CLASS_GIGANTIC
	projectile_type = /obj/projectile/bullet/armored/explosive/rocket/tow
	loading_sound = 'fenysha_events/sounds/vehicles/armored/fire/launcher_reload.ogg'

/obj/item/tank_ammo/microrocket_rack
	name = "microrocket pod rack"
	desc = "A 3x2 rack of high explosive homing microrockets."
	icon_state = "secondary_rocketpod"
	w_class = WEIGHT_CLASS_GIGANTIC
	max_rounds = 6
	projectile_type = /obj/projectile/bullet/armored/explosive/rocket/microrocket
	loading_sound = 'fenysha_events/sounds/vehicles/armored/fire/launcher_reload.ogg'

/obj/item/tank_ammo/bfg
	name = "\improper BFG antimatter container"
	desc = "Holds antimatter for a BFG glob. Do not open."
	icon_state = "bfg"
	w_class = WEIGHT_CLASS_GIGANTIC
	projectile_type = /obj/projectile/bullet/armored/bfg

/obj/item/tank_ammo/volkite_carronade
	name = "volkite carronade cell"
	desc = "A heavy, disposable cell for powering a volkite carronade."
	icon_state = "som_tank_cell"
	w_class = WEIGHT_CLASS_GIGANTIC
	max_rounds = 3
	projectile_type = null

/obj/item/tank_ammo/particle_lance
	name = "particle lance energy cell"
	desc = "A heavy, disposable cell for powering a tank mounted particle lance."
	icon_state = "particle_lance_cell"
	w_class = WEIGHT_CLASS_GIGANTIC
	projectile_type = /obj/projectile/beam/armored/particle_lance

/obj/item/tank_ammo/coilgun
	name = "coilgun projectile"
	desc = "An extremely dense kinetic penetrator round for a tank mounted coilgun."
	icon_state = "coilgun"
	w_class = WEIGHT_CLASS_NORMAL
	projectile_type = /obj/projectile/bullet/armored/explosive/coilgun
	loading_sound = 'fenysha_events/sounds/vehicles/armored/weapons/coilgun_cycle.ogg'

/obj/item/tank_ammo/coilgun/update_icon_state()
	. = ..()
	icon_state = initial(icon_state)

/obj/item/tank_ammo/secondary_mlrs
	name = "\improper MLRS magazine"
	desc = "A secondary armament rocket magazine loaded with homing HE rockets."
	icon_state = "secondary_mlrs"
	w_class = WEIGHT_CLASS_GIGANTIC
	max_rounds = 12
	projectile_type = /obj/projectile/bullet/armored/explosive/rocket/homing
	loading_sound = 'fenysha_events/sounds/vehicles/armored/fire/launcher_reload.ogg'

/obj/item/tank_ammo/sarden_clip
	name = "EM-2600 'SARDEN' APDS clip (30mm)"
	desc = "A 7 round clip for an EM-2600 autocannon, loaded with armor piercing rounds."
	icon_state = "sarden_clip_apds"
	max_rounds = 7
	projectile_type = /obj/projectile/bullet/armored/sarden
	loading_sound = 'fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_reload.ogg'

/obj/item/tank_ammo/sarden_clip/high_explosive
	name = "EM-2600 'SARDEN' high explosive clip (30mm)"
	desc = "A 7 round clip for an EM-2600 autocannon, loaded with high explosive rounds."
	icon_state = "sarden_clip_he"
	projectile_type = /obj/projectile/bullet/armored/sarden/high_explosive

/obj/item/tank_ammo/icc_lowvel_cannon
	name = "EM-2500 HEAT shell (76mm)"
	desc = "A 76mm HEAT shell for targeting hard targets."
	icon_state = "icc_lvrt_cannon_heat"
	w_class = WEIGHT_CLASS_BULKY
	projectile_type = /obj/projectile/bullet/armored/explosive/lowvel_heat
	callout_name = "HEAT"

/obj/item/tank_ammo/icc_lowvel_cannon/high_explosive
	name = "EM-2500 HE shell (76mm)"
	desc = "A 76mm HE shell for targeting large groups of soft targets."
	icon_state = "icc_lvrt_cannon_he"
	projectile_type = /obj/projectile/bullet/armored/explosive/lowvel_he
	callout_name = "HE"

/obj/item/tank_ammo/icc_coax
	name = "EM-94 coaxial belt (10x26mm)"
	desc = "A belt of machine gun ammunition for a vehicle coaxial gun."
	icon_state = "cupola"
	max_rounds = 120
	projectile_type = /obj/projectile/bullet/armored/coax
	loading_sound = 'sound/items/weapons/gun/general/bolt_rack.ogg'
