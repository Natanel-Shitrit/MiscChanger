#include <sourcemod>
#include <MiscChanger>
#include <EconAPI>

#pragma newdecls required
#pragma semicolon 1

// Category
#define CATEGORY_IDENTIFIER "music_kits"
#define CATEGORY_DISPLAY_NAME "Music-Kits"
#define CATEGORY_DESCRIPTION "Select your in-game Music-Kit"

// Valve has a Music-Kit with no display name.
#define VALVE_MUSIC_KIT_NO_DISPLAY_NAME_DEF_INDEX 1

// Personal Music-Kit
#define PERSONAL_MUSIC_KIT_IDENTIFIER "personal_music_kit"
#define PERSONAL_MUSIC_KIT_ID 0

// Offsets
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
	LoadTranslations("csgo.phrases");
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
		LoadMusicKits();
	}
}

void LoadMusicKits()
{
	RegisterMusicKit(PERSONAL_MUSIC_KIT_IDENTIFIER, "Your personal Music-Kit");

	char name[64], display_name[64];
	
	CEconMusicDefinition music_def;
	for (int i; i < CEconMusicDefinition.Count(); i++)
	{
		music_def = CEconMusicDefinition.Get(i);
		
		if (music_def == CEconMusicDefinition_NULL)
		{
			continue;
		}
		
		music_def.GetName(name, sizeof(name));
		music_def.GetNameLocToken(display_name, sizeof(display_name));
		
		if (i == VALVE_MUSIC_KIT_NO_DISPLAY_NAME_DEF_INDEX)
		{
			strcopy(display_name, sizeof(display_name), "VALVE Music-Kit 2");
		}
		else if (TranslationPhraseExists(display_name[1]))
		{
			Format(display_name, sizeof(display_name), "%t", display_name[1]);
		}

		RegisterMusicKit(name, display_name);
	}
}

void RegisterMusicKit(const char[] identifier, const char[] display_name)
{
	if (!MiscChanger_RegisterItem(identifier, display_name))
	{
		ThrowError("Failed to register %s (%s)", display_name, identifier);
	}

	if (!MiscChanger_AddItemToCategory(identifier, CATEGORY_IDENTIFIER))
	{
		ThrowError("Failed to add item %s (%s) to module category.", display_name, identifier);
	}
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier, const char[] display_name)
{
	CEconMusicDefinition music_kit;
	// Check if it's a music kit
	if (StrContains(item_identifier, PERSONAL_MUSIC_KIT_IDENTIFIER) == -1 ||
		(music_kit = CEconMusicDefinition.FindByName(item_identifier)) == CEconMusicDefinition_NULL)
	{
		return false;
	}

	int musickit = (music_kit == CEconMusicDefinition_NULL) ? PERSONAL_MUSIC_KIT_ID : music_kit.ID;

	// Apply if it is.
	ApplyMusicKit(client, musickit);

	// Show message.
	PrintToChat(client, "%s Changed to the \x02%s\x01 Music-Kit", MISC_CHANGER_PREFIX, display_name);

	// Re-open the menu.
	MiscChanger_OpenLastMenuFolding(client);

	// Don't delete the menu foldings.
	return false;
}

public void ApplyMusicKit(int client, int new_value)
{
	if (new_value == PERSONAL_MUSIC_KIT_ID)
	{
		SetEntData(client, g_ResetMusicKitFromInventoryOffset, 1, 1);
	}
	else
	{
		SetEntData(client, g_MusicIDOffset, new_value, 4);
	}
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