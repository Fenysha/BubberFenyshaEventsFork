/datum/injury/fracture
	name = "Fracture"
	undiagnosed_name = "broken bone"
	desc = "A bone has been fractured."
	examine_desc = "has a broken bone"
	series = "fracture"
	upgrade_path = /datum/injury/fracture/compound
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_SPLINT | INJURY_FLAG_SELF_HEALING

	pain_amount = 22
	interaction_penalty = 1.6
	limp_slowdown = 3
	limp_chance = 60

	// Bone knits slowly on its own (~11 minutes); splinting and bone setting speed it up.
	base_healing_rate = 0.0015
	base_treat_time = 6 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/bone_gel = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_BONESET)
	var/leg_step_pain = 10

	COOLDOWN_DECLARE(drop_cd)
	COOLDOWN_DECLARE(step_pain_cd)

/datum/injury/fracture/resolve_treatment_quality(obj/item/tool, mob/user)
	if(tool.tool_behaviour == TOOL_BONESET || istype(tool, /obj/item/stack/medical/medicine/bone_gel))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_POOR

/datum/injury/fracture/occur_text()
	return "cracks audibly"

/datum/injury/fracture/register_effects()
	reacts_to_movement = is_leg()
	return ..()

/datum/injury/fracture/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 70)
	if(prob(50))
		owner.emote("scream")

/datum/injury/fracture/process_effects(seconds_per_tick)
	// A broken arm cannot hold things reliably.
	if(is_arm() && treatment_quality < INJURY_TREATMENT_ADEQUATE && COOLDOWN_FINISHED(src, drop_cd) && SPT_PROB(3, seconds_per_tick))
		drop_limb_item("gives out with a grinding crunch")
		COOLDOWN_START(src, drop_cd, 4 SECONDS)

/datum/injury/fracture/on_owner_moved(movement_dir)
	if(!owner || owner.stat == DEAD || owner.body_position == LYING_DOWN || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(!COOLDOWN_FINISHED(src, step_pain_cd))
		return
	if(!prob(limp_chance * 0.35))
		return
	pain_spike(leg_step_pain, "Your broken [limb.plaintext_zone] screams with pain as you put weight on it!", "[owner] winces and limps on a broken [limb.plaintext_zone].", "groan")
	COOLDOWN_START(src, step_pain_cd, 2 SECONDS)
	if(prob(6))
		owner.visible_message(span_danger("[owner] stumbles on [owner.p_their()] broken [limb.plaintext_zone]!"))
		owner.Knockdown(1.5 SECONDS)

/datum/injury/fracture/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("[owner.p_Their()] [limb.plaintext_zone] is swollen and bent the wrong way.")


/datum/injury/fracture/compound
	name = "Compound Fracture"
	undiagnosed_name = "bone sticking out"
	desc = "A compound fracture. Bone has pierced through the skin."
	examine_desc = "has a bone protruding through the skin"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	// Open fracture: no self-healing, and the wound has to be closed as well.
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_INTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE | INJURY_FLAG_ACCEPTS_SPLINT

	bleed_rate = 0.40
	pain_amount = 35
	dismemberment_weight = 3.5
	disabling = TRUE
	processes = TRUE
	leg_step_pain = 30

	base_healing_rate = 0.002
	base_treat_time = 9 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
	)

/datum/injury/fracture/compound/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_POOR

/datum/injury/fracture/compound/occur_text()
	return "splits open as bone tears through the skin"

/datum/injury/fracture/compound/on_applied_effects(attack_direction)
	..()
	hit_spray(attack_direction, 1, 2)
	owner.ce_gib_splatter()
	play_effect_sound(INJURY_SOUND_BLOOD, 55, 1 SECONDS)

/datum/injury/fracture/compound/on_owner_moved(movement_dir)
	..()
	if(owner && treatment_quality < INJURY_TREATMENT_ADEQUATE && COOLDOWN_FINISHED(src, step_pain_cd) && prob(25) && isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)
		COOLDOWN_START(src, step_pain_cd, 1.5 SECONDS)

/datum/injury/fracture/compound/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_userdanger("Bone is sticking out of [owner.p_their()] [limb.plaintext_zone], slick with blood!")
