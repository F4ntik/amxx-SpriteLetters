// Gaming_v1 is immutable: 157 original glyphs followed by ten colored icons.
#if defined _sprlett_gaming_included
    #endinput
#endif
#define _sprlett_gaming_included
#include <reapi>

stock const SL_GAMING_CHARSET[] = "Gaming_v1";
stock const SL_GAMING_FIRST_FRAME = 157;
stock const SL_GAMING_ALIASES[][] = {
    ":aim:", ":gun:", ":bomb:", ":shield:", ":skull:",
    ":fire:", ":trophy:", ":swords:", ":ct:", ":tt:"
};
stock const SL_GAMING_GLYPHS[][] = {"🎯", "🔫", "💣", "🛡", "💀", "🔥", "🏆", "⚔", "🔵", "🔴"};

stock SprLett_ExpandGamingAliases(Text[], const MaxLen){
    // Each replacement is no longer in UTF-8 bytes than its ASCII alias.
    for(new i; i < sizeof SL_GAMING_ALIASES; i++)
        replace_all(Text, MaxLen, SL_GAMING_ALIASES[i], SL_GAMING_GLYPHS[i]);
    replace_all(Text, MaxLen, "🛡️", "🛡");
    replace_all(Text, MaxLen, "⚔️", "⚔");
}

stock bool:SprLett_IsGamingLetter(const Ent){
    new Charset[32];
    get_entvar(Ent, var_noise, Charset, charsmax(Charset));
    return equal(Charset, SL_GAMING_CHARSET)
        && Float:get_entvar(Ent, var_frame) >= float(SL_GAMING_FIRST_FRAME);
}
