#include <MiscChanger>

#define PREFIX " \x04"... PREFIX_NO_COLOR ..."\x01"
#define PREFIX_NO_COLOR "[MiscChangerAPI]"

public void OnPluginStart()
{
	RegConsoleCmd("sm_setmk", Command_SetMusickitNum);
	RegConsoleCmd("sm_getmk", Command_GetMusickitNum);
	RegConsoleCmd("sm_getdf", Command_GetDefaults);
}

public Action Command_GetDefaults(int client, int argc)
{
	PrintToChat(client, "%s Your Defaults:", PREFIX);
	PrintToChat(client, "Music-Kit Num: %d", MiscChanger_GetClientItemDefault(client, MCITEM_MUSICKIT));
	PrintToChat(client, "Coin / Pin Def Index: %d", MiscChanger_GetClientItemDefault(client, MCITEM_COIN));
	return Plugin_Handled;
}

public Action Command_GetMusickitNum(int client, int argc)
{
	PrintToChat(client, "%s Your Music-Kit Num: \x04%d\x01!", PREFIX, MiscChanger_GetClientItem(client, MCITEM_MUSICKIT));
	return Plugin_Handled;
}

public Action Command_SetMusickitNum(int client, int argc)
{
	MiscChanger_SetClientItem(client, MCITEM_MUSICKIT, GetCmdArgInt(1));
	PrintToChat(client, "%s Changed Music-Kit Num to \x04%d\x01!", PREFIX, GetCmdArgInt(1));
	return Plugin_Handled;
}

public Action MiscChanger_OnItemChangedPre(int client, MCItem itemLoaded, int oldvalue, int &newvalue, bool isFirstLoad)
{
	PrintToChatAll("[MiscChanger_OnItemChangedPre]");
	PrintToChatAll("[DATA] client: %d", client);
	PrintToChatAll("[DATA] itemLoaded: %d", itemLoaded);
	PrintToChatAll("[DATA] oldvalue: %d", oldvalue);
	PrintToChatAll("[DATA] newvalue: %d", newvalue);
	PrintToChatAll("[DATA] isFirstLoad: %b", isFirstLoad);
	
	// Blocking works.
	/*
	PrintToChatAll("[TEST] BLOCK CHANGE.")
	return Plugin_Handled;
	*/
	
	// Changing newvalue works
	/*
	if(itemLoaded == MCITEM_MUSICKIT)
	{
		newvalue = GetRandomInt(0, 40);
		PrintToChatAll("[TEST] Random music kit has been generated (%d)", newvalue);
	}
	*/
	
	return Plugin_Continue;
}

public void MiscChanger_OnItemChangedPost(int client, MCItem itemLoaded, int oldvalue, int newvalue, bool isFirstLoad)
{
	PrintToChatAll("[MiscChanger_OnItemChangedPost]");
	PrintToChatAll("[DATA] client: %d", client);
	PrintToChatAll("[DATA] itemLoaded: %d", itemLoaded);
	PrintToChatAll("[DATA] oldvalue: %d", oldvalue);
	PrintToChatAll("[DATA] newvalue: %d", newvalue);
	PrintToChatAll("[DATA] isFirstLoad: %b", isFirstLoad);
}