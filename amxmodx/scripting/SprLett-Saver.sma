/**
 * [SprLett] Saver
 */

#include <amxmodx>
#include <reapi>
#include <vector>
#include <json>
#include <SprLetters>
#include "SprLett-Core/Ver"

#define IntToStr(%1) fmt("%d",%1)

#define var_WordSaveId var_iuser4
#define offset__var_WordSaveId 10

new const CFGS_DIR[] = "/plugins/SpriteLetters/Saves/";

new const PLUG_NAME[] = "[SprLett] Saver";
#define PLUG_VER SPRLETT_VERSION

new JSON:gSaves = Invalid_JSON;
new gSavesFile[PLATFORM_MAX_PATH];
new gSavesDir[PLATFORM_MAX_PATH];
new bool:gSaveBlocked = true;
new bool:gSavesFileExpected;
new gLastSaveId = 0;

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

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
}

public plugin_natives(){
    register_native("SprLett_SaveWord", "@_SaveWord");
    register_native("SprLett_UnSaveWord", "@_UnSaveWord");
    register_native("SprLett_GetSavesFile", "@_GetSavesFile");
}

@_GetSavesFile(){
    return set_string(1, gSavesFile, get_param(2));
}

bool:@_SaveWord(){
    enum {Arg_WordEnt = 1}
    new WordEnt = get_param(Arg_WordEnt);

    if(!SprLett_Is(WordEnt, SL_Is_Word)){
        log_error(0, "Entity #%d is not a word.", WordEnt);
        return false;
    }

    if(gSaveBlocked || gSaves == Invalid_JSON)
        return false;

    new iId = get_entvar(WordEnt, var_WordSaveId)-offset__var_WordSaveId;
    if(iId < 0)
        iId = gLastSaveId + 1;

    new JSON:Candidate = json_deep_copy(gSaves);
    new JSON:WordObj = WordToJson(WordEnt);
    if(Candidate == Invalid_JSON || WordObj == Invalid_JSON){
        if(Candidate != Invalid_JSON) json_free(Candidate);
        if(WordObj != Invalid_JSON) json_free(WordObj);
        return false;
    }
    new bool:Updated = json_object_set_value(Candidate, IntToStr(iId), WordObj);
    json_free(WordObj);
    if(!Updated || !SaveToFile(Candidate)){
        json_free(Candidate);
        return false;
    }
    json_free(gSaves);
    gSaves = Candidate;
    gLastSaveId = max(gLastSaveId, iId);
    set_entvar(WordEnt, var_WordSaveId, iId+offset__var_WordSaveId);
    return true;
}

bool:@_UnSaveWord(){
    enum {Arg_WordEnt = 1}
    new WordEnt = get_param(Arg_WordEnt);

    if(!SprLett_Is(WordEnt, SL_Is_Word)){
        log_error(0, "Entity #%d is not a word.", WordEnt);
        return false;
    }

    new iId = get_entvar(WordEnt, var_WordSaveId)-offset__var_WordSaveId;
    if(iId < 0)
        return true;
    if(gSaveBlocked || gSaves == Invalid_JSON)
        return false;
    
    new JSON:Candidate = json_deep_copy(gSaves);
    if(Candidate == Invalid_JSON)
        return false;
    if(!json_object_remove(Candidate, IntToStr(iId)) || !SaveToFile(Candidate)){
        json_free(Candidate);
        return false;
    }
    json_free(gSaves);
    gSaves = Candidate;
    set_entvar(WordEnt, var_WordSaveId, 0);
    return true;
}

public plugin_cfg(){
    new MapName[32];
    rh_get_mapname(MapName, charsmax(MapName), MNT_TRUE);

    get_localinfo("amxx_configsdir", gSavesFile, charsmax(gSavesFile));
    if(!gSavesFile[0] || strlen(gSavesFile) + strlen(CFGS_DIR) + strlen(MapName) + 9 > charsmax(gSavesFile)){
        log_amx("[ERROR] Invalid or overlong saves path. Saving disabled.");
        return;
    }
    add(gSavesFile, charsmax(gSavesFile), CFGS_DIR);
    copy(gSavesDir, charsmax(gSavesDir), gSavesFile);
    add(gSavesFile, charsmax(gSavesFile), fmt("%s.json", MapName));

    new bool:PendingWrite = file_exists(fmt("%s.tmp", gSavesFile)) != 0;
    if(!file_exists(gSavesFile)){
        log_amx("[INFO] Saves for current map not found.");
        gSaves = json_init_object();
        gSaveBlocked = PendingWrite || file_exists(fmt("%s.bak", gSavesFile));
        if(gSaveBlocked)
            log_amx("[ERROR] Interrupted save: recover '%s.tmp' / '%s.bak' before saving.", gSavesFile, gSavesFile);
        return;
    }
    
    gSavesFileExpected = true;
    gSaves = json_parse(gSavesFile, true);
    if(gSaves == Invalid_JSON){
        log_amx("[WARNING] JSON syntax error. File '%s'.", gSavesFile);
        gSaves = json_init_object();
        return;
    }
    if(!json_is_object(gSaves)){
        json_free(gSaves);
        log_amx("[WARNING] Invalid saves structure. File '%s'.", gSavesFile);
        gSaves = json_init_object();
        return;
    }

    gSaveBlocked = PendingWrite;
    if(gSaveBlocked)
        log_amx("[ERROR] Pending '%s.tmp' preserved; saving disabled until recovery.", gSavesFile);

    gLastSaveId = 0;
    new sId[16], iId;
    for(new i = 0; i < json_object_get_count(gSaves); i++){
        json_object_get_name(gSaves, i, sId, charsmax(sId));
        iId = str_to_num(sId);
        if(iId > gLastSaveId)
            gLastSaveId = iId;

        new JSON:WordObj = json_object_get_value_at(gSaves, i);
        if(!json_is_object(WordObj)){
            json_free(WordObj);
            continue;
        }

        new WordEnt = SprLett_InitWord();
        if(!SprLett_Is(WordEnt, SL_Is_Word)){
            json_free(WordObj);
            log_amx("[ERROR] Cannot create saved word '%s'.", sId);
            continue;
        }
        JsonToWord(WordObj, WordEnt);
        set_entvar(WordEnt, var_WordSaveId, iId+offset__var_WordSaveId);
        SprLett_BuildWord(WordEnt);
        json_free(WordObj);
    }
}

public plugin_end(){
    // Explicit save/delete already commits a snapshot. Never rewrite on shutdown.
    if(gSaves != Invalid_JSON)
        json_free(gSaves);
}

bool:EnsureSaveDirectories(){
    new Path[PLATFORM_MAX_PATH];
    copy(Path, charsmax(Path), gSavesDir);
    for(new i = 1; Path[i]; i++){
        if(Path[i] != '/' && Path[i] != 92)
            continue;
        new Separator = Path[i];
        Path[i] = EOS;
        if(!dir_exists(Path) && mkdir(Path) != 0){
            log_amx("[ERROR] Cannot create saves directory '%s'.", Path);
            return false;
        }
        Path[i] = Separator;
    }
    return dir_exists(Path) != 0;
}

bool:SaveToFile(const JSON:Candidate){
    if(gSaveBlocked || !EnsureSaveDirectories())
        return false;

    new Temp[PLATFORM_MAX_PATH], Backup[PLATFORM_MAX_PATH];
    formatex(Temp, charsmax(Temp), "%s.tmp", gSavesFile);
    formatex(Backup, charsmax(Backup), "%s.bak", gSavesFile);
    if(file_exists(Temp)){
        log_amx("[ERROR] Pending file '%s' preserved. Recover it before saving.", Temp);
        gSaveBlocked = true;
        return false;
    }

    new bool:HadFile = file_exists(gSavesFile) != 0;
    if(HadFile != gSavesFileExpected){
        log_amx("[ERROR] Save '%s' appeared or disappeared outside Saver. Reload after recovery.", gSavesFile);
        gSaveBlocked = true;
        return false;
    }
    if(!HadFile && file_exists(Backup)){
        log_amx("[ERROR] Main save missing; backup '%s' preserved.", Backup);
        gSaveBlocked = true;
        return false;
    }
    if(HadFile){
        new JSON:Current = json_parse(gSavesFile, true);
        new bool:Unchanged = Current != Invalid_JSON && json_equals(Current, gSaves);
        if(Current != Invalid_JSON) json_free(Current);
        if(!Unchanged){
            log_amx("[ERROR] Save '%s' changed or became unreadable. Reload the map after recovery.", gSavesFile);
            gSaveBlocked = true;
            return false;
        }
    }

    if(!json_serial_to_file(Candidate, Temp, false)){
        log_amx("[ERROR] Cannot write temporary save '%s'.", Temp);
        if(file_exists(Temp)) delete_file(Temp);
        return false;
    }
    new JSON:Check = json_parse(Temp, true);
    new bool:Verified = Check != Invalid_JSON && json_equals(Check, Candidate);
    if(Check != Invalid_JSON) json_free(Check);
    if(!Verified){
        log_amx("[ERROR] Temporary save '%s' failed readback.", Temp);
        delete_file(Temp);
        return false;
    }

    if(HadFile){
        if(file_exists(Backup) && !delete_file(Backup)){
            log_amx("[ERROR] Cannot replace backup '%s'.", Backup);
            delete_file(Temp);
            return false;
        }
        if(!rename_file(gSavesFile, Backup, 1)){
            log_amx("[ERROR] Cannot move '%s' to backup.", gSavesFile);
            delete_file(Temp);
            return false;
        }
    }
    if(!rename_file(Temp, gSavesFile, 1)){
        log_amx("[ERROR] Cannot install new save '%s'.", gSavesFile);
        if(HadFile && !rename_file(Backup, gSavesFile, 1)){
            log_amx("[ERROR] Restore failed. Recover '%s' and '%s' manually.", Backup, Temp);
            gSaveBlocked = true;
        } else {
            delete_file(Temp);
        }
        return false;
    }
    gSavesFileExpected = true;
    return true;
}

JSON:WordToJson(const WordEnt){
    new JSON:WordObj = json_init_object();
    if(WordObj == Invalid_JSON)
        return Invalid_JSON;
    new Float:Vec[3], Str[WORD_MAX_LENGTH], Float:Fl, i;

    get_entvar(WordEnt, var_origin, Vec);
    json_object_set_vector(WordObj, "Origin", Vec);

    get_entvar(WordEnt, var_angles, Vec);
    json_object_set_vector(WordObj, "Angles", Vec);

    get_entvar(WordEnt, var_SL_WordDir, Vec);
    json_object_set_vector(WordObj, "Dir", Vec);

    get_entvar(WordEnt, var_rendercolor, Vec);
    json_object_set_vector(WordObj, "Color", Vec);

    get_entvar(WordEnt, var_SL_MarqueeText, Str, charsmax(Str));
    if(!Str[0])
        get_entvar(WordEnt, var_SL_WordText, Str, charsmax(Str));
    json_object_set_string(WordObj, "Text", Str);
    json_object_set_number(WordObj, "MarqueeID", get_entvar(WordEnt, var_SL_MarqueeID));
    json_object_set_number(WordObj, "MarqueeWidth", get_entvar(WordEnt, var_SL_MarqueeWidth));
    json_object_set_real(WordObj, "MarqueeSpeed", Float:get_entvar(WordEnt, var_SL_MarqueeSpeed));
    json_object_set_real(WordObj, "MarqueeOffset", Float:get_entvar(WordEnt, var_SL_MarqueeOffset));
    json_object_set_real(WordObj, "Scale", Float:get_entvar(WordEnt, var_scale));

    get_entvar(WordEnt, var_SL_WordCharset, Str, charsmax(Str)); // var_noise
    json_object_set_string(WordObj, "Charset", Str);

    Fl = get_entvar(WordEnt, var_SL_LetterSize); // var_fuser1 (for letters, but var_LetterSize for words)
    json_object_set_real(WordObj, "LetterSize", Fl);

    Fl = get_entvar(WordEnt, var_SL_WordOffset);
    json_object_set_real(WordObj, "Offset", Fl);

    Fl = get_entvar(WordEnt, var_renderamt);
    json_object_set_real(WordObj, "Alpha", Fl);

    i = get_entvar(WordEnt, var_rendermode);
    json_object_set_number(WordObj, "RenderMode", i);

    i = get_entvar(WordEnt, var_SL_RotateMode);
    json_object_set_number(WordObj, "RotateMode", i);

    return WordObj;
}

JsonToWord(const JSON:WordObj, const WordEnt){
    new Float:Vec[3], Str[WORD_MAX_LENGTH], Float:Fl, i;

    json_object_get_vector(WordObj, "Origin", Vec);
    set_entvar(WordEnt, var_origin, Vec);

    json_object_get_vector(WordObj, "Angles", Vec);
    set_entvar(WordEnt, var_angles, Vec);

    json_object_get_vector(WordObj, "Dir", Vec);
    set_entvar(WordEnt, var_SL_WordDir, Vec);

    set_entvar(WordEnt, var_SL_RotateMode, json_object_get_number(WordObj, "RotateMode"));
    if(SprLett_RotateMode:get_entvar(WordEnt, var_SL_RotateMode) == SL_ROTATE_WORD)
        SyncWordDirWithAngles(WordEnt);

    json_object_get_vector(WordObj, "Color", Vec);
    set_entvar(WordEnt, var_rendercolor, Vec);

    // Load "Text" (which is full text for marquees, display text for non-marquees)
    json_object_get_string(WordObj, "Text", Str, charsmax(Str));
    set_entvar(WordEnt, var_SL_WordText, Str); // Set to var_message for BuildWord

    // Load marquee properties (they will default to 0/empty if not in JSON)
    new marqueeId_val = json_object_get_number(WordObj, "MarqueeID");
    new loadedMarqueeWidth = clamp(json_object_get_number(WordObj, "MarqueeWidth"), 0, WORD_MAX_LENGTH - 1);
    new Float:marqueeSpeed_val = floatmax(0.0, json_object_get_real(WordObj, "MarqueeSpeed"));
    new Float:marqueeOffset_val = json_object_get_real(WordObj, "MarqueeOffset");

    set_entvar(WordEnt, var_iuser1, marqueeId_val);     // var_MarqueeID
    set_entvar(WordEnt, var_iuser2, loadedMarqueeWidth);  // var_MarqueeWidth
    set_entvar(WordEnt, var_fuser3, marqueeSpeed_val); // var_MarqueeSpeed
    set_entvar(WordEnt, var_fuser4, marqueeOffset_val);// var_MarqueeOffset

    set_entvar(WordEnt, var_SL_MarqueeText, Str);
    if(json_object_has_value(WordObj, "Scale"))
        set_entvar(WordEnt, var_scale, json_object_get_real(WordObj, "Scale"));
    
    json_object_get_string(WordObj, "Charset", Str, charsmax(Str));
    set_entvar(WordEnt, var_SL_WordCharset, Str); // var_noise

    Fl = json_object_get_real(WordObj, "LetterSize"); // var_fuser1 (for letters, but var_LetterSize for words)
    set_entvar(WordEnt, var_SL_LetterSize, Fl);

    Fl = json_object_get_real(WordObj, "Offset");
    set_entvar(WordEnt, var_SL_WordOffset, Fl);

    Fl = json_object_get_real(WordObj, "Alpha");
    set_entvar(WordEnt, var_renderamt, Fl);

    i = json_object_get_number(WordObj, "RenderMode");
    set_entvar(WordEnt, var_rendermode, i);

    return WordEnt;
}

json_object_set_vector(JSON:Obj, const Name[], const Float:Vec[], const Size = 3, const bool:DotNot = false){
    new JSON:Vector = json_init_vector(Vec, Size);
    json_object_set_value(Obj, Name, Vector, DotNot);
    json_free(Vector);
}

JSON:json_init_vector(const Float:Vec[], const Size = 3){
    new JSON:VecObj = json_init_array();
    for(new i = 0; i < Size; i++)
        json_array_append_real(VecObj, Vec[i]);
    return VecObj;
}

json_get_vector(const JSON:Item, Float:Vec[], const Size = 3){
    if(!json_is_array(Item))
        for(new i = 0; i < Size; i++)
            Vec[i] = 0.0;
    else
        for(new i = 0; i < Size; i++)
            Vec[i] = json_array_get_real(Item, i);
}

json_object_get_vector(const JSON:Obj, const Name[], Float:Vec[], const Size = 3, const bool:DotNot = false){
    new JSON:Item = json_object_get_value(Obj, Name, DotNot);
    json_get_vector(Item, Vec, Size);
    json_free(Item);
}
