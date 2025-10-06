/**
 * [SprLett] Editor: Marquee menu
 */

#include <amxmodx>
#include <reapi>
#include <SprLetters>

Menu_Marquee(const UserId){
    new WordEnt = gSelWord[UserId];

    new Title[WORD_MAX_LENGTH];
    if(get_entvar(WordEnt, var_SL_MarqueeWidth) > 0){
        get_entvar(WordEnt, var_SL_MarqueeText, Title, charsmax(Title));
        if(!Title[0])
            get_entvar(WordEnt, var_SL_WordText, Title, charsmax(Title));
    } else {
        get_entvar(WordEnt, var_SL_WordText, Title, charsmax(Title));
    }
    if(!Title[0])
        formatex(Title, charsmax(Title), Lang("MENUS_WORD_NOT_SELECTED"));

    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Title), "@MenuH_Marquee");

    new marqueeId = get_entvar(WordEnt, var_SL_MarqueeID);
    new width = get_entvar(WordEnt, var_SL_MarqueeWidth);
    new Float:speed = get_entvar(WordEnt, var_SL_MarqueeSpeed);
    new status[32];
    copy(status, charsmax(status), width > 0 ? Lang("MENUS_ENABLED") : Lang("MENUS_DISABLED"));

    menu_additem(MenuId, fmt("%l", "MENU_MARQUEE_TOGGLE", status), fmt("$%s", MARQUEE_TOGGLE_CMD));
    menu_addtext(MenuId, fmt("%l", "MENU_MARQUEE_INFO", marqueeId, width, speed), 0);

    new FullText[WORD_MAX_LENGTH];
    get_entvar(WordEnt, var_SL_MarqueeText, FullText, charsmax(FullText));
    if(!FullText[0])
        get_entvar(WordEnt, var_SL_WordText, FullText, charsmax(FullText));

    new DisplayText[32];
    copy(DisplayText, charsmax(DisplayText), FullText);
    if(strlen(FullText) > charsmax(DisplayText)){
        copy(DisplayText, charsmax(DisplayText) - 3, FullText);
        add(DisplayText, charsmax(DisplayText), "...");
    }
    menu_addtext(MenuId, fmt("%l", "MENU_MARQUEE_TEXT", DisplayText[0] ? DisplayText : Lang("MENU_MARQUEE_TEXT_EMPTY")), 0);

    menu_addblank2(MenuId);
    menu_additem(MenuId, fmt("%l", "MENU_MARQUEE_SET_ID", marqueeId), fmt("#messagemode %s", MARQUEE_SETID_CMD));
    menu_additem(MenuId, fmt("%l", "MENU_MARQUEE_SET_WIDTH", width), fmt("#messagemode %s", MARQUEE_SETWIDTH_CMD));
    menu_additem(MenuId, fmt("%l", "MENU_MARQUEE_SET_SPEED", speed), fmt("#messagemode %s", MARQUEE_SETSPEED_CMD));
    menu_additem(MenuId, Lang("MENU_MARQUEE_SET_TEXT"), fmt("#messagemode %s", MARQUEE_SETTEXT_CMD));
    if(width > 0)
        menu_additem(MenuId, Lang("MENU_MARQUEE_RESET_OFFSET"), fmt("$%s", MARQUEE_RESET_OFFSET_CMD));

    menu_addblank2(MenuId);
    menu_additem(MenuId, Lang("MENUS_BACK"), fmt("#%s", MAINMENU_CMD));

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_EXIT"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_ALL);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Marquee(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, MARQUEEMENU_CMD);
}
