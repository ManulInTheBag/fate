# SKILL: Системы и герои Fate — как всё работает

Это инженерный справочник-«скилл» по рантайму мода. Дополняет [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
(карта файлов). Здесь — **логика**: откуда берутся значения героев, как устроен игровой цикл,
модули, библиотеки анимаций/прожектайлов и ключевые утилиты. Все ссылки даны на `file:line`.

> Главный entry point сервера: [addon_game_mode.lua](scripts/vscripts/addon_game_mode.lua).
> Версия в коде: `FATE_VERSION = "v13.37"` ([addon_game_mode.lua:118](scripts/vscripts/addon_game_mode.lua:118)).

---

## 1. ⭐ Главное правило: герой = слот базового героя Dota (`override_hero`)

Кастомные Servant'ы **не новые юниты** — каждый «переопределяет» существующего героя Dota через
`override_hero` в `scripts/npc/heroes/npc_fate_hero_*.kv`. Движок применяет KV-блок поверх базового слота.

**Из этого следует самый важный факт для чтения кода:**
> `hero:GetName()` в Lua возвращает **имя базового слота Dota**, а НЕ имя Servant'а.

Поэтому по всему коду проверки вида:
```lua
if hero:GetName() == "npc_dota_hero_windrunner" then ...   -- это Nursery Rhyme
if hero:GetName() == "npc_dota_hero_doom_bringer" then ...  -- это Heracles
if hero:GetName() == "npc_dota_hero_legion_commander" then  -- это Arturia/Saber
```
`scripts/npc/custom_herolist.txt` тоже оперирует **базовыми** именами слотов (что включено/выключено).

### 1.1 Полная таблица Servant → слот Dota

(файл `npc_fate_hero_<name>.kv` → внутренний ключ KV → **слот Dota = реальное `GetName()`**)

| Файл (`npc_fate_hero_…`) | Внутренний ключ KV | Слот Dota (`override_hero`) |
|---|---|---|
| arturia (Saber) | npc_dota_hero_saber | **legion_commander** |
| arturia_alter (Saber Alter) | npc_dota_hero_saber_alter | **spectre** |
| emiya (Archer) | npc_dota_hero_archer_5th | **ember_spirit** |
| cu_chulain (Lancer) | npc_dota_hero_lancer_5th | **phantom_lancer** |
| medusa (Rider) | npc_dota_hero_rider_5th | **templar_assassin** |
| medea (Caster) | npc_dota_hero_caster_5th | **crystal_maiden** |
| heracles (Berserker) | npc_dota_hero_berserker_5th | **doom_bringer** |
| sasaki (False Assassin) | npc_dota_hero_false_assassin | **juggernaut** |
| true_assassin | npc_dota_hero_true_assassin | **bounty_hunter** |
| gilgamesh | npc_dota_hero_gilgamesh | **skywrath_mage** |
| gilles | npc_dota_hero_gille | **shadow_shaman** |
| iskandar (Rider) | npc_dota_hero_iskander | **chen** |
| nero | npc_dota_hero_nero | **lina** |
| jeanne | npc_dota_hero_jeanne | **mirana** |
| jeanne_alter | npc_dota_hero_jeanne_alter | **razor** |
| astolfo | npc_dota_hero_astolfo | **queenofpain** |
| atalanta | npc_dota_hero_atalanta | **drow_ranger** |
| atalanta_alter | npc_dota_hero_atalanta_alter | **ursa** |
| avenger | npc_dota_hero_avenger | **vengefulspirit** |
| diarmuid | npc_dota_hero_diarmuid | **huskar** |
| gawain | npc_dota_hero_gawain | **omniknight** |
| jtr (Jack the Ripper) | npc_dota_hero_jtr | **riki** |
| karna | npc_dota_hero_karna | **beastmaster** |
| kinghassan | npc_dota_hero_kinghassan | **skeleton_king** |
| lancelot | npc_dota_hero_lancelot | **sven** |
| leonidas | npc_dota_hero_leonidas | **venomancer** |
| li_shuwen | npc_dota_hero_li | **bloodseeker** |
| lu_bu | npc_dota_hero_centaur | **centaur** (ключ = слот, без override) |
| merlin | npc_dota_hero_merlin | **puck** |
| mordred | npc_dota_hero_mordred | **abaddon** |
| muramasa | npc_dota_hero_muramasa | **magnataur** |
| nanaya | npc_dota_hero_nanaya | **night_stalker** |
| nobu (Oda Nobunaga) | npc_dota_hero_nobu | **gyrocopter** |
| nursery_rhyme | npc_dota_hero_nursery_rhyme | **windrunner** |
| okada | npc_dota_hero_okada | **troll_warlord** |
| okita | npc_dota_hero_okita | **dark_willow** |
| ozy (Ozymandias) | npc_dota_hero_ozy | **phoenix** |
| robin (Robin Hood) | npc_dota_hero_robin | **sniper** |
| ryougi | npc_dota_hero_ryougi | **phantom_assassin** |
| saito | npc_dota_hero_saito | **terrorblade** |
| scathach | npc_dota_hero_scathach | **monkey_king** |
| tamamo | npc_dota_hero_tamamo | **enchantress** |
| vlad | npc_dota_hero_vlad | **tidehunter** |
| altera | npc_dota_hero_altera | **faceless_void** |
| aoko | npc_dota_hero_aoko | **ogre_magi** |
| arash | npc_dota_hero_arash | **clinkz** |
| arcueid | npc_dota_hero_arcueid | **tiny** |
| demon_king_nobunaga | npc_dota_hero_demon_king_nobunaga | **nevermore** |
| edmon (Edmond Dantès) | npc_dota_hero_dantes | **treant** |
| hijikata | npc_dota_hero_hijikata | **spirit_breaker** |

**Конфликты/варианты слотов** (один слот — один активный Servant):
- `terrorblade` ← saito **и** saito_hajime
- `phantom_assassin` ← ryougi **и** semiramis
- `naga_siren` ← chloe (слот выключен в herolist, см. ниже)

> ⚠️ Не все файлы в `heroes/` подключены: `npc_heroes_custom.txt` через `#base` грузит **51** файл.
> Например `semiramis` и `saito_hajime` присутствуют как `.kv`, но в `#base`-списке их нет — их слоты
> заняты ryougi/saito. `new.txt` (домерживается в [kv_data.lua:3](scripts/vscripts/data/kv_data.lua)) сейчас пустой (`"DOTAHeroes"{}`).

### 1.2 Что включено / выключено

`scripts/npc/custom_herolist.txt`, блок `"Selection"` — это **выбираемые** слоты:
- **Выключены (`"0"`)** в Selection: `npc_dota_hero_wisp` (служебный, см. §3), `npc_dota_hero_naga_siren` (chloe).
- Всё остальное в Selection = `"1"` (включено): legion_commander, spectre, phantom_lancer,
  ember_spirit, templar_assassin, crystal_maiden, juggernaut, bounty_hunter, doom_bringer,
  skywrath_mage, vengefulspirit, huskar, sven, shadow_shaman, chen, lina, omniknight,
  enchantress, bloodseeker, mirana, queenofpain, windrunner, drow_ranger, tidehunter,
  phantom_assassin, beastmaster, riki, dark_willow, abaddon, skeleton_king, ursa, razor,
  terrorblade, puck, magnataur, gyrocopter, tiny, venomancer, faceless_void, treant,
  night_stalker, clinkz, centaur, spirit_breaker, sniper, ogre_magi, nevermore, monkey_king,
  troll_warlord, phoenix.
- Другие блоки файла (`NoAbilities`, и т.п.) — служебные списки для движка, не выбор игрока.
- В разделе встречаются выключенные `npc_arena_hero_sai`, `npc_arena_hero_saitama`, `venomancer`(дубль) = `"0"`.

---

## 2. ⭐ Откуда берутся значения героя (статы)

Значения собираются из **4 слоёв**, по порядку применения:

**Слой 1 — базовый KV героя** (`scripts/npc/heroes/npc_fate_hero_*.kv`):
`StatusHealth`, `StatusMana`, `ArmorPhysical`, `MagicalResistance`, `AttackDamageMin/Max`,
`AttackRate`, `AttributeBaseStrength/Agility/Intellect`, `…Gain`, `Ability1..12`, `Model`, и т.д.
Пример: [npc_fate_hero_arturia.kv](scripts/npc/heroes/npc_fate_hero_arturia.kv).

**Слой 2 — глобальные правила конверсии атрибутов** (движок), задаются в
[addon_game_mode.lua:3921-3924](scripts/vscripts/addon_game_mode.lua:3921):
```lua
hGameModeEntity:SetControlFateMechanic( true )
hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0.0)         -- AGI не даёт броню
hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 2)    -- 2 AS за AGI
hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 9)             -- 9 HP за STR
```

**Слой 3 — кастомная система атрибутов Fate** ([modifiers/attributes.lua](scripts/vscripts/modifiers/attributes.lua)):
числа берутся из `scripts/npc/attributes.txt`:
```
HP_PER_STR 9 | HP_REGEN_PER_STR 0.25 | MANA_PER_INT 11 | MANA_REGEN_PER_INT 0.15
ATKSPD_PER_AGI 2 | MS_PER_AGI 1 | MAX_MS 550
MS_PER_STAT 3 | CDR_PER_STAT 0.7 | MR_PER_STAT 0.1 | GPS_PER_STAT 2.5
(DMG/ARMOR/HPREG/MPREG _PER_STAT помечены "does nothing")
```
`Attributes:Init()` ([attributes.lua:21](scripts/vscripts/modifiers/attributes.lua:21)) считает *дельту* между Fate-значениями и
дефолтами Dota и хранит как `*_adjustment`. На каждого героя при входе в игру зовётся
`Attributes:ModifyBonuses(hero)` ([attributes.lua:66](scripts/vscripts/modifiers/attributes.lua:66)) из
[addon_game_mode.lua:2526](scripts/vscripts/addon_game_mode.lua:2526). Она:
- навешивает набор lua-модификаторов: `modifier_attributes_hp/mp/hp_regen/mp_regen/ms/mr/cdr/gps/armor`
  (линкуются в [attributes.lua:7-18](scripts/vscripts/modifiers/attributes.lua:7), файлы `scripts/vscripts/modifiers/modifier_attributes_*.lua`);
- инициализирует поля `hero.STRgained/AGIgained/INTgained/DMGgained/ARMORgained/HPREGgained/…`
  (это «купленные у Мастера» бонус-статы, отдельно от уровневых);
- запускает **бесконечный таймер 0.1 c**, который каждый тик пересчитывает статы
  (`hero:CalculateStatBonus(true)`) и обновляет stack count модификаторов.

**Слой 4 — кастомные пер-стат бонусы** (`*gained`-поля): покупаются за ману Мастера (Master 2)
или прокачкой `attribute_bonus_custom`. Применяются теми же `modifier_attributes_*` через stack count.

> Итог: `итоговый стат = KV-база + (атрибуты × конверсия из attributes.txt) + *gained-бонусы`,
> и всё это динамически удерживается таймером 0.1 c в `ModifyBonuses`.

`donotlevel` ([util.lua:446](scripts/vscripts/libraries/util.lua:446)) — список абилок/пассивок, которые НЕ
левелятся автоматически в `LevelAllAbility` ([util.lua:1302](scripts/vscripts/libraries/util.lua:1302)).
`CannotReset` ([util.lua:501](scripts/vscripts/libraries/util.lua:501)) — абилки, чьи кулдауны не сбрасываются Command Seal'ом.

---

## 3. ⭐ Жизненный цикл героя

Все игроки сначала **форсятся в Wisp** — это «пустой» носитель до выбора Servant'а:
`SetCustomGameForceHero("npc_dota_hero_wisp")` ([addon_game_mode.lua:3902](scripts/vscripts/addon_game_mode.lua:3902)).

Поток: `npc_spawned` → `OnNPCSpawned` ([:2373](scripts/vscripts/addon_game_mode.lua:2373)) →
`OnHeroInGame(hero)` ([:2402](scripts/vscripts/addon_game_mode.lua:2402)).

В `OnHeroInGame` для Wisp вешается `modifier_dummy_pause` и выход ([:2409](scripts/vscripts/addon_game_mode.lua:2409)).
Для настоящего Servant'а (после выбора) делается ВСЁ ключевое:
- камера: `CameraModule:InitializeCamera` ([:2417](scripts/vscripts/addon_game_mode.lua:2417));
- обнуление золота/очков умений, `LevelAllAbility(hero)`, выдача `item_blink_scroll`, чистка талантов/фасетов;
- `hero.AltPart = AlternateParticle:initialise` (альт-партиклы), `hero.ServStat = ServantStatistics:initialise` (статистика);
- `Attributes:ModifyBonuses(hero)` (см. §2);
- **создаются 3 «Мастера»** (фишка мода):
  - `master_1` ([:2530](scripts/vscripts/addon_game_mode.lua:2530)) — Command Seal'ы; стартовый HP=7 → 12 печатей/10 мин;
    items `item_master_transfer_items1..6`;
  - `master_2` ([:2572](scripts/vscripts/addon_game_mode.lua:2572)) — атрибуты/комбо; `AddMasterAbility(master2, hero:GetName())`;
  - `master_3` = курьер ([:2596](scripts/vscripts/addon_game_mode.lua:2596)) — перенос предметов (`master_item_transfer_1..6`);
- `round_pause` на пре-гейм ([:2636-2648](scripts/vscripts/addon_game_mode.lua:2636));
- стартовое золото `+3050` и (для FFA/Trio) `+2` уровня, VICTORY_CONDITION=30 ([:2672-2688](scripts/vscripts/addon_game_mode.lua:2672)).

Команды печатей: `OnPlayerCastSeal` / `OnPlayerCastSeal1..6` ([:2014-2218](scripts/vscripts/addon_game_mode.lua:2014)).

---

## 4. ⭐ Игровой цикл и раунды

Состояния: `_G.CurrentGameState` (`"FATE_PRE_GAME"`…), `_G.IsPickPhase`, `_G.IsPreRound`,
`self.nCurrentRound`, счёт `self.nRadiantScore/nDireScore`, `VICTORY_CONDITION`
(по умолчанию **12**, для FFA/Trio = **30**) — [addon_game_mode.lua:95](scripts/vscripts/addon_game_mode.lua:95).

Константы времени: `PRE_ROUND_DURATION=12`, `ROUND_DURATION=120`, `BLESSING_PERIOD=480` ([:103-107](scripts/vscripts/addon_game_mode.lua:103)).

Ключевые методы машины состояний:
- `InitGameMode` ([:3855](scripts/vscripts/addon_game_mode.lua:3855)) — настройка GameRules под карту (число игроков на команду),
  фильтры, `ListenToGameEvent` (хуки) ([:3938-3972](scripts/vscripts/addon_game_mode.lua:3938)).
- `OnGameRulesStateChange` ([:2316](scripts/vscripts/addon_game_mode.lua:2316)) → `OnGameInProgress` ([:693](scripts/vscripts/addon_game_mode.lua:693))
  ставит `SetThink("OnGameTimerThink")`.
- `OnGameTimerThink` ([:4081](scripts/vscripts/addon_game_mode.lua:4081)) → каждую секунду `CountdownTimer()` (если не пауза).
- `InitializeRound` ([:4304](scripts/vscripts/addon_game_mode.lua:4304)) — пре-раунд: пауза героев (`round_pause`),
  `ResetAbilities/ResetItems/ResetMasterAbilities`, `RemoveTroublesomeModifiers`, выдача XP за раунд, UI-таймер.
- `FinishRound(IsTimeOut, winner)` ([:4576](scripts/vscripts/addon_game_mode.lua:4576)) — итог раунда, инкремент счёта,
  проверка `VICTORY_CONDITION` ([:4795,4870,4885](scripts/vscripts/addon_game_mode.lua:4795)), `nCurrentRound + 1` ([:4860](scripts/vscripts/addon_game_mode.lua:4860)).
- `OnEntityKilled` ([:3362](scripts/vscripts/addon_game_mode.lua:3362)) — смерти, first blood, условие победы по киллам в FFA ([:3683](scripts/vscripts/addon_game_mode.lua:3683)).

Спавны раундов чередуются по чётности раунда между `SPAWN_POSITION_RADIANT_DM`/`SPAWN_POSITION_DIRE_DM`
([:109-116, 2494-2523](scripts/vscripts/addon_game_mode.lua:109)). Карта определяется `_G.GameMap = GetMapName()`.

### Фильтры (регистрируются в InitGameMode)
- `TakeDamageFilter` ([:4112](scripts/vscripts/addon_game_mode.lua:4112)) — попап урона, спец-логика (Love Spot, Doppelganger anti-lethal).
- `ModifyGoldFilter` ([:4090](scripts/vscripts/addon_game_mode.lua:4090)) — обнуляет золото за килл героя.
- `ModifyExperienceFilter` ([:4104](scripts/vscripts/addon_game_mode.lua:4104)).
- `ExecuteProjectileFilter` ([:4159](scripts/vscripts/addon_game_mode.lua:4159)) — отмена авто-атак для Gil/Emiya (UBW).
- `ExecuteOrderFilter` ([:4166](scripts/vscripts/addon_game_mode.lua:4166)) — диспатч в `AnimeVectorTargeting` (векторное прицеливание).

---

## 5. Модули (`scripts/vscripts/modules/`)

Реестр — [modules/index.lua](scripts/vscripts/modules/index.lua). **Активные** (раскомментированы):

| Модуль | Что делает |
|---|---|
| `events/events` | Лёгкая шина событий: `Events:On/Off/Emit/Register` ([events.lua](scripts/vscripts/modules/events/events.lua)). Многие модули вешаются на `"activate"`. |
| `teams/teams` | Данные команд: цвета, имена, палитры цветов игроков ([teams.lua](scripts/vscripts/modules/teams/teams.lua)). |
| `hero_selection/hero_selection` | Фаза выбора: тайминги (`PICK_TIME=60`), стартовое золото (625), рандом/репик, фазы `HERO_SELECTION_PHASE_*`. Связан с panorama `fateanother_hero_selection`. |
| `options/options` | Голосуемые опции/настройки лобби, синк через `PlayerTables` в нет-таблицу `options`. |
| `chat/chat` | Чат + чат-команды (`commands` подмодуль): `-goldpls`, баны и т.д. Слушает `player_chat` и `custom_chat_send_message`. |

**Отключённые** (закомментированы в index.lua, код присутствует): `bosses`, `custom_abilities`,
`custom_runes`, `custom_talents`, `duel`, `dynamic_minimap`, `dynamic_wearables`, `gold`, `kills`,
`panorama_shop`, `simpleai`, `spawner`, `stats`, `structures`, `antiafk`, `meepo_fixes`, `weather`,
`console`, `illusions`, `verify`. (Это «барбонс»-задел; функциональность мода в основном живёт в
`addon_game_mode.lua` + `libraries/`, а не в этих модулях.)

---

## 6. ⭐ Библиотека анимаций ([libraries/animations.lua](scripts/vscripts/libraries/animations.lua))

Lua-controlled Animations by BMD. Управляет проигрыванием активностей/секвенций модели через
скрытые модификаторы. Линкует 4 модификатора ([animations.lua:63-66](scripts/vscripts/libraries/animations.lua:63)):
`modifier_animation`, `_translate`, `_translate_permanent`, `_freeze` (в `libraries/modifiers/`).

**Публичное API (глобальные функции + дубли в `GameRules`):**
- `StartAnimation(unit, {duration, activity, rate=1.0, translate, translate2})` ([:448](scripts/vscripts/libraries/animations.lua:448)) —
  играет анимацию. Повторный вызов отменяет предыдущую (с задержкой ~0.066 c). Кодирует
  activity+rate+translate в stack count модификатора (битовые сдвиги, [:457-464](scripts/vscripts/libraries/animations.lua:457)).
- `EndAnimation(unit)` ([:508](scripts/vscripts/libraries/animations.lua:508)).
- `FreezeAnimation(unit[, duration])` / `UnfreezeAnimation(unit)` ([:496,504](scripts/vscripts/libraries/animations.lua:496)) — стоп-кадр.
- `AddAnimationTranslate(unit, translate)` / `RemoveAnimationTranslate(unit)` ([:514,524](scripts/vscripts/libraries/animations.lua:514)) —
  постоянный translate-стенс (например «injured»/«aggressive»).

**Translate-коды:** огромный enum `_ANIMATION_TRANSLATE_TO_CODE` ([:70-446](scripts/vscripts/libraries/animations.lua:70)) маппит строковый
translate (`"haste"`, `"chakram"`, `"overload"`, кастомные `"rampant"=348`…) в числовой код.
**Если добавляешь новую кастомную секвенцию модели — нужно добавить её translate-код сюда вручную**,
иначе `StartAnimation` напечатает ошибку и не сыграет ([:460-462](scripts/vscripts/libraries/animations.lua:460)).

Ограничения: rate ≤ 12.75 с шагом 0.05; не более 2 translate-модификаторов одновременно.
Клиентская часть — `libraries/animations_cl.lua`.

---

## 7. ⭐ Прожектайлы

В моде ДВЕ библиотеки прожектайлов, но реально подключён **только** менеджер Fate
([addon_game_mode.lua:21](scripts/vscripts/addon_game_mode.lua:21): `require('libraries/fate_projectile_manager_test')`).
`libraries/projectiles.lua` (Physics-based от BMD) присутствует, но в основном цикле не используется.

### 7.1 `FATE_ProjectileManager` ([libraries/fate_projectile_manager_test.lua](scripts/vscripts/libraries/fate_projectile_manager_test.lua))

Самописный менеджер: свой `Think` ([:496](scripts/vscripts/libraries/fate_projectile_manager_test.lua:496)) обходит активные прожектайлы каждый
кадр (`Think_TRACKING` [:517], `Think_LINEAR` [:600]). Каждому присваивается uid (`AssignID` [:41](scripts/vscripts/libraries/fate_projectile_manager_test.lua:41)).

**Три типа:**

1. **`CreateTrackingProjectile(args)`** ([:51](scripts/vscripts/libraries/fate_projectile_manager_test.lua:51)) — самонаводящийся на `Target`.
   Ключи args: `Target`, `Source`/`Caster`, `Ability`, `EffectName`, `iMoveSpeed`,
   `iSourceAttachment` (ATTACK_1/ATTACK_2/HITLOCATION), `vSourceLoc`, `bDodgeable` (по умолч. true),
   `level` (по умолч. 3), `flExpireTime`, `ExtraData`, `CustomCallback`.
2. **`CreateLinearProjectile(args)`** ([:232](scripts/vscripts/libraries/fate_projectile_manager_test.lua:232)) — линейный.
   Ключи: `ability`, `caster` (обяз.), `source` (обяз.), `direction` (обяз.), `speed`, `distance`,
   `sourceLoc`, `sourceAttachment`, `CustomCallback`, и др. (ширина/визуал — дальше по функции).
3. **`CreateSlowingArea_Circle(args)`** ([:416](scripts/vscripts/libraries/fate_projectile_manager_test.lua:416)) — статическая зона эффекта (круг).

Управление: `DestroyTrackingProjectile(uid)` [:216], `DestroyArea(uid)` [:484],
`ProjectileDodge(unit)` [:208] (для абилок уклонения).

**Колбэки** определяются как методы абилки и подхватываются автоматически ([:107-120](scripts/vscripts/libraries/fate_projectile_manager_test.lua:107)):
`ability.OnProjectileHit` / `OnProjectileHit_ExtraData` / `OnProjectileThink` / `OnProjectileThink_ExtraData`,
либо `args.CustomCallback`. Это объясняет, почему в lua-абилках встречаются такие методы.

### 7.2 Старый `Projectiles` ([libraries/projectiles.lua](scripts/vscripts/libraries/projectiles.lua))
Physics-движок BMD (`Projectiles:CreateProjectile`, `CalcSlope`, `CalcNormal`, собственный `Think`).
Оставлен как наследие; новый код пишите на `FATE_ProjectileManager`.

---

## 8. ⭐ `libraries/util.lua` — общий тулкит (≈3000 строк)

Содержит две вещи: **классификационные таблицы модификаторов** и **функции-хелперы**.

### 8.1 Таблицы модификаторов (правила «как на это реагируют механики»)
В начале файла перечислены большие списки имён модификаторов — они задают **поведение механик**:
- `softdispellable` / `strongdispellable` / `deargdispellable` ([:4,50,124](scripts/vscripts/libraries/util.lua:4)) — что снимается
  обычным / сильным / Gáe Dearg диспелом. Применяются `ApplyPurge` [:2011], `ApplyStrongDispel` [:2029], `ApplyDeargDispel` [:2038].
- `revokes` / `locks` / `d_seal_locked` ([:205,228,221](scripts/vscripts/libraries/util.lua:205)) — что блокирует действия / печати. `IsRevoked` [:1574], `IsLocked` [:1581].
- `goesthruB` ([:254](scripts/vscripts/libraries/util.lua:254)) — абилки, игнорирующие B-scroll щит. `BIgnoreCheck` [:1808].
- `cleansable` / `slowmodifier` ([:263,397](scripts/vscripts/libraries/util.lua:263)) — что снимает Cleanse / какие именно слоу. `HardCleanse` [:1645], `RemoveSlowEffect` [:1659].
- `donotlevel` / `CannotReset` ([:446,501](scripts/vscripts/libraries/util.lua:446)) — см. §2.
- `femaleservant` ([:729](scripts/vscripts/libraries/util.lua:729)) — слоты-«женские» Servant'ы (для эффектов вроде Love Spot/charm). `IsFemaleServant` [:1596].
- `tCannotDetect`, `tDivineHeroes`, `tKnightClass`, `tHorsemanClass` ([:754,824,837,862](scripts/vscripts/libraries/util.lua:754)) — классы/категории для механик presence/discern.
- `tManalessHero`, `tModifierKBImmune`, `tRemoveTheseModifiers`, `tDangerousBuffs` — спец-списки.
- `itemComp` / `tItemComboTable` ([:771,781](scripts/vscripts/libraries/util.lua:771)) — рецепты комбинирования предметов (C→B→A→S→EX scroll и т.д.). Используют `CheckItemCombination(InStash)` [:1345,1388].
- `tipTable` ([:887](scripts/vscripts/libraries/util.lua:887)) — внутриигровые подсказки.

> Эти таблицы — **единое место правды**: добавил новый щит/слоу/диспеллабельный баф → внеси его имя
> в нужный список здесь, иначе механики диспела/клинза/печатей его «не увидят».

### 8.2 Важнейшие функции
- **`DoDamage(source, target, dmg, dmg_type, dmg_flag, abil, isLoop)`** ([:1816](scripts/vscripts/libraries/util.lua:1816)) —
  **центральная функция урона** мода. Обрабатывает composite-урон (`DAMAGE_TYPE_ALL` → треть phys/magic/pure
  через `DoCompositeDamage` [:1057]), распределение урона по «связанным» целям (`modifier_share_damage`,
  `target.linkTable`), флаг `NO_SPELL_AMPLIFICATION`. Всегда зовите её вместо сырого `ApplyDamage`.
- **Airborne / нокап:** `ApplyAirborne` [:1063], `ApplyAirborneOnly` [:1095], `ApplyReattachableAirborneOnly` [:1125]
  — подброс через Physics (`SetPhysicsVelocity/Acceleration`), иммунитет у `modifier_wind_protection_passive` / Avalon.
- **Спелл-блок (Linken-подобный):** `IsSpellBlocked(target, caster)` [:1501] — единый чекер всех «линкенов»
  мода (Instinct, Mind's Eye, Rho Aias, Ozy Mystic Eyes, Saito Mind Eye, …). Вызывать в начале таргет-абилок.
- **Урон/броня математика:** `GetPhysicalDamageReduction` [:1667], `CalculateDamagePre/PostReduction` [:1678,1693].
- **Вижн:** `SpawnVisionDummy` [:979], `SpawnAttachedVisionDummy` [:1024] (создают `sight_dummy_unit`).
- **Геометрия:** `CalculateAngle` [:900], `FATE_FindUnitsInLine` [:907], `RotateVector2D` [:1608],
  `IsFacingUnit` [:1627], `RandomPointInCircle` [:2150], `PointOnCircle` [:2157].
- **Реалмы/арены:** `IsInSameRealm(loc1, loc2)` [:1761] — разделение карты на зоны (нормальная карта /
  AotK / UBW / зона мастеров) по координатам. `IsFFA` [:2002], `IsTeamWiped` [:1986].
- **UI/звук/прочее:** `CreateUITimer` [:1735], `CreateGlobalParticle` [:1746], `EmitSoundWithCooldown` [:1565],
  `PlayBGM` [:1280], `DisplayTip` [:1716], `SendErrorMessage` [:1790], `SendKVToFatepedia` [:2105].
- `LevelAllAbility(hero)` [:1302] — левелит все абилки кроме `donotlevel`/талантов, помечает Combo и
  `IsResetable` по `CannotReset`. Вызывается в `OnHeroInGame`.

> Внимание: B-scroll щит и часть логики в `DoDamage` сейчас закомментированы — реальная обработка щитов
> может быть в другом месте (в OnTakeDamage обработчиках абилок). При правках урона читайте функцию целиком.

---

## 9. Прочие важные библиотеки

| Файл | Роль |
|---|---|
| `libraries/timers.lua` | `Timers:CreateTimer` — основа всей асинхронности (используется везде). |
| `libraries/physics.lua` | Physics-движок (используется в airborne/нокапах). |
| `libraries/crowdcontrol.lua` | CC-хелперы. |
| `libraries/attachments.lua` / `attachments_new.lua` | Прикрепление пропов/оружия к моделям. |
| `libraries/anime_vector_targeting.lua` | Векторное прицеливание (диспатч из `ExecuteOrderFilter`). |
| `libraries/servantstats.lua` | `ServantStatistics:initialise(hero)` — пер-герой статистика (урон и т.п.). |
| `libraries/alternateparticle.lua` | `AlternateParticle:initialise(hero)` — альт-партиклы. |
| `libraries/cameramodule.lua` | `CameraModule:InitializeCamera`. |
| `libraries/popups.lua` | `PopupDamage` и т.п. всплывающие числа. |
| `libraries/playertables.lua` | `PlayerTables` — синк данных на клиент (используется Options). |
| `libraries/notifications.lua` | Тосты/уведомления на экране. |
| `data/ability_functions.lua` | Глобальные таблицы боёвки: `BOSS_DAMAGE_ABILITY_MODIFIERS`, `ON_DAMAGE_MODIFIER_PROCS` (проки октарина/рефрешера/Sara и т.д.), лайфстил. |
| `data/abilities.lua` | `LINKED_ABILITIES`, `MULTICAST_*`, бан-листы боссов, рефреш-листы. |

---

## 10. Рецепт: как менять/добавлять героя (с учётом логики)

1. **Выбрать свободный слот Dota** и включить его в [custom_herolist.txt](scripts/npc/custom_herolist.txt) (`"1"`).
2. **KV героя:** `scripts/npc/heroes/npc_fate_hero_<name>.kv` с `override_hero "<слот>"`, статами, `Ability1..12`,
   `Model`; добавить `#base` в [npc_heroes_custom.txt](scripts/npc/npc_heroes_custom.txt).
3. **KV способностей:** `scripts/npc/abilities/<servant>/<servant>_abilities.kv` (+ вложенные `#base`),
   у lua-абилок `"BaseClass" "ability_lua"` + `"ScriptFile" "abilities/<servant>/<ability>"`;
   добавить `#base` в [npc_abilities_custom.txt](scripts/npc/npc_abilities_custom.txt).
4. **Lua способностей:** `scripts/vscripts/abilities/<servant>/*.lua` (+ `modifiers/`). Внутри:
   - урон — через `DoDamage` (§8.2); таргет-абилки начинать с `IsSpellBlocked`;
   - прожектайлы — `FATE_ProjectileManager:Create*` с методами-колбэками `OnProjectileHit/Think` (§7);
   - анимации — `StartAnimation` (§6), новые translate-коды добавить в enum;
   - новые щиты/слоу/диспеллабельные/печать-блокирующие модификаторы — **вписать в таблицы util.lua** (§8.1).
5. **В `hero:GetName()`-проверках кода** использовать **имя слота Dota** (§1), не имя Servant'а.
6. **Ассеты** (модель/партиклы/иконки/звук) — править в `content/`, перекомпилировать; тексты — `resource/addon_english.txt`.
7. Если нужны спец-хуки на спавн/раунд — смотреть `OnHeroInGame` (§3) и `InitializeRound` (§4).

---

## 11. Шпаргалка «где логика»

| Вопрос | Ответ |
|---|---|
| Какой Servant — какой слот? | §1.1 (или `grep override_hero scripts/npc/heroes/*.kv`) |
| Откуда статы героя? | KV + `attributes.txt` + `modifiers/attributes.lua` + `SetCustomAttributeDerivedStatValue` (§2) |
| Что происходит при спавне героя? | `OnHeroInGame` [addon_game_mode.lua:2402] (§3) |
| Раунды/победа/счёт? | `InitGameMode`/`InitializeRound`/`FinishRound`/`OnGameTimerThink` (§4) |
| Центральная функция урона? | `DoDamage` [util.lua:1816] |
| Спелл-блок (линкен)? | `IsSpellBlocked` [util.lua:1501] |
| Подброс в воздух? | `ApplyAirborne*` [util.lua:1063+] |
| Прожектайлы? | `FATE_ProjectileManager` (§7) |
| Анимации/translate-коды? | `animations.lua` (§6) |
| Диспел/клинз/слоу-списки? | таблицы в начале `util.lua` (§8.1) |
| Активные подсистемы? | `modules/index.lua` (§5) |
| Чат-команды? | `modules/chat/` |
| Фаза выбора героя? | `modules/hero_selection/` + panorama `fateanother_hero_selection` |
