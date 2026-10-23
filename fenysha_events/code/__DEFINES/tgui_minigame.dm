// Outcomes of tgui_minigame(), in /datum/minigame_result/var/outcome

/// Played to the end, or finished early from the game
#define MINIGAME_COMPLETED "completed"
/// Quit mid-session; the score so far is kept
#define MINIGAME_ABANDONED "abandoned"
/// Turned down at the briefing
#define MINIGAME_DECLINED "declined"
/// Dismissed at the briefing, or closed by distance, death, disconnect or timeout
#define MINIGAME_INTERRUPTED "interrupted"
