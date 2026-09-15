/proc/is_npc(thing)
	return istype(thing, /mob/living/basic/npc)

/mob/living/basic/npc
	name = "Civilian"
	desc = ""
	icon = 'icons/mob/simple/simple_human.dmi'
	health = 150
	maxHealth = 150
	speed = 1.5
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
	basic_mob_flags = FLAMMABLE_MOB | SENDS_DEATH_MOODLETS
	sentience_type = SENTIENCE_HUMANOID
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/items/weapons/punch1.ogg'
	melee_damage_lower = 10
	melee_damage_upper = 10
	unsuitable_atmos_damage = 7.5
	unsuitable_cold_damage = 7.5
	unsuitable_heat_damage = 7.5
	max_stamina = 150
	stamina_recovery = 5
	max_stamina_slowdown = 12
	faction = list(FACTION_CIVILIAN, FACTION_NEUTRAL)

	ai_controller = /datum/ai_controller/basic_controller/npc_civilian

	var/possible_outfits = list()
	var/outfit

	var/species = /datum/species/human
	var/mob_type = /obj/effect/mob_spawn/corpse/human

	var/item_l_hand
	var/item_r_hand
	var/make_random_name = TRUE

	var/ghost_controlable = TRUE
	var/join_text = "You are an NPC, follow the standard RP rules, remember that you are only a part of the story - not its center."
	var/important_text = "Do not grief players!"

	var/randomize_mutant_colors = FALSE
	var/add_hair = TRUE
	var/mutant_color_1 = COLOR_WHITE
	var/mutant_color_2 = COLOR_WHITE
	var/mutant_color_3 = COLOR_WHITE

	var/innate_actions = list()

	var/ranged = FALSE
	var/casingtype = /obj/item/ammo_casing/c9mm
	var/projectilesound = 'sound/items/weapons/gun/pistol/shot.ogg'
	var/burst_shots
	var/ranged_cooldown = 0.4 SECONDS
	var/ragned_shots_before_reload = 30

	var/save_data = TRUE

	var/saved_skin_tone
	var/saved_physique
	var/saved_eye_color_left
	var/saved_eye_color_right
	var/saved_hairstyle
	var/saved_hair_color
	var/saved_facial_hairstyle
	var/saved_facial_hair_color
	var/list/saved_dna_features = list()
	var/list/saved_mutant_bodypart = list()

	var/list/inante_abilities = list()
	var/npc_typing_popup

/mob/living/basic/npc/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_SHOE)
	AddElement(/datum/element/basic_eating)
	// AddElement(/datum/element/ai_pull_awareness)
	// AddElement(/datum/element/ai_social_awareness)
	AddElement(/datum/element/npc_talk, CALLBACK(src, PROC_REF(handle_npc_talk)))

	if(randomize_mutant_colors || (species != /datum/species/human))
		randomize_colors()
	if(make_random_name)
		name = generate_name()
	if(!outfit)
		pick_outfit()
	else if(islist(outfit))
		outfit = pick(outfit)
	gender = pick(MALE, FEMALE)
	INVOKE_ASYNC(src, PROC_REF(generate_dynamic_appearance))
	generate_desc_based_on_species()
	if(ranged)
		AddComponent(/datum/component/advanced_ranged_attacks,\
			casing_type = casingtype,\
			projectile_sound = projectilesound,\
			cooldown_time = ranged_cooldown,\
			burst_shots = burst_shots,\
			shots_before_reload = ragned_shots_before_reload,\
			before_fire_callback = CALLBACK(src, PROC_REF(before_ranged_fire)), \
			after_fire_callback = CALLBACK(src, PROC_REF(after_ranged_fire)), \
		)
		if(ranged_cooldown <= 1 SECONDS)
			AddComponent(/datum/component/ranged_mob_full_auto)
	grant_actions_by_list(inante_abilities)


/mob/living/basic/npc/examine(mob/user)
	. = ..()
	if(item_r_hand)
		var/obj/item/I = item_r_hand
		. += span_notice("In [p_their()] right hand is [I::name].")
	if(item_l_hand)
		var/obj/item/I = item_l_hand
		. += span_notice("In [p_their()] left hand is [I::name].")

/mob/living/basic/npc/proc/generate_desc_based_on_species()
	switch(species)
		if(/datum/species/human)
			desc = "An ordinary human civilian. Nothing particularly stands out."
		if(/datum/species/vulpkanin)
			desc = "A furry vulpkanin with expressive ears and a fluffy tail. This dog-like civilian looks around warily."
		if(/datum/species/tajaran)
			desc = "A feline tajaran with soft fur, expressive ears, and a swaying tail. Sharp eyes carefully scan the surroundings."
		if(/datum/species/lizard)
			desc = "A scaly lizard with proud posture and a twitching tail. The tough hide and sharp features speak of endurance."
		else
			var/datum/species/path = species
			desc = "A civilian of an unusual species. [path ? "([path::name])" : "Unknown species."]"
	if(prob(30))
		desc += pick(" Seems a little lost.", " Looks tired after a long shift.", " Quietly hums something to themselves.", " A faint smell of [pick("coffee","machine oil","fish","wet fur")] lingers around them.")


/mob/living/basic/npc/attack_ghost(mob/dead/observer/user)
	if(!user.client || key || !ghost_controlable)
		return
	var/ask = tgui_alert(user, "Do you want to play as [name] - this will require you to follow special rules.", \
	"Play as NPC?", list("Yes", "Never"), 15 SECONDS)
	if(!ask || ask != "Yes")
		return
	take_control(user)

/mob/living/basic/npc/proc/generate_name()
	return generate_random_name_species_based(gender, TRUE, species)

/mob/living/basic/npc/take_control(mob/user)
	key = user.key

	to_chat(src, span_boldnotice(join_text))
	to_chat(src, span_big(span_red(important_text)))
	log_game("[key_name(src)] took control of [name].")
	message_admins("[key_name(src)] too control of npc [ADMIN_LOOKUPFLW(src)]")

/mob/living/basic/npc/death(gibbed)
	if(gibbed)
		return ..()
	INVOKE_ASYNC(src, PROC_REF(spawn_real_corpse_and_destroy))
	return ..()


/mob/living/basic/npc/proc/pick_outfit()
	outfit = pick(possible_outfits)


/mob/living/basic/npc/proc/before_ranged_fire()
	return

/mob/living/basic/npc/proc/after_ranged_fire()
	return
