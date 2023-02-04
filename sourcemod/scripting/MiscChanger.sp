#include <sdktools>
#include <eItems>
#include <MiscChanger>
#include <PTaH>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX " \x04"... PREFIX_NO_COLOR ..."\x01"
#define PREFIX_NO_COLOR "[MiscChanger]"

// Database
Database g_Database;

// Forwards
GlobalForward g_fOnItemChangedPreForward; 	// Blockable
GlobalForward g_fOnItemChangedPostForward;	// Not Blockable

// Offsets
int g_ResetMusicKitFromInventoryOffset;
int g_ResetCoinFromInventoryOffset;

// Medal Categories
// https://github.com/perilouswithadollarsign/cstrike15_src/blob/29e4c1fda9698d5cebcdaf1a0de4b829fa149bf8/game/shared/cstrike15/cs_player_rank_shared.h
enum MedalCategory_t
{
	MEDAL_CATEGORY_NONE = -1, 
	MEDAL_CATEGORY_START = 0, 
	MEDAL_CATEGORY_TEAM_AND_OBJECTIVE = MEDAL_CATEGORY_START, 
	MEDAL_CATEGORY_COMBAT, 
	MEDAL_CATEGORY_WEAPON, 
	MEDAL_CATEGORY_MAP, 
	MEDAL_CATEGORY_ARSENAL, 
	MEDAL_CATEGORY_ACHIEVEMENTS_END, 
	MEDAL_CATEGORY_SEASON_COIN = MEDAL_CATEGORY_ACHIEVEMENTS_END, 
	MEDAL_CATEGORY_COUNT, 
}
// ArrayLists
ArrayList g_alMusicKitsNames;
ArrayList g_alCoinsSetsNames;
ArrayList g_alCoins;
ArrayList g_alPins;

// Menus
Menu g_mMainMenu;
Menu g_mCoinsSetsMenu;

// Settings
bool g_bShowEconPreview;

enum struct Pin
{
	char DisplayName[PIN_MAX_NAME_LEN];
	int iDefIndex;
}

enum struct Coin
{
	char DisplayName[COIN_MAX_NAME_LEN];
	int iDefIndex;
}

enum struct PlayerInfo
{
	bool bFoundDefaults;
	
	int iMusicKitNum;
	int iPinOrCoinDefIndex;
	int iAccountID;
	
	void Reset()
	{
		this.bFoundDefaults = false;
		this.iMusicKitNum = 0;
		this.iPinOrCoinDefIndex = 0;
		this.iAccountID = 0;
	}
	
	bool SaveAndApplyItem(int client, MCItem item, int newvalue, bool isFirstLoad = false)
	{
		int oldvalue = (item == MCITEM_MUSICKIT) ? this.iMusicKitNum : this.iPinOrCoinDefIndex;
		
		if (g_fOnItemChangedPreForward.FunctionCount)
		{
			static Action retAction;
			
			Call_StartForward(g_fOnItemChangedPreForward);
			Call_PushCell(client);		// int client
			Call_PushCell(item);		// int item
			Call_PushCell(oldvalue);	// int oldvalue
			Call_PushCellRef(newvalue);	// int &newvalue
			Call_PushCell(isFirstLoad);	// bool isFirstLoad
			Call_Finish(retAction);
			
			if(retAction >= Plugin_Handled)
				return false;
		}
		
		if(!isFirstLoad || newvalue)
		{
			switch (item)
			{
				// Music-Kit
				case MCITEM_MUSICKIT:
				{
					// Change in-game | 0 = Player default item
					if (newvalue)
					{
						SetEntProp(client, Prop_Send, "m_unMusicID", newvalue, .size=2);
					}
					else
					{
						SetEntData(client, g_ResetMusicKitFromInventoryOffset, 1, 1);
					}
					
					// Change global variable
					this.iMusicKitNum = newvalue;
				}
				// Coin / Pin
				case MCITEM_PIN, MCITEM_COIN, MCITEM_COIN_OR_PIN:
				{
					// Change in-game | 0 = Player default item
					if (newvalue)
					{
						SetEntProp(client, Prop_Send, "m_rank", newvalue, .element=view_as<int>(MEDAL_CATEGORY_SEASON_COIN));
					}
					else
					{
						SetEntData(client, g_ResetCoinFromInventoryOffset, 1, 1);
					}
					
					
					// Change global variable
					this.iPinOrCoinDefIndex = newvalue;
					
					CEconItemDefinition newItemDef;
		
					if(!isFirstLoad && g_bShowEconPreview && newvalue && (newItemDef = PTaH_GetItemDefinitionByDefIndex(newvalue)))
						PrintHintItemEconImage(client, newItemDef);
				}
			}
		}
		
		if (g_fOnItemChangedPostForward.FunctionCount)
		{
			Call_StartForward(g_fOnItemChangedPostForward);
			Call_PushCell(client);		// int client
			Call_PushCell(item);		// int item
			Call_PushCell(oldvalue);	// int oldvalue
			Call_PushCell(newvalue);	// int newvalue
			Call_PushCell(isFirstLoad);	// bool isFirstLoad
			Call_Finish();
		}
		
		return true;
	}
}

PlayerInfo g_PlayerInfo[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "MiscChanger", 
	author = "Natanel 'LuqS'", 
	description = "Allowing Players to change thier CS:GO miscellaneous items (Music-Kit / Coin / Pin).", 
	version = "1.2.2", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505 || https://github.com/Natanel-Shitrit"
}

/*********************
		Events
**********************/

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("%s This plugin is for CSGO only.", PREFIX_NO_COLOR);
	
	// Load needed Game-Data (Signatures).
	CalculateOffsets();
	
	// Create ArrayList for the data.
	CreateArrayLists();
	
	// Build Main-Menu.
	g_mMainMenu = BuildMainMenu();
	
	// Late-Loading support.
	if (eItems_AreItemsSynced())
		eItems_OnItemsSynced();
	
	// Hook event when we get the player default items.
	HookEvent("player_team", OnPlayerTeamChange);
	
	// Connect to the database
	Database.Connect(T_OnDBConnected, "MiscChanger");
}

public void OnPluginEnd()
{
	// Early-Unload Support
	for (int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if(IsClientInGame(iCurrentClient))
			OnClientDisconnect(iCurrentClient);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin is for CSGO only.");

		return APLRes_SilentFailure;
	}

	// Natives
	CreateNative("MiscChanger_GetClientItem", Native_GetClientItem);
	CreateNative("MiscChanger_SetClientItem", Native_SetClientItem);
	
	// Forwards
	g_fOnItemChangedPreForward = new GlobalForward("MiscChanger_OnItemChangedPre", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell);
	g_fOnItemChangedPostForward = new GlobalForward("MiscChanger_OnItemChangedPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	RegPluginLibrary("MiscChanger");

	return APLRes_Success;
}

// eItems has been loaded AFTER our plugin.
public void eItems_OnItemsSynced()
{
	//==================================[ Music-Kits ]==================================//
	g_alMusicKitsNames.PushString("VALVE Music-Kit 1 (Game Default)");
	g_alMusicKitsNames.PushString("VALVE Music-Kit 2 (Pre-Panorama T Default)");
	// Community Music-Kits
	for (int iCurrentMusicKit = 0; iCurrentMusicKit < eItems_GetMusicKitsCount(); iCurrentMusicKit++)
	{
		char sCurrentMusicKitName[MUSIC_KIT_MAX_NAME_LEN];
		eItems_GetMusicKitDisplayNameByDefIndex(iCurrentMusicKit + 3, sCurrentMusicKitName, MUSIC_KIT_MAX_NAME_LEN);
		
		g_alMusicKitsNames.PushString(sCurrentMusicKitName);
	}
	
	//==================================[ Coin-Sets ]===================================//
	for (int iCurrentCoinSet = 0; iCurrentCoinSet < eItems_GetCoinsSetsCount(); iCurrentCoinSet++)
	{
		char sCurrentCoinSetName[COIN_SET_MAX_NAME_LEN];
		if (!eItems_GetCoinSetDisplayNameByCoinSetNum(iCurrentCoinSet, sCurrentCoinSetName, COIN_SET_MAX_NAME_LEN))
		{
			LogError("Failed to load Coin Set #%d Display Name, Skipping", iCurrentCoinSet);
			continue;
		}
		
		g_alCoinsSetsNames.PushString(sCurrentCoinSetName);
	}
	g_mCoinsSetsMenu = BuildCoinsSetsMenu();
	
	//====================================[ Coins ]=====================================//
	for (int iCurrentCoin = 0; iCurrentCoin < eItems_GetCoinsCount(); iCurrentCoin++)
	{
		Coin currentCoin;
		
		if (!eItems_GetCoinDisplayNameByCoinNum(iCurrentCoin, currentCoin.DisplayName, sizeof(currentCoin.DisplayName)))
		{
			LogError("Failed to load Coin #%d Display Name, Skipping", iCurrentCoin);
			continue;
		}
		
		currentCoin.iDefIndex = eItems_GetCoinDefIndexByCoinNum(iCurrentCoin);
		
		g_alCoins.PushArray(currentCoin, sizeof(currentCoin));
	}
	
	//====================================[ Pins ]======================================//
	for (int iCurrentPin = 0; iCurrentPin < eItems_GetPinsCount(); iCurrentPin++)
	{
		Pin currentPin;
		
		if (!eItems_GetPinDisplayNameByPinNum(iCurrentPin, currentPin.DisplayName, sizeof(currentPin.DisplayName)))
		{
			LogError("Failed to load Pin #%d Display Name, Skipping", iCurrentPin);
			continue;
		}
		
		currentPin.iDefIndex = eItems_GetPinDefIndexByPinNum(iCurrentPin);
		
		g_alPins.PushArray(currentPin, sizeof(currentPin));
	}
	
}

// Load Config
public void OnMapStart()
{
	// Load KeyValues Config
	KeyValues kv = CreateKeyValues("MiscChanger");
	
	// Find the Config
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/MiscChanger/misc_changer.cfg");
	
	// Open file and go directly to the settings, if something doesn't work don't continue.
	if (!kv.ImportFromFile(sFilePath))
		SetFailState("%s Couldn't load plugin config.", PREFIX_NO_COLOR);
	
	g_bShowEconPreview = view_as<bool>(kv.GetNum("ShowCoinOrPinPreview", 1));
	
	// Load Main-Menu Commands
	if (!LoadCommandsFromKV(kv, "MainMenu", Command_MainMenu, "Opens the main menu of MiscChanger plugin", true))
		LogError("[KV Config] Faild To Load Main Menu Commands");
	
	// Load Music-Kits Menu Commands
	if (!LoadCommandsFromKV(kv, "MusicKits", Command_MusicKits, "Opens the Music-Kits menu", true))
		LogError("[KV Config] Faild To Load Music Kits Menu Commands");
	
	// Load Pins Menu Commands
	if (!LoadCommandsFromKV(kv, "Pins", Command_Pins, "Opens the Pins menu", true))
		LogError("[KV Config] Faild To Load Pins Menu Commands");
	
	// Load Coins Menu Commands
	if (!LoadCommandsFromKV(kv, "Coins", Command_Coins, "Opens the Coins menu", true))
		LogError("[KV Config] Faild To Load Coins Menu Commands");
	
	// Don't leak handles.
	kv.Close();
}
void OnPlayerTeamChange(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")), team = event.GetInt("team");
	
	if(client && !IsFakeClient(client) && !g_PlayerInfo[client].bFoundDefaults && team > 1)
		ProcessPlayerData(client);
}

// Processing the player data is:
// 1. Getting the client default items. (And his Steam-Account ID)
// 2. Get the prefrences from the database.
void ProcessPlayerData(int client)
{
	// We found the default values.
	g_PlayerInfo[client].bFoundDefaults = true;
	
	// Get the player account id so we find his data in the database.
	g_PlayerInfo[client].iAccountID = GetSteamAccountID(client);
	
	// If the database is avilable, Ask for the data.
	if(g_Database)
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT `musickit_num`, `coin_or_pin_def_index` FROM `misc_changer` WHERE `account_id` = %d", g_PlayerInfo[client].iAccountID);
		g_Database.Query(T_OnClientDataRecived, sQuery, GetClientUserId(client));
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Database)
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `misc_changer` (`account_id`, `musickit_num`, `coin_or_pin_def_index`) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `musickit_num` = VALUES(`musickit_num`), `coin_or_pin_def_index` = VALUES(`coin_or_pin_def_index`)",
			g_PlayerInfo[client].iAccountID,
			g_PlayerInfo[client].iMusicKitNum,
			g_PlayerInfo[client].iPinOrCoinDefIndex
		);
		
		g_Database.Query(T_OnClientSavedDataResponse, sQuery);
	}
	
	g_PlayerInfo[client].Reset();
}

/***********************
		Database
************************/

void T_OnDBConnected(Database db, const char[] error, any data)
{
	if (db == null) // Oops, something went wrong :S
		SetFailState("%s Cannot Connect To MySQL Server! | Error: %s", PREFIX_NO_COLOR, error);
	else
	{
		(g_Database = db).Query(T_OnDatabaseReady, "CREATE TABLE IF NOT EXISTS `misc_changer` (`account_id` INT NOT NULL DEFAULT '-1', `musickit_num` INT NOT NULL DEFAULT '-1', `coin_or_pin_def_index` INT NOT NULL DEFAULT '-1', UNIQUE (`account_id`))", _, DBPrio_High);
	}
}

void T_OnDatabaseReady(Database db, DBResultSet results, const char[] error, any data)
{
	if(!db || !results || error[0])
	{
		SetFailState("[T_OnDatabaseReady] Query Failed | Error: %s", error);
	}
	
	// Late Load Support
	for (int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if(IsClientInGame(iCurrentClient))
			ProcessPlayerData(iCurrentClient);
}

void T_OnClientDataRecived(Database db, DBResultSet results, const char[] error, any data)
{
	if(!db || !results || error[0])
	{
		LogError("[T_OnClientDataRecived] Query Failed | Error: %s", error);
		return;
	}
	
	if(results.FetchRow())
	{
		int client = GetClientOfUserId(data);
		if(!(0 < client <= MaxClients) || !IsClientConnected(client))
		{
			LogError("[T_OnClientDataRecived] Client disconnected before fetching data, aborting.");
			return;
		}
		
		// 0 - 'musickit_num'
		// 1 - 'coin_or_pin_def_index'
		g_PlayerInfo[client].SaveAndApplyItem(client, MCITEM_MUSICKIT, results.FetchInt(0), true);
		g_PlayerInfo[client].SaveAndApplyItem(client, MCITEM_COIN_OR_PIN, results.FetchInt(1), true);
	}
}

void T_OnClientSavedDataResponse(Database db, DBResultSet results, const char[] error, any data)
{
	if(!db || !results || error[0])
	{
		LogError("[T_OnClientSavedDataResponse] Query Failed | Error: %s", error);
		return;
	}
}

/***********************
		Commands
************************/

// Main Menu - All menus will show up in a main menu.
public Action Command_MainMenu(int client, int argc)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
		g_mMainMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

// Music Kits Menu - Lets you choose your preferred music kit from all the Music Kits that avilable in the game (With the help of eItems).
public Action Command_MusicKits(int client, int argc)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		char sFindMusicKit[MUSIC_KIT_MAX_NAME_LEN];
		GetCmdArgString(sFindMusicKit, sizeof(sFindMusicKit));
		
		OpenMusicKitsMenu(client, 0, sFindMusicKit);
	}
	
	return Plugin_Handled;
}

// Pins Menu - Lets you choose your preferred pin that will show up in the scoreboard - from all the avilable pins in the game (With the help of eItems).
public Action Command_Pins(int client, int argc)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		char sFindPin[PIN_MAX_NAME_LEN];
		GetCmdArgString(sFindPin, sizeof(sFindPin));
		
		OpenPinsMenu(client, 0, sFindPin);
	}
	
	return Plugin_Handled;
}

// Coins Menu - Lets you choose your preferred coin that will show up in the scoreboard - from all the avilable pins in the game (With the help of eItems).
public Action Command_Coins(int client, int argc)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		char sFindCoin[PIN_MAX_NAME_LEN];
		GetCmdArgString(sFindCoin, sizeof(sFindCoin));
			
		OpenCoinsMenu(client, 0, sFindCoin);
	}
	
	return Plugin_Handled;
}

/********************
		Menus
*********************/
/* Main-Menu */
Menu BuildMainMenu()
{
	Menu mMainMenu = new Menu(MainMenuHandler);
	mMainMenu.SetTitle("%s Browse Change-Able 'Miscellaneous' items:", PREFIX_NO_COLOR);
	
	mMainMenu.AddItem("", "• Change Your Music-Kit");
	mMainMenu.AddItem("", "• Change Your Coin");
	mMainMenu.AddItem("", "• Change Your Pin");
	
	return mMainMenu;
}

int MainMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				OpenMusicKitsMenu(client);
			}
			case 1:
			{
				OpenCoinsMenu(client);
			}
			case 2:
			{
				OpenPinsMenu(client);
			}
		}
	}
}

/* Music Kits */
Menu BuildMusicKitsMenu(const char[] sFindMusicKit = "", int client)
{
	Menu mMusicKitsMenu = new Menu(MusicKitsMenuHandler);
	mMusicKitsMenu.SetTitle("%s Choose Your Music-Kit:", PREFIX_NO_COLOR);
	
	// Reset Music-Kit
	mMusicKitsMenu.AddItem(sFindMusicKit, "Your Default Music-Kit", !g_PlayerInfo[client].iMusicKitNum ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	// Music-Kits Options
	for (int iCurrentMusicKit = 0; iCurrentMusicKit < g_alMusicKitsNames.Length; iCurrentMusicKit++) // + 2 Because we added 2 kits from VALVE
	{
		char sMusicKitName[MUSIC_KIT_MAX_NAME_LEN];
		g_alMusicKitsNames.GetString(iCurrentMusicKit, sMusicKitName, sizeof(sMusicKitName));
		
		char sMusicKitNum[4];
		IntToString(iCurrentMusicKit + 1, sMusicKitNum, sizeof(sMusicKitNum));
		
		if (!sFindMusicKit[0] || StrContains(sMusicKitName, sFindMusicKit, false) != -1)
			mMusicKitsMenu.AddItem(sMusicKitNum, sMusicKitName, g_PlayerInfo[client].iMusicKitNum == iCurrentMusicKit + 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	return mMusicKitsMenu;
}

void OpenMusicKitsMenu(int client, int startItem = 0, const char[] sFindMusicKit = "")
{
	// Display the menu from the given item
	if (eItems_AreItemsSynced())
	{
		Menu mMenuToDisplay = BuildMusicKitsMenu(sFindMusicKit, client);
		
		switch (mMenuToDisplay.ItemCount)
		{
			case 1:
			{
				PrintToChat(client, "%s No Music-Kits were found!", PREFIX);
			}
			case 2:
			{
				MusicKitsMenuHandler(mMenuToDisplay, MenuAction_Select, client, 1);
				delete mMenuToDisplay;
			}
			default:
			{
				mMenuToDisplay.DisplayAt(client, startItem, MENU_TIME_FOREVER);
			}
		}
	}
	else
		PrintToChat(client, "%s \x0EMusic-Kits\x01 Menu is \x02Currently Unavailable\x01!", PREFIX);
}

int MusicKitsMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sMusicKitNum[4], sMusicKitDisplayName[MUSIC_KIT_MAX_NAME_LEN];
			menu.GetItem(param2, sMusicKitNum, sizeof(sMusicKitNum), _, sMusicKitDisplayName, MUSIC_KIT_MAX_NAME_LEN);
			
			int iMusicKitNum = StringToInt(sMusicKitNum);
			// Change Client Music-Kit in the scoreboard and save his prefrence.
			if(g_PlayerInfo[client].SaveAndApplyItem(client, MCITEM_MUSICKIT, iMusicKitNum))
			{
				if(g_PlayerInfo[client].iMusicKitNum != iMusicKitNum)
					eItems_GetMusicKitDisplayNameByMusicKitNum(g_PlayerInfo[client].iMusicKitNum, sMusicKitDisplayName, MUSIC_KIT_MAX_NAME_LEN);
				
				// Alert him that the Music-Kit has been changed.
				PrintToChat(client, "%s \x04Successfully\x01 changed your Music-Kit to \x02%s\x01!", PREFIX, sMusicKitDisplayName); 
			}
			
			// Reopen the menu where it was.
			char sFindMusicKit[64];
			menu.GetItem(0, sFindMusicKit, sizeof(sFindMusicKit));
			OpenMusicKitsMenu(client, menu.Selection, sFindMusicKit);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

/* Coins */

Menu BuildCoinsSetsMenu()
{
	Menu mCoinsSetsMenu = new Menu(CoinsSetsMenuHandler, MenuAction_DrawItem);
	mCoinsSetsMenu.SetTitle("%s Choose Your Coin:", PREFIX_NO_COLOR);
	
	// Reset Coin
	mCoinsSetsMenu.AddItem("", "Your Default Coin");
	
	// Coin Options
	for (int iCurrentCoinSet = 0; iCurrentCoinSet < g_alCoinsSetsNames.Length; iCurrentCoinSet++)
	{
		char sCoinSetName[COIN_SET_MAX_NAME_LEN];
		g_alCoinsSetsNames.GetString(iCurrentCoinSet, sCoinSetName, sizeof(sCoinSetName));
		
		mCoinsSetsMenu.AddItem("", sCoinSetName);
	}
	
	return mCoinsSetsMenu;
}

Menu BuildCoinsMenu(int client, const char[] sFindCoin = "", int iCoinSet = -1, int iSelection = -1)
{
	Menu mCoinsMenu = new Menu(CoinsMenuHandler);
	mCoinsMenu.SetTitle("%s Choose Your Coin:", PREFIX_NO_COLOR);
	
	// Saving the first item in menu page to know where to return to.
	char sCoinSet[4];
	IntToString(iCoinSet, sCoinSet, sizeof(sCoinSet));
	
	char sSelection[4];
	IntToString(iSelection, sSelection, sizeof(sSelection));
	mCoinsMenu.AddItem(sCoinSet, iCoinSet == -1 ? sFindCoin : sSelection, ITEMDRAW_IGNORE);
	
	mCoinsMenu.AddItem("", "Your Default Coin", !g_PlayerInfo[client].iPinOrCoinDefIndex ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	// Coin Options
	for (int iCurrentCoin = 0; iCurrentCoin < g_alCoins.Length; iCurrentCoin++)
	{
		// "because SourcePawn" ~ asherkin 2020
		// https://discordapp.com/channels/335290997317697536/335290997317697536/759064525244072006
		Coin cCurrentCoin; cCurrentCoin = GetCoinByIndex(iCurrentCoin);
		
		char sDefIndex[16];
		IntToString(cCurrentCoin.iDefIndex, sDefIndex, sizeof(sDefIndex));
		
		if ((iCoinSet == -1 || eItems_IsCoinInSet(iCurrentCoin, eItems_GetCoinSetIdByCoinSetNum(iCoinSet))) && (!sFindCoin[0] || StrContains(cCurrentCoin.DisplayName, sFindCoin, false) != -1))
			mCoinsMenu.AddItem(sDefIndex, cCurrentCoin.DisplayName, g_PlayerInfo[client].iPinOrCoinDefIndex == cCurrentCoin.iDefIndex ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	return mCoinsMenu;
}

void OpenCoinsMenu(int client, int startItem = 0, const char[] sFindCoin = "")
{
	// Display the menu from the given item
	if (eItems_AreItemsSynced())
	{
		Menu mMenuToDisplay = sFindCoin[0] ? BuildCoinsMenu(client, sFindCoin) : BuildCoinsSetsMenu();
		
		switch (mMenuToDisplay.ItemCount)
		{
			// Only the 'Reset' Button, no coins were found.
			case 1:
			{
				PrintToChat(client, "%s No Coins were found!", PREFIX);
			}
			// Only 1 coin were found, don't bother opening the menu and automaticlly set it to the client coin.
			case 2:
			{
				CoinsMenuHandler(mMenuToDisplay, MenuAction_Select, client, 1);
				delete mMenuToDisplay;
			}
			// if there is more then 1 coin, open the menu and let the player select.
			default:
			{
				mMenuToDisplay.DisplayAt(client, startItem, MENU_TIME_FOREVER);
			}
		}
	}
	else
		PrintToChat(client, "%s \x0ECoins\x01 Menu is \x02Currently Unavailable\x01!", PREFIX);
}

int CoinsSetsMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// If the client clicked on a coins set.
			if(param2)
				BuildCoinsMenu(client, "", param2 - 1, menu.Selection).Display(client, MENU_TIME_FOREVER);
			// If the client clicked on the 'reset' button.
			else
				CoinsMenuHandler(menu, MenuAction_Select, client, 0);
		}
		case MenuAction_DrawItem:
		{
			return (!param2 && !g_PlayerInfo[client].iPinOrCoinDefIndex) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
		}
	}
	
	return 0;
}

int CoinsMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	char sCoinSet[4], sSelectionOrStringSearch[64];
	menu.GetItem(0, sCoinSet, sizeof(sCoinSet), _, sSelectionOrStringSearch, sizeof(sSelectionOrStringSearch));
	int iCoinSet = StringToInt(sCoinSet);
	
	switch (action)
	{
		case MenuAction_Select:
		{
			char sCoinDefIndex[16], sCoinDisplayName[PIN_MAX_NAME_LEN];
			menu.GetItem(param2, sCoinDefIndex, sizeof(sCoinDefIndex), _, sCoinDisplayName, PIN_MAX_NAME_LEN);
			
			int iCoinDefIndex = StringToInt(sCoinDefIndex);
			// Change Client Coin in the scoreboard and save his prefrence.
			if(g_PlayerInfo[client].SaveAndApplyItem(client, MCITEM_COIN, iCoinDefIndex))
			{
				if (g_PlayerInfo[client].iPinOrCoinDefIndex != iCoinDefIndex)
					eItems_GetCoinDisplayNameByDefIndex(g_PlayerInfo[client].iPinOrCoinDefIndex, sCoinDisplayName, PIN_MAX_NAME_LEN);
				
				// Alert him that the coin has been changed.
				PrintToChat(client, "%s \x04Successfully\x01 changed your Coin to \x02%s\x01!", PREFIX, sCoinDisplayName); 
			}
				
			BuildCoinsMenu(client, iCoinSet == -1 ? sSelectionOrStringSearch : "", iCoinSet, iCoinSet == -1 ? -1 : StringToInt(sSelectionOrStringSearch)).DisplayAt(client, menu.Selection, MENU_TIME_FOREVER);
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(iCoinSet != -1)
				g_mCoinsSetsMenu.DisplayAt(client, StringToInt(sSelectionOrStringSearch), MENU_TIME_FOREVER);
		}
	}
}

/* Pins */
Menu BuildPinsMenu(const char[] sFindPin = "", int client)
{
	Menu mPinsMenu = new Menu(PinsMenuHandler);
	mPinsMenu.SetTitle("%s Choose Your Pin:", PREFIX_NO_COLOR);
	
	// Reset Pin
	mPinsMenu.AddItem(sFindPin, "Your Default Pin", !g_PlayerInfo[client].iPinOrCoinDefIndex ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	// Pin Options
	for (int iCurrentPin = 0; iCurrentPin < g_alPins.Length; iCurrentPin++)
	{
		// "because SourcePawn" ~ asherkin 2020
		// https://discordapp.com/channels/335290997317697536/335290997317697536/759064525244072006
		Pin pCurrentPin; pCurrentPin = GetPinByIndex(iCurrentPin);
		
		char sDefIndex[16];
		IntToString(pCurrentPin.iDefIndex, sDefIndex, sizeof(sDefIndex));
		
		if (!sFindPin[0] || StrContains(pCurrentPin.DisplayName, sFindPin, false) != -1)
			mPinsMenu.AddItem(sDefIndex, pCurrentPin.DisplayName, g_PlayerInfo[client].iPinOrCoinDefIndex == pCurrentPin.iDefIndex ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	return mPinsMenu;
}

void OpenPinsMenu(int client, int startItem = 0, const char[] sFindPin = "")
{
	// Display the menu from the given item
	if (eItems_AreItemsSynced())
	{
		Menu mMenuToDisplay = BuildPinsMenu(sFindPin, client);
		
		switch (mMenuToDisplay.ItemCount)
		{
			case 1:
			{
				PrintToChat(client, "%s No Pins were found!", PREFIX);
			}
			case 2:
			{
				PinsMenuHandler(mMenuToDisplay, MenuAction_Select, client, 1);
				delete mMenuToDisplay;
			}
			default:
			{
				mMenuToDisplay.DisplayAt(client, startItem, MENU_TIME_FOREVER);
			}
		}
	}
	else
		PrintToChat(client, "%s \x0EPins\x01 Menu is \x02Currently Unavailable\x01!", PREFIX);
}

int PinsMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sPinDefIndex[16], sPinDisplayName[PIN_MAX_NAME_LEN];
			menu.GetItem(param2, sPinDefIndex, sizeof(sPinDefIndex), _, sPinDisplayName, PIN_MAX_NAME_LEN);
			
			int iPinDefIndex = StringToInt(sPinDefIndex);
			// Change Client Pin in the scoreboard and save his prefrence.
			if(g_PlayerInfo[client].SaveAndApplyItem(client, MCITEM_PIN, iPinDefIndex))
			{
				if(g_PlayerInfo[client].iPinOrCoinDefIndex != iPinDefIndex)
					eItems_GetPinDisplayNameByDefIndex(g_PlayerInfo[client].iPinOrCoinDefIndex, sPinDisplayName, PIN_MAX_NAME_LEN);
				
				PrintToChat(client, "%s \x04Successfully\x01 changed your Pin to \x02%s\x01!", PREFIX, sPinDisplayName); // Alert him that the Pin has been changed.
			}
				
			char sFindPin[64];
			menu.GetItem(0, sFindPin, sizeof(sFindPin));
			OpenPinsMenu(client, menu.Selection, sFindPin);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

/**********************
		Natives
***********************/

int Native_GetClientItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1); 
	
	if(!(0 < client <= MaxClients) || !IsClientInGame(client))
		ThrowNativeError(0, "Invalid client.");
	
	MCItem item = GetNativeCell(2);
	
	if(!(MCITEM_START < item < MCITEM_END))
		ThrowNativeError(1, "Invalid Item.");
	
	return item == MCITEM_MUSICKIT ? g_PlayerInfo[client].iMusicKitNum : g_PlayerInfo[client].iPinOrCoinDefIndex;
}

int Native_SetClientItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1); 
	
	if(!(0 < client <= MaxClients) || !IsClientInGame(client))
		ThrowNativeError(0, "Invalid client.");
	
	MCItem item = GetNativeCell(2);
	
	if(!(MCITEM_START < item < MCITEM_END))
		ThrowNativeError(1, "Invalid Item.");
	
	int value = GetNativeCell(3);
	g_PlayerInfo[client].SaveAndApplyItem(client, item, value);
}

/**********************
		Helpers
***********************/

void CalculateOffsets()
{
	g_ResetMusicKitFromInventoryOffset = FindSendPropInfo("CCSPlayer", "m_unMusicID") + 2; // 'm_unMusicID' is 'un' (unsigned number), size is 2.
	g_ResetCoinFromInventoryOffset = FindSendPropInfo("CCSPlayer", "m_rank") + 24; // 'm_rank' is array of 6 numbers, size is 24.
}

// Create ArrayList for the data.
void CreateArrayLists()
{
	g_alMusicKitsNames = new ArrayList(ByteCountToCells(MUSIC_KIT_MAX_NAME_LEN));
	g_alCoinsSetsNames = new ArrayList(ByteCountToCells(COIN_SET_MAX_NAME_LEN));
	g_alCoins = new ArrayList(sizeof(Coin));
	g_alPins = new ArrayList(sizeof(Pin));
}

bool LoadCommandsFromKV(KeyValues kv, const char[] sSectionName, ConCmd fCommandToRegTo, const char[] sCommandDescription, bool bDontRegIfCommandAlreadyExists = false)
{
	if (!kv.JumpToKey(sSectionName))
	{
		LogError("[KV Config] %s Section couldn't be found!", sSectionName);
		return false;
	}
	
	if (kv.JumpToKey("Commands"))
	{
		char sCommand[128];
		
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				kv.GetString(NULL_STRING, sCommand, sizeof(sCommand));
				
				if (!StrEqual(sCommand, "") && (!bDontRegIfCommandAlreadyExists || !CommandExists(sCommand)))
					RegConsoleCmd(sCommand, fCommandToRegTo, sCommandDescription);
				
			} while (kv.GotoNextKey(false));
			
			// Exit from all the commands.
			kv.GoBack();
		}
		
		// Exit from the Commands Section.
		kv.GoBack();
	}
	else
	{
		LogError("[KV Config] %s Commands Section couldn't be found!", sSectionName);
		return false;
	}
	
	// Exit from the current section.
	kv.GoBack();
	
	return true;
}

any[] GetPinByIndex(int index)
{
	Pin pin;
	g_alPins.GetArray(index, pin, sizeof(pin));
	
	return pin;
}

any[] GetCoinByIndex(int index)
{
	Coin coin;
	g_alCoins.GetArray(index, coin, sizeof(coin));
	
	return coin;
}

void PrintHintItemEconImage(int client, CEconItemDefinition itemDef, bool isFirstRun = true)
{
	static char sMessage[PLATFORM_MAX_PATH];

	if(!itemDef)
		return;
	
	Protobuf hMessage = view_as<Protobuf>(StartMessageOne("TextMsg", client));
	
	itemDef.GetEconImage(sMessage, sizeof(sMessage));
	Format(sMessage, sizeof(sMessage), "</font><img src='file://{images_econ}/%s.png'/><script>", sMessage);
	
	hMessage.SetInt("msg_dst", 4);
	hMessage.AddString("params", "#SFUI_ContractKillStart");
	hMessage.AddString("params", sMessage);
	hMessage.AddString("params", NULL_STRING);
	hMessage.AddString("params", NULL_STRING);
	hMessage.AddString("params", NULL_STRING);
	hMessage.AddString("params", NULL_STRING);

	EndMessage();
	
	if(isFirstRun)
	{
		DataPack dp = new DataPack();
		CreateDataTimer(0.1, Timer_PrintHintEconRepeat, dp);
		dp.WriteCell(itemDef);
		dp.WriteCell(client);
	}
}

Action Timer_PrintHintEconRepeat(Handle timer, DataPack dp)
{
	dp.Reset();
	
	CEconItemDefinition itemDef = dp.ReadCell();
	int client = dp.ReadCell();
	
	PrintHintItemEconImage(client, itemDef, false);
}
