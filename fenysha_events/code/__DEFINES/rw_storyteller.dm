#define STORYTELLER_JSON_PATH "config/storyteller/storytellers.json"
#define STORYTELLER_ICONS_PATH "config/storytellers_icons/"

#define STORYTELLER_DEFAULT_INTERVAL_DAYS 2
#define STORYTELLER_MIN_INTERVAL_DAYS 0.25
#define STORYTELLER_MAX_INTERVAL_DAYS 30
#define STORYTELLER_PLAN_LENGTH 3
#define STORYTELLER_THINK_INTERVAL 5 SECONDS
#define STORYTELLER_VOTE_DURATION 60 SECONDS

#define STORYTELLER_DEFAULT_DIFFICULTY 1.0
#define STORYTELLER_MIN_DIFFICULTY 0.3
#define STORYTELLER_MAX_DIFFICULTY 5.0

#define STORY_EVENT_GOOD "good"
#define STORY_EVENT_NEUTRAL "neutral"
#define STORY_EVENT_BAD "bad"
#define STORY_EVENT_MAJOR "major"

/// Every concrete child of /datum/storyteller_event is discovered automatically.
/// Event categories describe the kind of incident, not a faction or role.
#define STORY_EVENT_CATEGORY_GOOD STORY_EVENT_GOOD
#define STORY_EVENT_CATEGORY_NEUTRAL STORY_EVENT_NEUTRAL
#define STORY_EVENT_CATEGORY_BAD STORY_EVENT_BAD
#define STORY_EVENT_CATEGORY_MAJOR STORY_EVENT_MAJOR

#define ADMIN_CATEGORY_STORYTELLER "storytellers"

// Voting

/// Start a vote automatically once after the round begins.
#define STORYTELLER_VOTE_AUTO_START FALSE
#define STORYTELLER_VOTE_AUTO_DELAY (300 MINUTES)
/// How long the results window stays open after the vote ends.
#define STORYTELLER_VOTE_RESULT_LINGER (30 SECONDS)
/// Observers (people who have not founded/joined a colony yet) may vote.
#define STORYTELLER_OBSERVERS_CAN_VOTE FALSE

// Threat points (everything below is tuning, change freely)

#define STORYTELLER_THREAT_BASE 35
#define STORYTELLER_THREAT_PER_COLONIST 30
/// Every next colonist adds this share of the previous colonist's points.
#define STORYTELLER_THREAT_COLONIST_DECAY 0.88
/// Colony wealth is divided by this and added to the points.
#define STORYTELLER_THREAT_WEALTH_DIVISOR 400
#define STORYTELLER_THREAT_MIN 35
#define STORYTELLER_THREAT_MAX 8000
/// No threat events in a colony cell younger than this (planet days).
#define STORYTELLER_THREAT_GRACE_DAYS 3
/// Minimum gap between two threat events in the same cell (planet days).
#define STORYTELLER_THREAT_MIN_GAP_DAYS 1
/// Colony age at which the age bonus is fully applied.
#define STORYTELLER_THREAT_AGE_RAMP_DAYS 60
/// Extra threat multiplier a fully "aged" colony receives (+50%).
#define STORYTELLER_THREAT_AGE_BONUS 0.5


#define RAID_STATE_STAGING "staging"
#define RAID_STATE_ATTACKING "attacking"
#define RAID_STATE_RETREATING "retreating"

#define RAID_RESULT_DEFEATED "defeated"
#define RAID_RESULT_RETREATED "retreated"
#define RAID_RESULT_ABORTED "aborted"

/// Raiders gather at the entry point for a while, then attack together.
#define RAID_STRATEGY_STAGE "stage"
/// Raiders go straight for the nearest colonist.
#define RAID_STRATEGY_ASSAULT "assault"

#define RAID_MAX_PAWNS 25
/// Raiders spawn this many tiles inside the map edge so they never trigger the exit prompt.
#define RAID_ENTRY_DEPTH 3
#define RAID_STAGING_TIME (25 SECONDS)
/// A raid with nobody left to fight retreats after this long.
#define RAID_NO_TARGET_GRACE (60 SECONDS)
/// Raiders closer than this to the exit edge are despawned while retreating.
#define RAID_EXIT_DISTANCE 2
/// Deciseconds per raider step.
#define RAID_STEP_DELAY 2
/// JPS search cap in steps; long enough to walk a colony maze from the map edge.
#define RAID_MAX_PATH_LENGTH 250
/// Damage per second a raider without a usable melee weapon does to a wall or door it is breaching.
#define RAID_BREACH_DAMAGE 10
/// Raiders spread their breaches over wall tiles this far either side of where their line hits.
#define RAID_BREACH_SPREAD 3
/// Raiders sharing one breach tile before others prefer a neighbouring one.
#define RAID_BREACH_PER_TILE 2
/// How often a breaching raider checks whether the target became reachable without the wall.
#define RAID_BREACH_RECHECK (4 SECONDS)
/// Placeholder body for every raid_pawn_kind until real mob types are assigned.
#define RAID_FALLBACK_MOB /mob/living/carbon/human
