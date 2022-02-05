#include <sourcemod>
#include <MiscChanger>

#pragma newdecls required
#pragma semicolon 1

#include "MiscChanger/global_variables.sp"
#include "MiscChanger/configuration.sp"
#include "MiscChanger/commands.sp"
#include "MiscChanger/menus.sp"
#include "MiscChanger/api.sp"

public Plugin myinfo = 
{
	name = "[Core] Misc-Changer", 
	author = "Natanel 'LuqS'", 
	description = "Allows players to change thier CS:GO miscellaneous items.", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin is for CSGO only.");
		return APLRes_Failure; 
	}

	InitializeAPI();

	RegPluginLibrary(MISC_CHANGER_LIB_NAME);

	return APLRes_Success;
}

public void OnPluginStart()
{
	InitializeGlobalVariables();

	LoadConfig();

	RegisterCommands();
}