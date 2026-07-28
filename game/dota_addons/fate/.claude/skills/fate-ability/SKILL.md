---
name: fate-ability
description: >-
  Добавить новую способность Слуге или переписать существующую в аддоне fate
  (Dota 2, game/dota_addons/fate). Применять, когда просят сделать/поменять
  скилл, аттрибут (sa), комбо, скрытую способность или модификатор к ним.
  Описывает все семь мест, которые надо тронуть: KV-блок, ScriptFile, Lua-класс,
  LinkLuaModifier, precache, таблицы util.lua, локализация, иконка.
---

# Способность Слуги в аддоне fate

Порядок раскладки скиллов задан проектом (`Процесс разработки героя.md` в корне
аддона — прочитать при вопросах про дизайн, здесь только техника):
Q/W/E/R = `Ability1/2/3/6`, D/F = `Ability4/5` (качаются только атрибутами),
`Ability7` = комбо, дальше служебные. MaxLevel 5, Q/W — `LevelsBetweenUpgrades 1`,
E/R — `2`. Мана по умолчанию 100/200/400/800.

## Чек-лист (все пункты обязательны, пропуск любого = молчаливо не работает)

### 1. KV-блок способности
Файл: `scripts/npc/abilities/<hero>/<hero>_abilities.kv` — **один файл на героя**.
Новый файл героя надо подключить `#base` в `scripts/npc/npc_abilities_custom.txt`,
иначе движок его не увидит.

```
"okada_flashblade"
{
    "BaseClass"              "ability_lua"
    "ScriptFile"             "abilities/okada/okada_flashblade"
    "AbilityTextureName"     "custom/okada/okada_flashblade"
    "AbilityBehavior"        "DOTA_ABILITY_BEHAVIOR_POINT | DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES"
    "AbilityUnitTargetTeam"  "DOTA_UNIT_TARGET_TEAM_ENEMY"
    "AbilityUnitTargetType"  "DOTA_UNIT_TARGET_ALL"
    "AbilityUnitDamageType"  "DAMAGE_TYPE_MAGICAL"
    "LevelsBetweenUpgrades"  "1"
    "MaxLevel"               "5"
    "AbilityCooldown"        "12 11 10 9 8"
    "AbilityManaCost"        "200"
    "AbilityCastPoint"       "0.1"
    "AbilityCastAnimation"   "ACT_DOTA_CAST_ABILITY_2"
    "precache" { "particle" "particles/okada/okada_dash.vpcf" }
    "AbilityValues" { "damage" "250 312 375 437 500"  "radius" "300" }
}
```

⚠️ **`BaseClass` решает, что исполняется.** При `ability_lua` работает Lua-класс
из `ScriptFile`, а datadriven-хвосты (`OnSpellStart { RunScript ... }`, `Modifiers`)
движок **игнорирует** — это источник мёртвого кода в проекте. При
`ability_datadriven` наоборот работает `RunScript`, а Lua-файла нет.

⚠️ Числа НЕ хардкодить в Lua — всё в `AbilityValues`, читать
`self:GetSpecialValueFor("damage")`. Тултип инлайнит их как `%damage%`.

Кастпоинт: ≤0.2 для простых способностей, больше — для мощных/массовых, чтобы их
можно было сбить. `DOTA_ABILITY_BEHAVIOR_IMMEDIATE` — для самобафов и технических.

### 2. Упоминание в KV героя
`scripts/npc/heroes/npc_fate_hero_<hero>.kv` → `"AbilityN" "<ability>"`.
Способности, выдаваемые в рантайме (`AddAbility`), в hero.kv не значатся — это
нормально, но тогда их не увидит ни один индекс по hero.kv.

### 3. Lua-класс
`scripts/vscripts/abilities/<hero>/<ability>.lua`. Точка входа — `OnSpellStart`;
для каста/ченнела — `OnAbilityPhaseStart`, `OnChannelThink`, `OnChannelFinish`.

```lua
okada_flashblade = okada_flashblade or class({})
LinkLuaModifier("modifier_okada_flashblade_motion", "abilities/okada/okada_flashblade",
                LUA_MODIFIER_MOTION_HORIZONTAL)

function okada_flashblade:OnSpellStart()
    local caster = self:GetCaster()
    ...
end
```

Модификаторы способности пишутся **в её же файле** (один раз на способность) и
регистрируются `LinkLuaModifier` с путём **этого** файла. Имя модификатора
префикса `modifier_` не требует — в проекте полно `okada_manslayer`-подобных;
идентифицировать модификатор надо по `LinkLuaModifier`, а не по имени.

Модификаторы, дающие статы, писать так, чтобы значение считалось **и на клиенте**
(`IsHidden`/`DeclareFunctions` без серверных гейтов), иначе цифры в UI врут.

### 4. Хелперы вместо голого API
Из `scripts/vscripts/libraries/util.lua` (грузится глобально):
- `DoDamage(source, target, dmg, dmg_type, dmg_flag, abil, isLoop)` — **весь урон
  героям только через него**, не `ApplyDamage`;
- `IsSpellBlocked(target, caster)` — проверять перед применением дебафа на цель;
- `IsNotNull(hScript)` — гард для отложенных колбэков;
- `IsRevoked` / `IsLocked` / `IsImmuneToSlow` / `IsKnockbackImmune`,
  `FATE_FindUnitsInLine`, `ApplyAirborne*`, `SpawnVisionDummy`, `round`.

Задержки — библиотека `Timers`, партиклы — `ParticleManager`, снаряды —
`ProjectileManager`, AOE — `FindUnitsInRadius`/`FATE_FindUnitsInLine`.

Деши — отдельным motion-модификатором (эталон `abilities/okada/okada_flashblade.lua`),
и обязательно `DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES` в KV. Блинки — гейтить
dimensional lock через `CastFilterResultTarget/Location` и ставить
`FindClearSpaceForUnit`, чтобы не влипнуть в текстуру. Отбрасывание — knockback,
всегда с проверкой на knockback-иммун (эталон `aoko_facebreaker.lua`). Простой
барьер — готовый `scripts/vscripts/modifiers/modifier_barrier_new.lua`, свой
модификатор писать только под сложную логику.

### 5. Таблицы в `libraries/util.lua`
Каждый новый модификатор/способность прописать там, где ему место (списки строк):
- `softdispellable` / `strongdispellable` / `deargdispellable` / `cleansable` —
  что снимается каким диспелом;
- `slowmodifier` — чтобы работал `RemoveSlowEffect`/иммун к слоу;
- `donotlevel` — способности, которые не качаются обычным путём (D/F, пассивки);
- `CannotReset` — способности, чей кулдаун НЕ сбрасывается рефрешем; **этим же
  списком определяется Refreshable/Unrefreshable в тултипе** — не угадывать;
- `revokes`, `locks`, `d_seal_locked`, `tModifierKBImmune` — по смыслу.

### 6. Precache
Три независимых пути, и достаточно любого:
1. блок `precache { "particle" "..." }` в KV способности;
2. `PrecacheResource("particle", "...", context)` в Lua;
3. `PrecacheResource("particle_folder", "particles/<hero>", context)` в
   `scripts/vscripts/addon_game_mode.lua` — прекешит папку целиком.

Прежде чем добавлять — проверить, не покрыт ли путь уже вариантом 3. Не
прекешенный партикль = невидимый эффект без ошибок в логе.

### 7. Локализация и иконка
`resource/addon_english.txt` (UTF-8) и `resource/addon_schinese.txt` (**UTF-16**,
необязателен — при отсутствии ключа падает на английский):

```
"DOTA_Tooltip_Ability_okada_flashblade"              "Shimatsuken: Flashblade"
"DOTA_Tooltip_Ability_okada_flashblade_Description"  "..."
"DOTA_Tooltip_Ability_okada_flashblade_damage"       "Damage:"
```

Строка значения показывается, только если ключ (`damage`) есть в `AbilityValues`
этой же способности. Формат и цвета описания — скилл `fate-tooltips`.

Иконка: `resource/flash3/images/spellicons/custom/<hero>/<ability>.png`,
квадратная, не меньше 128×128; путь без расширения идёт в `AbilityTextureName`.

## Перед сдачей
Прогнать скилл `fate-crash-review` — он ловит утечки dummy, невычищенные партиклы,
протухшие хендлы в таймерах и реентрантность в damage-пайплайне.

## Правка файлов
Файлы в CRLF и с кириллицей в комментариях. Не переписывать их целиком
через PowerShell `Get-Content`/`Set-Content` — ломается кодировка; править
точечно (Edit) и сохранять `\r\n`.
