
// Category registeration.
GlobalForward 	g_OnCategoryRegister,
				g_OnCategoryRegistered;

// Item registeration.
GlobalForward 	g_OnItemRegister,
				g_OnItemRegistered;

// Item & Category unregisteration.
GlobalForward	g_OnCategoryUnregistered,
				g_OnItemUnregistered;

// Item & Category add to category.
GlobalForward 	g_OnItemAddToCategory,
				g_OnItemAddedToCategory;

GlobalForward	g_OnItemSelectedInMenu;

/*=========================================[ API ]==========================================*/
void InitializeAPI()
{
	InitializeForwards();

	InitializeNatives();
}

/*=======================================[ FORWARDS ]=======================================*/

void InitializeForwards()
{
	g_OnCategoryRegister = new GlobalForward(
		"MiscChanger_OnCategoryRegister",
		ET_Event,
		Param_String,
		Param_String,
		Param_String
	);

	g_OnCategoryRegistered = new GlobalForward(
		"MiscChanger_OnCategoryRegistered",
		ET_Event,
		Param_String,
		Param_String,
		Param_String,
		Param_Cell
	);

	g_OnItemRegister = new GlobalForward(
		"MiscChanger_OnItemRegister",
		ET_Event,
		Param_String,
		Param_String
	);

	g_OnItemRegistered = new GlobalForward(
		"MiscChanger_OnItemRegistered",
		ET_Ignore,
		Param_String,
		Param_String,
		Param_Cell
	);

	g_OnCategoryUnregistered = new GlobalForward(
		"MiscChanger_OnCategoryUnregistered",
		ET_Ignore,
		Param_String
	);

	g_OnItemUnregistered = 	new GlobalForward(
		"MiscChanger_OnItemUnregistered",
		ET_Ignore,
		Param_String
	);

	g_OnItemAddToCategory = new GlobalForward(
		"MiscChanger_OnItemAddToCategory",
		ET_Event,
		Param_String,
		Param_String
	);

	g_OnItemAddedToCategory = new GlobalForward(
		"MiscChanger_OnItemAddedToCategory",
		ET_Event,
		Param_String,
		Param_String,
		Param_Cell
	);

	g_OnItemSelectedInMenu = new GlobalForward(
		"MiscChanger_OnItemSelectedInMenu",
		ET_Event,
		Param_Cell,
		Param_String,
		Param_String
	);

	// g_On = new GlobalForward("MiscChanger_", ET_, Param_);
}

Action Call_OnCategoryRegister(const char[] identifier, char[] display_name, char[] description)
{
	Action return_value;

	Call_StartForward(g_OnCategoryRegister);
	Call_PushString(identifier);
	Call_PushStringEx(display_name, MISC_CHANGER_MAX_NAME_LENGTH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(description, MISC_CHANGER_MAX_NAME_LENGTH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(return_value);

	return return_value;
}

void Call_OnCategoryRegistered(const char[] identifier, const char[] display_name, const char[] description, bool already_exists)
{
	Call_StartForward(g_OnCategoryRegistered);
	Call_PushString(identifier);
	Call_PushString(display_name);
	Call_PushString(description);
	Call_PushCell(already_exists);
	Call_Finish();
}

Action Call_OnItemRegister(const char[] identifier, char[] display_name)
{
	Action return_value;

	Call_StartForward(g_OnItemRegister);
	Call_PushString(identifier);
	Call_PushStringEx(display_name, MISC_CHANGER_MAX_NAME_LENGTH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(return_value);

	return return_value;
}

void Call_OnItemRegistered(const char[] identifier, const char[] display_name, bool already_exists)
{
	Call_StartForward(g_OnItemRegistered);
	Call_PushString(identifier);
	Call_PushString(display_name);
	Call_PushCell(already_exists);
	Call_Finish();
}

void Call_OnCategoryUnregistered(const char[] identifier)
{
	Call_StartForward(g_OnCategoryUnregistered);
	Call_PushString(identifier);
	Call_Finish();
}

void Call_OnItemUnregistered(const char[] identifier)
{
	Call_StartForward(g_OnItemUnregistered);
	Call_PushString(identifier);
	Call_Finish();
}

Action Call_OnItemAddToCategory(const char[] item_identifier, const char[] cateogry_identifier)
{
	Action return_value;

	Call_StartForward(g_OnItemAddToCategory);
	Call_PushString(item_identifier);
	Call_PushString(cateogry_identifier);
	Call_Finish(return_value);

	return return_value;
}

void Call_OnItemAddedToCategory(const char[] item_identifier, const char[] cateogry_identifier, bool already_exists)
{
	Call_StartForward(g_OnItemAddedToCategory);
	Call_PushString(item_identifier);
	Call_PushString(cateogry_identifier);
	Call_PushCell(already_exists);
	Call_Finish();
}

bool Call_OnItemSelectedInMenu(int client, const char[] item_identifier, const char[] display_name)
{
	bool result;

	Call_StartForward(g_OnItemSelectedInMenu);
	Call_PushCell(client);
	Call_PushString(item_identifier);
	Call_PushString(display_name);
	Call_Finish(result);

	return result;
}

/*
	void Call_()
	{
		Call_StartForward(g_);
		Call_PushString();
		Call_PushCell();
		Call_Finish();
	}
*/
/*=======================================[ NATIVES ]========================================*/

void InitializeNatives()
{
	// Register a category.
	// bool MiscChanger_RegisterCategory(const char[] identifier, const char[] display_name, const char[] description, bool return_true_if_exists = true)
	CreateNative("MiscChanger_RegisterCategory", Native_RegisterCategory);

	// Register an item.
	// bool MiscChanger_RegisterItem(const char[] identifier, const char[] display_name, bool return_true_if_exists = true)
	CreateNative("MiscChanger_RegisterItem", Native_RegisterItem);

	// Unregister all categories and / or items registered by the calling plugin.
	// void MiscChanger_UnregisterMe()
	CreateNative("MiscChanger_UnregisterMe", Native_UnregisterMe);

	// Add an item or another category to a category.
	// bool MiscChanger_AddItemToCategory(const char[] item_identifier, const char[] cateogry_identifier, bool return_true_if_exists = true)
	CreateNative("MiscChanger_AddItemToCategory", Native_AddItemToCategory);

	// Opens the last menu folding of a player.
	// bool MiscChanger_OpenLastMenuFolding(int client)
	CreateNative("MiscChanger_OpenLastMenuFolding", Native_OpenLastMenuFolding);

	/////

	// Gets the value of a specific attribute from a specific item.
	// bool MiscChanger_GetItemAttribute(const char[] item_identifier, const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH)
	CreateNative("MiscChanger_GetItemAttribute", Native_GetItemAttribute);

	// Sets the value of a specific attribute from a specific item.
	// bool MiscChanger_SetItemAttribute(const char[] item_identifier, const char[] attribute, const char[] value, bool override = true)
	CreateNative("MiscChanger_SetItemAttribute", Native_SetItemAttribute);
	
	// Removes a specific attribute from a specific item.
	// bool MiscChanger_RemoveItemAttribute(const char[] item_identifier, const char[] attribute)
	CreateNative("MiscChanger_RemoveItemAttribute", Native_RemoveItemAttribute);

	// Removes all attributes from a specific item.
	// bool MiscChanger_RemoveAllItemAttributes(const char[] item_identifier)
	CreateNative("MiscChanger_RemoveAllItemAttributes", Native_RemoveAllItemAttributes);

	/////

	// Adds an item to the player StringMap.
	// bool MiscChanger_AddItemToPlayer(int client, const char[] item_identifier, bool return_true_if_exists = true)
	CreateNative("MiscChanger_AddItemToPlayer", Native_AddItemToPlayer);

	// Removes an item from the player StringMap.
	// bool MiscChanger_RemoveItemFromPlayer(int client, const char[] item_identifier)
	CreateNative("MiscChanger_RemoveItemFromPlayer", Native_RemoveItemFromPlayer);

	// Removes all items from the player StringMap.
	// bool MiscChanger_RemoveAllPlayerItems(int client)
	CreateNative("MiscChanger_RemoveAllPlayerItems", Native_RemoveAllPlayerItems);

	// Returns a specific item StringMap of a specific client.
	// bool MiscChanger_GetPlayerItem(int client, const char[] item_identifier, StringMap &attributes)
	CreateNative("MiscChanger_GetPlayerItem", Native_GetPlayerItem);

	// Returns the items StringMap of a specific client.
	// StringMap MiscChanger_GetPlayerItems(int client)
	CreateNative("MiscChanger_GetPlayerItems", Native_GetPlayerItems);

	// Gets the value of a specific attribute from a specific item of a specific client.
	// bool MiscChanger_GetPlayerItemAttribute(int client, const char[] item_identifier, const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH)
	CreateNative("MiscChanger_GetPlayerItemAttribute", Native_GetPlayerItemAttribute);

	// Sets the value of a specific attribute from a specific item of a specific client.
	// bool MiscChanger_SetPlayerItemAttribute(int client, const char[] item_identifier, const char[] attribute, const char[] value, bool override = true)
	CreateNative("MiscChanger_SetPlayerItemAttribute", Native_SetPlayerItemAttribute);

	// TEMPLATE:
	// any MiscChanger_()
	// CreateNative("MiscChanger_", Native_);
}

any Native_RegisterCategory(Handle plugin, int num_params)
{
	// parameters buffers.
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	Category new_category;

	// Check all parameters have a valid length before using them.
	CheckStringParamLength(1, "category identifier", identifier, sizeof(identifier));
	CheckStringParamLength(2, "category display name", new_category.display_name, sizeof(Category::display_name));
	CheckStringParamLength(3, "category description", new_category.description, sizeof(Category::description));

	if (Call_OnCategoryRegister(identifier, new_category.display_name, new_category.description) >= Plugin_Handled)
	{
		return false;
	}

	// If there is an item with the sent identifier, '.SetArray' will return false.
	// 4th parameter: return_true_if_exists. if '.SetArray' returns false, this will "correct" the return value as requested.
	bool already_exists = !g_Categories.SetArray(identifier, new_category, sizeof(new_category), false);

	Call_OnCategoryRegistered(identifier, new_category.display_name, new_category.description, already_exists);

	return (!already_exists || GetNativeCell(4));
}

any Native_RegisterItem(Handle plugin, int num_params)
{
	// parameters buffers.
	char identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	Item new_item;

	// Check all parameters have a valid length before using them.
	CheckStringParamLength(1, "item identifier", identifier, sizeof(identifier));
	CheckStringParamLength(2, "item display name", new_item.display_name, sizeof(Item::display_name));

	if (Call_OnItemRegister(identifier, new_item.display_name) >= Plugin_Handled)
	{
		return false;
	}

	// If there is an item with the sent identifier, '.SetArray' will return false.
	// 4th parameter: return_true_if_exists. if '.SetArray' returns false, this will "correct" the return value as requested.
	bool already_exists = !g_Items.SetArray(identifier, new_item, sizeof(new_item), false);

	Call_OnItemRegistered(identifier, new_item.display_name, already_exists);

	return (!already_exists || GetNativeCell(3));
}

any Native_UnregisterMe(Handle plugin, int num_params)
{
	return;
}

any Native_AddItemToCategory(Handle plugin, int num_params)
{
	// parameters buffers.
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 category_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	
	// Check all parameters have a valid length before using them.
	CheckStringParamLength(1, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(2, "category identifier", category_identifier, sizeof(category_identifier));

	Category category;
	if (!g_Categories.GetArray(category_identifier, category, sizeof(category)))
	{
		return false;
	}

	if (!g_Items.GetArray(item_identifier, {0}, 0) && !g_Categories.GetArray(item_identifier, {0}, 0))
	{
		return false;
	}

	if (Call_OnItemAddToCategory(item_identifier, category_identifier) >= Plugin_Handled)
	{
		return false;
	}

	if (!category.items)
	{
		category.items = new ArrayList(ByteCountToCells(MISC_CHANGER_MAX_IDENTIFIER_LENGTH));
		g_Categories.SetArray(category_identifier, category, sizeof(category));
	}

	// If there is an item with the sent identifier, '.FindString' will return the index.
	// If '.FindString' doesn't return -1 (means there is an item with the identifier), return according to the 'return_true_if_exists' parameter.
	bool already_exists = (category.items.FindString(item_identifier) != -1);
	if (!already_exists)
	{
		// Push the new item.
		category.items.PushString(item_identifier);
	}
	
	Call_OnItemAddedToCategory(item_identifier, category_identifier, already_exists);
	
	// All went successfully.
	return (!already_exists || GetNativeCell(3)); 
}

any Native_OpenLastMenuFolding(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);

	return g_Players[client].OpenLastMenu(client);
}

any Native_GetItemAttribute(Handle plugin, int num_params)
{
	// parameters buffers.
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 item_attribute[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 attribute_value[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH];
	
	// Check all parameters have a valid length before using them.
	CheckStringParamLength(1, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(2, "item attribute", item_attribute, sizeof(item_attribute));

	Item item;
	if (!g_Items.GetArray(item_identifier, item, sizeof(item)))
	{
		return false;
	}

	bool return_value = item.GetAttribute(item_attribute, attribute_value);

	int buffer_size = GetNativeCell(4);
	SetNativeString(3, attribute_value, Min(buffer_size, MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH));

	return return_value;
}

any Native_SetItemAttribute(Handle plugin, int num_params)
{
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 attribute[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH],
		 attribute_value[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH];
	
	CheckStringParamLength(1, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(2, "item attribute", attribute, sizeof(attribute));
	CheckStringParamLength(3, "attribute value", attribute_value, sizeof(attribute_value));

	Item item;
	if (!g_Items.GetArray(item_identifier, item, sizeof(item)))
	{
		return false;
	}

	bool attributes_was_null = !item.attributes;

	bool return_value = item.SetAttribute(attribute, attribute_value, GetNativeCell(4));

	// If the 'attributes' StringMap was null, a new StringMap was created for it.
	// Without updating the global data it will not be saved.
	if (attributes_was_null && item.attributes)
	{
		g_Items.SetArray(item_identifier, item, sizeof(item));
	}

	return return_value;
}

any Native_RemoveItemAttribute(Handle plugin, int num_params)
{
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 attribute[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH];
	
	CheckStringParamLength(1, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(2, "item attribute", attribute, sizeof(attribute));

	Item item;
	if (!g_Items.GetArray(item_identifier, item, sizeof(item)))
	{
		return false;
	}

	bool return_value = item.RemoveAttribute(attribute);

	// If the 'attributes' StringMap had only this removed attribute, the StringMap got deleted.
	// Without updating the global data it will still point at invalid StringMap handle, this is why this update is necessary.
	if (!item.attributes)
	{
		g_Items.SetArray(item_identifier, item, sizeof(item));
	}

	return return_value;
}

any Native_RemoveAllItemAttributes(Handle plugin, int num_params)
{
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];

	CheckStringParamLength(1, "item identifier", item_identifier, sizeof(item_identifier));

	Item item;
	if (!g_Items.GetArray(item_identifier, item, sizeof(item)))
	{
		return false;
	}

	item.RemoveAllAttributes();

	return true;
}

any Native_AddItemToPlayer(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);

	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	CheckStringParamLength(2, "item identifier", item_identifier, sizeof(item_identifier));

	return g_Players[client].AddItem(item_identifier, GetNativeCell(3));
}

any Native_RemoveItemFromPlayer(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);

	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	CheckStringParamLength(2, "item identifier", item_identifier, sizeof(item_identifier));

	return g_Players[client].RemoveItem(item_identifier);
}

any Native_RemoveAllPlayerItems(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);
	return g_Players[client].RemoveAllItems();
}

any Native_GetPlayerItem(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);

	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
	CheckStringParamLength(2, "item identifier", item_identifier, sizeof(item_identifier));

	StringMap attributes;
	bool return_value = g_Players[client].GetItem(item_identifier, attributes);

	SetNativeCellRef(3, attributes ? CloneHandle(attributes, plugin) : null);

	return return_value;
}

any Native_GetPlayerItems(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);
	return g_Players[client].items ? CloneHandle(g_Players[client].items, plugin) : null;
}

any Native_GetPlayerItemAttribute(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);
	
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 attribute[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH],
		 attribute_value[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH];
	
	CheckStringParamLength(2, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(3, "item attribute", attribute, sizeof(attribute));

	bool return_value = g_Players[client].GetItemAttribute(item_identifier, attribute, attribute_value);

	int buffer_size = GetNativeCell(5);
	SetNativeString(4, attribute_value, Min(buffer_size, MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH));

	return return_value;
}

any Native_SetPlayerItemAttribute(Handle plugin, int num_params)
{
	int client = CheckClientParam(1);
	
	char item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH],
		 attribute[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH],
		 value[MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH];
	
	CheckStringParamLength(2, "item identifier", item_identifier, sizeof(item_identifier));
	CheckStringParamLength(3, "item attribute", attribute, sizeof(attribute));
	CheckStringParamLength(4, "attribute value", value, sizeof(value));

	return g_Players[client].SetItemAttribute(item_identifier, attribute, value, GetNativeCell(5));
}


void CheckStringParamLength(int param_number, const char[] item_name, char[] buffer, int max_length, bool can_be_empty = false, int& param_length = 0)
{
	int error;

	if ((error = GetNativeStringLength(param_number, param_length)) != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Failed to retrive %s.", item_name);
	}

	if (!can_be_empty && !param_length)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s cannot be empty.", item_name);
	}
	
	if (param_length >= max_length)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s cannot be %d characters long (max: %d)", param_length, max_length - 1);
	}

	GetNativeString(param_number, buffer, max_length);
}

int CheckClientParam(int param_number)
{
	int client = GetNativeCell(param_number);

	if (!(1 <= client <= MaxClients))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}

	return client;
}

int Min(int val1, int val2)
{
	return val1 < val2 ? val1 : val2;
}

/*==========================================================================================*/