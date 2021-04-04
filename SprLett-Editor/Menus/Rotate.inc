/**
 * [SprLett] Editor: Rotate menu
 */

#include <amxmodx>
#include <reapi>

Menu_Rotate(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("Редактирование слова^n\wСлово: \r%s", Word), "@MenuH_Rotate");

    new Float:Angles[3];
    get_entvar(gSelWord[UserId], var_angles, Angles);

    menu_additem(MenuId, "Действие: \yВращение", fmt("#%s", DIRMENU_CMD));

    menu_additem(MenuId, fmt("Шаг: \r%.1f^n", gMoveStep[UserId]), fmt("$%s", STEPEX_CMD));

    menu_additem(MenuId, "X\y++", fmt("$%s %.1f 0.0 0.0", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "X\r--", fmt("$%s %.1f 0.0 0.0", ROTATE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, "Y\y++", fmt("$%s 0.0 %.1f 0.0", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Y\r--", fmt("$%s 0.0 %.1f 0.0", ROTATE_CMD, -gMoveStep[UserId]));

    menu_additem(MenuId, "Z\y++", fmt("$%s 0.0 0.0 %.1f", ROTATE_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Z\r--^n", fmt("$%s 0.0 0.0 %.1f", ROTATE_CMD, -gMoveStep[UserId]));
    
    menu_addtext(MenuId, fmt("\yТекущее значение: \r%.1f %.1f %.1f", Angles[0], Angles[1], Angles[2]), 0);

    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Rotate(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, ROTATEMENU_CMD);
}
