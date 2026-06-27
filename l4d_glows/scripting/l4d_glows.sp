#define PLUGIN_VERSION "customize 4.4"

/**
 * l4d_glows
 * Copyright (C) 2026 Mr.Creamy
 *
 * Originally designed by RIKO and edited by vℓα∂ιмιr.
 *
 * => LICENSE:
 * Respecting the rights of the original author and editor.
 * This derivative work is distributed under the: <GNU General Public License>.
 *
 * => THANKS:
 *
 *		- [L4D2] Glow Survivor			v.(9.9.9v)
 *			Authors :	King_OXO, valedar(rework and fix) y BloodyBlade(Edited)
 *			Url		:	https://github.com/BloodyBlade/L4D2-Plugins/blob/main/l4d2_glow_menu().sp
 *
 *		- [L4D2] Rainbow Flashlight		v.(1.1.0)
 *			Authors :	King_OXO
 *			Url		:	https://forums.alliedmods.net/showthread.php?t=281620
 *
 *	The following project was developed in the hope that it will be useful...
 *
*/

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#define CVAR_FLAGS						FCVAR_NOTIFY

native int LMC_GetClientOverlayModel(int client);
native int Hats_GetHatEntity(int client);

bool g_bLMC_Available = false;
bool g_bHats_Available = false;

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
	{
		g_bLMC_Available = true;
	}

	if (strcmp(sName, "l4d_hats", true) == 0)
	{
		g_bHats_Available = true;
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
	{
		g_bLMC_Available = false;
	}

	if (strcmp(sName, "l4d_hats", true) == 0)
	{
		g_bHats_Available = false;
	}
}

int g_clientItem[MAXPLAYERS+1];
int g_iGlowColor[MAXPLAYERS+1][4];
int g_iLightRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int g_iRainbowLightRef[MAXPLAYERS+1];

char classname[64];

Handle g_hGlowsMenu;
Handle g_hCookie;
Handle g_hKeyValues;

bool g_bEventsHooked;

ConVar g_hCvar_GlowsPluginEnable, g_hCvar_GlowsType, g_hCvar_GlowsRange, g_hCvar_GlowsMin, g_hCvar_GlowsFlashing;
static ConVar g_hCvar_GlowsThirdPersonTime = null;
int g_iGlowsType, g_iGlowsRange, g_iGlowsMin;
bool g_bGlowsPluginEnable, g_bGlowsFlash;
static float g_fGlowsThirdPersonTime = 2.0;

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									PLUGIN INFO
// ╘══════════════════════════════════════════════════════════════════════════════╛

public Plugin myinfo = 
{
	name		= "[L4D.1&2] Flashlight + Glows + Disco",
	author		= "R1KO (edited by vℓα∂ιмιr, Mr.Creamy)",
	description	= "Flashlight + Glows + Disco",
	version		= PLUGIN_VERSION,
	url			= "vℓα∂ιмιr#4284"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports \"Left 4 Dead 1 and 2\"");
		return APLRes_SilentFailure;
	}

	// ADDITIONAL NATIVES
	// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	MarkNativeAsOptional("Hats_GetHatEntity");

	return APLRes_Success;
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									PLUGIN START
// ╘══════════════════════════════════════════════════════════════════════════════╛

public void OnPluginStart()
{
	LoadTranslations("l4d_glows.phrases");

	CreateConVar("l4d_glows_version", PLUGIN_VERSION, "Glows Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvar_GlowsPluginEnable = CreateConVar("l4d_glows_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_GlowsType = CreateConVar("l4d_glows_type", "3", "TYPE of Glow on the client.\n0 = NONE, 1 = ON USE, 2 = ON LOOK AT, 3 = CONSTANT", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_hCvar_GlowsRange = CreateConVar("l4d_glows_range_max", "1500", "Range MAX of Glow on the client.\n0 = OFF", CVAR_FLAGS, true, 0.0);
	g_hCvar_GlowsMin = CreateConVar("l4d_glows_range_min", "0", "Range MIN of Glow on the client.\n0 = OFF", CVAR_FLAGS, true, 0.0);
	g_hCvar_GlowsFlashing = CreateConVar("l4d_glows_flashing", "0", "Enable/Disable Glow Flash on the client.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_GlowsThirdPersonTime = CreateConVar("l4d_glows_thirdperson_time", "1.0", "Duration in Thirdperson when choosing an option.\n0.5 <= OFF", CVAR_FLAGS, true, 0.0, true, 360.0);

	g_hCvar_GlowsPluginEnable.AddChangeHook(OnConVarChanged);
	g_hCvar_GlowsType.AddChangeHook(OnConVarChanged);
	g_hCvar_GlowsRange.AddChangeHook(OnConVarChanged);
	g_hCvar_GlowsMin.AddChangeHook(OnConVarChanged);
	g_hCvar_GlowsFlashing.AddChangeHook(OnConVarChanged);
	g_hCvar_GlowsThirdPersonTime.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "l4d_glows");
	ApplyCvars();

	g_hCookie = RegClientCookie("l4d_glows", "l4d_glows Cookies", CookieAccess_Private);

	g_hGlowsMenu = CreateMenu(AuraMenuHandler, MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hGlowsMenu, false);

	RegConsoleCmd("sm_aura", CmdOpenGlowMenu);
	RegConsoleCmd("sm_light", CmdOpenGlowMenu);
	RegConsoleCmd("sm_glow", CmdOpenGlowMenu);
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									CVARS
// ╘══════════════════════════════════════════════════════════════════════════════╛

public void OnConfigsExecuted()
{
	ApplyCvars();
	HookEvents();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyCvars();
	HookEvents();
}

void ApplyCvars()
{
	g_bGlowsPluginEnable = g_hCvar_GlowsPluginEnable.BoolValue;
	g_iGlowsType = g_hCvar_GlowsType.IntValue;
	g_iGlowsRange = g_hCvar_GlowsRange.IntValue;
	g_iGlowsMin = g_hCvar_GlowsMin.IntValue;
	g_bGlowsFlash = g_hCvar_GlowsFlashing.BoolValue;
	g_fGlowsThirdPersonTime = g_hCvar_GlowsThirdPersonTime.FloatValue;
}

void HookEvents()
{
	if(g_bGlowsPluginEnable && !g_bEventsHooked)
	{
		g_bEventsHooked = true;

		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_team", Event_PlayerDeath);
		HookEvent("heal_success", Event_HealSuccess);

		return;
	}

	if(!g_bGlowsPluginEnable && g_bEventsHooked)
	{
		g_bEventsHooked = false;

		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("player_team", Event_PlayerDeath);
		UnhookEvent("heal_success", Event_HealSuccess);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				RemoveAllEfects(i);
			}
		}

		return;
	}
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									COOKIES
// ╘══════════════════════════════════════════════════════════════════════════════╛

public void OnClientCookiesCached(int client)
{
	if (!g_bEventsHooked) return;

	char sColor[64];
	GetClientCookie(client, g_hCookie, sColor, 64);
	if(sColor[0] == 0 || LoadClientColor(client, sColor) == false)
	{
		g_clientItem[client] = 0;
		GetMenuItem(g_hGlowsMenu, g_clientItem[client], sColor, 64);
		SetClientCookie(client, g_hCookie, sColor);
		LoadClientColor(client, sColor);
	}
	else {
		g_clientItem[client] = UTIL_GetItemIndex(sColor);
	}
}

bool LoadClientColor(int client, const char[] sColor)
{
	KvRewind(g_hKeyValues);
	if (KvJumpToKey(g_hKeyValues, "Colors"))
	{
		char sBuffer[64];
		KvGetString(g_hKeyValues, sColor, sBuffer, sizeof(sBuffer));

		KvGetColor(g_hKeyValues, sColor, g_iGlowColor[client][0], g_iGlowColor[client][1], g_iGlowColor[client][2], g_iGlowColor[client][3]);

		KvRewind(g_hKeyValues);
		return true;
	}
	return false;
}

int UTIL_GetItemIndex(const char[] sItemInfo)
{
	char sColor[64], i, iSize;
	iSize = GetMenuItemCount(g_hGlowsMenu);
	for (i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hGlowsMenu, i, sColor, sizeof(sColor));
		if(strcmp(sColor, sItemInfo) == 0)
			return i;
	}
	return -1;
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									MAP START
// ╘══════════════════════════════════════════════════════════════════════════════╛

public void OnMapStart()
{
	RemoveAllMenuItems(g_hGlowsMenu);

	if (g_hKeyValues != INVALID_HANDLE)
		CloseHandle(g_hKeyValues);

	g_hKeyValues = CreateKeyValues("Glow_Colors");

	if (FileToKeyValues(g_hKeyValues, "addons/sourcemod/data/l4d_glows.ini") == false)
	{
		CloseHandle(g_hKeyValues);
		g_hKeyValues = INVALID_HANDLE;
		SetFailState("Couldn't parse file \"addons/sourcemod/data/l4d_glows.ini\"");
	}

	KvRewind(g_hKeyValues);

	if (KvJumpToKey(g_hKeyValues, "Colors") && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		char sColor[64];
		do
		{
			if (KvGetSectionName(g_hKeyValues, sColor, sizeof(sColor)))
				AddMenuItem(g_hGlowsMenu, sColor, sColor);
		}
		while (KvGotoNextKey(g_hKeyValues, false));
	}

	KvRewind(g_hKeyValues);
}

public Action CmdOpenGlowMenu(int client, int args)
{
	if (!g_bEventsHooked)
	{
		CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Disabled");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Only_Alive");
		return Plugin_Handled;
	}

	DisplayMenu(g_hGlowsMenu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int AuraMenuHandler(Handle menu, MenuAction action, int client, int id)
{
	switch(action)
	{
		case MenuAction_Display:
		{
            char sBuffer[255];
            FormatEx(sBuffer, sizeof(sBuffer), "%T", "VIP_Feature_Title_Menu", client);
            SetPanelTitle(view_as<Handle>(id), sBuffer);
		}
		case MenuAction_Select:
		{
			char sColor[64];
			GetMenuItem(menu, id, sColor, sizeof(sColor));
			g_clientItem[client] = id;

			if (LoadClientColor(client, sColor))
			{
				if (!g_bEventsHooked)
				{
					CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Disabled");
					return 0;
				}

				if (!IsPlayerAlive(client))
				{
					CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Only_Alive");
					return 0;
				}

				if (GetClientTeam(client) != 2)
				{
					CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Only_Survivors");
					return 0;
				}

				ThirdpersonView(client);
				SetAura(client);
				SetClientCookie(client, g_hCookie, sColor);

				if (IsDisableAura(g_iGlowColor[client]))
				{
					CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Off");
				}
				else {
					CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Choise", sColor);
				}
			}
			else
			{
				CPrintToChat(client, "%t%t", "VIP_Feature_Prefix", "VIP_Feature_Error", sColor);
			}

			DisplayMenuAtItem(g_hGlowsMenu, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			if (g_clientItem[client] == id)
			{
				char sColorName[64];
				GetMenuItem(menu, id, sColorName, sizeof(sColorName));

				Format(sColorName, sizeof(sColorName), "%s [X]", sColorName);

				return RedrawMenuItem(sColorName);
			}
		}
	}
	return 0;
}

// Third Person Function
void ThirdpersonView(int client)
{
	if (g_fGlowsThirdPersonTime < 0.5)
		return;

	if (GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") != 99999.3)
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + g_fGlowsThirdPersonTime);
	}
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									EVENTS
// ╘══════════════════════════════════════════════════════════════════════════════╛

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (!IsValidAliveSurv(client) || g_clientItem[client] == 0)
	{
		return;
	}

	CreateTimer(2.5, Timer_SetAura, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client) || g_clientItem[client] == 0)
	{
		return;
	}

	RemoveAllEfects(client);
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("subject");
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client) || g_clientItem[client] == 0)
	{
		return;
	}

	CreateTimer(0.5, Timer_SetAura, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetAura(Handle timer, any client)
{
	if (!g_bEventsHooked)
	{
		return Plugin_Stop;
	}

	client = GetClientOfUserId(client);
	if (IsValidAliveSurv(client))
	{
		if (g_clientItem[client] > 0)
		{
			SetAura(client);
		}
	}

	return Plugin_Stop;
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									SET GLOW
// ╘══════════════════════════════════════════════════════════════════════════════╛

void SetAura(int client)
{
	if (IsDisableAura(g_iGlowColor[client]))
	{
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		RemoveAllEfects(client);
	}
    else if (IsEnableRainbow(g_iGlowColor[client]))
	{
		RemoveAllEfects(client);
		SetRainbowPlayer(client);
	}
	else
	{
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		RemoveAllEfects(client);

		if (g_bLMC_Available)
		{
			int entity = LMC_GetClientOverlayModel(client);
			if (entity > MaxClients) SetGlow(entity, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
			else SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
		}
		else SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);

		if (g_bHats_Available)
		{
			int entity = Hats_GetHatEntity(client);
			if (entity > MaxClients) SetGlow(entity, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
		}

		for (int i = 1; i < 2048; i++)
		{
			if (IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client)
			{
				GetEdictClassname(i, classname, sizeof(classname));
				if (StrEqual(classname, "prop_dynamic", false))
				{
					SetGlow(i, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
				}
			}
		}

		SetLight(client, g_iGlowColor[client][0], g_iGlowColor[client][1], g_iGlowColor[client][2], g_iGlowColor[client][3]);
    }
}

stock bool IsDisableAura(int color[4])
{
    return (color[0] == 0 && color[1] == 0 && color[2] == 0);
}

stock bool IsEnableRainbow(int color[4])
{
    return (color[0] == 1 && color[1] == 1 && color[2] == 1);
}

void SetRainbowPlayer(int client)
{
	int light = CreateEntityByName("light_dynamic");
	if (!IsValidEntity(light))
	{
		g_iRainbowLightRef[client] = 0;
		return;
	}

	DispatchKeyValue(light, "brightness", "2");

	DispatchKeyValue(light, "spotlight_radius", "35.0");

	DispatchKeyValue(light, "distance", "255");
	DispatchKeyValue(light, "style", "0");

	SetEntPropEnt(light, Prop_Send, "m_hOwnerEntity", client);

	if (DispatchSpawn(light))
	{
		AcceptEntityInput(light, "TurnOn");

		SetVariantString("!activator");
		AcceptEntityInput(light, "SetParent", client);

		TeleportEntity(light, view_as<float>({ 0.0, 0.0, 10.0 }), NULL_VECTOR, NULL_VECTOR);

		SDKHook(light, SDKHook_SetTransmit, OnTransmit);
		SDKHook(client, SDKHook_PreThinkPost, RainbowPlayer);
		
		g_iRainbowLightRef[client] = light; 
	}
	else
	{
		AcceptEntityInput(light, "Kill");
		g_iRainbowLightRef[client] = 0;
	}
}

public Action OnTransmit(int entity, int client)
{
	if (g_iRainbowLightRef[client] == entity)
	{
		return Plugin_Continue;
	}

	static int owner, team;

	if ((owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) > 0 && 
		(team = GetClientTeam(client)) > 1
		 && GetClientTeam(owner) != team)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action RainbowPlayer(int client)
{
	if (!g_bEventsHooked || !IsValidAliveSurv(client))
	{
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	}

	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 1) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 3) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 5) * 127.5 + 127.5);

	if (g_bLMC_Available)
	{
		int entity = LMC_GetClientOverlayModel(client);
		if (entity > MaxClients) SetGlow(entity, color[0] + (color[1] * 256) + (color[2] * 65536), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
		else SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
	}
	else SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);

	if (g_bHats_Available)
	{
		int entity = Hats_GetHatEntity(client);
		if (entity > MaxClients) SetGlow(entity, color[0] + (color[1] * 256) + (color[2] * 65536), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
	}

	for (int i = 1; i < 2048; i++)
	{
		if (IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client)
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if (StrEqual(classname, "prop_dynamic", false))
			{
				SetGlow(i, color[0] + (color[1] * 256) + (color[2] * 65536), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
			}
		}
	}

	int lightEntity = g_iRainbowLightRef[client];

	// We verify that this entity of light actually exists on the server before touching it.
	if (lightEntity > MaxClients && IsValidEntity(lightEntity)) 
	{
		char sBuffer[16];
		FormatEx(sBuffer, sizeof(sBuffer), "%i %i %i %i", GetRandomColor(color[2]), GetRandomColor(color[1]), GetRandomColor(color[0]), g_iGlowColor[client][3]);
		// CORRECTION: We applied the DispatchKeyValue to the variable we just validated
		DispatchKeyValue(lightEntity, "_light", sBuffer);
	}

	return Plugin_Handled;
}

stock int GetRandomColor(int color)
{
	return (color == -1 || color < 0 || color > 255) ? GetRandomInt(0, 255) : color;
}

void RemoveAura(int client)
{
	if (g_bLMC_Available)
	{
		int entity = LMC_GetClientOverlayModel(client);
		if (entity > MaxClients) SetGlow(entity, 0, 0, 0, 0, 0);
		else SetGlow(client, 0, 0, 0, 0, 0);
	}
	else SetGlow(client, 0, 0, 0, 0, 0);

	if (g_bHats_Available)
	{
		int entity = Hats_GetHatEntity(client);
		if (entity > MaxClients) SetGlow(entity, 0, 0, 0, 0, 0);
	}

	for (int i = 1; i < 2048; i++)
	{
		if (IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client)
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if (StrEqual(classname, "prop_dynamic", false))
			{
				SetGlow(i, 0, 0, 0, 0, 0);
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
}

void SetGlow(int entity, int color, int type, int range, int min, bool flash)
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", min);
	SetEntProp(entity, Prop_Send, "m_bFlashing", flash);
}

void RemoveLight(int client)
{
	int light = EntRefToEntIndex(g_iLightRef[client]);
	if (light != INVALID_ENT_REFERENCE && IsValidEntity(light))
	{
		AcceptEntityInput(light, "TurnOff"); 
		AcceptEntityInput(light, "Kill");
	}
	g_iLightRef[client] = INVALID_ENT_REFERENCE;
	
	if (g_iRainbowLightRef[client] && IsValidEdict(g_iRainbowLightRef[client]))
	{
		AcceptEntityInput(g_iRainbowLightRef[client], "TurnOff");
		AcceptEntityInput(g_iRainbowLightRef[client], "Kill");
		SDKUnhook(client, SDKHook_PreThinkPost, RainbowPlayer);
	}
	g_iRainbowLightRef[client] = 0;
}

void SetLight(int client, int r, int g, int b, int alpha)
{
	int light = CreateEntityByName("light_dynamic");
	if (!IsValidEntity(light))
	{
		return;
	}

	char sBuffer[16];
	FormatEx(sBuffer, sizeof(sBuffer), "%i %i %i %i", r, g, b, alpha);
	DispatchKeyValue(light, "_light", sBuffer);

	DispatchKeyValue(light, "brightness", "2");

	DispatchKeyValue(light, "spotlight_radius", "35.0");

	DispatchKeyValue(light, "distance", "255");
	DispatchKeyValue(light, "style", "0");

	if (DispatchSpawn(light))
	{
		AcceptEntityInput(light, "TurnOn");

		SetVariantString("!activator");
		AcceptEntityInput(light, "SetParent", client);

		TeleportEntity(light, view_as<float>({ 0.0, 0.0, 10.0 }), NULL_VECTOR, NULL_VECTOR);

		g_iLightRef[client] = EntIndexToEntRef(light);
	}
}

void RemoveAllEfects(int client)
{
	RemoveAura(client);
	RemoveLight(client);
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									CALL FORWARDS
// ╘══════════════════════════════════════════════════════════════════════════════╛

public void LMC_OnClientModelApplied(int client, int entity, const char model[PLATFORM_MAX_PATH], bool baseReattach)
{
	if (!g_bEventsHooked || !IsValidAliveSurv(client) || g_clientItem[client] == 0)
	{
		return;
	}

	SetGlow
	(
			entity, 
			GetEntProp(client, Prop_Send, "m_glowColorOverride", 0), 
			GetEntProp(client, Prop_Send, "m_iGlowType", 0), 
			GetEntProp(client, Prop_Send, "m_nGlowRange", 0), 
			GetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0),
			GetEntProp(entity, Prop_Send, "m_bFlashing", 0)
	);

	SetGlow(client, 0, 0, 0, 0, 0);
}

public void LMC_OnClientModelDestroyed(int client, int entity)
{
	if (!g_bEventsHooked || !IsValidAliveSurv(client) || !IsValidEntity(entity) || g_clientItem[client] == 0)
	{
		return;
	}

	SetGlow
	(
			client, 
			GetEntProp(entity, Prop_Send, "m_glowColorOverride", 0), 
			GetEntProp(entity, Prop_Send, "m_iGlowType", 0), 
			GetEntProp(entity, Prop_Send, "m_nGlowRange", 0), 
			GetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0),
			GetEntProp(entity, Prop_Send, "m_bFlashing", 0)
	);
}

public void Hats_OnHatCreated(int client, int entity, const char model[PLATFORM_MAX_PATH])
{
	if (!g_bEventsHooked || !IsValidAliveSurv(client) || g_clientItem[client] == 0)
	{
		return;
	}

	SetGlow(entity, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
}

public void Hats_OnHatKilled(int client, int entity)
{
	if (!g_bEventsHooked || !IsValidAliveSurv(client) || !IsValidEntity(entity) || g_clientItem[client] == 0)
	{
		return;
	}

	if (g_bLMC_Available)
	{
		int lmcentity = LMC_GetClientOverlayModel(client);
		if (lmcentity > MaxClients) SetGlow(lmcentity, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
		else SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
	}
	else SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), g_iGlowsType, g_iGlowsRange, g_iGlowsMin, g_bGlowsFlash);
}

// ╒══════════════════════════════════════════════════════════════════════════════╕
//									UTILS
// ╘══════════════════════════════════════════════════════════════════════════════╛

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

stock bool IsValidAliveSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
