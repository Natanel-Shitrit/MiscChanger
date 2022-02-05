void RegisterCommands()
{
    // Server.
    RegServerCmd("sm_miscchanger_dump", Command_Dump, "Dumps all categories and items.");

    // Console.
    RegConsoleCmd("sm_misc", Command_MainMenu);

    // Admin.
}

Action Command_MainMenu(int client, int args)
{
    if (client)
    {
        Menu_DisplayCategory(client, MISC_CHANGER_GLOBAL_CATEGORY_IDENTIFIER);
    }

    return Plugin_Handled;
}

Action Command_Dump(int args)
{
    PrintToServer("*** [Misc-Changer Dump Start] ***");

    StringMapSnapshot categories_snapshot = g_Categories.Snapshot();
    char current_identifier[MISC_CHANGER_MAX_IDENTIFIER_LENGTH];
    Category current_category_data;
    Item current_item_data;

    for (int current_category; current_category < g_Categories.Size; current_category++)
    {
        // Get identifier.
        categories_snapshot.GetKey(current_category, current_identifier, sizeof(current_identifier));

        // Get data.
        g_Categories.GetArray(current_identifier, current_category_data, sizeof(current_category_data));

        // Print data.
        PrintToServer("\tCategory [%d]", current_category);
        PrintToServer("\t\tidentifier: %s", current_identifier);
        PrintToServer("\t\tdisplay name: %s", current_category_data.display_name);
        PrintToServer("\t\tdescription: %s", current_category_data.description);
        PrintToServer("\t\titems: %X", current_category_data.items);

        if (current_category_data.items)
        {
            PrintToServer("\n");

            for (int current_item; current_item < current_category_data.items.Length; current_item++)
            {
                // Get identifier.
                current_category_data.items.GetString(current_item, current_identifier, sizeof(current_identifier));

                // Get data.
                g_Items.GetArray(current_identifier, current_item_data, sizeof(current_item_data));
                
                // Print data.
                PrintToServer("\t\t\tItem [%d]", current_item);
                PrintToServer("\t\t\t\tidentifier: %s", current_identifier);
                PrintToServer("\t\tdisplay name: %s\n", current_item_data.display_name);
            }
        }

        if (current_category < g_Categories.Size - 1)
        {
            PrintToServer("\n");
        }
    }

    delete categories_snapshot;
    
    PrintToServer("*** [Misc-Changer Dump End] ***");
    return Plugin_Handled;
}