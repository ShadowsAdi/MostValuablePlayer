/* Sublime AMXX Editor v4.2 */

/* Uncomment this line if you want to use only ReAPI Support*/
//#define USE_REAPI

/*Comment the below line if you are not testing the plugin. When testing, debug information will be printed to all players */
//#define TESTING

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <most_valuable_player>

#if defined USE_REAPI
#include <reapi>
#else
#include <hamsandwich>

const m_LastHitGroup = 75
#endif

#define PLUGIN  "Most Valuable Player"
#define VERSION "1.0"
#define AUTHOR  "Shadows Adi"

#define IsPlayer(%1)	(1 <= %1 <= g_iMaxClients)

new g_iDamage[MAX_PLAYERS + 1][DamageData]
new g_iKills[MAX_PLAYERS + 1]
new g_iTopKiller
new g_iBombPlanter
new g_iBombDefuser
new g_iMaxClients

new bool:g_bIsBombPlanted
new bool:g_bIsBombDefused

new WinScenario:g_iScenario = NO_SCENARIO

new g_fwScenario
new g_iForwardResult

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	#if defined USE_REAPI
		RegisterHookChain(RG_CSGameRules_RestartRound, "RG_RestartRound_Post", 1)
		RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_Player_Damage_Post", 1)
		RegisterHookChain(RG_CBasePlayer_Killed, "RG_Player_Killed_Post", 1)
		RegisterHookChain(RG_RoundEnd, "RG_Round_End")
	#else
		register_event("TextMsg", "event_Game_Restart", "a", "2&#Game_C", "2&#Game_w")
		RegisterHam(Ham_TakeDamage, "player", "Ham_Player_Damage_Post", 1)
		RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", 1)
		register_logevent("logev_roundend", 2, "1=Round_End")
		register_event("SendAudio", "event_twin", "a", "2&%!MRAD_terwin");
		register_event("SendAudio", "event_ctwin", "a", "2=%!MRAD_ctwin");
	#endif

	register_logevent("logev_roundstart", 2, "1=Round_Start")

	#if defined TESTING
	register_clcmd("say /test", "clcmd_say_test")
	#endif

	g_fwScenario = CreateMultiForward("mvp_scenario", ET_IGNORE, FP_CELL)

	g_iMaxClients = get_maxplayers()
}

public plugin_natives()
{
	register_library("most_valuable_player")

	register_native("get_user_mvp_kills", "native_get_user_mvp_kills")
	register_native("get_user_mvp_topkiller", "native_get_user_mvp_topkiller")
	register_native("get_user_mvp_damage", "native_get_user_mvp_damage")
	register_native("get_user_mvp_hs_damage", "native_get_user_mvp_hs_damage")
}

#if defined USE_REAPI
public RG_RestartRound_Post()
{
	static players[32], inum, player
	get_players(players, inum)

	for(new i; i < inum; i++)
	{
		player = players[i]

		arrayset(g_iDamage[player], 0, sizeof(g_iDamage[]))
	}
	arrayset(g_iKills, 0, charsmax(g_iKills))
	g_iTopKiller = 0
	g_iBombPlanter = 0
	g_iBombDefuser = 0
	g_iScenario = NO_SCENARIO
	g_bIsBombDefused = false;
	g_bIsBombPlanted = false;
}

public RG_Player_Damage_Post(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
		return HC_CONTINUE

	new iHitzone = get_member( iAttacker , m_LastHitGroup )

	g_iDamage[iAttacker][iDamage] += floatround(fDamage)
	if(iHitzone == HIT_HEAD)
	{
		g_iDamage[iAttacker][iHeadshotsDmg] += floatround(fDamage)
	}

	return HC_CONTINUE
}

public RG_Player_Killed_Post(pVictim, pAttacker, iGibs)
{
	if(!IsPlayer(pVictim) || 
		!IsPlayer(pAttacker) || 
		pVictim == pAttacker)
		return HC_CONTINUE

	g_iKills[pAttacker]++

	return HC_CONTINUE
}

public RG_Round_End(WinStatus:status, ScenarioEventEndRound:event, Float:fDelay)
{
	switch(status)
	{
		case WINSTATUS_TERRORISTS:
		{
			if(g_bIsBombPlanted)
			{
				g_iScenario = TERO_MVP
			}
			else
			{
				g_iScenario = KILLER_MVP_TERO
			}
		}
		case WINSTATUS_CTS:
		{
			if(g_bIsBombDefused)
			{
				g_iScenario = CT_MVP
			}
			else
			{
				g_iScenario = KILLER_MVP_CT
			}
		}
	}
	set_task(1.0, "task_check_scenario")

	client_print(0, print_chat, "rg_round_end called")

	return HC_CONTINUE
}
#else
public event_Game_Restart()
{
	static players[32], inum, player
	get_players(players, inum)
	
	for(new i; i < inum; i++)
	{
		player = players[i]

		arrayset(g_iDamage[player], 0, sizeof(g_iDamage[]))
	}
	arrayset(g_iKills, 0, charsmax(g_iKills))
	g_iTopKiller = 0
	g_iBombPlanter = 0
	g_iBombDefuser = 0

	g_bIsBombDefused = false
	g_bIsBombPlanted = false
}

public Ham_Player_Damage_Post(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
		return HAM_IGNORED

	new iHitzone = get_pdata_int( iAttacker , m_LastHitGroup )

	g_iDamage[iAttacker][iDamage] += floatround(fDamage)
	if(iHitzone == HIT_HEAD)
	{
		g_iDamage[iAttacker][iHeadshotsDmg] += floatround(fDamage)
	}

	return HAM_IGNORED
}

public Ham_Player_Killed_Post(iVictim, iAttacker)
{
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
		return HAM_IGNORED

	g_iKills[iAttacker]++

	return HAM_IGNORED
}

public logev_roundend()
{
	set_task(1.0, "task_check_scenario")

	return PLUGIN_CONTINUE
}

public event_twin()
{
	if(g_bIsBombPlanted)
	{
		g_iScenario = TERO_MVP
	}
	else
	{
		g_iScenario = KILLER_MVP_TERO
	}
}

public event_ctwin()
{
	if(g_bIsBombDefused)
	{
		g_iScenario = CT_MVP
	}
	else
	{
		g_iScenario = KILLER_MVP_CT
	}
}
#endif

public logev_roundstart()
{
	static players[32], inum, player
	get_players(players, inum)

	for(new i; i < inum; i++)
	{
		player = players[i]

		arrayset(g_iDamage[player], 0, sizeof(g_iDamage[]))
		arrayset(g_iKills[player], 0, sizeof(g_iKills[]))
	}
	g_iTopKiller = 0
	g_iBombPlanter = 0
	g_iBombDefuser = 0
	g_iScenario = NO_SCENARIO
	g_bIsBombDefused = false;
	g_bIsBombPlanted = false;
}

public task_check_scenario()
{
	switch(g_iScenario)
	{
		case TERO_MVP:
		{
			if(g_bIsBombPlanted && IsPlayer(g_iBombPlanter))
			{
				static szName[32]
				get_user_name(g_iBombPlanter, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for planting the bomb", szName)
			
				#if defined TESTING
				client_print(0, print_chat, "Scenario: TERO_MVP %d", g_iScenario)
				#endif
			}
		}
		case CT_MVP:
		{
			if(g_bIsBombDefused && IsPlayer(g_iBombDefuser))
			{
				static szName[32]
				get_user_name(g_iBombDefuser, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for defusing the bomb", szName)
			
				#if defined TESTING
				client_print(0, print_chat, "Scenario: CT_MVP %d", g_iScenario )
				#endif
			}
		}
		case KILLER_MVP_TERO:
		{
			CalculateTopKiller(KILLER_MVP_TERO)

			#if defined TESTING
			client_print(0, print_chat, "Scenario: KILLER_MVP_TERO %d", g_iScenario)
			#endif
		
		}
		case KILLER_MVP_CT:
		{
			CalculateTopKiller(KILLER_MVP_CT)

			#if defined TESTING
			client_print(0, print_chat, "Scenario: KILLER_MVP_CT %d", g_iScenario)
			#endif
		}
	}

	ExecuteForward(g_fwScenario, g_iForwardResult, WinScenario:g_iScenario)
}

public bomb_explode(id)
{
	g_iBombPlanter = id
	g_bIsBombPlanted = true
	g_iScenario = TERO_MVP

	#if defined TESTING
	client_print(id, print_chat, "bomb_explode forward called")
	#endif
}

public bomb_defused(id)
{
	g_iBombDefuser = id
	g_bIsBombDefused = true
	g_iScenario = CT_MVP

	#if defined TESTING
	client_print(id, print_chat, "bomb_defused forward called")
	#endif
}

stock CalculateTopKiller(WinScenario:status)
{
	if(g_bIsBombDefused && g_iBombDefuser || g_bIsBombPlanted && g_iBombPlanter)
		return PLUGIN_HANDLED

	static players[32], inum

	switch(status)
	{
		case KILLER_MVP_TERO:
		{
			get_players(players, inum, "ch", "T")
		}
		case KILLER_MVP_CT:
		{
			get_players(players, inum, "ch", "CT")
		}
	}

	static player
	new iFrags, iTemp, iTempID
	for(new i; i < inum; i++)
	{
		player = players[i]

		iFrags = g_iKills[player]

		if(iFrags > iTemp)
		{
			iTemp = iFrags
			iTempID = player
		}
	}
	if(0 < iTempID)
	{
		g_iTopKiller = iTempID
	}

	static szName[32]
	get_user_name(g_iTopKiller, szName, charsmax(szName))
	client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for killing %i players", szName, g_iKills[g_iTopKiller])

	return PLUGIN_HANDLED
}

#if defined TESTING
public clcmd_say_test(id)
{
	client_print(id, print_chat, "Scenario: %d", g_iScenario)
}
#endif

public native_get_user_mvp_kills(iPluginID, iParamNum)
{
	new id = get_param(1)

	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "[MVP] Player is not connected (%d)", id);
		return -1;
	}

	return g_iKills[g_iTopKiller]
}
public native_get_user_mvp_topkiller(iPluginID, iParamNum)
{
	new id = get_param(1)

	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "[MVP] Player is not connected (%d)", id);
		return -1;
	}

	return g_iTopKiller
}

public native_get_user_mvp_damage(iPluginID, iParamNum)
{
	new id = get_param(1)

	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "[MVP] Player is not connected (%d)", id);
		return -1;
	}

	return g_iDamage[g_iTopKiller][iDamage]
}

public native_get_user_mvp_hs_damage(iPluginID, iParamNum)
{
	new id = get_param(1)

	if(!IsPlayer(id))
	{
		log_error(AMX_ERR_NATIVE, "[MVP] Player is not connected (%d)", id);
		return -1;
	}

	return g_iDamage[g_iTopKiller][iHeadshotsDmg]
}
