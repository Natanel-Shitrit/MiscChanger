#include <sourcemod>
#include <MiscChanger>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define CATEGORY_IDENTIFIER "music_kits"
#define CATEGORY_DISPLAY_NAME "Music-Kits"
#define CATEGORY_DESCRIPTION "Select your in-game music"

#define ITEM_TYPE "music_kit"
#define ITEM_DEF_INDEX_ATTRIBUTE "def_index"

int g_MusicIDOffset;
int g_ResetMusicKitFromInventoryOffset;

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
		if (!MiscChanger_RegisterCategory(CATEGORY_IDENTIFIER, CATEGORY_DISPLAY_NAME, CATEGORY_DESCRIPTION))
		{
			SetFailState("Failed to register module category. ("... CATEGORY_IDENTIFIER ...", "... CATEGORY_DISPLAY_NAME ...", "... CATEGORY_DESCRIPTION ...")");
		}

		MiscChanger_AddItemToCategory(CATEGORY_IDENTIFIER, MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER);

		if (eItems_AreItemsSynced())
		{
			eItems_OnItemsSynced();
		}
	}
}

public void eItems_OnItemsSynced()
{
	RegisterMusicKit("default_" ... ITEM_TYPE, 0, "Default");

	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	// VALVE Music-Kits
	for (int current_musickit = 1; current_musickit <= 2; current_musickit++)
	{
		Format(identifier, sizeof(identifier), ITEM_TYPE ... "%d", current_musickit);
		Format(display_name, sizeof(display_name), "VALVE Music-Kit %d", current_musickit);
		RegisterMusicKit(identifier, current_musickit, display_name);
	}
	
	// Community Music-Kits
	for (int current_musickit = 0; current_musickit < eItems_GetMusicKitsCount(); current_musickit++)
	{
		RegisterMusicKitFromMusicKitNum(current_musickit);
	}
}

void RegisterMusicKitFromMusicKitNum(int musickit_num)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), ITEM_TYPE ... "%d", musickit_num + 3);
	
	eItems_GetMusicKitDisplayNameByMusicKitNum(musickit_num, display_name, sizeof(display_name));

	RegisterMusicKit(identifier, eItems_GetMusicKitDefIndexByMusicKitNum(musickit_num), display_name);
}

void RegisterMusicKit(const char[] identifier, int value, const char[] display_name)
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
	// Check if it's a music kit
	char musickit_str[11];
	if (StrContains(item_identifier, ITEM_TYPE) == -1 ||
		!MiscChanger_GetItemAttribute(item_identifier, ITEM_DEF_INDEX_ATTRIBUTE, musickit_str, sizeof(musickit_str)))
	{
		return false;
	}

	int musickit = StringToInt(musickit_str);

	// Apply if it is.
	ApplyMusicKit(client, musickit);

	// Get display name.
	char display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	switch (musickit)
	{
		case 0:
		{
			strcopy(display_name, sizeof(display_name), "Default");
		}

		case 1, 2:
		{
			Format(display_name, sizeof(display_name), "VALVE Music-Kit %d", musickit);
		}

		default:
		{
			eItems_GetMusicKitDisplayNameByDefIndex(musickit, display_name, sizeof(display_name));
		}
	}

	// Show message.
	PrintToChat(client, "%s Changed to the \x02%s\x01 Music-Kit", MISC_CHANGER_PREFIX, display_name);

	// Re-open the menu.
	MiscChanger_OpenLastMenuFolding(client);

	// Don't delete the menu foldings.
	return false;
}

public void ApplyMusicKit(int client, int new_value)
{
	if (new_value)
	{
		SetEntData(client, g_MusicIDOffset, new_value, 4);
	}
	else // Default
	{
		SetEntData(client, g_ResetMusicKitFromInventoryOffset, 1, 1);
	}
}

// Don't let CS:GO load the default music-kit from the client inventory.
public void OnClientPutInServer(int client)
{
	/*
		if (!IsFakeClient(client))
		{
			SetEntData(client, g_ResetMusicKitFromInventoryOffset, 0, 1);
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
		
	g_MusicIDOffset = FindSendPropInfo("CCSPlayer", "m_unMusicID");
	
	g_ResetMusicKitFromInventoryOffset = g_MusicIDOffset + hGameData.GetOffset("ResetMusicKitFromInventory");
	
	delete hGameData;
}