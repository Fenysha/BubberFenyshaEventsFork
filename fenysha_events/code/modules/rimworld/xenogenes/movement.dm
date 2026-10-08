/datum/rw_xenogene/movement/slow_runner
	id = RW_XENOGENE_SLOW_RUNNER
	name = "Slow runner"
	desc = "Moves more slowly."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED

/datum/rw_xenogene/movement/fast_runner
	id = RW_XENOGENE_FAST_RUNNER
	name = "Fast runner"
	desc = "Moves faster."
	complexity = 1
	metabolic_efficiency = -1
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED

/datum/rw_xenogene/movement/very_fast_runner
	id = RW_XENOGENE_VERY_FAST_RUNNER
	name = "Very fast runner"
	desc = "Moves much faster."
	complexity = 2
	metabolic_efficiency = -2
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED

/datum/rw_xenogene/movement/naked_speed
	id = RW_XENOGENE_NAKED_SPEED
	name = "Naked speed"
	desc = "Moves faster when wearing little or no clothing."
	complexity = 1
	metabolic_efficiency = 0
