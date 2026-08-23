/datum/job/buckshot_player
	title = "Test subject"
	description = "You are a test subject who has been trapped in an endless simulation since yesterday evening."
	faction = FACTION_STATION
	total_positions = 5
	spawn_positions = 5
	supervisors = "Yourself"
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/test_subject
	plasmaman_outfit = /datum/outfit/plasmaman

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_SRV

	// mind_traits = list(TRAIT_NAIVE)
	// liver_traits = list(TRAIT_COMEDY_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_CAPTAIN
	departments_list = list(
		/datum/job_department/service,
		)

	mail_goodies = list()

	config_tag = "ASSISTANT"
	job_flags = STATION_JOB_FLAGS


/datum/outfit/job/test_subject
	name = "Test subject"
	jobtype = /datum/job/buckshot_player
	id_trim = /datum/id_trim/job/assistant
	belt = /obj/item/modular_computer/pda/assistant

	uniform = /obj/item/clothing/under/rank/prisoner/lowsec
	belt = /obj/item/modular_computer/pda
	back = /obj/item/storage/backpack/industrial/frontier_colonist/satchel
	shoes = /obj/item/clothing/shoes/jackboots/black
	box = /obj/item/storage/box/survival

/area/centcom/buckshot_club
	name = "Buckshot club"
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY
	area_flags = NOTELEPORT|NO_DEATH_MESSAGE|NO_BOH


/area/centcom/buckshot_club/outdoors
	name = "Streets"
	requires_power = FALSE
	outdoors = TRUE
	daylight = TRUE

/obj/effect/landmark/start/test_subject
	name = "Test subject"
	icon_state = JOB_ASSISTANT



/datum/action/cooldown/spell/disguise_sprite
	name = "Sprite Disguise"
	desc = "Disguises your appearance with a selected sprite."
	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "ninja_cloak"

	school = SCHOOL_FORBIDDEN
	cooldown_time = 3 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE

	var/icon/disguise_icon = 'icons/effects/effects.dmi'
	var/disguise_state = "curse"

	var/datum/status_effect/disguise_sprite/active_disguise

/datum/action/cooldown/spell/disguise_sprite/Remove(mob/living/remove_from)
	if(active_disguise)
		remove_disguise(remove_from)
	return ..()

/datum/action/cooldown/spell/disguise_sprite/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/disguise_sprite/before_cast(mob/living/cast_on)
	. = ..()
	return . | SPELL_NO_IMMEDIATE_COOLDOWN

/datum/action/cooldown/spell/disguise_sprite/cast(mob/living/cast_on)
	. = ..()
	if(active_disguise)
		remove_disguise(cast_on)
		StartCooldown()
	else
		apply_disguise(cast_on)
		StartCooldown()

/datum/action/cooldown/spell/disguise_sprite/proc/apply_disguise(mob/living/cast_on)
	active_disguise = cast_on.apply_status_effect(/datum/status_effect/disguise_sprite, disguise_icon, disguise_state)
	RegisterSignal(active_disguise, COMSIG_QDELETING, PROC_REF(on_disguise_lost))

/datum/action/cooldown/spell/disguise_sprite/proc/remove_disguise(mob/living/cast_on)
	if(!QDELETED(active_disguise))
		UnregisterSignal(active_disguise, COMSIG_QDELETING)
		qdel(active_disguise)
	active_disguise = null

/datum/action/cooldown/spell/disguise_sprite/proc/on_disguise_lost(datum/status_effect/source)
	SIGNAL_HANDLER
	active_disguise = null


// Статус-эффект подмены визуального отображения
/datum/status_effect/disguise_sprite
	id = "disguise_sprite"
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK

	var/image/disguise_image

/datum/status_effect/disguise_sprite/on_apply(mob/living/affected_mob, custom_icon, custom_state)
	if(!custom_icon || !custom_state)
		return FALSE

	disguise_image = image(custom_icon, owner, custom_state, dir = owner.dir)
	disguise_image.override = TRUE

	owner.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, id, disguise_image)

	RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_dir_change))
	RegisterSignal(owner, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(on_body_position_change))
	return TRUE

/datum/status_effect/disguise_sprite/on_remove()
	owner.remove_alt_appearance(id)
	QDEL_NULL(disguise_image)
	UnregisterSignal(owner, list(
		COMSIG_ATOM_DIR_CHANGE,
		COMSIG_LIVING_SET_BODY_POSITION,
	))

/datum/status_effect/disguise_sprite/proc/on_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	disguise_image.dir = new_dir

/datum/status_effect/disguise_sprite/proc/on_body_position_change(datum/source, new_value, old_value)
	SIGNAL_HANDLER
	if(new_value == LYING_DOWN)
		disguise_image.transform = turn(disguise_image.transform, 90)
	else
		disguise_image.transform = turn(disguise_image.transform, -90)


/datum/action/cooldown/spell/disguise_sprite/dealer
	name = "Into dealer"

	disguise_icon = 'fenysha_events/icons/mob/dealer.dmi'
	disguise_state = "dealer"
