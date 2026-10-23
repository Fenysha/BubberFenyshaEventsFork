#define RW_RESEARCH_STARTING		(1<<0)
#define RW_RESEARCH_HIDDEN			(1<<1)
#define RW_RESEARCH_DISABLED		(1<<2)


#define RW_TECH_ERA_NEOLITHIC		"neolithic"
#define RW_TECH_ERA_MEDIEVAL		"medieval"
#define RW_TECH_ERA_INDUSTRIAL		"industrial"
#define RW_TECH_ERA_SPACER			"spacer"
#define RW_TECH_ERA_ULTRATECH		"ultratech"

#define RW_TECH_ERAS list(\
	RW_TECH_ERA_NEOLITHIC,\
	RW_TECH_ERA_MEDIEVAL,\
	RW_TECH_ERA_INDUSTRIAL,\
	RW_TECH_ERA_SPACER,\
	RW_TECH_ERA_ULTRATECH\
)

#define RW_TECH_ERA_ORDER list(\
	RW_TECH_ERA_NEOLITHIC,\
	RW_TECH_ERA_MEDIEVAL,\
	RW_TECH_ERA_INDUSTRIAL,\
	RW_TECH_ERA_SPACER,\
	RW_TECH_ERA_ULTRATECH\
)


#define RW_RESEARCH_BASE_PROGRESS		1
#define RW_RESEARCH_CYCLE_TIME			12 SECONDS
#define RW_RESEARCH_IDEAL_SKILL			8
/// Minigame score worth one research point at a 1x bench
#define RW_RESEARCH_INSIGHT_PER_POINT	8
/// Share of the score kept when a research minigame is abandoned
#define RW_RESEARCH_ABANDON_RATIO		0.5
