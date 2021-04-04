/**
 * [SprLett] Editor: Attributes menu
 */

#include <amxmodx>
#include <reapi>

Menu_Attrs(const UserId){
    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    
    new MenuId = menu_create(fmt("Редактирование слова^n\wСлово: \r%s", Word), "@MenuH_Attrs");

    menu_additem(MenuId, "Действие: \yПрочее^n", fmt("#%s", MOVEMENU_CMD));

    new Float:Offset = get_entvar(gSelWord[UserId], var_SL_WordOffset);
    menu_addtext(MenuId, fmt("Текущий отступ: \r%.1f", Offset), 0);
    menu_additem(MenuId, "Отступ\y++", fmt("$%s %.1f", OFFSET_CMD, gMoveStep[UserId]));
    menu_additem(MenuId, "Отступ\r--^n", fmt("$%s %.1f", OFFSET_CMD, -gMoveStep[UserId]));

    new CharsetName[32];
    get_entvar(gSelWord[UserId], var_SL_WordCharset, CharsetName, charsmax(CharsetName));
    menu_additem(MenuId, fmt("Символы [\y%s\w]", CharsetName), fmt("#messagemode %s", CHARSET_CMD));
    menu_additem(MenuId, "Изменить слово", fmt("#messagemode %s", WRITE_CMD));
    menu_additem(MenuId, "Сохранить слово^n", fmt("$%s", SAVE_CMD));
    menu_additem(MenuId, "Удалить слово", fmt("#%s", REMOVE_CMD));
    
    menu_addblank2(MenuId);

    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Attrs(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId))
        client_cmd(UserId, ATTRSMENU_CMD);
}
