---
name: fate-hero-skin
description: >-
  Добавить скин (альтернативную модель) герою в аддоне fate — блок Skins в KV,
  precache, локализация имени, гейт озвучки по номеру скина, косметические
  партиклы и компиляция звука. Применять при добавлении/правке скина, а также
  когда «у скина чужой голос», «модель мигает» или «скин не виден в пикере».
---

# Скин Слуги (fate)

Проверено на Sasaki skin_2 «Bamboo-hatted Kim».

## Рецепт

1. **KV героя** `scripts/npc/heroes/npc_fate_hero_<hero>.kv`:
   ```
   "Skins"
   {
       "skin_1" { "loc_name" "<hero>_1"  "model" "models/.../x.vmdl" }
       "skin_2" { "loc_name" "<hero>_2"  "model" "models/.../y.vmdl" }
   }
   ```
   Нумерация с 1; **skin_0 генерится сам** из базового `Model`
   (`modules/hero_selection/hero_selection.lua`).
2. **Precache модели**: `PrecacheResource("model", "<путь>.vmdl", context)` в
   `scripts/vscripts/addon_game_mode.lua`, рядом с другими скинами.
3. **Локализация**: `resource/addon_english.txt` → `"<hero>_N"  "Имя скина"`.
   `addon_schinese.txt` — UTF-16, необязателен (падает на английский).
4. **Панорама/пикер трогать не надо** — `FillSkinUI` полностью data-driven:
   читает `Object.keys(skins).length` и `$.Localize('#'+loc_name)`.
5. **Портрет** (опционально): блок по пути `.vmdl` в `scripts/npc/portraits.txt` —
   свет, камера, фон.

## ЛОВУШКА 1: второй скин крадёт озвучку первого

Модель применяет модификатор `modifier_hero_selection_skin`
(`modules/hero_selection/hero_replacer.lua`), номер лежит в поле `.skinNumber`,
модификатор вешается только при `skinNumber ~= 0`. Старые герои гейтят кастомный
голос **булевым** `if caster:HasModifier("modifier_hero_selection_skin")` — то
есть скин 2 молча получит реплики скина 1. Баг не падает и не логируется.

Правильный идиом (как у ryougi/berserker):
```lua
if caster:HasModifier("modifier_hero_selection_skin") then
    if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
        -- голос скина 2
    else
        -- голос скина 1
    end
else
    -- базовый голос
end
```
**Добавляя скин N>1, СНАЧАЛА** `grep -rn modifier_hero_selection_skin` по папке
героя и перевести все точки на `.skinNumber`. Сверять с реально живым кодом:
в папках героев лежат мёртвые файлы (`*_old.lua`), их гейтить не нужно.

⚠️ Гейты по скину ставятся **только на реплики** (речь, 0.7–2.7 с), а не на SFX
(звук клинка, дотовские `Hero_*.*`) — SFX играет одинаково у всех скинов, если
специально не решили иначе.

## ЛОВУШКА 2: SetModel ломает скин

Скин — это *свойство* `GetModifierModelChange`, а не жёсткая установка модели.
Любой прямой `caster:SetModel(...)` перебивает его, и модель вернётся только на
следующем пересчёте модификаторов → мигание базовой моделью ~0.5 с.

Прятать/показывать героя — через `AddNoDraw()`/`RemoveNoDraw()` (идиома
lancelot/saito/ozy/arash), не подменой на `invisiblebox` с хардкодным возвратом.
С `NoDraw` обязательна страховка `RemoveNoDraw()` в таймере: пропущенный возврат =
навсегда невидимый герой.

## ЛОВУШКА 3: GetUnitName() — базовый герой

Из-за `override_hero` у Сасаки `GetUnitName()` = `npc_dota_hero_juggernaut`.
Гейт по кастомному имени всегда ложен. Идентифицировать скин-героя:
`GetUnitName() == <override_hero>` + `.skinNumber`.

## Постоянный косметический партикль на скине

1. свой зацикленный `.vpcf` (`C_OP_ContinuousEmitter`, не одноразовый
   `InstantaneousEmitter`);
2. attach-точка в модели (напр. `attach_eye`);
3. вешать в `FateGameMode:OnHeroSpawned` (`addon_game_mode.lua`) через
   `CreateParticle(..., PATTACH_POINT_FOLLOW, unit)` +
   `SetParticleControlEnt(fx, 0, unit, PATTACH_POINT_FOLLOW, "attach_eye", ...)`,
   с гейтом «базовый герой + номер скина», задержкой ~0.2 с (attach появляется
   после model-change) и очисткой прошлого индекса перед пересозданием;
4. precache в `Precache()`;
5. ⚠️ **attach-точки требуют ПЕРЕкомпиляции `.vmdl`** — в старом `_c` их нет.
   Грепом по бинарному `vmdl_c` имена attach не находятся (сжатый блок строк) —
   так не диагностировать.

## Озвучка скина (пайплайн звука)

- Исходники — **mp3** в `content/.../sounds/<группа>/<имя>.mp3` (конвенция проекта).
- Саундэвенты — плоский список блоков в `content/.../soundevents/<файл>.vsndevts`
  (без корневой обёртки). Шаблон копировать с существующего:
  `sos_reference_stack` + `reference_stack "dota_src1_3d"`, в `vsnd_files`
  путь с расширением **`.vsnd`** (не mp3), volume обычно 7.0.
- Форматов `.vsndevts` два (KV3 и старый KV1) — компилятор KV1 молча конвертирует.
- ⚠️ **Компиляция в два шага**: `resourcecompiler -i <файл>.vsndevts` собирает
  только событие и НЕ трогает аудио; mp3 компилировать отдельно:
  `resourcecompiler -fshallow -i "<...>/sounds/<группа>/*.mp3"`. Без второго шага
  событие есть, а звука нет — тишина без ошибок.
- Имена звуковых событий регистронезависимы: `EmitSound("Sasaki_Quickdraw_1")`
  найдёт событие `sasaki_quickdraw_1`. Грепать по имени без учёта регистра.
