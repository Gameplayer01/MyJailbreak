//includes
#include <cstrike>
#include <sourcemod>
#include <smartjaildoors>
#include <warden>
#include <colors>
#include <autoexecconfig>
#include <myjailbreak>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//Booleans
bool IsFreeday; 
bool StartFreeday; 
bool AutoFreeday; 
bool canSet;

//ConVars
ConVar gc_bPlugin;
ConVar gc_bSetW;
ConVar gc_bFirst;
ConVar gc_bAuto;
//ConVar gc_iRespawn;
ConVar gc_bdamage;
ConVar gc_bSetA;
ConVar gc_bVote;
ConVar gc_iCooldownDay;
ConVar gc_iRoundTime;
ConVar g_iGetRoundTime;
ConVar gc_sCustomCommand;
ConVar gc_sAdminFlag;

//Integers
int g_iOldRoundTime;
int g_iCoolDown;
int g_iVoteCount;
int FreedayRound = 0;

//Handles
Handle FreedayMenu;

//Strings
char g_sHasVoted[1500];
char g_sCustomCommand[64];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sAdminFlag[32];

public Plugin myinfo =
{
	name = "MyJailbreak - Freeday",
	author = "shanapu",
	description = "Event Day for Jailbreak Server",
	version = PLUGIN_VERSION,
	url = URL_LINK
};

public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Warden.phrases");
	LoadTranslations("MyJailbreak.FreeDay.phrases");
	
	//Client Commands
	RegConsoleCmd("sm_setfreeday", SetFreeday, "Allows the Admin or Warden to set freeday as next round");
	RegConsoleCmd("sm_freeday", VoteFreeday, "Allows players to vote for a freeday");

	
	//AutoExecConfig
	AutoExecConfig_SetFile("Freeday", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_freeday_version", PLUGIN_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_freeday_enable", "1", "0 - disabled, 1 - enable this MyJailbreak SourceMod plugin", _, true,  0.0, true, 1.0);
	gc_sCustomCommand = AutoExecConfig_CreateConVar("sm_freeday_cmd", "fd", "Set your custom chat command for Event voting. no need for sm_ or !");
	gc_bSetW = AutoExecConfig_CreateConVar("sm_freeday_warden", "1", "0 - disabled, 1 - allow warden to set freeday round", _, true,  0.0, true, 1.0);
	gc_bSetA = AutoExecConfig_CreateConVar("sm_freeday_admin", "1", "0 - disabled, 1 - allow admin/vip to set freeday round", _, true,  0.0, true, 1.0);
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_freeday_flag", "g", "Set flag for admin/vip to set this Event Day.");
	gc_bVote = AutoExecConfig_CreateConVar("sm_freeday_vote", "1", "0 - disabled, 1 - allow player to vote for freeday", _, true,  0.0, true, 1.0);
	gc_bAuto = AutoExecConfig_CreateConVar("sm_freeday_noct", "1", "0 - disabled, 1 - auto freeday when there is no CT", _, true,  0.0, true, 1.0);
//	gc_iRespawn = AutoExecConfig_CreateConVar("sm_freeday_respawn", "1", "1 - respawn on NoCT Freeday / 2 - respawn on firstround/vote/set Freeday / 3 - Both", _, true,  0.0, true, 1.0);
	gc_bFirst = AutoExecConfig_CreateConVar("sm_freeday_firstround", "1", "0 - disabled, 1 - auto freeday first round after mapstart", _, true,  0.0, true, 1.0);
	gc_bdamage = AutoExecConfig_CreateConVar("sm_freeday_damage", "1", "0 - disabled, 1 - enable damage on freedays", _, true,  0.0, true, 1.0);
	gc_iRoundTime = AutoExecConfig_CreateConVar("sm_freeday_roundtime", "5", "Round time in minutes for a single freeday round", _, true,  1.0);
	gc_iCooldownDay = AutoExecConfig_CreateConVar("sm_freeday_cooldown_day", "0", "Rounds until freeday can be started again.", _, true,  0.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
//	HookEvent("player_death", PlayerDeath);
	HookConVarChange(gc_sCustomCommand, OnSettingChanged);
	HookConVarChange(gc_sAdminFlag, OnSettingChanged);
	
	//FindConVar
	g_iGetRoundTime = FindConVar("mp_roundtime");
	g_iCoolDown = gc_iCooldownDay.IntValue + 1;
	gc_sCustomCommand.GetString(g_sCustomCommand , sizeof(g_sCustomCommand));
	gc_sAdminFlag.GetString(g_sAdminFlag , sizeof(g_sAdminFlag));
	
	SetLogFile(g_sEventsLogFile, "Events");
}

//ConVarChange for Strings

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sCustomCommand)
	{
		strcopy(g_sCustomCommand, sizeof(g_sCustomCommand), newValue);
		char sBufferCMD[64];
		Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
		if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(sBufferCMD, VoteFreeday, "Allows players to vote for a freeday");
	}
	else if(convar == gc_sAdminFlag)
	{
		strcopy(g_sAdminFlag, sizeof(g_sAdminFlag), newValue);
	}
}
//Initialize Event

public void OnConfigsExecuted()
{
	char sBufferCMD[64];
	Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
	if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)
		RegConsoleCmd(sBufferCMD, VoteFreeday, "Allows players to vote for a catch freeday");
}

public void OnMapStart()
{
	g_iVoteCount = 0;
	FreedayRound = 0;
	
	if (gc_bFirst.BoolValue)
	{
		StartFreeday = true;
		SetEventDay("freeday");
	}
	else
	{
		StartFreeday = false;	
	}
	IsFreeday = false;
	AutoFreeday = false;
	canSet = true;
}

//Admin & Warden set Event

public Action SetFreeday(int client,int args)
{
	if (gc_bPlugin.BoolValue && canSet)
	{
		if(client == 0)
		{
			StartNextRound();
			if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event FreeDay was started by groupvoting");
		}
		else if (warden_iswarden(client))
		{
			if (gc_bSetW.BoolValue)
			{
				char EventDay[64];
				GetEventDay(EventDay);
				
				if(StrEqual(EventDay, "none", false))
				{
					if (g_iCoolDown == 0)
					{
						StartNextRound();
						if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event Freeday was started by warden %L", client);
					}
					else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_wait", g_iCoolDown);
				}
				else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_progress" , EventDay);
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "freeday_setbywarden");
		}
		else if (CheckVipFlag(client,g_sAdminFlag))
		{
			if (gc_bSetA.BoolValue)
			{
				char EventDay[64];
				GetEventDay(EventDay);
				
				if(StrEqual(EventDay, "none", false))
				{
					if (g_iCoolDown == 0)
					{
						StartNextRound();
						if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event Freeday was started by admin %L", client);
					}
					else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_wait", g_iCoolDown);
				}
				else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_progress" , EventDay);
			}
			else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_setbyadmin");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
	else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_disabled");
}

//Voting for Event

public Action VoteFreeday(int client,int args)
{
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	if (gc_bPlugin.BoolValue && canSet)
	{	
		if (gc_bVote.BoolValue)
		{
			char EventDay[64];
			GetEventDay(EventDay);
			
			if(StrEqual(EventDay, "none", false))
			{
				if (g_iCoolDown == 0)
				{
					if (StrContains(g_sHasVoted, steamid, true) == -1)
					{
						int playercount = (GetClientCount(true) / 2);
						g_iVoteCount++;
						int Missing = playercount - g_iVoteCount + 1;
						Format(g_sHasVoted, sizeof(g_sHasVoted), "%s,%s", g_sHasVoted, steamid);
						
						if (g_iVoteCount > playercount)
						{
							StartNextRound();
							if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event freeday was started by voting");
						}
						else CPrintToChatAll("%t %t", "freeday_tag" , "freeday_need", Missing, client);
					}
					else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_voted");
				}
				else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_wait", g_iCoolDown);
			}
			else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_progress" , EventDay);
		}
		else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_voting");
	}
	else CPrintToChat(client, "%t %t", "freeday_tag" , "freeday_disabled");
}

//Prepare Event

void StartNextRound()
{
	StartFreeday = true;
	g_iCoolDown = gc_iCooldownDay.IntValue + 1;
	g_iVoteCount = 0;
	SetEventDay("freeday");
	
	CPrintToChatAll("%t %t", "freeday_tag" , "freeday_next");
	PrintHintTextToAll("%t", "freeday_next_nc");
}

/*
public void PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if((AutoFreeday && gc_iRespawn.IntValue == 1) || (IsFreeday && gc_iRespawn.IntValue == 2) || ((IsFreeday || AutoFreeday) && gc_iRespawn.IntValue == 3))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
		
		CS_RespawnPlayer(client);
	}
}
*/

//Round start

public void RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	canSet = true;
	if ((GetTeamClientCount(CS_TEAM_CT) < 1) && gc_bAuto.BoolValue)
	{
		char EventDay[64];
		GetEventDay(EventDay);
		
		if(StrEqual(EventDay, "none", false))
		{
			StartFreeday = true;
			g_iCoolDown = gc_iCooldownDay.IntValue + 1;
			g_iVoteCount = 0;
			SetEventDay("freeday");
			AutoFreeday = true;
		}
	}
	if (StartFreeday)
	{
		SetCvar("sm_hosties_lr", 0);
		SetCvar("sm_weapons_enable", 0);
		SetCvar("sm_weapons_t", 0);
		SetCvar("sm_warden_enable", 0);
		IsFreeday = true;
		FreedayRound++;
		StartFreeday = false;
		SJD_OpenDoors();
		
		LoopClients(client)
		{
			CreateInfoPanel(client);
			
			if (!gc_bdamage.BoolValue && IsValidClient(client))
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			}
			if (IsPlayerAlive(client)) 
			{
				PrintHintText(client,"%t", "freeday_start_nc");
				}
			}
		CPrintToChatAll("%t %t", "freeday_tag" , "freeday_start");
	}
	else
	{
		if (g_iCoolDown > 0) g_iCoolDown--;
	}
}

stock void CreateInfoPanel(int client)
{
	//Create info Panel
	char info[255];

	FreedayMenu = CreatePanel();
	Format(info, sizeof(info), "%T", "freeday_info_title", client);
	SetPanelTitle(FreedayMenu, info);
	DrawPanelText(FreedayMenu, "                                   ");
	Format(info, sizeof(info), "%T", "freeday_info_line1", client);
	DrawPanelText(FreedayMenu, info);
	DrawPanelText(FreedayMenu, "-----------------------------------");
	Format(info, sizeof(info), "%T", "freeday_info_line2", client);
	DrawPanelText(FreedayMenu, info);
	Format(info, sizeof(info), "%T", "freeday_info_line3", client);
	DrawPanelText(FreedayMenu, info);
	Format(info, sizeof(info), "%T", "freeday_info_line4", client);
	DrawPanelText(FreedayMenu, info);
	Format(info, sizeof(info), "%T", "freeday_info_line5", client);
	DrawPanelText(FreedayMenu, info);
	Format(info, sizeof(info), "%T", "freeday_info_line6", client);
	DrawPanelText(FreedayMenu, info);
	Format(info, sizeof(info), "%T", "freeday_info_line7", client);
	DrawPanelText(FreedayMenu, info);
	DrawPanelText(FreedayMenu, "-----------------------------------");
	Format(info, sizeof(info), "%T", "warden_close", client);
	DrawPanelItem(FreedayMenu, info); 
	SendPanelToClient(FreedayMenu, client, NullHandler, 20);
}
//Round End

public void RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	canSet = false;
	if (IsFreeday)
	{
		IsFreeday = false;
		StartFreeday = false;
		FreedayRound = 0;
		Format(g_sHasVoted, sizeof(g_sHasVoted), "");
		SetCvar("sm_hosties_lr", 1);
		SetCvar("sm_weapons_enable", 1);
		SetCvar("mp_teammates_are_enemies", 0);
		SetCvar("sm_warden_enable", 1);
		if(!AutoFreeday) g_iGetRoundTime.IntValue = g_iOldRoundTime;
		AutoFreeday = false;
		SetEventDay("none");
		CPrintToChatAll("%t %t", "freeday_tag" , "freeday_end");
	}
	if (StartFreeday)
	{
		LoopClients(i) CreateInfoPanel(i);
		g_iOldRoundTime = g_iGetRoundTime.IntValue;
		g_iGetRoundTime.IntValue = gc_iRoundTime.IntValue;
		
		CPrintToChatAll("%t %t", "freeday_tag" , "freeday_next");
		PrintHintTextToAll("%t", "freeday_next_nc");
	}
}

//Map End

public void OnMapEnd()
{
	if (gc_bFirst.BoolValue)
	{
		StartFreeday = true;
	}
	else
	{
		StartFreeday = false;
	}
	IsFreeday = false;
	AutoFreeday = false;
	canSet = true;
	g_iVoteCount = 0;
	FreedayRound = 0;
	g_sHasVoted[0] = '\0';
	SetEventDay("none");
}