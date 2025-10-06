/**
 * [SprLett] Editor: Color menu
 */

#include <amxmodx>
#include <reapi>

Menu_Color(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Color");

    new Float:Color[3];
    get_entvar(gSelWord[UserId], var_rendercolor, Color);

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_COLOR_ACTION")), fmt("#%s", RENDERMENU_CMD));
    menu_additem(MenuId, fmt("%l", "MENUS_STEP", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));
    menu_additem(MenuId, Lang("MENU_COLOR_RPP"), fmt("$%s %.1f 0.0 0.0", COLOR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_COLOR_RMM"), fmt("$%s %.1f 0.0 0.0", COLOR_CMD, -gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_COLOR_GPP"), fmt("$%s 0.0 %.1f 0.0", COLOR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_COLOR_GMM"), fmt("$%s 0.0 %.1f 0.0", COLOR_CMD, -gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_COLOR_BPP"), fmt("$%s 0.0 0.0 %.1f", COLOR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_COLOR_BMM"), fmt("$%s 0.0 0.0 %.1f", COLOR_CMD, -gMoveStep[UserId]));
    menu_addtext(MenuId, fmt("%l", "MENU_COLOR_CURRENT_VALUE", Color[0], Color[1], Color[2]), 0);

    menu_addblank2(MenuId);
    menu_additem(MenuId, Lang("MENUS_BACK"), fmt("#%s", MAINMENU_CMD));

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_EXIT"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_ALL);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Color(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, COLORMENU_CMD);
}
