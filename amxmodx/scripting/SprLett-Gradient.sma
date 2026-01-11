#include <amxmodx>
#include <reapi>
#include <SprLetters>

new const Float:RGBFrom[3] = {0.0, 255.0, 0.0};
new const Float:RGBTo[3] = {0.0, 0.0, 255.0};

public plugin_init(){
    register_plugin("[SprLett] Test Gradient", "1.0.0", "ArKaNeMaN");

    register_clcmd("slgradient", "@Cmd_Gradient");
}

@Cmd_Gradient(const UserId){
    new Ent;
    get_user_aiming(UserId, Ent);
    
    if((Ent = SprLett_GetWord(Ent)) == 0){
        client_print(UserId, print_center, "Слово не найдено");
        return;
    }
    
    new Len = GetWordLen(Ent);
    if(Len <= 1){
        if(Len == 1){
            new It = Ent;
            if(SprLett_WordIterNext(It))
                set_entvar(It, var_rendercolor, RGBFrom);
        }
        return;
    }
    new Float:RGBDelta[3], Float:RGBCurrent[3];
    for(new i = 0; i < 3; i++)
        RGBDelta[i] = (RGBTo[i] - RGBFrom[i]) / (Len - 1);
    RGBCurrent = RGBFrom;

    while(SprLett_WordIterNext(Ent)){
        set_entvar(Ent, var_rendercolor, RGBCurrent);
        for(new i = 0; i < 3; i++)
            RGBCurrent[i] += RGBDelta[i];
    }
}

GetWordLen(const WordEnt){
    new Ent = WordEnt;
    new Cnt = 0;
    while(SprLett_WordIterNext(Ent))
        Cnt++;
    return Cnt;
}
