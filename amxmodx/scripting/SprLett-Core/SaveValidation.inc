// Validate before creating engine entities. Preserve invalid input on disk.
bool:SaveNumber(const JSON:Obj, const Key[], const Float:Min, const Float:Max, const bool:Optional = false){
    if(!json_object_has_value(Obj, Key)) return Optional;
    if(!json_object_has_value(Obj, Key, JSONNumber)) return false;
    new Float:N = json_object_get_real(Obj, Key);
    return N >= Min && N <= Max; // Also rejects NaN and infinity.
}

bool:SaveVector(const JSON:Obj, const Key[], const Float:Min, const Float:Max){
    new JSON:Vec = json_object_get_value(Obj, Key);
    new bool:Valid = json_is_array(Vec) && json_array_get_count(Vec) == 3;
    if(Valid){
        for(new i; i < 3; i++){
            new JSON:Value = json_array_get_value(Vec, i);
            new Float:N = json_get_real(Value);
            Valid = json_is_number(Value) && N >= Min && N <= Max;
            json_free(Value);
            if(!Valid) break;
        }
    }
    if(Vec != Invalid_JSON) json_free(Vec);
    return Valid;
}

bool:SaveId(const Id[], &Value){
    if(!Id[0] || strlen(Id) > 9 || (Id[0] == '0' && Id[1])) return false;
    for(new i; Id[i]; i++) if(Id[i] < '0' || Id[i] > '9') return false;
    Value = str_to_num(Id);
    return Value >= 0 && Value < 999999999;
}

bool:ValidateSavedWord(const JSON:Obj){
    if(!json_is_object(Obj)) return false;
    if(!json_object_has_value(Obj, "Text", JSONString)
       || !json_object_has_value(Obj, "Charset", JSONString)) return false;
    new Text[WORD_MAX_LENGTH+1], Charset[33];
    json_object_get_string(Obj, "Text", Text, charsmax(Text));
    json_object_get_string(Obj, "Charset", Charset, charsmax(Charset));
    if(strlen(Text) >= WORD_MAX_LENGTH || !Charset[0] || strlen(Charset) >= 32) return false;
    if(!SprLett_HasCharset(Charset)) return false;
    if(!SaveVector(Obj, "Origin", -8192.0, 8192.0)
       || !SaveVector(Obj, "Angles", -36000.0, 36000.0)
       || !SaveVector(Obj, "Dir", -36000.0, 36000.0)
       || !SaveVector(Obj, "Color", 0.0, 255.0)) return false;
    if(!SaveNumber(Obj, "LetterSize", 0.01, 512.0)
       || !SaveNumber(Obj, "Offset", -512.0, 512.0)
       || !SaveNumber(Obj, "Alpha", 0.0, 255.0)
       || !SaveNumber(Obj, "RenderMode", 0.0, 5.0)
       || !SaveNumber(Obj, "Scale", 0.01, 32.0, true)
       || !SaveNumber(Obj, "RotateMode", 0.0, 1.0, true)
       || !SaveNumber(Obj, "MarqueeWidth", 0.0, 127.0, true)
       || !SaveNumber(Obj, "MarqueeID", 0.0, 999999999.0, true)
       || !SaveNumber(Obj, "MarqueeSpeed", 0.0, 1000.0, true)
       || !SaveNumber(Obj, "MarqueeOffset", -10000.0, 10000.0, true)) return false;
    if(json_object_has_value(Obj, "PanelWidth")){
        if(!SaveNumber(Obj, "PanelWidth", 32.0, 512.0)
           || !SaveNumber(Obj, "PanelHeight", 16.0, 128.0)
           || !SaveNumber(Obj, "PanelStyle", 0.0, 3.0)
           || json_object_get_number(Obj, "PanelWidth") % 4
           || json_object_get_number(Obj, "PanelHeight") % 4
           || json_object_get_number(Obj, "RotateMode") != _:SL_ROTATE_WORD) return false;
    }
    return true;
}
