/obj/item/stack/medical/medicine/medkit
	name = "medical kit"
	singular_name = "medical kit"
	desc = "A compact medical kit containing supplies for treating common injuries."
	icon_state = "brutepack"


	amount = 1
	max_amount = 1
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 8 SECONDS
	treatment_other_delay = 5 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/medkit

/obj/item/stack/medical/medicine/medkit/crude
	name = "crude medical kit"
	singular_name = "crude medical kit"
	icon_state = "brutepack"


	desc = "A crude collection of improvised medical supplies."
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_POOR
	treatment_self_delay = 10 SECONDS
	treatment_other_delay = 6 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_TINY
	merge_type = /obj/item/stack/medical/medicine/medkit/crude

/obj/item/stack/medical/medicine/medkit/indusrtial
	name = "industrial medical kit"
	singular_name = "industrial medical kit"
	desc = "A rugged medical kit intended for treating injuries in industrial environments."
	icon_state = "brutepack"

	treatment_effectiveness = 1.15
	treatment_self_delay = 7 SECONDS
	treatment_other_delay = 4 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/medkit/indusrtial

/obj/item/stack/medical/medicine/medkit/indusrtial/glitertech
	name = "glittertech medical kit"
	singular_name = "glittertech medical kit"
	desc = "An advanced medical kit using highly refined medical technology."
	icon_state = "brutepack"

	treatment_effectiveness = 1.35
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_NORMAL
	merge_type = /obj/item/stack/medical/medicine/medkit/indusrtial/glitertech
