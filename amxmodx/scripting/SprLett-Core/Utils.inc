/**
 * Sprite Letters: Utils
 */

#include <amxmodx>
#include <reapi>

new Float:__TEMP_VEC[3];
#define copy_entvar_vec(%1,%2,%3) get_entvar(%1,%2,__TEMP_VEC);set_entvar(%3,%2,__TEMP_VEC)
#define copy_entvar_num(%1,%2,%3) set_entvar(%3,%2,get_entvar(%1,%2))

#define RgRemoveEnt(%1) set_entvar(%1,var_flags,get_entvar(%1,var_flags)|FL_KILLME)
#define IsEntRemoved(%1) (is_nullent(%1)||get_entvar(%1,var_flags)&FL_KILLME)
 
new const Float:VEC_UNIT[3] = {1.0, 1.0, 1.0};

/**
 * Возвращает одну букву из строки
 *
 * @param Str       Строка
 * @param Letter    Сюда будет записана буква
 * @param Next      Номер ячейки с которой начать читать букву. Будет увеличено на кол-во байт, занимаемых полученной буквой.
 *
 * @return          true если будет получена, иначе false
 */
bool:GetLetterFromStr(const Str[], Letter[LETTER_SIZE], &Next = 0){
    if(!Str[Next])
        return false;
    new bytes = get_char_bytes(Str[Next]);
    if(bytes <= 0){
        Letter[0] = ' ';
        Letter[1] = EOS;
        Next += 1;
        return true;
    }
    if(bytes >= LETTER_SIZE)
        bytes = LETTER_SIZE - 1;
    copy(Letter, bytes, Str[Next]);
    Next += bytes;
    return true;
}

SetEntSize(const Ent, const Float:Size){
    new Float:_Mins[3];
    VecMult(VEC_UNIT, -Size, _Mins);
    set_entvar(Ent, var_mins, _Mins);

    new Float:_Maxs[3];
    VecMult(VEC_UNIT, Size, _Maxs);
    set_entvar(Ent, var_maxs, _Maxs);

    new Float:Size[3];
    for(new i = 0; i < 3; i++)
        Size[i] = _Maxs[i] - _Mins[i];

    set_entvar(Ent, var_size, Size);
}

VecSumm(const Float:Vec1[3], const Float:Vec2[3], Float:Out[3]){
    for(new i = 0; i < 3; i++)
        Out[i] = Vec1[i] + Vec2[i];
}

VecMult(const Float:Vec[3], const Float:Mult, Float:Out[3]){
    for(new i = 0; i < 3; i++)
        Out[i] = Vec[i] * Mult;
}

// VecCopy(const Float:Src[3], Float:Dest[3]){
//     for(new i = 0; i < 3; i++)
//         Dest[i] = Src[i];
// }

TrieGetFirstArray(const Trie:t, any:Out[], len){
    new TrieIter:ti = TrieIterCreate(t);
    TrieIterGetArray(ti, Out, len);
    TrieIterDestroy(ti);
}
