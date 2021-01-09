#if defined _miscchanger_included_
  #endinput
#endif
#define _miscchanger_included_

#define MAX_ITEM_NAME_LENGTH 64
#define MAX_ITEM_VALUE_LENGTH 64
#define MAX_ITEM_COMMAND_LENGTH 64

enum struct ItemData
{
	// Display Name of the item.
	char name[MAX_ITEM_NAME_LENGTH];
	
	// Value of the item to apply on use.
	char value[MAX_ITEM_VALUE_LENGTH];
	
	// Index of the category the item belongs to.
	int category_index;
}

// MiscChanger_RegisterItem
enum
{
	REGISTER_PARAM_ITEM_NAME = 1,
	REGISTER_PARAM_ITEM_CATEGORIES,
	REGISTER_PARAM_ITEM_VALUES,
	REGISTER_PARAM_APPLY_ITEM
}

/**
 * Called when the core plugin is ready.
 * -
 * Using all natives that relate to the items must be after this forward,
 * if the plugin has been loaded after the core use 'MiscChanger_IsCoreReady()'
 * On 'OnPluginStart()' to check.
 */
forward void MiscChanger_OnCoreReady();

/**
 * Called when the core plugin is getting unloaded.
 * 
 */
forward void MiscChanger_OnCoreUnloaded();

/**
 * Returns if the core is ready or not.
 * -
 * @note Use this on 'OnPluginStart()' to check if the core is already loaded
 * (In cases of late load / the module is loading after core).
 * -
 * @return        whether or not the core is ready.
 */
native bool MiscChanger_IsCoreReady();

/**
 * Registers an item in the core plugin.
 *
 * @param name				The name of the item that will show in the main menu. (Will be added even if short name already exists)
 * @param categories		ArrayList of the categories of the item. (pass null for no categories)
 * @param items				ArrayList of the items.
 * @param apply_item		A function to use to apply the value.
 *
 * @note					apply_item must be public and with the following signature: (int client, char[] new_value)
 *
 * @return					index of the item in the Items ArrayList.
 */
native int MiscChanger_RegisterItem(const char[] name, ArrayList categories, ArrayList values, Function apply_item);

/**
 * Changes the value of a specific item for a client.
 *
 * @param client		The client index.
 * @param index			The index of the item to change.
 * @param new_value		The new value to set.
 *
 */
native void MiscChanger_SetClientItemValue(int client, int index, char[] new_value);

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
//forward void MiscChanger_OnItemChangedPre(int client, MCItem itemLoaded, int oldvalue, int &newvalue, bool isFirstLoad);

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
//forward void MiscChanger_OnItemChangedPost(int client, MCItem itemLoaded, int oldvalue, int newvalue, bool isFirstLoad);

/**
 * Gets the client default value of an item.
 *
 * @param client			Client index.
 * @param item				Item index.
 *
 */
//native int MiscChanger_GetClientItem(int client, MCItem item);

/**
 * Sets the client value of an item.
 *
 * @param client			Client index.
 * @param item				Item to change.
 * @param value				Value to set. if not specified 0 is the default client item. (from his inventory)
 *
 */
//native void MiscChanger_SetClientItem(int client, MCItem item, int value = 0);

/**
 * Gets the client default value of an item.
 *
 * @param client			Client index.
 * @param item				Item index.
 *
 */
//native int MiscChanger_GetClientItemDefault(int client, MCItem item);

public SharedPlugin __pl_miscchanger = 
{
	name = "MiscChanger",
	file = "MiscChanger_DEV_Simple.smx",
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