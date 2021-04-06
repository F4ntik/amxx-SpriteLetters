@echo off

rmdir .\build /s /q
mkdir .\build\SpriteLetters\addons\amxmodx\scripting\

copy .\README.md .\build

xcopy .\resources\* .\build\SpriteLetters\ /s /e /y

xcopy .\include .\build\SpriteLetters\addons\amxmodx\scripting\include\ /s /e /y
xcopy .\SprLett-Core .\build\SpriteLetters\addons\amxmodx\scripting\SprLett-Core\ /s /e /y
xcopy .\SprLett-Editor .\build\SpriteLetters\addons\amxmodx\scripting\SprLett-Editor\ /s /e /y
xcopy .\amxmodx .\build\SpriteLetters\addons\amxmodx\ /s /e /y

for /R %%G in (*.sma) do (
    if exist .\%%~nG.sma (
        copy .\%%~nG.sma .\build\SpriteLetters\addons\amxmodx\scripting\
    )   
)

del .\SpriteLetters.zip
cd .\build
zip -r .\..\SpriteLetters.zip .
cd ..
rmdir .\build /s /q