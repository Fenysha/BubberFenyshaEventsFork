#define INJURY_SEVERITY_MINOR		1
#define INJURY_SEVERITY_MODERATE	2
#define INJURY_SEVERITY_SEVERE		3
#define INJURY_SEVERITY_CRITICAL	4
#define INJURY_SEVERITY_LOSS		5

#define INJURY_FLAG_EXTERNAL			(1<<0)
#define INJURY_FLAG_INTERNAL			(1<<1)
#define INJURY_FLAG_ACCEPTS_GAUZE		(1<<2)
#define INJURY_FLAG_ACCEPTS_SUTURE		(1<<3)
#define INJURY_FLAG_ACCEPTS_SPLINT		(1<<4)
#define INJURY_FLAG_BLEEDING			(1<<5)
#define INJURY_FLAG_PAINFUL				(1<<6)
#define INJURY_FLAG_DISABLING			(1<<7)
#define INJURY_FLAG_PROGRESSING			(1<<8)

#define INJURY_TYPE_LACERATION			"laceration"		// Порез
#define INJURY_TYPE_CONTUSION			"contusion"			// Ушиб
#define INJURY_TYPE_DISLOCATION			"dislocation"		// Вывих
#define INJURY_TYPE_SKIN_DAMAGE			"skin_damage"		// Повреждение кожи
#define INJURY_TYPE_NERVE_DAMAGE		"nerve_damage"		// Повреждение нервов
#define INJURY_TYPE_ARTERIAL_BLEED		"arterial_bleed"	// Артериальное кровотечение
#define INJURY_TYPE_VENOUS_BLEED		"venous_bleed"		// Венозное кровотечение
#define INJURY_TYPE_BURN				"burn"				// Ожог
#define INJURY_TYPE_FRACTURE			"fracture"			// Перелом
#define INJURY_TYPE_PUNCTURE			"puncture"			// Колотая рана
#define INJURY_TYPE_AVULSION			"avulsion"			// Отрыв мягких тканей


#define PAIN_MAX						200		// Абсолютный потолок боли
#define PAIN_SHOCK_THRESHOLD			45		// С этого уровня боли начинает расти шок
#define PAIN_CRIT_THRESHOLD				90		// Сильная боль, сильно бьёт по сознанию
#define PAIN_UNCONSCIOUS_THRESHOLD		140		// Шанс/риск потери сознания

#define SHOCK_MAX						100
#define SHOCK_MILD						25
#define SHOCK_MODERATE					50
#define SHOCK_SEVERE					75
#define SHOCK_CRITICAL					90

#define CONSCIOUSNESS_MAX				100
#define CONSCIOUSNESS_IMPAIRED			70
#define CONSCIOUSNESS_HEAVY				40
#define CONSCIOUSNESS_CRITICAL			15


// Visibility levels for injuries / medical data
#define INJURY_VISIBILITY_NONE			0	// Never shown
#define INJURY_VISIBILITY_SELF			1	// Only to the owner (self-examine)
#define INJURY_VISIBILITY_MEDICAL		2	// Visible with medical scanner / TRAIT_VIEW_FULL_HEALTH
#define INJURY_VISIBILITY_FULL			3	// Always visible on examine

// Trait
#define TRAIT_VIEW_FULL_HEALTH "always_full_healthpanel"
#define TRAIT_DISABLED_BY_INJURY "!disable_by_injury"


#define MAX_INJURIES_PER_LIMB 8
#define MAX_INJURY_DAMAGE_MULTIPLIER 2.5
