/**
 * [SprLett] Editor
 */

#include <amxmodx>
#include <reapi>
#include <SprLetters>

#pragma semicolon 1

#define nullent 0

#define EDIT_ACCESS ADMIN_RCON
new const MOVESTEP_VALUES[] = {1, 5, 10, 25, 50};

new const SELECT_CMD[] = "slselect";
new const CREATE_CMD[] = "slcreate";

new const STEP_CMD[] = "slsetstep";
new const STEPEX_CMD[] = "slsetstepex";

new const MOVE_CMD[] = "slmove";
new const ROTATE_CMD[] = "slrotate";
new const DIR_CMD[] = "sldir";

new const CHARSET_CMD[] = "slcharset";
new const OFFSET_CMD[] = "sloffset";
new const WRITE_CMD[] = "slwrite";
new const REMOVE_CMD[] = "slremove";
new const SAVE_CMD[] = "slsave";

new const PLUG_NAME[] = "[SprLett] Editor";
new const PLUG_VER[] = "1.0.0";

new gSelWord[MAX_PLAYERS + 1] = {nullent, ...};
new Float:gMoveStep[MAX_PLAYERS + 1] = {1.0, ...};

#include "SprLett-Editor/Utils"
#include "SprLett-Editor/Menus"

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    RegisterClCmds(CREATE_CMD, "@Cmd_Create");
    RegisterClCmds(SELECT_CMD, "@Cmd_Select");

    RegisterClCmds(STEP_CMD, "@Cmd_SetStep");
    RegisterClCmds(STEPEX_CMD, "@Cmd_SetStepEx");

    RegisterClCmds(MOVE_CMD, "@Cmd_Move");
    RegisterClCmds(ROTATE_CMD, "@Cmd_Rotate");
    RegisterClCmds(DIR_CMD, "@Cmd_Dir");

    RegisterClCmds(CHARSET_CMD, "@Cmd_Charset");
    RegisterClCmds(OFFSET_CMD, "@Cmd_Offset");
    RegisterClCmds(WRITE_CMD, "@Cmd_Write");
    RegisterClCmds(REMOVE_CMD, "@Cmd_Remove");
    RegisterClCmds(SAVE_CMD, "@Cmd_Save");

    MenuCmds_Init();
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
}

@Cmd_Remove(const UserId){
    CMD_CHECK_ACCESS(UserId)
    CHECK_WORD(UserId)

    SprLett_UnSaveWord(gSelWord[UserId]);
    SprLett_RemoveWord(gSelWord[UserId]);
    gSelWord[UserId] = nullent;
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

    new Float:Angles[3];
    get_entvar(gSelWord[UserId], var_angles, Angles);
    Angles[0] += read_argv_float(NULL_ARG+1);
    Angles[1] += read_argv_float(NULL_ARG+2);
    Angles[2] += read_argv_float(NULL_ARG+3);
    set_entvar(gSelWord[UserId], var_angles, Angles);
    SprLett_RebuildWord(gSelWord[UserId]);
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
        client_print(UserId, print_center, "Слово не найдено");
        gSelWord[UserId] = nullent;
        return;
    }

    gSelWord[UserId] = Ent;

    new Word[WORD_MAX_LENGTH];
    get_entvar(gSelWord[UserId], var_SL_WordText, Word, charsmax(Word));
    client_print(UserId, print_center, "Слово '%s' выбрано", Word);
    return;
}
