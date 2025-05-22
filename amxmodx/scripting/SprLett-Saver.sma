/**
 * [SprLett] Saver
 */

#include <amxmodx>
#include <reapi>
#include <json>
#include <SprLetters>
#include "SprLett-Core/Ver"

#define IntToStr(%1) fmt("%d",%1)
#define CreateFile(%1) fclose(fopen(%1,"w"))

#define var_WordSaveId var_iuser1
#define offset__var_WordSaveId 10

new const CFGS_DIR[] = "/plugins/SpriteLetters/Saves/";

new const PLUG_NAME[] = "[SprLett] Saver";
#define PLUG_VER SPRLETT_VERSION

new JSON:gSaves;
new gSavesFile[PLATFORM_MAX_PATH];
new gLastSaveId = 0;

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
}

public plugin_natives(){
    register_native("SprLett_SaveWord", "@_SaveWord");
    register_native("SprLett_UnSaveWord", "@_UnSaveWord");
}

@_SaveWord(){
    enum {Arg_WordEnt = 1}
    new WordEnt = get_param(Arg_WordEnt);

    if(!SprLett_Is(WordEnt, SL_Is_Word)){
        log_error(0, "Entity #%d is not a word.", WordEnt);
        return;
    }

    new iId = get_entvar(WordEnt, var_WordSaveId)-offset__var_WordSaveId;
    if(iId < 0){
        gLastSaveId++;
        iId = gLastSaveId;
        set_entvar(WordEnt, var_WordSaveId, iId+offset__var_WordSaveId);
    }

    json_object_set_value(gSaves, IntToStr(iId), WordToJson(WordEnt));
    SaveToFile();
}

@_UnSaveWord(){
    enum {Arg_WordEnt = 1}
    new WordEnt = get_param(Arg_WordEnt);

    if(!SprLett_Is(WordEnt, SL_Is_Word)){
        log_error(0, "Entity #%d is not a word.", WordEnt);
        return;
    }

    new iId = get_entvar(WordEnt, var_WordSaveId)-offset__var_WordSaveId;
    if(iId < 0)
        return;
    
    json_object_remove(gSaves, IntToStr(iId));
    SaveToFile();
}

public plugin_cfg(){
    new MapName[32];
    rh_get_mapname(MapName, charsmax(MapName), MNT_TRUE);

    get_localinfo("amxx_configsdir", gSavesFile, charsmax(gSavesFile));
    add(gSavesFile, charsmax(gSavesFile), CFGS_DIR);
    if(!dir_exists(gSavesFile))
        mkdir(gSavesFile);
    add(gSavesFile, charsmax(gSavesFile), fmt("%s.json", MapName));

    if(!file_exists(gSavesFile)){
        log_amx("[INFO] Saves for current map not found.");
        gSaves = json_init_object();
        return;
    }
    
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

    gLastSaveId = 0;
    new sId[16], iId;
    for(new i = 0; i < json_object_get_count(gSaves); i++){
        json_object_get_name(gSaves, i, sId, charsmax(sId));
        iId = str_to_num(sId);
        if(iId > gLastSaveId)
            gLastSaveId = iId;

        new JSON:WordObj = json_object_get_value_at(gSaves, i);
        if(!json_is_object(WordObj))
            continue;

        new WordEnt = SprLett_InitWord();
        JsonToWord(WordObj, WordEnt);
        set_entvar(WordEnt, var_WordSaveId, iId+offset__var_WordSaveId);
        SprLett_BuildWord(WordEnt);
    }
}

public plugin_end(){
    SaveToFile();
    json_free(gSaves);
}

SaveToFile(){
    if(!file_exists(gSavesFile))
        CreateFile(gSavesFile);
    json_serial_to_file(gSaves, gSavesFile, false);
}

JSON:WordToJson(const WordEnt){
    new JSON:WordObj = json_init_object();
    new Float:Vec[3], Str[WORD_MAX_LENGTH], Float:Fl, i;

    get_entvar(WordEnt, var_origin, Vec);
    json_object_set_vector(WordObj, "Origin", Vec);

    get_entvar(WordEnt, var_angles, Vec);
    json_object_set_vector(WordObj, "Angles", Vec);

    get_entvar(WordEnt, var_SL_WordDir, Vec);
    json_object_set_vector(WordObj, "Dir", Vec);

    get_entvar(WordEnt, var_rendercolor, Vec);
    json_object_set_vector(WordObj, "Color", Vec);

    // Handle Text field based on marquee status
    new marqueeWidth_val = get_entvar(WordEnt, var_iuser2); // var_MarqueeWidth
    if (marqueeWidth_val > 0) {
        get_entvar(WordEnt, var_netname, Str, charsmax(Str)); // var_MarqueeText (full text)
        json_object_set_string(WordObj, "Text", Str);

        // Save other marquee properties
        i = get_entvar(WordEnt, var_iuser1); // var_MarqueeID
        json_object_set_number(WordObj, "MarqueeID", i);
        json_object_set_number(WordObj, "MarqueeWidth", marqueeWidth_val); // Already have it

        Fl = get_entvar(WordEnt, var_fuser3); // var_MarqueeSpeed
        json_object_set_real(WordObj, "MarqueeSpeed", Fl);
        
        Fl = get_entvar(WordEnt, var_fuser4); // var_MarqueeOffset
        json_object_set_real(WordObj, "MarqueeOffset", Fl);

    } else { // Not a marquee, save var_WordText as "Text"
        get_entvar(WordEnt, var_SL_WordText, Str, charsmax(Str)); // var_message
        json_object_set_string(WordObj, "Text", Str);
    }

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

    json_object_get_vector(WordObj, "Color", Vec);
    set_entvar(WordEnt, var_rendercolor, Vec);

    // Load "Text" (which is full text for marquees, display text for non-marquees)
    json_object_get_string(WordObj, "Text", Str, charsmax(Str));
    set_entvar(WordEnt, var_SL_WordText, Str); // Set to var_message for BuildWord

    // Load marquee properties (they will default to 0/empty if not in JSON)
    new marqueeId_val = json_object_get_number(WordObj, "MarqueeID");
    new loadedMarqueeWidth = json_object_get_number(WordObj, "MarqueeWidth");
    new Float:marqueeSpeed_val = json_object_get_real(WordObj, "MarqueeSpeed");
    new Float:marqueeOffset_val = json_object_get_real(WordObj, "MarqueeOffset");

    set_entvar(WordEnt, var_iuser1, marqueeId_val);     // var_MarqueeID
    set_entvar(WordEnt, var_iuser2, loadedMarqueeWidth);  // var_MarqueeWidth
    set_entvar(WordEnt, var_fuser3, marqueeSpeed_val); // var_MarqueeSpeed
    set_entvar(WordEnt, var_fuser4, marqueeOffset_val);// var_MarqueeOffset

    if (loadedMarqueeWidth > 0) {
        // It's a marquee, so the "Text" we loaded is the full MarqueeText
        set_entvar(WordEnt, var_netname, Str); // var_MarqueeText
    } else {
        // Not a marquee, ensure MarqueeText is empty
        set_entvar(WordEnt, var_netname, "");
    }
    
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
    json_object_set_value(Obj, Name, json_init_vector(Vec, Size), DotNot);
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