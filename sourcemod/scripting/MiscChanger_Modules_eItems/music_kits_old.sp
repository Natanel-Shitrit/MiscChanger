#include <sourcemod>
#include <MiscChanger>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define CATEGORY_IDENTIFIER "music_kits"
#define CATEGORY_DISPLAY_NAME "Music-Kits"
#define CATEGORY_DESCRIPTION "Select your in-game music"

StringMap g_MusicKits;

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
	g_MusicKits = new StringMap();

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
	RegisterItem("default_music_kit", 0, "Default");

	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	// VALVE Music-Kits
	for (int current_musickit = 1; current_musickit <= 2; current_musickit++)
	{
		Format(identifier, sizeof(identifier), "valve%d", current_musickit);
		RegisterItem(identifier, current_musickit, "VALVE Music-Kit %d", current_musickit);
	}
	
	// Community Music-Kits
	for (int current_musickit = 0; current_musickit < eItems_GetMusicKitsCount(); current_musickit++)
	{
		Format(identifier, sizeof(identifier), "community%d", current_musickit);
		eItems_GetMusicKitDisplayNameByMusicKitNum(current_musickit, display_name, sizeof(display_name));
		
		RegisterItem(identifier, eItems_GetMusicKitDefIndexByMusicKitNum(current_musickit), display_name);
	}
}

void RegisterItem(const char[] identifier, int value, const char[] display_name, any ...)
{
	char formatted_name[MISC_CHANGER_MAX_NAME_LENGTH];
	VFormat(formatted_name, sizeof(formatted_name), display_name, 4);

	g_MusicKits.SetValue(identifier, value);

	if (!MiscChanger_RegisterItem(identifier, formatted_name))
	{
		ThrowError("Failed to register %s (%s)", formatted_name, identifier);
	}

	if (!MiscChanger_AddItemToCategory(identifier, CATEGORY_IDENTIFIER))
	{
		ThrowError("Failed to add item %s (%s) to module category.", formatted_name, identifier);
	}
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier)
{
	// Check if it's a music kit
	int musickit;
	if (!g_MusicKits.GetValue(item_identifier, musickit))
	{
		return false;
	}

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