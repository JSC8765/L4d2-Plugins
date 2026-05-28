/**
 * [VIP] Fast Reload - Module
 * 
 * Creado por: Pizza baiana
 *	▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
 *	Plugin Name:       "PERKAHOLIC_WEAPONS"
 *	Description:       "Increase the reload speed of all weapons in the game."
 *	Version:           "1.0"
 *	Plugin URL:        "https://forums.alliedmods.net/showthread.php?p=2805605"
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

#define PLUGIN_VERSION "1.0.1"

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <WeaponHandling>

#include <vip_core>
#define FEATURE_NAME "L4d2_FastReload"

public Plugin myinfo = 
{
	name		= "[VIP] Fast Reload",
	author		= "Pizza baiana, edited by Mr.Creamy",
	description	= "Increase the reload speed of all weapons in the game.",
	version		= PLUGIN_VERSION,
	url			= "https://discord.gg/vezaFCGFd3"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports \"Left 4 Dead 2\" game ");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(FEATURE_NAME, BOOL);
}

public void OnPluginEnd()
{
	VIP_UnregisterFeature(FEATURE_NAME);
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	if (VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, FEATURE_NAME))
	{
		switch(weapontype)
		{
			case L4D2WeaponType_Pistol:				speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_Magnum:				speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_Rifle:				speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_RifleAk47:			speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_RifleDesert: 		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_RifleM60:			speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_RifleSg552:			speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_HuntingRifle:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SniperAwp:			speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SniperMilitary:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SniperScout:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SMG:				speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SMGSilenced:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_SMGMp5:				speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_Autoshotgun:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_AutoshotgunSpas:	speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_Pumpshotgun:		speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_PumpshotgunChrome:	speedmodifier = speedmodifier * 3.00;
			case L4D2WeaponType_GrenadeLauncher:	speedmodifier = speedmodifier * 3.00;
		}
	}
}