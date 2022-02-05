#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <MiscChanger>
#include <Regex>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[Misc-Changer Module] Test Module", 
	author = "Natanel 'LuqS'", 
	description = "Tests the Misc-Changer API and warns about unexpected behavior.", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public void OnAllPluginsLoaded()
{
    TestCategoryRegistration();

    TestItemRegistration();

    TestItemLinking();

    OpenKVItems();
}

void TestCategoryRegistration()
{
    PrintToServer("[TestCategoryRegistration]");

    PrintToServer("[test_category, Test Category, This is a test category description]: %d (Should return 1)",
        MiscChanger_RegisterCategory("test_category", "Test Category", "This is a test category description")
    );

    PrintToServer("[another_test_category, Another Test Category, This is another test category description]: %d (Should return 1)",
        MiscChanger_RegisterCategory("another_test_category", "Another Test Category", "This is another test category description")
    );

    PrintToServer("[test_category, Test Category, This is a test category description]: %d (Should return 1)",
        MiscChanger_RegisterCategory("test_category", "Test Category", "This is a test category description", true)
    );

    PrintToServer("[test_category, Test Category, This is a test category description]: %d (Should return 0)",
        MiscChanger_RegisterCategory("test_category", "Test Category", "This is a test category description")
    );
}

void TestItemRegistration()
{
    PrintToServer("[TestItemRegistration]");

    PrintToServer("[test_item, Test Item]: %d (Should return 1)",
        MiscChanger_RegisterItem("test_item", "Test Item")
    );

    PrintToServer("[another_test_item, Another Test Item]: %d (Should return 1)",
        MiscChanger_RegisterItem("another_test_item", "Another Test Item")
    );

    PrintToServer("[test_item, Test Item]: %d (Should return 1)",
        MiscChanger_RegisterItem("test_item", "Test Item", true)
    );

    PrintToServer("[test_item, Test Item]: %d (Should return 0)",
        MiscChanger_RegisterItem("test_item", "Test Item")
    );

    PrintToServer("[test_global_item, Test Global Item]: %d (Should return 1)",
        MiscChanger_RegisterItem("test_global_item", "Test Global Item")
    );
}

void TestItemLinking()
{
    PrintToServer("[TestItemLinking]");

    MiscChanger_AddItemToCategory("test_category", MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER);
    MiscChanger_AddItemToCategory("test_item", "test_category");
    
    MiscChanger_AddItemToCategory("another_test_category", "test_category");
    MiscChanger_AddItemToCategory("another_test_item", "another_test_category");

    MiscChanger_AddItemToCategory("test_global_item", MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER);
}

public bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier)
{
    PrintToChat(client, "%s You selected the '%s' item", MISC_CHANGER_PREFIX, item_identifier);

    MiscChanger_OpenLastMenuFolding(client);

    return false;
}

void OpenKVItems()
{
    KeyValues items_game = new KeyValues("items_game");

    if (!items_game.ImportFromFile("scripts/items/items_game.txt"))
    {
        SetFailState("Couldn't open 'items_game.txt'");
    }

    if (!items_game.JumpToKey("music_definitions"))
    {
        SetFailState("'music_definitions' key couldn't be found.");
    }

    if (!items_game.GotoFirstSubKey())
    {
        SetFailState("'music_definitions' section is empty.");
    }

    char section_name[4],
         name[64],
         loc_name[64],
         loc_description[64],
         image_inventory[PLATFORM_MAX_PATH],
         pedestal_display_model[PLATFORM_MAX_PATH];
    do
    {
        items_game.GetSectionName(section_name, sizeof(section_name));
        //PrintToServer("section_name: %s", section_name);

        items_game.GetString("name", name, sizeof(name));
        //PrintToServer("name: %s", name);

        items_game.GetString("loc_name", loc_name, sizeof(loc_name));
        PrintToServer("loc_name: %s", loc_name);

        items_game.GetString("loc_description", loc_description, sizeof(loc_description));
        //PrintToServer("loc_description: %s", loc_description);

        items_game.GetString("image_inventory", image_inventory, sizeof(image_inventory));
        //PrintToServer("image_inventory: %s", image_inventory);

        items_game.GetString("pedestal_display_model", pedestal_display_model, sizeof(pedestal_display_model));
        //PrintToServer("pedestal_display_model: %s\n ", pedestal_display_model);

    }
    while (items_game.GotoNextKey());

    delete items_game;
}