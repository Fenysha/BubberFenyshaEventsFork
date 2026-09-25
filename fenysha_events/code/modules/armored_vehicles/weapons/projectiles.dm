/obj/projectile/bullet/armored
	name = "vehicle round"
	icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi'
	icon_state = "bullet"
	damage = 30
	armour_penetration = 20
	speed = 1.5
	range = 40
	demolition_mod = 2
	shrapnel_type = null
	embed_type = null

/// Blows up wherever the round stops, at the impact point or the end of its range
/obj/projectile/bullet/armored/explosive
	var/blast_devastation = 0
	var/blast_heavy = 0
	var/blast_light = 0
	var/blast_flash = 0
	var/exploded = FALSE

/obj/projectile/bullet/armored/explosive/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(!pierce_hit)
		detonate(target)

/obj/projectile/bullet/armored/explosive/on_range()
	detonate(get_turf(src))
	return ..()

/obj/projectile/bullet/armored/explosive/proc/detonate(atom/target)
	if(exploded)
		return
	exploded = TRUE
	var/turf/blast_turf = get_turf(target)
	if(blast_turf?.density)
		blast_turf = get_step_towards(blast_turf, src) || blast_turf
	if(blast_turf)
		explosion(blast_turf, blast_devastation, blast_heavy, blast_light, flash_range = blast_flash, explosion_cause = src)

/obj/projectile/bullet/armored/explosive/ltb
	name = "cannon round"
	icon_state = "ltb"
	damage = 200
	armour_penetration = 50
	armor_flag = BOMB
	speed = 1.2
	demolition_mod = 5
	blast_heavy = 2
	blast_light = 5
	blast_flash = 3

/obj/projectile/bullet/armored/explosive/ltb/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target) && !QDELETED(target) && !HAS_TRAIT(target, TRAIT_GODMODE))
		var/mob/living/victim = target
		victim.gib(DROP_ALL_REMAINS)

/obj/projectile/bullet/armored/explosive/ltb/heavy
	blast_devastation = 1
	blast_heavy = 4
	blast_light = 6

/obj/projectile/bullet/armored/apfds
	name = "8.8cm APFDS round"
	icon_state = "apfds"
	damage = 300
	armour_penetration = 75
	speed = 2.4
	range = 30
	demolition_mod = 4
	projectile_piercing = PASSMOB|PASSSTRUCTURE|PASSMACHINE|PASSVEHICLE|PASSCLOSEDTURF|PASSGLASS|PASSGRILLE|PASSWINDOW|PASSDOORS
	max_pierces = 10

/obj/projectile/bullet/armored/apfds/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	damage *= 0.85

/obj/projectile/bullet/armored/canister
	name = "canister shot"
	icon_state = "canister_shot"
	damage = 25
	armour_penetration = 0
	range = 8
	speed = 1.2

/obj/projectile/bullet/armored/canister/incendiary
	name = "incendiary canister shot"
	damage_type = BURN

/obj/projectile/bullet/armored/canister/incendiary/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/burning = target
		burning.adjust_fire_stacks(3)
		burning.ignite_mob()

/obj/projectile/bullet/armored/ltaap
	name = "chaingun bullet"
	damage = 30
	armour_penetration = 35
	range = 25

/obj/projectile/bullet/armored/ltaap/hv
	damage = 35
	armour_penetration = 30
	speed = 2

/obj/projectile/bullet/armored/autocannon
	name = "autocannon armor piercing"
	icon_state = "autocannon"
	damage = 70
	armour_penetration = 35
	demolition_mod = 3

/obj/projectile/bullet/armored/autocannon/high_explosive
	name = "autocannon high explosive"
	damage = 10
	armour_penetration = 0
	armor_flag = BOMB
	speed = 1.8

/obj/projectile/bullet/armored/autocannon/high_explosive/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	explosion(get_turf(target), light_impact_range = 1, flash_range = 1, explosion_cause = src)

/obj/projectile/bullet/armored/cupola
	name = "cupola bullet"
	icon_state = "bullet_red"
	damage = 30
	armour_penetration = 10
	range = 20

/obj/projectile/bullet/armored/coax
	name = "coaxial bullet"
	damage = 25
	armour_penetration = 15
	range = 20

/obj/projectile/bullet/armored/sarden
	name = "heavy autocannon armor piercing"
	icon_state = "autocannon"
	damage = 40
	armour_penetration = 40
	demolition_mod = 3

/obj/projectile/bullet/armored/sarden/high_explosive
	name = "heavy autocannon high explosive"
	damage = 25
	armour_penetration = 30
	range = 21

/obj/projectile/bullet/armored/sarden/high_explosive/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	explosion(get_turf(target), light_impact_range = 2, explosion_cause = src)

/obj/projectile/bullet/armored/explosive/lowvel_heat
	name = "low velocity HEAT shell"
	icon_state = "recoilless_rifle_heat"
	damage = 180
	armour_penetration = 100
	speed = 0.6
	demolition_mod = 5
	blast_flash = 1

/obj/projectile/bullet/armored/explosive/lowvel_he
	name = "low velocity HE shell"
	icon_state = "recoilless_rifle_heat"
	damage = 50
	armour_penetration = 100
	armor_flag = BOMB
	speed = 0.6
	blast_heavy = 2
	blast_light = 3
	blast_flash = 2

/obj/projectile/bullet/armored/explosive/coilgun
	name = "kinetic penetrator"
	icon_state = "tank_coilgun"
	damage = 300
	armour_penetration = 50
	speed = 1.8
	demolition_mod = 5
	blast_heavy = 3
	blast_light = 5
	blast_flash = 2

/obj/projectile/bullet/armored/explosive/coilgun/low
	damage = 150
	armour_penetration = 40
	speed = 1.2
	blast_heavy = 2
	blast_light = 3
	blast_flash = 0

/obj/projectile/bullet/armored/explosive/coilgun/high
	damage = 450
	armour_penetration = 70
	speed = 2.4
	projectile_piercing = PASSMOB
	max_pierces = 5
	blast_heavy = 3
	blast_light = 5

/obj/projectile/bullet/armored/explosive/rocket
	name = "rocket"
	icon_state = "missile"
	damage = 0
	armor_flag = BOMB
	speed = 0.4
	range = 20
	homing_turn_speed = 5
	blast_heavy = 2
	blast_light = 3
	blast_flash = 1

/obj/projectile/bullet/armored/explosive/rocket/homing

/obj/projectile/bullet/armored/explosive/rocket/tow
	name = "TOW-III missile"
	icon_state = "rocket_he"
	damage = 60
	armour_penetration = 30
	range = 30
	homing_turn_speed = 10
	blast_heavy = 0
	blast_light = 4
	blast_flash = 2

/obj/projectile/bullet/armored/explosive/rocket/microrocket
	name = "homing microrocket"
	speed = 0.5
	damage = 10
	armour_penetration = 20
	homing_turn_speed = 10
	blast_heavy = 0
	blast_light = 2

/// Slow antimatter glob that zaps everything alive around it while it flies
/obj/projectile/bullet/armored/bfg
	name = "bfg glob"
	icon_state = "bfg_ball"
	damage = 150
	armour_penetration = 50
	damage_type = BURN
	armor_flag = ENERGY
	speed = 0.2
	range = 20
	projectile_phasing = ALL
	light_system = OVERLAY_LIGHT
	light_range = 3
	light_power = 2
	light_color = COLOR_PALE_GREEN_GRAY
	var/zap_range = 4
	var/zap_damage = 25
	var/tiles_flown = 0

/obj/projectile/bullet/armored/bfg/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	tiles_flown++
	if(tiles_flown <= 2)
		return
	var/current_range = min(zap_range, tiles_flown - 2)
	for(var/mob/living/victim in range(current_range, src))
		if(victim.stat == DEAD || victim.loc == firer)
			continue
		Beam(victim, icon_state = "lightning[rand(1, 12)]", time = 0.3 SECONDS)
		victim.apply_damage(zap_damage, BURN, spread_damage = TRUE)
	if(tiles_flown % 3 == 0)
		playsound(src, 'sound/effects/magic/lightningbolt.ogg', 30, TRUE)

/obj/projectile/bullet/armored/bfg/on_range()
	var/turf/blast_turf = get_turf(src)
	if(blast_turf)
		explosion(blast_turf, light_impact_range = 4, explosion_cause = src)
	return ..()

/obj/projectile/bullet/incendiary/fire/armored
	name = "napalm stream"
	range = 7
	damage = 25
	fire_stacks = 5

/obj/projectile/beam/armored/particle_lance
	name = "particle beam"
	icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi'
	icon_state = "particle_lance"
	damage = 850
	armour_penetration = 120
	damage_type = BURN
	armor_flag = ENERGY
	range = 40
	hitscan = TRUE
	demolition_mod = 5
	projectile_piercing = PASSMOB|PASSSTRUCTURE|PASSMACHINE|PASSVEHICLE|PASSGLASS|PASSGRILLE|PASSWINDOW|PASSDOORS
	max_pierces = 10
	tracer_type = /obj/effect/projectile/tracer/particle_lance
	muzzle_type = /obj/effect/projectile/muzzle/particle_lance
	impact_type = /obj/effect/projectile/impact/particle_lance
	light_color = LIGHT_COLOR_PURPLE

/obj/projectile/beam/armored/particle_lance/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	damage *= 0.95

/obj/effect/projectile/tracer/particle_lance
	name = "particle beam"
	icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi'
	icon_state = "beam_particle"

/obj/effect/projectile/muzzle/particle_lance
	icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi'
	icon_state = "muzzle_beam_particle"

/obj/effect/projectile/impact/particle_lance
	icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi'
	icon_state = "impact_beam_particle"
