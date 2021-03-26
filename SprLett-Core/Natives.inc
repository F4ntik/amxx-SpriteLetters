/**
 * Sprite Letters: Natives
 */

#include <amxmodx>

#define get_vector(%1,%2) get_array_f(%1,%2,3)

enum {
    ERR_UNDEFINED_SPR_PARAM = 0,
    ERR_UNDEFINED_CHARSET,
}

public plugin_natives(){
    register_native("SprLett_CreateLetter", "@_CreateLetter");

    register_native("SprLett_InitWord", "@_InitWord");
    register_native("SprLett_BuildWord", "@_BuildWord");
    register_native("SprLett_RemoveWord", "@_RemoveWord");
    register_native("SprLett_DestroyWord", "@_DestroyWord");
    register_native("SprLett_WordIterNext", "@_WordIterNext");

    register_native("SprLett_Is", "@_Is");
    register_native("SprLett_SetParams", "@_SetParams");
    register_native("SprLett_EditToggle", "@_EditToggle");
}

@_WordIterNext(){
    enum {Arg_Ent = 1}
    new Ent = get_param(Arg_Ent);
    set_param_byref(Arg_Ent, WordIterNext(Ent));
    return Ent;
}

bool:@_Is(){
    enum {Arg_Ent = 1, Arg_Is}
    new Ent = get_param(Arg_Ent);
    new SprLett_WhatIs:Is = SprLett_WhatIs:get_param_byref(Arg_Is);

    switch(Is){
        case SL_Is_Word:
            return IsWord(Ent);
        case SL_Is_Letter:
            return IsLetter(Ent);
        case SL_Is_WordLetter:
            return IsWordLetter(Ent);
    }
    return false;
}

@_DestroyWord(){
    enum {Arg_WordEnt = 1}

    DestroyWord(get_param(Arg_WordEnt));
}

@_RemoveWord(){
    enum {Arg_Ent = 1}

    RemoveWord(get_param(Arg_Ent));
}

@_EditToggle(){
    enum {Arg_State = 1}

    EditToggle(bool:get_param(Arg_State));
}

@_CreateLetter(){
    enum {Arg_Letter = 1, Arg_Origin}

    new Letter[LETTER_SIZE];
    get_string(Arg_Letter, Letter, charsmax(Letter));

    new Float:Origin[3];
    get_vector(Arg_Origin, Origin);

    return CreateLetter(Letter, Origin);
}

@_InitWord(){
    enum {Arg_Word = 1, Arg_Origin}

    new Word[WORD_MAX_LENGTH];
    get_string(Arg_Word, Word, charsmax(Word));
    new Float:Origin[3];
    get_vector(Arg_Origin, Origin);

    return InitWord(Word, Origin);
}

@_BuildWord(){
    enum {Arg_WordEnt = 1}

    BuildWord(get_param(Arg_WordEnt));
}

bool:@_SetParams(PlugId, pCnt){
    for(new i = 1; i < pCnt; i += 2){
        new Param = get_param_byref(i);
        switch(Param){
            case SL_P_Scale:
                SprParams[SL_P_Scale] = get_param_f(i+1);
            case SL_P_Alpha:
                SprParams[SL_P_Alpha] = get_param_f(i+1);
            case SL_P_Size:
                SprParams[SL_P_Size] = get_param_f(i+1);

            case SL_P_WordDir: 
                get_vector(i+1, SprWordDir);
            case SL_P_Angles:
                get_vector(i+1, SprAngles);

            case SL_P_Charset: {
                new CharsetName[32];
                get_string(i+1, CharsetName, charsmax(CharsetName));
                if(!TrieGetArray(Charsets, CharsetName, SprCharset, SprLett_CharsetData)){
                    // log_error(ERR_UNDEFINED_CHARSET, "Undefined charset '%s'.", CharsetName);
                    return false;
                }
            }

            default: log_error(ERR_UNDEFINED_SPR_PARAM, "Undefined sprites param (%d).", _:Param);
        }
    }
    return true;
}