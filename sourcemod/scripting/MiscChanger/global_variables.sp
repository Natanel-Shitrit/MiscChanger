enum struct Category
{
	// Display name for menus, chat, etc...
	char display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	
	// Description. (Explanation or / and What items are included in the category)
	char description[MISC_CHANGER_MAX_DESCRIPTION_LENGTH];

	// All of the items of the category.
	ArrayList items;
}
StringMap g_Categories;

enum struct Item
{
	// Display name for menus, chat, etc...
	char display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	
	// Item attributes.
	StringMap attributes;

	bool GetAttribute(const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH)
	{
		// Returns true on success, false on failure. (fails if attributes StringMap is null or if item doesn't exist in the attributes StringMap)
		return (this.attributes && this.attributes.GetString(attribute, value_buffer, buffer_size));
	}

	bool SetAttribute(const char[] attribute, char[] value, bool override = true)
	{
		if (!this.attributes)
		{
			this.attributes = new StringMap();
		}

		// Returns true on success, false on failure. (if override is false and key already set)
		return this.attributes.SetString(attribute, value, override);
	}

	bool RemoveAttribute(const char[] identifier)
	{
		bool return_value = this.attributes.Remove(identifier);

		if (!this.attributes.Size)
		{
			delete this.attributes;
		}
		
		return return_value;
	}

	void RemoveAllAttributes()
	{
		delete this.attributes;
	}
}
StringMap g_Items;

enum struct MenuFolding
{
	// Function that displays the menu.
	Function display_function;
	
	// The menu selection to send to the display function.
	int selection;
	
	// Data to pass to the menu.
	char data[256];
}

enum struct Player
{
	// items[identifier] → attributes[attribute]
	StringMap items;

	bool GetItem(const char[] identifier, StringMap &attributes)
	{
		// returns true on success, false on failure. (if items StringMap is null or item doesn't exist)
		return (this.items && this.items.GetValue(identifier, attributes));
	}

	bool SetItem(const char[] identifier, StringMap attributes, bool override = true)
	{
		if (!this.items)
		{
			this.items = new StringMap();
		}

		// returns true on success, false on failure. (if override is false and key already set)
		return this.items.SetValue(identifier, attributes, override);
	}

	bool AddItem(const char[] identifier, bool return_true_if_exists = true)
	{
		// returns true if the item wasn't set, false if the item was set and 'return_true_if_exists' is false.
		return (this.SetItem(identifier, null, false) || return_true_if_exists);
	}

	bool GetItemAttribute(const char[] identifier, const char[] attribute, char[] value_buffer, int buffer_size = MISC_CHANGER_MAX_ATTRIBUTE_VALUE_LENGTH)
	{
		// Get item attributes.
		StringMap attributes;
		if (!this.GetItem(identifier, attributes))
		{
			// Failed to get the item attributes. (items StringMap is null or item doesn't exist)
			return false;
		}

		// Returns true on success, false on failure. (fails if attributes StringMap is null or item doesn't exist in the attributes StringMap) 
		return (attributes && attributes.GetString(attribute, value_buffer, buffer_size));
	}

	bool SetItemAttribute(const char[] identifier, const char[] attribute, const char[] value, bool override = true)
	{
		// Get item attributes.
		StringMap attributes;
		if (!this.GetItem(identifier, attributes))
		{
			// Failed to get the item attributes. (items StringMap is null or item doesn't exist)
			return false;
		}

		// If the item attributes StringMap doesn't exist yet, we need to create it.
		if (!attributes)
		{
			// Create the new item attributes StringMap and update it in the player items StringMap.
			this.SetItem(identifier, (attributes = new StringMap()));
		}

		// Returns true on success, false on failure. (if override is false and key already set)
		return attributes.SetString(attribute, value, override);
	}

	bool RemoveItem(const char[] identifier)
	{
		// Get item attributes.
		StringMap attributes;
		if (!this.GetItem(identifier, attributes))
		{
			// Failed to get the item attributes. (items StringMap is null or item doesn't exist)
			return false;
		}

		// Delete the attributes.
		delete attributes;

		// Remove the item from items StringMap (no need to save the return value because if the item didn't exist the first check should've catched it)
		this.items.Remove(identifier);

		// Remove the items StringMap if it's empty now.
		if (!this.items.Size)
		{
			delete this.items;
		}

		// Removed successfully.
		return true;
	}

	bool RemoveAllItems()
	{
		// If the items StringMap is already null we don't have anything to remove.
		if (!this.items)
		{
			return false;
		}

		// Buffer to get the current key. (identifier)
		char current_item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];

		// Get a snapshot of the items StringMap
		StringMapSnapshot items_snapshot = this.items.Snapshot();
		for (int current_item; current_item < this.items.Size; current_item++)
		{
			// Get the current item identifier from the snapshot.
			items_snapshot.GetKey(current_item, current_item_identifier, sizeof(current_item_identifier));

			// Remove the current item. (last item will delete the items StringMap itself)
			this.RemoveItem(current_item_identifier);
		}

		// Delete snapshot because it doesn't delete it self and we don't need it anymore.
		delete items_snapshot;

		// All items removed
		return true;
	}

	ArrayStack menu_foldings;
	char menu_data[128];

	void AddMenuFolding(Function display_function, int selection, const char[] data = "")
	{
		if (!this.menu_foldings)
		{
			this.menu_foldings = new ArrayStack(sizeof(MenuFolding));
		}

		MenuFolding new_menu_folding;
		
		new_menu_folding.display_function = display_function;
		new_menu_folding.selection = selection;
		strcopy(new_menu_folding.data, sizeof(MenuFolding::data), data);
		
		this.menu_foldings.PushArray(new_menu_folding);
	}
	
	bool OpenLastMenu(int client)
	{
		if (!this.menu_foldings || this.menu_foldings.Empty)
		{
			return false;
		}
		
		MenuFolding last_menu_folding;
		this.menu_foldings.PopArray(last_menu_folding);

		Call_StartFunction(INVALID_HANDLE, last_menu_folding.display_function);
		Call_PushCell(client);
		Call_PushString(last_menu_folding.data);
		Call_PushCell(last_menu_folding.selection);
		Call_Finish();

		return true;
	}
	
	void HandleMenuCancel(int client, int reason)
	{
		if (reason == MenuCancel_ExitBack)
		{
			this.OpenLastMenu(client);
		}
		else
		{
			delete this.menu_foldings;
		}
	}

	bool HasMenuFolding()
	{
		return (this.menu_foldings != null && !this.menu_foldings.Empty);
	}
}
Player g_Players[MAXPLAYERS + 1];

void InitializeGlobalVariables()
{
	// Each category is stored and associated to a unique key.
	g_Categories = new StringMap();

	// Each item is stored and associated to a unique key.
	g_Items = new StringMap();

	// Add global items category
	Category global_category;
	//FormatEx(global_category.display_name, sizeof(Category::display_name), "%t", "Global Category Name");
	FormatEx(global_category.display_name, sizeof(Category::display_name), "Global");
	g_Categories.SetArray(MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER, global_category, sizeof(global_category));
}