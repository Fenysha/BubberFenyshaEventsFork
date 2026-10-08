/datum/action/cooldown/rw_xenogene
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	button_icon = 'icons/effects/magic.dmi'
	button_icon_state = "fireball"

/datum/action/cooldown/rw_xenogene/proc/carbon_owner()
	if(!iscarbon(owner))
		return null
	return owner

/datum/action/cooldown/rw_xenogene/proc/require_hemogen(amount)
	var/mob/living/carbon/pawn = carbon_owner()
	if(!pawn)
		return FALSE
	if(!pawn.dna?.has_rw_xenogene(RW_XENOGENE_HEMOGENIC))
		to_chat(pawn, span_warning("You have no hemogen reserve."))
		return FALSE
	if(!pawn.rw_spend_hemogen(amount))
		to_chat(pawn, span_warning("Not enough hemogen."))
		return FALSE
	return TRUE


/datum/action/cooldown/rw_xenogene/fire_spew
	name = "Fire Spew"
	desc = "Spew a line of flammable bile."
	cooldown_time = 12 SECONDS
	button_icon_state = "fireball"

/datum/action/cooldown/rw_xenogene/fire_spew/Activate(atom/target)
	var/turf/end = get_ranged_target_turf(owner, owner.dir, 4)
	owner.visible_message(span_danger("[owner] spews a stream of burning bile!"), span_warning("You spew burning bile."))
	for(var/turf/step in get_line(owner, end))
		if(step == get_turf(owner))
			continue
		step.hotspot_expose(700, 50)
		new /obj/effect/hotspot(step, 50, 700)
		for(var/mob/living/hit in step)
			if(hit == owner)
				continue
			hit.adjust_fire_stacks(2)
			hit.ignite_mob()
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/foam_spray
	name = "Foam Spray"
	desc = "Extinguish fires in a short radius."
	cooldown_time = 8 SECONDS

/datum/action/cooldown/rw_xenogene/foam_spray/Activate(atom/target)
	owner.visible_message(span_notice("[owner] sprays a burst of fire-retardant foam."), span_notice("You spray fire-retardant foam."))
	for(var/turf/step in range(2, owner))
		step.extinguish()
		for(var/mob/living/hit in step)
			hit.extinguish_mob()
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/animal_warcall
	name = "Animal Warcall"
	desc = "Click a target. Nearby hostile animals attack it."
	cooldown_time = 20 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/animal_warcall/Activate(atom/target)
	var/mob/living/victim = target
	if(!isliving(target))
		victim = locate(/mob/living) in get_turf(target)
	if(!isliving(victim) || victim == owner)
		return FALSE
	var/called = 0
	for(var/mob/living/simple_animal/hostile/animal in oview(7, owner))
		if(animal.stat == DEAD)
			continue
		animal.GiveTarget(victim)
		called++
	if(!called)
		to_chat(owner, span_warning("Nothing answers the call."))
		return FALSE
	owner.visible_message(span_danger("[owner] lets out a warcall!"), span_notice("Nearby animals turn on [victim]."))
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/acid_spray
	name = "Acid Spray"
	desc = "Click a target to douse it in acid."
	cooldown_time = 12 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/acid_spray/Activate(atom/target)
	if(get_dist(owner, target) > 5)
		return FALSE
	owner.visible_message(span_danger("[owner] sprays acid at [target]!"), span_warning("You spray acid."))
	target.acid_act(40, 15)
	if(isliving(target))
		var/mob/living/victim = target
		victim.adjust_fire_loss(10)
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/gene_implanter
	name = "Gene Implanter"
	desc = "Click an adjacent person to copy one of your acquired xenogenes into them."
	cooldown_time = 2 MINUTES
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/gene_implanter/Activate(atom/target)
	if(!ishuman(owner) || !ishuman(target))
		return FALSE
	if(get_dist(owner, target) > 1)
		to_chat(owner, span_warning("You need to be adjacent."))
		return FALSE
	var/mob/living/carbon/human/donor = owner
	var/mob/living/carbon/human/recipient = target
	if(!donor.dna || !recipient.dna)
		return FALSE
	var/list/candidates = list()
	for(var/gene_id in donor.dna.rw_xenogenes)
		var/datum/rw_xenogene/gene = donor.dna.rw_xenogenes[gene_id]
		if(!gene || gene.is_innate())
			continue
		if(recipient.dna.has_rw_xenogene(gene_id))
			continue
		candidates += gene_id
	if(!length(candidates))
		to_chat(owner, span_warning("[recipient] already has every xenogene you can copy."))
		return FALSE
	var/picked = pick(candidates)
	var/datum/rw_xenogene/source_gene = donor.dna.get_rw_xenogene(picked)
	if(!recipient.dna.add_rw_xenogene(picked, source_gene?.option_value, TRUE, RW_XENOGEN_SOURCE_ACQUIRED))
		to_chat(owner, span_warning("The implant fails. Those genes cannot coexist."))
		return FALSE
	owner.visible_message(span_notice("[owner] presses a hand to [recipient]. Something under the skin shifts."), span_notice("You implant [source_gene?.name || picked] into [recipient]."))
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/bloodfeed
	name = "Bloodfeed"
	desc = "Click an adjacent person and drink hemogen from their blood."
	cooldown_time = 8 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/bloodfeed/Activate(atom/target)
	var/mob/living/carbon/pawn = carbon_owner()
	if(!pawn?.dna?.has_rw_xenogene(RW_XENOGENE_HEMOGENIC))
		to_chat(owner, span_warning("You have no hemogen reserve."))
		return FALSE
	if(!iscarbon(target) || target == owner || get_dist(owner, target) > 1)
		return FALSE
	var/mob/living/carbon/victim = target
	victim.apply_damage(18, BRUTE, BODY_ZONE_HEAD, sharpness = SHARP_POINTY)
	victim.blood_volume = max(0, victim.blood_volume - 30)
	pawn.rw_hemogen = min(1, pawn.rw_hemogen + 0.22)
	owner.visible_message(span_danger("[owner] bites [victim] and drinks."), span_notice("You drink hemogen from [victim]."))
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/coagulate
	name = "Coagulate"
	desc = "Spend hemogen to stop your bleeding, or an adjacent person's."
	cooldown_time = 10 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/coagulate/Activate(atom/target)
	var/mob/living/patient = owner
	if(iscarbon(target) && target != owner)
		if(get_dist(owner, target) > 1)
			return FALSE
		patient = target
	if(!iscarbon(patient))
		return FALSE
	if(!require_hemogen(0.2))
		return FALSE
	var/mob/living/carbon/carbon_patient = patient
	for(var/datum/injury/injury as anything in carbon_patient.all_injuries)
		injury.bleed_rate = 0
	var/whose = (patient == owner) ? "their own" : "[patient]'s"
	owner.visible_message(span_notice("[owner] seals [whose] wounds."), span_notice("The bleeding stops."))
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/deathrest
	name = "Deathrest"
	desc = "Collapse into a healing torpor. Clears the need to deathrest."
	cooldown_time = 3 MINUTES

/datum/action/cooldown/rw_xenogene/deathrest/Activate(atom/target)
	var/mob/living/carbon/pawn = carbon_owner()
	if(!pawn)
		return FALSE
	var/datum/rw_xenogene/gene = pawn.dna?.get_rw_xenogene(RW_XENOGENE_DEATHREST)
	if(gene)
		gene.last_deathrest = world.time
	pawn.Immobilize(25 SECONDS)
	pawn.adjust_brute_loss(-20)
	pawn.adjust_fire_loss(-20)
	pawn.visible_message(span_notice("[pawn] goes limp in a deathrest."), span_notice("You sink into deathrest. The need quiets, and your body knits."))
	var/datum/psychology/psy = pawn.get_psychology()
	psy?.add_factor("xenogene_deathrest_bonus", "deathrest", 6, "Rested in deathrest.", timeout = world.time + 8 MINUTES)
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/longjump
	name = "Longjump"
	desc = "Spend hemogen to leap forward."
	cooldown_time = 8 SECONDS

/datum/action/cooldown/rw_xenogene/longjump/Activate(atom/target)
	if(!require_hemogen(0.15))
		return FALSE
	var/turf/dest = get_ranged_target_turf(owner, owner.dir, 6)
	owner.visible_message(span_warning("[owner] leaps!"), span_notice("You leap."))
	owner.throw_at(dest, 6, 2, owner)
	StartCooldown()
	return TRUE


/datum/action/cooldown/rw_xenogene/piercing_spine
	name = "Piercing Spine"
	desc = "Click a target. Spend hemogen to fire a spine into them."
	cooldown_time = 6 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/rw_xenogene/piercing_spine/Activate(atom/target)
	if(!isliving(target) || target == owner || get_dist(owner, target) > 6)
		return FALSE
	if(!require_hemogen(0.18))
		return FALSE
	var/mob/living/victim = target
	owner.visible_message(span_danger("[owner] fires a spine into [victim]!"), span_warning("You fire a spine."))
	victim.apply_damage(30, BRUTE, BODY_ZONE_CHEST, sharpness = SHARP_POINTY)
	StartCooldown()
	return TRUE
