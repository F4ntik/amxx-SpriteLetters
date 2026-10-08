/**
 * [SprLett] Editor: Color menu
 */

#include <amxmodx>
#include <reapi>

Menu_ColorFine(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("%l", "MENUS_TITLE", Word), "@MenuH_ColorFine");

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

    menu_setprop(MenuId, MPROP_EXITNAME, Lang("MENUS_BACK"));
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_ColorFine(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, "slcolorfinemenu");
}


Menu_Color(const UserId){
    new MenuId = menu_create("Цвет надписи", "@MenuH_Color");
    menu_additem(MenuId, "Белый", "$slcolorpreset 0");
    menu_additem(MenuId, "Жёлтый", "$slcolorpreset 1");
    menu_additem(MenuId, "Зелёный", "$slcolorpreset 2");
    menu_additem(MenuId, "Голубой", "$slcolorpreset 3");
    menu_additem(MenuId, "Красный", "$slcolorpreset 4");
    menu_additem(MenuId, "Точная настройка RGB", "#slcolorfinemenu");
    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_display(UserId, MenuId);
}
@MenuH_Color(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId)) Menu_Color(UserId);
}
@Cmd_ColorFine(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_ColorFine(UserId);
}
@Cmd_ColorPreset(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)
    new const Float:Colors[5][3] = {{255.0,255.0,255.0},{255.0,215.0,70.0},{105.0,235.0,125.0},{100.0,200.0,255.0},{255.0,100.0,90.0}};
    new Index = read_argv_int(NULL_ARG+1);
    if(Index < 0 || Index >= sizeof Colors) return;
    new Float:Previous[3];
    get_entvar(gSelWord[UserId], var_rendercolor, Previous);
    set_entvar(gSelWord[UserId], var_rendercolor, Colors[Index]);
    if(!SprLett_RebuildWord(gSelWord[UserId])){
        set_entvar(gSelWord[UserId], var_rendercolor, Previous);
        ReportBuildError(UserId);
    }
}
