//includes
#include <cstrike>
#include <sourcemod>
#include <smartjaildoors>
#include <warden>
#include <emitsoundany>
#include <colors>
#include <autoexecconfig>
#include <myjailbreak>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//Booleans
bool IsTruce;
bool IsDealDamage;
bool StartDealDamage;
bool canSet;

//ConVars    gc_i = global convar integer / gc_i = global convar bool ...
ConVar gc_bPlugin;
ConVar gc_bSetW;
ConVar gc_iCooldownStart;
ConVar gc_bSetA;
ConVar gc_bSpawnCell;
ConVar gc_bVote;
ConVar gc_iCooldownDay;
ConVar gc_iRoundTime;
ConVar gc_iTruceTime;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_bSounds;
ConVar gc_iRounds;
ConVar gc_sSoundStartPath;
ConVar gc_sCustomCommand;
ConVar g_iGetRoundTime;
ConVar gc_bChat;
ConVar gc_bConsole;
ConVar gc_bShowPanel;
ConVar gc_bSpawnRandom;
ConVar gc_sAdminFlag;

//Integers    g_i = global integer
int g_iOldRoundTime;
int g_iCoolDown;
int g_iTruceTime;
int g_iVoteCount;
int g_iRound;
int g_iMaxRound;
int DamageCT;
int DamageT;
int DamageDealed[MAXPLAYERS+1];
int BestT = -1;
int BestCT = -1;
int BestTdamage = 0;
int BestCTdamage = 0;
int BestPlayer = -1;
int TotalDamage = 0;

//Floats    g_i = global float
float g_fPos[3];

//Handles
Handle TruceTimer;
Handle RoundTimer;
Handle DealDamageMenu;
Handle DealDamageEndMenu;

//Strings    g_s = global string
char g_sHasVoted[1500];
char g_sSoundStartPath[256];
char g_sCustomCommand[64];
char g_sEventsLogFile[PLATFORM_MAX_PATH];
char g_sAdminFlag[32];

public Plugin myinfo = {
	name = "MyJailbreak - DealDamage",
	author = "shanapu",
	description = "Event Day for Jailbreak Server",
	version = PLUGIN_VERSION,
	url = URL_LINK
};

public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Warden.phrases");
	LoadTranslations("MyJailbreak.DealDamage.phrases");
	
	//Client Commands
	RegConsoleCmd("sm_setdealdamage", SetDealDamage, "Allows the Admin or Warden to set dealdamage as next round");
	RegConsoleCmd("sm_dealdamage", VoteDealDamage, "Allows players to vote for a dealdamage");
	
	//AutoExecConfig
	AutoExecConfig_SetFile("DealDamage", "MyJailbreak/EventDays");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_dealdamage_version", PLUGIN_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_dealdamage_enable", "1", "0 - disabled, 1 - enable this MyJailbreak SourceMod plugin", _, true,  0.0, true, 1.0);
	gc_sCustomCommand = AutoExecConfig_CreateConVar("sm_dealdamage_cmd", "dd", "Set your custom chat command for Event voting. no need for sm_ or !");
	gc_bSetW = AutoExecConfig_CreateConVar("sm_dealdamage_warden", "1", "0 - disabled, 1 - allow warden to set dealdamage round", _, true,  0.0, true, 1.0);
	gc_bSetA = AutoExecConfig_CreateConVar("sm_dealdamage_admin", "1", "0 - disabled, 1 - allow admin/vip to set dealdamage round", _, true,  0.0, true, 1.0);
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_dealdamage_flag", "g", "Set flag for admin/vip to set this Event Day.");
	gc_bVote = AutoExecConfig_CreateConVar("sm_dealdamage_vote", "1", "0 - disabled, 1 - allow player to vote for dealdamage", _, true,  0.0, true, 1.0);
	gc_bSpawnCell = AutoExecConfig_CreateConVar("sm_dealdamage_spawn", "1", "0 - T teleport to CT spawn, 1 - cell doors auto open", _, true,  0.0, true, 1.0);
	gc_bSpawnRandom = AutoExecConfig_CreateConVar("sm_dealdamage_randomspawn", "1", "0 - disabled, 1 - use random spawns on map (sm_dealdamage_spawn 1)", _, true,  0.0, true, 1.0);
	gc_bShowPanel = AutoExecConfig_CreateConVar("sm_dealdamage_panel", "1", "0 - disabled, 1 - enable show results on a Panel", _, true,  0.0, true, 1.0);
	gc_bChat = AutoExecConfig_CreateConVar("sm_dealdamage_chat", "1", "0 - disabled, 1 - enable print results in chat", _, true,  0.0, true, 1.0);
	gc_bConsole = AutoExecConfig_CreateConVar("sm_dealdamage_console", "1", "0 - disabled, 1 - enable print results in client console", _, true,  0.0, true, 1.0);
	gc_iRounds = AutoExecConfig_CreateConVar("sm_dealdamage_rounds", "2", "Rounds to play in a row", _, true, 1.0);
	gc_iRoundTime = AutoExecConfig_CreateConVar("sm_dealdamage_roundtime", "2", "Round time in minutes for a single dealdamage round", _, true, 1.0);
	gc_iTruceTime = AutoExecConfig_CreateConVar("sm_dealdamage_trucetime", "15", "Time in seconds players can't deal damage", _, true,  0.0);
	gc_iCooldownDay = AutoExecConfig_CreateConVar("sm_dealdamage_cooldown_day", "3", "Rounds cooldown after a event until event can be start again", _, true,  0.0);
	gc_iCooldownStart = AutoExecConfig_CreateConVar("sm_dealdamage_cooldown_start", "3", "Rounds until event can be start after mapchange.", _, true, 0.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_dealdamage_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.1, true, 1.0);
	gc_sSoundStartPath = AutoExecConfig_CreateConVar("sm_dealdamage_sounds_start", "music/MyJailbreak/start.mp3", "Path to the soundfile which should be played for a start.");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_dealdamage_overlays_enable", "1", "0 - disabled, 1 - enable overlays", _, true,  0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_dealdamage_overlays_start", "overlays/MyJailbreak/start" , "Path to the start Overlay DONT TYPE .vmt or .vft");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sSoundStartPath, OnSettingChanged);
	HookConVarChange(gc_sCustomCommand, OnSettingChanged);
	HookConVarChange(gc_sAdminFlag, OnSettingChanged);
	
	//Find
	g_iGetRoundTime = FindConVar("mp_roundtime");
	gc_sOverlayStartPath.GetString(g_sOverlayStart , sizeof(g_sOverlayStart));
	gc_sSoundStartPath.GetString(g_sSoundStartPath, sizeof(g_sSoundStartPath));
	gc_sCustomCommand.GetString(g_sCustomCommand , sizeof(g_sCustomCommand));
	gc_sAdminFlag.GetString(g_sAdminFlag , sizeof(g_sAdminFlag));
	
	SetLogFile(g_sEventsLogFile, "Events");
}

//ConVarChange for Strings

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sOverlayStartPath)    //Add overlay to download and precache table if changed
	{
		strcopy(g_sOverlayStart, sizeof(g_sOverlayStart), newValue);
		if(gc_bOverlays.BoolValue) PrecacheDecalAnyDownload(g_sOverlayStart);
	}
	else if(convar == gc_sAdminFlag)
	{
		strcopy(g_sAdminFlag, sizeof(g_sAdminFlag), newValue);
	}
	else if(convar == gc_sSoundStartPath)    //Add sound to download and precache table if changed
	{
		strcopy(g_sSoundStartPath, sizeof(g_sSoundStartPath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundStartPath);
	}
	else if(convar == gc_sCustomCommand)    //Register the custom command if changed
	{
		strcopy(g_sCustomCommand, sizeof(g_sCustomCommand), newValue);
		char sBufferCMD[64];
		Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
		if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(sBufferCMD, VoteDealDamage, "Allows players to vote for DealDamage");
	}
}

//Initialize Event

public void OnMapStart()
{
	//set default start values
	g_iVoteCount = 0; //how many player voted for the event
	g_iRound = 0;
	IsDealDamage = false;
	StartDealDamage = false;
	canSet = true;
	
	//Precache Sound & Overlay
	if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundStartPath);
	if(gc_bOverlays.BoolValue) PrecacheDecalAnyDownload(g_sOverlayStart);
}

public void OnConfigsExecuted()
{
	//Find Convar Times
	g_iTruceTime = gc_iTruceTime.IntValue;
	g_iCoolDown = gc_iCooldownStart.IntValue + 1;
	g_iMaxRound = gc_iRounds.IntValue;
	
	//Register the custom command
	char sBufferCMD[64];
	Format(sBufferCMD, sizeof(sBufferCMD), "sm_%s", g_sCustomCommand);
	if(GetCommandFlags(sBufferCMD) == INVALID_FCVAR_FLAGS)
		RegConsoleCmd(sBufferCMD, VoteDealDamage, "Allows players to vote for DealDamage");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakedamage);
}

//Admin & Warden set Event

public Action SetDealDamage(int client,int args)
{
	if (gc_bPlugin.BoolValue && canSet) //is plugin enabled?
	{
		if(client == 0)
		{
			StartNextRound();
			if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event Deal Damage was started by groupvoting");
		}
		else if (warden_iswarden(client)) //is player warden?
		{
			if (gc_bSetW.BoolValue) //is warden allowed to set?
			{
				char EventDay[64];
				GetEventDay(EventDay);
				
				if(StrEqual(EventDay, "none", false)) //is an other event running or set?
				{
					if (g_iCoolDown == 0) //is event cooled down?
					{
						StartNextRound(); //prepare Event for next round
						if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event DealDamage was started by warden %L", client);
					}
					else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_wait", g_iCoolDown);
				}
				else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_progress" , EventDay);
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "nocscope_setbywarden");
		}
		else if (CheckVipFlag(client,g_sAdminFlag))//is player admin?
		{
			if (gc_bSetA.BoolValue) //is admin allowed to set?
			{
				char EventDay[64];
				GetEventDay(EventDay);
				
				if(StrEqual(EventDay, "none", false)) //is an other event running or set?
				{
					if (g_iCoolDown == 0) //is event cooled down?
					{
						StartNextRound(); //prepare Event for next round
						if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event DealDamage was started by admin %L", client);
					}
					else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_wait", g_iCoolDown);
				}
				else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_progress" , EventDay);
			}
			else CPrintToChat(client, "%t %t", "nocscope_tag" , "dealdamage_setbyadmin");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
	else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_disabled");
}

//Voting for Event

public Action VoteDealDamage(int client,int args)
{
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	if (gc_bPlugin.BoolValue && canSet) //is plugin enabled?
	{	
		if (gc_bVote.BoolValue) //is voting enabled?
		{	
			char EventDay[64];
			GetEventDay(EventDay);
			
			if(StrEqual(EventDay, "none", false)) //is an other event running or set?
			{
				if (g_iCoolDown == 0) //is event cooled down?
				{
					if (StrContains(g_sHasVoted, steamid, true) == -1) //has player already voted
					{
						int playercount = (GetClientCount(true) / 2);
						g_iVoteCount++;
						int Missing = playercount - g_iVoteCount + 1;
						Format(g_sHasVoted, sizeof(g_sHasVoted), "%s,%s", g_sHasVoted, steamid);
						
						if (g_iVoteCount > playercount) 
						{
							StartNextRound(); //prepare Event for next round
							if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Event DealDamage was started by voting");
						}
						else CPrintToChatAll("%t %t", "dealdamage_tag" , "dealdamage_need", Missing, client);
					}
					else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_voted");
				}
				else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_wait", g_iCoolDown);
			}
			else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_progress" , EventDay);
		}
		else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_voting");
	}
	else CPrintToChat(client, "%t %t", "dealdamage_tag" , "dealdamage_disabled");
}

//Prepare Event

void StartNextRound()
{
	StartDealDamage = true;
	g_iCoolDown = gc_iCooldownDay.IntValue + 1;
	g_iVoteCount = 0;
	
	SetEventDay("dealdamage"); //tell myjailbreak new event is set
	
	if(gc_bSpawnRandom.BoolValue)SetCvar("mp_randomspawn", 1);
	if(gc_bSpawnRandom.BoolValue)SetCvar("mp_randomspawn_los", 1);
	
	CPrintToChatAll("%t %t", "dealdamage_tag" , "dealdamage_next");
	PrintHintTextToAll("%t", "dealdamage_next_nc");
//	LoopClients(i) CreateInfoPanel(i);
}

//Round start

public void RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	canSet = true;
	if (StartDealDamage || IsDealDamage)
	{
		
		
		//disable other plugins
		SetCvar("sm_hosties_lr", 0);
		SetCvar("sm_weapons_enable", 1);
		SetCvar("sm_weapons_t", 1);
		SetCvar("sm_weapons_ct", 1);
		SetCvar("sm_menu_enable", 0);
		SetCvar("sm_warden_enable", 0);
		BestT = 0;
		BestCT = 0;
		BestTdamage = 0;
		BestCTdamage = 0;
		BestPlayer = 0;
		
		float RoundTime = (gc_iRoundTime.FloatValue*60-5);
		RoundTimer = CreateTimer (RoundTime, EndTheRound);
		IsDealDamage = true;
		IsTruce = true;
		
		DamageCT = 0;
		DamageT = 0;
		TotalDamage = 0;
		
		g_iRound++; //Add Round number
		StartDealDamage = false;
		SJD_OpenDoors(); //open Jail
		
		
		
		//Find Position in CT Spawn
		
		int RandomCT = 0;
		
		LoopClients(client)
		{
			if (IsClientInGame(client))
			{
				if (GetClientTeam(client) == CS_TEAM_CT)
				{
					RandomCT = client;
					break;
				}
			}
		}
		if (RandomCT)
		{	
			GetClientAbsOrigin(RandomCT, g_fPos);
			
			g_fPos[2] = g_fPos[2] + 5;
			
			if (g_iRound > 0)
			{
				LoopClients(client)
				{
					//Give Players Start Equiptment & parameters
					
					if (IsClientInGame(client))
					{
						if (GetClientTeam(client) == CS_TEAM_CT && IsValidClient(client, false, false))
						{
							//here start Equiptment & parameters
						}
						if (GetClientTeam(client) == CS_TEAM_T && IsValidClient(client, false, false))
						{
							//here start Equiptment & parameters
						}
						GivePlayerItem(client, "weapon_knife"); //give Knife
						SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true); //NoBlock
						CreateInfoPanel(client);
						SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //disable damage
						if (!gc_bSpawnCell.BoolValue) //spawn Terrors to CT Spawn
						{
							TeleportEntity(client, g_fPos, NULL_VECTOR, NULL_VECTOR);
						}
					}
					DamageDealed[client] = 0;
				}
				//Set Start Timer
				g_iTruceTime--;
				TruceTimer = CreateTimer(1.0, StartTimer, _, TIMER_REPEAT);
				CPrintToChatAll("%t %t", "dealdamage_tag" ,"dealdamage_rounds", g_iRound, g_iMaxRound);
			}
		}
	}
	else
	{
		//If Event isnt running - subtract cooldown round
		
		char EventDay[64];
		GetEventDay(EventDay);
		
		if(!StrEqual(EventDay, "none", false))
		{
			g_iCoolDown = gc_iCooldownDay.IntValue + 1;
		}
		else if (g_iCoolDown > 0) g_iCoolDown--;
	}
}

stock void CreateInfoPanel(int client)
{
	//Create info Panel
	char info[255];
	
	DealDamageMenu = CreatePanel();
	Format(info, sizeof(info), "%T", "dealdamage_info_title",client );
	SetPanelTitle(DealDamageMenu, info);
	DrawPanelText(DealDamageMenu, "                                   ");
	Format(info, sizeof(info), "%T", "dealdamage_info_line1",client );
	DrawPanelText(DealDamageMenu, info);
	DrawPanelText(DealDamageMenu, "-----------------------------------");
	Format(info, sizeof(info), "%T", "dealdamage_info_line2" ,client);
	DrawPanelText(DealDamageMenu, info);
	Format(info, sizeof(info), "%T", "dealdamage_info_line3" ,client);
	DrawPanelText(DealDamageMenu, info);
	Format(info, sizeof(info), "%T", "dealdamage_info_line4" ,client);
	DrawPanelText(DealDamageMenu, info);
	Format(info, sizeof(info), "%T", "dealdamage_info_line5" ,client);
	DrawPanelText(DealDamageMenu, info);
	Format(info, sizeof(info), "%T", "dealdamage_info_line6" ,client);
	DrawPanelText(DealDamageMenu, info);
	Format(info, sizeof(info), "%T", "dealdamage_info_line7" ,client);
	DrawPanelText(DealDamageMenu, info);
	DrawPanelText(DealDamageMenu, "-----------------------------------");
	Format(info, sizeof(info), "%T", "warden_close", client);
	DrawPanelItem(DealDamageMenu, info); 
	SendPanelToClient(DealDamageMenu, client, NullHandler, 20); //open info Panel
}

//Round End

public void RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	canSet = false;
	int winner = GetEventInt(event, "winner");
	
	if (IsDealDamage) //if event was running this round
	{
		LoopClients(client)
		{
			if (IsClientInGame(client)) 
			{
				SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 0, 4, true); //disbale noblock
				
			}
		}
		delete TruceTimer; //kill start time if still running
		delete RoundTimer; //kill start time if still running
		if (winner == 2) PrintHintTextToAll("%t", "dealdamage_twin_nc", DamageT);
		if (winner == 3) PrintHintTextToAll("%t", "dealdamage_ctwin_nc", DamageCT);
		if (g_iRound == g_iMaxRound) //if this was the last round
		{
			//return to default start values
			IsDealDamage = false;
			StartDealDamage = false;
			g_iRound = 0;
			Format(g_sHasVoted, sizeof(g_sHasVoted), "");
			
			//enable other pluigns
			SetCvar("sm_hosties_lr", 1);
			SetCvar("sm_weapons_enable", 1);
			SetCvar("sv_infinite_ammo", 0);
			SetCvar("sm_menu_enable", 1);
			SetCvar("sm_warden_enable", 1);
			SetCvar("sm_weapons_t", 0);
			if(gc_bSpawnRandom.BoolValue)SetCvar("mp_randomspawn", 0);
			if(gc_bSpawnRandom.BoolValue)SetCvar("mp_randomspawn_los", 0);
			
			g_iGetRoundTime.IntValue = g_iOldRoundTime; //return to original round time
			SetEventDay("none"); //tell myjailbreak event is ended
			CPrintToChatAll("%t %t", "dealdamage_tag" , "dealdamage_end");
			
		}
	}
	if (StartDealDamage)
	{
		LoopClients(i) CreateInfoPanel(i);
		g_iOldRoundTime = g_iGetRoundTime.IntValue; //save original round time
		g_iGetRoundTime.IntValue = gc_iRoundTime.IntValue;//set event round time
		
		CPrintToChatAll("%t %t", "dealdamage_tag" , "dealdamage_next");
		PrintHintTextToAll("%t", "dealdamage_next_nc");
	}
}

//Map End

public void OnMapEnd()
{
	//return to default start values
	IsDealDamage = false;
	StartDealDamage = false;
	canSet = true;
	delete TruceTimer; //kill start time if still running
	delete RoundTimer; //kill start time if still running
	g_iVoteCount = 0;
	g_iRound = 0;
	g_sHasVoted[0] = '\0'; 
	SetEventDay("none");
}

//Start Timer

public Action StartTimer(Handle timer)
{
	if (g_iTruceTime > 1) //countdown to start
	{
		g_iTruceTime--;
		LoopClients(client)
		if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				PrintHintText(client,"%t", "dealdamage_timeuntilstart_nc", g_iTruceTime);
			}
		return Plugin_Continue;
	}
	
	g_iTruceTime = gc_iTruceTime.IntValue;
	
	if (g_iRound > 0)
	{
		LoopClients(client)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				PrintHintText(client,"%t", "dealdamage_start_nc");
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			}
			if(gc_bOverlays.BoolValue) CreateTimer( 0.0, ShowOverlayStart, client);
			if(gc_bSounds.BoolValue)
			{
				EmitSoundToAllAny(g_sSoundStartPath);
			}
		}
		CPrintToChatAll("%t %t", "dealdamage_tag" , "dealdamage_start");
	}
	
	TruceTimer = null;
	IsTruce = false;
	
	return Plugin_Stop;
}

public Action OnTakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(victim, true, false) || attacker == victim || !IsValidClient(attacker, true, false) || !IsDealDamage) return Plugin_Continue;
	
	if((GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(victim) == CS_TEAM_T) && !IsTruce)
	{
		DamageCT = DamageCT + RoundToCeil(damage);
	}
	if((GetClientTeam(attacker) == CS_TEAM_T) && (GetClientTeam(victim) == CS_TEAM_CT) && !IsTruce)
	{
		DamageT = DamageT + RoundToCeil(damage);
	}
	LoopClients(i) PrintHintText(i, "<font color='#0055FF'>%t  </font> %i %t                     <font color='#FF0000'>%t   </font> %i %t                    <font color='#00FF00'>%t   </font> %i %t", "dealdamage_ctdealed", DamageCT, "dealdamage_hpdamage", "dealdamage_tdealed", DamageT, "dealdamage_hpdamage", "dealdamage_clientdealed", DamageDealed[i], "dealdamage_hpdamage");
	if((GetClientTeam(attacker) != GetClientTeam(victim))) DamageDealed[attacker] = DamageDealed[attacker] + RoundToCeil(damage);
	return Plugin_Handled;
}

public Action EndTheRound(Handle timer)
{
	if (DamageCT > DamageT) 
	{
		CS_TerminateRound(8.0, CSRoundEnd_CTWin);
		LoopClients(i) if(GetClientTeam(i) == CS_TEAM_T ) ForcePlayerSuicide(i);
	}
	else if(DamageCT < DamageT) 
	{
		CS_TerminateRound(8.0, CSRoundEnd_TerroristWin);
		LoopClients(i) if(GetClientTeam(i) == CS_TEAM_CT ) ForcePlayerSuicide(i);
	}
	else
	{
		CS_TerminateRound(8.0, CSRoundEnd_Draw);
	}
	LoopClients(i)
	{
		if (GetClientTeam(i) == CS_TEAM_CT && (DamageDealed[i] > BestCTdamage))
		{
			BestCTdamage = DamageDealed[i];
			BestCT = i;
		}
		if (GetClientTeam(i) == CS_TEAM_T && (DamageDealed[i] > BestTdamage))
		{
			BestTdamage = DamageDealed[i];
			BestT = i;
		}
	}
	if(BestCTdamage > BestTdamage) BestPlayer = BestCT;
		else BestPlayer = BestT;
	
	TotalDamage = DamageCT + DamageT;
	

	LoopValidClients(client,false,false)
	{
		SendResults(client);
	}
	delete RoundTimer;
	if(MyJBLogging(true)) LogToFileEx(g_sEventsLogFile, "Damage Deal Result: BestCT: %N Dmg: %i BestT: %N Dmg: %i CT Damage: %i T Damage: %i Total Damage: %i", BestCT, BestCTdamage, BestT, BestTdamage, DamageCT, DamageT, TotalDamage);
}

stock void SendResults(int client)
{
	char info[128];
	
	DealDamageEndMenu = CreatePanel();
	Format(info, sizeof(info),"%t", "dealdamage_result");
	SetPanelTitle(DealDamageEndMenu, info);
	Format(info, sizeof(info),"%t %t", "dealdamage_tag" , "dealdamage_result");
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	DrawPanelText(DealDamageEndMenu, "                                   ");
	Format(info, sizeof(info), "%t", "dealdamage_total", TotalDamage);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info), "%t %t", "dealdamage_tag" ,  "dealdamage_total", TotalDamage);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	Format(info, sizeof(info), "%t","dealdamage_most", BestPlayer, DamageDealed[BestPlayer]);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info), "%t %t", "dealdamage_tag" ,  "dealdamage_most", BestPlayer, DamageDealed[BestPlayer]);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	DrawPanelText(DealDamageEndMenu, "                                   ");
	Format(info, sizeof(info),"%t", "dealdamage_ct", DamageCT);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info),"%t %t", "dealdamage_tag" ,  "dealdamage_ct", DamageCT);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	Format(info, sizeof(info), "%t", "dealdamage_t", DamageT);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info), "%t %t", "dealdamage_tag" ,  "dealdamage_ct", DamageT);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	DrawPanelText(DealDamageEndMenu, "                                   ");
	Format(info, sizeof(info),"%t", "dealdamage_bestct", BestCT, BestCTdamage);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info),"%t %t", "dealdamage_tag" ,  "dealdamage_bestct", BestCT, BestCTdamage);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	Format(info, sizeof(info),"%t", "dealdamage_bestt", BestT, BestTdamage);
	DrawPanelText(DealDamageEndMenu, info);
	Format(info, sizeof(info),"%t %t", "dealdamage_tag" , "dealdamage_bestt", BestT, BestTdamage);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	Format(info, sizeof(info),"%t", "dealdamage_client", DamageDealed[client]);
	DrawPanelText(DealDamageEndMenu, info);
	DrawPanelText(DealDamageEndMenu, "                                   ");
	Format(info, sizeof(info),"%t %t", "dealdamage_tag" , "dealdamage_client", DamageDealed[client]);
	if(gc_bChat.BoolValue) CPrintToChat(client, info);
	if(gc_bConsole.BoolValue) PrintToConsole(client, info);
	
	if(gc_bShowPanel.BoolValue) SendPanelToClient(DealDamageEndMenu, client, NullHandler, 20); //open info Panel
}

