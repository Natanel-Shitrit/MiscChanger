/*=======================================[ MENUS ]=======================================*/
void Menu_DisplayCategory(int client, const char[] category_identifier, int first_item = 0)
{
	bool go_to_last_memu;

	Category category;
	if (!g_Categories.GetArray(category_identifier, category, sizeof(category)))
	{
		PrintToChat(client, "%s Couldn't load category data.", MISC_CHANGER_PREFIX);
		go_to_last_memu = true;
	}
	else if (!category.items || !category.items.Length)
	{
		PrintToChat(client, "%s \x02'%s'\x01 Category is empty.", MISC_CHANGER_PREFIX, category.display_name);
		go_to_last_memu = true;
	}

	if (go_to_last_memu)
	{
		g_Players[client].OpenLastMenu(client);
		return;
	}

	Menu category_menu = new Menu(Handler_CategoryMenu);

	category_menu.SetTitle("%s\n%s:\n ", MISC_CHANGER_MENU_PREFIX, category.display_name);

	// Buffers for the loop.
	char current_item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], current_item_display_name[MISC_CHANGER_MAX_NAME_LENGTH];
	Category current_category_data;
	Item current_item_data;

	for (int current_item; current_item < category.items.Length; current_item++)
	{
		// Get identifier.
		category.items.GetString(current_item, current_item_identifier, sizeof(current_item_identifier));

		// Check if the item is a category, an item, and if it's not found, skip it, reomve it, and log an error.
		if (g_Categories.GetArray(current_item_identifier, current_category_data, sizeof(current_category_data)))
		{
			Format(current_item_display_name, sizeof(current_item_display_name), "[C] %s", current_category_data.display_name);
		}
		else if (g_Items.GetArray(current_item_identifier, current_item_data, sizeof(current_item_data)))
		{
			strcopy(current_item_display_name, sizeof(current_item_display_name), current_item_data.display_name);
		}
		else
		{
			LogError("[Menu_DisplayMainMenu] Unknown item in '%s': '%s'.", category.display_name, current_item_identifier);
			category.items.Erase(current_item);
			continue;
		}

		// Add item to menu.
		category_menu.AddItem(current_item_identifier, current_item_display_name);
	}

	if (g_Players[client].HasMenuFolding())
	{
		category_menu.ExitBackButton = true;
		FixMenuGap(category_menu);
	}

	strcopy(g_Players[client].menu_data, sizeof(Player::menu_data), category_identifier);
	
	// Display menu to client.
	category_menu.DisplayAt(client, first_item, MENU_TIME_FOREVER);
}

/*
	void Menu_DisplayItem(int client, const char[] item_identifier, int first_item = 0)
	{
		Item item;
		if (!g_Items.GetArray(item_identifier, item, sizeof(item)))
		{
			PrintToChat(client, "%s Couldn't load category data.", MISC_CHANGER_PREFIX);
			g_Players[client].OpenLastMenu(client);
			return;
		}

		Menu item_menu = new Menu(Handler_ItemMenu);

		item_menu.SetTitle("%s %s:\n ", MISC_CHANGER_MENU_PREFIX, item.display_name);

		if (g_Players[client].HasMenuFolding())
		{
			item_menu.ExitBackButton = true;
			FixMenuGap(item_menu);
		}

		// Display menu to client.
		item_menu.DisplayAt(client, first_item, MENU_TIME_FOREVER);
	}
*/
/*===================================[ MENU HANDLERS ]====================================*/
int Handler_CategoryMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int client = param1, selected_item = param2;

			char selected_item_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH], selected_item_display_name[MISC_CHANGER_MAX_NAME_LENGTH];
			menu.GetItem(
				selected_item,
				selected_item_identifier,
				sizeof(selected_item_identifier),
				_,
				selected_item_display_name,
				sizeof(selected_item_display_name)
			);

			g_Players[client].AddMenuFolding(Menu_DisplayCategory, menu.Selection, g_Players[client].menu_data);

			if (g_Categories.GetArray(selected_item_identifier, {0}, 0))
			{
				Menu_DisplayCategory(client, selected_item_identifier);
			}
			else if (g_Items.GetArray(selected_item_identifier, {0}, 0))
			{
				if (Call_OnItemSelectedInMenu(client, selected_item_identifier, selected_item_display_name))
				{
					delete g_Players[client].menu_foldings;
				}
			}
			else
			{
				// TODO: do something.
			}
		}
		
		case MenuAction_Cancel:
		{
			int client = param1, cancel_reason = param2;
			g_Players[client].HandleMenuCancel(client, cancel_reason);
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

// Fixs the menu gap created when Exit-Back button is used. (Thank you KoNLiG)
void FixMenuGap(Menu menu)
{
    int max_items = 6 - menu.ItemCount;
	
    for (int current_item = 0; current_item < max_items; current_item++) 
    {
        menu.AddItem("", "", ITEMDRAW_NOTEXT);
    }
}