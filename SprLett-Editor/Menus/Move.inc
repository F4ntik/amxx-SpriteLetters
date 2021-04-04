/**
 * [SprLett] Editor: Move menu
 */

#include <amxmodx>
#include <reapi>

Menu_Move(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("Редактирование слова^n\wСлово: \r%s", Word), "@MenuH_Move");

    new Float:Origin[3];
    get_entvar(gSelWord[UserId], var_origin, Origin);

    menu_additem(MenuId, "Действие: \yПеремещение", fmt("#%s", ROTATEMENU_CMD));

    menu_additem(MenuId, fmt("Шаг: \r%.1f^n", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));

    menu_additem(MenuId, "X\y++", fmt("$%s %.1f 0.0 0.0", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "X\r--", fmt("$%s %.1f 0.0 0.0", MOVE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, "Y\y++", fmt("$%s 0.0 %.1f 0.0", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Y\r--", fmt("$%s 0.0 %.1f 0.0", MOVE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, "Z\y++", fmt("$%s 0.0 0.0 %.1f", MOVE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Z\r--^n", fmt("$%s 0.0 0.0 %.1f^n", MOVE_CMD, -gMoveStep[UserId]));
    
    menu_addtext(MenuId, fmt("\yТекущее значение: \r%.1f %.1f %.1f", Origin[0], Origin[1], Origin[2]), 0);

    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Move(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, MOVEMENU_CMD);
}
