/**
 * [SprLett] Editor: Attributes menu
 */

#include <amxmodx>
#include <reapi>

Menu_Attrs(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Attrs");

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_OTHER_ACTION")), fmt("#%s", MOVEMENU_CMD));

    new Float:Offset = get_entvar(gSelWord[UserId], var_SL_WordOffset);
    menu_additem(MenuId, Lang("MENU_OTHER_OFFSETPP"), fmt("$%s %.1f", OFFSET_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_OTHER_OFFSETMM"), fmt("$%s %.1f", OFFSET_CMD, -gMoveStep[UserId]));
    menu_addtext(MenuId, fmt("%l", "MENU_OTHER_CURRENT_OFFSET", Offset), 0);

    new CharsetName[32];
    get_entvar(gSelWord[UserId], var_SL_WordCharset, CharsetName, charsmax(CharsetName));
    menu_additem(MenuId, fmt("%l", "MENU_OTHER_CHARSET", CharsetName), "#slfontmenu");
    menu_additem(MenuId, Lang("MENU_OTHER_EDIT_WORD"), fmt("#messagemode %s", WRITE_CMD));
    menu_additem(MenuId, Lang("MENU_OTHER_SAVE_WORD"), fmt("$%s", SAVE_CMD));
    menu_additem(MenuId, Lang("MENU_OTHER_REMOVE_WORD"), "#sldeleteconfirm");
    
    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Attrs(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, ATTRSMENU_CMD);
}


@Cmd_FontMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    new MenuId = menu_create("Шрифт надписи", "@MenuH_Font");
    new Name[32], FileType:Type;
    new Dir = open_dir("sprites/SprLett/Charsets/", Name, charsmax(Name), Type), Count;
    if(Dir){
        do{
            if(Type != FileType_Directory || Name[0] == '.' || Name[0] == '!') continue;
            if(!file_exists(fmt("sprites/SprLett/Charsets/%s/chars.spr", Name))
               || !file_exists(fmt("sprites/SprLett/Charsets/%s/map.txt", Name))) continue;
            menu_additem(MenuId, Name, Name);
            Count++;
        }while(Count < 32 && next_file(Dir, Name, charsmax(Name), Type));
        close_dir(Dir);
    }
    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_display(UserId, MenuId);
}
@MenuH_Font(const UserId, const MenuId, const ItemId){
    if(ItemId < 0){ menu_destroy(MenuId); Menu_Main(UserId); return; }
    new Name[32];
    menu_item_getinfo(MenuId, ItemId, _, Name, charsmax(Name));
    menu_destroy(MenuId);
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    new Previous[32];
    get_entvar(gSelWord[UserId], var_SL_WordCharset, Previous, charsmax(Previous));
    set_entvar(gSelWord[UserId], var_SL_WordCharset, Name);
    if(!SprLett_BuildWord(gSelWord[UserId])){
        set_entvar(gSelWord[UserId], var_SL_WordCharset, Previous);
        client_print(UserId, print_chat, "[Табличка] Шрифт недоступен; прежнее оформление сохранено.");
    }
    Menu_Attrs(UserId);
}
