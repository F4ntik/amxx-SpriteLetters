/**
 * [SprLett] Editor: Direction menu
 */

#include <amxmodx>
#include <reapi>

Menu_Direction(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Direction");

    new Float:Dir[3];
    get_entvar(gSelWord[UserId], var_SL_WordDir, Dir);

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_DIR_ACTION")), fmt("#%s", COLORMENU_CMD));
    menu_additem(MenuId, fmt("%l", "MENUS_STEP", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));
    menu_additem(MenuId, Lang("MENU_DIR_XPP"), fmt("$%s %.1f 0.0", DIR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_DIR_XMM"), fmt("$%s %.1f 0.0", DIR_CMD, -gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_DIR_YPP"), fmt("$%s 0.0 %.1f", DIR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_DIR_YMM"), fmt("$%s 0.0 %.1f", DIR_CMD, -gMoveStep[UserId]));
    menu_addtext(MenuId, fmt("%l", "MENU_DIR_CURRENT_VALUE", Dir[0], Dir[1]), 0);

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Direction(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, DIRMENU_CMD);
}

