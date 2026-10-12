/obj/item/organ
	var/density_sharp = 0.15
	var/density_blunt = 0.5
	/// World time of the last critical-organ lethal-hit protection.
	var/last_lethal_guard_time = -INFINITY

/**
 * Applies resolved damage from an external attack to an internal organ.
 * External hits transfer less damage than direct damage systems such as
 * hypoxia. Brain and heart get a separate anti-one-shot safety window.
 */
/obj/item/organ/proc/apply_external_combat_damage(amount, list/packet, damage_source)
	if(amount <= 0)
		return 0

	var/applied_damage = amount * ORGAN_EXTERNAL_DAMAGE_MULT
	var/is_critical_organ = istype(src, /obj/item/organ/brain) || istype(src, /obj/item/organ/heart)
	var/guard_ready = world.time >= last_lethal_guard_time + ORGAN_LETHAL_GUARD_COOLDOWN
	var/critical_threshold = maxHealth

	// Heart failure is triggered at its high threshold, before the organ is fully destroyed.
	if(istype(src, /obj/item/organ/heart))
		var/obj/item/organ/heart/heart = src
		critical_threshold = min(maxHealth, heart.high_threshold)

	if(is_critical_organ && critical_threshold > 0 && damage < critical_threshold && damage + applied_damage >= critical_threshold && guard_ready)
		// The guard reduces the hit, then caps it just below the organ's critical threshold.
		// This second check is necessary when even 80% of the attack would trigger fatal failure.
		applied_damage *= ORGAN_LETHAL_GUARD_DAMAGE_MULT
		applied_damage = min(applied_damage, max(critical_threshold - damage - 1, 0))
		last_lethal_guard_time = world.time
		if(owner)
			playsound(owner, ORGAN_LETHAL_GUARD_SOUND, 70, TRUE)
			owner.visible_message(
				span_danger("[owner] jolts as a catastrophic [name] injury is narrowly prevented!"),
				span_userdanger("A sharp impact is interrupted before it can fatally destroy your [name]!")
			)

	if(applied_damage <= 0)
		return 0

	apply_organ_damage(applied_damage)
	on_external_damage(applied_damage, packet, damage_source)
	return applied_damage

/obj/item/organ/proc/on_external_damage(amount, list/packet, damage_source)
	return

