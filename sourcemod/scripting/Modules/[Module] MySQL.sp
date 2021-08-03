#include <sourcemod>
#include <MiscChangerDev>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "MySQL"
#define DEBUG

Database g_Database;

ArrayList g_Items;

public Plugin myinfo = 
{
	name = "[MiscChanger] "...MODULE_NAME..." Module", 
	author = "Natanel 'LuqS'", 
	description = "A module for the MiscChager plugin that saves players item to a MySQL Database!", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_Items = new ArrayList(ByteCountToCells(MAX_ITEM_NAME_LENGTH));
}

public void OnAllPluginsLoaded()
{
	// Connect to the database
	Database.Connect(T_OnDBConnected, "MiscChanger");
}

public void MiscChanger_OnItemRegistered(int index, const char[] name, const char[] data_name)
{
	if (g_Database)
	{
		char item_name[MAX_ITEM_NAME_LENGTH];
		strcopy(item_name, MAX_ITEM_NAME_LENGTH, StrEqual(data_name, "") ? name : data_name);
		
		if (g_Items.FindString(item_name) == -1)
		{
			// Check if there is an existing column for the item.
			char check_column[512];
			Format(check_column, sizeof(check_column), "SHOW COLUMNS FROM `misc_changer` LIKE '%s'", item_name);
			
			DataPack dp_item_column = new DataPack();
			g_Database.Query(T_OnColumnCheckResult, check_column, dp_item_column);
			
			dp_item_column.WriteCell(index);
			dp_item_column.WriteString(item_name);
		}
		
		g_Items.PushString(item_name);
	}
}

/****************************
		Client Events
*****************************/

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		LoadPlayerItems(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	ArrayList client_items = MiscChanger_GetClientItemsValues(client);
	
	if (client_items != INVALID_HANDLE)
	{
		if (client_items.Length)
		{
			char query_names[255], query_values[255];
			
			for (int current_item = 0; current_item < client_items.Length; current_item++)
			{
				char current_item_name[MAX_ITEM_NAME_LENGTH];
				g_Items.GetString(current_item, current_item_name, MAX_ITEM_NAME_LENGTH);
				
				char current_item_value[MAX_ITEM_NAME_LENGTH];
				client_items.GetString(current_item, current_item_value, MAX_ITEM_VALUE_LENGTH);
				
				if (current_item > 0)
				{
					if (!StrEqual(current_item_value, "") && StrContains(query_names, current_item_name) == -1)
					{
						Format(query_names, sizeof(query_names), "%s, `%s`", query_names, current_item_name);
						Format(query_values, sizeof(query_values), "%s, '%s'", query_values, current_item_value);
					}
				}
				else
				{
					Format(query_names, sizeof(query_names), "`%s`", current_item_name);
					Format(query_values, sizeof(query_values), "'%s'", current_item_value);
				}
				
				#if defined DEBUG
				PrintToServer("[OnClientDisconnect] Item: [%d] Name: %s | Value: %s", current_item, current_item_name, current_item_value);
				#endif
			}
			
			char update_query[512];
			Format(update_query, sizeof(update_query), "REPLACE INTO `misc_changer` (account_id, %s) VALUES (%d, %s)", query_names, GetSteamAccountID(client), query_values);
			
			#if defined DEBUG
			PrintToServer("[OnClientDisconnect] Query: %s", update_query);
			#endif
			
			g_Database.Query(T_DoNothing, update_query);
		}
		
		delete client_items;
	}
}

/***********************
		Database
************************/

// Create the table if doesn't exist yet.
void T_OnDBConnected(Database db, const char[] error, any data)
{
	if (db == null) // Oops, something went wrong :S
	{
		SetFailState("Cannot Connect To MySQL Server! | Error: %s", error);
	}
	else
	{
		(g_Database = db).Query(T_OnDatabaseReady, "CREATE TABLE IF NOT EXISTS `misc_changer` (`account_id` INT NOT NULL DEFAULT '-1', UNIQUE (`account_id`))", _, DBPrio_High);
	}
}

// After this callback we have a connection to the database and we have a table ready to use.
void T_OnDatabaseReady(Database db, DBResultSet results, const char[] error, any data)
{
	if (!db || !results || error[0])
	{
		SetFailState("[T_OnDatabaseReady] Query Failed | Error: %s", error);
	}
	
	ArrayList g_ItemsFromCore = MiscChanger_GetItemsArrayList();
	
	Item current_item;
	for (int current_item_index = 0; current_item_index < g_ItemsFromCore.Length; current_item_index++)
	{
		g_ItemsFromCore.GetArray(current_item_index, current_item, sizeof(current_item));
		
		#if defined DEBUG
		PrintToServer("[T_OnDatabaseReady] Loading Item: [%d] %s", current_item_index, current_item.name);
		#endif
		
		MiscChanger_OnItemRegistered(current_item_index, current_item.name, current_item.data_name);
	}
	
	delete g_ItemsFromCore;
}

void T_OnColumnCheckResult(Database db, DBResultSet results, const char[] error, any data)
{
	if (!db || !results || error[0])
	{
		LogError("[T_OnColumnCheckResult] Query Failed | Error: %s", error);
		return;
	}
	
	// Store DataPack:
	DataPack dp_item_column = view_as<DataPack>(data); dp_item_column.Reset();
	
	// Read DataPack:
	int item_index = dp_item_column.ReadCell();
	
	char item_name[MAX_ITEM_NAME_LENGTH];
	dp_item_column.ReadString(item_name, MAX_ITEM_NAME_LENGTH);
	
	// Delete DataPack:
	delete dp_item_column;
	
	// Does column exist?
	if (results.FetchRow())
	{
		// YES - Load item for players that is already in the server.
		for (int current_client = 1; current_client <= MaxClients; current_client++)
		{
			if (IsClientInGame(current_client) && IsClientAuthorized(current_client))
			{
				LoadPlayerItem(current_client, item_name, item_index);
			}
		}
	}
	else
	{
		// NO - create new column.
		char add_column_query[512];
		g_Database.Format(add_column_query, sizeof(add_column_query), "ALTER TABLE `misc_changer` ADD `%s` varchar(%d) NOT NULL DEFAULT \"\"", item_name, MAX_ITEM_VALUE_LENGTH);
		g_Database.Query(T_DoNothing, add_column_query);
	}
	
}

// Load all items from the arraylist.
void LoadPlayerItems(int client)
{
	if (!g_Items.Length)
	{
		return;
	}
	
	char load_query[512], current_item_name[MAX_ITEM_NAME_LENGTH];
	
	for (int current_item = 0; current_item < g_Items.Length; current_item++)
	{
		g_Items.GetString(current_item, current_item_name, MAX_ITEM_NAME_LENGTH);
		
		if (current_item > 0)
		{
			Format(load_query, sizeof(load_query), "%s, `%s`", load_query, current_item_name);
		}
		else
		{
			Format(load_query, sizeof(load_query), "`%s`", current_item_name);
		}
	}
	
	g_Database.Format(load_query, sizeof(load_query), "SELECT %s FROM `misc_changer` WHERE `account_id` = %d", load_query, GetSteamAccountID(client));
	
	#if defined DEBUG
	PrintToServer("[LoadPlayerItems] Query: %s", load_query);
	#endif
	
	g_Database.Query(T_OnClientItemsRecived, load_query, GetClientUserId(client));
}

void T_OnClientItemsRecived(Database db, DBResultSet results, const char[] error, any data)
{
	if (!db || !results || error[0])
	{
		LogError("[T_OnClientDataRecived] Query Failed | Error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (!client)
	{
		LogError("[T_OnClientDataRecived] Client disconnected before fetching data, aborting.");
		return;
	}
	
	char current_item_value[MAX_ITEM_VALUE_LENGTH];
	bool row_fetched = results.FetchRow();
	
	for (int current_item = 0; current_item < g_Items.Length && current_item < results.FieldCount; current_item++)
	{
		if (row_fetched)
		{
			results.FetchString(current_item, current_item_value, MAX_ITEM_VALUE_LENGTH);
		}
		
		MiscChanger_SetClientItemValue(client, current_item, current_item_value, true);
	}
}

// Load 1 item.
void LoadPlayerItem(int client, const char[] item_column, int item_index)
{
	char load_query[512];
	Format(load_query, sizeof(load_query), "SELECT `%s` FROM `misc_changer` WHERE `account_id` = %d", item_column, GetSteamAccountID(client));
	
	#if defined DEBUG
	PrintToServer("[LoadPlayerItem] Query: %s", load_query);
	#endif
	
	DataPack load_data = new DataPack();
	g_Database.Query(T_OnClientItemRecived, load_query, load_data);
	
	load_data.WriteCell(GetClientUserId(client)); // Client UserID
	load_data.WriteCell(item_index); // Item index
}

void T_OnClientItemRecived(Database db, DBResultSet results, const char[] error, any data)
{
	DataPack load_data = view_as<DataPack>(data); load_data.Reset();
	
	if (!db || !results || error[0])
	{
		LogError("[T_OnClientItemRecived] Query Failed | Error: %s", error);
		delete load_data;
		return;
	}
	
	if (results.FetchRow())
	{
		int client = GetClientOfUserId(load_data.ReadCell());
		if (!client)
		{
			LogError("[T_OnClientItemRecived] Client disconnected before fetching data, aborting.");
			return;
		}
		
		int item_index = load_data.ReadCell();
		
		char current_item_value[MAX_ITEM_VALUE_LENGTH];
		results.FetchString(0, current_item_value, MAX_ITEM_VALUE_LENGTH);
		MiscChanger_SetClientItemValue(client, item_index, current_item_value, true);
	}
	
	delete load_data;
}

// Just check if the query was sent successfully, nothing else needed.
void T_DoNothing(Database db, DBResultSet results, const char[] error, any data)
{
	if (!db || !results || error[0])
	{
		LogError("[T_OnClientSavedDataResponse] Query Failed | Error: %s", error);
	}
} 