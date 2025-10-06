/**
 * [SprLett] Editor: Move menu
 */

#include <amxmodx>
#include <reapi>

Menu_Move(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Move");

    new Float:Origin[3];
    get_entvar(gSelWord[UserId], var_origin, Origin);

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_MOVE_ACTION")), fmt("#%s", ROTATEMENU_CMD));
    menu_additem(MenuId, fmt("%l", "MENUS_STEP", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));
    menu_additem(MenuId, Lang("MENU_MOVE_XPP"), fmt("$%s %.1f 0.0 0.0", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_MOVE_XMM"), fmt("$%s %.1f 0.0 0.0", MOVE_CMD, -gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_MOVE_YPP"), fmt("$%s 0.0 %.1f 0.0", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_MOVE_YMM"), fmt("$%s 0.0 %.1f 0.0", MOVE_CMD, -gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_MOVE_ZPP"), fmt("$%s 0.0 0.0 %.1f", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_MOVE_ZMM"), fmt("$%s 0.0 0.0 %.1f", MOVE_CMD, -gMoveStep[UserId]));
    menu_addtext(MenuId, fmt("%l", "MENU_MOVE_CURRENT_VALUE", Origin[0], Origin[1], Origin[2]), 0);

    menu_addblank2(MenuId);
    menu_additem(MenuId, Lang("MENUS_BACK"), fmt("#%s", MAINMENU_CMD));

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_EXIT"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_ALL);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Move(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, MOVEMENU_CMD);
}
