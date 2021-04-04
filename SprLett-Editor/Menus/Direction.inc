/**
 * [SprLett] Editor: Direction menu
 */

#include <amxmodx>
#include <reapi>

Menu_Direction(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("Редактирование слова^n\wСлово: \r%s", Word), "@MenuH_Direction");

    new Float:Dir[3];
    get_entvar(gSelWord[UserId], var_SL_WordDir, Dir);

    menu_additem(MenuId, "Действие: \yНаправление", fmt("#%s", ATTRSMENU_CMD));

    menu_additem(MenuId, fmt("Шаг: \r%.1f^n", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));

    menu_additem(MenuId, "Верт\y++", fmt("$%s %.1f 0.0", DIR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Верт\r--", fmt("$%s %.1f 0.0", DIR_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, "Гор\y++", fmt("$%s 0.0 %.1f", DIR_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Гор\r--", fmt("$%s 0.0 %.1f", DIR_CMD, -gMoveStep[UserId]));
    
    menu_addtext(MenuId, fmt("\yТекущее значение: \r%.1f %.1f", Dir[0], Dir[1]), 0);

    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Direction(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, DIRMENU_CMD);
}
