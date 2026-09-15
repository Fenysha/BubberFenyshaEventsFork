/datum/material/rimworld_material/steel
	name = "steel"
	desc = "A common, versatile metal. The backbone of any colony."
	color = "#7F7F7F"
	greyscale_color = "#7F7F7F"
	value_per_unit = 1.9
	stuff_category = RIMWORLD_STUFF_METALLIC
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1,
		RIMWORLD_STAT_FLAMMABILITY = 0.4,
		RIMWORLD_STAT_ARMOR_SHARP = 0.9,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.45,
		RIMWORLD_STAT_ARMOR_HEAT = 0.6,
		RIMWORLD_STAT_MELEE_SHARP = 1,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 1.9,
	)

/datum/material/rimworld_material/plasteel
	name = "plasteel"
	desc = "An advanced composite metal. Extremely tough and light."
	color = "#5B8CFF"
	greyscale_color = "#5B8CFF"
	value_per_unit = 9
	stuff_category = RIMWORLD_STUFF_METALLIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 2.8,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_ARMOR_SHARP = 1.14,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.55,
		RIMWORLD_STAT_ARMOR_HEAT = 0.65,
		RIMWORLD_STAT_MELEE_SHARP = 1.1,
		RIMWORLD_STAT_MELEE_BLUNT = 0.9,
		RIMWORLD_STAT_MELEE_COOLDOWN = 0.8,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 9,
	)

/datum/material/rimworld_material/uranium
	name = "uranium"
	desc = "A dense, heavy radioactive metal. Excellent for armor and blunt weapons."
	color = "#4A5A2A"
	greyscale_color = "#4A5A2A"
	value_per_unit = 6
	stuff_category = RIMWORLD_STUFF_METALLIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 0.5,
		RIMWORLD_STAT_HP_FACTOR = 2.5,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_ARMOR_SHARP = 1.08,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.54,
		RIMWORLD_STAT_ARMOR_HEAT = 0.65,
		RIMWORLD_STAT_MELEE_SHARP = 1.1,
		RIMWORLD_STAT_MELEE_BLUNT = 1.5,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1.1,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 6,
	)

/datum/material/rimworld_material/gold
	name = "gold"
	desc = "The most seductive metal. Soft, beautiful, never tarnishes."
	color = "#FFD700"
	greyscale_color = "#FFD700"
	value_per_unit = 10
	stuff_category = RIMWORLD_STUFF_METALLIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 4,
		RIMWORLD_STAT_BEAUTY_OFFSET = 20,
		RIMWORLD_STAT_HP_FACTOR = 0.6,
		RIMWORLD_STAT_FLAMMABILITY = 0.4,
		RIMWORLD_STAT_ARMOR_SHARP = 0.72,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.36,
		RIMWORLD_STAT_ARMOR_HEAT = 0.36,
		RIMWORLD_STAT_MELEE_SHARP = 0.75,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 10,
	)

/datum/material/rimworld_material/silver
	name = "silver"
	desc = "A precious metal. Soft but beautiful."
	color = "#C0C0C0"
	greyscale_color = "#C0C0C0"
	value_per_unit = 1
	stuff_category = RIMWORLD_STUFF_METALLIC
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 2,
		RIMWORLD_STAT_BEAUTY_OFFSET = 6,
		RIMWORLD_STAT_HP_FACTOR = 0.7,
		RIMWORLD_STAT_FLAMMABILITY = 0.4,
		RIMWORLD_STAT_ARMOR_SHARP = 0.72,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.36,
		RIMWORLD_STAT_ARMOR_HEAT = 0.36,
		RIMWORLD_STAT_MELEE_SHARP = 0.85,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 1,
	)

/datum/material/rimworld_material/bioferrite
	name = "bioferrite"
	desc = "An exotic metal-like fibrous substance with organic and metallic properties."
	color = "#8B4513"
	greyscale_color = "#8B4513"
	value_per_unit = 0.75
	stuff_category = RIMWORLD_STUFF_METALLIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 0.25,
		RIMWORLD_STAT_HP_FACTOR = 2,
		RIMWORLD_STAT_FLAMMABILITY = 0.75,
		RIMWORLD_STAT_ARMOR_SHARP = 1.1,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.5,
		RIMWORLD_STAT_ARMOR_HEAT = 0.5,
		RIMWORLD_STAT_MELEE_SHARP = 1.3,
		RIMWORLD_STAT_MELEE_BLUNT = 0.9,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 2.5,
		RIMWORLD_STAT_MARKET_VALUE = 0.75,
	)

// ========================
// КАМНИ
// ========================

/datum/material/rimworld_material/granite
	name = "granite"
	desc = "A very hard stone. Excellent for durable structures."
	color = "#6B6B6B"
	greyscale_color = "#6B6B6B"
	value_per_unit = 0.9
	stuff_category = RIMWORLD_STUFF_STONY
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1.7,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_ARMOR_SHARP = 0.65,
		RIMWORLD_STAT_MELEE_SHARP = 0.65,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1.3,
		RIMWORLD_STAT_MARKET_VALUE = 0.9,
	)

/datum/material/rimworld_material/marble
	name = "marble"
	desc = "A soft, beautiful stone, known for being easy to sculpt."
	color = "#F5F5F5"
	greyscale_color = "#F5F5F5"
	value_per_unit = 0.9
	stuff_category = RIMWORLD_STUFF_STONY
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1.35,
		RIMWORLD_STAT_BEAUTY_OFFSET = 1,
		RIMWORLD_STAT_HP_FACTOR = 1.2,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_MELEE_SHARP = 0.6,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1.3,
		RIMWORLD_STAT_MARKET_VALUE = 0.9,
	)

/datum/material/rimworld_material/limestone
	name = "limestone"
	desc = "Blocks of solid limestone."
	color = "#D2B48C"
	value_per_unit = 0.9
	stuff_category = RIMWORLD_STUFF_STONY
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1.55,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_MELEE_SHARP = 0.6,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MARKET_VALUE = 0.9,
	)

/datum/material/rimworld_material/sandstone
	name = "sandstone"
	desc = "A relatively soft rock that chips easily."
	color = "#C2B280"
	value_per_unit = 0.9
	stuff_category = RIMWORLD_STUFF_STONY
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1.1,
		RIMWORLD_STAT_HP_FACTOR = 1.4,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_MELEE_SHARP = 0.5,
		RIMWORLD_STAT_MARKET_VALUE = 0.9,
	)

/datum/material/rimworld_material/slate
	name = "slate"
	desc = "A dull-looking rock that chips easily."
	color = "#2F4F4F"
	value_per_unit = 0.9
	stuff_category = RIMWORLD_STUFF_STONY
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1.1,
		RIMWORLD_STAT_HP_FACTOR = 1.3,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_MELEE_SHARP = 0.6,
		RIMWORLD_STAT_MARKET_VALUE = 0.9,
	)

/datum/material/rimworld_material/jade
	name = "jade"
	desc = "A hard, green stone. Beautiful and dense. Great for blunt weapons and decorations."
	color = "#00A86B"
	greyscale_color = "#00A86B"
	value_per_unit = 5
	stuff_category = RIMWORLD_STUFF_STONY
	mineral_rarity = MATERIAL_RARITY_RARE
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 2.5,
		RIMWORLD_STAT_BEAUTY_OFFSET = 10,
		RIMWORLD_STAT_HP_FACTOR = 0.5,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_ARMOR_SHARP = 0.9,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.45,
		RIMWORLD_STAT_ARMOR_HEAT = 0.54,
		RIMWORLD_STAT_MELEE_BLUNT = 1.5,
		RIMWORLD_STAT_MELEE_SHARP = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1.3,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 5,
	)

/datum/material/rimworld_material/obsidian
	name = "obsidian"
	desc = "A dark, glossy volcanic rock. Brittle but extremely sharp."
	color = "#1C1C1C"
	greyscale_color = "#1C1C1C"
	value_per_unit = 5
	stuff_category = RIMWORLD_STUFF_STONY
	mineral_rarity = MATERIAL_RARITY_RARE
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 2,
		RIMWORLD_STAT_BEAUTY_OFFSET = 8,
		RIMWORLD_STAT_HP_FACTOR = 0.5,
		RIMWORLD_STAT_FLAMMABILITY = 0,
		RIMWORLD_STAT_ARMOR_SHARP = 0.85,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.4,
		RIMWORLD_STAT_ARMOR_HEAT = 0.7,
		RIMWORLD_STAT_MELEE_SHARP = 1.4,
		RIMWORLD_STAT_MELEE_BLUNT = 1,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 3,
		RIMWORLD_STAT_MARKET_VALUE = 5,
	)


/datum/material/rimworld_material/wood
	name = "wood"
	desc = "Wood from trees. Lightweight, flammable, and easy to work with."
	color = "#8B4513"
	greyscale_color = "#8B4513"
	value_per_unit = 1.2
	stuff_category = RIMWORLD_STUFF_WOODY
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 0.65,
		RIMWORLD_STAT_FLAMMABILITY = 1,
		RIMWORLD_STAT_ARMOR_SHARP = 0.54,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.54,
		RIMWORLD_STAT_ARMOR_HEAT = 0.4,
		RIMWORLD_STAT_MELEE_SHARP = 0.9,
		RIMWORLD_STAT_MELEE_BLUNT = 0.9,
		RIMWORLD_STAT_MELEE_COOLDOWN = 1,
		RIMWORLD_STAT_INSULATION_COLD = 8,
		RIMWORLD_STAT_INSULATION_HEAT = 4,
		RIMWORLD_STAT_MARKET_VALUE = 1.2,
	)

// ========================
// ТКАНИ
// ========================

/datum/material/rimworld_material/cloth
	name = "cloth"
	desc = "Basic woven fabric."
	color = "#F5F5DC"
	value_per_unit = 1.5
	stuff_category = RIMWORLD_STUFF_FABRIC
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1,
		RIMWORLD_STAT_FLAMMABILITY = 1.2,
		RIMWORLD_STAT_ARMOR_SHARP = 0.36,
		RIMWORLD_STAT_ARMOR_BLUNT = 0,
		RIMWORLD_STAT_ARMOR_HEAT = 0.18,
		RIMWORLD_STAT_INSULATION_COLD = 18,
		RIMWORLD_STAT_INSULATION_HEAT = 18,
		RIMWORLD_STAT_MARKET_VALUE = 1.5,
	)

/datum/material/rimworld_material/devilstrand
	name = "devilstrand"
	desc = "A tough, heat-resistant fabric grown from devilstrand mushrooms."
	color = "#8B0000"
	value_per_unit = 5.5
	stuff_category = RIMWORLD_STUFF_FABRIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 3.2,
		RIMWORLD_STAT_HP_FACTOR = 1.3,
		RIMWORLD_STAT_FLAMMABILITY = 0.4,
		RIMWORLD_STAT_ARMOR_SHARP = 1.4,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.36,
		RIMWORLD_STAT_ARMOR_HEAT = 3,
		RIMWORLD_STAT_INSULATION_COLD = 20,
		RIMWORLD_STAT_INSULATION_HEAT = 24,
		RIMWORLD_STAT_MARKET_VALUE = 5.5,
	)

/datum/material/rimworld_material/hyperweave
	name = "hyperweave"
	desc = "An ultra-advanced synthetic fabric of incredible strength and beauty."
	color = "#4B0082"
	value_per_unit = 9
	stuff_category = RIMWORLD_STUFF_FABRIC
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 5.5,
		RIMWORLD_STAT_HP_FACTOR = 2.4,
		RIMWORLD_STAT_FLAMMABILITY = 0.4,
		RIMWORLD_STAT_ARMOR_SHARP = 2,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.54,
		RIMWORLD_STAT_ARMOR_HEAT = 2.88,
		RIMWORLD_STAT_INSULATION_COLD = 26,
		RIMWORLD_STAT_INSULATION_HEAT = 26,
		RIMWORLD_STAT_MARKET_VALUE = 9,
	)

/datum/material/rimworld_material/synthread
	name = "synthread"
	desc = "A synthetic fabric with balanced properties."
	color = "#708090"
	value_per_unit = 4
	stuff_category = RIMWORLD_STUFF_FABRIC
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 2.3,
		RIMWORLD_STAT_HP_FACTOR = 1.3,
		RIMWORLD_STAT_FLAMMABILITY = 0.7,
		RIMWORLD_STAT_ARMOR_SHARP = 0.94,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.26,
		RIMWORLD_STAT_ARMOR_HEAT = 0.9,
		RIMWORLD_STAT_INSULATION_COLD = 22,
		RIMWORLD_STAT_INSULATION_HEAT = 22,
		RIMWORLD_STAT_MARKET_VALUE = 4,
	)


/datum/material/rimworld_material/plainleather
	name = "plainleather"
	desc = "Standard leather."
	color = "#8B4513"
	value_per_unit = 2.1
	stuff_category = RIMWORLD_STUFF_LEATHERY
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1.3,
		RIMWORLD_STAT_FLAMMABILITY = 1,
		RIMWORLD_STAT_ARMOR_SHARP = 0.81,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.24,
		RIMWORLD_STAT_ARMOR_HEAT = 1.5,
		RIMWORLD_STAT_INSULATION_COLD = 16,
		RIMWORLD_STAT_INSULATION_HEAT = 16,
		RIMWORLD_STAT_MARKET_VALUE = 2.1,
	)

/datum/material/rimworld_material/thrumbofur
	name = "thrumbofur"
	desc = "Incredibly tough and insulating fur from a thrumbo."
	color = "#F5F5F5"
	value_per_unit = 14
	stuff_category = RIMWORLD_STUFF_LEATHERY
	mineral_rarity = MATERIAL_RARITY_RARE
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 8,
		RIMWORLD_STAT_HP_FACTOR = 2,
		RIMWORLD_STAT_FLAMMABILITY = 1,
		RIMWORLD_STAT_ARMOR_SHARP = 2.08,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.36,
		RIMWORLD_STAT_ARMOR_HEAT = 1.5,
		RIMWORLD_STAT_INSULATION_COLD = 34,
		RIMWORLD_STAT_INSULATION_HEAT = 22,
		RIMWORLD_STAT_MARKET_VALUE = 14,
	)

/datum/material/rimworld_material/human_leather
	name = "human leather"
	desc = "Leather made from human skin. Controversial, but functional."
	color = "#C4A484"
	value_per_unit = 4.2
	stuff_category = RIMWORLD_STUFF_LEATHERY
	rimworld_stats = list(
		RIMWORLD_STAT_BEAUTY_FACTOR = 1,
		RIMWORLD_STAT_HP_FACTOR = 1.3,
		RIMWORLD_STAT_ARMOR_SHARP = 0.64,
		RIMWORLD_STAT_ARMOR_BLUNT = 0.24,
		RIMWORLD_STAT_ARMOR_HEAT = 1.5,
		RIMWORLD_STAT_INSULATION_COLD = 12,
		RIMWORLD_STAT_INSULATION_HEAT = 12,
		RIMWORLD_STAT_MARKET_VALUE = 4.2,
	)
