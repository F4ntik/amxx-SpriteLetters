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
    else Word[0] = 0;
    
    new MenuId = menu_create(fmt("Редактирование слова^n\wСлово: \r%s", Word[0] ? Word : "\y*Не выбрано*"), "@MenuH_Main");

    menu_additem(MenuId, "Выбрать слово", fmt("$%s", SELECT_CMD));
    menu_additem(MenuId, "Создать слово^n", fmt("#messagemode %s", CREATE_CMD));

    menu_additem(MenuId, "Перемещение", fmt("#%s", MOVEMENU_CMD));
    menu_additem(MenuId, "Вращение", fmt("#%s", ROTATEMENU_CMD));
    menu_additem(MenuId, "Направление", fmt("#%s", DIRMENU_CMD));
    menu_additem(MenuId, "Прочее^n", fmt("#%s", ATTRSMENU_CMD));
    
    menu_addblank2(MenuId);
    menu_addblank2(MenuId);

    menu_setprop(MenuId, MPROP_EXITNAME, "Выход");
    menu_setprop(MenuId, MPROP_EXIT, MEXIT_FORCE);
    menu_setprop(MenuId, MPROP_PERPAGE, 0);

    menu_display(UserId, MenuId);
}

@MenuH_Main(const UserId, const MenuId, const ItemId){
    if(_CmdMenuHandle(UserId, MenuId, ItemId, false))
        client_cmd(UserId, MAINMENU_CMD);
}
