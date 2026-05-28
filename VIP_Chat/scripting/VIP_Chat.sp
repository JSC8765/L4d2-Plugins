//------------------------------------------------------------------------------
// GPL LISENCE (short)
//------------------------------------------------------------------------------
/*
 * Copyright (c) 2014 R1KO

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
//------------------------------------------------------------------------------
*/

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <clientprefs>
#include <vip_core>
#include <simple_chatprocessor>

public Plugin myinfo = 
{
	name		= "[VIP] CHAT (scp)",
	author		= "R1KO, edited by Mr.Creamy",
	version		= "3.1.3"
}

enum
{
	PREFIX = 0,
	PREFIX_COLOR,
	NAME_COLOR,
	TEXT_COLOR,

	SIZE
};

char g_sFeature[] = "Chat";
char g_sCUSTOM[] = "custom";
char g_sLIST[] = "list";
char g_sFeatures[SIZE][] = { "Chat_Prefix", "Chat_PrefixColor", "Chat_NameColor", "Chat_TextColor" };

Handle g_hCookies[SIZE], g_hKeyValues, g_hIgnoredPhrases, g_hColorsTrie;

bool g_bIgnoreTriggers, g_bIgnorePhrases;

bool g_bWaitChat[MAXPLAYERS+1];

public void OnPluginStart() 
{
	g_hColorsTrie = CreateTrie();
	
	g_hCookies[0]	= RegClientCookie("VIP_Chat_Prefix", "VIP_Chat_Prefix", CookieAccess_Private);
	g_hCookies[1]	= RegClientCookie("VIP_Chat_PrefixColor", "VIP_Chat_PrefixColor", CookieAccess_Private);
	g_hCookies[2]	= RegClientCookie("VIP_Chat_NameColor", "VIP_Chat_NameColor", CookieAccess_Private);
	g_hCookies[3]	= RegClientCookie("VIP_Chat_TextColor", "VIP_Chat_TextColor", CookieAccess_Private);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	RegConsoleCmd("sm_charla", Command_ChatMenu);
	
	LoadTranslations("vip_chat.phrases");
	LoadTranslations("vip_core.phrases");
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnSelectItem);
	VIP_RegisterFeature(g_sFeatures[PREFIX], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[PREFIX_COLOR], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[NAME_COLOR], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[TEXT_COLOR], STRING, HIDE);
}

public void OnPluginEnd()
{
	VIP_UnregisterFeature(g_sFeature);
	VIP_UnregisterFeature(g_sFeatures[PREFIX]);
	VIP_UnregisterFeature(g_sFeatures[PREFIX_COLOR]);
	VIP_UnregisterFeature(g_sFeatures[NAME_COLOR]);
	VIP_UnregisterFeature(g_sFeatures[TEXT_COLOR]);
}

public Action Command_ChatMenu(int iClient, int args)
{
	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		DisplayChatMainMenu(iClient);
	}
	else VIP_PrintToChatClient(iClient, "%t", "COMMAND_NO_ACCESS");
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	char sBuffer[256];

	if(g_hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_hKeyValues);
	}
	
	ClearTrie(g_hColorsTrie);
	
	g_hKeyValues = CreateKeyValues("Chat");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/chat_config.ini");
	
	if (FileToKeyValues(g_hKeyValues, sBuffer) == false)
	{
		CloseHandle(g_hKeyValues);
		SetFailState("No se encontró el archivo: \"%s\"", sBuffer);
	}
	
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Settings"))
	{
		g_bIgnoreTriggers = view_as<bool>(KvGetNum(g_hKeyValues, "ignore_chat_triggers"));
		g_bIgnorePhrases = view_as<bool>(KvGetNum(g_hKeyValues, "ignore_chat_phrases"));
	}
	
	if(g_hIgnoredPhrases != INVALID_HANDLE)
	{
		CloseHandle(g_hIgnoredPhrases);
	}
	
	g_hIgnoredPhrases = CreateArray(ByteCountToCells(64));
	
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Ignore"))
	{
		if(KvGotoFirstSubKey(g_hKeyValues, false))
		{
			do
			{
				KvGetString(g_hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
				PushArrayString(g_hIgnoredPhrases, sBuffer);
			}while (KvGotoNextKey(g_hKeyValues, false));
		}
	}
	
	if(!GetArraySize(g_hIgnoredPhrases))
	{
		CloseHandle(g_hIgnoredPhrases);
		g_hIgnoredPhrases = INVALID_HANDLE;
	}
	
	LoadColors("NameColor_List");
	LoadColors("TextColor_List");
	LoadColors("PrefixColor_List");
	LoadColors("PrefixColor2_List");
}

void LoadColors(const char[] sKey)
{
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, sKey) && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		char sColorCode[16], sColorName[32];
		do
		{
			KvGetSectionName(g_hKeyValues, sColorName, sizeof(sColorName));
			KvGetString(g_hKeyValues, NULL_STRING, sColorCode, sizeof(sColorCode));
			SetTrieString(g_hColorsTrie, sColorCode, sColorName);
		}while (KvGotoNextKey(g_hKeyValues, false));
	}
}

public Action OnChatMessage2(int iOriginalAuthor, int &Author, ArrayList hRecipients, char[] sName, int maxlength_name, char[] sMessage, int maxlength_message)
{
	if(VIP_IsClientVIP(iOriginalAuthor) && VIP_IsClientFeatureUse(iOriginalAuthor, g_sFeature))
	{
		if(g_bIgnoreTriggers &&
			(sMessage[0] == '!' ||
			sMessage[0] == '/' ||
			sMessage[0] == '@'))
		{
			return Plugin_Continue;
		}
		
		if(g_bIgnorePhrases && g_hIgnoredPhrases && FindStringInArray(g_hIgnoredPhrases, sMessage) != -1)
		{
			return Plugin_Continue;
		}
		
		/*
		for(new iSize = GetArraySize(hRecipients), x, i = 0; i < iSize; ++i)
		{
			x = GetArrayCell(hRecipients, i);
			if(IsClientInGame(x) || !IsPlayerAlive(x))
			RemoveFromArray(hRecipients, i);
		}
		*/
		
		char sBuffer[192];
		if(GetClientChat(iOriginalAuthor, TEXT_COLOR, sBuffer, sizeof(sBuffer)))
		{
			Format(sMessage, MAXLENGTH_MESSAGE, "%s%s", sBuffer, sMessage);
		}
		
		if(GetClientChat(iOriginalAuthor, NAME_COLOR, sBuffer, sizeof(sBuffer)))
		{
			Format(sName, MAXLENGTH_NAME, "%s%s", sBuffer, sName);
		}
		else
		{
			Format(sName, MAXLENGTH_NAME, "\x03%s", sName);
		}
		
		if(GetClientChat(iOriginalAuthor, PREFIX, sBuffer, sizeof(sBuffer)))
		{
			Format(sName, MAXLENGTH_NAME, "%s %s", sBuffer, sName);
			
			if(GetClientChat(iOriginalAuthor, PREFIX_COLOR, sBuffer, sizeof(sBuffer)))
			{
				Format(sName, MAXLENGTH_NAME, "%s%s", sBuffer, sName);
			}
		}
		
		ReplaceStringColors(sName, MAXLENGTH_NAME);
		ReplaceStringColors(sMessage, MAXLENGTH_MESSAGE);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

bool GetClientChat(int iClient, int index, char[] sBuffer, int iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
	{
		VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, iMaxLen);
		if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
		{
			GetClientCookie(iClient, g_hCookies[index], sBuffer, iMaxLen);
		}
		else
		{
			char sCookie[4];
			GetClientCookie(iClient, g_hCookies[index], sCookie, sizeof(sCookie));
			if(sCookie[0] == '0')
			{
				return false;
			}
		}
		
		if(sBuffer[0] == '0')
		{
			return false;
		}
		
		if(sBuffer[0])
		{
			return true;
		}
	}
	
	return false;
}

void ReplaceStringColors(char[] sMessage, int iMaxLen)
{
	ReplaceString(sMessage, iMaxLen, "{DEFAULT}", "\x01", false);
	ReplaceString(sMessage, iMaxLen, "{TEAM}", "\x03", false);
	ReplaceString(sMessage, iMaxLen, "{GREEN}",	"\x04", false);
	ReplaceString(sMessage, iMaxLen, "{OLIVE}", "\x05", false);
}

public bool OnSelectItem(int iClient, const char[] sFeatureName)
{
	DisplayChatMainMenu(iClient);
	
	return false;
}

void DisplayChatMainMenu(int iClient)
{
	SetGlobalTransTarget(iClient);
	
	char sBuffer[128];
	Handle hMenu = CreateMenu(ChatMainMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MainMenuTitle");
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "DisableAll");
	AddMenuItem(hMenu, "", sBuffer);
	
	AddMenuFeatureItem(iClient, PREFIX, hMenu, "Prefix");
	AddMenuFeatureItem(iClient, PREFIX_COLOR, hMenu, "PrefixColor");
	AddMenuFeatureItem(iClient, NAME_COLOR, hMenu, "NameColor");
	AddMenuFeatureItem(iClient, TEXT_COLOR, hMenu, "TextColor");
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void AddMenuFeatureItem(int iClient, int index, Handle & hMenu, const char[] sFeatureName)
{
	char sBuffer[128];
	if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
	{
		char sItemInfo[128];
		VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
		GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
		
		if(sItemInfo[0] == '0')
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", sFeatureName, "Disabled");
		}
		else
		{
			if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
			{
				if(sItemInfo[0])
				{
					GetTrieString(g_hColorsTrie, sItemInfo, sItemInfo, sizeof(sItemInfo));
					FormatEx(sBuffer, sizeof(sBuffer), "%t - %s", sFeatureName, sItemInfo);
				}
				else
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", sFeatureName, "NotChosen");
				}
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "%t - %s", sFeatureName, sBuffer);
			}
		}
		
		FormatEx(sItemInfo, sizeof(sItemInfo), "%i_%s", index, sFeatureName);
		AddMenuItem(hMenu, sItemInfo, sBuffer);
	}
	else
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t (%t)", sFeatureName, "NoAccess");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
}

public int ChatMainMenu_Handler(Handle hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			char sBuffer[128];
			int index;
			if(Item == 0)
			{
				for(index = 0; index < 4; ++index)
				{
					if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
					{
						VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
						if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
						{
							SetClientCookie(iClient, g_hCookies[index], "");
						}
						else
						{
							SetClientCookie(iClient, g_hCookies[index], "0");
						}
					}
				}
				
				DisplayChatMainMenu(iClient);
				
				return 0;
			}
			
			char sItemInfo[128];
			GetMenuItem(hMenu, Item, sItemInfo, sizeof(sItemInfo));
			
			index = sItemInfo[0]-48;
			
			VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
			Handle hTrie = VIP_GetVIPClientTrie(iClient);
			
			SetTrieString(hTrie, "Chat_MenuType", sItemInfo[2]);
			SetTrieValue(hTrie, "Chat_CookieIndex", index);
			
			if(strcmp(sBuffer, g_sCUSTOM) == 0)
			{
				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
				if(sItemInfo[0] == '0')
				{
					sItemInfo[0] = 0;
				}
				
				DisplayWaitChatMenu(iClient, sItemInfo, false, index);
			}
			else if(strcmp(sBuffer, g_sLIST) == 0)
			{
				DisplayChatListMenu(iClient, sItemInfo[2], index);
			}
			else
			{
				RemoveFromTrie(hTrie, "Chat_MenuType");
				RemoveFromTrie(hTrie, "Chat_CookieIndex");
				
				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
				
				bool bEnable;
				if(sItemInfo[0])
				{
					bEnable = view_as<bool>(StringToInt(sItemInfo));
				}
				else
				{
					bEnable = true;
				}
				
				bEnable = !bEnable;
				SetClientCookie(iClient, g_hCookies[index], bEnable ? "":"0");
				
				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
				
				DisplayChatMainMenu(iClient);
			}
		}
	}
	
	return 0;
}

void DisplayChatListMenu(int iClient, const char[] sKey, int index)
{
	SetGlobalTransTarget(iClient);
	
	char sBuffer[128], sClientColor[64];
	Handle hMenu = CreateMenu(ChatListMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	
	SetMenuTitle(hMenu, "%t:\n ", sKey);
	GetClientCookie(iClient, g_hCookies[index], sClientColor, sizeof(sClientColor));
	
	if(sClientColor[0] && sClientColor[0] != '0')
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Disable");
		AddMenuItem(hMenu, "_disable", sBuffer);
	}
	
	KvRewind(g_hKeyValues);
	FormatEx(sBuffer, sizeof(sBuffer), "%s_List", sKey);
	if(KvJumpToKey(g_hKeyValues, sBuffer) && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		sBuffer[0] = 0;
		char sColor[64];
		do
		{
			KvGetString(g_hKeyValues, NULL_STRING, sColor, sizeof(sColor));
			KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));
			if(strcmp(sClientColor, sColor) == 0)
			{
				Format(sBuffer, sizeof(sBuffer), "%s (%t)", sBuffer, "Selected");
				AddMenuItem(hMenu, sColor, sBuffer, ITEMDRAW_DISABLED);
				continue;
			}
			
			AddMenuItem(hMenu, sColor, sBuffer);
		}while (KvGotoNextKey(g_hKeyValues, false));
		
		if(sBuffer[0] == 0)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "NoItems");
			AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "NoItems");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int ChatListMenu_Handler(Handle hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayChatMainMenu(iClient);
		}
		case MenuAction_Select:
		{
			int index;
			char sColor[64], sColorName[128];
			GetMenuItem(hMenu, Item, sColor, sizeof(sColor), _, sColorName, sizeof(sColorName));
			
			Handle hTrie = VIP_GetVIPClientTrie(iClient);
			GetTrieValue(hTrie, "Chat_CookieIndex", index);
			
			if(strcmp(sColor, "_disable") == 0)
			{
				SetClientCookie(iClient, g_hCookies[index], "0");
				RemoveFromTrie(hTrie, "Chat_MenuType");
				RemoveFromTrie(hTrie, "Chat_CookieIndex");
				DisplayChatMainMenu(iClient);
				
				return 0;
			}
			
			char sBuffer[64];
			
			SetClientCookie(iClient, g_hCookies[index], sColor);
			
			GetTrieString(hTrie, "Chat_MenuType", sBuffer, sizeof(sBuffer));
			
			if(index == PREFIX)
			{
				VIP_PrintToChatClient(iClient, "\x01%t %t: \x04%s", "Set", sBuffer, sColorName);
			}
			else
			{
				VIP_PrintToChatClient(iClient, "\x01%t ->  %s%t", "Set", sColor, sBuffer);
			}
			
			DisplayChatListMenu(iClient, sBuffer, index);
		}
	}
	
	return 0;
}

void DisplayWaitChatMenu(int iClient, const char[] sValue = "", const bool bIsValid = false, const int index)
{
	if(!bIsValid)
	{
		g_bWaitChat[iClient] = true;
	}
	
	Handle hMenu = CreateMenu(WaitChatMenu_Handler);
	
	SetGlobalTransTarget(iClient);
	
	if(sValue[0])
	{
		SetMenuTitle(hMenu, "%t \"%t\"\n%t: %s\n ", "EnterValueInChat", "Confirm", "Value", sValue);
	}
	else
	{
		SetMenuTitle(hMenu, "%t \"%t\"\n ", "EnterValueInChat", "Confirm");
	}
	
	char sBuffer[128];
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Confirm");
	AddMenuItem(hMenu, sValue, sBuffer, bIsValid ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Cancel");
	AddMenuItem(hMenu, "", sBuffer);
	
	GetClientCookie(iClient, g_hCookies[index], sBuffer, sizeof(sBuffer));
	
	if(sBuffer[0] && sBuffer[0] != '0')
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Disable");
		AddMenuItem(hMenu, "_disable", sBuffer);
	}
	
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Help"))
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Help");
		AddMenuItem(hMenu, "_help", sBuffer);
	}
	else
	{
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	}
	
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int WaitChatMenu_Handler(Handle hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			g_bWaitChat[iClient] = false;
			if(Item == MenuCancel_ExitBack)
			{
				DisplayChatMainMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			int index;
			Handle hTrie = VIP_GetVIPClientTrie(iClient);
			GetTrieValue(hTrie, "Chat_CookieIndex", index);
			
			if(Item == 0)
			{
				char sBuffer[64], sColor[64];
				GetMenuItem(hMenu, Item, sColor, sizeof(sColor));
				
				SetClientCookie(iClient, g_hCookies[index], sColor);
				
				GetTrieString(hTrie, "Chat_MenuType", sBuffer, sizeof(sBuffer));
				
				if(index == PREFIX)
				{
					VIP_PrintToChatClient(iClient, "\x01%t %t: \x04%s", "Set", sBuffer, sColor);
				}
				else
				{
					VIP_PrintToChatClient(iClient, "\x01%t -> %s%t", "Set", sColor, sBuffer);
				}
			}
			else
			{
				char sBuffer[64];
				GetMenuItem(hMenu, Item, sBuffer, sizeof(sBuffer));
				if(strcmp(sBuffer, "_disable") == 0)
				{
					SetClientCookie(iClient, g_hCookies[index], "0");
				}
				else if(strcmp(sBuffer, "_help") == 0)
				{
					DisplayHelpMenu(iClient);
					
					return 0;
				}
			}
			
			RemoveFromTrie(hTrie, "Chat_MenuType");
			RemoveFromTrie(hTrie, "Chat_CookieIndex");
			g_bWaitChat[iClient] = false;
			DisplayChatMainMenu(iClient);
		}
	}
	
	return 0;
}

public Action Command_Say(int iClient, const char[] sCommand, int iArgs)
{
	if(iClient && iClient <= MaxClients && iArgs)
	{
		if(g_bWaitChat[iClient])
		{
			char sText[64];
			GetCmdArgString(sText, sizeof(sText));
			TrimString(sText);
			StripQuotes(sText);
			
			if(sText[0])
			{
				int index;
				GetTrieValue(VIP_GetVIPClientTrie(iClient), "Chat_CookieIndex", index);
				DisplayWaitChatMenu(iClient, sText, true, index);
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void DisplayHelpMenu(int iClient)
{
	SetGlobalTransTarget(iClient);
	
	char sBuffer[128];
	
	Handle hPanel = CreatePanel();
	FormatEx(sBuffer, sizeof(sBuffer), "%t:\n ", "Help");
	SetPanelTitle(hPanel, sBuffer);
	
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Help"))
	{
		if(KvGotoFirstSubKey(g_hKeyValues, false))
		{
			do
			{
				KvGetString(g_hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
				DrawPanelText(hPanel, sBuffer);
			}while (KvGotoNextKey(g_hKeyValues, false));
		}
	}
	
	DrawPanelItem(hPanel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	DrawPanelItem(hPanel, "<-");
	
	SendPanelToClient(hPanel, iClient, ChatInfoMenu_Handler, MENU_TIME_FOREVER); 
	CloseHandle(hPanel); 
}

public int ChatInfoMenu_Handler(Handle hMenu, MenuAction action, int iClient, int Item)
{
	if(action == MenuAction_Select)
	{
		int index;
		char sBuffer[64];
		GetTrieValue(VIP_GetVIPClientTrie(iClient), "Chat_CookieIndex", index);
		GetClientCookie(iClient, g_hCookies[index], sBuffer, sizeof(sBuffer));
		if(sBuffer[0] == '0')
		{
			sBuffer[0] = 0;
		}

		DisplayWaitChatMenu(iClient, sBuffer, false, index);
	}
	
	return 0;
}
