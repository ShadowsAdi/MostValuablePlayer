/* Sublime AMXX Editor v4.2 */

#if defined _most_valuable_player_included
	#endinput
#endif
#define _most_valuable_player_included

#pragma reqlib most_valuable_player
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib most_valuable_player
#endif

enum WinScenario
{
	NO_SCENARIO = -1,
	TERO_MVP = 0,
	CT_MVP,
	KILLER_MVP_TERO,
	KILLER_MVP_CT,
	KILLER_MVP /* Just for default: case in PlayTrack(), unusable */
}

/**
 * @description			Multiforward called when a round end.
 *
 * @param scenario		Scenario index. See WinScenario enum
 * @return				Scenario index.
 */
forward mvp_scenario(WinScenario:scenario);

/**
 * Returns player's MVP kills.
 *
 * @param id		Player index.
 * @return			Amount of kills. -1 on error.
 */
native get_user_mvp_kills(id);

/**
 * Returns top killer's index.
 *
 * @param id		Top killer index.
 * @return			Top killer's index. -1 on error.
 */
native get_user_mvp_topkiller(id);

/**
 * Returns player's MVP damage.
 *
 * @param id		Player index.
 * @return			Player index. -1 on error.
 */
native get_user_mvp_damage(id);

/**
 * Returns player's MVP damage made with headshot.
 *
 * @param id		Player index.
 * @return			Player index. -1 on error.
 */
native get_user_mvp_hs_damage(id);

/**
 * Returns Player's MVPs.
 *
 * @param id		Player index.
 * @return			Player index. -1 on error.
 */
native get_user_mvps(id);
