# Fate — структура проекта и рабочий процесс

Кастомная игра (custom game) для Dota 2 по вселенной Fate/Type-Moon.
Внутренний код-нейм аддона — `fateanother` (видно в именах panorama-файлов), версия в коде `FATE_VERSION = "v13.37"`.
Это арена-режим: игроки выбирают Servant'ов (геров), сражаются по раундам на картах 7vs7 / FFA / Trio Rumble.

> Документ описывает **что где лежит** и **что с чем связано**. Конкретные формулы способностей смотри в самих `.lua`/`.kv`.

---

## 0. Где физически лежит проект

Аддон живёт в **двух параллельных деревьях** внутри установки Dota 2:

```
steamapps/common/dota 2 beta/
├─ content/dota_addons/fate/   ← ИСХОДНИКИ (то, что редактируется в SDK / руками)
└─ game/dota_addons/fate/      ← СКОМПИЛИРОВАННОЕ + код (то, что грузит движок)
```

Это стандартное разделение Source 2:

- **`content/`** — «сырые» ассеты, которые открываются и компилируются Asset Browser / Resource Compiler (`resourcecompiler.exe`): модели, текстуры, материалы, партиклы, звуки, исходники Panorama-интерфейса.
- **`game/`** — то, что реально попадает в игру: **скомпилированные** версии всех ассетов (`*_c`), **плюс** весь игровой код (Lua), KV-файлы (герои/способности/юниты/предметы), локализация и иконки. Карты `.vpk`.

Lua-скрипты и `.kv`/`.txt`-файлы **не компилируются** — они лежат только в `game/` и интерпретируются на лету.

### Соответствие исходник → скомпилированное

| Тип ассета         | `content/` (исходник)         | `game/` (компилят)        |
|--------------------|-------------------------------|---------------------------|
| Модель             | `.vmdl` (+ `.fbx`, `.dmx`)    | `.vmdl_c`                 |
| Анимация / граф    | (внутри `.vmdl`)              | `.vanim_c`, `.vagrp_c`, `.vseq_c` |
| Меш / физика       | —                             | `.vmesh_c`, `.vphys_c`, `.vmorf_c` |
| Текстура           | `.png` / `.tga` / `.jpg` / `.psd` / `.dds` | `.vtex_c`     |
| Материал           | `.vmat`                       | `.vmat_c`                 |
| Партикл            | `.vpcf`                       | `.vpcf_c` (+ `.vsnap_c`)  |
| Звук (событие)     | `.vsndevts`                   | `.vsndevts_c`             |
| Звук (сэмпл)       | `.wav` / `.mp3` / `.ogg` / `.hca` | `.vsnd_c`             |
| Panorama разметка  | `.xml`                        | `.vxml_c`                 |
| Panorama скрипт    | `.js`                         | `.vjs_c`                  |
| Panorama стиль     | `.css`                        | `.vcss_c`                 |
| Карта              | `.vmap` (+ prefabs/tileset)   | `.vpk`                    |

**Важно:** чтобы изменение ассета (модель/партикл/звук/UI) попало в игру — нужно **перекомпилировать** исходник из `content/` (через Asset Browser в Dota Workshop Tools). Изменение Lua/KV в `game/` работает сразу (для Lua — после перезапуска карты, KV — после перезапуска игры).

---

## 1. Корень `game/dota_addons/fate/` — мета-файлы

| Файл                       | Назначение |
|----------------------------|------------|
| `addoninfo.txt`            | Манифест аддона: список карт (`7vs7_common 7vs7_draft fate_ffa`), число игроков/команд на каждую карту. |
| `gameinfo.txt`             | Идентификация движку (SteamAppId 816, тулзы 211). |
| `hotkeys.txt`              | Кастомные хоткеи. |
| `misc.txt`, `network_measurement.txt`, `panorama_debugger.cfg` | Технические настройки/отладка. |
| `cache_*.soc`, `sendtables.bin`, `tools_asset_info.bin`, `tools_thumbnail_cache.sqlite3` | Кэши Workshop Tools (генерируются автоматически, не редактируются руками). |
| `balance_patch_proposal.md` | Документ по балансу (заметки разработки). |
| `PROJECT_STRUCTURE.md`     | Этот файл. |
| `fate-scoreboard-bot/`     | Отдельный Python/Discord-бот для статистики (OCR → Excel). См. раздел 11. |

---

## 2. `scripts/vscripts/` — игровой код (Lua, серверная логика)

Сердце мода. Точка входа — `addon_game_mode.lua` (~5100 строк): подключает все библиотеки/модули (`require(...)`), хранит глобальные константы режима (длительность раундов, спавны, `VICTORY_CONDITION = 12` и т.д.), управляет игровым циклом, раундами, спавном и событиями.

```
scripts/vscripts/
├─ addon_game_mode.lua          ← ГЛАВНАЯ точка входа (сервер)
├─ addon_game_mode_client.lua   ← клиентская точка входа
├─ addon_init.lua
│
├─ <class>_ability.lua          ← СТАРЫЙ стиль: один файл = все способности класса
│      saber_ability.lua, archer_ability.lua, lancer_ability.lua,
│      rider_ability.lua, caster_ability.lua, berserker_ability.lua,
│      avenger_ability.lua, master_ability.lua, и т.д. (≈30 файлов в корне)
│
├─ abilities/                   ← НОВЫЙ стиль: папка на каждого Servant'а
│      <servant>/<servant>_<ability>.lua
│      <servant>/modifiers/modifier_*.lua
│      (≈1178 файлов — основной объём кода способностей)
│
├─ items/                       ← логика кастомных предметов (Lua)
│      blink_scroll.lua, mana_essence.lua, sentry_familiar.lua,
│      item_relic_of_the_king.lua, modifiers/...
│
├─ modifiers/                   ← система атрибутов героев (STR/AGI/INT → HP/MP/armor/...)
│      attributes.lua, attributes_cl.lua, modifier_attributes_*.lua
│
├─ libraries/                   ← переиспользуемые движки/утилиты
│      timers.lua, projectiles.lua, physics.lua, animations.lua,
│      attachments.lua, crowdcontrol.lua, popups.lua, notifications.lua,
│      containers.lua, playertables.lua, keyvalues.lua, cameramodule.lua,
│      servantstats.lua, anime_vector_targeting.lua, alternateparticle.lua,
│      pathgraph.lua, binheap.lua, worldpanels.lua,
│      abilities/  modifiers/  statcollection/
│
├─ modules/                     ← модульные подсистемы (вкл/выкл в index.lua)
│      index.lua  ← реестр: какие модули require'ятся
│      events/ teams/ hero_selection/ options/ chat/  (активные)
│      bosses/ duel/ gold/ kills/ spawner/ stats/ weather/ illusions/
│      panorama_shop/ structures/ simpleai/ ... (присутствуют, многие отключены)
│
├─ util/                        ← хелперы: ability, item, modifier, units,
│      math, string, table, other, playerresource, debug, shared, init
│
├─ data/                        ← ДАННЫЕ/таблицы-конфиги (не логика)
│      kv_data.lua        ← загружает KV-файлы в Lua (LoadKeyValues)
│      globals.lua, constants.lua
│      abilities.lua      ← таблицы: LINKED_ABILITIES, MULTICAST, бан-листы для боссов и т.д.
│      ability_functions.lua ← общие процедуры (урон боссам, лайфстил предметов, проки)
│      ability_shop.lua, modifiers.lua
│
├─ internal/                    ← events.lua, gamemode.lua (служебное ядро Barebones)
├─ statcollection/              ← интеграция со сбором статистики
├─ eyeherodemo/                 ← тестовый/демо-герой (require в init)
└─ astolfo/                     ← отдельный код (legacy)
```

### Два стиля написания способностей — это важно

1. **Старый, monolithic:** `scripts/vscripts/<class>_ability.lua` — один большой файл на класс Servant'а (saber/archer/lancer/...). Подключается напрямую в `addon_game_mode.lua` через `require('saber_ability')`.
2. **Новый, модульный:** `scripts/vscripts/abilities/<servant>/` — каждая способность в своём файле + папка `modifiers/`. На него ссылается KV-поле `"ScriptFile" "abilities/<servant>/<ability>"` (275 KV-способностей используют этот механизм).

Новые герои делаются во втором стиле; старые классы постепенно мигрируют.

---

## 3. `scripts/npc/` — KV-описания (герои, способности, юниты, предметы)

Это «таблицы данных» движка Dota — параметры всего, что есть в игре. Связаны через директиву **`#base "..."`** (инклюд другого KV-файла).

```
scripts/npc/
├─ npc_heroes_custom.txt     ← реестр героев: 51× #base "heroes/npc_fate_hero_*.kv"
├─ npc_abilities_custom.txt  ← реестр способностей: 54× #base "abilities/<servant>/*.kv"
├─ npc_abilities_override.txt← переопределение стандартных способностей Dota
├─ npc_units_custom.txt      ← кастомные юниты (саммоны/боссы)
├─ npc_items_custom.txt      ← кастомные предметы (2400+ строк, 4× #base)
├─ custom_herolist.txt       ← какие БАЗОВЫЕ слоты-герои Dota включены (override-механика)
├─ herolist.txt, attributes.txt, common_items.txt, portraits*.txt, voices.txt
│
├─ heroes/                   ← по файлу на Servant'а: npc_fate_hero_<name>.kv
│      + new.txt (доп. герои, домерживается в Lua через table.deepmerge)
├─ abilities/                ← по ПАПКЕ на Servant'а: <servant>/<servant>_abilities.kv
│      внутри тоже свои #base на отдельные .kv способностей
├─ units/                    ← gilles/ misc/ nursery/ semiramis/ (саммоны, боссы)
├─ items/                    ← item_*.txt / *.kv для кастомных предметов
└─ voices/                   ← <class>.txt — реплики/озвучка по классам
```

### Override-механика героев (ключевой момент)

Кастомные герои **не создаются с нуля** — каждый «переопределяет» существующего героя Dota.
В `npc_fate_hero_*.kv`:

```
"npc_dota_hero_saber"
{
    "override_hero"   "npc_dota_hero_legion_commander"   ← занимает слот LC
    "Model"           "models/artoria/artoria.vmdl"      ← своя модель из content
    "Ability1".."Ability12"  ← список способностей (имена из npc_abilities_custom)
    "Attribute1".. , "Combo", статы, броня, дальность атаки и т.д.
}
```

`custom_herolist.txt` перечисляет, какие **базовые** слоты Dota активны (`npc_dota_hero_legion_commander = 1`, ...). Один базовый слот = один Servant.

> ⚠️ Имя героя в Lua и в kv — это `npc_dota_hero_saber` (внутреннее имя слота), а отображаемое имя «Arturia/Saber» задаётся в локализации. Связь «override_hero → реальное имя» используется в т.ч. ботом статистики.

### Связь способность KV ↔ Lua

В `<servant>_abilities.kv`:

- `"BaseClass" "ability_lua"` + `"ScriptFile" "abilities/arturia/arturia_invisible_air"` → логика в `scripts/vscripts/abilities/arturia/arturia_invisible_air.lua`.
- `"BaseClass" "ability_datadriven"` → логика описана прямо в KV (блоки `Modifiers`, `OnCreated`, `AttachEffect` и пр.) — старый стиль.
- `"AbilityTextureName" "custom/saber_invisible_air"` → иконка (см. раздел 5/6).
- блок `"precache" { "particle" ... }` → какие vpcf/звуки подгрузить.

---

## 4. Прочие `scripts/` (не npc, не vscripts)

| Файл/папка                     | Назначение |
|--------------------------------|------------|
| `scripts/custom_net_tables.txt`| Реестр net-таблиц сервер↔клиент: `selection, score, sync, stats`. |
| `scripts/custom_events.txt`    | Описание кастомных событий клиент↔сервер (таймеры, ошибки, статколлекшн, выбор героя и т.д.). |
| `scripts/attachments.txt`      | Точки привязки эффектов к моделям. |
| `scripts/attributes.txt`       | Параметры системы атрибутов. |
| `scripts/shops.txt`, `shops/`  | Магазины. |
| `scripts/addon_hud_textures.txt`| Атлас HUD-текстур. |
| `scripts/soundscapes_*.txt`    | Звуковые ландшафты (пример). |

---

## 5. `resource/` — локализация и интерфейсные тексты

```
resource/
├─ addon_english.txt          ← ОСНОВНАЯ локализация (12000+ строк):
│      имена героев/способностей/предметов, описания, тексты UI.
│      Ключи вида "DOTA_Tooltip_ability_artoria_excalibur_Description" и т.п.
├─ addon_schinese.txt         ← китайский перевод
├─ addon_*_changes.txt        ← дельты/незакоммиченные правки переводов
├─ flash3/                    ← custom_ui.txt, images, videos (ресурсы UI)
├─ overviews/                 ← миникарты/превью карт (по файлу на карту)
└─ translator reminders/, temp/
```

Связь: ключ способности `artoria_excalibur` (из KV) → строки `DOTA_Tooltip_ability_artoria_excalibur*` в `addon_english.txt`.

---

## 6. Ассеты: модели, текстуры, материалы, иконки

Исходники — в `content/dota_addons/fate/`, компиляты — в `game/dota_addons/fate/`.

| Папка (в обоих деревьях) | Что лежит |
|--------------------------|-----------|
| `models/`     | Модели Servant'ов и юнитов. `content`: `.vmdl/.fbx/.dmx` + текстуры; `game`: `.vmdl_c` (+анимации/меши). Путь из KV героя: `"Model" "models/artoria/artoria.vmdl"`. |
| `materials/`  | Материалы и текстуры. `game`: `.vmat_c`, `.vtex_c`. |
| `images/`     | Доп. изображения. |
| `particles/`  | Партиклы (vfx). `content`: ~5100 `.vpcf`; `game`: ~20000 `.vpcf_c`. Ссылки из KV (`precache`, `AttachEffect`) и из Lua (`ParticleManager:CreateParticle(...)`). |

### Иконки способностей/героев — где искать

`"AbilityTextureName" "custom/saber_invisible_air"` означает текстуру `custom/saber_invisible_air` в спелл-иконках Panorama:
- исходник: `content/.../panorama/images/spellicons/...`
- компилят: `game/.../panorama/images/spellicons/*.vtex_c`
- также `panorama/images/heroes/`, `items/`, `misc/`.

---

## 7. `soundevents/` + `sounds/` — звук

Двухуровневая система Source 2:

1. **Сэмплы** (`sounds/`): `content` — `.wav/.mp3/.ogg`; `game` — `.vsnd_c`.
2. **События** (`soundevents/`): `content` — `.vsndevts`; `game` — `.vsndevts_c`. Описывают, как проигрывать сэмплы (громкость, питч, рандомизация).

Организация — по героям/классам: `hero_saber.vsndevts`, `hero_nero.vsndevts`, ..., плюс `bgm`, `announcer`, `game_sounds_*`, тематические (`gachi`, `devil_trigger`, `killer_queen` и т.п.), и подпапки `heroes/`, `music/`, `voscripts/`.

Из кода вызывается по имени события: `EmitSoundOn("hero_saber.excalibur", unit)` и т.п. Озвучка реплик также завязана на `scripts/npc/voices/`.

---

## 8. `panorama/` — пользовательский интерфейс (HUD)

Исходники UI — в `content/.../panorama/` (`.xml` + `.js` + `.css`), компиляты — в `game/.../panorama/` (`.vxml_c` + `.vjs_c` + `.vcss_c`).

```
panorama/
├─ layout/custom_game/    ← разметка панелей (.xml → .vxml_c)
│      custom_ui_manifest  ← КОРНЕВОЙ манифест: какие панели грузить
│      fateanother_ability, fateanother_buff_bar, fateanother_hero_selection,
│      fateanother_scoreboard_left, fateanother_timer, fateanother_masterbar,
│      fateanother_fatepedia (внутриигровая энциклопедия), fateanother_shop, ...
├─ scripts/custom_game/   ← логика панелей (.js → .vjs_c)
│      одноимённые fateanother_*.js + combo.js, inventory.js, shop, voice, bgm...
├─ styles/custom_game/    ← стили (.css → .vcss_c)
├─ images/                ← spellicons / heroes / items / misc (.png → .vtex_c)
└─ localization/, videos/
```

Связь UI ↔ игра: Panorama-скрипты общаются с Lua через **custom events** (`scripts/custom_events.txt`) и **net tables** (`scripts/custom_net_tables.txt`: `selection/score/sync/stats`). Префикс `fateanother_` = внутреннее имя проекта.

---

## 9. `maps/` — карты

| `content/.../maps/` (исходники `.vmap`) | `game/.../maps/` (собранные `.vpk`) |
|------------------------------------------|--------------------------------------|
| `7vs7_common.vmap`, `7vs7_draft.vmap`, `7vs7_test.vmap`, `fate_ffa.vmap`, `fate_elim_7v7*.vmap`, `anime_fate_7vs7_beta.vmap`, `template_map.vmap`, ... + `prefabs/`, `tileset/` | `7vs7_common.vpk`, `7vs7_draft.vpk`, `7vs7_test.vpk`, `fate_ffa.vpk`, `fate_trio_rumble_3v3v3v3.vpk` |

Играбельные карты перечислены в `addoninfo.txt`. Превью/миникарты — в `resource/overviews/`.

---

## 10. Полный путь добавления/правки Servant'а (как всё связано)

Чтобы понять рабочий процесс, проследим один герой целиком на примере Arturia (слот `npc_dota_hero_saber`):

1. **Слот включён:** `scripts/npc/custom_herolist.txt` → `npc_dota_hero_legion_commander = 1`.
2. **Герой описан:** `scripts/npc/heroes/npc_fate_hero_arturia.kv` (override LC, модель `models/artoria/artoria.vmdl`, список Ability1–12, статы) → инклюдится в `npc_heroes_custom.txt` через `#base`.
3. **Способности описаны (KV):** `scripts/npc/abilities/saber/saber_abilities.kv` (+ вложенные `#base` на отдельные `.kv`) → инклюдится в `npc_abilities_custom.txt`. Каждая способность задаёт `ScriptFile`, иконку, партиклы (`precache`), параметры.
4. **Логика способностей (Lua):** `scripts/vscripts/abilities/arturia/*.lua` (+ `modifiers/`), на которые указывает `ScriptFile`. Используют библиотеки из `scripts/vscripts/libraries/`.
5. **Модель:** `content/.../models/artoria/*` (исходник) → `game/.../models/artoria/artoria.vmdl_c` (компилят).
6. **Партиклы/иконки:** `content/.../particles/*` и `content/.../panorama/images/spellicons/*` → компиляты в `game/`.
7. **Звук:** `content/.../soundevents/hero_saber.vsndevts` + сэмплы → компиляты; реплики в `scripts/npc/voices/`.
8. **Тексты:** ключи `DOTA_Tooltip_ability_artoria_*` и имя героя — в `resource/addon_english.txt`.
9. **UI:** иконки/панели рисует Panorama (`panorama/...`), данные летят через net tables / custom events.

> Любая правка ассета (5–7) требует перекомпиляции из `content/`. Правки KV/Lua/локализации (2–4, 8) — только в `game/`.

---

## 11. `fate-scoreboard-bot/` — внешний инструмент

Отдельный проект (не часть рантайма мода): Discord-бот, который OCR'ит скриншоты табло и пишет статистику в Excel. Имена героев он получает, разворачивая `override_hero` → `addon_english.txt`. Подробнее — в памяти проекта (`scoreboard-bot.md`).

---

## 12. Краткая шпаргалка «где что искать»

| Нужно изменить...                     | Иди в... |
|---------------------------------------|----------|
| Логику способности (новый стиль)      | `scripts/vscripts/abilities/<servant>/*.lua` |
| Логику способности (старый стиль)     | `scripts/vscripts/<class>_ability.lua` |
| Числа/параметры способности           | `scripts/npc/abilities/<servant>/*.kv` |
| Статы/модель/список абилок героя      | `scripts/npc/heroes/npc_fate_hero_*.kv` |
| Включить/выключить героя              | `scripts/npc/custom_herolist.txt` |
| Предметы                              | `scripts/npc/npc_items_custom.txt` + `scripts/vscripts/items/` |
| Правила режима (раунды, спавны, победа)| `scripts/vscripts/addon_game_mode.lua` |
| Подсистемы (вкл/выкл)                 | `scripts/vscripts/modules/index.lua` |
| Тексты/описания                       | `resource/addon_english.txt` |
| Интерфейс (HUD)                       | `content/.../panorama/` → перекомпиляция |
| Модель/партикл/звук/иконку            | `content/.../{models,particles,sounds,soundevents,panorama/images}/` → перекомпиляция |
| Карту                                 | `content/.../maps/*.vmap` → сборка в `.vpk` |
| Связь UI↔Lua                          | `scripts/custom_events.txt`, `scripts/custom_net_tables.txt` |
