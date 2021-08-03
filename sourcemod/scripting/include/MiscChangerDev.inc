#if defined _miscchanger_included_
  #endinput
#endif
#define _miscchanger_included_

#define MAX_ITEM_NAME_LENGTH 64
#define MAX_ITEM_VALUE_LENGTH 64
#define MAX_ITEM_COMMAND_LENGTH 64

// Used to pass the items.
// Example: In MiscChanger_RegisterItem's items ArrayList, returned ArrayList from MiscChanger_GetClientItemsValues native.
enum struct ItemValue
{
	// Display Name of the item.
	char display_name[MAX_ITEM_NAME_LENGTH];
	
	// Value of the item to apply on use.
	char value[MAX_ITEM_VALUE_LENGTH];
	
	// Index of the category the item belongs to.
	int category_index;
}

// The structure of an item used in core + passed in MiscChanger_GetItemsArrayList returned ArrayList.
enum struct Item
{
	// The name of the item.
	char name[MAX_ITEM_NAME_LENGTH];
	
	// For items that need to have shared saved data.
	char data_name[MAX_ITEM_NAME_LENGTH];
	
	// ArrayList of category names.
	// TODO: Close on delete ~~
	ArrayList categories;
	
	// ArrayList of the values.
	// TODO: Close on delete ~~
	ArrayList values;
	
	// ArrayList of the item commands.
	// TODO: Close on delete ~~
	ArrayList commands;
	
	// Owner Plugin
	Handle owner;
	
	// function to use to apply the item
	Function apply_item;
	
	// Fake call to apply the item.
	void ApplyItem(int client, const char[] new_value)
	{
		Call_StartFunction(this.owner, this.apply_item); // int client, char[] new_value
		Call_PushCell(client);
		Call_PushString(new_value);
		Call_Finish();
	}
	
	// Stores item display name into a buffer
	void GetItemDisplayName(int item_index, char[] buffer)
	{
		ItemValue item_data;
		this.values.GetArray(item_index, item_data, sizeof(item_data));
		
		strcopy(buffer, MAX_ITEM_NAME_LENGTH, item_data.display_name);
	}
	
	// Stores category name into a buffer
	void GetCategoryName(int index, char[] buffer)
	{
		this.categories.GetString(index, buffer, MAX_ITEM_NAME_LENGTH);
	}
}

// MiscChanger_RegisterItem
enum
{
	REGISTER_PARAM_ITEM_NAME = 1,
	REGISTER_PARAM_ITEM_CATEGORIES,
	REGISTER_PARAM_ITEM_VALUES,
	REGISTER_PARAM_APPLY_ITEM,
	REGISTER_PARAM_DATA_NAME
}

// MiscChanger_RemoveItem
enum
{
	REMOVE_ITEM_PARAM_INDEX = 1
}

// MiscChanger_GetClientItemValue, MiscChanger_SetClientItemValue
enum
{
	GET_ITEM_PARAM_CLIENT = 1,
	GET_ITEM_PARAM_ITEM,
	GET_ITEM_PARAM_BUFFER,
	GET_ITEM_PARAM_APPLY,
	GET_ITEM_PARAM_FIRST_LOAD
}

/**
 * Called when an item has been registered.
 * 
 * @param item_index	The index of the item.
 * @param item_name		The name of the item.
 * @param data_name		This name is used in modules that save the players prefrences.
 *
 * @note 	item is already in the core global ArrayList (so the remove native can be used here).
 */
forward void MiscChanger_OnItemRegistered(int item_index, const char[] item_name, const char[] data_name);
 
/**
 * Called when an item has been removed.
 * 
 * @param index		The index of the item.
 *
 * @note 			Shifts all items that are above it down 1 slot (useful for correcting item indexs).
 */
 forward void MiscChanger_OnItemRemoved(int item_index);
 
/**
 * Called when client item value is being changed.
 * 
 * @param client 		Client index.
 * @param item_index	Item index that's being changed.
 * @param old_value		The current value of the client item (before the change).
 * @param new_value		The value of the client item after the change.
 * @param first_load	If this is the first load (value from the database / cookie).
 *
 * @note In most cases changing new_value to "0" will set the default item, look in module to verify.
 *
 * @return				Plugin_Handled or higher to block.
 */
forward Action MiscChanger_OnItemValueChange(int client, int item_index, const char[] old_value, char[] new_value, bool first_load);

/**
 * Registers an item in the core plugin.
 *
 * @param name				The name of the item that will show in the main menu.
 * @param values_categories	ArrayList of the categories of the item. (pass null for no categories)
 * @param values			ArrayList of the values (ArrayList of ItemData).
 * @param apply_item		A function to use to apply the value.
 * @param data_name			When not empty - will override the data name for MySQL / Cookies Modules.
 *
 * @note apply_item must be public and with the following signature: (int client, char[] new_value)
 *
 * @return					index of the item in the Items ArrayList.
 */
native int MiscChanger_RegisterItem(const char[] item_name, ArrayList values_categories, ArrayList values, Function apply_item, const char[] data_name = "");

/**
 * Returns a cloned copy of the ArrayList that contains all the items that has been registered.
 *
 * @return    Cloned copy of the ArrayList owned by the calling plugin.
 */
native ArrayList MiscChanger_GetItemsArrayList();

/**
 * Removes an item in a given index.
 *
 * @param item_index	Item index.
 *
 */
native void MiscChanger_RemoveItem(int item_index);

/**
 * Gets the value of a client item.
 *
 * @param client		Client index.
 * @param item_index	Item index.
 * @param buffer		buffer to store the value.
 *
 * @note buffer must be with the size: MAX_ITEM_VALUE_LENGTH
 */
native int MiscChanger_GetClientItemValue(int client, int item_index, char[] buffer);

/**
 * Changes the value of a specific item for a client.
 *
 * @param client		The client index.
 * @param index			The index of the item to change.
 * @param new_value		The new value to set.
 * @param apply_iten	Should the item be applied? (Default: true)
 * @param first_load	Whether or not this is the first load (from MySQL / Cookies)
 *
 */
native void MiscChanger_SetClientItemValue(int client, int item_index, char[] new_value, bool apply_iten = true, bool first_load = false);

/**
 * Gets the ArrayList that contains the client items values.
 *
 * @param client	Client index.
 *
 * @return			A cloned ArrayList. (The plugin owner will be the calling plugin)
 */
native ArrayList MiscChanger_GetClientItemsValues(int client);

public SharedPlugin __pl_miscchanger = 
{
	name = "MiscChanger",
	file = "MiscChanger_DEV.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_miscchanger_SetNTVOptional()
{
	// Core
	MarkNativeAsOptional("MiscChanger_GetItemsArrayList");
	
	// Item
	MarkNativeAsOptional("MiscChanger_RegisterItem");
	
	// pData
	MarkNativeAsOptional("MiscChanger_GetClientItemValue");
	MarkNativeAsOptional("MiscChanger_SetClientItemValue");
	MarkNativeAsOptional("MiscChanger_GetClientItemsValues");
}
#endif