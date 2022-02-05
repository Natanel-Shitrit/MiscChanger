#include <sourcemod>
#include <sdktools>
#include <MiscChanger>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define FLAIRS_CATEGORY_IDENTIFIER "flairs"
#define FLAIRS_CATEGORY_DISPLAY_NAME "Flairs"
#define FLAIRS_CATEGORY_DESCRIPTION "Flairs are shown on the scoreboard"

#define CATEGORY_IDENTIFIER "coins"
#define CATEGORY_DISPLAY_NAME "Coins"
#define CATEGORY_DESCRIPTION "Select your in-game coin"

#define ITEM_TYPE "coin"
#define ITEM_DEF_INDEX_ATTRIBUTE "def_index"

#define MEDAL_CATEGORY_SEASON_COIN 5
Handle g_hSetRank;

int g_ResetFlairFromInventoryOffset;

public Plugin myinfo = 
{
	name = "[MiscChanger] "... CATEGORY_DISPLAY_NAME ..." Module",
	author = "Natanel 'LuqS'",
	description = "A module for the MiscChager plugin that allows players to change thier in-game "... CATEGORY_DISPLAY_NAME ..."!",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public void OnPluginStart()
{
	LoadGameData();
}

public void OnPluginEnd()
{
	// TODO: Unregister from MiscChanger
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "MiscChanger"))
	{
		if (MiscChanger_RegisterCategory(FLAIRS_CATEGORY_IDENTIFIER, FLAIRS_CATEGORY_DISPLAY_NAME, FLAIRS_CATEGORY_DESCRIPTION))
		{
			MiscChanger_AddItemToCategory(FLAIRS_CATEGORY_IDENTIFIER, MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER);
		}

		if (!MiscChanger_RegisterCategory(CATEGORY_IDENTIFIER, CATEGORY_DISPLAY_NAME, CATEGORY_DESCRIPTION))
		{
			SetFailState("Failed to register module category. ("... CATEGORY_IDENTIFIER ...", "... CATEGORY_DISPLAY_NAME ...", "... CATEGORY_DESCRIPTION ...")");
		}

		MiscChanger_AddItemToCategory(CATEGORY_IDENTIFIER, FLAIRS_CATEGORY_IDENTIFIER);

		if (eItems_AreItemsSynced())
		{
			eItems_OnItemsSynced();
		}
	}
}

public void eItems_OnItemsSynced()
{
	RegisterCoin("default" ... ITEM_TYPE, 0, -1, "Default");

	int num_of_coinsets = eItems_GetCoinsSetsCount();
	for (int current_coinset; current_coinset < num_of_coinsets; current_coinset++)
	{
		RegisterCoinSet(current_coinset);
	}

	for (int current_coin, num_of_coins = eItems_GetCoinsCount(); current_coin < num_of_coins; current_coin++)
	{
		RegisterCoinFromCoinNumber(current_coin);
	}
}

void RegisterCoinSet(int coinset_number)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), "coinset%d", coinset_number);
	eItems_GetCoinSetDisplayNameByCoinSetNum(coinset_number, display_name, sizeof(display_name));

	MiscChanger_RegisterCategory(identifier, display_name, "A coinset");
	MiscChanger_AddItemToCategory(identifier, CATEGORY_IDENTIFIER);
}

void RegisterCoinFromCoinNumber(int coin_number)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), ITEM_TYPE ... "%d", coin_number);

	eItems_GetCoinDisplayNameByCoinNum(coin_number, display_name, sizeof(display_name));

	RegisterCoin(identifier, eItems_GetCoinDefIndexByCoinNum(coin_number), GetCoinCoinset(coin_number), display_name);
}

void RegisterCoin(const char[] identifier, int value, int coinset, const char[] display_name)
{
	if (!MiscChanger_RegisterItem(identifier, display_name))
	{
		ThrowError("Failed to register %s (%s)", display_name, identifier);
	}

	char value_str[11];
	IntToString(value, value_str, sizeof(value_str));
	MiscChanger_SetItemAttribute(identifier, ITEM_DEF_INDEX_ATTRIBUTE, value_str);

	char current_coinset_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	if (coinset != -1)
	{
		Format(current_coinset_identifier, sizeof(current_coinset_identifier), "coinset%d", coinset);
	}
	
	if (!MiscChanger_AddItemToCategory(identifier, current_coinset_identifier[0] ? current_coinset_identifier : CATEGORY_IDENTIFIER))
	{
		ThrowError("Failed to add item %s (%s) to module category.", display_name, identifier);
	}
}

int GetCoinCoinset(int coin_num)
{
	for (int current_coinset, num_of_coinsets = eItems_GetCoinsSetsCount(); current_coinset < num_of_coinsets; current_coinset++)
	{
		if (eItems_IsCoinInSet(coin_num, eItems_GetCoinSetIdByCoinSetNum(current_coinset)))
		{
			return current_coinset;
		}
	}
	
	return -1;
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier)
{
	// Check if it's a music kit
	char coin_def_index_str[11];
	if (StrContains(item_identifier, ITEM_TYPE) == -1 ||
		!MiscChanger_GetItemAttribute(item_identifier, ITEM_DEF_INDEX_ATTRIBUTE, coin_def_index_str, sizeof(coin_def_index_str)))
	{
		return false;
	}

	int coin_def_index = StringToInt(coin_def_index_str);

	// Apply if it is.
	ApplyCoin(client, coin_def_index);

	// Get display name.
	char display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	eItems_GetCoinDisplayNameByDefIndex(coin_def_index, display_name, sizeof(display_name));

	// Show message.
	PrintToChat(client, "%s Changed to the \x02%s\x01 Coin", MISC_CHANGER_PREFIX, coin_def_index ? display_name : "Default");

	// Re-open the menu.
	MiscChanger_OpenLastMenuFolding(client);

	// Don't delete the menu foldings.
	return false;
}

public void ApplyCoin(int client, int new_value)
{
	if (new_value)
	{
		SDKCall(g_hSetRank, client, MEDAL_CATEGORY_SEASON_COIN, new_value);
	}
	else // Default
	{
		SetEntData(client, g_ResetFlairFromInventoryOffset, 1, 1);
	}
}

// Don't let CS:GO load the default music-kit from the client inventory.
public void OnClientPutInServer(int client)
{
	/*
		if (!IsFakeClient(client))
		{
			SetEntData(client, g_ResetFlairFromInventoryOffset, 0, 1);
		}
	*/
}

void LoadGameData()
{
	GameData hGameData = new GameData("misc.game.csgo");
	
	if(!hGameData)
	{
		SetFailState("'sourcemod/gamedata/misc.game.csgo.txt' is missing!");
	}
		
	// https://github.com/perilouswithadollarsign/cstrike15_src/blob/29e4c1fda9698d5cebcdaf1a0de4b829fa149bf8/game/server/cstrike15/cs_player.cpp#L16369-L16372
	// Changes the the rank of the player ( this case use is the coin )
	// void CCSPlayer::SetRank( MedalCategory_t category, MedalRank_t rank )
	StartPrepSDKCall(SDKCall_Player);
	
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::SetRank"); // void
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalCategory_t category
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalRank_t rank
	
	if (!(g_hSetRank = EndPrepSDKCall()))
	{
		SetFailState("Failed to get CCSPlayer::SetRank signature");
	}

	int m_unMusicID = FindSendPropInfo("CCSPlayer", "m_unMusicID");
	
	g_ResetFlairFromInventoryOffset = m_unMusicID + hGameData.GetOffset("ResetCoinFromInventory");

	delete hGameData;
}