/**
 * [SprLett] Editor: Main menu
 */

#include <amxmodx>
#include <reapi>
#include <SprLetters>

Menu_Main(const UserId){
    new Word[WORD_MAX_LENGTH];
    if(SprLett_Is(gSelWord[UserId], SL_Is_Word))
        get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    else
        formatex(Word, charsmax(Word), Lang("MENUS_WORD_NOT_SELECTED"));
        
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Main");

    menu_additem(MenuId, Lang("MENU_MAIN_SELECT_WORD"), fmt("$%s", SELECT_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_CREATE_WORD"), fmt("#messagemode %s", CREATE_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_MOVE"), fmt("#%s", MOVEMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_ROT"), fmt("#%s", ROTATEMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_DIR"), fmt("#%s", DIRMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_COLOR"), fmt("#%s", COLORMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_RENDER"), fmt("#%s", RENDERMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_MARQUEE"), fmt("#%s", MARQUEEMENU_CMD));
    menu_additem(MenuId, Lang("MENU_MAIN_OTHER"), fmt("#%s", ATTRSMENU_CMD));

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_EXIT"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Main(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId, false))
        client_cmd(UserId, MAINMENU_CMD);
}
