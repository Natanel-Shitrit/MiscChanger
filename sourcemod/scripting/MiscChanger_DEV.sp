#include <sourcemod>
#include <MiscChangerDev>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX_NO_COLOR "[MiscChanger]"
#define PREFIX " \x04"... PREFIX_NO_COLOR ..."\x01"
#define CORE_CONFIG_PATH "configs/MiscChanger/misc_changer.cfg"


// Is Core Ready
bool g_IsReady;

// Main menu - where you can see all the registered items.
Menu g_MainMenu;

// Config
KeyValues g_Config;

// API	-------	Core
GlobalForward 	g_OnCoreReady, 
				g_OnCoreUnloaded, 
				
				// ItemDefinition
				//g_OnItemChangedForward,
				//g_OnItemChangedMessageForward,
				
				// pData
				g_OnClientItemValueChange;

enum struct Item
{
	// The name of the item.
	char name[MAX_ITEM_NAME_LENGTH];
	
	// ArrayList of category names.
	ArrayList categories;
	
	// ArrayList of items.
	ArrayList items;
	
	// ArrayList of the item commands.
	ArrayList commands;
	
	// Owner Plugin
	Handle owner;
	
	// function to use to apply the item
	Function apply_item;
	
	void ApplyItem(int client, const char[] new_value)
	{
		Call_StartFunction(this.owner, this.apply_item); // int client, char[] new_value
		Call_PushCell(client);
		Call_PushString(new_value);
		Call_Finish();
	}
	
	void GetItemDisplayName(int item_index, char[] buffer)
	{
		ItemData item_data;
		this.items.GetArray(item_index, item_data, sizeof(item_data));
		
		strcopy(buffer, MAX_ITEM_NAME_LENGTH, item_data.name);
	}
	
	void GetCategoryName(int index, char[] buffer)
	{
		this.categories.GetString(index, buffer, MAX_ITEM_NAME_LENGTH);
	}
}
ArrayList g_Items;

enum struct pData
{
	// The client Account-ID, will be used if saving in a MySQL server.
	int account_id[MAXPLAYERS + 1];
	
	// The item the client is currently choosing.
	int choosing_item[MAXPLAYERS + 1];
	
	// The category the player is in.
	int current_category[MAXPLAYERS + 1];
	
	// This is where all the client items can be found.
	// NOTE: Search functions can be a good idea. (GetItemIndexBy...) 
	ArrayList item_values[MAXPLAYERS + 1];
	
	void Init(int client)
	{
		this.Close(client);
		
		// Set client account id.
		this.account_id[client] = GetSteamAccountID(client);
		
		// Create items array-list
		this.item_values[client] = new ArrayList(MAX_ITEM_VALUE_LENGTH);
		
		// Add all items.
		for (int current_item_index = 0; current_item_index < g_Items.Length; current_item_index++)
		{
			this.item_values[client].PushString("");
		}
	}
	
	void Reset(int client)
	{
		this.account_id[client] = 0;
		this.choosing_item[client] = 0;
		this.current_category[client] = 0;
	}
	
	void Close(int client)
	{
		this.Reset(client);
		delete this.item_values[client];
	}
	
	void GetItemValue(int client, int item_index, char[] buffer)
	{
		this.item_values[client].GetString(item_index, buffer, MAX_ITEM_VALUE_LENGTH);
	}
	
	bool SetItemValue(int client, int item_index, char[] new_value, bool first_load = false)
	{
		Call_StartForward(g_OnClientItemValueChange);
			
		// int client
		Call_PushCell(client);
			
		// int item_index
		Call_PushCell(this.choosing_item[client]);
			
		// const char[] old_value
		char current_value[MAX_ITEM_VALUE_LENGTH];
		this.GetItemValue(client, this.choosing_item[client], current_value);
		Call_PushString(current_value);
			
		// char[] new_value
		Call_PushStringEx(new_value, MAX_ITEM_VALUE_LENGTH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			
		// bool first_load
		Call_PushCell(first_load);
			
		// Send Forward
		Action return_action;
			
		int error = Call_Finish(return_action);
		if (error != SP_ERROR_NONE)
		{
			ThrowNativeError(error, "Global Forward Failed - Error Code: %d", error);
			return false;
		}
			
		if (return_action >= Plugin_Handled)
		{
			return false;
		}
		
		// Save new value
		this.item_values[client].SetString(this.choosing_item[client], new_value);
		
		// Apply Item
		GetItemByIndex(this.choosing_item[client]).ApplyItem(client, new_value);
		
		return true;
	}
}
pData g_ClientData;

char g_SearchString[MAXPLAYERS][MAX_ITEM_NAME_LENGTH];

public Plugin myinfo = 
{
	name = "[DEV] MiscChanger",  // DEV version of MisChanger
	author = "Natanel 'LuqS'", 
	description = "Allowing Players to change thier CS:GO miscellaneous items (Music-Kit / Coin / Pin / Stickers [SOON]).", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505 || https://github.com/Natanel-Shitrit"
}

/*********************
		Events
**********************/
// Called before OnPluginStart().
// API is loading here.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin is for CSGO only.");
		
		return APLRes_Failure; // will notify with a error message.
	}
	
	//=================================[ NATIVES ]=================================//
	
	// [✓] TODO: [Core] Check if the core plugin is ready.
	CreateNative("MiscChanger_IsCoreReady", Native_IsCoreReady);
	
	// [✓] TODO: [ItemDefinition] Registering an item to the system.
	CreateNative("MiscChanger_RegisterItem", Native_RegisterItem);
	
	// [✗] TODO: [ItemDefinition] Removes an item from the system.
	CreateNative("MiscChanger_RemoveItem", Native_RemoveItem);
	
	// [X] TODO: [ItemDefinition] Sets the global item default value.
	//CreateNative("MiscChanger_SetItemDefaultValue", Native_GetClientItemDefault);
	
	// [✗] TODO: [pData Item] Gets a client item value.
	//CreateNative("MiscChanger_GetClientItemValue", Native_GetClientItemValue);
	
	// [✗] TODO: [pData Item] Sets a client item value.
	CreateNative("MiscChanger_SetClientItemValue", Native_SetClientItemValue);
	
	//=================================[ FORWARDS ]=================================//
	
	// [✓] TODO: [Core] When the core plugin is ready (only after this moment items should be added).
	g_OnCoreReady = new GlobalForward("MiscChanger_OnCoreReady", ET_Ignore);
	
	// [✓] TODO: [Core] When the core plugin is unloaded (when you can't use it anymore).
	g_OnCoreUnloaded = new GlobalForward("MiscChanger_OnCoreUnloaded", ET_Ignore);
	
	// [✗] TODO: [ItemDefinition] When a item is beening added.
	//g_OnItemAdd = new GlobalForward("MiscChanger_OnItemRegister", ET_Hook, Param_String);
	
	// [✗] TODO: [ItemDefinition] When a item is beening removed.
	//g_OnItemRemove = new GlobalForward("MiscChanger_OnItemRemove", ET_Hook, Param_Cell, Param_String);
	
	// [✗] TODO: [pData Item] When a item value has been changed.
	g_OnClientItemValueChange = new GlobalForward("MiscChanger_OnItemValueChange", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	
	RegPluginLibrary("MiscChanger");
	
	return APLRes_Success;
}

// When the plugin starts.
// NOTE: not fired between map changes.
public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("%s This plugin is for CSGO only.", PREFIX_NO_COLOR);
	}
	
	// Build Main-Menu.
	// NOTE: Items will be added to the menu dynamically, probably in the register item native.
	BuildMainMenu();
	
	// Load Config
	LoadConfig();
	
	// Create the items Array-List.
	g_Items = new ArrayList(sizeof(Item));
	
	// Core is ready and modules can be added now.
	g_IsReady = true;
	
	// Fire the forward - let all of the modules know that they can use the natives.
	if (g_OnCoreReady.FunctionCount)
	{
		Call_StartForward(g_OnCoreReady);
		Call_Finish();
	}
	
	// Late Load support
	for (int current_client = 1; current_client <= MaxClients; current_client++)
	{
		if (IsClientInGame(current_client) && !IsFakeClient(current_client) && IsClientAuthorized(current_client))
		{
			g_ClientData.Init(current_client);
		}
	}
}

// When the plugin ends - not fired between map changes.
// NOTE: probably not fired when server is crashing - clients data to not be saved.
public void OnPluginEnd()
{
	// Fire the forward - let all of the modules know that they can not longer use the natives.
	if (g_OnCoreUnloaded.FunctionCount)
	{
		Call_StartForward(g_OnCoreUnloaded);
		Call_Finish();
	}
	
	// Early-Unload Support
	for (int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
	{
		if (IsClientInGame(iCurrentClient))
		{
			OnClientDisconnect(iCurrentClient);
		}
	}
}

// The config is loaded each map change.
public void OnMapStart()
{
	LoadConfig();
	
	Item item;
	if (!RegItemCommands("MainMenu", Command_MainMenu, "Opens the Main-Menu", item))
	{
		SetFailState("%s Main-Menu Commands couldn't be found!", PREFIX_NO_COLOR);
	}
}

/***********************
		Commands
************************/
public Action Command_MainMenu(int client, int argc)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		g_MainMenu.Display(client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public Action Command_OpenItemMenu(int client, int argc)
{
	g_ClientData.Reset(client);
	
	char command[MAX_ITEM_COMMAND_LENGTH];
	GetCmdArg(0, command, MAX_ITEM_COMMAND_LENGTH);
	
	if ((g_ClientData.choosing_item[client] = FindItemOfCommand(command)) != -1)
	{
		GetCmdArgString(g_SearchString[client], sizeof(g_SearchString[]));
		if (g_SearchString[client][0])
		{
			ShowItemMenu(client);
		}
		else
		{
			ShowItemCategoriesMenu(client);
		}
	}
	
	return Plugin_Handled;
}

/********************
		Menus
*********************/
void BuildMainMenu()
{
	g_MainMenu = new Menu(MainMenuHandler, MenuAction_Select | MenuAction_DisplayItem);
	
	//g_MainMenu.SetTitle("%T", "Main Menu Title", LANG_SERVER);
	g_MainMenu.SetTitle("%s Choose an item:", PREFIX_NO_COLOR);
}

int MainMenuHandler(Menu menu, MenuAction action, int client, int item_index)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_ClientData.Reset(client);
			
			g_ClientData.choosing_item[client] = item_index;
			
			ShowItemCategoriesMenu(client);
		}
		
		case MenuAction_DisplayItem:
		{
			// Original Message
			char menu_item[MAX_ITEM_NAME_LENGTH];
			menu.GetItem(item_index, "", 0, _, menu_item, MAX_ITEM_NAME_LENGTH);
			
			// Get client current item value:
			char client_current_item_value[MAX_ITEM_VALUE_LENGTH];
			g_ClientData.GetItemValue(client, item_index, client_current_item_value);
			
			// Get client current item name with the value:
			char item_menu_with_client_value[MAX_ITEM_NAME_LENGTH * 2];
			Item item; g_Items.GetArray(item_index, item, sizeof(item));
			
			ItemData current_item_data;
			for (int current_item = 0; current_item < item.items.Length; current_item++)
			{
				item.items.GetArray(current_item, current_item_data, sizeof(current_item_data));
				if (StrEqual(client_current_item_value, current_item_data.value))
				{
					strcopy(item_menu_with_client_value, MAX_ITEM_NAME_LENGTH, current_item_data.name);
					break;
				}
			}
			
			// Format them together:
			Format(item_menu_with_client_value, sizeof(item_menu_with_client_value), "%s \n  > Current: %s", menu_item, item_menu_with_client_value);
			
			return RedrawMenuItem(item_menu_with_client_value);
		}
	}
	
	return 0;
}

void ShowItemCategoriesMenu(int client, int start_at = 0)
{
	// Validate item index - must be in this range:
	if (!(0 <= g_ClientData.choosing_item[client] < g_Items.Length))
	{
		return;
	}
	
	Item item; item = GetItemByIndex(g_ClientData.choosing_item[client]);
	
	if (!item.categories || item.categories.Length == 1)
	{
		ShowItemMenu(client);
	}
	else
	{
		Menu item_categories_menu = new Menu(ItemCategoriesMenuHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
		item_categories_menu.SetTitle("%s Choose A %s Category:", PREFIX_NO_COLOR, item.name); //g_MainMenu.SetTitle("%T", "Main Menu Title", LANG_SERVER);
	
		char current_category_name[MAX_ITEM_NAME_LENGTH];
		for (int current_category = 0; current_category < item.categories.Length; current_category++)
		{
			item.categories.GetString(current_category, current_category_name, MAX_ITEM_NAME_LENGTH);
			item_categories_menu.AddItem("", current_category_name);
		}
		
		item_categories_menu.DisplayAt(client, start_at, MENU_TIME_FOREVER);
	}
}

int ItemCategoriesMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int client = param1, category_num = param2;
			
			g_ClientData.current_category[client] = category_num;
			
			ShowItemMenu(client);
		}
		
		case MenuAction_Cancel:
		{
			int client = param1;
			g_MainMenu.Display(client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ShowItemMenu(int client, int start_at = 0)
{
	// Get Variables
	Item item; item = GetItemByIndex(g_ClientData.choosing_item[client]);
	
	char client_item_value[MAX_ITEM_VALUE_LENGTH];
	g_ClientData.GetItemValue(client, g_ClientData.choosing_item[client], client_item_value);
	
	// Create Menu
	Menu item_menu = new Menu(ItemMenuHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	if (g_ClientData.current_category[client])
	{
		char category_name[MAX_ITEM_NAME_LENGTH];
		item.GetCategoryName(g_ClientData.current_category[client], category_name);
		item_menu.SetTitle("%s Choose A %s From %s:", PREFIX_NO_COLOR, item.name, category_name); //g_MainMenu.SetTitle("%T", "Main Menu Title", LANG_SERVER);
	}
	else
	{
		item_menu.SetTitle("%s Choose A %s:", PREFIX_NO_COLOR, item.name);
	}
	
	ItemData current_item_data;
	for (int current_item = 0; current_item < item.items.Length; current_item++)
	{
		item.items.GetArray(current_item, current_item_data, sizeof(current_item_data));
		if (!current_item || ((!g_ClientData.current_category[client] || g_ClientData.current_category[client] == current_item_data.category_index) &&
							  (!g_SearchString[client][0] || StrContains(current_item_data.name, g_SearchString[client], false) != -1)))
		{
			item_menu.AddItem(current_item_data.value, current_item_data.name, StrEqual(client_item_value, current_item_data.value) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
	}
	
	switch (item_menu.ItemCount)
	{
		case 1:
		{
			PrintToChat(client, "%s \x02No %ss were found!\x01", PREFIX, item.name);
		}
		case 2:
		{
			ItemMenuHandler(item_menu, MenuAction_Select, client, 1);
			delete item_menu;
		}
		default:
		{
			item_menu.DisplayAt(client, start_at, MENU_TIME_FOREVER);
		}
	}
}

int ItemMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int client = param1, item_value_num = param2;
			
			// Get the new value
			char new_item_value[MAX_ITEM_VALUE_LENGTH], new_item_name[MAX_ITEM_NAME_LENGTH];
			menu.GetItem(item_value_num, new_item_value, MAX_ITEM_VALUE_LENGTH, _, new_item_name, MAX_ITEM_NAME_LENGTH);
			
			// Set the value of the client variable.
			if (g_ClientData.SetItemValue(client, g_ClientData.choosing_item[client], new_item_value, true))
			{
				PrintToChat(client, "%s \x06Successfully\x01 changed \x02%s\x01 to \x02%s\x01!", PREFIX, GetItemByIndex(g_ClientData.choosing_item[client]).name, new_item_name);
			}
			
			// Show Menu again.
			if (menu.ItemCount > 2)
			{
				ShowItemMenu(client, menu.Selection);
			}
		}
		
		case MenuAction_Cancel:
		{
			int client = param1;
			if (g_ClientData.current_category[client])
			{
				ShowItemCategoriesMenu(client, (g_ClientData.current_category[client] / 6) * 6);
			}
			else
			{
				g_MainMenu.Display(client, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

/****************************
		Client Events
*****************************/
public void OnClientAuthorized(int client, const char[] auth)
{
	if (auth[0] && !StrEqual(auth, "BOT"))
	{
		g_ClientData.Init(client);
	}
}

public void OnClientDisconnect(int client)
{
	g_ClientData.Close(client);
}

/**********************
		Natives
***********************/
int Native_IsCoreReady(Handle plugin, int numParams)
{
	return g_IsReady;
}

int Native_RegisterItem(Handle plugin, int numParams)
{
	// If core is not ready - throw an error.
	if (!g_IsReady)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Core is not ready!", PREFIX_NO_COLOR);
	}
	
	Item new_item;
	
	// Getting the item name:
	int name_length;
	if (GetNativeStringLength(REGISTER_PARAM_ITEM_NAME, name_length) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Failed to get the item name length!", PREFIX_NO_COLOR);
	}
	
	// ++ for EOS.
	if (!(0 < ++name_length <= MAX_ITEM_NAME_LENGTH))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Name is empty or too long! (MAX %d characters)", PREFIX_NO_COLOR, MAX_ITEM_NAME_LENGTH);
	}
	
	GetNativeString(REGISTER_PARAM_ITEM_NAME, new_item.name, MAX_ITEM_NAME_LENGTH);
	/*
	// Getting the item command:
	int command_length;
	if (GetNativeStringLength(REGISTER_PARAM_ITEM_COMMAND, command_length) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Failed to get the item command length!", PREFIX_NO_COLOR);
	}
	
	// ++ for EOS.
	if (!(0 < ++command_length <= MAX_ITEM_COMMAND_LENGTH))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Command is empty or too long! (MAX %d characters)", PREFIX_NO_COLOR, MAX_ITEM_COMMAND_LENGTH);
	}
	
	char command[MAX_ITEM_NAME_LENGTH];
	GetNativeString(REGISTER_PARAM_ITEM_COMMAND, command, MAX_ITEM_NAME_LENGTH);
	*/
	
	// Onwer plugin
	new_item.owner = plugin;
	
	// Get the item apply function:
	new_item.apply_item = GetNativeFunction(REGISTER_PARAM_APPLY_ITEM);
	
	// Get the item values:
	Handle categories = GetNativeCell(REGISTER_PARAM_ITEM_CATEGORIES);
	if (categories)
	{
		new_item.categories = view_as<ArrayList>(CloneHandle(categories));
		
		new_item.categories.ShiftUp(0);
		new_item.categories.SetString(0, "All Items");
	}
	
	// Get the item values:
	new_item.items = view_as<ArrayList>(CloneHandle(view_as<Handle>(GetNativeCell(REGISTER_PARAM_ITEM_VALUES))));
	
	// Free first position for the default item.
	new_item.items.ShiftUp(0);
	
	// Add 'Default Item'.
	ItemData default_item;
	Format(default_item.name, MAX_ITEM_NAME_LENGTH, "Default %s", new_item.name);
	new_item.items.SetArray(0, default_item, sizeof(default_item));
	
	// Add to Main-Menu.
	g_MainMenu.AddItem("", new_item.name);
	
	// TODO: 'MiscChanger_OnItemRegister' Forward.
	
	for (int current_client = 1; current_client <= MaxClients; current_client++)
	{
		if (g_ClientData.item_values[current_client])
		{
			g_ClientData.item_values[current_client].PushString("");
		}
	}
	
	char desc[32];
	Format(desc, sizeof(desc), "Opens the %s Menu.", new_item.name);
	
	new_item.commands = new ArrayList(ByteCountToCells(MAX_ITEM_COMMAND_LENGTH));
	RegItemCommands(new_item.name, Command_OpenItemMenu, desc, new_item);
	
	return g_Items.PushArray(new_item, sizeof(new_item));
}

int Native_RemoveItem(Handle plugin, int numParams)
{
	//g_MainMenu.RemoveItem()
	
	/* TODO: Complete */
}

int Native_SetClientItemValue(Handle plugin, int numParams)
{
	/* TODO: Complete */
}

/*
int Native_GetClientItemDefault(Handle plugin, int numParams)
{
	// TODO: Complete
}

int Native_GetClientItemValue(Handle plugin, int numParams)
{
	// TODO: Complete
}

int (Handle plugin, int numParams)
{
	
}
*/

/**********************
		Helpers
***********************/
void LoadConfig()
{
	// delete old config from previos map.
	delete g_Config;
	
	// Load KeyValues Config
	g_Config = new KeyValues("MiscChanger");
	
	// Find the Config
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), CORE_CONFIG_PATH);
	
	// Open file and go directly to the settings, if something doesn't work don't continue.
	if (!g_Config.ImportFromFile(sFilePath))
	{
		SetFailState("%s Couldn't load plugin config.", PREFIX_NO_COLOR);
	}
}

bool RegItemCommands(const char[] section, ConCmd command_func, const char[] desc, Item item)
{
	// Go back to the top.
	g_Config.Rewind();
	
	if (!g_Config.JumpToKey(section) || !g_Config.JumpToKey("Commands") || !g_Config.GotoFirstSubKey(false))
	{
		return false;
	}
	
	char command[64];
	
	do
	{
		g_Config.GetString(NULL_STRING, command, sizeof(command));
		
		if (command[0] && !CommandExists(command))
		{
			RegConsoleCmd(command, command_func, desc);
			
			if (item.commands)
			{
				item.commands.PushString(command);
			}
		}
		
	} while (g_Config.GotoNextKey(false));
	
	return true;
}

int FindItemOfCommand(const char[] command)
{
	Item current_item;
	for (int current_item_index = 0; current_item_index < g_Items.Length; current_item_index++)
	{
		current_item = GetItemByIndex(current_item_index);
		
		if (current_item.commands.FindString(command) != -1)
		{
			return current_item_index;
		}
	}
	
	return -1;
}

// Must check the index before calling this function because this can't really return invalid item or something similar.
any[] GetItemByIndex(int index)
{
	Item item;
	g_Items.GetArray(index, item, sizeof(item));
	
	return item;
} 