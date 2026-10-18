// RimWorld research projects: normal research-tree projects for this tech era.
// Node IDs use the RW_ prefix to avoid collisions with TG research nodes.

/datum/techweb_node/rw/drug_production
	id = RW_TECH_DRUG_PRODUCTION
	display_name = "Drug Production"
	description = "Build the equipment required to synthesize industrial drugs."
	research_cost = 500
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/psychite_refining
	id = RW_TECH_PSYCHITE_REFINING
	display_name = "Psychite Refining"
	description = "Refine psychoid into flake and yayo."
	research_cost = 400
	prereq_ids = list(RW_TECH_DRUG_PRODUCTION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/wake_up_production
	id = RW_TECH_WAKE_UP_PRODUCTION
	display_name = "Wake-up Production"
	description = "Synthesize wake-up, a stimulant that reduces the need for sleep."
	research_cost = 600
	prereq_ids = list(RW_TECH_DRUG_PRODUCTION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/go_juice_production
	id = RW_TECH_GO_JUICE_PRODUCTION
	display_name = "Go-juice Production"
	description = "Synthesize a combat stimulant that improves performance and suppresses pain."
	research_cost = 1000
	prereq_ids = list(RW_TECH_DRUG_PRODUCTION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/penoxycyline_production
	id = RW_TECH_PENOXYCYLINE_PRODUCTION
	display_name = "Penoxycyline Production"
	description = "Produce preventative medicine for several major infectious diseases."
	research_cost = 500
	prereq_ids = list(RW_TECH_DRUG_PRODUCTION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/electricity
	id = RW_TECH_ELECTRICITY
	display_name = "Electricity"
	description = "Generate, distribute, and use electrical power throughout a settlement."
	research_cost = 1600
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/batteries
	id = RW_TECH_BATTERIES
	display_name = "Batteries"
	description = "Store excess generated electricity for later use."
	research_cost = 400
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/biofuel_refining
	id = RW_TECH_BIOFUEL_REFINING
	display_name = "Biofuel Refining"
	description = "Convert organic materials into chemfuel."
	research_cost = 700
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/watermill_generator
	id = RW_TECH_WATERMILL_GENERATOR
	display_name = "Watermill Generator"
	description = "Generate electricity from a flowing river."
	research_cost = 700
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/nutrient_paste
	id = RW_TECH_NUTRIENT_PASTE
	display_name = "Nutrient Paste"
	description = "Automate meal preparation using nutrient paste dispensers."
	research_cost = 400
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "food"

/datum/techweb_node/rw/solar_panels
	id = RW_TECH_SOLAR_PANELS
	display_name = "Solar Panels"
	description = "Generate electricity from sunlight."
	research_cost = 600
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/air_conditioning
	id = RW_TECH_AIR_CONDITIONING
	display_name = "Air Conditioning"
	description = "Build powered coolers for temperature control and food preservation."
	research_cost = 500
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "infrastructure"

/datum/techweb_node/rw/autodoors
	id = RW_TECH_AUTODOORS
	display_name = "Autodoors"
	description = "Build powered doors that open automatically for nearby traffic."
	research_cost = 600
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "construction"

/datum/techweb_node/rw/hydroponics
	id = RW_TECH_HYDROPONICS
	display_name = "Hydroponics"
	description = "Grow crops indoors in powered hydroponic basins."
	research_cost = 700
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "agriculture"

/datum/techweb_node/rw/tube_television
	id = RW_TECH_TUBE_TELEVISION
	display_name = "Tube Television"
	description = "Manufacture televisions for indoor recreation."
	research_cost = 1000
	prereq_ids = list(RW_TECH_ELECTRICITY, RW_TECH_COMPLEX_FURNITURE)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "recreation"

/datum/techweb_node/rw/packaged_survival_meal
	id = RW_TECH_PACKAGED_SURVIVAL_MEAL
	display_name = "Packaged Survival Meal"
	description = "Prepare shelf-stable meals for long trips and emergency supplies."
	research_cost = 500
	prereq_ids = list(RW_TECH_NUTRIENT_PASTE)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "food"

/datum/techweb_node/rw/firefoam
	id = RW_TECH_FIREFOAM
	display_name = "Firefoam"
	description = "Build automatic fire suppression devices and related equipment."
	research_cost = 600
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"

/datum/techweb_node/rw/ieds
	id = RW_TECH_IEDS
	display_name = "IEDs"
	description = "Assemble improvised explosive traps from ammunition."
	research_cost = 500
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"

/datum/techweb_node/rw/geothermal_power
	id = RW_TECH_GEOTHERMAL_POWER
	display_name = "Geothermal Power"
	description = "Generate continuous power from geothermal vents."
	research_cost = 3200
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/sterile_materials
	id = RW_TECH_STERILE_MATERIALS
	display_name = "Sterile Materials"
	description = "Construct sterile flooring for hygienic medical and laboratory areas."
	research_cost = 600
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/advanced_lights
	id = RW_TECH_ADVANCED_LIGHTS
	display_name = "Advanced Lights"
	description = "Build powerful outdoor lights and more efficient configurable lighting."
	research_cost = 300
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "infrastructure"

/datum/techweb_node/rw/machining
	id = RW_TECH_MACHINING
	display_name = "Machining"
	description = "Machine precision parts and manufacture firearms, grenades, and armor."
	research_cost = 1000
	prereq_ids = list(RW_TECH_ELECTRICITY, RW_TECH_SMITHING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "manufacturing"

/datum/techweb_node/rw/smokepop_packs
	id = RW_TECH_SMOKEPOP_PACKS
	display_name = "Smokepop Packs"
	description = "Make wearable equipment that releases a defensive smoke screen."
	research_cost = 300
	prereq_ids = list(RW_TECH_MACHINING, RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "armor"

/datum/techweb_node/rw/prosthetics
	id = RW_TECH_PROSTHETICS
	display_name = "Prosthetics"
	description = "Manufacture simple replacement limbs and organs."
	research_cost = 600
	prereq_ids = list(RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/gunsmithing
	id = RW_TECH_GUNSMITHING
	display_name = "Gunsmithing"
	description = "Craft manually operated firearms and incendiary launchers."
	research_cost = 500
	prereq_ids = list(RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"

/datum/techweb_node/rw/flak_armor
	id = RW_TECH_FLAK_ARMOR
	display_name = "Flak Armor"
	description = "Make clothing with built-in metal protection against bullets and blasts."
	research_cost = 1200
	prereq_ids = list(RW_TECH_MACHINING, RW_TECH_PLATE_ARMOR)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "armor"

/datum/techweb_node/rw/mortars
	id = RW_TECH_MORTARS
	display_name = "Mortars"
	description = "Build mortar launchers and long-range ammunition."
	research_cost = 2000
	prereq_ids = list(RW_TECH_GUNSMITHING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"

/datum/techweb_node/rw/blowback_operation
	id = RW_TECH_BLOWBACK_OPERATION
	display_name = "Blowback Operation"
	description = "Craft simple blowback-operated pistols and machine pistols."
	research_cost = 500
	prereq_ids = list(RW_TECH_GUNSMITHING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"

/datum/techweb_node/rw/gas_operation
	id = RW_TECH_GAS_OPERATION
	display_name = "Gas Operation"
	description = "Craft higher-power gas-operated firearms."
	research_cost = 1000
	prereq_ids = list(RW_TECH_BLOWBACK_OPERATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"

/datum/techweb_node/rw/gun_turrets
	id = RW_TECH_GUN_TURRETS
	display_name = "Gun Turrets"
	description = "Build automatic light gun turrets."
	research_cost = 500
	prereq_ids = list(RW_TECH_BLOWBACK_OPERATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"

/datum/techweb_node/rw/foam_turret
	id = RW_TECH_FOAM_TURRET
	display_name = "Foam Turret"
	description = "Build a turret that can suppress fires with extinguishing foam."
	research_cost = 800
	prereq_ids = list(RW_TECH_GUN_TURRETS, RW_TECH_FIREFOAM)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"

/datum/techweb_node/rw/microelectronics
	id = RW_TECH_MICROELECTRONICS
	display_name = "Microelectronics"
	description = "Work with advanced electronics and build a high-tech research bench and comms equipment."
	research_cost = 3000
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "electronics"

/datum/techweb_node/rw/flatscreen_television
	id = RW_TECH_FLATSCREEN_TELEVISION
	display_name = "Flatscreen Television"
	description = "Manufacture high-resolution televisions."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_TUBE_TELEVISION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "recreation"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/moisture_pump
	id = RW_TECH_MOISTURE_PUMP
	display_name = "Moisture Pump"
	description = "Build pumps that gradually normalize moisture in the surrounding ground."
	research_cost = 1200
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "infrastructure"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/hospital_bed
	id = RW_TECH_HOSPITAL_BED
	display_name = "Hospital Bed"
	description = "Build beds that improve treatment quality in medical rooms."
	research_cost = 1200
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_STERILE_MATERIALS, RW_TECH_COMPLEX_FURNITURE)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/deep_drilling
	id = RW_TECH_DEEP_DRILLING
	display_name = "Deep Drilling"
	description = "Build drills that extract resources from deep underground deposits."
	research_cost = 4000
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "mining"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/ground_penetrating_scanner
	id = RW_TECH_GROUND_PENETRATING_SCANNER
	display_name = "Ground-Penetrating Scanner"
	description = "Detect mineable deposits beneath the surface."
	research_cost = 1000
	prereq_ids = list(RW_TECH_DEEP_DRILLING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "mining"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/transport_pod
	id = RW_TECH_TRANSPORT_POD
	display_name = "Transport Pod"
	description = "Launch people and cargo across long distances on the planet."
	research_cost = 1000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_BIOFUEL_REFINING, RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "transport"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/medicine_production
	id = RW_TECH_MEDICINE_PRODUCTION
	display_name = "Medicine Production"
	description = "Produce standard industrial medicine from basic medical ingredients."
	research_cost = 1500
	prereq_ids = list(RW_TECH_DRUG_PRODUCTION, RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/long_range_mineral_scanner
	id = RW_TECH_LONG_RANGE_MINERAL_SCANNER
	display_name = "Long-Range Mineral Scanner"
	description = "Scan distant regions for deposits of a selected mineral."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "mining"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/shields
	id = RW_TECH_SHIELDS
	display_name = "Shields"
	description = "Manufacture wearable shields that deflect incoming projectiles."
	research_cost = 1000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/precision_rifling
	id = RW_TECH_PRECISION_RIFLING
	display_name = "Precision Rifling"
	description = "Machine accurate rifles for long-range and automatic fire."
	research_cost = 1400
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_GAS_OPERATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/autocannon_turret
	id = RW_TECH_AUTOCANNON_TURRET
	display_name = "Autocannon Turret"
	description = "Build a heavy turret with a long-range autocannon."
	research_cost = 1600
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_GUN_TURRETS, RW_TECH_GAS_OPERATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/multibarrel_weapons
	id = RW_TECH_MULTIBARREL_WEAPONS
	display_name = "Multibarrel Weapons"
	description = "Assemble high-rate-of-fire multibarrel firearms."
	research_cost = 2600
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_GAS_OPERATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/multi_analyzer
	id = RW_TECH_MULTI_ANALYZER
	display_name = "Multi-Analyzer"
	description = "Build a research analyzer that supports advanced projects and improves research speed."
	research_cost = 4000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "electronics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/vitals_monitor
	id = RW_TECH_VITALS_MONITOR
	display_name = "Vitals Monitor"
	description = "Build medical monitors that improve the quality of care near hospital beds."
	research_cost = 2500
	prereq_ids = list(RW_TECH_MULTI_ANALYZER, RW_TECH_HOSPITAL_BED)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/fabrication
	id = RW_TECH_FABRICATION
	display_name = "Fabrication"
	description = "Build fabrication benches for components and advanced manufactured goods."
	research_cost = 4000
	prereq_ids = list(RW_TECH_MULTI_ANALYZER)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "manufacturing"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/advanced_fabrication
	id = RW_TECH_ADVANCED_FABRICATION
	display_name = "Advanced Fabrication"
	description = "Produce advanced components from standard components and other materials."
	research_cost = 4000
	prereq_ids = list(RW_TECH_FABRICATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "manufacturing"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/uranium_slug_turret
	id = RW_TECH_URANIUM_SLUG_TURRET
	display_name = "Uranium Slug Turret"
	description = "Build an armor-piercing heavy turret that fires uranium slugs."
	research_cost = 3000
	prereq_ids = list(RW_TECH_MULTI_ANALYZER, RW_TECH_AUTOCANNON_TURRET, RW_TECH_PRECISION_RIFLING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/rocketswarm_launcher
	id = RW_TECH_ROCKETSWARM_LAUNCHER
	display_name = "Rocketswarm Launcher"
	description = "Build a turret that launches salvos of rockets."
	research_cost = 3000
	prereq_ids = list(RW_TECH_MULTI_ANALYZER, RW_TECH_AUTOCANNON_TURRET)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/piano
	id = RW_TECH_PIANO
	display_name = "Piano"
	description = "Craft a piano for advanced musical recreation."
	research_cost = 2000
	prereq_ids = list(RW_TECH_HARPSICHORD)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "recreation"

/datum/techweb_node/rw/jump_packs
	id = RW_TECH_JUMP_PACKS
	display_name = "Jump Packs"
	description = "Manufacture wearable packs for short aerial leaps in combat."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/gunlink
	id = RW_TECH_GUNLINK
	display_name = "Gunlink"
	description = "Build a wearable targeting interface that improves shooting accuracy."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/biosculpting
	id = RW_TECH_BIOSCULPTING
	display_name = "Biosculpting"
	description = "Build biosculpter pods for biological treatment and alteration."
	research_cost = 1500
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/bioregeneration
	id = RW_TECH_BIOREGENERATION
	display_name = "Bioregeneration"
	description = "Unlock a biosculpter cycle that heals scars and age-related damage."
	research_cost = 4000
	prereq_ids = list(RW_TECH_MULTI_ANALYZER, RW_TECH_BIOSCULPTING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/neural_supercharger
	id = RW_TECH_NEURAL_SUPERCHARGER
	display_name = "Neural Supercharger"
	description = "Build devices that temporarily improve consciousness and learning."
	research_cost = 1500
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "electronics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/toxifier_generator
	id = RW_TECH_TOXIFIER_GENERATOR
	display_name = "Toxifier Generator"
	description = "Generate power using a system that produces pollution as a by-product."
	research_cost = 500
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/xenogenetics
	id = RW_TECH_XENOGENETICS
	display_name = "Xenogenetics"
	description = "Extract, store, combine, and implant genes using xenogenetic equipment."
	research_cost = 1000
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "genetics"

/datum/techweb_node/rw/gene_processor
	id = RW_TECH_GENE_PROCESSOR
	display_name = "Gene Processor"
	description = "Build processors for assembling more complex xenogerms."
	research_cost = 1500
	prereq_ids = list(RW_TECH_XENOGENETICS, RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "genetics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/archogenetics
	id = RW_TECH_ARCHOGENETICS
	display_name = "Archogenetics"
	description = "Use archite capsules to assemble exceptionally complex gene combinations."
	research_cost = 2500
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_GENE_PROCESSOR)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "genetics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/deathrest
	id = RW_TECH_DEATHREST
	display_name = "Deathrest"
	description = "Build structures that support and enhance the deathrest cycle."
	research_cost = 1000
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/fertility_procedures
	id = RW_TECH_FERTILITY_PROCEDURES
	display_name = "Fertility Procedures"
	description = "Perform assisted reproduction and sterilization procedures."
	research_cost = 1000
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/tox_gas
	id = RW_TECH_TOX_GAS
	display_name = "Tox Gas"
	description = "Manufacture weapons and equipment that deploy toxic gas."
	research_cost = 600
	prereq_ids = list(RW_TECH_MACHINING)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "weapons"

/datum/techweb_node/rw/basic_mechtech
	id = RW_TECH_BASIC_MECHTECH
	display_name = "Basic Mechtech"
	description = "Build the equipment needed to create and control basic mechanoids."
	research_cost = 200
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "robotics"

/datum/techweb_node/rw/standard_mechtech
	id = RW_TECH_STANDARD_MECHTECH
	display_name = "Standard Mechtech"
	description = "Unlock fabrication of standard-tier mechanoids."
	research_cost = 1000
	prereq_ids = list(RW_TECH_BASIC_MECHTECH)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "robotics"

/datum/techweb_node/rw/high_mechtech
	id = RW_TECH_HIGH_MECHTECH
	display_name = "High Mechtech"
	description = "Unlock advanced mechanoid fabrication and control equipment."
	research_cost = 3000
	prereq_ids = list(RW_TECH_STANDARD_MECHTECH, RW_TECH_MULTI_ANALYZER)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "robotics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/wastepack_atomizer
	id = RW_TECH_WASTEPACK_ATOMIZER
	display_name = "Wastepack Atomizer"
	description = "Build equipment that breaks down toxic wastepacks."
	research_cost = 8000
	prereq_ids = list(RW_TECH_ADVANCED_FABRICATION)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "environment"

/datum/techweb_node/rw/security_door
	id = RW_TECH_SECURITY_DOOR
	display_name = "Security Door"
	description = "Build a powered, heavily reinforced security door."
	research_cost = 700
	prereq_ids = list(RW_TECH_AUTODOORS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"

/datum/techweb_node/rw/turret_pack
	id = RW_TECH_TURRET_PACK
	display_name = "Turret Pack"
	description = "Build a wearable pack that deploys a battery-powered turret."
	research_cost = 1400
	prereq_ids = list(RW_TECH_GUN_TURRETS, RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/basic_gravtech
	id = RW_TECH_BASIC_GRAVTECH
	display_name = "Basic Gravtech"
	description = "Build the core parts needed for a basic gravship."
	research_cost = 300
	prereq_ids = list(RW_TECH_ELECTRICITY)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "transport"

/datum/techweb_node/rw/standard_gravtech
	id = RW_TECH_STANDARD_GRAVTECH
	display_name = "Standard Gravtech"
	description = "Build more complex gravship systems."
	research_cost = 1200
	prereq_ids = list(RW_TECH_BASIC_GRAVTECH, RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "transport"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/orbital_tech
	id = RW_TECH_ORBITAL_TECH
	display_name = "Orbital Tech"
	description = "Build equipment and apparel intended for operation in space."
	research_cost = 1000
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/heavy_bridges
	id = RW_TECH_HEAVY_BRIDGES
	display_name = "Heavy Bridges"
	description = "Build bridges capable of supporting heavier structures."
	research_cost = 800
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "construction"

/datum/techweb_node/rw/hunter_drones
	id = RW_TECH_HUNTER_DRONES
	display_name = "Hunter Drones"
	description = "Build traps and wearable packs that deploy explosive hunter drones."
	research_cost = 1600
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "security"
	required_attachments = list(/obj/building/attachment/analyzer)
