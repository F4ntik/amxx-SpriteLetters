/**
 * [SprLett] Editor
 */

#include <amxmodx>
#include <reapi>
#include <vector>
#include <SprLetters>
#include "SprLett-Core/Ver"

#pragma semicolon 1

#define nullent 0

#define EDIT_ACCESS ADMIN_RCON
new const MOVESTEP_VALUES[] = {1, 5, 10, 25, 50};

new const SELECT_CMD[] = "slselect";
new const CREATE_CMD[] = "slcreate";
new const EDITMODE_CMD[] = "sleditmode";

new const STEP_CMD[] = "slsetstep";
new const STEPEX_CMD[] = "slsetstepex";

new const MOVE_CMD[] = "slmove";
new const ROTATE_CMD[] = "slrotate";
new const ROTATE_MODE_CMD[] = "slrotatemode";
new const DIR_CMD[] = "sldir";

new const CHARSET_CMD[] = "slcharset";
new const OFFSET_CMD[] = "sloffset";
new const WRITE_CMD[] = "slwrite";
new const REMOVE_CMD[] = "slremove";
new const SAVE_CMD[] = "slsave";

new const RENDER_TYPE_CMD[] = "slrendtype";
new const RENDER_TYPE_EX_CMD[] = "slrendtypeex";
new const ALPHA_CMD[] = "slalpha";
new const COLOR_CMD[] = "slcolor";

new const MARQUEE_MENU_CMD[] = "slmarqueemenu";
new const MARQUEE_TOGGLE_CMD[] = "slmarqueetoggle";
new const MARQUEE_SETID_CMD[] = "slmarqueeid";
new const MARQUEE_SETWIDTH_CMD[] = "slmarqueewidth";
new const MARQUEE_SETSPEED_CMD[] = "slmarqueespeed";
new const MARQUEE_SETTEXT_CMD[] = "slmarqueetext";
new const MARQUEE_RESET_OFFSET_CMD[] = "slmarqueeoffset";

const DEFAULT_MARQUEE_WIDTH = 10;
const Float:DEFAULT_MARQUEE_SPEED = 5.0;

new const PLUG_NAME[] = "[SprLett] Editor";
#define PLUG_VER SPRLETT_VERSION

new gSelWord[MAX_PLAYERS + 1] = {nullent, ...};
new Float:gMoveStep[MAX_PLAYERS + 1] = {1.0, ...};

SyncWordDirWithAngles(const WordEnt){
    if(!SprLett_Is(WordEnt, SL_Is_Word))
        return;

    new Float:Angles[3];
    get_entvar(WordEnt, var_angles, Angles);

    new Float:Right[3];
    angle_vector(Angles, ANGLEVECTOR_RIGHT, Right);

    new Float:DirAngles[3];
    vector_to_angle(Right, DirAngles);
    set_entvar(WordEnt, var_SL_WordDir, DirAngles);
}


#include "SprLett-Editor/Utils"
#include "SprLett-Editor/Menus"

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
    register_dictionary("SpriteLetters.ini");

    RegisterClCmds(CREATE_CMD, "@Cmd_Create");
    RegisterClCmds(SELECT_CMD, "@Cmd_Select");
    RegisterClCmds(EDITMODE_CMD, "@Cmd_EditMode");

    RegisterClCmds(STEP_CMD, "@Cmd_SetStep");
    RegisterClCmds(STEPEX_CMD, "@Cmd_SetStepEx");

    RegisterClCmds(MOVE_CMD, "@Cmd_Move");
    RegisterClCmds(ROTATE_CMD, "@Cmd_Rotate");
    RegisterClCmds(ROTATE_MODE_CMD, "@Cmd_RotateMode");
    RegisterClCmds(DIR_CMD, "@Cmd_Dir");

    RegisterClCmds(CHARSET_CMD, "@Cmd_Charset");
    RegisterClCmds(OFFSET_CMD, "@Cmd_Offset");
    RegisterClCmds(WRITE_CMD, "@Cmd_Write");
    RegisterClCmds(REMOVE_CMD, "@Cmd_Remove");
    RegisterClCmds(SAVE_CMD, "@Cmd_Save");

    RegisterClCmds(RENDER_TYPE_CMD, "@Cmd_RenderType");
    RegisterClCmds(RENDER_TYPE_EX_CMD, "@Cmd_RenderTypeEx");
    RegisterClCmds(ALPHA_CMD, "@Cmd_Alpha");
    RegisterClCmds(COLOR_CMD, "@Cmd_Color");
    RegisterClCmds(MARQUEE_MENU_CMD, "@Cmd_MarqueeMenu");
    RegisterClCmds(MARQUEE_TOGGLE_CMD, "@Cmd_MarqueeToggle");
    RegisterClCmds(MARQUEE_SETID_CMD, "@Cmd_MarqueeSetId");
    RegisterClCmds(MARQUEE_SETWIDTH_CMD, "@Cmd_MarqueeSetWidth");
    RegisterClCmds(MARQUEE_SETSPEED_CMD, "@Cmd_MarqueeSetSpeed");
    RegisterClCmds(MARQUEE_SETTEXT_CMD, "@Cmd_MarqueeSetText");
    RegisterClCmds(MARQUEE_RESET_OFFSET_CMD, "@Cmd_MarqueeResetOffset");

    MenuCmds_Init();
}

@Cmd_Color(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 3)
    CHECK_WORD(UserId)

    new Float:Color[3];
    get_entvar(gSelWord[UserId], var_rendercolor, Color);
    Color[0] = floatclamp(Color[0] + read_argv_float(NULL_ARG+1), 0.0, 255.0);
    Color[1] = floatclamp(Color[1] + read_argv_float(NULL_ARG+2), 0.0, 255.0);
    Color[2] = floatclamp(Color[2] + read_argv_float(NULL_ARG+3), 0.0, 255.0);
    set_entvar(gSelWord[UserId], var_rendercolor, Color);

    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_RenderType(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)
    
    set_entvar(gSelWord[UserId], var_rendermode, clamp(read_argv_int(NULL_ARG+1), kRenderNormal, kRenderTransAdd));

    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_RenderTypeEx(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    new RendType = get_entvar(gSelWord[UserId], var_rendermode);
    RendType++;
    if(RendType > kRenderTransAdd)
        RendType = kRenderNormal;

    client_cmd(UserId, fmt("%s %d", RENDER_TYPE_CMD, RendType));
}

@Cmd_Alpha(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new Float:Alpha = Float:get_entvar(gSelWord[UserId], var_renderamt);
    Alpha = floatclamp(Alpha + read_argv_float(NULL_ARG+1), 0.0, 255.0);
    set_entvar(gSelWord[UserId], var_renderamt, Alpha);
    
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_EditMode(const UserId){
    CMD_CHECK_ACCESS(UserId)
    
    SprLett_SetEditMode(!SprLett_GetEditMode());

    client_print(UserId, print_center, "%l", "CMD_EDIT_MODE", SprLett_GetEditMode() ? Lang("CMDS_ENABLED") : Lang("CMDS_DISABLED"));
}

@Cmd_Create(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)

    new Word[WORD_MAX_LENGTH];
    read_argv(NULL_ARG+1, Word, charsmax(Word));

    new Float:UserOrigin[3];
    get_entvar(UserId, var_origin, UserOrigin);
    UserOrigin[2] += 75.0;

    new Float:UserAngles[3];
    get_entvar(UserId, var_v_angle, UserAngles);
    UserAngles[2] = 0.0;
    UserAngles[0] = 0.0;

    new Float:Dir[3];
    Dir[0] = UserAngles[0];
    Dir[1] = UserAngles[1] - 90.0;
    Dir[2] = UserAngles[2];

    SprLett_SetParams(
        SL_P_Angles, UserAngles,
        SL_P_WordDir, Dir
    );

    gSelWord[UserId] = SprLett_InitWord(Word, UserOrigin);
    SprLett_BuildWord(gSelWord[UserId]);

    client_print(UserId, print_center, "%l", "CMD_WORD_CREATED", Word);
}

@Cmd_Charset(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new CharsetName[32];
    read_argv(NULL_ARG+1, CharsetName, charsmax(CharsetName));
    set_entvar(gSelWord[UserId], var_SL_WordCharset, CharsetName);
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_Write(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new NewWord[WORD_MAX_LENGTH];
    read_argv(NULL_ARG+1, NewWord, charsmax(NewWord));

    set_entvar(gSelWord[UserId], var_SL_WordText, NewWord);
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_Save(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    SprLett_SaveWord(gSelWord[UserId]);

    client_print(UserId, print_center, Lang("CMD_WORD_SAVED"));
}

@Cmd_Remove(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    SprLett_UnSaveWord(gSelWord[UserId]);
    SprLett_RemoveWord(gSelWord[UserId]);
    gSelWord[UserId] = nullent;

    client_print(UserId, print_center, Lang("CMD_WORD_REMOVED"));
}

@Cmd_MarqueeToggle(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    new WordEnt = gSelWord[UserId];

    if (get_entvar(WordEnt, var_SL_MarqueeWidth) > 0) {
        MarqueeEditor_Disable(WordEnt);
    } else {
        new Float:speed = get_entvar(WordEnt, var_SL_MarqueeSpeed);
        MarqueeEditor_Enable(WordEnt, DEFAULT_MARQUEE_WIDTH, speed);
    }

    Menu_Marquee(UserId);
}

@Cmd_MarqueeSetId(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new WordEnt = gSelWord[UserId];
    new marqueeId = read_argv_int(NULL_ARG+1);
    set_entvar(WordEnt, var_SL_MarqueeID, marqueeId);

    Menu_Marquee(UserId);
}

@Cmd_MarqueeSetWidth(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new width = read_argv_int(NULL_ARG+1);
    new WordEnt = gSelWord[UserId];

    if (width <= 0) {
        MarqueeEditor_Disable(WordEnt);
    } else {
        new Float:speed = get_entvar(WordEnt, var_SL_MarqueeSpeed);
        MarqueeEditor_Enable(WordEnt, width, speed);
    }

    Menu_Marquee(UserId);
}

@Cmd_MarqueeSetSpeed(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new Float:speed = floatmax(0.0, read_argv_float(NULL_ARG+1));

    new WordEnt = gSelWord[UserId];
    set_entvar(WordEnt, var_SL_MarqueeSpeed, speed);

    Menu_Marquee(UserId);
}

@Cmd_MarqueeSetText(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new WordEnt = gSelWord[UserId];

    new Text[WORD_MAX_LENGTH];
    read_argv(NULL_ARG+1, Text, charsmax(Text));
    MarqueeEditor_TrimString(Text, charsmax(Text));
    set_entvar(WordEnt, var_SL_MarqueeText, Text);

    new width = get_entvar(WordEnt, var_SL_MarqueeWidth);
    if (width <= 0) {
        set_entvar(WordEnt, var_SL_WordText, Text);
        SprLett_RebuildWord(WordEnt);
    } else {
        set_entvar(WordEnt, var_SL_MarqueeOffset, float(width));
    }

    Menu_Marquee(UserId);
}

@Cmd_MarqueeResetOffset(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    new WordEnt = gSelWord[UserId];
    new width = get_entvar(WordEnt, var_SL_MarqueeWidth);
    if (width > 0) {
        set_entvar(WordEnt, var_SL_MarqueeOffset, float(width));
    }

    Menu_Marquee(UserId);
}

stock bool:MarqueeEditor_Enable(const WordEnt, marqueeWidth, Float:speed){
    if (!SprLett_Is(WordEnt, SL_Is_Word))
        return false;

    marqueeWidth = clamp(marqueeWidth, 1, WORD_MAX_LENGTH - 1);
    if (marqueeWidth <= 0)
        return false;

    if (speed <= 0.0)
        speed = DEFAULT_MARQUEE_SPEED;

    if (get_entvar(WordEnt, var_SL_MarqueeID) == 0)
        set_entvar(WordEnt, var_SL_MarqueeID, WordEnt);

    new StoredText[WORD_MAX_LENGTH];
    MarqueeEditor_GetStoredText(WordEnt, StoredText, charsmax(StoredText));
    if (!StoredText[0])
        copy(StoredText, charsmax(StoredText), " ");

    set_entvar(WordEnt, var_SL_MarqueeText, StoredText);
    set_entvar(WordEnt, var_SL_MarqueeWidth, marqueeWidth);
    set_entvar(WordEnt, var_SL_MarqueeSpeed, speed);
    set_entvar(WordEnt, var_SL_MarqueeOffset, float(marqueeWidth));

    new Placeholder[WORD_MAX_LENGTH];
    MarqueeEditor_FillWindowString(Placeholder, charsmax(Placeholder), marqueeWidth);
    set_entvar(WordEnt, var_SL_WordText, Placeholder);

    SprLett_RebuildWord(WordEnt);
    return true;
}

stock MarqueeEditor_Disable(const WordEnt){
    if (!SprLett_Is(WordEnt, SL_Is_Word))
        return;

    new StoredText[WORD_MAX_LENGTH];
    MarqueeEditor_GetStoredText(WordEnt, StoredText, charsmax(StoredText));

    set_entvar(WordEnt, var_SL_MarqueeWidth, 0);
    set_entvar(WordEnt, var_SL_MarqueeSpeed, 0.0);
    set_entvar(WordEnt, var_SL_MarqueeOffset, 0.0);
    set_entvar(WordEnt, var_SL_MarqueeText, StoredText);
    set_entvar(WordEnt, var_SL_WordText, StoredText);

    SprLett_RebuildWord(WordEnt);
}

stock MarqueeEditor_GetStoredText(const WordEnt, buffer[], const maxLen){
    get_entvar(WordEnt, var_SL_MarqueeText, buffer, maxLen);
    if (!buffer[0])
        get_entvar(WordEnt, var_SL_WordText, buffer, maxLen);
    MarqueeEditor_TrimString(buffer, maxLen);
}

stock MarqueeEditor_FillWindowString(dest[], const maxLen, marqueeWidth){
    new limit = marqueeWidth;
    if (limit < 0)
        limit = 0;
    else if (limit > maxLen)
        limit = maxLen;

    for (new i = 0; i < limit; i++)
        dest[i] = ' ';

    dest[limit] = EOS;
}

stock MarqueeEditor_TrimString(string[], maxlength){
    new len = strlen(string);
    for (new i = len - 1; i >= 0; i--){
        if (string[i] == ' ')
            string[i] = EOS;
        else
            break;
    }

    len = strlen(string);
    new start = 0;
    while (string[start] == ' ' && start < len)
        start++;

    if (start > 0)
        format(string, maxlength, "%s", string[start]);
}

@Cmd_SetStepEx(const UserId){
    CMD_CHECK_ACCESS(UserId)

    new CurValId;
    for(CurValId = sizeof MOVESTEP_VALUES-1; CurValId >= 0; CurValId--){
        if(floatround(gMoveStep[UserId]) >= MOVESTEP_VALUES[CurValId]){
            CurValId++;
            break;
        }
    }

    if(CurValId >= sizeof MOVESTEP_VALUES)
        CurValId = 0;

    gMoveStep[UserId] = float(MOVESTEP_VALUES[CurValId]);
}

@Cmd_SetStep(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    gMoveStep[UserId] = read_argv_float(NULL_ARG+1);
}

@Cmd_Offset(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 1)
    CHECK_WORD(UserId)

    new Float:Offset = get_entvar(gSelWord[UserId], var_SL_WordOffset);
    set_entvar(gSelWord[UserId], var_SL_WordOffset, Offset+read_argv_float(NULL_ARG+1));
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_Move(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 3)
    CHECK_WORD(UserId)

    new Float:Origin[3];
    get_entvar(gSelWord[UserId], var_origin, Origin);
    Origin[0] += read_argv_float(NULL_ARG+1);
    Origin[1] += read_argv_float(NULL_ARG+2);
    Origin[2] += read_argv_float(NULL_ARG+3);
    set_entvar(gSelWord[UserId], var_origin, Origin);
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_Rotate(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 3)
    CHECK_WORD(UserId)

    new Float:Delta[3];
    Delta[0] = read_argv_float(NULL_ARG+1);
    Delta[1] = read_argv_float(NULL_ARG+2);
    Delta[2] = read_argv_float(NULL_ARG+3);

    new Float:Angles[3];
    get_entvar(gSelWord[UserId], var_angles, Angles);
    Angles[0] += Delta[0];
    Angles[1] += Delta[1];
    Angles[2] += Delta[2];
    set_entvar(gSelWord[UserId], var_angles, Angles);

    if(SprLett_RotateMode:get_entvar(gSelWord[UserId], var_SL_RotateMode) == SL_ROTATE_WORD)
        SyncWordDirWithAngles(gSelWord[UserId]);

    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_RotateMode(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 0)
    CHECK_WORD(UserId)

    new WordEnt = gSelWord[UserId];
    new SprLett_RotateMode:PrevMode = SprLett_RotateMode:get_entvar(WordEnt, var_SL_RotateMode);
    new SprLett_RotateMode:Mode = (PrevMode == SL_ROTATE_WORD) ? SL_ROTATE_LETTERS : SL_ROTATE_WORD;
    set_entvar(WordEnt, var_SL_RotateMode, _:Mode);

    if(PrevMode == SL_ROTATE_WORD)
        SyncWordDirWithAngles(WordEnt);
    if(Mode == SL_ROTATE_WORD)
        SyncWordDirWithAngles(WordEnt);

    SprLett_RebuildWord(WordEnt);

    new ModeMessageKey[32];
    if(Mode == SL_ROTATE_WORD)
        copy(ModeMessageKey, charsmax(ModeMessageKey), "CMD_ROTATE_MODE_WORD");
    else
        copy(ModeMessageKey, charsmax(ModeMessageKey), "CMD_ROTATE_MODE_LETTERS");
    client_print(UserId, print_center, "%l", ModeMessageKey);
}

@Cmd_Dir(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CMD_CHECK_ARGC(UserId, 2)
    CHECK_WORD(UserId)

    new Float:Dir[3];
    get_entvar(gSelWord[UserId], var_SL_WordDir, Dir);
    Dir[0] += read_argv_float(NULL_ARG+1);
    Dir[1] += read_argv_float(NULL_ARG+2);
    set_entvar(gSelWord[UserId], var_SL_WordDir, Dir);
    SprLett_RebuildWord(gSelWord[UserId]);
}

@Cmd_Select(const UserId){
    CMD_CHECK_ACCESS(UserId)
    new Ent;
    get_user_aiming(UserId, Ent);
    
    if((Ent = SprLett_GetWord(Ent)) == nullent){
        client_print(UserId, print_center, Lang("CMD_WORD_NOT_FOUND"));
        gSelWord[UserId] = nullent;
        return;
    }

    gSelWord[UserId] = Ent;

    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    client_print(UserId, print_center, "%l", "CMD_WORD_SELECTED", Word);
    return;
}
