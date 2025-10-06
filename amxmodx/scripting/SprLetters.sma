/**
 * Sprite Letters
 */

#include <amxmodx>
#include <reapi>
#include <SprLetters>
#include "SprLett-Core/Ver"

#pragma semicolon 1

#define nullent 0
#define var_WordEnt var_owner
#define var_WordDir var_vuser1
#define var_WordText var_message
#define var_WordOffset var_fuser2
#define var_WordCharset var_noise
#define var_LetterSize var_fuser1
#define var_LetterText var_message
#define var_LetterCharset var_noise

// Marquee feature variables
#define var_MarqueeID var_iuser1
#define var_MarqueeWidth var_iuser2
#define var_MarqueeSpeed var_fuser3
#define var_MarqueeText var_netname
#define var_MarqueeOffset var_fuser4

#include "SprLett-Core/Utils"

// Helper function to trim leading/trailing spaces from a string
stock trim_string(string[], maxlength) {
    new len = strlen(string);
    // Trim trailing spaces
    for (new i = len - 1; i >= 0; i--) {
        if (string[i] == ' ') string[i] = EOS;
        else break;
    }
    len = strlen(string);
    // Trim leading spaces
    new start = 0;
    while (string[start] == ' ' && start < len) start++;
    if (start > 0) {
        format(string, maxlength, "%s", string[start]);
    }
}
stock MarqueeFillWindowString(dest[], const maxLen, marqueeWidth) {
    new limit = marqueeWidth;
    if (limit < 0) {
        limit = 0;
    } else if (limit > maxLen) {
        limit = maxLen;
    }
    for (new i = 0; i < limit; i++) {
        dest[i] = ' ';
    }
    dest[limit] = EOS;
}






new const PLUG_NAME[] = "Sprite Letters";
#define PLUG_VER SPRLETT_VERSION

// Marquee feature default values
#define DEFAULT_MARQUEE_WIDTH 10
#define DEFAULT_MARQUEE_SPEED 5.0
#define MARQUEE_UPDATE_INTERVAL 0.1 // For 10 updates per second

new const INFO_TARGET_CLASSNAME[] = "info_target";
new const LETTER_CLASSNAME[] = "SprLetters_Letter";
new const WORD_CLASSNAME[] = "SprLetters_Word";

new CHARSET_DEFAULT_NAME[32] = "Default";

#define IsLetter(%1) FClassnameIs(%1,LETTER_CLASSNAME)
#define IsWord(%1) FClassnameIs(%1,WORD_CLASSNAME)
#define IsWordLetter(%1) (IsLetter(%1)&&IsWord(get_entvar(%1,var_WordEnt)))
#define IsWordOrLetter(%1) (IsLetter(%1)||IsWord(%1))

new SprParams[SprLett_Params] = {
    1.0,                // SL_P_Scale
    255.0,              // SL_P_Alpha
    9.0,                // SL_P_Size
    18.0,               // SL_P_Offset
    kRenderTransAdd,    // SL_P_RenderMode
};
new Float:SprWordDir[3] = {1.0, 0.0, 0.0};
new Float:SprAngles[3] = {0.0, 0.0, 0.0};
new Float:SprColor[3] = {255.0, 255.0, 255.0};
new SprCharset[SprLett_CharsetData];

new bool:EditMode = false;
new Trie:Charsets;

public plugin_precache(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
    register_library(SL_LIB_NAME);

    Charsets = LoadCharsets();
    if(Charsets == Invalid_Trie)
        set_fail_state("[ERROR] Charsets not loaded.");

    if(!TrieGetArray(Charsets, "Default", SprCharset, SprLett_CharsetData))
        TrieGetFirstArray(Charsets, SprCharset, SprLett_CharsetData);
    copy(CHARSET_DEFAULT_NAME, charsmax(CHARSET_DEFAULT_NAME), SprCharset[SL_CD_Name]);
}

public plugin_init(){
    set_task(MARQUEE_UPDATE_INTERVAL, "Marquee_Think", 0, "", 0, "b"); // Register marquee think task

    // Register server commands for marquee control
    register_srvcmd("sl_marquee_text", "Cmd_Marquee_Text", -1, "Sets text for marquees by ID. Usage: sl_marquee_text <id> <text>");
    register_srvcmd("sl_marquee_width", "Cmd_Marquee_Width", -1, "Sets width for marquees by ID. Usage: sl_marquee_width <id> <width>");
    register_srvcmd("sl_marquee_speed", "Cmd_Marquee_Speed", -1, "Sets speed for marquees by ID. Usage: sl_marquee_speed <id> <speed>");
    register_srvcmd("sl_marquee_count_ids", "Cmd_Marquee_Count_IDs", -1, "Counts unique active marquee IDs.");

    server_print(
        "[%s v%s] %d charsets loaded. Default charset: '%s'.",
        PLUG_NAME, PLUG_VER,
        TrieGetSize(Charsets),
        SprCharset[SL_CD_Name]
    );
}
stock CountWordLetters(const WordEnt) {
    if (!IsWord(WordEnt))
        return 0;

    new Iterator = WordEnt;
    new count = 0;

    while (WordIterNext(Iterator) != nullent)
        count++;

    return count;
}

stock SyncMarqueeLetters(const WordEnt, const displayString[], const marqueeWidth) {
    if (!IsWord(WordEnt))
        return;

    new CharsetName[32];
    get_entvar(WordEnt, var_WordCharset, CharsetName, charsmax(CharsetName));

    new Charset[SprLett_CharsetData];
    GetCharset(CharsetName, Charset);

    new Iterator = WordEnt;
    new Next = 0;
    new Letter[LETTER_SIZE];
    new currentLetter[LETTER_SIZE];
    new bool:exhausted = false;

    for (new windowPos = 0; windowPos < marqueeWidth; windowPos++) {
        new LetterEnt = WordIterNext(Iterator);
        if (LetterEnt == nullent)
            break;

        if (!exhausted && GetLetterFromStr(displayString, Letter, Next)) {
        } else {
            exhausted = true;
            Letter[0] = ' ';
            Letter[1] = EOS;
        }

        get_entvar(LetterEnt, var_LetterText, currentLetter, charsmax(currentLetter));
        if (!equal(currentLetter, Letter)) {
            set_entvar(LetterEnt, var_LetterText, Letter);
            SetLetterCharset(LetterEnt, Charset);
        }
    }
}


/**
 * Перключает режим редактирования букв/слов
 *
 * @param State В какое состояние переключиться
 *
 * @noreturn
 */
EditToggle(const bool:State){
    if(State == EditMode)
        return;
    EditMode = State;
    
    new Ent = -1;
    while((Ent = rg_find_ent_by_class(Ent, LETTER_CLASSNAME)) > 0){
        if(IsEntRemoved(Ent))
            continue;
        set_entvar(Ent, var_solid, EditMode ? SOLID_BBOX : SOLID_NOT);
    }
}

/**
 * Инициализация слова.
 *
 * @note Данная функция не строит слово. Для построения слова используется функция BuildWord
 *
 * @param Word   Слово, которое надо вывести
 * @param Origin Начальные коорды
 *
 * @return  Индекс ентити слова
 */
InitWord(const Word[], const Float:Origin[3], MarqueeID = 0, MarqueeWidth = 0, Float:MarqueeSpeed = 0.0){ // Added marquee params with defaults
    new WordEnt = rg_create_entity(INFO_TARGET_CLASSNAME);
    if(is_nullent(WordEnt))
        return nullent;
        
    set_entvar(WordEnt, var_classname, WORD_CLASSNAME);

    set_entvar(WordEnt, var_origin, Origin);
    set_entvar(WordEnt, var_angles, SprAngles);
    set_entvar(WordEnt, var_scale, SprParams[SL_P_Scale]);
    set_entvar(WordEnt, var_LetterSize, SprParams[SL_P_Size]);
    set_entvar(WordEnt, var_WordOffset, SprParams[SL_P_Offset]); // This is inter-letter spacing
    set_entvar(WordEnt, var_WordDir, SprWordDir);
    set_entvar(WordEnt, var_SL_RotateMode, SL_ROTATE_WORD);

    // Set original text to var_WordText (for display) and var_MarqueeText (for full source)
    if (MarqueeWidth > 0) {
        new initialWindow[WORD_MAX_LENGTH];
        MarqueeFillWindowString(initialWindow, charsmax(initialWindow), MarqueeWidth);
        set_entvar(WordEnt, var_WordText, initialWindow);
    } else {
        set_entvar(WordEnt, var_WordText, Word); // Current displayed portion
    }
    set_entvar(WordEnt, var_MarqueeText, Word); // Full text for marquee

    set_entvar(WordEnt, var_WordCharset, SprCharset[SL_CD_Name]);

    set_entvar(WordEnt, var_renderamt, SprParams[SL_P_Alpha]);
    set_entvar(WordEnt, var_rendercolor, SprColor);
    set_entvar(WordEnt, var_rendermode, SprParams[SL_P_RenderMode]);

    // Store marquee properties
    if (MarqueeWidth > 0) { // Only set marquee properties if width is positive
        set_entvar(WordEnt, var_MarqueeID, MarqueeID);
        set_entvar(WordEnt, var_MarqueeWidth, MarqueeWidth);
        if (MarqueeSpeed <= 0.0) {
            MarqueeSpeed = DEFAULT_MARQUEE_SPEED;
        }
        set_entvar(WordEnt, var_MarqueeSpeed, MarqueeSpeed);
        set_entvar(WordEnt, var_MarqueeOffset, float(MarqueeWidth)); // Start from the right edge
    } else { // Ensure they are zeroed out if not a marquee to avoid issues with reused entities
        set_entvar(WordEnt, var_MarqueeID, 0);
        set_entvar(WordEnt, var_MarqueeWidth, 0);
        set_entvar(WordEnt, var_MarqueeSpeed, 0.0);
        set_entvar(WordEnt, var_MarqueeOffset, 0.0);
    }

    return WordEnt;
}

public Marquee_Think() {
    new ent = -1;
    // Loop through all entities that are potential "Word" entities
    while((ent = rg_find_ent_by_class(ent, WORD_CLASSNAME)) > 0) { 
        // Ensure it's specifically a word entity managed by this plugin. 
        // IsWord also checks classname, but good for logical clarity.
        if(!IsWord(ent)) 
            continue;

        new marqueeWidth = get_entvar(ent, var_MarqueeWidth);
        if (marqueeWidth <= 0) // Not a marquee or invalid width
            continue;

        new Float:speed = get_entvar(ent, var_MarqueeSpeed);
        if (speed <= 0.0) // Marquee is paused or has invalid speed
            continue;

        new Float:currentOffset = get_entvar(ent, var_MarqueeOffset);
        
        new fullText[WORD_MAX_LENGTH];
        get_entvar(ent, var_MarqueeText, fullText, charsmax(fullText));

        new fullText_EffectiveCharLen = 0;
        new scanIdx = 0;
        while(fullText[scanIdx] != EOS) {
            new charBytes = get_char_bytes(fullText[scanIdx]);
            if (charBytes == 0) { // Should ideally not happen with valid strings
                scanIdx++; // Skip to prevent infinite loop on malformed string
                continue;
            }
            fullText_EffectiveCharLen++;
            scanIdx += charBytes;
            if (scanIdx >= WORD_MAX_LENGTH) break; // Safety break if string is somehow not EOS-terminated
        }
        
        // If there's no text to scroll, UpdateMarquee will handle ensuring the display is empty.
        // This check is mostly to prevent division by zero or weirdness if speed calculation depended on length.
        if (fullText_EffectiveCharLen == 0) {
            UpdateMarquee(ent);
            continue;
        }

        // Update offset based on speed and interval
        // Speed is in "characters per second". Interval is in seconds.
        currentOffset -= speed * MARQUEE_UPDATE_INTERVAL;

        // If the text has fully scrolled past the left edge
        // currentOffset represents the position of fullText[0] relative to the left window edge.
        // When currentOffset = 0, fullText[0] is at the left edge.
        // When currentOffset = -1, fullText[0] is one char position to the left of the window.
        // So, when currentOffset < -fullText_EffectiveCharLen, the entire string has passed.
        if (currentOffset < -float(fullText_EffectiveCharLen)) {
            currentOffset = float(marqueeWidth); // Reset to starting position (fullText[0] is at the right edge of the window)
        }
        
        set_entvar(ent, var_MarqueeOffset, currentOffset);
        UpdateMarquee(ent); // Update the visible part of the word
    }
}

/**
 * Обновляет отображаемый текст для бегущей строки на основе смещения.
 * Это основная функция, отвечающая за эффект "бегущей строки".
 * Она конструирует видимую часть текста на основе полного текста и текущего смещения.
 * currentOffsetF: позиция fullText[0] относительно левого края окна.
 * Положительные значения: fullText[0] смещен вправо от левого края окна (еще не полностью виден).
 * 0: fullText[0] находится у левого края окна.
 * Отрицательные: fullText[0] смещен влево от левого края окна (уже частично или полностью проскроллен).
 *
 * @param WordEnt Индекс ентити слова (должно быть марки).
 *
 * @noreturn
 */
UpdateMarquee(const WordEnt) {
    if (!IsWord(WordEnt))
        return;

    new marqueeWidth = get_entvar(WordEnt, var_MarqueeWidth);
    if (marqueeWidth <= 0)
        return;

    new renderWidth = marqueeWidth;
    if (renderWidth > WORD_MAX_LENGTH - 1)
        renderWidth = WORD_MAX_LENGTH - 1;

    if (renderWidth <= 0)
        return;

    new letterCount = CountWordLetters(WordEnt);
    if (letterCount != renderWidth) {
        new placeholder[WORD_MAX_LENGTH];
        MarqueeFillWindowString(placeholder, charsmax(placeholder), renderWidth);
        set_entvar(WordEnt, var_WordText, placeholder);
        DestroyWord(WordEnt);
        BuildWord(WordEnt);
        letterCount = CountWordLetters(WordEnt);
        if (letterCount != renderWidth) {
            return;
        }
    }

    new Float:currentOffsetF = get_entvar(WordEnt, var_MarqueeOffset);
    new fullText[WORD_MAX_LENGTH];
    get_entvar(WordEnt, var_MarqueeText, fullText, charsmax(fullText));

    new fullText_EffectiveCharLen = 0;
    for(new scanIdx = 0; fullText[scanIdx] != EOS; ) {
        new charBytes = get_char_bytes(fullText[scanIdx]);
        if(charBytes == 0) {
            scanIdx++;
            continue;
        }
        fullText_EffectiveCharLen++;
        scanIdx += charBytes;
    }

    if (fullText_EffectiveCharLen == 0) {
        new placeholder[WORD_MAX_LENGTH];
        MarqueeFillWindowString(placeholder, charsmax(placeholder), renderWidth);
        set_entvar(WordEnt, var_WordText, placeholder);
        SyncMarqueeLetters(WordEnt, placeholder, renderWidth);
        return;
    }

    new actualDisplayString[WORD_MAX_LENGTH];
    new actualDisplayLen = 0;
    new roundedOffset = floatround(currentOffsetF);

    for (new windowPos = 0; windowPos < renderWidth; ++windowPos) {
        if (actualDisplayLen >= WORD_MAX_LENGTH - 1) {
            break;
        }

        new charIndexInFullText = windowPos - roundedOffset;

        if (charIndexInFullText >= 0 && charIndexInFullText < fullText_EffectiveCharLen) {
            new bytePosInFullText = 0;
            new currentActualCharIndex = 0;

            while (fullText[bytePosInFullText] != EOS && currentActualCharIndex < charIndexInFullText) {
                new charBytesScanned = get_char_bytes(fullText[bytePosInFullText]);
                if (charBytesScanned == 0) {
                    bytePosInFullText++;
                    continue;
                }
                bytePosInFullText += charBytesScanned;
                currentActualCharIndex++;
            }

            if (fullText[bytePosInFullText] != EOS && currentActualCharIndex == charIndexInFullText) {
                new charBytesToCopy = get_char_bytes(fullText[bytePosInFullText]);
                if (charBytesToCopy > 0 && actualDisplayLen + charBytesToCopy < WORD_MAX_LENGTH) {
                    for (new k = 0; k < charBytesToCopy; ++k) {
                        actualDisplayString[actualDisplayLen + k] = fullText[bytePosInFullText + k];
                    }
                    actualDisplayLen += charBytesToCopy;
                } else if (actualDisplayLen < WORD_MAX_LENGTH - 1) {
                    actualDisplayString[actualDisplayLen++] = ' ';
                } else {
                    break;
                }
            } else {
                actualDisplayString[actualDisplayLen++] = ' ';
            }
        } else {
            actualDisplayString[actualDisplayLen++] = ' ';
        }
    }

    actualDisplayString[actualDisplayLen] = EOS;

    new currentDisplayedText[WORD_MAX_LENGTH];
    get_entvar(WordEnt, var_WordText, currentDisplayedText, charsmax(currentDisplayedText));

    if (!equal(currentDisplayedText, actualDisplayString)) {
        set_entvar(WordEnt, var_WordText, actualDisplayString);
    }

    SyncMarqueeLetters(WordEnt, actualDisplayString, renderWidth);
}

BuildWord(const WordEnt){
    if(!IsWord(WordEnt))
        return;
    
    set_entvar(WordEnt, var_effects, EF_NODRAW);
    set_entvar(WordEnt, var_flags, FL_DORMANT);
    set_entvar(WordEnt, var_WordEnt, WordEnt);

    new Float:DirAngles[3];
    get_entvar(WordEnt, var_WordDir, DirAngles);

    new SprLett_RotateMode:RotateMode = SprLett_RotateMode:get_entvar(WordEnt, var_SL_RotateMode);

    new Float:Angles[3];
    new Float:StepVec[3];
    if(RotateMode == SL_ROTATE_WORD){
        get_entvar(WordEnt, var_angles, Angles);
        angle_vector(Angles, ANGLEVECTOR_RIGHT, StepVec);
    } else {
        angle_vector(DirAngles, ANGLEVECTOR_FORWARD, StepVec);
    }

    new Float:WordOffset = Float:get_entvar(WordEnt, var_WordOffset);
    new Float:OffsetVec[3];
    VecMult(StepVec, WordOffset, OffsetVec);

    new Word[WORD_MAX_LENGTH];
    get_entvar(WordEnt, var_WordText, Word, charsmax(Word));

    new Float:Origin[3];
    get_entvar(WordEnt, var_origin, Origin);

    new Charset[SprLett_CharsetData], CharsetName[32];
    get_entvar(WordEnt, var_WordCharset, CharsetName, charsmax(CharsetName));
    GetCharset(CharsetName, Charset);

    new bool:isMarquee = (get_entvar(WordEnt, var_MarqueeWidth) > 0);
    new PrevLetterEnt = WordEnt;
    new Letter[LETTER_SIZE], Next = 0;
    while(GetLetterFromStr(Word, Letter, Next)){
        if(!isMarquee && equal(Letter, " ")){
            VecSumm(Origin, OffsetVec, Origin);
            continue;
        }

        new LetterEnt = CreateLetter(Letter, Origin, true);
        if(is_nullent(LetterEnt)){
            log_amx("[WARNING] Can`t create letter '%s' for word.", Letter);
            VecSumm(Origin, OffsetVec, Origin);
            continue;
        }

        MakeWordLetter(WordEnt, LetterEnt);
        SetLetterCharset(LetterEnt, Charset);
        set_entvar(PrevLetterEnt, var_chain, LetterEnt);
        PrevLetterEnt = LetterEnt;

        VecSumm(Origin, OffsetVec, Origin);
    }

    // Замыкание списка
    set_entvar(PrevLetterEnt, var_chain, WordEnt);
}

/**
 * Настраивает букву исходя из параметров слова
 *
 * @param WordEnt   Индекс ентити слова
 * @param LetterEnt Индекс ентити буквы
 *
 * @noreturn
 */
MakeWordLetter(const WordEnt, const LetterEnt){
    SetEntSize(LetterEnt, get_entvar(WordEnt, var_LetterSize));
    copy_entvar_num(WordEnt, var_renderamt, LetterEnt);
    copy_entvar_num(WordEnt, var_rendermode, LetterEnt);
    copy_entvar_num(WordEnt, var_scale, LetterEnt);
    copy_entvar_vec(WordEnt, var_angles, LetterEnt);
    copy_entvar_vec(WordEnt, var_rendercolor, LetterEnt);

    set_entvar(LetterEnt, var_WordEnt, WordEnt);
}

/**
 * Получает индекс ентити слова
 *
 * @param Ent Индекс ентити буквы/слова
 *
 * @return Индекс ентити слова или 0 если слово не найдено
 */
GetWord(const Ent){
    if(IsWord(Ent))
        return Ent;
    if(IsWordLetter(Ent))
        return get_entvar(Ent, var_WordEnt);
    return nullent;
}

/**
 * Создаёт букву спрайтом
 *
 * @param Letter  Буква
 * @param Origin  Координаты
 * @param ForWord Если true, то не задаёт некотоыре параметры ентити
 *
 * @return          Индекс ентити созданной буквы
 */
CreateLetter(const Letter[LETTER_SIZE], const Float:Origin[3], const bool:ForWord = false){
    new Ent = rg_create_entity(INFO_TARGET_CLASSNAME);
    if(is_nullent(Ent))
        return nullent;

    set_entvar(Ent, var_classname, LETTER_CLASSNAME);
    set_entvar(Ent, var_movetype, MOVETYPE_FLY);
    set_entvar(Ent, var_solid, EditMode ? SOLID_BBOX : SOLID_NOT);
    set_entvar(Ent, var_origin, Origin);
    set_entvar(Ent, var_LetterText, Letter);

    if(!ForWord){
        set_entvar(Ent, var_rendermode, SprParams[SL_P_RenderMode]);
        set_entvar(Ent, var_rendercolor, SprColor);
        SetLetterCharset(Ent, SprCharset);
        set_entvar(Ent, var_renderamt, SprParams[SL_P_Alpha]);
        SetEntSize(Ent, SprParams[SL_P_Size] / 2);
        set_entvar(Ent, var_angles, SprAngles);
        set_entvar(Ent, var_scale, SprParams[SL_P_Scale]);
    }

    return Ent;
}

/**
 * Устанавливает набор символов для буквы
 *
 * @param LetterEnt Индекс ентити буквы
 * @param Charset   Новый набор символов
 *
 * @noreturn
 */
SetLetterCharset(const LetterEnt, const Charset[SprLett_CharsetData]){
    set_entvar(LetterEnt, var_model, Charset[SL_CD_SpriteFile]);
    set_entvar(LetterEnt, var_modelindex, Charset[SL_CD_SpriteIndex]);
    set_entvar(LetterEnt, var_LetterCharset, Charset[SL_CD_Name]);

    new Letter[LETTER_SIZE];
    get_entvar(LetterEnt, var_LetterText, Letter, charsmax(Letter));
    set_entvar(LetterEnt, var_frame, float(GetCharNum(Letter, Charset[SL_CD_Map])));
}

/**
 * Удаляет все буквы слова
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
DestroyWord(const WordEnt){
    if(!IsWord(WordEnt))
        return;
    new LetterEnt = WordEnt;
    while(WordIterNext(LetterEnt) != nullent)
        RemoveLetter(LetterEnt);
    set_entvar(WordEnt, var_chain, nullent);
}

/**
 * Удаляет слово
 *
 * @param Ent Индекс ентити слова или любой буквы слова
 *
 * @noreturn
 */
RemoveWord(Ent){
    new WordEnt = GetWord(Ent);
    if(WordEnt == nullent)
        return;
    DestroyWord(WordEnt);
    RgRemoveEnt(WordEnt);
}

/**
 * Удаляет букву
 *
 * @param LetterEnt Ентити буквы
 *
 * @noreturn
 */
RemoveLetter(const LetterEnt){
    if(!IsLetter(LetterEnt))
        return;
    RgRemoveEnt(LetterEnt);
}

/**
 * Получение номера символа из карты символов
 *
 * @note Если указанный символ не найден, функция вернёт номер первого символа (0)
 *
 * @param Char Символ
 * @param Map  Карта символов. Если не укзана, берётся из текущего набора символов
 *
 * @return Порядковый номер символа
 */
GetCharNum(const Char[], const Trie:Map = Invalid_Trie){
    new Num;
    return TrieGetCell(Map == Invalid_Trie ? SprCharset[SL_CD_Map] : Map, Char, Num) ? Num-1 : 0;
}

/**
 * Получение набора символов по его названию
 *
 * @note Если набор символов не найден, будет возвращён первый загруженный набор или Default
 *
 * @param Name    Название набора символов
 * @param Charset Полученный набор символов
 *
 * @noreturn
 */
bool:GetCharset(const Name[], Charset[SprLett_CharsetData]){
    if(!TrieGetArray(Charsets, Name, Charset, SprLett_CharsetData)){
        TrieGetArray(Charsets, CHARSET_DEFAULT_NAME, Charset, SprLett_CharsetData);
        return false;
    }
    return true;
}

/**
 * Возвращает следующий элемент слова
 *
 * @param Iterator Индекс ентити слова или буквы
 *
 * @return  Индекс ентити буквы или 0 если пройдены все буквы
 */
WordIterNext(&Iterator){
    if(!IsWordOrLetter(Iterator))
        return Iterator = nullent;

    Iterator = get_entvar(Iterator, var_chain);
    if(
        IsWord(Iterator) // Если следующий элемент слово - все буквы пройдены
        || !IsLetter(Iterator)
    ) Iterator = nullent;

    return Iterator;
}

// Server Command Handlers for Marquee Control

public Cmd_Marquee_Text(id, level, cid) {
    if (read_argc() < 3) {
        console_print(id, "Usage: sl_marquee_text <id> <text>");
        return PLUGIN_HANDLED;
    }

    new targetId_str[32];
    read_argv(1, targetId_str, charsmax(targetId_str));
    new targetId = str_to_num(targetId_str);

    if (targetId == 0) {
        console_print(id, "Error: Marquee ID cannot be 0 for this command.");
        return PLUGIN_HANDLED;
    }

    new text[WORD_MAX_LENGTH]; text[0] = EOS;
    new arg[128]; 

    for (new i = 2; i < read_argc(); i++) {
        read_argv(i, arg, charsmax(arg));
        add(text, charsmax(text), arg);
        if (i < read_argc() - 1) {
            add(text, charsmax(text), " ");
        }
    }
    trim_string(text, charsmax(text));

    new bool:found = false;
    new ent = -1;
    while((ent = rg_find_ent_by_class(ent, WORD_CLASSNAME)) > 0) {
        if(!IsWord(ent)) continue;
        if (get_entvar(ent, var_MarqueeID) == targetId && get_entvar(ent, var_MarqueeWidth) > 0) {
            set_entvar(ent, var_MarqueeText, text);
            set_entvar(ent, var_MarqueeOffset, float(get_entvar(ent, var_MarqueeWidth))); 
            UpdateMarquee(ent);
            found = true;
        }
    }

    if (found) {
        console_print(id, "Marquee ID %d text set to: ^"%s^"", targetId, text);
    } else {
        console_print(id, "No active marquee found with ID %d.", targetId);
    }
    return PLUGIN_HANDLED;
}

public Cmd_Marquee_Width(id, level, cid) {
    if (read_argc() != 3) {
        console_print(id, "Usage: sl_marquee_width <id> <width>");
        return PLUGIN_HANDLED;
    }

    new targetId_str[32];
    read_argv(1, targetId_str, charsmax(targetId_str));
    new targetId = str_to_num(targetId_str);
    
    new width_str[32];
    read_argv(2, width_str, charsmax(width_str));
    new width = str_to_num(width_str);

    if (targetId == 0 && width != 0) {
         console_print(id, "Error: Marquee ID cannot be 0 unless setting width to 0.");
         return PLUGIN_HANDLED;
    }
    if (width < 0) width = 0;

    new bool:found_any = false;
    new ent = -1;
    while((ent = rg_find_ent_by_class(ent, WORD_CLASSNAME)) > 0) {
        if(!IsWord(ent)) continue;

        if (get_entvar(ent, var_MarqueeID) == targetId || (targetId == 0 && width == 0) ) {
            new oldWidth = get_entvar(ent, var_MarqueeWidth);
            set_entvar(ent, var_MarqueeWidth, width);

            if (width > 0) {
                if (oldWidth <= 0) {
                    set_entvar(ent, var_MarqueeOffset, float(width));
                    if (get_entvar(ent, var_MarqueeSpeed) <= 0.0) {
                        set_entvar(ent, var_MarqueeSpeed, DEFAULT_MARQUEE_SPEED);
                    }
                }
                if (oldWidth != width) {
                    new effectiveWidth = width;
                    if (effectiveWidth > WORD_MAX_LENGTH - 1) {
                        effectiveWidth = WORD_MAX_LENGTH - 1;
                    }
                    new placeholder[WORD_MAX_LENGTH];
                    MarqueeFillWindowString(placeholder, charsmax(placeholder), effectiveWidth);
                    set_entvar(ent, var_WordText, placeholder);
                    DestroyWord(ent);
                    BuildWord(ent);
                }
                UpdateMarquee(ent);
            } else if (oldWidth > 0) {
                set_entvar(ent, var_WordText, "");
                DestroyWord(ent);
                BuildWord(ent);
            }
            found_any = true;
        }
    }
    if(found_any){
        if(targetId == 0 && width == 0) console_print(id, "All marquees disabled by setting width to 0.");
        else console_print(id, "Marquee ID %d width set to %d.", targetId, width);
    } else {
        console_print(id, "No marquee found with ID %d.", targetId);
    }
    return PLUGIN_HANDLED;
}


public Cmd_Marquee_Speed(id, level, cid) {
    if (read_argc() != 3) {
        console_print(id, "Usage: sl_marquee_speed <id> <speed>");
        return PLUGIN_HANDLED;
    }

    new targetId_str[32];
    read_argv(1, targetId_str, charsmax(targetId_str));
    new targetId = str_to_num(targetId_str);

    new speed_str[32];
    read_argv(2, speed_str, charsmax(speed_str));
    new Float:speed = str_to_float(speed_str);

    if (targetId == 0) {
        console_print(id, "Error: Marquee ID cannot be 0 for this command.");
        return PLUGIN_HANDLED;
    }

    new bool:found = false;
    new ent = -1;
    while((ent = rg_find_ent_by_class(ent, WORD_CLASSNAME)) > 0) {
        if(!IsWord(ent)) continue;
        if (get_entvar(ent, var_MarqueeID) == targetId && get_entvar(ent, var_MarqueeWidth) > 0) {
            set_entvar(ent, var_MarqueeSpeed, speed);
            found = true;
        }
    }

    if (found) {
        console_print(id, "Marquee ID %d speed set to %.2f.", targetId, speed);
    } else {
        console_print(id, "No active marquee found with ID %d.", targetId);
    }
    return PLUGIN_HANDLED;
}


public Cmd_Marquee_Count_IDs(id, level, cid) {
    new Trie:uniqueIDs = TrieCreate();
    if (uniqueIDs == Invalid_Trie) {
        console_print(id, "Error: Could not create Trie for counting IDs.");
        return PLUGIN_HANDLED;
    }
    new count = 0;
    new ent = -1;

    while((ent = rg_find_ent_by_class(ent, WORD_CLASSNAME)) > 0) {
        if(!IsWord(ent)) continue;

        new marqueeId = get_entvar(ent, var_MarqueeID);
        new marqueeWidth = get_entvar(ent, var_MarqueeWidth);

        // Only count active marquees with a non-zero ID
        if (marqueeWidth > 0 && marqueeId != 0) {
            new sMarqueeId[12];
            num_to_str(marqueeId, sMarqueeId, charsmax(sMarqueeId));
            if (!TrieKeyExists(uniqueIDs, sMarqueeId)) {
                TrieSetCell(uniqueIDs, sMarqueeId, 1); // Value doesn't matter, just key presence
                count++;
            }
        }
    }

    console_print(id, "Active unique marquee IDs: %d", count);
    TrieDestroy(uniqueIDs);
    return PLUGIN_HANDLED;
}

#include "SprLett-Core/Natives"
#include "SprLett-Core/Configs"
