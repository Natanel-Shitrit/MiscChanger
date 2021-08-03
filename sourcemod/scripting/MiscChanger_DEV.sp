#include <sourcemod>
#include <MiscChangerDev>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX_NO_COLOR "[MiscChanger]"
#define PREFIX " \x04"... PREFIX_NO_COLOR ..."\x01"
#define CORE_CONFIG_PATH "configs/MiscChanger/misc_changer.cfg"

// Main menu - where you can see all the registered items.
Menu g_MainMenu;

// Config
KeyValues g_Config;

// API	-------	// Item
GlobalForward 	g_OnItemRegistered,
				g_OnItemRemoved,
				
				// pData
				g_OnClientItemValueChange;


ArrayList g_Items;

enum struct pData
{
	// The item the client is currently choosing.
	int choosing_item[MAXPLAYERS + 1];
	
	// The category the player is currently in.
	int choosing_category[MAXPLAYERS + 1];
	
	// This is where all the client items can be found.
	ArrayList item_values[MAXPLAYERS + 1];
	
	void Init(int client)
	{
		this.Close(client);
		
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
		this.choosing_item[client] = 0;
		this.choosing_category[client] = 0;
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
	
	bool SetItemValue(int client, int item_index, char[] new_value, bool apply_item = true, bool first_load = false)
	{
		Call_StartForward(g_OnClientItemValueChange);
			
		// int client
		Call_PushCell(client);
			
		// int item_index
		Call_PushCell(item_index);
			
		// const char[] old_value
		char current_value[MAX_ITEM_VALUE_LENGTH];
		this.GetItemValue(client, item_index, current_value);
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
		this.item_values[client].SetString(item_index, new_value);
		
		// Apply Item
		if (apply_item)
		{
			GetItemByIndex(item_index).ApplyItem(client, new_value);
		}
		
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
	
	// [✓] TODO: [Core] Sets a client item value.
	CreateNative("MiscChanger_GetItemsArrayList", Native_GetItemsArrayList);
	
	// [✓] TODO: [Item] Registering an item to the system.
	CreateNative("MiscChanger_RegisterItem", Native_RegisterItem);
	
	// [✓] TODO: [Item] Removes an item from the system.
	CreateNative("MiscChanger_RemoveItem", Native_RemoveItem);
	
	// [✓] TODO: [pData] Gets a client item value.
	CreateNative("MiscChanger_GetClientItemValue", Native_GetClientItemValue);
	
	// [✓] TODO: [pData] Sets a client item value.
	CreateNative("MiscChanger_SetClientItemValue", Native_SetClientItemValue);
	
	// [✓] TODO: [pData] Gets a client item value.
	CreateNative("MiscChanger_GetClientItemsValues", Native_GetClientItemsValues);
	
	//=================================[ FORWARDS ]=================================//
	
	// [✓] TODO: [Item] When a item is beening added.
	g_OnItemRegistered = new GlobalForward("MiscChanger_OnItemRegistered", ET_Ignore, Param_Cell, Param_String, Param_String);
	
	// [✓] TODO: [Item] When a item is beening removed.
	g_OnItemRemoved = new GlobalForward("MiscChanger_OnItemRemoved", ET_Hook, Param_Cell);
	
	// [✓] TODO: [pData] When a item value has been changed.
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
			
			ItemValue current_item_data;
			for (int current_item = 0; current_item < item.values.Length; current_item++)
			{
				item.values.GetArray(current_item, current_item_data, sizeof(current_item_data));
				if (StrEqual(client_current_item_value, current_item_data.value))
				{
					strcopy(item_menu_with_client_value, MAX_ITEM_NAME_LENGTH, current_item_data.display_name);
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
	
		char choosing_category_name[MAX_ITEM_NAME_LENGTH];
		for (int choosing_category = 0; choosing_category < item.categories.Length; choosing_category++)
		{
			item.categories.GetString(choosing_category, choosing_category_name, MAX_ITEM_NAME_LENGTH);
			item_categories_menu.AddItem("", choosing_category_name);
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
			
			g_ClientData.choosing_category[client] = category_num;
			
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
	if (g_ClientData.choosing_category[client])
	{
		char category_name[MAX_ITEM_NAME_LENGTH];
		item.GetCategoryName(g_ClientData.choosing_category[client], category_name);
		item_menu.SetTitle("%s Choose A %s From %s:", PREFIX_NO_COLOR, item.name, category_name); //g_MainMenu.SetTitle("%T", "Main Menu Title", LANG_SERVER);
	}
	else
	{
		item_menu.SetTitle("%s Choose A %s:", PREFIX_NO_COLOR, item.name);
	}
	
	ItemValue current_item_data;
	for (int current_item = 0; current_item < item.values.Length; current_item++)
	{
		item.values.GetArray(current_item, current_item_data, sizeof(current_item_data));
		if (!current_item || ((!g_ClientData.choosing_category[client] || g_ClientData.choosing_category[client] == current_item_data.category_index + 1) &&
							  (!g_SearchString[client][0] || StrContains(current_item_data.display_name, g_SearchString[client], false) != -1)))
		{
			item_menu.AddItem(current_item_data.value, current_item_data.display_name, StrEqual(client_item_value, current_item_data.value) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
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
			if (g_ClientData.SetItemValue(client, g_ClientData.choosing_item[client], new_item_value))
			{
				PrintToChat(client, "%s \x06Successfully\x01 changed \x02%s\x01 to \x02%s\x01!", PREFIX, GetItemByIndex(g_ClientData.choosing_item[client]).name, new_item_name);
			}
			
			// Reset all other item with the same data name.
			Item changed_item; changed_item = GetItemByIndex(g_ClientData.choosing_item[client]);
			for (int current_item_index = 0; current_item_index < g_Items.Length; current_item_index++)
			{
				if (g_ClientData.choosing_item[client] != current_item_index)
				{
					Item current_item; current_item = GetItemByIndex(current_item_index);
					
					if (StrEqual(changed_item.data_name, current_item.data_name))
					{
						g_ClientData.SetItemValue(client, current_item_index, "", false);
					}
				}
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
			if (g_ClientData.choosing_category[client])
			{
				ShowItemCategoriesMenu(client, (g_ClientData.choosing_category[client] / 6) * 6);
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

public void OnClientDisconnect_Post(int client)
{
	g_ClientData.Close(client);
}

/**********************
		Natives
***********************/
any Native_GetItemsArrayList(Handle plugin, int numParams)
{
	return CloneHandle(g_Items, plugin);
}

any Native_RegisterItem(Handle plugin, int numParams)
{
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
	
	// Onwer plugin
	new_item.owner = plugin;
	
	// Get the item apply function:
	new_item.apply_item = GetNativeFunction(REGISTER_PARAM_APPLY_ITEM);
	
	// Get the item values:
	Handle categories = GetNativeCell(REGISTER_PARAM_ITEM_CATEGORIES);
	if (categories)
	{
		new_item.categories = view_as<ArrayList>(CloneHandle(categories));
		
		delete categories;
		
		// Free first position for the 'All Items' item.
		new_item.categories.ShiftUp(0);
		
		// Add 'All Items' Option.
		new_item.categories.SetString(0, "All Items");
	}
	
	// Get the item values:
	Handle values = GetNativeCell(REGISTER_PARAM_ITEM_VALUES);
	if (values)
	{
		new_item.values = view_as<ArrayList>(CloneHandle(values));
		
		delete values;
		
		// Free first position for the 'Default Item' item.
		new_item.values.ShiftUp(0);
		
		// Add 'Default Item' Option.
		ItemValue default_item;
		Format(default_item.display_name, MAX_ITEM_NAME_LENGTH, "Default %s", new_item.name);
		new_item.values.SetArray(0, default_item, sizeof(default_item));
	}
	
	int data_name_length;
	if (GetNativeStringLength(REGISTER_PARAM_DATA_NAME, name_length) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Failed to get the item data name length!", PREFIX_NO_COLOR);
	}
	
	// ++ for EOS.
	if (!(++data_name_length <= MAX_ITEM_NAME_LENGTH))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Data Name is too long! (MAX %d characters)", PREFIX_NO_COLOR, MAX_ITEM_NAME_LENGTH);
	}
	
	GetNativeString(REGISTER_PARAM_DATA_NAME, new_item.data_name, MAX_ITEM_NAME_LENGTH);
	
	// Add to Main-Menu.
	g_MainMenu.AddItem("", new_item.name);
	
	// Add item buffer for each client.
	for (int current_client = 1; current_client <= MaxClients; current_client++)
	{
		if (g_ClientData.item_values[current_client])
		{
			g_ClientData.item_values[current_client].PushString("");
		}
	}
	
	// Load Commands.
	char desc[32];
	Format(desc, sizeof(desc), "Opens the %s Menu.", new_item.name);
	
	new_item.commands = new ArrayList(ByteCountToCells(MAX_ITEM_COMMAND_LENGTH));
	RegItemCommands(new_item.name, Command_OpenItemMenu, desc, new_item);
	
	// Push to global ArrayList.
	int new_item_index = g_Items.PushArray(new_item, sizeof(new_item));
	
	// Fire Forward.
	if (g_OnItemRegistered.FunctionCount)
	{
		Call_StartForward(g_OnItemRegistered); // int index, const char[] name
		Call_PushCell(new_item_index);
		Call_PushString(new_item.name);
		Call_PushString(new_item.data_name);
		Call_Finish();
	}
	
	// Return index in global ArrayList.
	return new_item_index;
}

any Native_RemoveItem(Handle plugin, int numParams)
{
	int item_index = GetNativeCell(REMOVE_ITEM_PARAM_INDEX);
	
	if (!(0 <= item_index < g_Items.Length))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Invalid item index. (Got: %d, Range: 0-%d)", item_index, g_Items.Length);
		return;
	}
	
	// Delete all ArrayList to not leak handles.
	Item item; item = GetItemByIndex(item_index);
	
	delete item.categories;
	delete item.values;
	delete item.commands;
	
	// Remove from global ArrayList.
	g_Items.Erase(item_index);
	
	// Remove from main menu.
	g_MainMenu.RemoveItem(item_index);
	
	if (g_OnItemRemoved.FunctionCount)
	{
		Call_StartForward(g_OnItemRemoved); // int index, const char[] name
		Call_PushCell(item_index);
		Call_Finish();
	}
}

any Native_GetClientItemValue(Handle plugin, int numParams)
{
	int client = GetNativeCell(GET_ITEM_PARAM_CLIENT);
	
	if (!(0 < client <= MaxClients))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Invalid client index.");
		return;
	}
	
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client not in-game.");
		return;
	}
	
	int item_index = GetNativeCell(GET_ITEM_PARAM_ITEM);
	
	if (!(0 < item_index < g_Items.Length))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Invalid item index.");
		return;
	}
	
	int buffer_length;
	if (GetNativeStringLength(GET_ITEM_PARAM_BUFFER, buffer_length) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to get buffer length.");
		return;
	}
	
	if (buffer_length != MAX_ITEM_VALUE_LENGTH)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Buffer length is not MAX_ITEM_VALUE_LENGTH.");
		return;
	}
	
	char client_item_value[MAX_ITEM_VALUE_LENGTH];
	g_ClientData.GetItemValue(client, item_index, client_item_value);
	
	int error;
	if ((error = SetNativeString(GET_ITEM_PARAM_BUFFER, client_item_value, MAX_ITEM_VALUE_LENGTH)) != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Error while saving value to buffer - Error: %d", error);
	}
}

any Native_SetClientItemValue(Handle plugin, int numParams)
{
	int client = GetNativeCell(GET_ITEM_PARAM_CLIENT);
	
	if (!(0 < client <= MaxClients))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index %d.", client);
	}
	
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d not in-game.", client);
	}
	
	int item_index = GetNativeCell(GET_ITEM_PARAM_ITEM);
	
	if (!(0 <= item_index < g_Items.Length))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid item index. (Sent: %d | Range: 0-%d)", item_index, g_Items.Length);
	}
	
	char client_item_value[MAX_ITEM_VALUE_LENGTH];
	int error;
	if ((error = GetNativeString(GET_ITEM_PARAM_BUFFER, client_item_value, MAX_ITEM_VALUE_LENGTH)) != SP_ERROR_NONE)
	{
		return ThrowNativeError(error, "Error while reading buffer - Error: %d", error);
	}
	
	g_ClientData.SetItemValue(client, item_index, client_item_value, GetNativeCell(GET_ITEM_PARAM_APPLY), GetNativeCell(GET_ITEM_PARAM_APPLY));
	
	return 0;
}

any Native_GetClientItemsValues(Handle plugin, int numParams)
{
	int client = GetNativeCell(GET_ITEM_PARAM_CLIENT);
	
	if (!(0 < client <= MaxClients))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Invalid client index.");
		return INVALID_HANDLE;
	}
	
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client not in-game.");
		return INVALID_HANDLE;
	}
	
	ArrayList client_items = new ArrayList(ByteCountToCells(MAX_ITEM_VALUE_LENGTH));
	
	for (int current_item = 0; current_item < g_ClientData.item_values[client].Length; current_item++)
	{
		char current_item_value[MAX_ITEM_VALUE_LENGTH];
		g_ClientData.GetItemValue(client, current_item, current_item_value);
		
		client_items.PushString(current_item_value);
	}
	
	// Clone a handle that's owned by the calling plugin.
	Handle cloned_client_items = CloneHandle(client_items, plugin);
	
	// Delete original ArrayList because we don't want memory leak.
	delete client_items;
	
	// Return the cloned ArrayList.
	return cloned_client_items;
}

/*
any (Handle plugin, int numParams)
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