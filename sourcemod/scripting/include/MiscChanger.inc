#if defined _miscchanger_included_
  #endinput
#endif
#define _miscchanger_included_

#define MISC_CHANGER_LIB_NAME "MiscChanger"

#define MISC_CHANGER_MENU_PREFIX "[MiscChanger]"
#define MISC_CHANGER_PREFIX " \x04"... MISC_CHANGER_MENU_PREFIX ..."\x01"

#define MISC_CHANGER_MAX_NAME_LENGTH 64
#define MISC_CHANGER_MAX_IDENTIFIER_LENGTH 64
#define MISC_CHANGER_MAX_DESCRIPTION_LENGTH 128
#define MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH 256

#define MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER "global"

forward Action MiscChanger_OnCategoryRegister(const char[] identifier, char[] display_name, char[] description);
forward void MiscChanger_OnCategoryRegistered(const char[] identifier, const char[] display_name, const char[] description, bool already_exists);

forward Action MiscChanger_OnItemRegister(const char[] identifier, char[] display_name);
forward void MiscChanger_OnItemRegistered(const char[] identifier, const char[] display_name, bool already_exists);

forward Action MiscChanger_OnItemAddToCategory(const char[] item_identifier, const char[] cateogry_identifier);
forward void MiscChanger_OnItemAddedToCategory(const char[] item_identifier, const char[] cateogry_identifier, bool already_exists);

forward bool MiscChanger_OnItemSelectedInMenu(int client, const char[] item_identifier, const char[] display_name);

// Register a category.
native bool MiscChanger_RegisterCategory(const char[] identifier, const char[] display_name, const char[] description, bool return_true_if_exists = true);

// Register an item.
native bool MiscChanger_RegisterItem(const char[] identifier, const char[] display_name, bool return_true_if_exists = true);

// Add an item to a category.
native bool MiscChanger_AddItemToCategory(const char[] item_identifier, const char[] cateogry_identifier, bool return_true_if_exists = true);

// Opens the last menu folding of a player.
native bool MiscChanger_OpenLastMenuFolding(int client);

// Gets the value of a specific attribute from a specific item.
native bool MiscChanger_GetItemAttribute(const char[] item_identifier, const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH);

// Sets the value of a specific attribute from a specific item.
native bool MiscChanger_SetItemAttribute(const char[] item_identifier, const char[] attribute, const char[] value, bool override = true);

// Removes a specific attribute from a specific item.
native bool MiscChanger_RemoveItemAttribute(const char[] item_identifier, const char[] attribute);

// Removes all attributes from a specific item.
native bool MiscChanger_RemoveAllItemAttributes(const char[] item_identifier);

// Adds an item to the player StringMap.
native bool MiscChanger_AddItemToPlayer(int client, const char[] item_identifier, bool return_true_if_exists = true);

// Removes an item from the player StringMap.
native bool MiscChanger_RemoveItemFromPlayer(int client, const char[] item_identifier);

// Removes all items from the player StringMap.
native bool MiscChanger_RemoveAllPlayerItems(int client);

// Returns a specific item StringMap of a specific client.
native bool MiscChanger_GetPlayerItem(int client, const char[] item_identifier, StringMap &attributes);

// Returns the items StringMap of a specific client.
native StringMap MiscChanger_GetPlayerItems(int client);

// Gets the value of a specific attribute from a specific item of a specific client.
native bool MiscChanger_GetPlayerItemAttribute(int client, const char[] item_identifier, const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH);

// Sets the value of a specific attribute from a specific item of a specific client.
native bool MiscChanger_SetPlayerItemAttribute(int client, const char[] item_identifier, const char[] attribute, const char[] value, bool override = true);
		
public SharedPlugin __pl_miscchanger = 
{
	name = MISC_CHANGER_LIB_NAME,
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
	MarkNativeAsOptional("MiscChanger_RegisterCategory");
	MarkNativeAsOptional("MiscChanger_RegisterItem");
	MarkNativeAsOptional("MiscChanger_AddItemToCategory");
	MarkNativeAsOptional("MiscChanger_OpenLastMenuFolding");
	//MarkNativeAsOptional("MiscChanger_");
}
#endif