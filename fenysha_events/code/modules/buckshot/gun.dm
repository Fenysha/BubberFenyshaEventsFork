// Buckshot Roulette Ammunition

/obj/projectile/bullet/shotgun_slug/buckshot
    name = "buckshot slug"
    damage = 50
    damage_type = BRUTE
    armour_penetration = 100
    icon_state = "slug"

/obj/projectile/bullet/shotgun_slug/buckshot/can_hit_target(atom/target, direct_target, ignore_loc, cross_failed)
    if(isliving(target) && !HAS_TRAIT(target, TRAIT_BUCKSHOT_PLAYER))
        return FALSE

    return ..()

/obj/projectile/bullet/shotgun_slug/buckshot/on_hit(atom/target, blocked, pierce_hit)
    . = ..()

    if(ishuman(target) && HAS_TRAIT(target, TRAIT_BUCKSHOT_PLAYER))
        var/mob/living/living_target = target
        living_target.death(FALSE)


/obj/projectile/bullet/shotgun_slug/blankshoot
    name = "buckshot blank slug"
    damage = 0
    damage_type = OXY
    armour_penetration = 0
    icon_state = "slug"

/obj/projectile/bullet/shotgun_slug/blankshoot/fire(fire_angle, atom/direct_target)
    qdel(src) // Instantly delete the projectile upon firing


/obj/item/ammo_casing/shotgun/buckshot
    name = "buckshot shell"
    desc = "A mysterious shotgun shell used in Buckshot Roulette."
    caliber = CALIBER_SHOTGUN
    pellets = 1
    variance = 0

/obj/item/ammo_casing/shotgun/buckshot/blank
    name = "buckshot blank shell"
    desc = "A harmless blank shotgun shell for Buckshot Roulette."
    icon_state = "bshell"
    projectile_type = /obj/projectile/bullet/shotgun_slug/blankshoot

/obj/item/ammo_casing/shotgun/buckshot/blank/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
    ..()

/obj/item/ammo_casing/shotgun/buckshot/live
    name = "buckshot live shell"
    desc = "A deadly live shotgun shell for Buckshot Roulette."
    icon_state = "gshell"
    projectile_type = /obj/projectile/bullet/shotgun_slug/buckshot


// Buckshot Roulette Shotgun
/obj/item/gun/ballistic/shotgun/buckshot_game
    name = "\improper Buckshot shotgun"
    desc = "A modified shotgun designed for the Buckshot Roulette game. It features a unique internal mechanism that loads and cycles a shuffled mix of live and blank rounds."
    icon_state = "cshotgun"
    inhand_icon_state = "shotgun_combat"
    can_suppress = FALSE
    burst_size = 1
    fire_delay = 3 SECONDS
    spread = 0
    dual_wield_spread = 0
    randomspread = 0

    var/list/chambers = list()
    var/datum/weakref/party_ref = null
    var/static/list/possible_ammo_types = list(
        /obj/item/ammo_casing/shotgun/buckshot/live,
        /obj/item/ammo_casing/shotgun/buckshot/blank
    )

    var/last_shoot_result = ""
    var/shotingself = FALSE
    var/sawed_off = FALSE

    COOLDOWN_DECLARE(real_shot_cd)

/obj/item/gun/ballistic/shotgun/buckshot_game/Initialize(mapload, datum/buckshot_roulette_party/party)
    . = ..()
    if(party)
        party_ref = WEAKREF(party)
    chambers.Cut()
    chambered = null
    magazine = null

/obj/item/gun/ballistic/shotgun/buckshot_game/examine(mob/user)
    . = ..()
    if(length(chambers))
        . += span_notice("It has [length(chambers)] round[length(chambers) > 1 ? "s" : ""] left.")

/obj/item/gun/ballistic/shotgun/buckshot_game/attempt_pickup(mob/living/user, skip_grav)
    if(!party_ref)
        return ..()
    var/datum/buckshot_roulette_party/party = party_ref.resolve()
    if(!party)
        return ..()
    if(!party.game_started)
        return ..()
    if(!party.is_participant(user))
        to_chat(user, span_warning("You are not a participant in this game!"))
        return FALSE
    if(party.current_turn_player != user)
        to_chat(user, span_warning("It's not your turn right now!"))
        return FALSE
    return ..()

/obj/item/gun/ballistic/shotgun/buckshot_game/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
    if(shotingself)
        return TRUE
    INVOKE_ASYNC(src, PROC_REF(try_fire_gun), target, user, modifiers)
    return TRUE

/obj/item/gun/ballistic/shotgun/buckshot_game/pre_attack_secondary(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
    if(shotingself)
        return TRUE
    INVOKE_ASYNC(src, PROC_REF(try_fire_gun), target, user, modifiers)
    return TRUE

/obj/item/gun/ballistic/shotgun/buckshot_game/try_fire_gun(atom/target, mob/living/user, params)
    if(!COOLDOWN_FINISHED(src, real_shot_cd))
        return

    if(!party_ref)
        return ..()
    if(shotingself)
        return
    var/datum/buckshot_roulette_party/party = party_ref.resolve()
    if(!party)
        return ..()
    if(!ishuman(target))
        return
    var/mob/living/living_target = target
    if(!party.is_participant(living_target))
        user.balloon_alert(user, "Not a game participant!")
        return
    if(party.current_turn_player != user)
        user.balloon_alert(user, "Not your turn!")
        return

    if(target == user && !shotingself)
        INVOKE_ASYNC(src, PROC_REF(attempt_shotself), user)
        return

    COOLDOWN_START(src, real_shot_cd, fire_delay)
    return ..()

/obj/item/gun/ballistic/shotgun/buckshot_game/proc/attempt_shotself(mob/living/user)
    if(shotingself)
        return
    shotingself = TRUE
    user.visible_message(span_warning("[user.name] points the [src.name] at themselves!"))
    user.balloon_alert(user, "You are about to shoot yourself...")
    var/ask_shoot_self = tgui_alert(user, "Shoot yourself?", "Do you want to shoot yourself?", list("Take a chance", "No"), timeout = 10 SECONDS)
    if(ask_shoot_self != "Take a chance")
        user.balloon_alert(user, "You decided not to shoot yourself.")
        user.visible_message(span_notice("[user.name] decides not to shoot themselves with the [src.name]."))
        shotingself = FALSE
        return

    // Safety check in case the shotgun was dropped or moved during the prompt window
    if(src.loc != user)
        shotingself = FALSE
        return

    COOLDOWN_START(src, real_shot_cd, fire_delay)
    fire_gun(user, user)

/obj/item/gun/ballistic/shotgun/buckshot_game/fire_gun(atom/target, mob/living/user, flag, params)
    if(!isliving(target))
        return
    var/mob/living/living_target = target
    var/datum/buckshot_roulette_party/party = party_ref.resolve()
    if(!party)
        return
    var/datum/component/gun_safety/safety_comp = GetComponent(/datum/component/gun_safety)
    if(safety_comp && safety_comp.safety_currently_on)
        safety_comp.toggle_safeties(user)

    if(!party.is_participant(living_target))
        user.balloon_alert(user, "Not a game participant!")
        return
    if(party.current_turn_player != user)
        user.balloon_alert(user, "Not your turn!")
        return

    if(istype(chambered, /obj/item/ammo_casing/shotgun/buckshot/live))
        last_shoot_result = "live"
    else if(istype(chambered, /obj/item/ammo_casing/shotgun/buckshot/blank))
        last_shoot_result = "blank"
    else
        last_shoot_result = "empty"

    if(living_target == user && shotingself)
        shotingself = FALSE

    party.shoot_pending = TRUE
    addtimer(CALLBACK(party, TYPE_PROC_REF(/datum/buckshot_roulette_party, after_player_shoot), user, living_target, last_shoot_result), 1 SECONDS)
    ..()

    if(sawed_off)
        addtimer(CALLBACK(src, PROC_REF(unsaw_off)), 1 SECONDS)

/obj/item/gun/ballistic/shotgun/buckshot_game/attack_self(mob/living/user)
    if(shotingself)
        return TRUE
    INVOKE_ASYNC(src, PROC_REF(try_fire_gun), user, user, list())
    return TRUE

/obj/item/gun/ballistic/shotgun/buckshot_game/rack(mob/user)
    . = ..()
    load_chamber()

/obj/item/gun/ballistic/shotgun/buckshot_game/chamber_round(spin_cylinder, replace_new_round)
    return

/obj/item/gun/ballistic/shotgun/buckshot_game/load_gun(obj/item/ammo, mob/living/user)
    return

/obj/item/gun/ballistic/shotgun/buckshot_game/proc/load_chamber()
    if(chambered)
        return
    if(!length(chambers))
        return
    chambered = chambers[1]
    chambers.Cut(1, 2)

/obj/item/gun/ballistic/shotgun/buckshot_game/proc/load_rounds(live_count = 0, blank_count = 0)
    QDEL_LIST(chambers)
    chambers = list()
    if(chambered)
        qdel(chambered)
        chambered = null

    for(var/i in 1 to live_count)
        chambers += new /obj/item/ammo_casing/shotgun/buckshot/live(src)
        playsound(get_turf(src), 'fenysha_events/sounds/effects/buckshot/load_shell.ogg', 100, TRUE)
        sleep(0.2 SECONDS)

    for(var/i in 1 to blank_count)
        chambers += new /obj/item/ammo_casing/shotgun/buckshot/blank(src)
        playsound(get_turf(src), 'fenysha_events/sounds/effects/buckshot/load_shell.ogg', 100, TRUE)
        sleep(0.2 SECONDS)

    for(var/i = 1 to 3)
        chambers = shuffle(chambers)
    load_chamber()
    return TRUE

/obj/item/gun/ballistic/shotgun/buckshot_game/attackby(obj/item/I, mob/user, params)
    if(I.tool_behaviour == TOOL_SAW || I.tool_behaviour == TOOL_WIRECUTTER)
        saw_off(user)
        return
    return ..()

/obj/item/gun/ballistic/shotgun/buckshot_game/proc/saw_off(mob/user)
    if(sawed_off)
        return
    sawed_off = TRUE
    icon_state = "cshotgunc"

/obj/item/gun/ballistic/shotgun/buckshot_game/proc/unsaw_off(mob/user)
    if(!sawed_off)
        return
    sawed_off = FALSE
    icon_state = "cshotgun"
    balloon_alert_to_viewers("Barrel is regenerating!")
    Shake()
    playsound(get_turf(src), 'fenysha_events/sounds/effects/buckshot/grow_barrel.ogg', 100, TRUE)
