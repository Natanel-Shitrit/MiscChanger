#include <sourcemod>
#include <MiscChangerDev>

#pragma newdecls required
#pragma semicolon 1

#define MODULE_NAME "Logger"

public Plugin myinfo = 
{
	name = "[MiscChanger] "... MODULE_NAME ..." Module",
	author = "Natanel 'LuqS'",
	description = "A module for the MiscChager plugin that allows players to change thier in-game "... MODULE_NAME ..."!",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public void OnPluginStart()
{
	
}

public void MiscChanger_OnItemRegistered(int index, const char[] name, const char[] data_name)
{
	PrintToChatAll("[%s] Forward MiscChanger_OnItemRegistered(): index = %d, name: %s, data_name: %s", MODULE_NAME, index, name, data_name);
}

public void MiscChanger_OnItemRemoved(int index)
{
	PrintToChatAll("[%s] Forward MiscChanger_OnItemRemoved(): index = %d", MODULE_NAME, index);
}

public Action MiscChanger_OnItemValueChange(int client, int item_index, const char[] old_value, char[] new_value, bool first_load)
{
	PrintToChatAll("[%s] Forward MiscChanger_OnItemValueChange(): client = %d, index: %d, old_value: %s, new_value: %s, first_load: %d", MODULE_NAME, client, item_index, old_value, new_value, first_load);
}