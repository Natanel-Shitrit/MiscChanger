#include <sourcemod>
#include <sdktools>
#include <MiscChanger>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define FLAIRS_CATEGORY_IDENTIFIER "flairs"
#define FLAIRS_CATEGORY_DISPLAY_NAME "Flairs"
#define FLAIRS_CATEGORY_DESCRIPTION "Flairs are shown on the scoreboard"

#define CATEGORY_IDENTIFIER "pins"
#define CATEGORY_DISPLAY_NAME "Pins"
#define CATEGORY_DESCRIPTION "Select your in-game pin"

#define ITEM_TYPE "pin"
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
	RegisterPin("default" ... ITEM_TYPE, 0, "Default");

	for (int current_pin, num_of_pins = eItems_GetPinsCount(); current_pin < num_of_pins; current_pin++)
	{
		RegisterPinFromPinNumber(current_pin);
	}
}

void RegisterPinFromPinNumber(int pin_number)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), ITEM_TYPE ... "%d", pin_number);

	eItems_GetPinDisplayNameByPinNum(pin_number, display_name, sizeof(display_name));

	RegisterPin(identifier, eItems_GetPinDefIndexByPinNum(pin_number), display_name);
}

void RegisterPin(const char[] identifier, int value, const char[] display_name)
{
	if (!MiscChanger_RegisterItem(identifier, display_name))
	{
		ThrowError("Failed to register %s (%s)", display_name, identifier);
	}

	char value_str[11];
	IntToString(value, value_str, sizeof(value_str));
	MiscChanger_SetItemAttribute(identifier, ITEM_DEF_INDEX_ATTRIBUTE, value_str);

	if (!MiscChanger_AddItemToCategory(identifier, CATEGORY_IDENTIFIER))
	{
		ThrowError("Failed to add item %s (%s) to module category.", display_name, identifier);
	}
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier)
{
	// Check if it's a pin.
	char pin_def_index_str[11];
	if (StrContains(item_identifier, ITEM_TYPE) == -1 ||
		!MiscChanger_GetItemAttribute(item_identifier, ITEM_DEF_INDEX_ATTRIBUTE, pin_def_index_str, sizeof(pin_def_index_str)))
	{
		return false;
	}

	int pin_def_index = StringToInt(pin_def_index_str);

	// Apply if it is.
	ApplyPin(client, pin_def_index);

	// Get display name.
	char display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	eItems_GetPinDisplayNameByDefIndex(pin_def_index, display_name, sizeof(display_name));

	// Show message.
	PrintToChat(client, "%s Changed to the \x02%s\x01 Coin", MISC_CHANGER_PREFIX, pin_def_index ? display_name : "Default");

	// Re-open the menu.
	MiscChanger_OpenLastMenuFolding(client);

	// Don't delete the menu foldings.
	return false;
}

public void ApplyPin(int client, int new_value)
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