#include <sourcemod>
#include <MiscChanger>
#include <eItems>

#pragma newdecls required
#pragma semicolon 1

#define CATEGORY_IDENTIFIER "gloves"
#define CATEGORY_DISPLAY_NAME "Gloves"
#define CATEGORY_DESCRIPTION "Wearable Gloves"

#define ITEM_TYPE "gloves"
#define ITEM_DEF_INDEX_ATTRIBUTE "def_index"

public Plugin myinfo = 
{
	name = "[MiscChanger] "... CATEGORY_DISPLAY_NAME ..." Module",
	author = "Natanel 'LuqS'",
	description = "A module for the MiscChager plugin that allows players to change thier in-game "... CATEGORY_DISPLAY_NAME ..."!",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

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
	RegisterGlovesSkin("default" ... ITEM_TYPE, 0, -1, "Default");

	for (int current_gloves_type; current_gloves_type < eItems_GetGlovesCount(); current_gloves_type++)
	{
		RegisterGlovesType(current_gloves_type);
	}

	for (int current_skin; current_skin < eItems_GetPaintsCount(); current_skin++)
	{
		if (eItems_IsSkinNumGloveApplicable(current_skin))
		{
			RegisterGlovesSkinByNum(current_skin);
		}
	}
}

void RegisterGlovesType(int gloves_type_num)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), "glovestype%d", gloves_type_num);
	eItems_GetGlovesDisplayNameByGlovesNum(gloves_type_num, display_name, sizeof(display_name));

	MiscChanger_RegisterCategory(identifier, display_name, "Gloves Type");
	MiscChanger_AddItemToCategory(identifier, CATEGORY_IDENTIFIER);
}

void RegisterGlovesSkinByNum(int skin_num)
{
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Format(identifier, sizeof(identifier), ITEM_TYPE ... "%d", skin_num);
	eItems_GetSkinDisplayNameBySkinNum(skin_num, display_name, sizeof(display_name));

	RegisterGlovesSkin(identifier, eItems_GetSkinDefIndexBySkinNum(skin_num), eItems_GetGlovesNumBySkinNum(skin_num), display_name);
}

void RegisterGlovesSkin(const char[] identifier, int value, int glove_type, const char[] display_name)
{
	if (!MiscChanger_RegisterItem(identifier, display_name))
	{
		ThrowError("Failed to register %s (%s)", display_name, identifier);
	}

	char value_str[11];
	IntToString(value, value_str, sizeof(value_str));
	MiscChanger_SetItemAttribute(identifier, ITEM_DEF_INDEX_ATTRIBUTE, value_str);

	char glove_type_category[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	if (glove_type != -1)
	{
		Format(glove_type_category, sizeof(glove_type_category), "glovestype%d", glove_type);
	}

	if (!MiscChanger_AddItemToCategory(identifier, glove_type_category[0] ? glove_type_category : CATEGORY_IDENTIFIER))
	{
		ThrowError("Failed to add item %s (%s) to module category.", display_name, identifier);
	}
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier)
{
	// Check if it's gloves.
	char gloves_def_index_str[11];
	if (StrContains(item_identifier, ITEM_TYPE) == -1 ||
		!MiscChanger_GetItemAttribute(item_identifier, ITEM_DEF_INDEX_ATTRIBUTE, gloves_def_index_str, sizeof(gloves_def_index_str)))
	{
		return false;
	}

	Menu_DisplayGlovesMenu(client, StringToInt(gloves_def_index_str));

	// Re-open the menu.
	// MiscChanger_OpenLastMenuFolding(client);
	
	// Don't delete the menu foldings.
	return false;
}

void Menu_DisplayGlovesMenu(int client, int gloves_skin_def)
{
	int gloves_type_num = eItems_GetGlovesNumBySkinNum(eItems_GetSkinNumByDefIndex(gloves_skin_def));

	Menu gloves_menu = new Menu(Handler_GlovesMenu);

	char gloves_type_name[MISC_CHANGER_MAX_NAME_LENGTH], skin_name[MISC_CHANGER_MAX_NAME_LENGTH];
	eItems_GetGlovesDisplayNameByGlovesNum(gloves_type_num, gloves_type_name, sizeof(gloves_type_name));
	eItems_GetSkinDisplayNameByDefIndex(gloves_skin_def, skin_name, sizeof(skin_name));

	gloves_menu.SetTitle("%s\n%s %s:\n ", MISC_CHANGER_MENU_PREFIX, skin_name, gloves_type_name);

	gloves_menu.AddItem("", "Preview\n ");

	// TODO: Check if already equipped
	gloves_menu.AddItem("", "Equipe [T]");
	gloves_menu.AddItem("", "Equipe [CT]\n ");

	gloves_menu.AddItem("", "Change Wear\n ");

	gloves_menu.ExitBackButton = true;
	FixMenuGap(gloves_menu);
	
	gloves_menu.Display(client, MENU_TIME_FOREVER);
}

int Handler_GlovesMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int client = param1;
			MiscChanger_OpenLastMenuFolding(client);
		}
		
		case MenuAction_Cancel:
		{
			
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ApplyGloves(int client)
{
	return;	
}

// Fixs the menu gap created when Exit-Back button is used. (Thank you KoNLiG)
void FixMenuGap(Menu menu)
{
    int max_items = 6 - menu.ItemCount;
	
    for (int current_item = 0; current_item < max_items; current_item++) 
    {
        menu.AddItem("", "", ITEMDRAW_NOTEXT);
    }
}