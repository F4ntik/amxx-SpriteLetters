/**
 * [SprLett] Editor: Rotate menu
 */

#include <amxmodx>
#include <reapi>

Menu_Rotate(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Rotate");

    new Float:Angles[3];
    get_entvar(gSelWord[UserId], var_angles, Angles);

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_ROT_ACTION")), fmt("#%s", DIRMENU_CMD));

    menu_additem(MenuId, fmt("%l", "MENUS_STEP", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));

    menu_additem(MenuId, Lang("MENU_ROT_XPP"), fmt("$%s %.1f 0.0 0.0", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_ROT_XMM"), fmt("$%s %.1f 0.0 0.0", ROTATE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, Lang("MENU_ROT_YPP"), fmt("$%s 0.0 %.1f 0.0", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_ROT_YMM"), fmt("$%s 0.0 %.1f 0.0", ROTATE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, Lang("MENU_ROT_ZPP"), fmt("$%s 0.0 0.0 %.1f", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_ROT_ZMM"), fmt("$%s 0.0 0.0 %.1f", ROTATE_CMD, -gMoveStep[UserId]));
    
    menu_addtext(MenuId, fmt("%l", "MENU_ROT_CURRENT_VALUE", Angles[0], Angles[1], Angles[2]), 0);
    
    menu_addblank2(MenuId);

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Rotate(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, ROTATEMENU_CMD);
}
