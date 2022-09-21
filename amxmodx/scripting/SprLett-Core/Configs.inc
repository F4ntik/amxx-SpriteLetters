/**
 * Sprite Letters: Configs
 */

#include <amxmodx>
#include <json>

// Must be const (https://github.com/alliedmodders/amxmodx/pull/955)
new CHARSETS_PATH[] = "sprites/SprLett/Charsets/";

Trie:LoadCharsets(){
    if(!dir_exists(CHARSETS_PATH)){
        set_fail_state("[ERROR] Charsets folder '%s' not found.", CHARSETS_PATH);
        return Invalid_Trie;
    }

    new Charset[SprLett_CharsetData];
    new Trie:CharsetsMap;
    new MapFile[PLATFORM_MAX_PATH];
    
    new DirHandler, FileType:Type;
    DirHandler = open_dir(CHARSETS_PATH, Charset[SL_CD_Name], charsmax(Charset[SL_CD_Name]), Type);
    if(!DirHandler){
        set_fail_state("[ERROR] Can't open charsets directory '%s'.", CHARSETS_PATH);
        return Invalid_Trie;
    }

    do{
        if(
            Charset[SL_CD_Name][0] == '!'
            || Charset[SL_CD_Name][0] == '.'
        ) continue;

        if(Type != FileType_Directory)
            continue;

        formatex(Charset[SL_CD_SpriteFile], charsmax(Charset[SL_CD_SpriteFile]), "%s%s/chars.spr", CHARSETS_PATH, Charset[SL_CD_Name]);
        formatex(MapFile, charsmax(MapFile), "%s%s/map.txt", CHARSETS_PATH, Charset[SL_CD_Name]);

        if(
            !file_exists(MapFile)
            || !file_exists(Charset[SL_CD_SpriteFile])
        ) continue;

        Charset[SL_CD_Map] = ReadCharset(MapFile);
        if(Charset[SL_CD_Map] == Invalid_Trie){
            log_amx("[WARNING] Can`t read chars map file '%s'.", MapFile);
            continue;
        }

        Charset[SL_CD_SpriteIndex] = precache_model(Charset[SL_CD_SpriteFile]);

        if(CharsetsMap == Invalid_Trie)
            CharsetsMap = TrieCreate();
        TrieSetArray(CharsetsMap, Charset[SL_CD_Name], Charset, SprLett_CharsetData);

    }while(next_file(DirHandler, Charset[SL_CD_Name], charsmax(Charset[SL_CD_Name]), Type));

    close_dir(DirHandler);

    return CharsetsMap;
}

Trie:ReadCharset(const FileName[]){
    new F = fopen(FileName, "rt");
    if(!F)
        return Invalid_Trie;

    new Trie:Map = TrieCreate();
    while(!feof(F)){
        new Char[LETTER_SIZE], sNum[4], line[16];
        if(
            !fgets(F, line, charsmax(line))
            || !line[0]
        ) continue;
        
        if(parse(line, Char, charsmax(Char), sNum, charsmax(sNum)) != 2)
            continue;

        TrieSetCell(Map, Char, str_to_num(sNum));
    }
    fclose(F);
    return Map;
}