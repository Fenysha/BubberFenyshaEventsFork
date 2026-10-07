#ifndef OLD_COMBAT_SYSTEM
/**
 * Projectile damage application.
 */
/mob/living/proc/apply_projectile_effects(obj/projectile/proj, def_zone, armor_check)
	if(proj.is_hostile_projectile() && try_dodge(proj.firer, "\the [proj]", PROJECTILE_ATTACK))
		return

	var/damage_dealt = apply_damage(
		damage = proj.damage,
		damagetype = proj.damage_type,
		def_zone = def_zone,
		blocked = 0,
		wound_bonus = proj.wound_bonus,
		exposed_wound_bonus = proj.exposed_wound_bonus,
		sharpness = proj.sharpness,
		attack_direction = get_dir(proj.starting, src),
		attacking_item = proj,
	)

	if(damage_dealt > 0)
		apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	apply_effects(
		stun = proj.stun,
		knockdown = proj.knockdown,
		unconscious = proj.unconscious,
		slur = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.slur,
		stutter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.stutter,
		eyeblur = proj.eyeblur,
		drowsy = proj.drowsy,
		blocked = 0,
		stamina = proj.stamina,
		jitter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.jitter,
		paralyze = proj.paralyze,
		immobilize = proj.immobilize,
	)

	if(proj.dismemberment)
		check_projectile_dismemberment(proj, def_zone)

	if(proj.damage && armor_check < 100)
		create_projectile_hit_effects(proj, def_zone, armor_check)

	if(proj.fired_from)
		SEND_SIGNAL(proj.fired_from, COMSIG_PROJECTILE_POST_HIT_LIVING, src, def_zone, armor_check)
	SEND_SIGNAL(proj, COMSIG_PROJECTILE_SELF_POST_HIT_LIVING, src, def_zone, armor_check)
	return damage_dealt
#endif
