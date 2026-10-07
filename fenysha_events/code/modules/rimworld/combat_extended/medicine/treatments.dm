/obj/item/stack/medical/medicine/gauze
	name = "medical gauze"
	singular_name = "medical gauze"
	desc = "Sterile gauze used to dress and stabilize wounds."
	icon_state = "brutepack"

	amount = 6
	max_amount = 12
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_TINY
	merge_type = /obj/item/stack/medical/medicine/gauze
	apply_verb = "bandaging"

/obj/item/stack/medical/medicine/suture
	name = "suture"
	singular_name = "suture"
	desc = "Sterile sutures used to close and stabilize wounds."
	icon_state = "brutepack"

	gender = PLURAL
	amount = 10
	max_amount = 10
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 4 SECONDS
	treatment_other_delay = 2 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/suture
	apply_verb = "suturing"

/obj/item/stack/medical/medicine/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "A therapeutic pack designed to treat blunt-force injuries."
	icon_state = "brutepack"

	amount = 6
	max_amount = 6
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/bruise_pack

/obj/item/stack/medical/medicine/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "A medical gel designed to assist the repair of damaged bone."
	icon_state = "brutepack"

	amount = 5
	max_amount = 5
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT
	treatment_self_delay = 8 SECONDS
	treatment_other_delay = 5 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_NORMAL
	merge_type = /obj/item/stack/medical/medicine/bone_gel
