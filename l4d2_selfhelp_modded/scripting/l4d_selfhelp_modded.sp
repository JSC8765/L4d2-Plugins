/**
 * [L4D.1&2] SelfHelp - Modded
 * 
 * Basado en el trabajo original de: Pan Xiaohai
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *	Plugin Name:       "Self Help"
 *	Description:       "Self revive through medkid and pain pills."
 *	Version:           "0.3"
 *	Plugin URL:        "https://forums.alliedmods.net/showthread.php?t=129444"
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
 *	-	"valedar(XXX 18+)" por "Self Help" - Medicines now have permanent health. - 1.0.1
 *		https://forums.alliedmods.net/showpost.php?p=2784803&postcount=143
 *
 *	-	"cravenge" por  "Self-Help (Reloaded)" - Lets Players Help Themselves When Troubled. - 0.3
 *		https://forums.alliedmods.net/showthread.php?t=281620
 *
 *	-	"Lux" por "adrenaline_effect"
 *		https://forums.alliedmods.net/showpost.php?p=2721773&postcount=2
 *
 * MAYOR INFORMACIÓN:
 * Discord:	https://discord.gg/vezaFCGFd3
 * GitHub: 	https://github.com/JSC8765
*/

#define PLUGIN_VERSION "modded 1.6"

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <multicolors>

public Plugin myinfo = 
{
	name		= "[L4D.1&2] SelfHelp",
	author		= "Pan Xiaohai, editado por Mr.Creamy",
	description	= "Self revive through medkid and pain pills.",
	version		= PLUGIN_VERSION,
	url			= "https://discord.gg/vezaFCGFd3"
}

#define INCAP			1
#define INCAP_GRAB		2
#define INCAP_POUNCE	3
#define INCAP_RIDE		4
#define INCAP_PUMMEL	5
#define INCAP_EDGEGRAB	6

#define TICKS			10
#define STATE_NONE		0
#define STATE_SELFHELP	1
#define STATE_OK		2
#define STATE_FAILED	3

#define SOUND_KILL1		"weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2		"weapons/knife/knife_deploy.wav"

ConVar Cvar_selfhelp_enabled, Cvar_selfhelp_hintdelay, Cvar_selfhelp_delay, Cvar_selfhelp_otherdelay,
	Cvar_selfhelp_duration, Cvar_selfhelp_incap, Cvar_selfhelp_grab, Cvar_selfhelp_pounce, Cvar_selfhelp_ride,
	Cvar_selfhelp_pummel, Cvar_selfhelp_edgegrab, Cvar_selfhelp_eachother, Cvar_selfhelp_pickup,
	Cvar_selfhelp_kill, Cvar_selfhelp_tempkit, Cvar_selfhelp_temppills, Cvar_selfhelp_tempadre, Cvar_selfhelp_tempother,
	Cvar_selfhelp_kitHP, Cvar_selfhelp_pillsHP, Cvar_selfhelp_adreHP, Cvar_selfhelp_otherHP, Cvar_selfhelp_AdreEffect,
	Cvar_selfhelp_AdreEffectDuration;
bool g_bSelfHelp_Enable, g_bSelfHelp_EachOther, g_bSelfHelp_Pickup, g_bSelfHelp_Kill, g_bSelfHelp_AdreEffect;
int g_iSelfHelp_Incap, g_iSelfHelp_Grab, g_iSelfHelp_Pounce, g_iSelfHelp_Ride, g_iSelfHelp_Pummel,
	g_iSelfHelp_EdgeGrab, g_iSelfHelp_TempKit, g_iSelfHelp_TempPills, g_iSelfHelp_TempAdre, g_iSelfHelp_TempOther,
	g_iSelfHelp_KitHP, g_iSelfHelp_PillsHP, g_iSelfHelp_AdreHP, g_iSelfHelp_OtherHP;
float g_fSelfHelp_HintDelay, g_fSelfHelp_Delay, g_fSelfHelp_OtherDelay, g_fSelfHelp_Duration, g_fSelfHelp_AdreEffectDuration;

bool g_bL4D2, g_bEventsHooked;
int HelpState[MAXPLAYERS+1], HelpOhterState[MAXPLAYERS+1], Attacker[MAXPLAYERS+1], IncapType[MAXPLAYERS+1];
float HelpStartTime[MAXPLAYERS+1];
Handle Timers[MAXPLAYERS+1];
char Gauge1[2] = "-", Gauge3[2] = "#";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports \"Left 4 Dead 1 and 2\" game.");
		return APLRes_SilentFailure;
	}
	g_bL4D2 = (engine == Engine_Left4Dead2);
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_selfhelp.phrases");
	
	CreateConVar("l4d_selfhelp_version", PLUGIN_VERSION, "SelfHelp Modded plugin version.", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	Cvar_selfhelp_enabled	 = CreateConVar("l4d_selfhelp_enabled",		"1",	"¿Activar Auto-Ayuda?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	Cvar_selfhelp_hintdelay	 = CreateConVar("l4d_selfhelp_hintdelay",	"3.0",	"¿En cuánto tiempo deseas mostrar el informe de la Auto-Ayuda?(Hint)\nNO ES POSIBLE DESACTIVAR ESTO", FCVAR_NOTIFY, true, 1.0, true, 5.0);
	Cvar_selfhelp_delay		 = CreateConVar("l4d_selfhelp_delay",		"1.0",	"¿En cuánto tiempo deseas mostrar el aviso de la Auto-Ayuda?(Chat)\nNO ES POSIBLE DESACTIVAR ESTO", FCVAR_NOTIFY, true, 1.0, true, 5.0);
	Cvar_selfhelp_otherdelay = CreateConVar("l4d_selfhelp_otherdelay",	"7.0",	"¿En cuánto tiempo deseas mostrar el aviso de la Auto-Ayuda\npara ayudar a otros supervivientes incapacitados?(Hint)\n0.0 - Desactivado", FCVAR_NOTIFY, true, 0.0, true, 15.0);
	Cvar_selfhelp_duration	 = CreateConVar("l4d_selfhelp_duration",	"2.5",	"¿Cuánto tiempo debe durar la Auto-Ayuda al usarse?\nNO ES POSIBLE DESACTIVAR ESTO", FCVAR_NOTIFY, true, 1.0, true, 5.0);
	
	Cvar_selfhelp_incap 	 = CreateConVar("l4d_selfhelp_incap",		"3",	"¿Qué usaras para Auto-Ayudarte estando incapacitado?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_selfhelp_grab		 = CreateConVar("l4d_selfhelp_grab",		"3",	"¿Qué usaras para Auto-Ayudarte si te ataca el SMOKER?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_selfhelp_pounce	 = CreateConVar("l4d_selfhelp_pounce",		"3",	"¿Qué usaras para Auto-Ayudarte si te ataca el HUNTER?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	
	Cvar_selfhelp_edgegrab	 = CreateConVar("l4d_selfhelp_edgegrab",	"3",	"¿Qué usaras para Auto-Ayudarte estando colgado de una cornisa?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_selfhelp_eachother	 = CreateConVar("l4d_selfhelp_eachother",	"1",	"¿Quieres levantar a tus compañeros incapacitados, estando tú también incapacitado?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_selfhelp_pickup	 = CreateConVar("l4d_selfhelp_pickup",		"1",	"¿Quieres agarrar del suelo Botiquines, Píldoras o Adrenalinas estando incapacitado?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_selfhelp_kill		 = CreateConVar("l4d_selfhelp_kill",		"1",	"¿Deseas matar a tu atacante al usar la Auto-Ayuda?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	Cvar_selfhelp_tempkit	 = CreateConVar("l4d_selfhelp_tempkit",		"0",	"¿Deseas que al usar tu Botiquín, tu vida sea temporal?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_selfhelp_temppills	 = CreateConVar("l4d_selfhelp_temppills",	"1",	"¿Deseas que al usar tus Píldoras, tu vida sea temporal?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_selfhelp_tempother	 = CreateConVar("l4d_selfhelp_tempother",	"1",	"¿Deseas que al levantar a una persona, estando ambos incapacitados, su vida sea temporal?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	Cvar_selfhelp_kitHP		 = CreateConVar("l4d_selfhelp_kitHP",		"100",	"¿Cuánto de vida obtendrás al usar tu Botiquín?", FCVAR_NOTIFY, true, 80.0, true, 100.0);
	Cvar_selfhelp_pillsHP	 = CreateConVar("l4d_selfhelp_pillsHP",		"30",	"¿Cuánto de vida obtendrás al usar tus Píldoras?", FCVAR_NOTIFY, true, 30.0, true, 100.0);
	Cvar_selfhelp_otherHP	 = CreateConVar("l4d_selfhelp_otherHP",		"30",	"¿Cuánto de vida obtendrá la persona que levantes? (Estando ambos incapacitados)", FCVAR_NOTIFY, true, 30.0, true, 100.0);
	
	if(g_bL4D2){
		Cvar_selfhelp_ride		 = CreateConVar("l4d_selfhelp_ride",		"3",	"¿Qué usaras para Auto-Ayudarte si te ataca el JOCKEY?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
		Cvar_selfhelp_pummel	 = CreateConVar("l4d_selfhelp_pummel",		"3",	"¿Qué usaras para Auto-Ayudarte si te ataca el CHARGER?\n0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
		
		Cvar_selfhelp_tempadre	 = CreateConVar("l4d_selfhelp_tempadre",	"1",	"¿Deseas que al usar tus Adrenalina, tu vida sea temporal?\n0 - No, 1 - Si", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		Cvar_selfhelp_adreHP	 = CreateConVar("l4d_selfhelp_adreHP",		"30",	"¿Cuánto de vida obtendrás al usar tu Adrenalina?", FCVAR_NOTIFY, true, 30.0, true, 100.0);
		
		Cvar_selfhelp_AdreEffect	 		= CreateConVar("l4d_selfhelp_adreeffect",			"0",	"¿Deseas agregar el efecto de la adrenalina al usarse?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
		Cvar_selfhelp_AdreEffectDuration	= CreateConVar("l4d_selfhelp_adreeffectduration",	"10",	"¿Cuántos segundos quieres que dure el efecto de la adrenalina?", FCVAR_NOTIFY, true, 3.0, true, 15.0);
	}
	
	Cvar_selfhelp_enabled.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_hintdelay.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_delay.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_otherdelay.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_duration.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_incap.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_grab.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_pounce.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_edgegrab.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_eachother.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_pickup.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_kill.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_tempkit.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_temppills.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_tempother.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_kitHP.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_pillsHP.AddChangeHook(ConVarChanged_Cvars);
	Cvar_selfhelp_otherHP.AddChangeHook(ConVarChanged_Cvars);
	
	if(g_bL4D2){
		Cvar_selfhelp_ride.AddChangeHook(ConVarChanged_Cvars);
		Cvar_selfhelp_pummel.AddChangeHook(ConVarChanged_Cvars);
		Cvar_selfhelp_tempadre.AddChangeHook(ConVarChanged_Cvars);
		Cvar_selfhelp_adreHP.AddChangeHook(ConVarChanged_Cvars);
		Cvar_selfhelp_AdreEffect.AddChangeHook(ConVarChanged_Cvars);
		Cvar_selfhelp_AdreEffectDuration.AddChangeHook(ConVarChanged_Cvars);
	}
	
	AutoExecConfig(true, "l4d_selfhelp_modded");
}

public void OnConfigsExecuted()
{
	GetCvars();
	HookEvents();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	HookEvents();
}

void GetCvars()
{
	g_bSelfHelp_Enable = Cvar_selfhelp_enabled.BoolValue;
	g_fSelfHelp_HintDelay = Cvar_selfhelp_hintdelay.FloatValue;
	g_fSelfHelp_Delay = Cvar_selfhelp_delay.FloatValue;
	g_fSelfHelp_OtherDelay = Cvar_selfhelp_otherdelay.FloatValue;
	g_fSelfHelp_Duration = Cvar_selfhelp_duration.FloatValue;
	g_iSelfHelp_Incap = Cvar_selfhelp_incap.IntValue;
	g_iSelfHelp_Grab = Cvar_selfhelp_grab.IntValue;
	g_iSelfHelp_Pounce = Cvar_selfhelp_pounce.IntValue;
	g_iSelfHelp_EdgeGrab = Cvar_selfhelp_edgegrab.IntValue;
	g_bSelfHelp_EachOther = Cvar_selfhelp_eachother.BoolValue;
	g_bSelfHelp_Pickup = Cvar_selfhelp_pickup.BoolValue;
	g_bSelfHelp_Kill = Cvar_selfhelp_kill.BoolValue;
	g_iSelfHelp_TempKit = Cvar_selfhelp_tempkit.IntValue;
	g_iSelfHelp_TempPills = Cvar_selfhelp_temppills.IntValue;
	g_iSelfHelp_TempOther = Cvar_selfhelp_tempother.IntValue;
	g_iSelfHelp_KitHP = Cvar_selfhelp_kitHP.IntValue;
	g_iSelfHelp_PillsHP = Cvar_selfhelp_pillsHP.IntValue;
	g_iSelfHelp_OtherHP = Cvar_selfhelp_otherHP.IntValue;
	
	if(g_bL4D2){
		g_iSelfHelp_Ride = Cvar_selfhelp_ride.IntValue;
		g_iSelfHelp_Pummel = Cvar_selfhelp_pummel.IntValue;
		g_iSelfHelp_TempAdre = Cvar_selfhelp_tempadre.IntValue;
		g_iSelfHelp_AdreHP = Cvar_selfhelp_adreHP.IntValue;
		g_bSelfHelp_AdreEffect = Cvar_selfhelp_AdreEffect.BoolValue;
		g_fSelfHelp_AdreEffectDuration = Cvar_selfhelp_AdreEffectDuration.FloatValue;
	}
}

void HookEvents()
{
	if(g_bSelfHelp_Enable && !g_bEventsHooked)
	{
		g_bEventsHooked = true;
		
		HookEvent("round_start", Event_RoundStart);
		HookEvent("lunge_pounce", Event_LungePounce);
		HookEvent("pounce_stopped", Event_PounceStopped);
		HookEvent("tongue_grab", Event_TongueGrab);
		HookEvent("tongue_release", Event_TongueRelease);
		HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
		HookEvent("player_incapacitated", Event_PlayerIncap);
		HookEvent("revive_success",Event_ReviveSuccess);
		
		if(g_bL4D2)
		{
			HookEvent("jockey_ride", Event_JockeyRide);
			HookEvent("jockey_ride_end", Event_JockeyRideEnd);
			HookEvent("charger_pummel_start", Event_ChargerPummelStart);
			HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
		}
		
		return;
	}
	
	if(!g_bSelfHelp_Enable && g_bEventsHooked)
	{
		g_bEventsHooked = false;
		
		UnhookEvent("round_start", Event_RoundStart);
		UnhookEvent("lunge_pounce", Event_LungePounce);
		UnhookEvent("pounce_stopped", Event_PounceStopped);
		UnhookEvent("tongue_grab", Event_TongueGrab);
		UnhookEvent("tongue_release", Event_TongueRelease);
		UnhookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
		UnhookEvent("player_incapacitated", Event_PlayerIncap);
		UnhookEvent("revive_success",Event_ReviveSuccess);
		
		if(g_bL4D2)
		{
			UnhookEvent("jockey_ride", Event_JockeyRide);
			UnhookEvent("jockey_ride_end", Event_JockeyRideEnd);
			UnhookEvent("charger_pummel_start", Event_ChargerPummelStart);
			UnhookEvent("charger_pummel_end", Event_ChargerPummelEnd);
		}
		
		return;
	}
}

public void OnMapStart()
{
 	if(g_bL4D2) PrecacheSound(SOUND_KILL2, true);
	else PrecacheSound(SOUND_KILL1, true);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 0; i < MAXPLAYERS+1; i++)
	{
 		HelpOhterState[i] = HelpState[i] = STATE_NONE;
		Attacker[i] = 0;
		HelpStartTime[i] = 0.0;
		
		if(Timers[i] != INVALID_HANDLE)
			KillTimer(Timers[i]);
		
		Timers[i] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
	//PrintToChatAll("Start Round");
}

public void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim")),
		attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
	
	if(g_iSelfHelp_Pounce > 0)
	{
		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
	}
	//PrintToChatAll("Start Pounce"); 
}

public void Event_PounceStopped(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	
	if(!victim) return;
	
	Attacker[victim] = 0;
	//PrintToChatAll("End Pounce");
}

public void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	
	if(g_iSelfHelp_Grab > 0)
	{
 		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
	}
	//PrintToChatAll("Start Grab");
}

public void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	if(Attacker[victim]==attacker)
		Attacker[victim] = 0;
	
	//PrintToChatAll("End Grab");
}

public void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
	
	if(g_iSelfHelp_Ride > 0)
	{
 		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
	}
	//PrintToChatAll("Start Ride");
}

public void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	if(Attacker[victim]==attacker)
		Attacker[victim] = 0;
	
	//PrintToChatAll("End Ride");
}

public void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),	
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_PUMMEL;
	
	if(g_iSelfHelp_Pummel > 0)
	{
 		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
	}
	//PrintToChatAll("Start Pummel");
}

public void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")),
		attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if(!victim) return;
	if(!attacker) return;
	
	if(Attacker[victim]==attacker)
		Attacker[victim] = 0;
	
	//PrintToChatAll("End Pummel");
}

public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	IncapType[victim] = INCAP_EDGEGRAB;
	
	if(g_iSelfHelp_EdgeGrab > 0)
	{
		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
 	}
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	IncapType[victim] = INCAP;
	
	if(g_iSelfHelp_Incap > 0)
	{
		CreateTimer(g_fSelfHelp_Delay, WatchPlayer, victim);
 		CreateTimer(g_fSelfHelp_HintDelay, AdvertisePills, victim);
		if(g_fSelfHelp_OtherDelay > 0.0) CreateTimer(g_fSelfHelp_OtherDelay, AdvertiseHelpOther, victim);
	}
	
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	int count = GetEntData(victim, propincapcounter, 1);
	int countlimit = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	
	CPrintToChat(victim, "%t", "Go Incapacitated", count, countlimit);
	
	if(count == countlimit-1) CPrintToChat(victim, "%t", "Go B/W");
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int reviver = GetClientOfUserId(event.GetInt("userid")),
		revived = GetClientOfUserId(event.GetInt("subject"));
	
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	int count = GetEntData(revived, propincapcounter, 1);
	int countlimit = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	
	if(reviver == revived)
	{
		if(!IsFakeClient(revived)) CPrintToChat(revived, "%t", "You Helped Yourself", count, countlimit);
	}
	else
	{
		if(!IsFakeClient(reviver)) CPrintToChat(reviver, "%t", "You Helped", revived, count, countlimit);
		
		if(!IsFakeClient(revived)) CPrintToChat(revived, "%t", "Helped You", reviver, count, countlimit);
	}
}

public Action WatchPlayer(Handle timer, any client)
{
 	if(!client) return Plugin_Stop;
	if(!IsClientInGame(client)) return Plugin_Stop;
	if(!IsPlayerAlive(client)) return Plugin_Stop;
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] == 0) return Plugin_Stop;
 	if(Timers[client] != INVALID_HANDLE) return Plugin_Stop;
	
 	HelpOhterState[client] = HelpState[client]=STATE_NONE;
	
	Timers[client] = CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public Action AdvertisePills(Handle timer, any client)
{
 	if(!client) return Plugin_Stop;
	if(!IsClientInGame(client)) return Plugin_Stop;
	if(!IsPlayerAlive(client)) return Plugin_Stop;
	
	if(CanSelfHelp(client)) CPrintToChat(client, "%t", "Keyboard Key Self Help Chat");
	
	return Plugin_Continue;
}

public Action AdvertiseHelpOther(Handle timer, any client)
{
 	if(!client) return Plugin_Stop;
	if(!IsClientInGame(client)) return Plugin_Stop;
	if(!IsPlayerAlive(client)) return Plugin_Stop;
	
	PrintHintText(client, "%t", "Keyboard Key Self Help Other Hint");
	
	return Plugin_Continue;
}

bool CanSelfHelp(int client)
{
	bool pills = HavePills(client);
	bool kid = HaveKid(client);
	bool adrenaline = HaveAdrenaline(client);
	bool ok = false;
	int self;
	
	if(IncapType[client] == INCAP)
	{
		self = g_iSelfHelp_Incap;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	else if(IncapType[client] == INCAP_EDGEGRAB)
	{
		self = g_iSelfHelp_EdgeGrab;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	else if(IncapType[client] == INCAP_GRAB)
	{
		self = g_iSelfHelp_Grab;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	else if(IncapType[client] == INCAP_POUNCE)
	{
		self = g_iSelfHelp_Pounce;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	else if(IncapType[client] == INCAP_RIDE)
	{
		self = g_iSelfHelp_Ride;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	else if(IncapType[client] == INCAP_PUMMEL)
	{
		self = g_iSelfHelp_Pummel;
		if((self == 1 || self == 3) && (pills || adrenaline)) ok = true;
		else if((self == 2 || self == 3) && kid) ok = true;
	}
	
	return ok;
}

int SelfHelpUseSlot(int client)
{
	int pills = GetPlayerWeaponSlot(client, 4);
	int kid = GetPlayerWeaponSlot(client, 3);
	int solt = -1;
	int self;
	
	if(IncapType[client] == INCAP)
	{
		self = g_iSelfHelp_Incap;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	else if(IncapType[client] == INCAP_EDGEGRAB)
	{
		self = g_iSelfHelp_EdgeGrab;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	else if(IncapType[client] == INCAP_GRAB)
	{
		self = g_iSelfHelp_Grab;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	else if(IncapType[client] == INCAP_POUNCE)
	{
		self = g_iSelfHelp_Pounce;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	else if(IncapType[client] == INCAP_RIDE)
	{
		self = g_iSelfHelp_Ride;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	else if(IncapType[client] == INCAP_PUMMEL)
	{
		self = g_iSelfHelp_Pummel;
		if((self == 1 || self == 3) && pills != -1) solt = 4;
		else if((self == 2 || self == 3) && kid) solt = 3;
	}
	
	return solt;
}

public Action PlayerTimer(Handle timer, any client)
{
	float time = GetEngineTime();
	
	if(client == 0)
	{
		HelpOhterState[client] = HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		HelpOhterState[client] = HelpState[client]=STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
	
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] == 0)
	{
		HelpOhterState[client] = HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
	
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] != 0)
	{
 		if (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))
		{
			HelpOhterState[client] = HelpState[client] = STATE_NONE;
			Timers[client] = INVALID_HANDLE;
			Attacker[client] = 0;
 			return Plugin_Stop;
		}
	}
	
	if(HelpState[client] == STATE_OK)
	{
 		HelpOhterState[client] = HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int buttons = GetClientButtons(client);
	int haveone = 0;
	int PillSlot = GetPlayerWeaponSlot(client, 4);
	int KidSlot = GetPlayerWeaponSlot(client, 3);
	
	if(PillSlot != -1)
		haveone++;
	
	if(KidSlot != -1)
		if(HaveKid(client)) haveone++;
	
	if(haveone > 0)
	{
		if((buttons & IN_DUCK) || (buttons & IN_USE))
		{
			if(CanSelfHelp(client))
			{
				if(g_bL4D2)
				{
					if(HelpState[client] == STATE_NONE)
					{
						HelpStartTime[client] = time;
						SetupProgressBar(client, g_fSelfHelp_Duration);
						PrintHintText(client, "%t", "Helping Yourself");
					}
				}
				else
				{
					if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
					ShowBar(client,"self help ", time-HelpStartTime[client], g_fSelfHelp_Duration);
				}
				
				HelpState[client] = STATE_SELFHELP;
				
				//PrintToChatAll("%f  %f", time-HelpStartTime[client], g_fSelfHelp_Duration);
				
				if(time - HelpStartTime[client] > g_fSelfHelp_Duration)
				{
					if(HelpState[client] != STATE_OK)
					{
						SelfHelp(client);
						if(g_bL4D2) KillProgressBar(client);
					}
				}					
			}
			else if(HelpState[client] == STATE_SELFHELP)
			{
				if(g_bL4D2) KillProgressBar(client);
				HelpState[client] = STATE_NONE;
			}
		}
		else
		{
			if(HelpState[client] == STATE_SELFHELP)
			{
				if(g_bL4D2) KillProgressBar(client);
				else ShowBar(client, "self help ", 0.0, g_fSelfHelp_Duration);
				HelpState[client] = STATE_NONE;
			}
		}
	}
	
	if(g_bSelfHelp_EachOther)
	{
		if((buttons & IN_RELOAD))
		{
			float dis = 50.0;
			float pos[3];
			float targetVector[3];
			GetClientEyePosition(client, pos);
			
			bool findone=false;
			int other = 0;
			
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && target != client)
				{
					if(IsPlayerAlive(target))
					{
						if(GetClientTeam(target) == 2 && (IsPlayerIncapped(target) || IsPlayerGrapEdge(target)))
						{ 
							GetClientAbsOrigin(target, targetVector);
							float distance = GetVectorDistance(targetVector, pos);
							
							if(distance < dis)
							{
								findone = true;
								other = target;
								break;
							}
						}
					}
				}
			}
			
			if(findone)
			{
				char msg[30];
				Format(msg, sizeof(msg), "%t", "Helping Target", other);
				
				if(HelpOhterState[client] == STATE_NONE)
				{
					if(g_bL4D2)
					{
						SetupProgressBar(client, g_fSelfHelp_Duration);
						PrintHintText(client, msg);											 
					}
					
					PrintHintText(other, "%t", "Helping You", client);
					HelpStartTime[client] = time;
				}
				
				HelpOhterState[client] = STATE_SELFHELP;
				
				if(!g_bL4D2) ShowBar(client, msg, time - HelpStartTime[client], g_fSelfHelp_Duration);
				
				if(time-HelpStartTime[client] > g_fSelfHelp_Duration)
				{
					HelpOther(other, client);
					HelpOhterState[client] = STATE_NONE;
					if(g_bL4D2) KillProgressBar(client);							
 				}
			}
			else
			{
				if(HelpOhterState[client] != STATE_NONE)
				{
					if(g_bL4D2) KillProgressBar(client);
					else ShowBar(client, "help other", 0.0, g_fSelfHelp_Duration);
				}
				HelpOhterState[client] = STATE_NONE;
			}
		}
		else
		{
			if(HelpOhterState[client] != STATE_NONE)
			{
				if(g_bL4D2) KillProgressBar(client);
				else ShowBar(client, "help other", 0.0, g_fSelfHelp_Duration);
			}
			HelpOhterState[client] = STATE_NONE;
		}
	}
	
	if((buttons & IN_DUCK) && g_bSelfHelp_Pickup)
	{	
		bool pickup = false;
		float dis = 100.0;
 		int ent = -1;
		
		if(PillSlot == -1)
		{
 			float targetVector1[3];
			float targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			
			ent = -1;
			
			while((ent = FindEntityByClassname(ent, "weapon_pain_pills" )) != -1)
			{
				if(IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					
					if(GetVectorDistance(targetVector1  , targetVector2) < dis)
					{
						CheatCommand(client, "give", "pain_pills", "");
						//CheatCommand(client, "give", "pain_pills");
						RemoveEdict(ent);
						pickup = true;
						PrintHintText(client,"%t", "Found Pills");
						
						break;
					}
				}
 			}
			
			if(!pickup)
			{
				ent = -1;
				while((ent = FindEntityByClassname(ent, "weapon_adrenaline" )) != -1)
				{
					if(IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						
						if(GetVectorDistance(targetVector1  , targetVector2) < dis)
						{
							CheatCommand(client, "give", "adrenaline", "");
							//CheatCommand(client, "give", "adrenaline");
							RemoveEdict(ent);
							pickup = true;
							PrintHintText(client,"%t", "Found Adrenaline");
							
							break;
						}
					}
 				}
			}
		}
		
 		if(KidSlot == -1 && !pickup)
		{
 			float targetVector1[3];
			float targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			
			ent = -1;
			
			while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit" )) != -1)
			{
				if(IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2) < dis)
					{
						CheatCommand(client, "give", "first_aid_kit", "");
						//CheatCommand(client, "give", "first_aid_kit");
						RemoveEdict(ent);
						pickup = true;
						PrintHintText(client,"%t", "Found Medkit");
						
						break;
					}
				}
 			}
		}
		
 		if(GetPlayerWeaponSlot(client, 1) == -1 && !pickup)
		{
 			float targetVector1[3];
			float targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			
			ent = -1;
			
			while ((ent = FindEntityByClassname(ent,  "weapon_pistol" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					
					if(GetVectorDistance(targetVector1  , targetVector2) < dis)
					{
 						CheatCommand(client, "give", "pistol", "");
						//CheatCommand(client, "give", "pistol");
						RemoveEdict(ent);
						pickup = true;
						PrintHintText(client,"%t", "Found Pistol");
						
						break;
					}
				}
 			}
		}
	}
	
 	return Plugin_Continue;
}

void SelfHelp(int client)
{
 	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] == 0) 
		return;
	
	bool pills = HavePills(client);
	bool adrenaline = HaveAdrenaline(client);
	int slot = SelfHelpUseSlot(client);
	
	if(slot != -1)
	{
		int weaponslot = GetPlayerWeaponSlot(client, slot);
		
		if(slot == 4)
		{
			//Pildoras
			if(pills)
			{
				if(Attacker[client] != 0)
				{
					if(IsPlayerIncapped(client))
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
						ReviveClientWithPills(client);
					}
					else
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
					}
				}
				else
				{
					if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
					{
						RemovePlayerItem(client, weaponslot);
						ReviveClientWithHangingLedge(client);
					}
					else if(IsPlayerIncapped(client))
					{
						RemovePlayerItem(client, weaponslot);
						ReviveClientWithPills(client);
					}
				}
				CPrintToChatAll("%t", "Self Help with Pills", client);
			}
			//Adrenalina
			if(adrenaline)
			{
				if(Attacker[client] != 0)
				{
					if(IsPlayerIncapped(client))
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
						ReviveClientWithAdrenaline(client);
					}
					else
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
					}
				}
				else
				{
					if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
					{
						RemovePlayerItem(client, weaponslot);
						ReviveClientWithHangingLedge(client);
					}
					else if(IsPlayerIncapped(client))
					{
						RemovePlayerItem(client, weaponslot);
						ReviveClientWithAdrenaline(client);
					}
				}
				
				if(g_bSelfHelp_AdreEffect) SetAdrenalineTime(client, g_fSelfHelp_AdreEffectDuration);
				
				CPrintToChatAll("%t", "Self Help with Adrenaline", client);
			}
			
			HelpState[client] = STATE_OK;
			
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav");
		}
		else if(slot == 3)
		{
			if(Attacker[client] != 0)
			{
				if(IsPlayerIncapped(client))
				{
					RemovePlayerItem(client, weaponslot);
					if(g_bSelfHelp_Kill) KillAttack(client);
					ReviveClientWithKid(client);
				}
				else
				{
					if(GetClientHealth(client) < 100)
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
						ReviveClientWithKid(client);
					}
					else if(GetClientHealth(client) > 100)
					{
						RemovePlayerItem(client, weaponslot);
						if(g_bSelfHelp_Kill) KillAttack(client);
					}
					
					//RemovePlayerItem(client, weaponslot);
					//if(g_bSelfHelp_Kill) KillAttack(client);
					//ReviveClientWithKid(client);
				}
			}
			else
			{
				if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
				{
					RemovePlayerItem(client, weaponslot);
					ReviveClientWithKid(client);
				}
				else if(IsPlayerIncapped(client))
				{
					RemovePlayerItem(client, weaponslot);
					ReviveClientWithKid(client);
				}
			}
			
			HelpState[client] = STATE_OK;
			
			CPrintToChatAll("%t", "Self Help with Medkit", client);
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav");
		}
	}
	else
	{
		PrintHintText(client, "%t", "Self Help Failed");
		HelpState[client] = STATE_FAILED;
	}
}

void HelpOther(int client, int helper)
{
 	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] == 0)
		return;
	
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	int count = GetEntData(client, propincapcounter, 1);
	int countlimit = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	
	count++;
	if(count > countlimit) count = countlimit;
	
	CheatCommand(client, "give", "health", "");
	
	switch(g_iSelfHelp_TempOther)
	{
		case 0: SetRealHealth(client, g_iSelfHelp_OtherHP);
		case 1: SetTempHealth(client, g_iSelfHelp_OtherHP);
	}
	
	SetEntData(client, propincapcounter, count, 1);
	//if(count == countlimit)
	//{
	//	SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
	//	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	//}
	
 	CPrintToChatAll("%t", "Self Help Other", helper, client);  
}

void ReviveClientWithHangingLedge(int client)
{
	CheatCommand(client, "give", "health", "");
	
	switch(g_iSelfHelp_TempPills)
	{
		case 0: SetRealHealth(client, g_iSelfHelp_PillsHP);
		case 1: SetTempHealth(client, g_iSelfHelp_PillsHP);
	}
}

void ReviveClientWithPills(int client)
{
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	int count = GetEntData(client, propincapcounter, 1);
	int countlimit = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	
	count++;
	if(count > countlimit) count = countlimit;
	
	CheatCommand(client, "give", "health", "");
	
	switch(g_iSelfHelp_TempPills)
	{
		case 0: SetRealHealth(client, g_iSelfHelp_PillsHP);
		case 1: SetTempHealth(client, g_iSelfHelp_PillsHP);
	}
	
	SetEntData(client, propincapcounter, count, 1);
}

void ReviveClientWithAdrenaline(int client)
{
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	int count = GetEntData(client, propincapcounter, 1);
	int countlimit = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	
	count++;
	if(count > countlimit) count = countlimit;
	
	CheatCommand(client, "give", "health", "");
	
	switch(g_iSelfHelp_TempAdre)
	{
		case 0: SetRealHealth(client, g_iSelfHelp_AdreHP);
		case 1: SetTempHealth(client, g_iSelfHelp_AdreHP);
	}
	
	SetEntData(client, propincapcounter, count, 1);
}

void ReviveClientWithKid(int client)
{
	int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	
	CheatCommand(client, "give", "health", "");
	
	switch(g_iSelfHelp_TempKit)
	{
		case 0: SetRealHealth(client, g_iSelfHelp_KitHP);
		case 1: SetTempHealth(client, g_iSelfHelp_KitHP);
	}
	
	SetEntData(client, propincapcounter, 0, 1);
}

stock void SetRealHealth(int client, int Health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", Health);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
}

stock void SetTempHealth(int client, int Health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", 1);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", Health * 1.0);
}

stock void SetAdrenalineTime(int client, float duration)
{
    // Get CountdownTimer address
    static int timerAddress = -1;
    if(timerAddress == -1)
    {
        timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
    }
    
    //timerAddress + 4 = Duration
    //timerAddress + 8 = TimeStamp
    SetEntDataFloat(client, timerAddress + 4, duration);
    SetEntDataFloat(client, timerAddress + 8, GetGameTime() + duration);
    SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1, 1);
}

void KillAttack(int client)
{
	int a = Attacker[client];
	if(g_bSelfHelp_Kill && a != 0)
	{
		if(IsClientInGame(a) && GetClientTeam(a) == 3 &&  IsPlayerAlive(a))
		{
			ForcePlayerSuicide(a);
			if(g_bL4D2)	EmitSoundToAll(SOUND_KILL2, client); 
			else EmitSoundToAll(SOUND_KILL1, client); 
		}
	}
}

void ShowBar(int client, char[] msg, float pos, float max)
{
	int i;
	char ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	
	float GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum < 0.0)
		GaugeNum = 0.0;
 	for(i = 0; i < 100; i++)
		ChargeBar[i] = Gauge1[0];
	int p = RoundFloat(GaugeNum);
	
	if(p >= 0 && p < 100) ChargeBar[p] = Gauge3[0]; 
 	/* Display gauge */
	PrintCenterText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
}

bool HaveKid(int client)
{
	char weapon[32];
	int KidSlot = GetPlayerWeaponSlot(client, 3);
	
	if(KidSlot != -1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_first_aid_kit"))
			return true;
 	}
	return false;
}

bool HavePills(int client)
{
	char weapon[32];
	int KidSlot = GetPlayerWeaponSlot(client, 4);
	
	if(KidSlot != -1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_pain_pills"))
			return true;
 	}
	return false;
}

bool HaveAdrenaline(int client)
{
	char weapon[32];
	int KidSlot=GetPlayerWeaponSlot(client, 4);
	
	if(KidSlot != -1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_adrenaline"))
			return true;
 	}
	return false;
}

stock void CheatCommand(int client, const char[] command, const char[] parameter1, const char[] parameter2)
{
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock void SetupProgressBar(int client, float time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock void KillProgressBar(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}

bool IsPlayerGrapEdge(int client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}
