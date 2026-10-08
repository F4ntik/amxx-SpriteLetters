# Компилятор модели

Для frame_bones_v1.mdl использован готовый StudioMDL hlsdk.exe (PE32, 114688 байт). SHA-256: 36f0f5bd85920097ee8730c1ffb51e82790074b5d2f9e98b1541f10ea6f19e86.

Источник бинарника: https://raw.githubusercontent.com/PostScriptReal/Snark_Compiler/main/third_party/StudioMDL/hlsdk.exe

В [README Snark Compiler](https://github.com/PostScriptReal/Snark_Compiler/blob/main/README.md) этот инструмент атрибутирован как FunnkyHD's StudioMDL (modified), лицензия HLSDK, [исходный проект](https://github.com/PostScriptReal/studiomdl). Числовую версию бинарник не выводит. Сам компилятор в этот репозиторий и установочный архив не включён.

Исходники геометрии созданы tools/build_frame.py. Компиляция: перейти в model-source и запустить StudioMDL с frame.qc. Проверка результата: python tools/build_frame.py --check из корня проекта. Это проверка структуры/геометрии MDL вне игрового клиента.
