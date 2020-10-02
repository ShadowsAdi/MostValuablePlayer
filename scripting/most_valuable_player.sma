/* Sublime AMXX Editor v4.2 */

/* Uncomment this line if you want to use only ReAPI */
//#define USE_REAPI

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

new WinScenario:g_iScenario

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
public RG_Restart_Post()
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
	if(status == WINSTATUS_DRAW || status == WINSTATUS_NONE)
		return HC_CONTINUE

	switch(g_iScenario)
	{
		case TERO_MVP:
		{
			if(g_bIsBombPlanted && IsPlayer(g_iBombPlanter))
			{
				static szName[32]
				get_user_name(g_iBombDefuser, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for planting the bomb", szName)
			}
		}
		case CT_MVP:
		{
			if(g_bIsBombDefused && IsPlayer(g_iBombDefuser))
			{
				static szName[32]
				get_user_name(g_iBombDefuser, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for defusing the bomb", szName)
			}
		}
		case KILLER_MVP_TERO:
		{
			CalculateTopKiller(KILLER_MVP_TERO)
			static szName[32]
			get_user_name(g_iTopKiller, szName, charsmax(szName))
			client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for killing %i players", szName, g_iKills[g_iTopKiller])
		}
		case KILLER_MVP_CT:
		{
			CalculateTopKiller(KILLER_MVP_CT)

			static szName[32]
			get_user_name(g_iTopKiller, szName, charsmax(szName))
			client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for killing %i players", szName, g_iKills[g_iTopKiller])
		}
	}

	ExecuteForward(g_fwScenario, g_iForwardResult, WinScenario:g_iScenario)

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
	switch(g_iScenario)
	{
		case TERO_MVP:
		{
			if(g_bIsBombPlanted && IsPlayer(g_iBombPlanter))
			{
				static szName[32]
				get_user_name(g_iBombPlanter, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for planting the bomb", szName)
			}
		}
		case CT_MVP:
		{
			if(g_bIsBombDefused && IsPlayer(g_iBombDefuser))
			{
				static szName[32]
				get_user_name(g_iBombDefuser, szName, charsmax(szName))
				client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for defusing the bomb", szName)
			}
		}
		case KILLER_MVP_TERO:
		{
			CalculateTopKiller(KILLER_MVP_TERO)
			static szName[32]
			get_user_name(g_iTopKiller, szName, charsmax(szName))
			client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for killing %i players", szName, g_iKills[g_iTopKiller])
		}
		case KILLER_MVP_CT:
		{
			CalculateTopKiller(KILLER_MVP_CT)
			static szName[32]
			get_user_name(g_iTopKiller, szName, charsmax(szName))
			client_print_color(0, print_chat, "^1[^4MVP^1] Player of the round: ^3%s^1 for killing %i players", szName, g_iKills[g_iTopKiller])
		}
	}

	ExecuteForward(g_fwScenario, g_iForwardResult, WinScenario:g_iScenario)

	return PLUGIN_CONTINUE
}

public event_twin()
{
	g_iScenario = TERO_MVP
}

public event_ctwin()
{
	g_iScenario = CT_MVP
}
#endif

public bomb_explode(id)
{
	g_iBombPlanter = id
	g_bIsBombPlanted = true
	g_iScenario = TERO_MVP
}

public bomb_defused(id)
{
	g_iBombDefuser = id
	g_bIsBombDefused = true
	g_iScenario = CT_MVP
}

stock CalculateTopKiller(WinScenario:status)
{
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
}

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