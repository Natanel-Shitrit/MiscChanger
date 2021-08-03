#include <sourcemod>
#include <sdktools>
#include <MiscChangerDev>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "Pin"
#define MEDAL_CATEGORY_SEASON_COIN 5

int g_ModuleIndex = -1;

ArrayList g_Pins;

Handle g_hSetRank;
int g_ResetCoinFromInventoryOffset;

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

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "MiscChanger"))
	{
		if (g_ModuleIndex == -1 && eItems_AreItemsSynced())
		{
			g_ModuleIndex = MiscChanger_RegisterItem(MODULE_NAME, null, g_Pins.Clone(), ApplyPin, "Flair");
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

public void MiscChanger_OnItemRemoved(int index)
{
	if (g_ModuleIndex > index)
	{
		g_ModuleIndex--;
	}
}

public void eItems_OnItemsSynced()
{
	// Load Pins
	g_Pins = new ArrayList(sizeof(ItemValue));
	
	ItemValue current_item;
	for (int current_pin = 0; current_pin < eItems_GetPinsCount(); current_pin++)
	{
		IntToString(eItems_GetPinDefIndexByPinNum(current_pin), current_item.value, sizeof(ItemValue::value));
		eItems_GetPinDisplayNameByPinNum(current_pin, current_item.display_name, sizeof(ItemValue::display_name));
		
		g_Pins.PushArray(current_item);
	}
	
	if (g_ModuleIndex != -1 && LibraryExists("MiscChanger"))
	{
		g_ModuleIndex = MiscChanger_RegisterItem(MODULE_NAME, null, g_Pins.Clone(), ApplyPin, "Flair");
	}
}

public void ApplyPin(int client, const char[] new_value)
{
	int value = StringToInt(new_value);
	if (value)
	{
		SDKCall(g_hSetRank, client, MEDAL_CATEGORY_SEASON_COIN, value);
	}
	else // Default
	{
		SetEntData(client, g_ResetCoinFromInventoryOffset, 1, 1);
	}
} 

void LoadGameData()
{
	GameData hGameData = new GameData("misc.game.csgo");
	
	if(!hGameData)
		SetFailState("'sourcemod/gamedata/misc.game.csgo.txt' is missing!");
	
	// https://github.com/perilouswithadollarsign/cstrike15_src/blob/29e4c1fda9698d5cebcdaf1a0de4b829fa149bf8/game/server/cstrike15/cs_player.cpp#L16369-L16372
	// Changes the the rank of the player ( this case use is the pin )
	// void CCSPlayer::SetRank( MedalCategory_t category, MedalRank_t rank )
	StartPrepSDKCall(SDKCall_Player);
	
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::SetRank"); // void
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalCategory_t category
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalRank_t rank
	
	if (!(g_hSetRank = EndPrepSDKCall()))
		SetFailState("Failed to get CCSPlayer::SetRank signature");
	
	int m_unMusicID = FindSendPropInfo("CCSPlayer", "m_unMusicID");
	
	g_ResetCoinFromInventoryOffset = m_unMusicID + hGameData.GetOffset("ResetCoinFromInventory");
	
	delete hGameData;
}