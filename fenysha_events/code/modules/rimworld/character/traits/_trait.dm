/datum/rw_trait
	abstract_type = /datum/rw_trait
	var/id
	var/name = "Trait"
	var/desc = "A colonist trait."
	var/text_good
	var/text_bad
	var/cost = 0
	var/positive = TRUE
	var/list/skill_bonuses

/datum/rw_trait/tough
	id = "tough"
	name = "Tough"
	desc = "Scar tissue and stubborn bone. Harder to put down."
	text_good = "Takes half damage from most hits."
	cost = 400
	positive = TRUE

/datum/rw_trait/industrious
	id = "industrious"
	name = "Industrious"
	desc = "Always moving, always finishing the job."
	text_good = "+35% global work speed."
	text_bad = "Slightly disliked by the lazy."
	cost = 350
	positive = TRUE

/datum/rw_trait/fast_learner
	id = "fast_learner"
	name = "Fast Learner"
	desc = "Picks up techniques after one demonstration."
	text_good = "+75% skill learning rate."
	cost = 350
	positive = TRUE

/datum/rw_trait/sanguine
	id = "sanguine"
	name = "Sanguine"
	desc = "Unreasonably cheerful, even on a rimworld."
	text_good = "Permanent +12 mood."
	cost = 300
	positive = TRUE

/datum/rw_trait/iron_willed
	id = "iron_willed"
	name = "Iron-Willed"
	desc = "Breaks later than most under pressure."
	text_good = "-18% mental break threshold."
	cost = 280
	positive = TRUE

/datum/rw_trait/jogger
	id = "jogger"
	name = "Jogger"
	desc = "Moves with a permanent sense of urgency."
	text_good = "+0.4 move speed."
	cost = 250
	positive = TRUE

/datum/rw_trait/nimble
	id = "nimble"
	name = "Nimble"
	desc = "Dances around danger without thinking about it."
	text_good = "+15 melee dodge chance, far less likely to spring traps."
	cost = 220
	positive = TRUE
	skill_bonuses = list("melee" = 1)

/datum/rw_trait/brawler
	id = "brawler"
	name = "Brawler"
	desc = "Prefers fists and blades to anything with a trigger."
	text_good = "Melee weapons feel natural."
	text_bad = "Hates ranged weapons; will not use them well."
	cost = 150
	positive = TRUE
	skill_bonuses = list("melee" = 4)

/datum/rw_trait/trigger_happy
	id = "trigger_happy"
	name = "Trigger-Happy"
	desc = "Shoots first and checks the target second."
	text_good = "Fires faster with ranged weapons."
	text_bad = "Accuracy suffers from the rush."
	cost = 120
	positive = TRUE
	skill_bonuses = list("ranged" = 2)

/datum/rw_trait/careful_shooter
	id = "careful_shooter"
	name = "Careful Shooter"
	desc = "Lines up every shot like it is the only one that matters."
	text_good = "Higher ranged accuracy."
	text_bad = "Slower rate of fire."
	cost = 120
	positive = TRUE
	skill_bonuses = list("ranged" = 3)

/datum/rw_trait/kind
	id = "kind"
	name = "Kind"
	desc = "Never insults, sometimes lifts others up."
	text_good = "Never insults; occasional kind words improve others' mood."
	cost = 150
	positive = TRUE
	skill_bonuses = list("social" = 2)

/datum/rw_trait/beautiful
	id = "beautiful"
	name = "Beautiful"
	desc = "An arresting face that opens doors."
	text_good = "Large opinion bonus from most people."
	cost = 180
	positive = TRUE
	skill_bonuses = list("social" = 1)

/datum/rw_trait/quick_sleeper
	id = "quick_sleeper"
	name = "Quick Sleeper"
	desc = "Needs less sleep than others to stay sharp."
	text_good = "Restores rest need faster; less time in bed."
	cost = 200
	positive = TRUE

/datum/rw_trait/super_immune
	id = "super_immune"
	name = "Super-Immune"
	desc = "Shrugs off infections that floor others."
	text_good = "+30% immunity gain speed."
	cost = 200
	positive = TRUE

/datum/rw_trait/bloodlust
	id = "bloodlust"
	name = "Bloodlust"
	desc = "Gets a rush from violence and never flinches at corpses."
	text_good = "No mood penalties from death, blood, or butchering."
	text_bad = "Others may find the enthusiasm unsettling."
	cost = 100
	positive = TRUE

/datum/rw_trait/masochist
	id = "masochist"
	name = "Masochist"
	desc = "Pain is interesting, not purely unpleasant."
	text_good = "Gains mood from being in pain instead of losing it."
	cost = 80
	positive = TRUE

/datum/rw_trait/ascetic
	id = "ascetic"
	name = "Ascetic"
	desc = "Wants a simple room and plain food."
	text_good = "Happy with poor rooms and simple meals; ignores beauty of others."
	text_bad = "Unhappy in impressive bedrooms or with fine food."
	cost = 60
	positive = TRUE

/datum/rw_trait/night_owl
	id = "night_owl"
	name = "Night Owl"
	desc = "Works best after dark."
	text_good = "Mood bonus when awake at night; no darkness mood penalty."
	text_bad = "Mood penalty when awake during the day."
	cost = 40
	positive = TRUE

/datum/rw_trait/wimp
	id = "wimp"
	name = "Wimp"
	desc = "Pain thresholds are uncomfortably low."
	text_bad = "Breaks from pain much sooner than others."
	cost = -200
	positive = FALSE

/datum/rw_trait/slowpoke
	id = "slowpoke"
	name = "Slowpoke"
	desc = "Never in a hurry, even when the base is on fire."
	text_bad = "-0.4 move speed."
	cost = -200
	positive = FALSE

/datum/rw_trait/lazy
	id = "lazy"
	name = "Lazy"
	desc = "Work is optional if nobody is watching."
	text_bad = "-15% global work speed."
	cost = -180
	positive = FALSE

/datum/rw_trait/slothful
	id = "slothful"
	name = "Slothful"
	desc = "Would rather nap than finish a job."
	text_bad = "-35% global work speed."
	cost = -300
	positive = FALSE

/datum/rw_trait/slow_learner
	id = "slow_learner"
	name = "Slow Learner"
	desc = "Needs the lesson explained twice, then practiced."
	text_bad = "-75% skill learning rate."
	cost = -280
	positive = FALSE

/datum/rw_trait/depressive
	id = "depressive"
	name = "Depressive"
	desc = "The world is heavy and grey most days."
	text_bad = "Permanent -12 mood."
	cost = -300
	positive = FALSE

/datum/rw_trait/pessimist
	id = "pessimist"
	name = "Pessimist"
	desc = "Expects the worst and is rarely surprised."
	text_bad = "Permanent -6 mood."
	cost = -150
	positive = FALSE

/datum/rw_trait/nervous
	id = "nervous"
	name = "Nervous"
	desc = "Jumps at shadows and bad news."
	text_bad = "+8% mental break threshold (breaks sooner)."
	cost = -120
	positive = FALSE

/datum/rw_trait/volatile
	id = "volatile"
	name = "Volatile"
	desc = "Mood swings hard and fast."
	text_bad = "Much higher mental break threshold; breaks more easily."
	cost = -250
	positive = FALSE

/datum/rw_trait/pyromaniac
	id = "pyromaniac"
	name = "Pyromaniac"
	desc = "Fire is fascinating. Putting it out is not."
	text_bad = "May start fires during mental breaks; will not fight fires."
	cost = -350
	positive = FALSE

/datum/rw_trait/chemical_fascination
	id = "chemical_fascination"
	name = "Chemical Fascination"
	desc = "Anything in a syringe or pill is worth trying."
	text_bad = "Strongly driven to take drugs, even forbidden ones."
	cost = -250
	positive = FALSE

/datum/rw_trait/gourmand
	id = "gourmand"
	name = "Gourmand"
	desc = "Always hungry and particular about meals."
	text_good = "Slight cooking aptitude."
	text_bad = "Eats ~50% more; food binges during breaks."
	cost = -180
	positive = FALSE
	skill_bonuses = list("cooking" = 2)

/datum/rw_trait/ugly
	id = "ugly"
	name = "Ugly"
	desc = "A face people remember for the wrong reasons."
	text_bad = "Opinion penalty from most people."
	cost = -120
	positive = FALSE

/datum/rw_trait/staggeringly_ugly
	id = "staggeringly_ugly"
	name = "Staggeringly Ugly"
	desc = "Hard to look at for long."
	text_bad = "Severe opinion penalty from most people."
	cost = -200
	positive = FALSE

/datum/rw_trait/abrasive
	id = "abrasive"
	name = "Abrasive"
	desc = "Says exactly what is on their mind, especially if it hurts."
	text_bad = "Insults others; opinion penalties stack up."
	cost = -150
	positive = FALSE

/datum/rw_trait/annoying_voice
	id = "annoying_voice"
	name = "Annoying Voice"
	desc = "A grating, nasal bark that wears people down."
	text_bad = "Permanent -25 opinion from most colonists."
	cost = -200
	positive = FALSE

/datum/rw_trait/greedy
	id = "greedy"
	name = "Greedy"
	desc = "Wants the best room and the most wealth."
	text_bad = "Unhappy without impressive wealth and rooms."
	cost = -100
	positive = FALSE

/datum/rw_trait/jealous
	id = "jealous"
	name = "Jealous"
	desc = "Compares bedrooms and never stops."
	text_bad = "Mood penalties if others have better rooms."
	cost = -100
	positive = FALSE

/datum/rw_trait/body_purist
	id = "body_purist"
	name = "Body Purist"
	desc = "Artificial parts are a violation."
	text_bad = "Hates prosthetics and implants on self or others."
	cost = -150
	positive = FALSE

/datum/rw_trait/sickly
	id = "sickly"
	name = "Sickly"
	desc = "Illness finds them first."
	text_bad = "Much lower immunity gain; gets sick more often."
	cost = -220
	positive = FALSE
