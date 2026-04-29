/**
 * [L4D.1&2] Glows - Customize
 * 
 * Basado en uno de los trabajos de: R1KO
 * Editado por: vℓα∂ιмιr#4284, con el nombre: [L4d2] Flashlight + Glows + Disco - 2.0
 *
 * LICENCIA:
 * Este plugin fue publicado originalmente en HLMOD. Sin embargo su primera edición fue puesta en Discord.
 * Respetando los derechos del autor original, con su editor, este trabajo derivado se distribuye bajo 
 * la licencia GNU General Public License v3.
 *
 * AGRADECIMIENTOS:
 * Este plugin fue editado usando el código fuente de otros plugins.
 *
 *	-	"King_OXO && valedar(rework and fix) && BloodyBlade(Edited)"
 *		por "[L4D2] Glow Survivor" - Lets Players Help Themselves When Troubled. - 9.9.9v
 *		https://github.com/BloodyBlade/L4D2-Plugins/blob/main/l4d2_glow_menu().sp
 *
 *	-	"King_OXO" por "[L4D2] Rainbow Flashlight" - Set Rainbow To flashlight - 1.1.0
 *		https://forums.alliedmods.net/showthread.php?t=281620
 *
 * MAYOR INFORMACIÓN:
 * Discord:	https://discord.gg/vezaFCGFd3
 * GitHub: 	https://github.com/JSC8765
*/

#define PLUGIN_VERSION "customize 4.3"

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

// ██============================================================================██
//									GLOBALS
// ██============================================================================██

#define CVAR_FLAGS						FCVAR_NOTIFY

native int LMC_GetClientOverlayModel(int client);

bool g_bLMC_Available = false;

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
	{
		g_bLMC_Available = true;
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
	{
		g_bLMC_Available = false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports \"Left 4 Dead 1 and 2\"");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	return APLRes_Success;
}

int g_clientItem[MAXPLAYERS+1];
int g_iGlowColor[MAXPLAYERS+1][4];
int g_iLightRef[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
int g_iRainbowLight[MAXPLAYERS + 1];

char classname[64];

Handle g_hGlowsMenu;
Handle g_hCookie;
Handle g_hKeyValues;

bool g_bEventsHooked;

ConVar g_hCvar_GlowEnable;
ConVar g_hCvar_ThirdPersonTime;
bool g_bGlow_Enable;
static float g_fThirdPersonTime = 2.0;

// ██============================================================================██
//									PLUGIN INFO
// ██============================================================================██

public Plugin myinfo = 
{
	name		= "[L4D.1&2] Flashlight + Glows + Disco",
	author		= "R1KO, edited by vℓα∂ιмιr and Mr.Creamy",
	description	= "Flashlight + Glows + Disco",
	version		= PLUGIN_VERSION,
	url			= "https://discord.gg/vezaFCGFd3"
}

// ██============================================================================██
//									PLUGIN START
// ██============================================================================██

public void OnPluginStart()
{
	LoadTranslations("l4d_glows.phrases");

	CreateConVar("l4d_glows_version", PLUGIN_VERSION, "Glows Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvar_GlowEnable			=	CreateConVar("l4d_glows_enable",	"1",	"Enable Glows?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_ThirdPersonTime		=	CreateConVar("l4d_glows_thirdperson_time",	"3.5",	"How long (in seconds) the client will be in 3rd person view after using the glows commands. (0.5 < = off)", CVAR_FLAGS, true, 0.0, true, 360.0);

	g_hCvar_GlowEnable.AddChangeHook(OnConVarChanged);
	g_hCvar_ThirdPersonTime.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "l4d_glows");

	g_hCookie = RegClientCookie("l4d_glows", "l4d_glows Cookies", CookieAccess_Public);

	g_hGlowsMenu = CreateMenu(AuraMenuHandler, MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hGlowsMenu, false);

	RegConsoleCmd("sm_aura", CmdOpenGlowMenu);
	RegConsoleCmd("sm_light", CmdOpenGlowMenu);
	RegConsoleCmd("sm_glow", CmdOpenGlowMenu);
}

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
	g_bGlow_Enable = g_hCvar_GlowEnable.BoolValue;
	g_fThirdPersonTime = g_hCvar_ThirdPersonTime.FloatValue;
}

void HookEvents()
{
	if(g_bGlow_Enable && !g_bEventsHooked)
	{
		g_bEventsHooked = true;

		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_team", Event_PlayerDeath);

		return;
	}

	if(!g_bGlow_Enable && g_bEventsHooked)
	{
		g_bEventsHooked = false;

		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("player_team", Event_PlayerDeath);

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
	for(i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hGlowsMenu, i, sColor, sizeof(sColor));
		if(strcmp(sColor, sItemInfo) == 0)
			return i;
	}
	return -1;
}

// ██============================================================================██
//									MAP START
// ██============================================================================██

public void OnMapStart()
{
	RemoveAllMenuItems(g_hGlowsMenu);

	if(g_hKeyValues != INVALID_HANDLE)
		CloseHandle(g_hKeyValues);

	g_hKeyValues = CreateKeyValues("Glow_Colors");

	if (FileToKeyValues(g_hKeyValues, "addons/sourcemod/data/l4d_glows.ini") == false)
	{
		CloseHandle(g_hKeyValues);
		g_hKeyValues = INVALID_HANDLE;
		SetFailState("Couldn't parse file \"addons/sourcemod/data/l4d_glows.ini\"");
	}

	KvRewind(g_hKeyValues);

	if(KvJumpToKey(g_hKeyValues, "Colors") && KvGotoFirstSubKey(g_hKeyValues, false)){
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

public int AuraMenuHandler(Handle hMenu, MenuAction action, int client, int id)
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
			GetMenuItem(hMenu, id, sColor, sizeof(sColor));
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

				SetAura(client);
				SetExternalView(client);
				SetClientCookie(client, g_hCookie, sColor);
				
				if(IsDisableAura(g_iGlowColor[client]))
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
			if(g_clientItem[client] == id)
			{
				char sColorName[64];
				GetMenuItem(hMenu, id, sColorName, sizeof(sColorName));

				Format(sColorName, sizeof(sColorName), "%s [X]", sColorName);

				return RedrawMenuItem(sColorName);
			}
		}
	}
	return 0;
}

// ██============================================================================██
//									SET AURA CLIENT
// ██============================================================================██

void SetAura(int client)
{
	if(IsDisableAura(g_iGlowColor[client]))
	{
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		RemoveAllEfects(client);
	}
    else if(IsEnableRainbow(g_iGlowColor[client]))
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
			if (entity > MaxClients)
			{
				SetGlow(entity, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), 3, 99999, 0);
			}
			else {
				SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), 3, 99999, 0);
			}
		}
		else {
			SetGlow(client, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), 3, 99999, 0);
		}

		for( int i = 1; i < 2048; i++ )
		{
			if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
			{
				GetEdictClassname(i, classname, sizeof(classname));
				if( StrEqual(classname, "prop_dynamic", false))
				{
					SetGlow(i, g_iGlowColor[client][0] + (g_iGlowColor[client][1] << 8) + (g_iGlowColor[client][2] << 16), 3, 99999, 0);
				}
			}
		}

		SetLight(client, g_iGlowColor[client][0], g_iGlowColor[client][1], g_iGlowColor[client][2], g_iGlowColor[client][3], 35);
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

void SetRainbowPlayer(int iClient)
{
	// Creación de la entidad
	int iLight = CreateEntityByName("light_dynamic");
	if (iLight == -1 || !IsValidEntity(iLight))
	{
		g_iRainbowLight[iClient] = 0;
		return;
	}

	// Configuración de parámetros
	DispatchKeyValue(iLight, "brightness", "4");
	DispatchKeyValue(iLight, "spotlight_radius", "250");
	DispatchKeyValue(iLight, "distance", "255");
	DispatchKeyValue(iLight, "style", "0");

	SetEntPropEnt(iLight, Prop_Send, "m_hOwnerEntity", iClient);

	// Intento de Spawn
	if (DispatchSpawn(iLight))
	{
		float fOrigin[3];
		GetClientAbsOrigin(iClient, fOrigin);

		AcceptEntityInput(iLight, "TurnOn");
		TeleportEntity(iLight, fOrigin, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iLight, "SetParent", iClient);

		SDKHook(iLight, SDKHook_SetTransmit, OnTransmit);
		SDKHook(iClient, SDKHook_PreThinkPost, RainbowPlayer);

		// Guardamos el índice o la referencia (preferiblemente referencia)
		g_iRainbowLight[iClient] = iLight; 
	}
	else
	{
		// Si falló el spawn, nos aseguramos de borrar la entidad fallida
		AcceptEntityInput(iLight, "Kill");
		g_iRainbowLight[iClient] = 0;
	}
}

public Action OnTransmit(int iEntity, int iClient)
{
	if (g_iRainbowLight[iClient] == iEntity)
	{
		return Plugin_Continue;
	}

	static int iOwner, iTeam;

	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 && 
		(iTeam = GetClientTeam(iClient)) > 1
		 && GetClientTeam(iOwner) != iTeam)
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
		if (entity > MaxClients) SetGlow(entity, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
		else SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
	}
	else {
		SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
	}

	for( int i = 1; i < 2048; i++ )
	{
		if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if( StrEqual(classname, "prop_dynamic", false))
			{
				SetGlow(i, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
			}
		}
	}

	//Light Color
	char sBuffer[16];
	FormatEx(sBuffer, sizeof(sBuffer), "%i %i %i %i", GetRandomColor(color[2]), GetRandomColor(color[1]), GetRandomColor(color[0]), 255);
	DispatchKeyValue(g_iRainbowLight[client], "_light", sBuffer);
	
	return Plugin_Handled;
}

stock int GetRandomColor(int color)
{
	return (color == -1 || color < 0 || color > 255) ? GetRandomInt(0, 255) : color;
}

void RemoveGlow(int client)
{
	if (g_bLMC_Available)
	{
		int entity = LMC_GetClientOverlayModel(client);
		if (entity > MaxClients)
		{
			SetGlow(entity, 0, 0, 0, 0);
		}
		else {
			SetGlow(client, 0, 0, 0, 0);
		}
	}
	else {
		SetGlow(client, 0, 0, 0, 0);
	}
	
	for( int i = 1; i < 2048; i++ )
	{
		if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if( StrEqual(classname, "prop_dynamic", false))
			{
				SetGlow(i, 0, 0, 0, 0);
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
	
	if (g_iRainbowLight[client] && IsValidEdict(g_iRainbowLight[client]))
	{
		AcceptEntityInput(g_iRainbowLight[client], "TurnOff");
		AcceptEntityInput(g_iRainbowLight[client], "Kill");
		SetGlow(client, 0, 0, 0, 0);
		SDKUnhook(client, SDKHook_PreThinkPost, RainbowPlayer);
	}
	
	g_iRainbowLight[client] = 0;
}

void SetGlow(int entity, int color, int type, int range, int rangeMin)
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", rangeMin);
}

void RemoveLight(int client)
{
	int iLight = EntRefToEntIndex(g_iLightRef[client]);
	if (iLight != INVALID_ENT_REFERENCE && IsValidEntity(iLight))
	{
		AcceptEntityInput(iLight, "TurnOff"); 
		AcceptEntityInput(iLight, "Kill");
	}
	g_iLightRef[client] = INVALID_ENT_REFERENCE;
}

void SetLight(int client, int r, int g, int b, int alpha, int radius)
{
	int iLight = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iLight))
	{
		char sTempL[16];
		// El formato de "_light" en light_dynamic es "R G B Exponente"
		FormatEx(sTempL, sizeof(sTempL), "%d %d %d %d", r, g, b, alpha);

		DispatchKeyValue(iLight, "_light", sTempL);
		DispatchKeyValue(iLight, "brightness", "3.0");
		DispatchKeyValueFloat(iLight, "spotlight_radius", view_as<float>(radius));
		DispatchKeyValue(iLight, "distance", "255");
		DispatchKeyValue(iLight, "style", "0");

		// Spawn y encendido
		DispatchSpawn(iLight);
		AcceptEntityInput(iLight, "TurnOn");

		// Emparentar al jugador
		SetVariantString("!activator");
		AcceptEntityInput(iLight, "SetParent", client);

		// Posicionarlo un poco arriba del origen (pies) del jugador
		TeleportEntity(iLight, view_as<float>({ 0.0, 0.0, 10.0 }), NULL_VECTOR, NULL_VECTOR);

		// Guardar referencia segura
		g_iLightRef[client] = EntIndexToEntRef(iLight);
	}
}

void RemoveAllEfects(int client)
{
	RemoveGlow(client);
	RemoveLight(client);
}

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
			GetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0)
	);
	SetGlow(client, 0, 0, 0, 0);
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
			GetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0)
	);
}

// ██============================================================================██
//									PLUGIN EVENTS
// ██============================================================================██

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (!IsValidAliveSurv(client))
	{
		return;
	}

	CreateTimer(2.5, Timer_SetAura, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_SetAura(Handle timer, any client)
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
			//SetAura(client, g_clientItem[client]);
			SetAura(client);
		}
	}

	return Plugin_Stop;
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

// ██============================================================================██
//										UTILS
// ██============================================================================██

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

stock bool IsValidAliveSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

void SetExternalView(int client)
{
	if (g_fThirdPersonTime < 0.5) // Best time any lower is kinda pointless
	{
		return;
	}

	float fCurrentTPtime = GetForcedThirdPerson(client);
	float fTime = GetGameTime();
	if (fCurrentTPtime > (fTime + g_fThirdPersonTime))
	{
		return;
	}

	if (fCurrentTPtime < fTime + 0.5)
	{
		if (fCurrentTPtime > fTime - 1.0) //Helps to prevent a strange rare bug with models that include particles(e.g. witch) model spamming just about to go back to firstperson, causing stuff to not render correctly (Could be only me) this seems to be client bug, this only seems to happen on maps with modded func_precipitation.
		{
			return;
		}
	}
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", fTime + g_fThirdPersonTime);
}

float GetForcedThirdPerson(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView");
}