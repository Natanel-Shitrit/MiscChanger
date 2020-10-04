#if defined _miscchanger_included_
  #endinput
#endif
#define _miscchanger_included_

#define MUSIC_KIT_MAX_NAME_LEN 48
#define COIN_SET_MAX_NAME_LEN 48
#define COIN_MAX_NAME_LEN 48
#define PIN_MAX_NAME_LEN 48

enum MCItem
{
	MCITEM_START = -1,
	MCITEM_MUSICKIT = 0,
	MCITEM_PIN,
	MCITEM_COIN,
	MCITEM_COIN_OR_PIN,
	MCITEM_END
}

/**
 * Called when a item value has been changed.
 * 
 * @param client 			Client index.
 * @param item				Item that has been changed.
 * @param oldvalue			The value of the item new (before the change).
 * @param &newvalue			The value of the item that will be after the change.
 * @param firstLoad			If this is the first load (value from the database).
 *
 * @note					if newvalue set to 0 the plugin will use the players item from his inventory.
 * @return					Plugin_Handled or higher to block.
 */
forward Action MiscChanger_OnItemChangedPre(int client, MCItem itemLoaded, int oldvalue, int &newvalue, bool isFirstLoad);


/**
 * Called when a item value has been changed.
 * 
 * @param client 			Client index.
 * @param item				Item that has been changed.
 * @param oldvalue			The value of the item that was before the change.
 * @param &newvalue			The value of the item now (after the change).
 * @param firstLoad			If this is the first load (value from the database).
 *
 */
forward void MiscChanger_OnItemChangedPost(int client, MCItem itemLoaded, int oldvalue, int newvalue, bool isFirstLoad);

/**
 * Gets the client default value of an item.
 *
 * @param client			Client index.
 * @param item				Item index.
 *
 */
native int MiscChanger_GetClientItem(int client, MCItem item);

/**
 * Sets the client value of an item.
 *
 * @param client			Client index.
 * @param item				Item to change.
 * @param value				Value to set. if not specified 0 is the default client item. (from his inventory)
 *
 */
native void MiscChanger_SetClientItem(int client, MCItem item, int value = 0);

/**
 * Gets the client default value of an item.
 *
 * @param client			Client index.
 * @param item				Item index.
 *
 */
native int MiscChanger_GetClientItemDefault(int client, MCItem item);

public SharedPlugin __pl_miscchanger = 
{
	name = "MiscChanger",
	file = "MiscChanger.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_miscchanger_SetNTVOptional()
{
	MarkNativeAsOptional("MiscChanger_GetClientItem");
	MarkNativeAsOptional("MiscChanger_SetClientItem");
	MarkNativeAsOptional("MiscChanger_GetClientItemDefault");
}
#endif