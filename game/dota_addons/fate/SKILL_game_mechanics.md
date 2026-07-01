# SKILL: Игровые механики Fate

Глубокий разбор основных механик мода. Дополняет [SKILL_systems_and_heroes.md](SKILL_systems_and_heroes.md)
(архитектура) и [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) (карта файлов). Ссылки — `file:line`.

Темы: командные заклинания · предметы · прокачка/атрибуты · комбо · кастомные функции vs API ·
очищение/диспел · revoke/dimensional lock · система скинов.

---

## 1. ⭐ Командные заклинания (Command Seals)

Реализация: [master_ability.lua](scripts/vscripts/master_ability.lua), хэндлеры
`OnSeal1Start..OnSeal4Start` ([:17,125,205,267](scripts/vscripts/master_ability.lua:17)); диспетчер каста —
`OnPlayerCastSeal` ([addon_game_mode.lua:2014](scripts/vscripts/addon_game_mode.lua:2014)) и `OnPlayerCastSeal1..6` ([:2136+](scripts/vscripts/addon_game_mode.lua:2136)).

**Носитель:** печати кастует `master_1` (юнит «Мастер», создаётся в `OnHeroInGame`, стартовый HP=7).
**Ресурс — HP Мастера** (не мана!): каждая печать тратит HP Мастера. Мастер реген HP ограничен →
лимит ~12 печатей / 10 минут (см. tip в [util.lua:892](scripts/vscripts/libraries/util.lua:892)). `modifier_command_seal_mana_regen`.

| Печать | Хэндлер | Стоимость HP | Эффект | CD после (общий на все печати) |
|---|---|---|---|---|
| **Seal 1** (Q) | `OnSeal1Start` [:17] | **−2 HP** | Накладывает `modifier_command_seal_1` на героя и Мастера (защитный баф/очистка). `ServStat:useQSeal()` | `cmd_seal_1` на 60 c |
| **Seal 2** (W) | `OnSeal2Start` [:125] | **−1 HP** | `ResetAbilities(hero)` + `ResetItems(hero)` + `IncrementCharges(hero)` — **сброс КД способностей и предметов** (рефреш). `modifier_command_seal_2` | все печати на 30 c |
| **Seal 3** (E) | `OnSeal3Start` [:205] | **−1 HP** | **Полный хил** (`hero:Heal(maxHP−curHP)`). `modifier_command_seal_3` | все на 20 c |
| **Seal 4** (R) | `OnSeal4Start` [:267] | **−1 HP** | **Полное восстановление маны** (`SetMana(maxMana)`). Запрещена безмановым (Juggernaut). `modifier_command_seal_4` | все на 10 c |

**Общие правила всех печатей:**
- Блокируются если `hero` мёртв или `IsRevoked(hero)` — кроме случая `modifier_master_intervention`
  ([master_ability.lua:29,152,217,282](scripts/vscripts/master_ability.lua:29)). Ошибка `#Revoked_Error`.
- Блокируются если HP Мастера ≤ 1–2 (`#Master_Not_Enough_Health`).
- **`IsFirstSeal`** ([:57](scripts/vscripts/master_ability.lua:57)): первая печать в окне — особая (флаг на 20 c). Если активна,
  последующая печать в окне идёт **без общего КД** и с возвратом ресурсов (см. [:190,256,320](scripts/vscripts/master_ability.lua:190)).
- `ResetAbilities` ([:68](scripts/vscripts/master_ability.lua:68)) сбрасывает только способности с `ability.IsResetable ~= false`
  (флаг ставится по таблице `CannotReset` в `LevelAllAbility`, см. §4). Сначала `RemoveChargeModifiers`.
- Каждая печать дёргает статистику: `ServStat:useQSeal/useWSeal/useESeal/useRSeal`.

**Раундовый сброс печатей:** `ResetMasterAbilities(hero)` ([:93](scripts/vscripts/master_ability.lua:93)) — `EndCooldown`
на cmd_seal_1..4 + `master_presence_resonator` + `master_intervention`. Вызывается в `InitializeRound`.

> Доп. способности Мастера: `master_presence_resonator` (обнаружение), `master_intervention`
> (даёт каст печати даже в revoke). «D-seal» (блинк) — отдельно через `item_blink_scroll`, см. §7.

---

## 2. ⭐ Предметы

KV: [npc_items_custom.txt](scripts/npc/npc_items_custom.txt) (#base подключает `items/item_*.txt`),
часть — `scripts/npc/items/`. Lua-логика: [items.lua](scripts/vscripts/items.lua) и `scripts/vscripts/items/`.

### 2.1 Система свитков (Scroll) и комбинирование
Базовые расходники — «свитки защиты/контроля». Рецепты комбинирования заданы в
[util.lua:771-788](scripts/vscripts/libraries/util.lua:771) (`itemComp`, `tItemComboTable`):
```
C scroll + C scroll → B scroll → A scroll → S scroll → EX scroll
mana_essence + mana_essence → condensed_mana_essence
mana_essence + recipe_healing_scroll → healing_scroll
a_scroll + recipe_a_plus_scroll → a_plus_scroll
```
Авто-комбинирование при получении предмета: `CheckItemCombination(hero)` (инвентарь, [:1345](scripts/vscripts/libraries/util.lua:1345))
и `CheckItemCombinationInStash(hero)` (стэш, [:1388](scripts/vscripts/libraries/util.lua:1388)) — ищут две одинаковые компоненты,
удаляют, создают результат через `CreateItemAtSlot` ([:1464](scripts/vscripts/libraries/util.lua:1464)). Рецепты также парсятся из KV в
`ParseCombinationKV` ([items.lua:10](scripts/vscripts/items.lua:10)).

Назначение свитков (Lua в `items/`): `c_scroll.lua` (прерывание/мгновенный каст), `b_scroll.lua`
(щит от маг. урона — связан с `goesthruB`/B-shield, см. §6), `a_scroll`/`modifier_a_scroll`
(снижение урона на время), `sex_scrolls.lua` (root/slow CC), `blink_scroll.lua` (D-seal блинк, §7),
`mana_essence.lua` (мана), `shard_of_replenishment.lua` (Shard of Holy Grail — выдаётся после 7 смертей).

### 2.2 Покупка и переноска
- **Quick-buy:** `OnPlayerCustomQuickBuy` ([addon_game_mode.lua:2052](scripts/vscripts/addon_game_mode.lua:2052)). Цена ×1.5 если герой
  **вне базы** (`not hHero.IsInBase`). Проверки слотов (`IsItemFullSlot`/`IsStashFullSlot`/`IsInventoryFullSlot`
  в [items.lua:125+](scripts/vscripts/items.lua:125)). Авто-запрос золота при <200g.
- **База** определяется триггерами входа/выхода (`OnBaseEntered/Left`, Trio/FFA-варианты, [items.lua:38-123](scripts/vscripts/items.lua:38)).
- **Перенос предметов:** два пути — курьер `master_3` (абилки `master_item_transfer_1..6`) **и** Мастер
  `master_1` (айтемы `master_transfer_items1..6`); функции `TransferItem`/`AutoTransferItem` ([items.lua:168,203](scripts/vscripts/items.lua:168)).
  Опция авто-переноса — `ply.AutoTransferItemEnabled` (`OnConfig9Checked`); также есть бинд кнопки в самой Dota.
- **Стартовый набор героя** (в `OnHeroInGame`): 4× `item_dummy_item_unusable` в слоты, `item_blink_scroll`,
  стартовое золото **+3050** ([addon_game_mode.lua:2431-2446,2688](scripts/vscripts/addon_game_mode.lua:2431)).
- **TP:** `TPScroll`/`MassTPSuccess`/`item_teleport_scroll`/`item_mass_teleport_scroll` ([items.lua:280,431](scripts/vscripts/items.lua:280)).

---

## 3. ⭐ Прокачка: статы и атрибуты

Есть **три независимых канала** роста силы героя:

**(A) Уровни героя** — `MAX_LEVEL=24`, кастомные XP-значения (`SetUseCustomHeroXPValues`).
Прокачка способностей — НЕ ручная: `LevelAllAbility(hero)` ([util.lua:1302](scripts/vscripts/libraries/util.lua:1302)) при спавне
левелит все способности до 1 (кроме списка `donotlevel`); таланты Dota удаляются ([addon_game_mode.lua:2454](scripts/vscripts/addon_game_mode.lua:2454)).
XP за раунд начисляется в `InitializeRound` (`hero:AddExperience(nCurrentRound*100)`).

**(B) Атрибуты STR/AGI/INT** — конверсия в статы (см. §2 предыдущего скилла):
KV-база героя → `attributes.txt` (HP_PER_STR=9, MANA_PER_INT=11, ATKSPD_PER_AGI=2, MS_PER_AGI=1,
AGI не даёт броню) → `Attributes:ModifyBonuses` ([modifiers/attributes.lua:66](scripts/vscripts/modifiers/attributes.lua:66)) с таймером
пересчёта 0.1 c → `modifier_attributes_*`. Глобальные конверсии — `SetCustomAttributeDerivedStatValue`
([addon_game_mode.lua:3922](scripts/vscripts/addon_game_mode.lua:3922)).

**(C) Покупка бонус-статов у Мастера 2 за ману** — основной «фарм» мода.
Способности на `master_2`: `master_strength/agility/intelligence/damage/health_regen/mana_regen/gold_per_second_new`
(добавляются в `AddMasterAbility` [master_ability.lua:400](scripts/vscripts/master_ability.lua:400)). Хэндлеры — `OnStrengthGain` [:571],
`OnAgilityGain` [:597], `OnIntelligenceGain` [:635], `OnDamageGain` [:669], `OnArmorGain` [:713],
`OnHPRegenGain` [:739], `OnManaRegenGain` [:770], `OnMovementSpeedGain` [:805], `OnGpsGain` [:838].

Каждое нажатие:
- проверяет **кап = 30** на данный стат (`hero.STRgained < 30`, иначе `#Cannot_Get_Over_30_Stats` + возврат маны);
- увеличивает `hero.<X>gained` и базовый стат (`SetBaseStrength(+1)` и т.п.), зовёт `CalculateStatBonus(true)`;
- AGI даёт **и AGI, и +1 ARMORgained** ([:613-626](scripts/vscripts/master_ability.lua:613)); INT обновляет CDR-модификатор ([:660](scripts/vscripts/master_ability.lua:660));
- тратит ману Мастера (`master1:SetMana(... - ManaCost)`); **мана master_1 и master_2 синхронизирована**
  (списывается фактически у обоих — это один общий пул маны Мастера);
- шлёт `servant_stats_updated` на клиент (UI), `ServStat:addStr/addAgi/...`.
- Juggernaut (безмановый) не может брать INT (`#Cannot_Acquire_Intelligence`).

**Особые приобретения** (за достижения/ману): `OnAvariceAcquired`, `OnAMAcquired` (Mad Enhancement?),
`OnReplenishmentAcquired`, `OnProsperityAcquired` ([:871-1017](scripts/vscripts/master_ability.lua:871)).

`*gained`-поля хранятся на герое и читаются `CreateTemporaryStatTable` ([util.lua:2124](scripts/vscripts/libraries/util.lua:2124)) для UI.

---

## 4. ⭐ Комбо-способности

Каждый герой имеет одну **Combo** — мощную способность, доступную при условии (обычно **30 во всех статах**).

**⚠️ Два разных кулдауна (важно):**
- На юните **Мастер 2** копия комбо стоит на `StartCooldown(9999)` ([`LoopThroughAttr`:432](scripts/vscripts/master_ability.lua:432)) —
  это **чисто демонстрационный** дисплей (Мастер не может кастовать способности). Реальный статус
  комбо для UI Мастера выставляет `OnComboCheck` ([master_ability.lua:1145](scripts/vscripts/master_ability.lua:1145)) через модификаторы
  `combo_unavailable` (условие не выполнено) / `combo_cooldown` (на перезарядке).
- На самом **герое** комбо — обычная способность со своим КД из KV; её доступность гейтится статами
  (см. ниже), а не блокирующим CD 9999.

**Каноничный реестр комбо:** таблица `heroCombos` в [util.lua:2577](scripts/vscripts/libraries/util.lua:2577) (ключ = слот Dota →
имя комбо-абилки). Читается `GetHeroCombo(hero)` [:2630]. Примеры: legion_commander→`saber_max_excalibur`,
doom_bringer→`berserker_5th_madmans_roar`, ember_spirit→`emiya_combo`.

**Условие доступности — `GetComboAvailability(hero)`** ([util.lua:2638](scripts/vscripts/libraries/util.lua:2638)):
```
-1  — комбо НЕдоступно (не набраны статы)
 0  — доступно и готово
 >0 — доступно, но на перезарядке (возвращает остаток КД)
```
Требование по статам — **актуальные** значения атрибутов (не «gained»): обычно STR/AGI/INT каждый **≥ 19.1**;
Juggernaut — STR и AGI **≥ 24.1** (без INT); Sven/Lancelot с активным `modifier_arondite` получает
надбавку к порогу (`bonus_allstat`). (В тултипах фигурирует «30 all stats» — это ориентир для игрока;
код-гейт = значения выше.)

`hero.ComboName` ([`LoopThroughAttr`:428](scripts/vscripts/master_ability.lua:428)) = последний элемент массива
`attributesandcombo` из PlayerTables `hero_selection_heroes_data[<heroName>]` (`FindAttribute` [:438]).

**Пометка комбо у способностей:** в `LevelAllAbility` ([util.lua:1315](scripts/vscripts/libraries/util.lua:1315)):
`if GetHeroCombo(hero) == ability:GetName() then ability.IsCombo = true`. Флаг `IsCombo` влияет на CDR
(`modifier_attributes_cdr` пропускает комбо, [modifier_attributes_cdr.lua:28](scripts/vscripts/modifiers/modifier_attributes_cdr.lua:28)) и на сброс
печатью (комбо обычно в `CannotReset`, §1).

**Управление видимостью комбо** на Мастере 2: `OnStatList1Open/OnStatList2Open/OnShardOpen` и
`caster:AddAbility(caster.ComboName)` / `RemoveAbility(caster.ComboName)` ([:487-546](scripts/vscripts/master_ability.lua:487)).

**Внутри героев** комбо-секвенции отслеживаются своими флагами/модификаторами:
`caster.IsComboActive` (gawain), `caster.IsComboReady` (gilles), `combo_available` (saber), и т.п.
Требования и последовательность кнопок описаны в тултипах (`resource/addon_english.txt`,
напр. «Combo Requirement : 30 all stats», «Combo Sequence : Q-W-D in 4 seconds»).

`CannotReset` ([util.lua:501](scripts/vscripts/libraries/util.lua:501)) — длинный список комбо/особых абилок, чьи КД печать W не сбрасывает.

---

## 5. ⭐ Кастомные функции vs стандартный API

Стандартный API: <https://moddota.com/api/#/vscripts>. Ниже — **наши** глобальные функции и
расширения классов (которых нет в ванильном API; вызывать их можно как родные).

### 5.1 Расширения методов юнита (через `Wrappers.WrapUnit`, [wrappers.lua:3](scripts/vscripts/wrappers.lua:3))
- **`unit:ApplyHeal(fAmount, hSource, ...)`** [:5] — хил с учётом кап-оверхила и **хуков модификаторов**
  `modifier:OnHeal(...)` / `modifier:DisableHeal()`. Используйте вместо сырого `:Heal`, если нужны реакции.
- **`unit:Execute(hAbility, hKiller, tParams)`** [:34] — «добивание» с хуками `modifier:OnKill()` /
  `modifier:BlockExecute()` (учитывает Battle Continuation у Skeleton King и Avalon).
- **`Wrappers.ChargedBeam(ability, ability2)`** [:61] — каркас заряжаемых лучей (Saber/Excalibur-подобные):
  каналирование, `__Formula`/`ChargeGetTotal`, swap на `_activate`, `LaunchBeam`.

### 5.2 Расширения `CDOTA_BaseNPC` (определены в util.lua)
- `CDOTA_BaseNPC:SetUnitOnClearGround()` ([util.lua:1085](scripts/vscripts/libraries/util.lua:1085)) — посадить на чистую землю.

### 5.3 Боёвка / урон (глобальные)
- **`DoDamage(source, target, dmg, dmg_type, dmg_flag, abil, isLoop)`** [util.lua:1816] — ЦЕНТРАЛЬНАЯ
  функция урона (composite, share_damage/linkTable, NO_SPELL_AMP). Поверх `ApplyDamage`.
- `DoCompositeDamage(...)` [:1057] — урон тремя типами (⅓ phys/magic/pure).
- `CalculateDamagePreReduction` / `CalculateDamagePostReduction` [:1678,1693], `GetPhysicalDamageReduction` [:1667].
- `ApplyAirborne` / `ApplyAirborneOnly` / `ApplyReattachableAirborneOnly` [:1063,1095,1125] — подброс (Physics).
- `IsSpellBlocked(target, caster)` [:1501] — единый «линкен»-чекер мода.
- `ReduceCooldown(ability, reduction)` [:1709].

### 5.4 Очищение/диспел/CC-проверки
`ApplyPurge` [:2011], `ApplyStrongDispel` [:2029], `ApplyDeargDispel` [:2038], `HardCleanse` [:1645],
`RemoveSlowEffect` [:1659], `IsRevoked` [:1574], `IsLocked` [:1581], `IsImmuneToSlow` [:1617],
`BIgnoreCheck` [:1808], `IsRevivePossible` [:1588], `IsFemaleServant` [:1596]. (Подробно — §6, §7.)

### 5.5 Поиск/геометрия/вижн
`FATE_FindUnitsInLine` [:907], `CalculateAngle` [:900], `RotateVector2D` [:1608], `IsFacingUnit` [:1627],
`RandomPointInCircle` [:2150], `PointOnCircle` [:2157], `SpawnVisionDummy` [:979],
`SpawnAttachedVisionDummy` [:1024], `IsInSameRealm` [:1761].

### 5.6 Менеджеры (классы, не из API)
- **`FATE_ProjectileManager`** ([libraries/fate_projectile_manager_test.lua](scripts/vscripts/libraries/fate_projectile_manager_test.lua)):
  `CreateTrackingProjectile` / `CreateLinearProjectile` / `CreateSlowingArea_Circle` (см. скилл систем §7).
- **Анимации** ([libraries/animations.lua](scripts/vscripts/libraries/animations.lua)): `StartAnimation`/`EndAnimation`/`FreezeAnimation`/
  `AddAnimationTranslate` (+ дубли в `GameRules.*`).
- `Timers` (timers.lua), `Physics` (physics.lua), `Attachments`, `ServantStatistics`, `AlternateParticle`,
  `CameraModule`, `PlayerTables`, `Notifications`, `PopupDamage`, `Sounds:EmitSoundOnAllClient`.

### 5.7 Прочее
`GiveGold(senderID, receiverID, amount)` [:1176], `LevelAllAbility(hero)` [:1302],
`CheckItemCombination(InStash)` [:1345,1388], `CreateUITimer` [:1735], `CreateGlobalParticle` [:1746],
`EmitSoundWithCooldown` [:1565], `EmitSoundOnAllClient` [:1335], `SendErrorMessage` [:1790],
`PrintTable` [:2067], `spairs` [:1189], `round` [:1239], `SumTable` [:1224], `MaxNumTable` [:1233].

> Правило: для урона — `DoDamage`; для хила с реакциями — `unit:ApplyHeal`; для добивания — `unit:Execute`;
> для прожектайлов — `FATE_ProjectileManager`; для анимаций — `StartAnimation`. НЕ зовите сырые
> `ApplyDamage`/`Heal`/`Kill`, если нужны механики мода.

---

## 6. ⭐ Очищение (Cleanse) и диспел (Dispel)

Вся классификация — таблицы в начале [util.lua](scripts/vscripts/libraries/util.lua:4). Это «единое место правды»:
если эффект не вписан в нужный список — механики его «не видят».

**Три уровня диспела** (по силе; каждый последующий снимает больше):
| Функция | Таблица | Что снимает |
|---|---|---|
| `ApplyPurge(target)` [:2011] | `softdispellable` [:4] | слабые бафы (только мягкий диспел) |
| `ApplyStrongDispel(target)` [:2029] | `strongdispellable` [:50] | soft + сильные щиты/бафы |
| `ApplyDeargDispel(target)` [:2038] | `deargdispellable` [:124] | максимальный (Gáe Dearg) — всё из strong + ещё больше |

Особый случай в `ApplyPurge`: `modifier_courage_stackable_buff` снимается по 2 стака, а не целиком ([:2013](scripts/vscripts/libraries/util.lua:2013)).
`modifier_share_damage` дополнительно вызывает `RemoveHeroFromLinkTables` при снятии.

**Cleanse (снятие CC/слоу с себя/союзника):**
- `HardCleanse(target)` [:1645] — снимает всё из `cleansable` [:263] **и** из `slowmodifier` [:397].
- `RemoveSlowEffect(target)` [:1659] — только слоу (`slowmodifier`).
- `cleansable` — огромный список (слоу всех героев, stun/silence/root/knockback/disarm и спец-дебаффы).
- `slowmodifier` — только модификаторы замедления.

**Связанные проверки:** `IsImmuneToSlow(target)` [:1617] (Berserk+Mad Enhancement, modifier_forward),
`tDangerousBuffs`/`tRemoveTheseModifiers` — спец-списки.

> При добавлении нового щита/слоу/дебаффа: впиши имя в `cleansable`/`slowmodifier` (для cleanse) и в
> соответствующие `*dispellable` (для диспела). Иначе он не будет сниматься.

---

## 7. ⭐ Revoke и Dimensional Lock

Это две РАЗНЫЕ механики контроля (часто путают):

### 7.1 Revoke (отзыв)
**Что:** в первую очередь — **запрет кастовать командные печати** (это единственный прямой эффект самого
«revoke»-чека). Невозможность *двигаться/действовать* в `round_pause`/`jump_pause` обеспечивают **сами эти
модификаторы** (пауза), а не «revoke» как механика; они просто заодно входят в таблицу `revokes`.
**Проверка:** `IsRevoked(target)` ([util.lua:1574](scripts/vscripts/libraries/util.lua:1574)) — проходит по таблице `revokes` [:205]:
`modifier_ubw_chronosphere`, `jump_pause`, `pause_sealdisabled`, `rb_sealdisabled`, `revoked`,
`round_pause`, `modifier_nss_shock`, `modifier_tres_fontaine_nero` и др.
**Где применяется:** во всех `OnSealNStart` (печать запрещена в revoke, кроме `modifier_master_intervention`)
и в `OnPlayerCastSeal`. Источники revoke — ульты-«реалии»: UBW, Ionioi Hetairoi, Berserker Madman's Roar и т.п.
`round_pause` — это тоже revoke (пауза между раундами).
Подмножество `d_seal_locked` [:221] — что именно блокирует D-seal даже когда intervention доступен.

### 7.2 Dimensional Lock (измеренческий замок)
**Что:** запрет **блинка/телепорта/прыжка** (анти-escape CC). По лору — «запечатывание измерения».
**Проверка:** в [item_blink_scroll.lua](scripts/vscripts/items/blink_scroll.lua) есть локальная таблица `locks` + метод
`CheckLocks(caster)` → блинк возвращает `UF_FAIL_CUSTOM` если на касторе любой из:
`modifier_sex_scroll_root`, `locked`, `dragged`, `jump_pause_postlock`, `modifier_rho_aias(_emiya)`,
`modifier_gordius_wheel`, `modifier_altera_dash`, `modifier_nero_tres_new`, `modifier_arcueid_melty`,
`modifier_robin_yew_bow_combo_lock`, `modifier_cu_chulain_combo`, `modifier_jeanne_health_lock` и др.
Аналогичная таблица `locks` + `IsLocked(target)` есть и в [util.lua:228,1581](scripts/vscripts/libraries/util.lua:228) (для прочих
проверок «закреплён ли юнит»). Применяют dimensional lock: Excalibur, Cu Gae Bolg/combo (Heartbreak,
undispellable), Emiya Big Swords, Berserker Madman's Roar и др. (см. тултипы в addon_english.txt).

> ⚠️ Двойственность: `locks` существует в ДВУХ местах (util.lua и blink_scroll.lua) с **разными** списками.
> Для запрета блинка правь именно `blink_scroll.lua`.

### 7.3 Реалмы и Dimension Exception (контекст)
Карта поделена на **реалмы** (физические зоны по координатам): обычная карта / AotK (Aestus Domus Aurea) /
UBW / зона Мастеров — `IsInSameRealm(loc1, loc2)` ([util.lua:1761](scripts/vscripts/libraries/util.lua:1761)). **Reality Marble**-ульты
(`emiya_unlimited_bladeworks`, `iskander_ionioi`, Nero AotK) **физически телепортируют** врагов в свою зону
через `SetAbsOrigin` и вручную снимают конфликтующие модификаторы (`modifier_aestus_domus_aurea_*`,
`modifier_unlimited_bladeworks`, и т.д.) — см. [iskander_ionioi.lua:272-525](scripts/vscripts/abilities/iskandar/iskander_ionioi.lua:272),
[emiya_unlimited_bladeworks.lua:318+](scripts/vscripts/abilities/emiya/emiya_unlimited_bladeworks.lua:318).
Многие модификаторы объявляют метод **`IsDimensionException() -> true`** (напр.
[hero_replacer.lua:219](scripts/vscripts/modules/hero_selection/hero_replacer.lua:219) — скин).
> ✅ **Уточнено:** `IsDimensionException()` — **мёртвый код**. Generic-цикла, который его читает, нет;
> переносящие ульты снимают конфликтующие модификаторы **поимённо** (`RemoveModifierByName`).
> Метод-интерфейс остался от старой реализации и сейчас ни на что не влияет — при правках на него не закладывайтесь.

---

## 8. ⭐ Система скинов

Скины — **кастомная** система (НЕ Dota-косметика/wearables).

**Данные:** на каждого героя в PlayerTables `hero_selection_heroes_data[<heroName>].skins["skin_N"]`
с полем `.model` (путь к .vmdl). `skin_0` — базовый.

**Выбор:** в фазе пика игрок выбирает скин → `HeroSelection:SelectHero(plyId, hero, …, skinNumber)`
([hero_selection.lua:509,516](scripts/vscripts/modules/hero_selection/hero_selection.lua:509), сохранение `tableData.skin` в [util.lua:294](scripts/vscripts/modules/hero_selection/util.lua:294)).

**Применение:** [hero_replacer.lua:58](scripts/vscripts/modules/hero_selection/hero_replacer.lua:58) — если `skinNumber ≠ 0`, на героя вешается
`modifier_hero_selection_skin {skinNumber=N}` ([:212](scripts/vscripts/modules/hero_selection/hero_replacer.lua:212)). Модификатор:
- скрытый, непургуемый, **переживает смерть** (`RemoveOnDeath()=false`), `IsDimensionException()=true`;
- `OnCreated` читает `skins["skin_N"].model` (или `skin_0` как фолбэк) ([:231-245](scripts/vscripts/modules/hero_selection/hero_replacer.lua:231));
- **`GetModifierModelChange` → подменяет модель героя** на модель скина ([:228](scripts/vscripts/modules/hero_selection/hero_replacer.lua:228)),
  объявляя `MODIFIER_PROPERTY_MODEL_CHANGE`.

**Бранчинг в способностях:** каждая способность сама проверяет скин и подменяет FX/звук/доп-модель:
```lua
if caster:HasModifier("modifier_hero_selection_skin")
   and caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
       -- использовать партиклы/звуки скина (напр. jia_qiu вместо lu_bu)
end
```
Пример — Jia Qiu (skin 1) над Lu Bu: [lu_bu_armistice.lua:52-93](scripts/vscripts/abilities/lu_bu/lu_bu_armistice.lua:52),
`lu_bu_god_strike.lua`, и т.д. (звук `jia_qiu_armistice`, партикл `particles/custom/jia_qiu/...`).

> Чтобы добавить скин: 1) положить модель/FX/звуки в `content/`, перекомпилировать; 2) добавить запись
> `skins.skin_N.model` в данные героя для PlayerTables (hero_selection); 3) в нужных способностях добавить
> ветку `skinNumber == N` для подмены FX/звуков. Смена самой **модели** делается автоматически модификатором.

---

## 9. ⭐ Обнаружение присутствия (Presence Detection)

Механика «чувства» вражеских Servant'ов рядом. Реализация — `OnPresenceDetectionThink`
([master_ability.lua:1020](scripts/vscripts/master_ability.lua:1020)), пассивка `presence_detection_passive` на герое
(и `master_presence_resonator` на Мастере).

Как работает:
- Каждый тик ищет вражеских героев в **радиусе 2500** (`FindUnitsInRadius`, фильтр без иллюзий).
- Сравнивает с прошлым кадром (`caster.PresenceTable`) — пингует **только тех, кто только что вошёл**
  в радиус (флаг `IsPresenceDetected`), чтобы не спамить.
- Для новых: пинг на миникарте (`MinimapEvent`), сообщение `#Presence_Detected`, партикл `ping_world`,
  звук `Misc.BorrowedTime` (если не выключен опцией `bIsAlertSoundDisabled` / `OnConfig4Checked`).
- **Окно тишины:** первые **60 c** раунда (`GameRules:GetGameTime() < RoundStartTime + 60`) обычное
  обнаружение НЕ работает — только если у героя `hasSpecialPresenceDetection` ([:1031](scripts/vscripts/master_ability.lua:1031)).
- Фильтр целей — `CanBeDetected(enemy)` (учитывает `tCannotDetect` [util.lua:754] и concealment-абилки
  TA/EA: ambush/presence concealment, lishuwen concealment).

**⚠️ Уточнение про «доп-вижен» у трёх героев** (важно, частая путаница):
- Реально **изменяет presence detection только Карна** (`beastmaster`, флаг `DiscernPoorAttribute`,
  [karna_attributes.lua:18](scripts/vscripts/abilities/karna/karna_discern_poor.lua)): его detection работает в т.ч. в окне тишины. Сама `karna_discern_poor`
  — это таргет-дебафф по классу врага (knights/horseman/extra), [karna_discern_poor.lua](scripts/vscripts/abilities/karna/karna_discern_poor.lua).
- **Сасаки** (`false_assassin`/juggernaut) и **Жиль** (`gille`/shadow_shaman) получают доп-вижен
  через **СВОИ отдельные абилки**, НЕ через presence detection:
  - Жиль — **Eye for Art** ([gilles_eye_for_art.lua](scripts/vscripts/abilities/gilles/gilles_eye_for_art.lua)): аура вешает на врагов
    `modifier_eye_for_art_trigger`; когда такой враг **кастует способность**, ему даётся
    `modifier_eye_for_art_vision` (`MODIFIER_PROPERTY_PROVIDES_FOW_POSITION`) — Жиль видит его FOW на время.
  - Сасаки — вижен через `sasaki_gatekeeper` / `modifier_sasaki_vision` (true-sight) и Eye of Serenity.
  - (В `OnPresenceDetectionThink` остались ветки для них — true-sight/реплики — но это сопутствующее;
    основной их вижен реализован в собственных абилках выше.)

---

## 10. ⭐ Reality Marble (реалмы измерений) — детально

«Reality Marble» (Marble of Reality) — ульты, переносящие бой в отдельное **измерение**:
Emiya `emiya_unlimited_bladeworks` (UBW), Iskandar `iskander_ionioi` (Ionioi Hetairoi),
Nero/Archer `*_aestus_domus_aurea` (AotK).

**Реалмы = физические зоны карты** по координатам (`IsInSameRealm(loc1, loc2)` [util.lua:1761](scripts/vscripts/libraries/util.lua:1761)):
обычная карта (`y > -2000`) / AotK / UBW (`y <= -2000`, разделение по `x=3300`) / зона Мастеров (`y <= -6300`).
Юниты взаимодействуют только в пределах одного реалма.

Механика входа (на примере [iskander_ionioi.lua:272-525](scripts/vscripts/abilities/iskandar/iskander_ionioi.lua:272), [emiya_unlimited_bladeworks.lua:318+](scripts/vscripts/abilities/emiya/emiya_unlimited_bladeworks.lua:318)):
1. Враги в радиусе **физически телепортируются** в зону Marble (`SetAbsOrigin(marbleCenter ± diff)`), сохраняя
   взаимное расположение (`diffFromCenter`).
2. При входе/выходе **поимённо снимаются** конфликтующие модификаторы:
   `modifier_aestus_domus_aurea_enemy/ally/nero`, `modifier_hijikata_duel(_leash)`, `modifier_inside_marble`,
   `modifier_unlimited_bladeworks`, `modifier_annihilate_mute` и т.п.
3. **Приоритет при наложении:** если уже активен чужой Marble (`caster.IsAOTKDominant`/первый каст),
   новый не телепортирует — бой идёт в первом Marble; ломается первый → рушатся оба (см. тултип UBW Note0).
4. **Длительность/слом:** Marble держится до **истечения времени ИЛИ смерти кастера** (что раньше).
   По окончании юниты возвращаются, модификаторы Marble снимаются. (Уход за радиус Marble НЕ ломает.)
5. Спец-кейс: невидимость/прыжок (`cu_chulain` Gae Bolg, `lancer_5th`) — invulnerable юниты НЕ
   переносятся в Marble (см. тултипы `*_gae_bolg_Note0`).

> `revokes`-список содержит `modifier_ubw_chronosphere` — внутри Marble враги обычно в revoke (нельзя печати).
> `IsDimensionException()` к этому переносу **не подключён** (§7.3, мёртвый код).

---

## 11. ⭐ Shard of Holy Grail (осколки Грааля)

Система «утешения» отстающих. **Три источника** осколков, зависят от режима — НЕ путать:

1. **⭐ За проигранные раунды (основной, командные режимы)** — в `FinishRound`
   ([addon_game_mode.lua:4766,4784](scripts/vscripts/addon_game_mode.lua:4766)): когда счёт **проигравшей** команды по поражениям
   достигает **4 / 8 / 12** (т.е. счёт противника = 4/8/12), каждый игрок проигравшей команды получает
   `+1 ShardAmount` **и +2 уровня XP**, с оповещением «Your team had lost 4 rounds, you are rewarded with
   a shard of Holy Grail». → **Граали даются за проигрыш раундов, а не за смерти.**
2. **За 7 смертей — ТОЛЬКО в FFA** (`fate_ffa`): `OnEntityKilled` считает `killedUnit.DeathCount`; при
   `DeathCount == 7` → `+1 ShardAmount`, счётчик сбрасывается ([addon_game_mode.lua:3535-3547](scripts/vscripts/addon_game_mode.lua:3535)).
   В командных режимах эта ветка не выполняется.
3. **Периодический дроп на карте** — таймер `SHARD_DROP_PERIOD` ([addon_game_mode.lua:708-769](scripts/vscripts/addon_game_mode.lua:708)),
   UI-таймер «Next Holy Grail's Shard», по срабатыванию `CreateShardDrop(itemVector)` роняет `item_shard_drop`
   на карту (подбирается любым).

**Подбор дропа:** `OnItemPickedUp` ([:2833](scripts/vscripts/addon_game_mode.lua:2833)) — `item_shard_drop` удаляется и зовётся
`AddRandomShard(hero)` ([:2868](scripts/vscripts/addon_game_mode.lua:2868)): рандом `master_shard_of_anti_magic` /
`master_shard_of_replenishment`, каст через **Мастера** (`CastAbilityImmediately`), `ShardAmount++`, оповещение всем.

**Использование:** `hero.ShardAmount` показывается на Мастере 2; доступ к осколкам — `OnShardOpen`
([master_ability.lua:523](scripts/vscripts/master_ability.lua:523), способности `master_shard_of_holy_grail`/`master_shard_of_avarice`).
Сами предметы-осколки: `item_shard_of_replenishment` / `item_shard_of_anti_magic`
([items/shard_of_replenishment.lua](scripts/vscripts/items/shard_of_replenishment.lua), модификаторы `modifier_replenishment_armor/heal`).

---

## 12. ⭐ Эталонный герой: анатомия (Artoria / Saber)

Сквозной пример «как собран герой» (слот **legion_commander**).

**Файлы:**
- KV героя: [npc_fate_hero_arturia.kv](scripts/npc/heroes/npc_fate_hero_arturia.kv) — `override_hero legion_commander`,
  `Model models/artoria/artoria.vmdl`, `Ability1..12`, `Attribute1..5`, статы.
- KV способностей: [scripts/npc/abilities/saber/saber_abilities.kv](scripts/npc/abilities/saber/saber_abilities.kv) (+ `#base` на отдельные `.kv`).
- Lua способностей: [scripts/vscripts/abilities/arturia/](scripts/vscripts/abilities/arturia) (+ `modifiers/`).
- Комбо: `heroCombos["npc_dota_hero_legion_commander"] = "saber_max_excalibur"` ([util.lua:2578](scripts/vscripts/libraries/util.lua:2578)).

**Анатомия одной lua-абилки** — `arturia_invisible_air` (Q), [arturia_invisible_air.lua](scripts/vscripts/abilities/arturia/arturia_invisible_air.lua):
```lua
arturia_invisible_air = class({})                       -- класс способности (BaseClass ability_lua в KV)
modifier_invisible_air_bonus_damage = class({})         -- сопутствующий lua-модификатор
LinkLuaModifier("modifier_invisible_air_bonus_damage", "abilities/arturia/arturia_invisible_air", ...)

function arturia_invisible_air:OnSpellStart()
    -- 1) снаряд через НАТИВНЫЙ ProjectileManager (см. ниже)
    local nProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
    -- 2) рывок кастера через Physics (SetPhysicsVelocity + PHYSICS_NAV_BOUNCE)
    -- 3) pause_sealenabled на время рывка (служебная пауза)
    -- 4) предатак-бонус-урон через свой модификатор (+ Chivalry если IsChivalryAcquired)
end

function arturia_invisible_air:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)  -- урон через DoDamage
    -- стоп рывка + стан если Chivalry
end
```
Модификатор `modifier_invisible_air_bonus_damage` показывает паттерн **server↔client sync**: сервер кладёт
значение в `CustomNetTables:SetTableValue("sync", ...)`, клиент читает его в `GetModifierPreAttack_BonusDamage`.

**Важные общие приёмы, видимые в эталоне:**
- Урон — всегда через `DoDamage` (§5.3), не `ApplyDamage`.
- Рывки/нокапы — через `Physics:Unit` + `SetPhysicsVelocity` (или `ApplyAirborne*`).
- «Апгрейды от атрибутов» — флаги на герое (`hero.IsChivalryAcquired` и т.п.), выставляемые
  attribute-способностями; основная абилка читает флаг и усиливается.
- Снаряды бывают на разных API (см. ниже).

**⚠️ Три API снарядов в проекте** (важно не путать):
| API | Вызов | Когда |
|---|---|---|
| **Нативный Valve** | `ProjectileManager:CreateLinearProjectile/CreateTrackingProjectile` | большинство абилок (как в эталоне); колбэки `OnProjectileHit(_ExtraData)` |
| **FATE кастомный** | `FATE_ProjectileManager:CreateTrackingProjectile/CreateLinearProjectile/CreateSlowingArea_Circle` | спец-случаи (свой Think/уклонение/зоны) |
| **BMD Physics (legacy)** | `Projectiles:CreateProjectile` ([libraries/projectiles.lua](scripts/vscripts/libraries/projectiles.lua)) | наследие, новый код не использует |

> Это уточняет более ранний скилл: нативный `ProjectileManager` — глобал движка (require не нужен) и
> используется свободно; `FATE_ProjectileManager` — отдельный менеджер для особых снарядов.

---

## 13. Шпаргалка

| Механика | Точка входа |
|---|---|
| Командные печати | `OnSeal1..4Start` [master_ability.lua], диспетч `OnPlayerCastSeal` [addon_game_mode.lua:2014] |
| Сброс способностей печатью | `ResetAbilities/ResetItems` [master_ability.lua:68], флаг `IsResetable` (таблица `CannotReset`) |
| Комбинирование свитков | `CheckItemCombination(InStash)` [util.lua:1345], рецепты `itemComp`/`tItemComboTable` [util.lua:771] |
| Покупка предметов | `OnPlayerCustomQuickBuy` [addon_game_mode.lua:2052] |
| Покупка статов у Мастера | `OnStrengthGain`/`OnAgilityGain`/… [master_ability.lua:571+], кап 30 |
| Атрибуты→статы | `attributes.txt` + `Attributes:ModifyBonuses` [modifiers/attributes.lua:66] |
| Комбо | `hero.ComboName`, `LoopThroughAttr` [master_ability.lua:417], `IsCombo`/`CannotReset` |
| Урон / хил / добивание | `DoDamage` [util.lua:1816] / `unit:ApplyHeal` / `unit:Execute` [wrappers.lua] |
| Диспел | `ApplyPurge/StrongDispel/DeargDispel` [util.lua:2011+] |
| Cleanse / слоу | `HardCleanse`/`RemoveSlowEffect` [util.lua:1645], таблицы `cleansable`/`slowmodifier` |
| Revoke | `IsRevoked` + `revokes` [util.lua:1574,205] |
| Dimensional lock (анти-блинк) | `locks`+`CheckLocks` [blink_scroll.lua], `IsLocked` [util.lua:1581] |
| Реалмы / Reality Marble | `IsInSameRealm` [util.lua:1761], `iskander_ionioi`/`emiya_unlimited_bladeworks` |
| Скины | `modifier_hero_selection_skin` [hero_replacer.lua:212], данные `skins.skin_N.model` |
| Анлок комбо | `GetComboAvailability`/`heroCombos` [util.lua:2638,2577], `OnComboCheck` [master_ability.lua:1145] |
| Обнаружение присутствия | `OnPresenceDetectionThink` [master_ability.lua:1020], радиус 2500, тишина 60c; спец-detection только у Карны |
| Доп-вижен Жиль/Сасаки | Eye for Art (аура→каст→FOW) [gilles_eye_for_art.lua], Gatekeeper/`modifier_sasaki_vision` — отдельно от presence |
| Reality Marble | `iskander_ionioi`/`emiya_unlimited_bladeworks`; держится до конца времени ИЛИ смерти кастера; реалмы `IsInSameRealm` [util.lua:1761] |
| Shard of Holy Grail | за проигрыш 4/8/12 раундов (FinishRound [4766]); 7 смертей только в FFA [3535]; периодич. дроп [708] |
| Анатомия lua-абилки | `arturia_invisible_air.lua` (эталон); снаряды: нативный `ProjectileManager` vs `FATE_ProjectileManager` |
