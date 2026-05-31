/**
 * [L4D.2] Saferoom Locker - Customize
 * 
 * Basado en el trabajo original de: alasfourom
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *	Plugin Name:       "L4D2 Saferoom Locker"
 *	Description:       "Lock Saferoom Door Until All Players Are Ready"
 *	Version:           "1.0"
 *	Plugin URL:        "https://forums.alliedmods.net/showpost.php?p=2788193&postcount=38"
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *
 * LICENCIA:
 * Este plugin fue publicado originalmente en AlliedModders. Respetando
 * los derechos del autor original, este trabajo derivado se distribuye bajo 
 * la licencia GNU General Public License v3.
 *
 * AGRADECIMIENTOS:
 * Este plugin fue editado usando el código fuente de otros plugins.
 *
 *	-	"SilverShot" por "[L4D & L4D2] Lift Music" - Plays music when players are travelling inside an elevator. - 1.5
 *		https://forums.alliedmods.net/showthread.php?t=157267
 *
 *	-	"cravenge" por "[L4D2] Anti-Rush System (Reloaded)" - Blocks Paths And Lock Saferoom Doors To Prevent Rushing. - 1.82
 *		https://forums.alliedmods.net/showthread.php?t=281374
 *
 * CONTRIBUIDORES:
 *	-	"cumball_007" por informar bugs y errores.
 *
 * MAYOR INFORMACIÓN:
 * Discord:	https://discord.gg/vezaFCGFd3
 * GitHub: 	https://github.com/JSC8765
*/

#define PLUGIN_VERSION "customize 2.4"

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <multicolors>

public Plugin myinfo = 
{
	name = "[L4D.2] Saferoom Locker",
	author = "alasfourom, edited by Mr.Creamy",
	description = "Lock Saferoom Door Until All Players Are Ready.",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/vezaFCGFd3"
}

ConVar Cvar_DoorLock_AllowLock, Cvar_DoorLock_ModesType, Cvar_DoorLock_GameModes, Cvar_DoorLock_Countdown,
	Cvar_DoorLock_LoaderMax, Cvar_DoorLock_AllowGlow, Cvar_DoorLock_GlowRange, Cvar_DoorLock_LockColor,
	Cvar_DoorLock_OpenColor, Cvar_DoorLock_LoaderMsg, Cvar_DoorLock_AddCheats, Cvar_DoorLock_AddCustom,
	Cvar_DoorLock_StartMusic, Cvar_DoorLock_AddFiles;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

#define SNDCHAN_DEFAULT 	SNDCHAN_STATIC 
#define MAX_TRACKS			32	// Soporte para 32 rutas de sonido

char g_sTracks[MAX_TRACKS][64];
char g_sCountdown[MAX_TRACKS][64];
char g_sStartGame[MAX_TRACKS][64];

int g_iTracks;
int g_iCountdown;
int g_iStartGame;
int g_iLoadersTime;
int g_iUnlocksTime;

Handle g_hTimer_PendingLoader;
Handle g_hTimer_WarmingUpTime;
Handle g_hTimer_CountdownTime;

bool g_bIgnoreLoaders;
bool g_bLockSafeAreas;

char sDataFilePath[PLATFORM_MAX_PATH];

#define MAX_PATHS			32	// Soporte para 32 bloques por mapa

char sBlockModel[MAX_PATHS][128];
char sMap[64];

float fBlockPos[MAX_PATHS][3];
float fBlockAng[MAX_PATHS][3];

int iBlockCount;
int g_iSpawnedEntities[MAX_PATHS]; // Soporte para guardar los IDs de los bloques y poder borrarlos luego

bool g_bFirstScenario;

/* =============================================================================================================== *
 *												Plugin Start   													   *
 *================================================================================================================ */

public void OnPluginStart()
{
	BuildPath(Path_SM, sDataFilePath, sizeof(sDataFilePath), "data/l4d2_doorlock.cfg");
	if (!FileExists(sDataFilePath))
		SetFailState("[DOORLOCK] '%s' File Not Found!", sDataFilePath);
	
	LoadTranslations("l4d2_doorlock.phrases");
	
	CreateConVar("l4d2_doorlock_version", PLUGIN_VERSION, "Doorlock plugin version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	Cvar_DoorLock_AllowLock = CreateConVar("l4d2_doorlock_plugin_enable",		"1",			"0 = No Locks, 1 = Lock Saferooms", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_ModesType = CreateConVar("l4d2_doorlock_first_scenario_mode", "0", 			"Set First Chapters Mode (0=Disable First Scenario Mode, 1 = Freeze Survivors)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_GameModes = CreateConVar("l4d2_doorlock_game_mode",			"versus,coop",	"Add The Modes You Want To Enable This Plugin In It", FCVAR_NOTIFY);
	Cvar_DoorLock_Countdown = CreateConVar("l4d2_doorlock_countdown",			"45",			"How Long You Want To Lock The Safe Area (In Seconds)", FCVAR_NOTIFY);
	Cvar_DoorLock_LoaderMax = CreateConVar("l4d2_doorlock_loaders_time",		"60",			"How Long Plugin Waits For Loaders Before Giving Up On Them (In Seconds)", FCVAR_NOTIFY);
	Cvar_DoorLock_AllowGlow = CreateConVar("l4d2_doorlock_glow_enable",			"1",			"0 = No Glow, 1 = Glow Saferoom Doors Only, 2 = Glow Barricades Only, 3 = Glow All Locks", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_DoorLock_GlowRange = CreateConVar("l4d2_doorlock_glow_range",			"1500",			"Set The Glow Range For Saferoom Doors", FCVAR_NOTIFY);
	Cvar_DoorLock_LockColor = CreateConVar("l4d2_doorlock_lock_glow_color",		"255 0 0",		"Set Saferoom Lock Glow Color, (0-255) Separated By Spaces.", FCVAR_NOTIFY);
	Cvar_DoorLock_OpenColor = CreateConVar("l4d2_doorlock_unlock_glow_color", 	"0 255 0",		"Set Saferoom Unlock Glow Color, (0-255) Separated By Spaces.", FCVAR_NOTIFY);
	Cvar_DoorLock_LoaderMsg = CreateConVar("l4d2_doorlock_loaders_message", 	"1", 			"Display Hint Texts To Connected Players Notiying Them That Loaders Are Connecting (0 = Disable, 1 = Enable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_AddCheats	= CreateConVar("l4d2_doorlock_cheats_enable", 		"3", 			"0 = No Cheats, 1 = No Damage, 2 = Infinite Ammo, 3 = All", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_DoorLock_AddCustom = CreateConVar("l4d2_doorlock_custom_music_enable", "0", 			"0 = No Custom Music, 1 = Only Custom Music", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_StartMusic = CreateConVar("l4d2_doorlock_custom_music_started", "40", 		"At what second do you want the music to start?", FCVAR_NOTIFY);
	Cvar_DoorLock_AddFiles = CreateConVar("l4d2_doorlock_addfiletodownloads_enable", "0", 		"0 = No AddFileToDownloadsTable, 1 = AddFileToDownloadsTable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2_doorlock");
	
	RegAdminCmd("sm_lock",		Command_Lock,		ADMFLAG_ROOT);
	RegAdminCmd("sm_unlock",	Command_Unlock,		ADMFLAG_ROOT);
	
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_Post);
	HookEvent("round_end", Event_OnRoundEnd);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

/* =============================================================================================================== *
 *												  Map Start   													   *
 *================================================================================================================ */

public void OnMapStart()
{
	g_bFirstScenario = false;
	
	GetCurrentMap(sMap, sizeof(sMap));
	InitConfig(sMap, true);
	
	if (L4D_IsFirstMapInScenario()) g_bFirstScenario = true;
	
	PrecacheSound("ambient/alarms/klaxon1.wav", true);
	PrecacheSound("ui/survival_medal.wav", true);	
	PrecacheSound("ui/survival_playerrec.wav", true);
	PrecacheSound("ui/survival_teamrec.wav", true);
	
	if(Cvar_DoorLock_AddCustom.BoolValue)
	{
		StoreCustomSounds(g_sTracks, g_iTracks);
		StoreCustomSounds(g_sCountdown, g_iCountdown);
		StoreCustomSounds(g_sStartGame, g_iStartGame);
	}
}

/* =============================================================================================================== *
 *												Event_OnRoundStart   											   *
 *================================================================================================================ */

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	char GameMode[64];
	char GameInfo[64];
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	Cvar_DoorLock_GameModes.GetString(GameInfo, sizeof(GameInfo));
	
	if(StrContains(GameInfo, GameMode) != -1)
	{
		// Limpiamos el contador de bloques del sistema anterior
		iBlockCount = 0; 
		for (int i = 0; i < MAX_PATHS; i++)
			g_iSpawnedEntities[i] = -1;
	}
}

/* =============================================================================================================== *
 *												Event_RoundFreezeEnd   											   *
 *================================================================================================================ */

void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	char GameMode[64];
	char GameInfo[64];
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	Cvar_DoorLock_GameModes.GetString(GameInfo, sizeof(GameInfo));
	
	if (StrContains(GameInfo, GameMode) != -1)
	{
		g_bIgnoreLoaders = false;
		g_bLockSafeAreas = false;
		
		g_iLoadersTime = Cvar_DoorLock_LoaderMax.IntValue;
		g_iUnlocksTime = Cvar_DoorLock_Countdown.IntValue;
		
		// Bloqueo de refugios
		StartLockingSafeRoom();
		// Temporizador
		g_hTimer_PendingLoader = CreateTimer(1.0, Timer_PendingLoaders, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

/* =============================================================================================================== *
 *												 Event_OnRoundEnd   											   *
 *================================================================================================================ */

void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	SafeDeleteTimer(g_hTimer_PendingLoader);
	SafeDeleteTimer(g_hTimer_WarmingUpTime);
	SafeDeleteTimer(g_hTimer_CountdownTime);
}

/* =============================================================================================================== *
 *													Timers: Waiting For Loaders									   *
 *================================================================================================================ */

Action Timer_PendingLoaders(Handle timer)
{
	int iHuman = GetRealPlayers();
	if (iHuman == 0) return Plugin_Continue;
	
	if (!g_bIgnoreLoaders)
	{
		if(g_iLoadersTime > 1) g_iLoadersTime--;
		else g_bIgnoreLoaders = true;
	}
	
	int iLoaders = GetLoadingPlayers();
	if (iHuman > 0 && (iLoaders == 0 || g_bIgnoreLoaders || AreTheTeamsCurrentlyFull()))
	{
		g_hTimer_WarmingUpTime = CreateTimer(3.0, Timer_WarmingUpBeforeStartingCountdown, _, TIMER_FLAG_NO_MAPCHANGE);
		g_hTimer_PendingLoader = null;
		return Plugin_Stop;
	}
	
	if (Cvar_DoorLock_LoaderMsg.BoolValue) PrintHintTextToAll("%t", "Loaders Connecting");
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *                     		 		 			Start Countdown To Unlock										   *
 *================================================================================================================ */

Action Timer_WarmingUpBeforeStartingCountdown(Handle timer)
{
	g_iUnlocksTime = Cvar_DoorLock_Countdown.IntValue;
	g_hTimer_CountdownTime = CreateTimer(1.0, Timer_StartCountdownToUnlock, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer_WarmingUpTime = null;
	return Plugin_Handled;
}

Action Timer_StartCountdownToUnlock(Handle timer)
{
	if (g_iUnlocksTime >= 0)
	{
		PrintHintTextToAll("%t", "WAIT", g_iUnlocksTime);
		
		if (Cvar_DoorLock_AddCustom.BoolValue)
		{
			if (g_iTracks == 0)
			{
				// ...
			}
			else
			{
				if (g_iUnlocksTime == Cvar_DoorLock_StartMusic.IntValue)
				{
					EmitSoundCustomToAll(g_sTracks[GetRandomInt(0, g_iTracks-1)]);
				}
			}
			
			if( g_iCountdown == 0 )
			{
				switch(g_iUnlocksTime)
				{
					case 10,9,8,7,6,5,4,3,2,1:
					{
						EmitSoundCustomToAll("ambient/alarms/klaxon1.wav");
					}
				}
			}
			else
			{
				char sSearch[16];
				Format(sSearch, sizeof(sSearch), "/%d.mp3", g_iUnlocksTime);

				for (int i = 0; i < g_iCountdown; i++)
				{
					if (StrContains(g_sCountdown[i], sSearch, false) != -1)
					{
						EmitSoundCustomToAll(g_sCountdown[i]);
						break; 
					}
				}
			}
		}
		else
		{
			switch(g_iUnlocksTime)
			{
				case 10,9,8,7,6,5,4,3,2,1: EmitSoundCustomToAll("ambient/alarms/klaxon1.wav");
			}
		}
	}
	else
	{
		if (Cvar_DoorLock_AddCustom.BoolValue)
		{
			if (g_iStartGame == 0)
			{
				int EmitRandomSoundUnlock = GetRandomInt(1, 3);
				switch(EmitRandomSoundUnlock)
				{
					case 1: EmitSoundCustomToAll("ui/survival_medal.wav");
					case 2: EmitSoundCustomToAll("ui/survival_playerrec.wav");
					case 3: EmitSoundCustomToAll("ui/survival_teamrec.wav");
				}
			}
			else
			{
				EmitSoundCustomToAll(g_sStartGame[GetRandomInt(0, g_iStartGame-1)]);
			}
		}
		else
		{
			int EmitRandomSoundUnlock = GetRandomInt(1, 3);
			switch(EmitRandomSoundUnlock)
			{
				case 1: EmitSoundCustomToAll("ui/survival_medal.wav");
				case 2: EmitSoundCustomToAll("ui/survival_playerrec.wav");
				case 3: EmitSoundCustomToAll("ui/survival_teamrec.wav");
			}
		}
		
		PrintHintTextToAll("%t", "MOVE");
		
		g_hTimer_CountdownTime = null;
		StartUnlockingSaferoom();
		
		int iCheckPointDoor = L4D_GetCheckpointFirst();
		if(!IsValidEnt(iCheckPointDoor)) CPrintToChatAll("%t", "PATH_CLEAR");
		else CPrintToChatAll("%t", "DOOR_OPEN");
		
        return Plugin_Stop;
    }
    
    if (!g_bLockSafeAreas)
    {
        g_hTimer_CountdownTime = null;
		StartUnlockingSaferoom();
		
        return Plugin_Stop;
    }
    
    g_iUnlocksTime--;
    return Plugin_Continue;
}

/* =============================================================================================================== *
 *                     		 				Command Lock and Unlock Doors										   *
 *================================================================================================================ */

public Action Command_Lock(int client, int args)
{
	if(Cvar_DoorLock_AllowLock.BoolValue)
	{
		StartLockingSafeRoom();
		CPrintToChatAll("%t", "PAUSE", client);
	}
	return Plugin_Handled;
}

public Action Command_Unlock(int client, int args)
{
	if(Cvar_DoorLock_AllowLock.BoolValue)
	{
		StartUnlockingSaferoom();
		SafeDeleteTimer(g_hTimer_CountdownTime);
		CPrintToChatAll("%t", "UNPAUSE", client);
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 				 	Void Lock and Unlock Doors										   *
 *================================================================================================================ */

void StartLockingSafeRoom()
{
	FreezePlayersForFirstChapterOnly();
	LockFirstChaptersDoors();
	LockAllRotatingSaferoomDoors();
}

void StartUnlockingSaferoom()
{
	UnFreezePlayersForFirstChapterOnly();
	UnlockFirstChaptersDoors();
	UnLockAllRotatingSaferoomDoors();
}

/* =============================================================================================================== *
 *                     		 				Method To Freeze Players On First Chapter							   *
 *================================================================================================================ */

void FreezePlayersForFirstChapterOnly()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue || !g_bFirstScenario || GetConVarInt(Cvar_DoorLock_ModesType) != 1) return;
	
	g_bLockSafeAreas = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && GetClientTeam(i) == 2)
		{
			// Congelamos a los jugadores reales
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
	
	// Congelamos a los bots y Activamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 1);
	if (GetConVarInt(Cvar_DoorLock_AddCheats) == 2 || GetConVarInt(Cvar_DoorLock_AddCheats) == 3)
	{
		SetConVarInt(FindConVar("sv_infinite_ammo"), 1);
	}
}

/* =============================================================================================================== *
 *                     		 		 Method To UnFreeze Players On First Chapters								   *
 *================================================================================================================ */

void UnFreezePlayersForFirstChapterOnly()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue || !g_bFirstScenario || GetConVarInt(Cvar_DoorLock_ModesType) != 1) return;
	
	g_bLockSafeAreas = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && GetClientTeam(i) == 2)
		{
			// Descongelamos a los jugadores reales
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
	
	// Descongelamos a los bots y Desactivamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 0);
	SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
}

/* =============================================================================================================== *
 *                     		 				 	Method To Lock First Doors										   *
 *================================================================================================================ */

void LockFirstChaptersDoors()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	g_bLockSafeAreas = true;
	
	// Cargamos los datos del CFG para cualquier mapa establecido en el archivo
	InitConfig(sMap);
	
	if (iBlockCount <= 0) return; // Si el mapa no tiene bloques configurados, salimos
	
	for (int i = 0; i < iBlockCount; i++)
	{
		int entity = CreateEntityByName("prop_dynamic_override");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", sBlockModel[i]);
			DispatchKeyValue(entity, "targetname", "anti-rush_system-l4d2_fence");
			DispatchSpawn(entity);
			
			// Aplicamos posición y ángulos leídos del CFG
			TeleportEntity(entity, fBlockPos[i], fBlockAng[i], NULL_VECTOR);
			
			// Establecemos a Sólido los bloques
			SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
			
			if (Cvar_DoorLock_AllowGlow.IntValue > 1)
			{
				AcceptEntityInput(entity, "StartGlowing");
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_nGlowRange", Cvar_DoorLock_GlowRange.IntValue);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
			}
			
			g_iSpawnedEntities[i] = entity; // Guardamos la referencia
		}
	}
	
	// Congelamos a los bots y Activamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 1);
	if (GetConVarInt(Cvar_DoorLock_AddCheats) == 2 || GetConVarInt(Cvar_DoorLock_AddCheats) == 3)
	{
		SetConVarInt(FindConVar("sv_infinite_ammo"), 1);
	}
}

/* =============================================================================================================== *
 *                     		 				 Method To Unlock First Doors										   *
 *================================================================================================================ */

void UnlockFirstChaptersDoors()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	g_bLockSafeAreas = false;
	
	// Eliminamos los bloques (Muros, Vallas, Rejas, etc..) creados
	for (int i = 0; i < iBlockCount; i++)
	{
		if (g_iSpawnedEntities[i] > 0 && IsValidEntity(g_iSpawnedEntities[i]))
		{
			AcceptEntityInput(g_iSpawnedEntities[i], "Kill");
		}
		g_iSpawnedEntities[i] = -1; // Limpiamos el índice
	}
	
	// Debido al código de arriba, esta función ya no es necesaria
	//CheatCommand(_, "ent_fire", "anti-rush_system-l4d2_fence KillHierarchy");
	
	// Reseteamos el contador de bloques para el próximo mapa
	iBlockCount = 0;
	
	// Descongelamos a los bots y Desactivamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 0);
	SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
}

/* =============================================================================================================== *
 *                     		 				 	Method To Lock Other Doors										   *
 *================================================================================================================ */

void LockAllRotatingSaferoomDoors()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	// Bloqueamos
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (!IsValidEnt(iCheckPointDoor)) return;
	
	AcceptEntityInput(iCheckPointDoor, "Close");
	AcceptEntityInput(iCheckPointDoor, "Lock");
	SetVariantString("spawnflags 40960");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");
	
	// Añade brillo
	int g_iDoorLockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_LockColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorLockColors, sColor);
	if (GetConVarInt(Cvar_DoorLock_AllowGlow) == 1 || GetConVarInt(Cvar_DoorLock_AllowGlow) == 3)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, g_iDoorLockColors, false);
	
	// Congelamos a los bots y Activamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 1);
	if (GetConVarInt(Cvar_DoorLock_AddCheats) == 2 || GetConVarInt(Cvar_DoorLock_AddCheats) == 3)
	{
		SetConVarInt(FindConVar("sv_infinite_ammo"), 1);
	}
}

/* =============================================================================================================== *
 *                     		 				 	Method To Unlock Other Doors									   *
 *================================================================================================================ */

void UnLockAllRotatingSaferoomDoors()
{
	if (!Cvar_DoorLock_AllowLock.BoolValue) return;
	
	// Desbloqueamos
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (!IsValidEnt(iCheckPointDoor)) return;
	
	SetVariantString("spawnflags 8192");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");
	AcceptEntityInput(iCheckPointDoor, "Unlock");
	AcceptEntityInput(iCheckPointDoor, "Open");
	AcceptEntityInput(iCheckPointDoor, "StartGlowing");
	
	// Añade brillo
	int iDoorUnlockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_OpenColor.GetString(sColor, sizeof(sColor));
	GetColor(iDoorUnlockColors, sColor);
	if (GetConVarInt(Cvar_DoorLock_AllowGlow) == 1 || GetConVarInt(Cvar_DoorLock_AllowGlow) == 3)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, iDoorUnlockColors, false);
	
	// Descongelamos a los bots y Desactivamos Munición Infinita
	SetConVarInt(FindConVar("nb_player_stop"), 0);
	SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
}

/* =============================================================================================================== *
 *											Correction of Health and God Mode   								   *
 *================================================================================================================ */

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (Cvar_DoorLock_AllowLock.BoolValue && g_bLockSafeAreas)
	{
		// Solo protegemos a los Supervivientes (Humanos y Bots)
		if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 2)
		{
			if (GetConVarInt(Cvar_DoorLock_AddCheats) == 1 || GetConVarInt(Cvar_DoorLock_AddCheats) == 3)
			{
				damage = 0.0;			// Cambiamos el daño a 0
				return Plugin_Changed;	// Notificamos al juego que hemos modificado el daño
			}
		}
	}
	
	return Plugin_Continue; // Si no se cumplen las condiciones, el daño sigue normal
}

/* =============================================================================================================== *
 *                     		 				 	Method For Loading Models										   *
 *================================================================================================================ */

void InitConfig(char sMapName[64], bool bPrecache = false)
{
	KeyValues kvData = new KeyValues("data");
	
	// Verificamos la primera Llave del archivo CFG
	if (!kvData.ImportFromFile(sDataFilePath))
	{
		delete kvData;
		return;
	}
	
	// Comenzamos con la lectura de las demás Llaves
	if (kvData.JumpToKey("path"))
	{
		if (kvData.JumpToKey(sMapName))
		{
			// Leemos cuántos bloques hay definidos
			iBlockCount = kvData.GetNum("blocks", 0);
			
			// Limitamos a 32 para no desbordar el array
			if (iBlockCount > MAX_PATHS) iBlockCount = MAX_PATHS;
			
			char sTemp[MAX_PATHS];
			for (int i = 1; i <= iBlockCount; i++)
			{
				IntToString(i, sTemp, sizeof(sTemp));
				
				if (kvData.JumpToKey(sTemp))
				{
					// Se Lee el Modelo
					kvData.GetString("model", sBlockModel[i - 1], 128);
					if (bPrecache || !IsModelPrecached(sBlockModel[i - 1]))
					{
						PrecacheModel(sBlockModel[i - 1], true);
					}
					
					// Se Lee la Posición y Ángulos
					kvData.GetVector("origin", fBlockPos[i - 1]);
					kvData.GetVector("angles", fBlockAng[i - 1]);
					
					// Regresamos a 'sMapName' para leer el siguiente bloque,
					// hasta cumplir con el límite establecido en 'iBlockCount'
					kvData.GoBack();
				}
			}
			kvData.Rewind(); // Volvemos al inicio después de leer todo
		}
		else // En caso de que el mapa establecido no tenga bloques configurados
		{
			iBlockCount = 0;
			if (L4D_IsFirstMapInScenario()) PrintToServer("[DOORLOCK] '%s' Key Not Configured In 'Path' Category!", sMapName);
		}
	}
	
	g_iTracks = 0;
	g_iCountdown = 0;
	g_iStartGame = 0;
	
	kvData.Rewind();
	LoadSectionSounds(kvData, "music", g_sTracks, g_iTracks, sizeof(g_sTracks[]));
	
	kvData.Rewind(); 
	LoadSectionSounds(kvData, "countdown", g_sCountdown, g_iCountdown, sizeof(g_sCountdown[]));
	
	kvData.Rewind();
	LoadSectionSounds(kvData, "start", g_sStartGame, g_iStartGame, sizeof(g_sStartGame[]));
	
	delete kvData;
}

void LoadSectionSounds(KeyValues kv, const char[] section, char[][] storage, int &index, int maxLen)
{
	if (kv.JumpToKey(section))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				kv.GetString(NULL_STRING, storage[index], maxLen);
				if (storage[index][0] != '\0') index++;
				
			} while (kv.GotoNextKey(false));
			
			kv.GoBack();
		}
		
		kv.GoBack();
	}
}

/* =============================================================================================================== *
 *											Change Saferoom Doors Lock/Unlock Colors							   *
 *================================================================================================================ */

void GetColor(int[] array, char[] sTemp)
{
	if (StrEqual(sTemp, ""))
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	
	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);
	
	if (color != 3)
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	
	array[0] = StringToInt(sColors[0]);
	array[1] = StringToInt(sColors[1]);
	array[2] = StringToInt(sColors[2]);
}

/* =============================================================================================================== *
 *                     		 				 	Counting Loaders Method											   *
 *================================================================================================================ */

int GetLoadingPlayers()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			number++;
	}
	return number;
}

int GetRealPlayers()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			number++;
	}
	return number;
}

bool AreTheTeamsCurrentlyFull()
{
	if (GetTotalSlots() == (GetRealTeamCount(3) + GetRealTeamCount(2))) return true;
	return false;
}

int GetTotalSlots()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) == 2) number += 2;
	return number;
}

int GetRealTeamCount(int team)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) number++;
	return number;
}

/* =============================================================================================================== *
 *                     		 		 				Some Functions												   *
 *================================================================================================================ */

void StoreCustomSounds(const char[][] Storage, int Index)
{
	for (int i = 0; i < Index; i++)
	{
		PrecacheSound(Storage[i], true);
		if(Cvar_DoorLock_AddFiles.BoolValue) AddFile(Storage[i]);
	}
}

stock void AddFile(const char[] sPath)
{
	char sDownloadPath[PLATFORM_MAX_PATH];
	
	// Si por alguna razón la ruta en el .cfg ya empieza con "sound/", la dejamos igual
	if (StrContains(sPath, "sound/", false) == 0)
	{
		strcopy(sDownloadPath, sizeof(sDownloadPath), sPath);
	}
	else 
	{
		// Si no tiene "sound/", se lo agregamos automáticamente aquí adentro
		Format(sDownloadPath, sizeof(sDownloadPath), "sound/%s", sPath);
	}
	
	// Si el archivo físico existe en el servidor, lo agregamos a las descargas
	if (FileExists(sDownloadPath, true))
	{
		AddFileToDownloadsTable(sDownloadPath);
	}
}

void SafeDeleteTimer(Handle &timer)
{
    if (timer != null && timer != INVALID_HANDLE)
    {
        delete timer;
        timer = null;
    }
}

void EmitSoundCustomToAll(const char[] soundfile)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ClientCommand(i, "playgamesound \"%s\"", soundfile);
		}
	}
}

/* =============================================================================================================== *
 *															Utils												   *
 *================================================================================================================ */

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}
