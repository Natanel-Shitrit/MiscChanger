#include <sourcemod>
#include <sdktools>
#include <MiscChangerDev>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "Coin"
#define MEDAL_CATEGORY_SEASON_COIN 5

ArrayList g_Categories;
ArrayList g_Coins;

Handle g_hSetRank;
int g_ResetCoinFromInventoryOffset;

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
		if (!g_Coins)
		{
			LoadCoins();
		}
		
		MiscChanger_RegisterItem(MODULE_NAME, g_Categories, g_Coins, ApplyCoin);
		
		// We don't need this anymore.
		delete g_Coins;
	}
}

public void eItems_OnItemsSynced()
{
	LoadCoins();
	
	if (MiscChanger_IsCoreReady())
	{
		MiscChanger_OnCoreReady();
	}
}

void LoadCoins()
{
	int num_of_coinsets = eItems_GetCoinsSetsCount();
	
	g_Categories = new ArrayList(MAX_ITEM_NAME_LENGTH);
	char current_category_name[MAX_ITEM_NAME_LENGTH];
	for (int current_coinset = 0; current_coinset < num_of_coinsets; current_coinset++)
	{
		eItems_GetCoinSetDisplayNameByCoinSetNum(current_coinset, current_category_name, MAX_ITEM_NAME_LENGTH);
		g_Categories.PushString(current_category_name);
	}
	
	g_Coins = new ArrayList(sizeof(ItemData));
	ItemData current_item;
	for (int current_coin = 0; current_coin < eItems_GetCoinsCount(); current_coin++)
	{
		IntToString(eItems_GetCoinDefIndexByCoinNum(current_coin), current_item.value, sizeof(ItemData::value));
		eItems_GetCoinDisplayNameByCoinNum(current_coin, current_item.name, sizeof(ItemData::name));
		
		for (int current_coinset = 0; current_coinset < num_of_coinsets; current_coinset++)
		{
			if (eItems_IsCoinInSet(current_coin, eItems_GetCoinSetIdByCoinSetNum(current_coinset)))
			{
				current_item.category_index = current_coinset;
				break;
			}
		}
		
		g_Coins.PushArray(current_item);
	}
}

public void ApplyCoin(int client, const char[] new_value)
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
	
	if (!hGameData)
		SetFailState("'sourcemod/gamedata/misc.game.csgo.txt' is missing!");
	
	// https://github.com/perilouswithadollarsign/cstrike15_src/blob/29e4c1fda9698d5cebcdaf1a0de4b829fa149bf8/game/server/cstrike15/cs_player.cpp#L16369-L16372
	// Changes the the rank of the player ( this case use is the coin )
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