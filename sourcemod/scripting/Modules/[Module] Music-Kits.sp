#include <sourcemod>
#include <MiscChangerDev>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "Music-Kit"

int g_ModuleIndex = -1;

ArrayList g_MusicKits;

int g_ResetMusicKitFromInventoryOffset;

public Plugin myinfo = 
{
	name = "[MiscChanger] "... MODULE_NAME ..." Module",
	author = "Natanel 'LuqS'",
	description = "A module for the MiscChager plugin that allows players to change thier in-game "... MODULE_NAME ..."!",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public void OnPluginStart()
{
	LoadGameData();
	
	if (eItems_AreItemsSynced())
	{
		eItems_OnItemsSynced();
	}
}

public void OnPluginEnd()
{
	MiscChanger_RemoveItem(g_ModuleIndex);
}

public void MiscChanger_OnItemRemoved(int index)
{
	if (g_ModuleIndex > index)
	{
		g_ModuleIndex--;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "MiscChanger"))
	{
		if (g_ModuleIndex == -1 && eItems_AreItemsSynced())
		{
			g_ModuleIndex = MiscChanger_RegisterItem(MODULE_NAME, null, g_MusicKits.Clone(), ApplyMusicKit);
		}
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "MiscChanger"))
	{
		g_ModuleIndex = -1;
	}
}

public void eItems_OnItemsSynced()
{
	// Load Music-Kits
	g_MusicKits = new ArrayList(sizeof(ItemValue));
	
	// VALVE Music-Kits
	ItemValue valve_musickit;
	for (int current_musickit = 1; current_musickit <= 2; current_musickit++)
	{
		IntToString(current_musickit, valve_musickit.value, MAX_ITEM_VALUE_LENGTH);
		Format(valve_musickit.display_name, MAX_ITEM_NAME_LENGTH, "VALVE Music-Kit %d", current_musickit);
		
		g_MusicKits.PushArray(valve_musickit);
	}
	
	// Community Music-Kits
	ItemValue current_item;
	for (int current_musickit = 0; current_musickit < eItems_GetMusicKitsCount(); current_musickit++)
	{
		IntToString(eItems_GetMusicKitDefIndexByMusicKitNum(current_musickit), current_item.value, sizeof(ItemValue::value));
		eItems_GetMusicKitDisplayNameByMusicKitNum(current_musickit, current_item.display_name, sizeof(ItemValue::display_name));
		
		g_MusicKits.PushArray(current_item);
	}
	
	if (g_ModuleIndex != -1 && LibraryExists("MiscChanger"))
	{
		g_ModuleIndex = MiscChanger_RegisterItem(MODULE_NAME, null, g_MusicKits.Clone(), ApplyMusicKit);
	}
}

public void ApplyMusicKit(int client, const char[] new_value)
{
	int musickit_num = StringToInt(new_value);
	if (musickit_num)
	{
		SetEntProp(client, Prop_Send, "m_unMusicID", musickit_num);
	}
	else // Default
	{
		SetEntData(client, g_ResetMusicKitFromInventoryOffset, 1, 1);
	}
}

// Don't let CS:GO load the default music-kit from the client inventory.
public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SetEntData(client, g_ResetMusicKitFromInventoryOffset, 0, 1);
	}
}

void LoadGameData()
{
	GameData hGameData = new GameData("misc.game.csgo");
	
	if(!hGameData)
	{
		SetFailState("'sourcemod/gamedata/misc.game.csgo.txt' is missing!");
	}
		
	int m_unMusicID = FindSendPropInfo("CCSPlayer", "m_unMusicID");
	
	g_ResetMusicKitFromInventoryOffset = m_unMusicID + hGameData.GetOffset("ResetMusicKitFromInventory");
	
	delete hGameData;
}