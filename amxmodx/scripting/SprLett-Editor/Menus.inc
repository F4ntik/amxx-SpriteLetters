new const MAINMENU_CMD[] = "slmainmenu";
new const MOVEMENU_CMD[] = "slmovemenu";
new const ROTATEMENU_CMD[] = "slrotatemenu";
new const ATTRSMENU_CMD[] = "slattrsmenu";
new const DIRMENU_CMD[] = "sldirmenu";
new const RENDERMENU_CMD[] = "slrendermenu";
new const COLORMENU_CMD[] = "slcolormenu";
new const MARQUEEMENU_CMD[] = "slmarqueemenu";

MenuCmds_Init(){
    RegisterClCmds(MAINMENU_CMD, "@Cmd_MainMenu");

    RegisterClCmds(MOVEMENU_CMD, "@Cmd_MoveMenu");
    RegisterClCmds(ROTATEMENU_CMD, "@Cmd_RotateMenu");
    RegisterClCmds(DIRMENU_CMD, "@Cmd_DirMenu");
    RegisterClCmds(ATTRSMENU_CMD, "@Cmd_AttrsMenu");
    RegisterClCmds(RENDERMENU_CMD, "@Cmd_RenderMenu");
    RegisterClCmds(COLORMENU_CMD, "@Cmd_ColorMenu");
    RegisterClCmds(MARQUEEMENU_CMD, "@Cmd_MarqueeMenu");
}

@Cmd_MainMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    Menu_Main(UserId);
}

@Cmd_MoveMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Move(UserId);
}

@Cmd_RotateMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Rotate(UserId);
}

@Cmd_DirMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Direction(UserId);
}

@Cmd_AttrsMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Attrs(UserId);
}

@Cmd_RenderMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Render(UserId);
}

@Cmd_ColorMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Color(UserId);
}

@Cmd_MarqueeMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Marquee(UserId);
}

bool:_CmdMenuHandle(const UserId, const MenuId, const ItemId){
    if(ItemId == MENU_EXIT){
        menu_destroy(MenuId);
        return false;
    }

    new Data[32];
    menu_item_getinfo(MenuId, ItemId, _, Data, charsmax(Data));
    client_cmd(UserId, Data[1]);
    menu_destroy(MenuId);

    return (Data[0] == '$');
}

#include "SprLett-Editor/Menus/Main"
#include "SprLett-Editor/Menus/Move"
#include "SprLett-Editor/Menus/Rotate"
#include "SprLett-Editor/Menus/Direction"
#include "SprLett-Editor/Menus/Marquee"
#include "SprLett-Editor/Menus/Color"
#include "SprLett-Editor/Menus/Render"
#include "SprLett-Editor/Menus/Attrs"
