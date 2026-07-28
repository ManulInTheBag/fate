---
name: fate-new-servant
description: >-
  Завести нового Слугу (героя) в аддоне fate — от KV-файла и override_hero до
  регистрации во всех реестрах, комбо, атрибутов, звуков, портрета и картинок.
  Применять, когда просят добавить нового персонажа/героя в игру, или когда
  новый герой не появляется в выборе, не имеет имени, комбо или портрета.
---

# Новый Слуга в аддоне fate

Слуга не создаётся с нуля: он **переопределяет базового героя Dota** через
`override_hero`. Свободный слот берётся из `scripts/npc/custom_herolist.txt`
(значение `1` = слот включён в выбор). Эталон свежего героя — Okada Izo
(`npc_dota_hero_okada`, override `npc_dota_hero_troll_warlord`), по нему и равняться.

Дизайн-требования к набору способностей (сколько, как качаются, кап 30 у комбо) —
в `Процесс разработки героя.md` в корне аддона.

## 1. KV героя

`scripts/npc/heroes/npc_fate_hero_<hero>.kv`:

```
"DOTAHeroes"
{
    "npc_dota_hero_okada"
    {
        "override_hero"     "npc_dota_hero_troll_warlord"
        "DisableWearables"  "1"
        "Model"             "models/okada/okada.vmdl"
        "AbilityLayout"     "6"

        "Ability1".."Ability6"   // Q W E D F R
        "Ability7"  "okada_combo"
        "Ability8"  "hero_base_stats_bonus"
        "Ability9"  "presence_detection_passive"
        "Ability10" "attribute_bonus_custom"
        "Combo"           "okada_combo"
        "AttributeNumber" "4"
        "Attribute1".."Attribute4"

        "StatusHealth" / "StatusMana" / "ArmorPhysical" / "MagicalResistance"
        "AttackDamageMin/Max" / "AttackRate" / "AttackRange" / "MovementSpeed"
        "AttributePrimary" + Base/Gain по трём статам
        "HealthBarOffset"
    }
}
```

⚠️ Ключ блока **не обязан** совпадать с `npc_dota_hero_*` (у Лю Бу это
`npc_fate_hero_lu_bu`) — но новых героев заводить по образцу Okada.
⚠️ `Ability8/9/10` — служебные (базовые статы, детект присутствия, атрибуты), их
копировать всегда.
⚠️ `DisableWearables` движком по факту игнорируется — визуальный мусор с базового
героя чистится кодом на спавне, отдельно ничего делать не надо.

## 2. Регистрации (без них герой невидим)

| Файл | Что добавить |
|---|---|
| `scripts/npc/npc_heroes_custom.txt` | `#base "heroes/npc_fate_hero_<hero>.kv"` |
| `scripts/npc/npc_abilities_custom.txt` | `#base "abilities/<hero>/<hero>_abilities.kv"` |
| `scripts/npc/custom_herolist.txt` | базовый герой = `"1"` |
| `resource/addon_english.txt` | `"npc_dota_hero_<БАЗОВЫЙ>"  "Имя Слуги"` — имя в UI берётся по ключу **базового** героя |
| `scripts/vscripts/libraries/util.lua`, таблица `heroNames` | `["npc_dota_hero_<БАЗОВЫЙ>"] = "Имя Слуги"` — иначе `GetHeroName` вернёт `"Undefined"` |
| `scripts/npc/portraits.txt` | блок по пути `.vmdl`: свет, камера, фон портрета (необязательно, без него дефолтная рамка) |

Комбо в `heroCombos` (util.lua) прописывать **не надо**: `GetHeroCombo` строит
обратную карту из `override_hero` + `Combo` в KV героя, таблица — легаси-фолбэк.

## 3. Модель, звук, precache

`scripts/vscripts/addon_game_mode.lua`:
- `PrecacheResource("model", "models/<hero>/<hero>.vmdl", context)`;
- `PrecacheResource("soundfile", "soundevents/hero_<hero>.vsndevts", context)`;
- по желанию `PrecacheResource("particle_folder", "particles/<hero>", context)` —
  тогда отдельный precache каждого партикля героя не нужен.

Исходники моделей/партиклей/звуков живут в `content/dota_addons/fate/` и требуют
компиляции через Workshop Tools; Lua/KV/локализация правятся прямо в `game/`.

## 4. Способности

Каждая — по скиллу `fate-ability` (KV-блок, ScriptFile, Lua, LinkLuaModifier,
precache, таблицы util.lua, локализация, иконка). Все файлы Lua героя — в
`scripts/vscripts/abilities/<hero>/`, один KV на героя в
`scripts/npc/abilities/<hero>/`.

Атрибуты (`<hero>_sa_N`) — обычно одним файлом `<hero>_attributes.lua`, качаются
маной Мастера, а не уровнями; добавить их в `donotlevel` в util.lua.

## 5. Картинки и тултипы

- Портрет/selection-иконка — скилл `fate-hero-images` (имена файлов по **базовому**
  герою, обязательная компиляция ассетов).
- Описания способностей — скилл `fate-tooltips`.

## 6. Проверка

1. Герой появился в экране выбора и с правильным именем.
2. Все 6 способностей + атрибуты видны, иконки не дефолтные.
3. Комбо доступно при 30/30/30 (проверка в коде идёт по `>= 29.1`).
4. Прогнать скилл `fate-crash-review` по новым Lua-файлам.

## Грабли

- ⚠️ Файл героя в `scripts/npc/heroes/`, не подключённый через `#base`, движок не
  грузит — но глоб по папке подхватывает. Источник правды — список `#base`.
- ⚠️ `caster:GetUnitName()` вернёт **базового** дотовского героя, а не имя Слуги.
  Гейты по кастомному имени всегда ложны.
- Файлы CRLF, местами с кириллицей: править точечно, не переписывать целиком
  через PowerShell `Get-Content`/`Set-Content`.
