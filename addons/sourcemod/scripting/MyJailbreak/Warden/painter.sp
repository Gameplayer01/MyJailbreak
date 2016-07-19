// Laser Pointer module for MyJailbreak - Warden

//Includes
#include <sourcemod>
#include <cstrike>
#include <warden>
#include <colors>
#include <autoexecconfig>
#include <myjailbreak>
#include <lastrequest>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//Defines
#define MAX_BUTTONS 25

//Convars
ConVar gc_bPainter;
ConVar gc_bPainterT;
ConVar gc_sAdminFlagPainter;

//Bools
bool g_bPainterUse[MAXPLAYERS+1] = {false, ...};
bool g_bPainter[MAXPLAYERS+1] = false;
bool g_bPainterT = false;
bool g_bPainterColorRainbow[MAXPLAYERS+1] = true;

//Integers
int g_iPainterColor[MAXPLAYERS+1];

//Strings
char g_sAdminFlagPainter[32];

//Floats
float g_fLastPainter[MAXPLAYERS+1][3];

public void Painter_OnPluginStart()
{
	//Client commands
	RegConsoleCmd("sm_painter", Command_PainterMenu, "Allows Warden to toggle on/off the wardens Painter");
	
	//AutoExecConfig
	gc_bPainter = AutoExecConfig_CreateConVar("sm_warden_painter", "1", "0 - disabled, 1 - enable Warden Painter with +E ", _, true,  0.0, true, 1.0);
	gc_sAdminFlagPainter = AutoExecConfig_CreateConVar("sm_warden_painter_flag", "", "Set flag for admin/vip to get warden painter access. No flag = feature is available for all players!");
	gc_bPainterT= AutoExecConfig_CreateConVar("sm_warden_painter_terror", "1", "0 - disabled, 1 - allow Warden to toggle Painter for Terrorist ", _, true,  0.0, true, 1.0);
	
	//Hooks
	HookConVarChange(gc_sAdminFlagPainter, Painter_OnSettingChanged);
	HookEvent("round_end", Painter_RoundEnd);
	HookEvent("player_team", Painter_PlayerTeam);
	HookEvent("player_death", Painter_PlayerTeam);
	
	//FindConVar
	gc_sAdminFlagLaser.GetString(g_sAdminFlagLaser , sizeof(g_sAdminFlagLaser));
}

public int Painter_OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sAdminFlagPainter)
	{
		strcopy(g_sAdminFlagPainter, sizeof(g_sAdminFlagPainter), newValue);
	}
}

public Action Command_PainterMenu(int client, int args)
{
	if(gc_bPainter.BoolValue && CheckVipFlag(client,g_sAdminFlagPainter))
	{
		if ((IsClientWarden(client)) || ((GetClientTeam(client) == CS_TEAM_T) && g_bPainterT))
		{
			if(CheckVipFlag(client,g_sAdminFlagPainter) || (GetClientTeam(client) == CS_TEAM_T))
			{
				char menuinfo[255];
				
				Menu menu = new Menu(Handler_PainterMenu);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_painter_title", client);
				menu.SetTitle(menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_painter_off", client);
				menu.AddItem("off", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_paintert", client);
				if (GetClientTeam(client) == CS_TEAM_CT) menu.AddItem("terror", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_rainbow", client);
				menu.AddItem("rainbow", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_white", client);
				menu.AddItem("white", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_red", client);
				menu.AddItem("red", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_green", client);
				menu.AddItem("green", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_blue", client);
				menu.AddItem("blue", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_yellow", client);
				menu.AddItem("yellow", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_cyan", client);
				menu.AddItem("cyan", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_magenta", client);
				menu.AddItem("magenta", menuinfo);
				Format(menuinfo, sizeof(menuinfo), "%T", "warden_orange", client);
				menu.AddItem("orange", menuinfo);
				
				menu.ExitBackButton = true;
				menu.ExitButton = true;
				menu.Display(client, 20);
			}
			else CPrintToChat(client, "%t %t", "warden_tag", "warden_vipfeature");
		}
	}
	return Plugin_Handled;
}

public int Handler_PainterMenu(Menu menu, MenuAction action, int client, int selection)
{
if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));
		
		if ( strcmp(info,"off") == 0 ) 
		{
			g_bPainter[client] = false;
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painteroff");
		}
		else if ( strcmp(info,"terror") == 0 ) 
		{
			TogglePainterT(client,0);
		}
		else if ( strcmp(info,"rainbow") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesRainbow);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = true;
			
		}
		else if ( strcmp(info,"white") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesWhite);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 0;
			
		}
		else if ( strcmp(info,"red") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesRed);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 1;
			
		}
		else if ( strcmp(info,"green") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesGreen);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 2;
			
		}
		else if ( strcmp(info,"blue") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesBlue);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 3;
			
		}
		else if ( strcmp(info,"yellow") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesYellow);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 4;
			
		}
		else if ( strcmp(info,"cyan") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesCyan);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 5;
			
		}
		else if ( strcmp(info,"magenta") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesMagenta);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 6;
			
		}
		else if ( strcmp(info,"orange") == 0 ) 
		{
			if(!g_bPainter[client]) CPrintToChat(client, "%t %t", "warden_tag", "warden_painteron");
			CPrintToChat(client, "%t %t", "warden_tag", "warden_painter", g_sColorNamesOrange);
			g_bPainter[client] = true;
			g_bPainterColorRainbow[client] = false;
			g_iPainterColor[client] = 7;
			
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(selection == MenuCancel_ExitBack) 
		{
			FakeClientCommand(client, "sm_menu");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

public Action TogglePainterT(int client, int args)
{
	if (gc_bPainterT.BoolValue) 
	{
		if (IsClientWarden(client))
		{
			if (!g_bPainterT) 
			{
				g_bPainterT = true;
				CPrintToChatAll("%t %t", "warden_tag", "warden_tpainteron");
				
				LoopValidClients(iClient, false, true)
				{
					if (GetClientTeam(iClient) == CS_TEAM_T) Command_PainterMenu(iClient,0);
				}
			}
			else
			{
				LoopValidClients(iClient, false, true)
				{
					if (GetClientTeam(iClient) == CS_TEAM_T)
					{
						g_fLastPainter[iClient][0] = 0.0;
						g_fLastPainter[iClient][1] = 0.0;
						g_fLastPainter[iClient][2] = 0.0;
						g_bPainterUse[iClient] = false;
					}
				}
				g_bPainterT = false;
				CPrintToChatAll("%t %t", "warden_tag", "warden_tpainteroff");
			}
		}
	}
}

public Action Print_Painter(Handle timer)
{
	float g_fPos[3];
	
	for(int Y = 1; Y <= MaxClients; Y++) 
	{
		if(g_bPainterColorRainbow[Y]) g_iPainterColor[Y] = GetRandomInt(0,6);
		if(IsClientInGame(Y) && g_bPainterUse[Y])
		{
			TraceEye(Y, g_fPos);
			if(GetVectorDistance(g_fPos, g_fLastPainter[Y]) > 6.0) {
				Connect_Painter(g_fLastPainter[Y], g_fPos, g_iColors[g_iPainterColor[Y]]);
				g_fLastPainter[Y][0] = g_fPos[0];
				g_fLastPainter[Y][1] = g_fPos[1];
				g_fLastPainter[Y][2] = g_fPos[2];
			}
		}
	}
}

public Action Painter_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if((IsClientWarden(client) && gc_bPainter.BoolValue && g_bPainter[client] && CheckVipFlag(client,g_sAdminFlagPainter)) || ((GetClientTeam(client) == CS_TEAM_T) && gc_bPainter.BoolValue && g_bPainterT))
	{
		for (int i = 0; i < MAX_BUTTONS; i++)
		{
			int button = (1 << i);
			
			if ((buttons & button))
			{
				if (!(g_iLastButtons[client] & button))
				{
					OnButtonPress(client, button);
				}
			}
			else if ((g_iLastButtons[client] & button))
			{
				OnButtonRelease(client, button);
			}
		}
		g_iLastButtons[client] = buttons;
	}
}

stock void OnButtonPress(int client,int button)
{
	if(button == IN_USE)
	{
		TraceEye(client, g_fLastPainter[client]);
		g_bPainterUse[client] = true;
	}
}

stock void OnButtonRelease(int client,int button)
{
	if(button == IN_USE)
	{
		g_fLastPainter[client][0] = 0.0;
		g_fLastPainter[client][1] = 0.0;
		g_fLastPainter[client][2] = 0.0;
		g_bPainterUse[client] = false;
	}
}

public Action Connect_Painter(float start[3], float end[3],int color[4])
{
	TE_SetupBeamPoints(start, end, g_iBeamSprite, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
	TE_SendToAll();
}

public Action TraceEye(int client, float g_fPos[3]) 
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(g_fPos, INVALID_HANDLE);
	return;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

public void Painter_OnMapEnd()
{
	g_bPainterT = false;
	
	LoopClients(i)
	{
		g_fLastPainter[i][0] = 0.0;
		g_fLastPainter[i][1] = 0.0;
		g_fLastPainter[i][2] = 0.0;
		g_bPainterUse[i] = false;
		g_bPainter[i] = false;
		
		if(IsClientWarden(i)) g_bPainterT = false;
		if(g_bPainter[i]) g_bPainter[i] = false;
	}
}

public Action Painter_PlayerTeam(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_fLastPainter[client][0] = 0.0;
	g_fLastPainter[client][1] = 0.0;
	g_fLastPainter[client][2] = 0.0;
	g_bPainterUse[client] = false;
	g_bPainter[client] = false;
	
	g_iLastButtons[client] = 0;
}

public void Painter_OnMapStart()
{
	CreateTimer(0.1, Print_Painter, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_bPainterT = false;
	LoopClients(i) g_bPainter[i] = false;
}

public void Painter_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bPainterT = false;
	LoopClients(i) if(g_bPainter[i]) g_bPainter[i] = false;
}

public void Painter_OnClientPutInServer(int client)
{
	g_bLaserUse[client] = false;
	g_bLaserColorRainbow[client] = true;
}

public void Painter_OnWardenCreation(int client)
{
	g_bLaser = true;
}

public void Painter_OnWardenRemoved(int client)
{
	g_bPainterT = false;
}

public void Painter_OnClientDisconnect(int client)
{
	if(IsClientWarden(client)) g_bPainterT = false;
	g_iLastButtons[client] = 0;
}