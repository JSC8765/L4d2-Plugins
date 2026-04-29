/**
 * [L4D.2] Hunter Advanced Jump - Fixed
 * 
 * Basado en el trabajo original de: King_OXO
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *	Plugin Name:       "[L4D2]Hunter Advanced Jump"
 *	Description:       "Allows hunter use advanced jumps"
 *	Version:           "1.0"
 *	Plugin URL:        "https://forums.alliedmods.net/showthread.php?p=2744447"
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *
 * LICENCIA:
 * Este plugin fue publicado originalmente en AlliedModders. Respetando
 * los derechos del autor original, este trabajo derivado se distribuye bajo 
 * la licencia GNU General Public License v3.
 *
 * MAYOR INFORMACIÓN:
 * Discord:	https://discord.gg/vezaFCGFd3
 * GitHub: 	https://github.com/JSC8765
*/

#define PLUGIN_VERSION		"fix 2.1"

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sdktools>
#include <sourcemod>

#define ZOMBIECLASS_HUNTER 3

public Plugin myinfo = 
{
	name		= "[L4D.2] Hunter Advanced Jump",
	author		= "King_OXO, editado por Mr.Creamy",
	description	= "Allows hunter use advanced jumps.",
	version		= PLUGIN_VERSION,
	url			= "https://discord.gg/vezaFCGFd3"
}

ConVar cvarJumpBoost;
ConVar cvarPluginEnable;
ConVar cvarJumpMax;

float vBoost;
bool AllowPlugin;
int Jumps[MAXPLAYERS+1];
int LastButtons[MAXPLAYERS+1];
int iJumps;

public void OnPluginStart() 
{
	CreateConVar("hunter_jump_version", PLUGIN_VERSION, "Hunter Advanced Jump Version", FCVAR_NOTIFY);
	
	cvarPluginEnable = CreateConVar("hunter_jump_enable", "1", "Enables Hunter Advanced Jump.", FCVAR_NOTIFY);
	cvarJumpBoost = CreateConVar("hunter_jump_boost", "300.0", "Hunter Jump Boost", FCVAR_NOTIFY);
	cvarJumpMax = CreateConVar("hunter_jump_max", "1", "Hunter Max Jumps", FCVAR_NOTIFY);
	
	cvarJumpBoost.AddChangeHook(convar_Change);
	cvarPluginEnable.AddChangeHook(convar_Change);
	cvarJumpMax.AddChangeHook(convar_Change);
	
	AllowPlugin = cvarPluginEnable.BoolValue;
	vBoost = cvarJumpBoost.FloatValue;
	iJumps = cvarJumpMax.IntValue;
	
	AutoExecConfig(true, "l4d2_hunter_multi_jump");
}

public void convar_Change(ConVar convar, const char[] oldVal, const char[] newVal)
{
	AllowPlugin = cvarPluginEnable.BoolValue;
	vBoost = cvarJumpBoost.FloatValue;
	iJumps = cvarJumpMax.IntValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!AllowPlugin || !IsPlayerAlive(client) || IsFakeClient(client)) return Plugin_Continue;

	if(IsValidHunter(client))
	{
		int fCurFlags = GetEntityFlags(client);
		
		// Si toca el suelo, reseteamos saltos
		if(fCurFlags & FL_ONGROUND)
		{
			Jumps[client] = 0;
		}
		else 
		{
			// Si presiona SALTO, no estaba presionándolo antes, y no está en el suelo
			if((buttons & IN_JUMP) && !(LastButtons[client] & IN_JUMP))
			{
				// Solo saltar si no ha superado el máximo
				if(Jumps[client] < iJumps)
				{
					PerformReJump(client);
				}
			}
		}
		LastButtons[client] = buttons;
	}
	
	return Plugin_Continue;
}

void PerformReJump(int client)
{
	Jumps[client]++;
	
	float vVel[3], vAng[3], vForward[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	GetClientEyeAngles(client, vAng);
	
	// Obtenemos la dirección hacia donde mira el Hunter
	GetAngleVectors(vAng, vForward, NULL_VECTOR, NULL_VECTOR);
	
	// Multiplicamos la dirección por el boost para que salte hacia ADELANTE y ARRIBA
	vVel[0] += vForward[0] * vBoost;
	vVel[1] += vForward[1] * vBoost;
	vVel[2] = vBoost * 1.2; // Fuerza vertical fija para asegurar el despegue

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
}

bool IsValidHunter(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		return (GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER);
	}
	return false;
}