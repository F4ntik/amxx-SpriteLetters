@echo off

rmdir .\build /s /q
mkdir .\build\SpriteLetters\addons\amxmodx\scripting\

copy .\README.md .\build

xcopy .\resources\* .\build\SpriteLetters\ /s /e /y

xcopy .\include .\build\SpriteLetters\addons\amxmodx\scripting\include\ /s /e /y
xcopy .\SprLett-Core .\build\SpriteLetters\addons\amxmodx\scripting\SprLett-Core\ /s /e /y
xcopy .\SprLett-Editor .\build\SpriteLetters\addons\amxmodx\scripting\SprLett-Editor\ /s /e /y

set PLUGINS_LIST=.\amxmodx\configs\plugins-SprLett.ini
echo. 2>%PLUGINS_LIST%

for %%G in (*.sma) do (
     echo %%~nG
     echo %%~nG.amxx>>%PLUGINS_LIST%
     copy .\%%~nG.sma .\build\SpriteLetters\addons\amxmodx\scripting\
)

xcopy .\amxmodx .\build\SpriteLetters\addons\amxmodx\ /s /e /y

del .\SpriteLetters.zip
cd .\build
zip -r .\..\SpriteLetters.zip .
cd ..
rmdir .\build /s /q
