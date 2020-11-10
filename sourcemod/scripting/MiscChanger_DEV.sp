#include <sdktools>
#include <eItems>
#include <MiscChanger>
#include <PTaH>
#include <MenuEx>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX " \x04"... PREFIX_NO_COLOR ..."\x01"
#define PREFIX_NO_COLOR "[MiscChanger]"

#define LOADOUT_POSITION_FLAIR0 55
#define SDK_COIN_POS 0

// Database
Database g_Database;

// API - Forwards
GlobalForward g_fOnItemChangedForward; 			// Blockable - Will block the change.
GlobalForward g_fOnItemChangedMessageForward;	// Blockable - Will block the chat message.

// SDK Handles
Handle g_hSetRank; // To set the coin / pin.

// KeyValues Config - Is preview enabled?
bool g_bShowEconPreview;

// Item enum struct - Pin / Coin.
enum struct Item
{
	// The plugin that registered the item.
	// Used by the API for several things.
	Handle item_plugin;
	
	// Index of the item in client items array-list.
	int index;
	
	// display name of the item (maybe this will be the translation phrase).
	char name[PIN_MAX_NAME_LEN];
	
	// if i'm going to abandon 'found_defaults' variable in pData struct.
	//bool found_client_default;
	
	// When in global array-list: The default value that will be for all client before getting his default value.
	// When in a client items array-list: The client specefic item default value, or the global value if not applied.
	// NOTE: 'any' type is not suitable for items that require more than 1 value.
	any value_default;
	any value;
	
	// if the item can be previewed.
	//bool previewable;
}
ArrayList g_Items;

enum struct pData
{
	// The client Account-ID, will be used if saving in a MySQL server.
	int account_id;
	
	// if all the client item defaults has been found.
	// NOTE: Maybe this is not such a good idea for all the items together, because the client can change the values before set to true and this will result wrong defaults.
	// NOTE: Making a variable for each item can fix this.	
	bool found_defaults;
	
	// This is where all the client items can be found.
	// NOTE: Search functions can be a good idea. (GetItemIndexBy...) 
	ArrayList items;
	
	/* TODO: Reset function
	void Reset()
	{
		// TODO: Complete
	}
	*/
	
	/* TODO: Change item value
	void ChangeItemValue(int item_index, int new_value, bool preview)
	{
		// TODO: Complete
	}
	*/
}
pData g_ClientData[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[DEV] MiscChanger", // DEV version of MisChanger
	author = "Natanel 'LuqS'", 
	description = "Allowing Players to change thier CS:GO miscellaneous items (Music-Kit / Coin / Pin / Stickers [SOON]).", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505 || https://github.com/Natanel-Shitrit"
}

// Called before OnPluginStart().
// API should be loaded here.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin is for CSGO only.");

		return APLRes_Failure; // will notify with a error message.
	}

	// Natives
	CreateNative("MiscChanger_GetClientItemValue", Native_GetClientItemValue);
	CreateNative("MiscChanger_SetClientItemValue", Native_SetClientItemValue);
	//CreateNative("MiscChanger_GetClientItemDefault", Native_GetClientItemDefault);
	
	// Forwards
	//g_fOnItemChangedPreForward = new GlobalForward("MiscChanger_OnItemChangedPre", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell);
	//g_fOnItemChangedPostForward = new GlobalForward("MiscChanger_OnItemChangedPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	RegPluginLibrary("MiscChanger");

	return APLRes_Success;
}

// When the plugin starts - not fired between map changes.
public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("%s This plugin is for CSGO only.", PREFIX_NO_COLOR);
	
	// Load needed Game-Data (Signatures).
	LoadGameData();
	
	// Create ArrayList for the data.
	CreateArrayLists();
	
	// Build Main-Menu.
	g_mMainMenu = BuildMainMenu();
	
	// Hook event when we get the player default items.
	// forward that will notify the plugins to try get the default values and use a native on success.
	HookEvent("player_team", OnPlayerTeamChange);
}

// When the plugin ends - not fired between map changes.
// NOTE: probably not fired when server is crashing - clients data to not be saved.
public void OnPluginEnd()
{
	// Early-Unload Support
	for (int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if(IsClientInGame(iCurrentClient))
			OnClientDisconnect(iCurrentClient);
}


// Load needed Game-Data (Signatures).
void LoadGameData()
{
	// Open the plugin game data file.
	GameData hGameData = new GameData("misc.game.csgo");
	
	if(!hGameData)
		SetFailState("'sourcemod/gamedata/misc.game.csgo.txt' is missing!");
	
	// https://github.com/perilouswithadollarsign/cstrike15_src/blob/29e4c1fda9698d5cebcdaf1a0de4b829fa149bf8/game/server/cstrike15/cs_player.cpp#L16369-L16372
	// Changes the the rank of the player ( this case use is the coin )
	// void CCSPlayer::SetRank( MedalCategory_t category, MedalRank_t rank )
	StartPrepSDKCall(SDKCall_Player);
	
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::SetRank"); // void
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalCategory_t category
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int MedalRank_t rank
	
	if (!(g_hSetRank = EndPrepSDKCall()))
		SetFailState("Failed to get CCSPlayer::SetRank signature");
	
	// not needed anymore.
	delete hGameData;
}