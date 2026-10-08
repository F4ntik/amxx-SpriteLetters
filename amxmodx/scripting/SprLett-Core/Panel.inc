/** A sign is a word plus bounded, reusable oriented sprite sections. */
#define PANEL_LIMIT 32
#define PANEL_PART_LIMIT 64
#define PANEL_ENTITY_RESERVE 64
new const PANEL_MODEL[] = "sprites/SprLett/panel.spr";
new const PANEL_CLASS[] = "sprlett_panel";
new gPanelModel;
new const PANEL_MDL_MODELS[][] = {
    "models/SprLett/panel_bg_a.mdl", "models/SprLett/panel_bg_b.mdl",
    "models/SprLett/panel_edges.mdl", "models/SprLett/panel_corners.mdl"
};
new gPanelMdlIndices[4];
new bool:gPanelMdlReady;
new gPanelWord[PANEL_LIMIT];
new gPanelWidth[PANEL_LIMIT], gPanelHeight[PANEL_LIMIT], gPanelStyle[PANEL_LIMIT];
new gPanelCount[PANEL_LIMIT], gPanelParts[PANEL_LIMIT][PANEL_PART_LIMIT];

PanelPrecache(){
    if(file_exists(PANEL_MODEL))
        gPanelModel = precache_model(PANEL_MODEL);
    else
        log_amx("[WARNING] Optional panel sprite missing: %s", PANEL_MODEL);
    gPanelMdlReady = true;
    for(new i; i < sizeof(PANEL_MDL_MODELS); i++){
        if(!file_exists(PANEL_MDL_MODELS[i])){
            gPanelMdlReady = false;
            log_amx("[WARNING] Optional panel model missing: %s", PANEL_MDL_MODELS[i]);
        }
    }
    if(gPanelMdlReady)
        for(new i; i < sizeof(PANEL_MDL_MODELS); i++)
            gPanelMdlIndices[i] = precache_model(PANEL_MDL_MODELS[i]);
}

PanelSlot(const WordEnt){
    for(new i; i < PANEL_LIMIT; i++)
        if(gPanelWord[i] == WordEnt) return i;
    return -1;
}

bool:PanelPartIs(const Ent, const WordEnt){
    if(is_nullent(Ent) || get_entvar(Ent, var_flags) & FL_KILLME) return false;
    new Class[32];
    get_entvar(Ent, var_classname, Class, charsmax(Class));
    return equal(Class, PANEL_CLASS) && get_entvar(Ent, var_owner) == WordEnt;
}

PanelRemove(const WordEnt){
    new Slot = PanelSlot(WordEnt);
    if(Slot < 0) return;
    for(new i; i < gPanelCount[Slot]; i++){
        if(PanelPartIs(gPanelParts[Slot][i], WordEnt))
            engfunc(EngFunc_RemoveEntity, gPanelParts[Slot][i]);
        gPanelParts[Slot][i] = 0;
    }
    gPanelCount[Slot] = 0;
    gPanelWord[Slot] = 0;
}

// Rectangles use integer map units, in multiples of four. Each sprite frame is
// (2^W x 2^H); binary decomposition needs at most 64 pieces for a whole panel.
PanelRect(const X, const Y, const W, const H, const Edge,
          Parts[][5], &Count){
    new XPos = X;
    for(new wx = 9; wx >= 1; wx--){
        if(!(W & (1 << wx))) continue;
        new YPos = Y;
        for(new hy = 7; hy >= 1; hy--){
            if(!(H & (1 << hy))) continue;
            if(Count >= PANEL_PART_LIMIT) return false;
            Parts[Count][0] = (wx - 1) * 7 + hy - 1;
            Parts[Count][1] = XPos + (1 << wx) / 2;
            Parts[Count][2] = YPos + (1 << hy) / 2;
            Parts[Count][3] = Edge;
            Parts[Count][4] = 0;
            Count++;
            YPos += 1 << hy;
        }
        XPos += 1 << wx;
    }
    return true;
}

bool:PanelSet(const WordEnt, const Width, const Height, const Style){
    if(!IsWord(WordEnt)) return false;
    if(!Width){ PanelRemove(WordEnt); return true; }
    if(Width < 32 || Width > 512 || Height < 16 || Height > 128
       || Width % 4 || Height % 4 || Style < 0 || Style > 3) return false;
    new bool:IsMdl = Style == 3;
    if(IsMdl ? !gPanelMdlReady : !gPanelModel) return false;
    if(get_entvar(WordEnt, var_SL_RotateMode) != SL_ROTATE_WORD) return false;

    new Slot = PanelSlot(WordEnt);
    if(Slot < 0){
        for(new i; i < PANEL_LIMIT; i++){
            if(!gPanelWord[i]){ Slot = i; break; }
        }
    }
    if(Slot < 0) return false;

    new Parts[PANEL_PART_LIMIT][5], Count;
    if(IsMdl){
        if(!PanelRect(4, 4, Width-8, Height-8, 0, Parts, Count)
           || !PanelRect(4, 0, Width-8, 4, 1, Parts, Count)
           || !PanelRect(4, Height-4, Width-8, 4, 2, Parts, Count)
           || !PanelRect(0, 4, 4, Height-8, 3, Parts, Count)
           || !PanelRect(Width-4, 4, 4, Height-8, 4, Parts, Count)) return false;
        if(Count + 4 > PANEL_PART_LIMIT) return false;
        for(new Corner; Corner < 4; Corner++){
            Parts[Count][0] = Corner;
            Parts[Count][1] = (Corner % 2) ? Width-2 : 2;
            Parts[Count][2] = (Corner / 2) ? Height-2 : 2;
            Parts[Count][3] = 5;
            Count++;
        }
    } else {
        if(!PanelRect(2, 2, Width-4, Height-4, 0, Parts, Count)
           || !PanelRect(0, 0, Width, 2, 1, Parts, Count)
           || !PanelRect(0, Height-2, Width, 2, 1, Parts, Count)
           || !PanelRect(0, 2, 2, Height-4, 1, Parts, Count)
           || !PanelRect(Width-2, 2, 2, Height-4, 1, Parts, Count)) return false;
    }

    new Needed;
    for(new i; i < Count; i++)
        if(!PanelPartIs(gPanelParts[Slot][i], WordEnt)) Needed++;
    if(Needed && global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities)
       < Needed + PANEL_ENTITY_RESERVE) return false;

    // Allocate all missing pieces before changing the current panel.
    new Added[PANEL_PART_LIMIT], AddedCount;
    for(new i; i < Count; i++){
        if(PanelPartIs(gPanelParts[Slot][i], WordEnt)) continue;
        new Ent = rg_create_entity(INFO_TARGET_CLASSNAME);
        if(is_nullent(Ent)){
            for(new a; a < AddedCount; a++){
                engfunc(EngFunc_RemoveEntity, gPanelParts[Slot][Added[a]]);
                gPanelParts[Slot][Added[a]] = 0;
            }
            return false;
        }
        gPanelParts[Slot][i] = Ent;
        Added[AddedCount++] = i;
        set_entvar(Ent, var_classname, PANEL_CLASS);
        set_entvar(Ent, var_owner, WordEnt);
        set_entvar(Ent, var_solid, SOLID_NOT);
        set_entvar(Ent, var_movetype, MOVETYPE_NONE);
        set_entvar(Ent, var_scale, 1.0);
        set_entvar(Ent, var_renderamt, 255.0);
    }

    new Float:Origin[3], Float:Angles[3], Float:Right[3], Float:Up[3], Float:Forward[3];
    get_entvar(WordEnt, var_origin, Origin);
    get_entvar(WordEnt, var_angles, Angles);
    angle_vector(Angles, ANGLEVECTOR_RIGHT, Right);
    angle_vector(Angles, ANGLEVECTOR_UP, Up);
    angle_vector(Angles, ANGLEVECTOR_FORWARD, Forward);
    new Cells = get_entvar(WordEnt, var_MarqueeWidth);
    if(Cells <= 0){
        new Text[WORD_MAX_LENGTH], Char[LETTER_SIZE], Next;
        get_entvar(WordEnt, var_WordText, Text, charsmax(Text));
        while(GetLetterFromStr(Text, Char, Next)) Cells++;
    }
    new Float:Center = float(max(0, Cells-1)) * Float:get_entvar(WordEnt, var_WordOffset) * 0.5;
    new const Float:BackColors[3][3] = {{20.0,24.0,32.0},{18.0,38.0,58.0},{42.0,30.0,20.0}};
    new const Float:EdgeColors[3][3] = {{155.0,165.0,175.0},{60.0,170.0,235.0},{215.0,167.0,92.0}};
    for(new i; i < Count; i++){
        new Ent = gPanelParts[Slot][i];
        new Float:Pos[3];
        for(new a; a < 3; a++)
            Pos[a] = Origin[a] + Right[a] * (Center + float(Parts[i][1]) - float(Width)*0.5)
                   + Up[a] * (float(Parts[i][2]) - float(Height)*0.5) - Forward[a]*2.0;
        engfunc(EngFunc_SetOrigin, Ent, Pos);
        set_entvar(Ent, var_angles, Angles);
        if(IsMdl){
            new Frame = Parts[i][0], Zone = Parts[i][3], Model, Body;
            if(!Zone){ Model = Frame / 32; Body = Frame % 32; }
            else if(Zone == 5){ Model = 3; Body = Frame; }
            else {
                Model = 2;
                if(Zone <= 2) Body = (Zone-1)*9 + Frame/7;
                else Body = 18 + (Zone-3)*7 + Frame%7;
            }
            if(get_entvar(Ent, var_modelindex) != gPanelMdlIndices[Model])
                engfunc(EngFunc_SetModel, Ent, PANEL_MDL_MODELS[Model]);
            set_entvar(Ent, var_body, Body);
            set_entvar(Ent, var_sequence, 0);
            set_entvar(Ent, var_frame, 0.0);
            set_entvar(Ent, var_framerate, 0.0);
            set_entvar(Ent, var_skin, 0);
            set_entvar(Ent, var_rendermode, kRenderNormal);
            set_entvar(Ent, var_rendercolor, Float:{255.0,255.0,255.0});
        } else {
            if(get_entvar(Ent, var_modelindex) != gPanelModel)
                engfunc(EngFunc_SetModel, Ent, PANEL_MODEL);
            set_entvar(Ent, var_body, 0);
            set_entvar(Ent, var_frame, float(Parts[i][0]));
            set_entvar(Ent, var_rendermode, kRenderTransTexture);
            if(Parts[i][3]) set_entvar(Ent, var_rendercolor, EdgeColors[Style]);
            else set_entvar(Ent, var_rendercolor, BackColors[Style]);
        }
    }
    for(new i = Count; i < gPanelCount[Slot]; i++){
        if(PanelPartIs(gPanelParts[Slot][i], WordEnt))
            engfunc(EngFunc_RemoveEntity, gPanelParts[Slot][i]);
        gPanelParts[Slot][i] = 0;
    }
    gPanelWord[Slot] = WordEnt;
    gPanelCount[Slot] = Count;
    gPanelWidth[Slot] = Width;
    gPanelHeight[Slot] = Height;
    gPanelStyle[Slot] = Style;
    return true;
}

PanelRefresh(const WordEnt){
    new Slot = PanelSlot(WordEnt);
    if(Slot >= 0) PanelSet(WordEnt, gPanelWidth[Slot], gPanelHeight[Slot], gPanelStyle[Slot]);
}

bool:@_SetPanel(){
    return PanelSet(get_param(1), get_param(2), get_param(3), get_param(4));
}

bool:@_GetPanel(){
    new Slot = PanelSlot(get_param(1));
    set_param_byref(2, Slot < 0 ? 0 : gPanelWidth[Slot]);
    set_param_byref(3, Slot < 0 ? 0 : gPanelHeight[Slot]);
    set_param_byref(4, Slot < 0 ? 0 : gPanelStyle[Slot]);
    return Slot >= 0;
}
