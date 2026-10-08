/** Sign editing: common actions stay on the first screen. */
Menu_Main(const UserId){
    if(!is_user_connected(UserId)) return;
    new MenuId;
    if(!SprLett_Is(gSelWord[UserId], SL_Is_Word)){
        MenuId = menu_create("Таблички^n\wНаведите прицел на надпись", "@MenuH_Main");
        menu_additem(MenuId, "Выбрать надпись под прицелом", fmt("$%s", SELECT_CMD));
        menu_additem(MenuId, "Создать надпись", fmt("#messagemode %s", CREATE_CMD));
    } else {
        new Text[64];
        get_entvar(gSelWord[UserId], var_SL_MarqueeText, Text, charsmax(Text));
        MenuId = menu_create(fmt("Табличка: %.48s^n\w%s", Text,
            SprLett_IsWordSaved(gSelWord[UserId]) ? "Сохранено" : "Есть несохранённые изменения"), "@MenuH_Main");
        menu_additem(MenuId, "Изменить текст", fmt("#messagemode %s", WRITE_CMD));
        menu_additem(MenuId, "Поставить на стену под прицелом", "#slplace");
        menu_additem(MenuId, "Сдвинуть / повернуть", fmt("#%s", MOVEMENU_CMD));
        menu_additem(MenuId, "Рамка и фон", "#slpanelmenu");
        menu_additem(MenuId, "Бегущая строка", fmt("#%s", MARQUEEMENU_CMD));
        menu_additem(MenuId, "Сохранить табличку", fmt("$%s", SAVE_CMD));
        menu_additem(MenuId, "Цвет, шрифт и другие действия", "#slmoremenu");
    }
    menu_setprop(MenuId, MPROP_EXITNAME, "Закрыть");
    menu_display(UserId, MenuId);
}

@MenuH_Main(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId, false)) client_cmd(UserId, MAINMENU_CMD);
}

Menu_More(const UserId){
    new MenuId = menu_create("Табличка: настройки и действия", "@MenuH_More");
    menu_additem(MenuId, "Добавить игровой значок", "#slemoji");
    menu_additem(MenuId, "Цвет текста", fmt("#%s", COLORMENU_CMD));
    menu_additem(MenuId, "Прозрачность и отображение", fmt("#%s", RENDERMENU_CMD));
    menu_additem(MenuId, "Шрифт и расстояние между буквами", fmt("#%s", ATTRSMENU_CMD));
    menu_additem(MenuId, "Вращение", fmt("#%s", ROTATEMENU_CMD));
    menu_additem(MenuId, "Выбрать другую надпись", fmt("$%s", SELECT_CMD));
    menu_additem(MenuId, "Создать новую надпись", fmt("#messagemode %s", CREATE_CMD));
    menu_additem(MenuId, "Удалить выбранную табличку...", "#sldeleteconfirm");
    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_display(UserId, MenuId);
}

@MenuH_More(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId)) Menu_Main(UserId);
}

@Cmd_MoreMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_More(UserId);
}

new gConfirmDelete[MAX_PLAYERS+1];
@Cmd_DeleteConfirm(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    gConfirmDelete[UserId] = gSelWord[UserId];
    new MenuId = menu_create("Удалить табличку и её сохранение?", "@MenuH_DeleteConfirm");
    menu_additem(MenuId, "Нет, вернуться", "no");
    menu_additem(MenuId, "Да, удалить", "yes");
    menu_setprop(MenuId, MPROP_EXITNAME, "Отмена");
    menu_display(UserId, MenuId);
}

@MenuH_DeleteConfirm(const UserId, const MenuId, const ItemId){
    menu_destroy(MenuId);
    if(ItemId == 1 && gConfirmDelete[UserId] && gConfirmDelete[UserId] == gSelWord[UserId])
        @Cmd_Remove(UserId);
    gConfirmDelete[UserId] = 0;
    Menu_Main(UserId);
}

@Cmd_EmojiMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    if(!SprLett_HasCharset(SL_GAMING_CHARSET)){
        client_print(UserId, print_chat, "[Табличка] Установите Gaming_v1 и смените карту для загрузки значков.");
        return;
    }
    new const Names[][] = {"Прицел", "Оружие", "Бомба", "Щит", "Череп", "Огонь", "Трофей", "Мечи", "Команда CT", "Команда T"};
    new MenuId = menu_create("Добавить значок в конец текста", "@MenuH_Emoji");
    for(new i; i < sizeof Names; i++)
        menu_additem(MenuId, fmt("%s  %s", Names[i], SL_GAMING_ALIASES[i]));
    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_display(UserId, MenuId);
}

@MenuH_Emoji(const UserId, const MenuId, const ItemId){
    menu_destroy(MenuId);
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    if(ItemId < 0){ Menu_More(UserId); return; }
    if(ItemId >= sizeof SL_GAMING_GLYPHS) return;
    new Text[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_MarqueeText, Text, charsmax(Text));
    new Len = strlen(Text), Separator = Len > 0 && Text[Len-1] != ' ';
    if(Len + Separator + strlen(SL_GAMING_GLYPHS[ItemId]) > charsmax(Text)){
        client_print(UserId, print_chat, "[Табличка] Текст заполнен. Сократите его перед добавлением значка.");
    } else {
        if(Separator) add(Text, charsmax(Text), " ");
        add(Text, charsmax(Text), SL_GAMING_GLYPHS[ItemId]);
        if(!SprLett_SetWordText(gSelWord[UserId], Text)) ReportBuildError(UserId);
    }
    @Cmd_EmojiMenu(UserId);
}
