#if defined(NOERP)
/*
*	Map placeholders for NOERP builds.
*
*	These type paths are still placed in .dmm files that load at runtime, but the files
*	defining them are not compiled in. Without a stub the map loader would log a failure
*	for every instance, so each path is reparented onto a placeholder that deletes itself
*	the instant it initialises - nothing of the original object survives into the round.
*
*	If you map a new piece of erotic content, add its path here too.
*/

/obj/effect/noerp_removed
	name = "removed object"
	icon = null
	icon_state = null
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

/obj/effect/noerp_removed/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_QDEL

/obj/effect/decal/cleanable/cum
	parent_type = /obj/effect/noerp_removed

/obj/effect/decal/cleanable/cum/femcum

/obj/item/bdsm_bed_kit
	parent_type = /obj/effect/noerp_removed

/obj/item/bdsm_candle
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/erp_leash
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/glasses/hypno
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/glasses/nice_goggles
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/gloves/ball_mittens
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/mask/leatherwhip
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/neck/mind_collar
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/sextoy
	parent_type = /obj/effect/noerp_removed

/obj/item/clothing/sextoy/buttplug

/obj/item/clothing/sextoy/condom

/obj/item/clothing/sextoy/dildo

/obj/item/clothing/sextoy/eggvib/signalvib

/obj/item/clothing/sextoy/nipple_clamps

/obj/item/clothing/sextoy/vibrator

/obj/item/clothing/sextoy/vibroring

/obj/item/condom_pack
	parent_type = /obj/effect/noerp_removed

/obj/item/construction_kit/pole
	parent_type = /obj/effect/noerp_removed

/obj/item/electropack/shockcollar
	parent_type = /obj/effect/noerp_removed

/obj/item/fancy_pillow
	parent_type = /obj/effect/noerp_removed

/obj/item/kinky_shocker
	parent_type = /obj/effect/noerp_removed

/obj/item/lustwish_discount
	parent_type = /obj/effect/noerp_removed

/obj/item/mind_controller
	parent_type = /obj/effect/noerp_removed

/obj/item/reagent_containers/applicator/pill/crocin
	parent_type = /obj/effect/noerp_removed

/obj/item/reagent_containers/applicator/pill/dopamine
	parent_type = /obj/effect/noerp_removed

/obj/item/reagent_containers/cup/bottle/hexacrocin
	parent_type = /obj/effect/noerp_removed

/obj/item/restraints/handcuffs/lewd
	parent_type = /obj/effect/noerp_removed

/obj/item/serviette_pack
	parent_type = /obj/effect/noerp_removed

/obj/item/stack/shibari_rope
	parent_type = /obj/effect/noerp_removed

/obj/item/stack/shibari_rope/full

/obj/item/stack/shibari_rope/glow

/obj/item/stack/shibari_rope/glow/full

/obj/item/spanking_pad
	parent_type = /obj/effect/noerp_removed

/obj/item/storage/box/shibari_stand
	parent_type = /obj/effect/noerp_removed

/obj/item/storage/box/strippole_kit
	parent_type = /obj/effect/noerp_removed

/obj/item/tickle_feather
	parent_type = /obj/effect/noerp_removed

/obj/machinery/vending/dorms
	parent_type = /obj/effect/noerp_removed

/obj/machinery/vending/dorms/prison

/obj/structure/bed/pillow_large
	parent_type = /obj/effect/noerp_removed

/obj/structure/bed/pillow_tiny
	parent_type = /obj/effect/noerp_removed

/obj/structure/chair/pillow_small
	parent_type = /obj/effect/noerp_removed

/obj/structure/stripper_pole
	parent_type = /obj/effect/noerp_removed

#endif
