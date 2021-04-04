# Sprite Letters

## Описание

Позволяет размещать на картах надписи спрайтами.

## Требования

- [AmxModX 1.9.0](https://www.amxmodx.org/downloads-new.php) и выше
- [ReAPI](https://github.com/s1lentq/reapi/releases/latest)

## Команды

- `slmainmenu`
  - Главное меню редактора слов.

## Наборы символов

Наборы символов хранятся в папке `/sprites/SprLett/Charsets/`.

### Пример

Название набора: `Default`

- Спрайт с символами: `.../Charsets/Default/chars.spr`
- Карта символов: `.../Charsets/Default/map.txt`

### Структура карты символов

```ini
<Char1> 1
<Char2> 2
<Char3> 3
<CharN> N
```

_Где `<CharN>` - какой-то символ, а N - его порядковый номер._

### Создание своего набора символов

Инструменты:

- [Программа для генерации битмап с символами](https://github.com/ArKaNeMaN/lazarus-BmpLettersGenerator/releases/latest)
- [Программа для сборки спрайтов](https://gamebanana.com/tools/4775)

[Процесс создания набора символов (Видео)](https://youtu.be/GDpwsGnayGU)

Программа, генерирующая битмапы, сразу создаёт карту символов и записывает её в файл `map.txt`.

## [API](include/SprLetters.inc)
