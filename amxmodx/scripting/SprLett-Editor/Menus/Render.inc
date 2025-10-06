/**
 * [SprLett] Editor: Render menu
 */

#include <amxmodx>
#include <reapi>
RenderModeLabel(const Mode, Dest[], const Len){
    static const Labels[][] = {
        "Normal",
        "TransColor",
        "TransTexture",
        "Glow",
        "TransAlpha",
        "TransAdd"
    };
    if(Mode < 0 || Mode >= sizeof Labels){
        copy(Dest, Len, "Unknown");
        return;
    }
    copy(Dest, Len, Labels[Mode]);
}



Menu_Render(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_Render");

    menu_additem(MenuId, fmt("%l", "MENUS_ACTION", Lang("MENU_RENDER_ACTION")), fmt("#%s", ATTRSMENU_CMD));
    menu_additem(MenuId, fmt("%l", "MENUS_STEP", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));

    new Mode = get_entvar(gSelWord[UserId], var_rendermode);
    new ModeName[16];
    RenderModeLabel(Mode, ModeName, charsmax(ModeName));
    menu_additem(MenuId, fmt("%l", "MENU_RENDER_MODE", ModeName, Mode), fmt("$%s", RENDER_TYPE_EX_CMD));
    
    new Float:Alpha = get_entvar(gSelWord[UserId], var_renderamt);
    menu_additem(MenuId, Lang("MENU_RENDER_ALPHAPP"), fmt("$%s %.1f", ALPHA_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, Lang("MENU_RENDER_ALPHAMM"), fmt("$%s %.1f", ALPHA_CMD, -gMoveStep[UserId]));
    menu_addtext(MenuId, fmt("%l", "MENU_RENDER_CURRENT_ALPHA", Alpha), 0);

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Render(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, RENDERMENU_CMD);
}


