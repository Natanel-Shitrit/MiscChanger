#include <sourcemod>
#include <MiscChangerDev>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "Music-Kit"

ArrayList g_MusicKits;

int g_ResetMusicKitFromInventoryOffset;

public void OnPluginStart()
{
	LoadGameData();
	
	if (eItems_AreItemsSynced())
	{
		eItems_OnItemsSynced();
	}
}

public void MiscChanger_OnCoreReady()
{
	if (eItems_AreItemsSynced())
	{
		if (!g_MusicKits)
		{
			LoadMusicKits();
		}
		
		MiscChanger_RegisterItem(MODULE_NAME, null, g_MusicKits, ApplyMusicKit);
	}
}

public void eItems_OnItemsSynced()
{
	LoadMusicKits();
	
	if (MiscChanger_IsCoreReady())
	{
		MiscChanger_OnCoreReady();
	}
}

void LoadMusicKits()
{
	g_MusicKits = new ArrayList(sizeof(ItemData));
	
	// VALVE Music-Kits
	for (int current_musickit = 1; current_musickit <= 2; current_musickit++)
	{
		ItemData valve_musickit;
		IntToString(current_musickit, valve_musickit.value, MAX_ITEM_VALUE_LENGTH);
		Format(valve_musickit.name, MAX_ITEM_NAME_LENGTH, "VALVE Music-Kit %d", current_musickit);
		g_MusicKits.PushArray(valve_musickit);
	}
	
	// Community Music-Kits
	ItemData current_item;
	for (int current_musickit = 0; current_musickit < eItems_GetMusicKitsCount(); current_musickit++)
	{
		IntToString(eItems_GetMusicKitDefIndexByMusicKitNum(current_musickit), current_item.value, sizeof(ItemData::value));
		eItems_GetMusicKitDisplayNameByMusicKitNum(current_musickit, current_item.name, sizeof(ItemData::name));
		
		g_MusicKits.PushArray(current_item);
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