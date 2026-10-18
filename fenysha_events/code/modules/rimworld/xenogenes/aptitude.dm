// ========== ANIMALS ==========
/datum/rw_xenogene/aptitude/awful_animals
	id = RW_XENOGENE_AWFUL_ANIMALS
	name = "Awful animals"
	desc = "Animals aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_ANIMALS = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ANIMALS
	passion_skill = RW_SKILL_ANIMALS
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_animals"

/datum/rw_xenogene/aptitude/poor_animals
	id = RW_XENOGENE_POOR_ANIMALS
	name = "Poor animals"
	desc = "Animals aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_ANIMALS = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ANIMALS
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_animals"

/datum/rw_xenogene/aptitude/strong_animals
	id = RW_XENOGENE_STRONG_ANIMALS
	name = "Strong animals"
	desc = "Animals aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_ANIMALS = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ANIMALS
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_animals"

/datum/rw_xenogene/aptitude/great_animals
	id = RW_XENOGENE_GREAT_ANIMALS
	name = "Great animals"
	desc = "Animals aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_ANIMALS = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ANIMALS
	passion_skill = RW_SKILL_ANIMALS
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_animals"

// ========== MELEE ==========
/datum/rw_xenogene/aptitude/awful_melee
	id = RW_XENOGENE_AWFUL_MELEE
	name = "Awful melee"
	desc = "Melee aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MELEE = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MELEE
	passion_skill = RW_SKILL_MELEE
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_melee"

/datum/rw_xenogene/aptitude/poor_melee
	id = RW_XENOGENE_POOR_MELEE
	name = "Poor melee"
	desc = "Melee aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MELEE = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MELEE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_melee"

/datum/rw_xenogene/aptitude/strong_melee
	id = RW_XENOGENE_STRONG_MELEE
	name = "Strong melee"
	desc = "Melee aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_MELEE = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MELEE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_melee"

/datum/rw_xenogene/aptitude/great_melee
	id = RW_XENOGENE_GREAT_MELEE
	name = "Great melee"
	desc = "Melee aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_MELEE = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MELEE
	passion_skill = RW_SKILL_MELEE
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_melee"

// ========== SHOOTING ==========
/datum/rw_xenogene/aptitude/awful_shooting
	id = RW_XENOGENE_AWFUL_SHOOTING
	name = "Awful shooting"
	desc = "Shooting aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_SHOOTING = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SHOOTING
	passion_skill = RW_SKILL_RANGED
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_shooting"

/datum/rw_xenogene/aptitude/poor_shooting
	id = RW_XENOGENE_POOR_SHOOTING
	name = "Poor shooting"
	desc = "Shooting aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_SHOOTING = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SHOOTING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_shooting"

/datum/rw_xenogene/aptitude/strong_shooting
	id = RW_XENOGENE_STRONG_SHOOTING
	name = "Strong shooting"
	desc = "Shooting aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_SHOOTING = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SHOOTING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_shooting"

/datum/rw_xenogene/aptitude/great_shooting
	id = RW_XENOGENE_GREAT_SHOOTING
	name = "Great shooting"
	desc = "Shooting aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_SHOOTING = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SHOOTING
	passion_skill = RW_SKILL_RANGED
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_shooting"

// ========== CONSTRUCTION ==========
/datum/rw_xenogene/aptitude/awful_construction
	id = RW_XENOGENE_AWFUL_CONSTRUCTION
	name = "Awful construction"
	desc = "Construction aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_CONSTRUCTION = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CONSTRUCTION
	passion_skill = RW_SKILL_CONSTRUCTION
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_construction"

/datum/rw_xenogene/aptitude/poor_construction
	id = RW_XENOGENE_POOR_CONSTRUCTION
	name = "Poor construction"
	desc = "Construction aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_CONSTRUCTION = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CONSTRUCTION
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_construction"

/datum/rw_xenogene/aptitude/strong_construction
	id = RW_XENOGENE_STRONG_CONSTRUCTION
	name = "Strong construction"
	desc = "Construction aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_CONSTRUCTION = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CONSTRUCTION
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_construction"

/datum/rw_xenogene/aptitude/great_construction
	id = RW_XENOGENE_GREAT_CONSTRUCTION
	name = "Great construction"
	desc = "Construction aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_CONSTRUCTION = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CONSTRUCTION
	passion_skill = RW_SKILL_CONSTRUCTION
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_construction"

// ========== MINING ==========
/datum/rw_xenogene/aptitude/awful_mining
	id = RW_XENOGENE_AWFUL_MINING
	name = "Awful mining"
	desc = "Mining aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MINING = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MINING
	passion_skill = RW_SKILL_MINING
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_mining"

/datum/rw_xenogene/aptitude/poor_mining
	id = RW_XENOGENE_POOR_MINING
	name = "Poor mining"
	desc = "Mining aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MINING = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MINING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_mining"

/datum/rw_xenogene/aptitude/strong_mining
	id = RW_XENOGENE_STRONG_MINING
	name = "Strong mining"
	desc = "Mining aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_MINING = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MINING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_mining"

/datum/rw_xenogene/aptitude/great_mining
	id = RW_XENOGENE_GREAT_MINING
	name = "Great mining"
	desc = "Mining aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_MINING = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MINING
	passion_skill = RW_SKILL_MINING
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_mining"

// ========== COOKING ==========
/datum/rw_xenogene/aptitude/awful_cooking
	id = RW_XENOGENE_AWFUL_COOKING
	name = "Awful cooking"
	desc = "Cooking aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_COOKING = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_COOKING
	passion_skill = RW_SKILL_COOKING
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_cooking"

/datum/rw_xenogene/aptitude/poor_cooking
	id = RW_XENOGENE_POOR_COOKING
	name = "Poor cooking"
	desc = "Cooking aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_COOKING = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_COOKING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_cooking"

/datum/rw_xenogene/aptitude/strong_cooking
	id = RW_XENOGENE_STRONG_COOKING
	name = "Strong cooking"
	desc = "Cooking aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_COOKING = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_COOKING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_cooking"

/datum/rw_xenogene/aptitude/great_cooking
	id = RW_XENOGENE_GREAT_COOKING
	name = "Great cooking"
	desc = "Cooking aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_COOKING = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_COOKING
	passion_skill = RW_SKILL_COOKING
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_cooking"

// ========== PLANTS ==========
/datum/rw_xenogene/aptitude/awful_plants
	id = RW_XENOGENE_AWFUL_PLANTS
	name = "Awful plants"
	desc = "Plants aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_PLANTS = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_PLANTS
	passion_skill = RW_SKILL_PLANTS
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_plants"

/datum/rw_xenogene/aptitude/poor_plants
	id = RW_XENOGENE_POOR_PLANTS
	name = "Poor plants"
	desc = "Plants aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_PLANTS = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_PLANTS
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_plants"

/datum/rw_xenogene/aptitude/strong_plants
	id = RW_XENOGENE_STRONG_PLANTS
	name = "Strong plants"
	desc = "Plants aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_PLANTS = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_PLANTS
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_plants"

/datum/rw_xenogene/aptitude/great_plants
	id = RW_XENOGENE_GREAT_PLANTS
	name = "Great plants"
	desc = "Plants aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_PLANTS = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_PLANTS
	passion_skill = RW_SKILL_PLANTS
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_plants"

// ========== CRAFTING ==========
/datum/rw_xenogene/aptitude/awful_crafting
	id = RW_XENOGENE_AWFUL_CRAFTING
	name = "Awful crafting"
	desc = "Crafting aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_CRAFTING = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CRAFTING
	passion_skill = RW_SKILL_CRAFTING
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_crafting"

/datum/rw_xenogene/aptitude/poor_crafting
	id = RW_XENOGENE_POOR_CRAFTING
	name = "Poor crafting"
	desc = "Crafting aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_CRAFTING = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CRAFTING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_crafting"

/datum/rw_xenogene/aptitude/strong_crafting
	id = RW_XENOGENE_STRONG_CRAFTING
	name = "Strong crafting"
	desc = "Crafting aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_CRAFTING = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CRAFTING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_crafting"

/datum/rw_xenogene/aptitude/great_crafting
	id = RW_XENOGENE_GREAT_CRAFTING
	name = "Great crafting"
	desc = "Crafting aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_CRAFTING = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_CRAFTING
	passion_skill = RW_SKILL_CRAFTING
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_crafting"

// ========== ARTISTIC ==========
/datum/rw_xenogene/aptitude/awful_artistic
	id = RW_XENOGENE_AWFUL_ARTISTIC
	name = "Awful artistic"
	desc = "Artistic aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_ARTISTIC = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ARTISTIC
	passion_skill = RW_SKILL_ARTISTIC
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_artistic"

/datum/rw_xenogene/aptitude/poor_artistic
	id = RW_XENOGENE_POOR_ARTISTIC
	name = "Poor artistic"
	desc = "Artistic aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_ARTISTIC = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ARTISTIC
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_artistic"

/datum/rw_xenogene/aptitude/strong_artistic
	id = RW_XENOGENE_STRONG_ARTISTIC
	name = "Strong artistic"
	desc = "Artistic aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_ARTISTIC = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ARTISTIC
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_artistic"

/datum/rw_xenogene/aptitude/great_artistic
	id = RW_XENOGENE_GREAT_ARTISTIC
	name = "Great artistic"
	desc = "Artistic aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_ARTISTIC = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_ARTISTIC
	passion_skill = RW_SKILL_ARTISTIC
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_artistic"

// ========== MEDICAL ==========
/datum/rw_xenogene/aptitude/awful_medical
	id = RW_XENOGENE_AWFUL_MEDICAL
	name = "Awful medical"
	desc = "Medical aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MEDICAL = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MEDICAL
	passion_skill = RW_SKILL_MEDICAL
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_medical"

/datum/rw_xenogene/aptitude/poor_medical
	id = RW_XENOGENE_POOR_MEDICAL
	name = "Poor medical"
	desc = "Medical aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_MEDICAL = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MEDICAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_medical"

/datum/rw_xenogene/aptitude/strong_medical
	id = RW_XENOGENE_STRONG_MEDICAL
	name = "Strong medical"
	desc = "Medical aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_MEDICAL = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MEDICAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_medical"

/datum/rw_xenogene/aptitude/great_medical
	id = RW_XENOGENE_GREAT_MEDICAL
	name = "Great medical"
	desc = "Medical aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_MEDICAL = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_MEDICAL
	passion_skill = RW_SKILL_MEDICAL
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_medical"

// ========== SOCIAL ==========
/datum/rw_xenogene/aptitude/awful_social
	id = RW_XENOGENE_AWFUL_SOCIAL
	name = "Awful social"
	desc = "Social aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_SOCIAL = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SOCIAL
	passion_skill = RW_SKILL_SOCIAL
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_social"

/datum/rw_xenogene/aptitude/poor_social
	id = RW_XENOGENE_POOR_SOCIAL
	name = "Poor social"
	desc = "Social aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_SOCIAL = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SOCIAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_social"

/datum/rw_xenogene/aptitude/strong_social
	id = RW_XENOGENE_STRONG_SOCIAL
	name = "Strong social"
	desc = "Social aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_SOCIAL = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SOCIAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_social"

/datum/rw_xenogene/aptitude/great_social
	id = RW_XENOGENE_GREAT_SOCIAL
	name = "Great social"
	desc = "Social aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_SOCIAL = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_SOCIAL
	passion_skill = RW_SKILL_SOCIAL
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_social"

// ========== INTELLECTUAL ==========
/datum/rw_xenogene/aptitude/awful_intellectual
	id = RW_XENOGENE_AWFUL_INTELLECTUAL
	name = "Awful intellectual"
	desc = "Intellectual aptitude −8. Removes passion."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_INTELLECTUAL = -8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_INTELLECTUAL
	passion_skill = RW_SKILL_INTELLECTUAL
	passion_grant = RW_PASSION_NONE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "awful_intellectual"

/datum/rw_xenogene/aptitude/poor_intellectual
	id = RW_XENOGENE_POOR_INTELLECTUAL
	name = "Poor intellectual"
	desc = "Intellectual aptitude −4."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	point_cost = 0
	skill_bonuses = list(RW_SKILL_INTELLECTUAL = -4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_INTELLECTUAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "poor_intellectual"

/datum/rw_xenogene/aptitude/strong_intellectual
	id = RW_XENOGENE_STRONG_INTELLECTUAL
	name = "Strong intellectual"
	desc = "Intellectual aptitude +4."
	complexity = 1
	metabolic_efficiency = -1
	point_cost = 150
	skill_bonuses = list(RW_SKILL_INTELLECTUAL = 4)
	incompatibility_group = RW_XENOGENE_GROUP_APT_INTELLECTUAL
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_intellectual"

/datum/rw_xenogene/aptitude/great_intellectual
	id = RW_XENOGENE_GREAT_INTELLECTUAL
	name = "Great intellectual"
	desc = "Intellectual aptitude +8. Adds passion."
	complexity = 1
	metabolic_efficiency = -2
	point_cost = 400
	skill_bonuses = list(RW_SKILL_INTELLECTUAL = 8)
	incompatibility_group = RW_XENOGENE_GROUP_APT_INTELLECTUAL
	passion_skill = RW_SKILL_INTELLECTUAL
	passion_grant = RW_PASSION_INTERESTED
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "great_intellectual"

/datum/rw_xenogene/aptitude/apply_gameplay(mob/living/target)
	. = ..()
	if(!passion_skill || isnull(passion_grant) || !target)
		return
	var/datum/psychology/psy = target.get_psychology()
	if(!psy)
		return
	if(passion_grant <= RW_PASSION_NONE)
		psy.set_passion(passion_skill, RW_PASSION_NONE)
	else if(psy.get_passion(passion_skill) < passion_grant)
		psy.set_passion(passion_skill, passion_grant)
