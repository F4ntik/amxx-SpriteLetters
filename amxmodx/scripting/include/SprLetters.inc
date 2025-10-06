#if defined _sprletters_included
	#endinput
#endif
#define _sprletters_included

stock const SL_LIB_NAME[] = "SpriteLetters";

#define LETTER_SIZE 8
#define WORD_MAX_LENGTH 128

#define var_SL_WordEnt var_owner
#define var_SL_WordDir var_vuser1
#define var_SL_WordText var_message
#define var_SL_WordOffset var_fuser2
#define var_SL_WordCharset var_noise
#define var_SL_LetterSize var_fuser1
#define var_SL_LetterText var_message
#define var_SL_LetterCharset var_noise
#define var_SL_MarqueeID var_iuser1
#define var_SL_MarqueeWidth var_iuser2
#define var_SL_MarqueeSpeed var_fuser3
#define var_SL_MarqueeText var_netname
#define var_SL_MarqueeOffset var_fuser4

#define var_SL_WordSaveId var_iuser1

#define SprLett_CreateWord(%1) SprLett_BuildWord(SprLett_InitWord(%1))
#define SprLett_RebuildWord(%1) SprLett_DestroyWord(%1);SprLett_BuildWord(%1)

enum _:SprLett_CharsetData {
    SL_CD_Name[32],
    SL_CD_SpriteFile[PLATFORM_MAX_PATH],
    SL_CD_SpriteIndex,
    Trie:SL_CD_Map,
}

enum SprLett_WhatIs{
    /**
     * Слово
     */
    SL_Is_Word = 0,

    /**
     * Буква
     */
    SL_Is_Letter,

    /**
     * Буква в составе слова
     */
    SL_Is_WordLetter,
}

/**
 * Числовые параметры
 */
enum _:SprLett_Params{
    /**
     * Масштаб спрайтов
     */
    Float:SL_P_Scale = 0,
    
    /**
     * Непрозрачность спрайтов
     */
    Float:SL_P_Alpha,
    
    /**
     * Физический размер букв.
     */
    Float:SL_P_Size,
    
    /**
     * Расстояние между буквами.
     */
    Float:SL_P_Offset,
    
    /**
     * Режим рендера букв.
     */
    SL_P_RenderMode,
}

/**
 * Векторные параметры
 */
enum _:SprLett_ParamsVec{
    /**
     * Направление написания слов
     */
    SL_P_WordDir = _:SprLett_Params,
    
    /**
     * Направление букв
     */
    SL_P_Angles,
    
    /**
     * Цвет рендера букв
     */
    SL_P_Color,
}

/**
 * Строковые параметры
 */
enum _:SprLett_ParamsStr{
    /**
     * Название набора символов
     */
    SL_P_Charset = _:SprLett_ParamsVec,
}

/* Core */

/**
 * Получает индекс ентити слова
 *
 * @param Ent Индекс ентити буквы/слова
 *
 * @return Индекс ентити слова или 0 если слово не найдено
 */
native SprLett_GetWord(const Ent);

/**
 * Возвращает следующий элемент слова
 *
 * @param Iterator Индекс ентити слова или буквы
 *
 * @return  Индекс ентити буквы или 0 если пройдены все буквы
 */
native SprLett_WordIterNext(&Iterator);

/**
 * Является ли ентити буквой/словом
 *
 * @param Ent Индекс ентити
 * @param Is  Тип проверки (см. enum SprLett_WhatIs)
 *
 * @return true если ентити является тем, что указано во втором параметре
 */
native SprLett_Is(const Ent, const SprLett_WhatIs:Is);

/**
 * Удаление слова.
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
native SprLett_RemoveWord(const WordEnt);

/**
 * Переключение режима редактирования букв.
 *
 * @note По сути это включение/выключение коллизии букв
 *
 * @param State true - включить режим редактирования (Коллизии), false - выключить
 *
 * @noreturn
 */
native SprLett_SetEditMode(const bool:State = true);

/**
 * Получение текущего состояния режима редактирования.
 *
 * @return true, если режим редактирования включен, инче false;
 */
native bool:SprLett_GetEditMode();

/**
 * Создаёт букву.
 *
 * @param Letter Буква
 * @param Origin Координаты
 * @param Angles Направление (Если спрайт ориентированный)
 *
 * @return Индекс ентити созданной буквы. 0, если что-то пошло не так
 */
native SprLett_CreateLetter(const Letter[LETTER_SIZE], const Float:Origin[3] = {0.0, 0.0, 0.0});

/**
 * Инициализация слова.
 *
 * @note Данная функция не строит слово. Для построения слова используется натив SprLett_BuildWord
 *
 * @param Word   Слово, которое надо вывести
 * @param Origin Начальные координаты слова
 *
 * @return  Индекс ентити слова
 */
native SprLett_InitWord(const Word[WORD_MAX_LENGTH] = "", const Float:Origin[3] = {0.0, 0.0, 0.0});

/**
 * Строит слово исходя из параметров ентити слова
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
native SprLett_BuildWord(const WordEnt);

/**
 * Удаляет все буквы слова
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
native SprLett_DestroyWord(const WordEnt);

/**
 * Изменяет параметры создаваемых спрайтов.
 *
 * @note Перечисление параметров: SprLett_Params*
 * @note Ex: SprLett_SetParams(SL_P_Scale, 1.5, SL_P_Alpha, 255.0)
 *
 * @return true если параметр успешно изменён, иначе false
 */
native bool:SprLett_SetParams(any:...);

/**
 * Получение текущих значений параметров создания слов.
 *
 * @note Ex: new LetterSize = SprLett_GetParam(SL_P_Size);
 * @note Ex: new Float:WordDir[3]; SprLett_GetParam(SL_P_WordDir, WordDir);
 * @note Ex: new Charset[32]; SprLett_GetParam(SL_P_Charset, Charset, charsmax(Charset));
 *
 * @return Для числовых значений - значение параметра. Для остальных кол-во записанных в массив ячеек.
 */
native any:SprLett_GetParam(const {SprLett_Params, SprLett_ParamsVec, SprLett_ParamsStr}:Param, any:...);

/* Saver */

/**
 * Сохранение слова на карте.
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
native SprLett_SaveWord(const WordEnt);

/**
 * Удаление сохранения слова.
 *
 * @param WordEnt Индекс ентити слова
 *
 * @noreturn
 */
native SprLett_UnSaveWord(const WordEnt);