#include <amxmodx>
#include <reapi>
#include <SprLetters>

new const PLUG_NAME[] = "[SprLett] Cmds";
new const PLUG_VER[] = "1.0.0";

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    register_clcmd("Lett_Word", "@Cmd_Word");
    register_clcmd("Lett_Letter", "@Cmd_Letter");
    register_clcmd("Lett_Remove", "@Cmd_Remove");
    register_clcmd("Lett_EditMode", "@Cmd_EditMode");
    register_clcmd("Lett_SelectCharset", "@Cmd_SelectCharset");

    SprLett_EditToggle(true);
}

@Cmd_SelectCharset(const UserId){
    new CharsetName[32];
    read_argv(1, CharsetName, charsmax(CharsetName));

    if(!SprLett_SetParams(SL_P_Charset, CharsetName))
        client_print(UserId, print_center, "Указанный набор символов не найден");
}

@Cmd_EditMode(const UserId){
    SprLett_EditToggle(bool:read_argv_int(1));
}

@Cmd_Remove(const UserId){
    new Ent;
    get_user_aiming(UserId, Ent);

    SprLett_RemoveWord(Ent);
}

@Cmd_Letter(const UserId){
    new Char[LETTER_SIZE];
    read_argv(1, Char, charsmax(Char));

    new Float:UserOrigin[3];
    get_entvar(UserId, var_origin, UserOrigin);
    UserOrigin[2] += 75.0;

    new Float:UserAngles[3];
    get_entvar(UserId, var_angles, UserAngles);
    UserAngles[2] = 0.0;

    SprLett_SetParams(SL_P_Angles, UserAngles);

    SprLett_CreateLetter(Char, UserOrigin);
}

@Cmd_Word(const UserId){
    new Word[WORD_MAX_LENGTH];
    read_argv(1, Word, charsmax(Word));

    new Float:UserOrigin[3];
    get_entvar(UserId, var_origin, UserOrigin);
    UserOrigin[2] += 75.0;

    new Float:Dir[3];
    get_entvar(UserId, var_v_angle, Dir);
    angle_vector(Dir, ANGLEVECTOR_RIGHT, Dir);

    new Float:UserAngles[3];
    get_entvar(UserId, var_v_angle, UserAngles);
    UserAngles[2] = 0.0;

    SprLett_SetParams(
        SL_P_Angles, UserAngles,
        SL_P_WordDir, Dir
    );

    SprLett_CreateWord(Word, UserOrigin);
}