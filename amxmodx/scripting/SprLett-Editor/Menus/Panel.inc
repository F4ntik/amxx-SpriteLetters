Menu_Panel(const UserId){
    new W, H, Style;
    new bool:Enabled = SprLett_GetPanel(gSelWord[UserId], W, H, Style);
    new MenuId = menu_create(fmt("Табличка: рамка и фон^n\\w%s", Enabled ? fmt("%d x %d", W, H) : "Без рамки"), "@MenuH_Panel");
    menu_additem(MenuId, Enabled ? "Убрать рамку" : "Добавить рамку по тексту", "toggle");
    menu_additem(MenuId, "Подогнать рамку под текст", "fit");
    menu_additem(MenuId, "Шире на 4", "wide");
    menu_additem(MenuId, "Уже на 4", "narrow");
    menu_additem(MenuId, "Выше на 4", "tall");
    menu_additem(MenuId, "Ниже на 4", "short");
    new const Styles[][] = {"Спрайт: графит", "Спрайт: синий", "Спрайт: бронза", "Объёмная MDL (пробная)"};
    menu_additem(MenuId, fmt("Оформление: %s", Styles[Style]), "style");
    menu_setprop(MenuId, MPROP_EXITNAME, "Назад");
    menu_display(UserId, MenuId);
}

PanelFit(const WordEnt, &W, &H){
    new Text[WORD_MAX_LENGTH];
    get_entvar(WordEnt, var_SL_MarqueeText, Text, charsmax(Text));
    new Cells = get_entvar(WordEnt, var_SL_MarqueeWidth);
    if(!Cells){
        for(new i; Text[i]; i++)
            if((Text[i] & 0xC0) != 0x80) Cells++;
    }
    new Float:Glyph = floatmax(32.0*Float:get_entvar(WordEnt, var_scale), Float:get_entvar(WordEnt, var_SL_LetterSize)*2.0);
    W = clamp(floatround((float(max(0, Cells-1))*floatabs(Float:get_entvar(WordEnt, var_SL_WordOffset))+Glyph+12.0)/4.0, floatround_ceil)*4, 32, 512);
    H = clamp(floatround((Glyph+12.0)/4.0, floatround_ceil)*4, 16, 128);
}

@MenuH_Panel(const UserId, const MenuId, const ItemId){
    if(ItemId < 0){ menu_destroy(MenuId); Menu_Main(UserId); return; }
    new Data[16];
    menu_item_getinfo(MenuId, ItemId, _, Data, charsmax(Data));
    menu_destroy(MenuId);
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    new Ent = gSelWord[UserId], W, H, Style;
    new bool:Enabled = SprLett_GetPanel(Ent, W, H, Style);
    if(!Enabled) PanelFit(Ent, W, H);
    if(equal(Data, "toggle") && Enabled) W = 0;
    else if(equal(Data, "fit")) PanelFit(Ent, W, H);
    else if(equal(Data, "wide")) W = min(512, W+4);
    else if(equal(Data, "narrow")) W = max(32, W-4);
    else if(equal(Data, "tall")) H = min(128, H+4);
    else if(equal(Data, "short")) H = max(16, H-4);
    else if(equal(Data, "style")) Style = (Style+1)%4;
    if(!SprLett_SetPanel(Ent, W, H, Style))
        client_print(UserId, print_chat, "[Табличка] Рамка не изменена: проверьте ресурсы рамки, свободные объекты и режим вращения слова.");
    Menu_Panel(UserId);
}

@Cmd_PanelMenu(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    Menu_Panel(UserId);
}

@Cmd_Panel(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 2)
    CHECK_WORD(UserId)
    new W, H, Style;
    SprLett_GetPanel(gSelWord[UserId], W, H, Style);
    if(read_argc() > NULL_ARG+3) Style = read_argv_int(NULL_ARG+3);
    if(!SprLett_SetPanel(gSelWord[UserId], read_argv_int(NULL_ARG+1), read_argv_int(NULL_ARG+2), Style))
        client_print(UserId, print_chat, "[Табличка] Размер: ширина 32–512, высота 16–128, шаг 4. Ширина 0 убирает рамку.");
    Menu_Panel(UserId);
}

// One bounded ray per click. A stable placement avoids an endless preview loop.
@Cmd_Place(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)
    if(!is_user_alive(UserId)) return;
    new Float:Start[3], Float:View[3], Float:End[3], Float:Normal[3], Float:Angles[3];
    get_entvar(UserId, var_origin, Start);
    get_entvar(UserId, var_view_ofs, View);
    for(new i; i < 3; i++) Start[i] += View[i];
    get_entvar(UserId, var_v_angle, Angles);
    angle_vector(Angles, ANGLEVECTOR_FORWARD, View);
    for(new i; i < 3; i++) End[i] = Start[i]+View[i]*2048.0;
    new Trace = create_tr2();
    engfunc(EngFunc_TraceLine, Start, End, IGNORE_MONSTERS, UserId, Trace);
    new Float:Fraction;
    get_tr2(Trace, TR_flFraction, Fraction);
    new bool:Valid = !get_tr2(Trace, TR_StartSolid) && !get_tr2(Trace, TR_AllSolid)
                  && Fraction > 0.001 && Fraction < 1.0 && get_tr2(Trace, TR_pHit) == 0;
    get_tr2(Trace, TR_vecEndPos, End);
    get_tr2(Trace, TR_vecPlaneNormal, Normal);
    free_tr2(Trace);
    if(!Valid || vector_length(Normal) < 0.9){
        client_print(UserId, print_chat, "[Табличка] Наведите прицел на неподвижную стену, пол или потолок.");
        Menu_Main(UserId);
        return;
    }
    vector_to_angle(Normal, Angles);
    Angles[0] = -Angles[0];
    for(new i; i < 3; i++) End[i] += Normal[i]*4.0;
    new Ent = gSelWord[UserId], Float:OldOrigin[3], Float:OldAngles[3], OldMode;
    get_entvar(Ent, var_origin, OldOrigin);
    get_entvar(Ent, var_angles, OldAngles);
    OldMode = get_entvar(Ent, var_SL_RotateMode);
    set_entvar(Ent, var_origin, End);
    set_entvar(Ent, var_angles, Angles);
    set_entvar(Ent, var_SL_RotateMode, SL_ROTATE_WORD);
    SyncWordDirWithAngles(Ent);
    if(!SprLett_BuildWord(Ent)){
        set_entvar(Ent, var_origin, OldOrigin);
        set_entvar(Ent, var_angles, OldAngles);
        set_entvar(Ent, var_SL_RotateMode, OldMode);
        SyncWordDirWithAngles(Ent);
        client_print(UserId, print_chat, "[Табличка] Недостаточно свободных объектов. Положение сохранено.");
    }
    Menu_Main(UserId);
}
