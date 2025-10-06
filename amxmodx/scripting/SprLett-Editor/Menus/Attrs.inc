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
    menu_additem(MenuId, fmt("%l", "MENU_OTHER_CHARSET", CharsetName), fmt("#messagemode %s", CHARSET_CMD));
    menu_additem(MenuId, Lang("MENU_OTHER_EDIT_WORD"), fmt("#messagemode %s", WRITE_CMD));
    menu_additem(MenuId, Lang("MENU_OTHER_SAVE_WORD"), fmt("$%s", SAVE_CMD));
    menu_additem(MenuId, Lang("MENU_OTHER_REMOVE_WORD"), fmt("#%s", REMOVE_CMD));
    
    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Attrs(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, ATTRSMENU_CMD);
}

