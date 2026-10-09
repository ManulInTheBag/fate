--[[ Общее для всех способностей Billy the Kid.
     ⚠️ Каждый ScriptFile грузится в СВОЮ среду — общий код подключается через
     require (как у barghest_shared).
     ⚠️ Файл грузится и в КЛИЕНТСКОЙ VM (GetCooldown/тултипы считаются на клиенте),
     поэтому на уровне файла — только клиентобезопасное; DoDamage и прочее из
     libraries/util зовётся только внутри серверных функций.

     Устройство:
       * пули (D) — стаки modifier_billy_bullets (интринсик Bullets to Spare);
         максимум — ровно base_bullets (6), не растёт ни с уровнем, ни от атрибута;
       * «D включена» = ToggleState способности billy_bullets_to_spare;
         Billy_TrySpend списывает пули и говорит, получила ли способность усиление;
       * атрибуты — флаги hero.BillyAttrNAcquired на сервере; для клиента (КД Q
         в тултипе) их дублирует битовая маска в стаках modifier_billy_attributes,
         её поддерживает думалка пуль.
]]

-- EffectBars (значки ульты и хедшота над хелсбаром). Без require глобал есть, только
-- если его уже подтянул другой Слуга: в матче без них OnCreated/OnDestroy модификаторов
-- падали посреди AddNewModifier — значков не было, раньше это роняло игру.
require("libraries/effect_bars")

LinkLuaModifier("modifier_billy_attributes", "abilities/billy/billy_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_headshot",   "abilities/billy/billy_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_quick_turn", "abilities/billy/billy_shared", LUA_MODIFIER_MOTION_NONE)

BILLY_D_NAME = "billy_bullets_to_spare"

-- Партиклы. Линейная пуля — копия пули Хиджикаты (дерево particles/billy/billy_bullet*,
-- генератор build_billy_fx.py в content) — она же у автоатаки (Billy_AttackBulletFx),
-- искры — стоковые Муэрты. ⚠️ Самописные .vpcf в игре не рисовались — только копии рабочих.
BILLY_FX = {
    -- ⚠️ Пуля ЛИНЕЙНАЯ: летящая частица берёт скорость из CP1 (C_INIT_VelocityFromCP).
    -- Рисуется только через Billy_BulletFx (CP0/CP3 старт, CP1 скорость), не EffectName
    -- снаряда: у самонаводящегося CP1 = позиция цели, и пуля улетала вбок (06.10.2026).
    -- Создаём сразу billy_bullet_1, без корня billy_bullet: тот тоже писал CP3 детям и
    -- сбивал модель пули с пути («трейл быстрее пули»). Стартовые дети (вспышка, угли,
    -- дымок Dead Shot — «белые всплески») выключены генератором; выстрел — gunflash.
    bullet_linear   = "particles/billy/billy_bullet_1.vpcf",
    bullet_ricochet = "particles/billy/billy_bullet_1.vpcf",       -- рикошет Q — та же пуля
    -- трейл — отдельная система с теми же CP: на попадании гаснет вместе с пулей, но её
    -- ленты/искры без endcap-операторов доживают свой срок (лингер ~0.5 с)
    trail           = "particles/billy/billy_trail.vpcf",
    -- пуля и трейл комбо — те же, только массивные (пуля шириной 100, 07.10.2026)
    combo_bullet    = "particles/billy/billy_combo_bullet.vpcf",
    combo_trail     = "particles/billy/billy_combo_trail.vpcf",
    -- массивная пуля в окраске пуль под D — крупная пуля W, когда D включена (07.10.2026)
    combo_d         = { bullet = "particles/billy/billy_combo_bullet_d.vpcf", trail = "particles/billy/billy_combo_trail_d.vpcf" },
    -- выстрелы очереди комбо: яркая крупная головка + КОРОТКИЙ трейл (короче расстояния
    -- между пулями) — три отдельные пули, а не сплошной луч (юзер 07.10.2026)
    combo_shot       = "particles/billy/billy_combo_shot.vpcf",
    combo_shot_trail = "particles/billy/billy_combo_shot_trail.vpcf",
    -- пули под D (выстрел потратил пули): оранжевая головка и трейл ярче/шире (юзер
    -- 07.10.2026); на попадании вместо землистой пыли — оранжевый всплеск burst_d
    -- (CP0/CP3 точка, forward CP3 — к стрелку: вспышка Хиджикаты бьёт назад по пуле)
    d               = { bullet = "particles/billy/billy_bullet_d.vpcf", trail = "particles/billy/billy_trail_d.vpcf" },
    burst_d         = "particles/billy/billy_burst_d.vpcf",
    -- выстрел у дула: оранжевая вспышка Хиджикаты втрое меньше + серый дымок; CP3 — дуло,
    -- ориентация CP3 — направление выстрела
    gunflash        = "particles/billy/billy_gunflash.vpcf",
    ricochet_dust   = "particles/billy/billy_ricochet_dust.vpcf",   -- CP0; копия стоковой пыли dust_impact_mist
    impact          = "particles/billy/billy_hitsparks.vpcf",       -- CP0; искры Муэрты, перекрашены в оранжевый
    -- кровь по размеру (юзер): Q/W/E — s, R — m, комбо — l (стоковая PA persona, «много»).
    -- s/m — её уменьшенные копии (build_billy_blood.py). CP0 hitloc, CP1 цель + forward
    -- ОТ стрелка: брызги летят по −X осей CP1
    blood = {
        s = "particles/billy/billy_blood_s.vpcf",
        m = "particles/billy/billy_blood_m.vpcf",
        l = "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_crit_impact.vpcf",
    },
    -- копия sniper_crosshair вдвое крупнее, ярче и поверх всего (без z-буфера)
    mark            = "particles/billy/billy_crosshair.vpcf",
    -- копия riki_smokebomb, перекрашенная в пыльно-серый (build_billy_smoke.py)
    smoke           = "particles/billy/billy_smoke.vpcf",   -- CP0 центр, CP1 радиус
    -- копия индикатора ульты Распутина (rasputin_skill_mark_widea)
    cone            = "particles/billy/billy_highnoon_cone.vpcf",
    cone_color      = Vector(255, 40, 30),   -- CP4 клина; аддитивный, поверх земли (без z-буфера)
}
BILLY_TRACER_SPEED = 9000

-- Звуки выстрелов — штатные Муэрты (её слот: те же, что у автоатаки Билли);
-- файл soundevents/game_sounds_heroes/game_sounds_muerta.vsndevts прекешится в KV.
BILLY_SND = {
    shot     = "Hero_Muerta.Attack",              -- одиночный выстрел
    multi    = "Hero_Muerta.Attack.DoubleShot",   -- залп (W, E, R)
    impact   = "Hero_Muerta.ProjectileImpact",    -- попадание
    ricochet = "Hero_Muerta.DeadShot.Ricochet",   -- отскок пули Q
}
BILLY_CONE_COLOR = Vector(255, 190, 70)

---------------------------------------------------------------------------------------------------
-- Атрибуты

function Billy_HasAttr(hero, n)
    if not hero then return false end
    if IsServer() then
        return hero["BillyAttr" .. n .. "Acquired"] == true
    end
    -- ⚠️ в клиентской VM нет FindModifierByName (ловилось в игре: падал GetCooldown Q)
    if not hero.GetModifierStackCount then return false end
    local ok, mask = pcall(hero.GetModifierStackCount, hero, "modifier_billy_attributes", hero)
    if not ok or not mask then return false end
    return math.floor(mask / (2 ^ (n - 1))) % 2 == 1
end

function Billy_AttrMask(hero)
    local mask = 0
    for n = 1, 5 do
        if hero["BillyAttr" .. n .. "Acquired"] then mask = mask + 2 ^ (n - 1) end
    end
    return mask
end

modifier_billy_attributes = class({})
function modifier_billy_attributes:IsHidden()      return true end
function modifier_billy_attributes:IsPurgable()    return false end
function modifier_billy_attributes:RemoveOnDeath() return false end
function modifier_billy_attributes:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

---------------------------------------------------------------------------------------------------
-- Сброс анимации. Activity modifiers ("bullets", "walk"/"run") движок перечитывает
-- только когда ЗАНОВО выбирает последовательность базовой активности: включил D —
-- стойка менялась лишь на следующем витке цикла (~1 с) или когда герой вставал.
-- Перезапускаем базовую активность явно: ForcePlayActivityOnce(текущая IDLE/RUN)
-- выбирает последовательность сразу с новыми тегами.
-- ⚠️ Что НЕ сработало (ловилось в игре 06.10.2026): MODIFIER_PROPERTY_OVERRIDE_ANIMATION —
-- отдельный слой поверх базового: базовый под ним доигрывает старую анимацию и после
-- снятия подмены возвращается как был. Подмена на чужую базовую (бежит → IDLE) давала
-- «зависание» посреди бега, на копии-ретрансляторы (*_relay в billy.vmdl под
-- ACT_DOTA_CUSTOM_TOWER_IDLE*) — «короткую прокрутку», а затем старую стойку на секунду.
-- В касте/ченнеле/атаке не трогаем: принудительная активность перебила бы их анимацию.
-- caster_ability — способность, из которой зовём: в своём OnToggle/OnSpellStart она
-- сама числится GetCurrentActiveAbility, и без исключения сброс молча отменялся.
function Billy_RefreshAnim(unit, caster_ability)
    if not IsServer() or not IsNotNull(unit) or not unit:IsAlive() then return end
    local active = unit:GetCurrentActiveAbility()
    if unit:IsChanneling() or (active ~= nil and active ~= caster_ability) then return end
    if unit:IsAttacking() or unit:IsStunned() or unit:IsHexed() then return end
    if unit:HasModifier("modifier_billy_skedaddle_motion") or unit:HasModifier("modifier_billy_highnoon_firing")
        or unit:HasModifier("modifier_billy_combo_firing") or unit:HasModifier("modifier_billy_combo_stance") then return end
    unit:ForcePlayActivityOnce(unit:IsMoving() and ACT_DOTA_RUN or ACT_DOTA_IDLE)
end

---------------------------------------------------------------------------------------------------
-- Пули

function Billy_GetD(caster)
    return caster:FindAbilityByName(BILLY_D_NAME)
end

function Billy_IsDActive(caster)
    local d = Billy_GetD(caster)
    return d ~= nil and d:GetLevel() > 0 and d:GetToggleState()
end

function Billy_GetBullets(caster)
    local m = caster:FindModifierByName("modifier_billy_bullets")
    return m and m:GetStackCount() or 0
end

-- Всегда ровно base_bullets: ни уровень, ни Bullet Poncho запас больше не растят (юзер 08.10.2026).
function Billy_GetMaxBullets(caster)
    local d = Billy_GetD(caster)
    return d and d:GetSpecialValueFor("base_bullets") or 0
end

-- Прибавка к дальности Q и W от Skedaddle (E): пока висит modifier_billy_skedaddle_buff,
-- это дальность рывка E. Значение держат стаки баффа — так оно читается и на клиенте.
function Billy_RangeBonus(caster)
    if not caster or not caster.GetModifierStackCount then return 0 end
    return caster:GetModifierStackCount("modifier_billy_skedaddle_buff", caster) or 0
end

-- Включена ли D и хватает ли пуль: если да — списывает n и возвращает true
-- (способность срабатывает с усилением). Иначе ничего не тратит.
function Billy_TrySpend(caster, n)
    if not Billy_IsDActive(caster) then return false end
    local m = caster:FindModifierByName("modifier_billy_bullets")
    if not m or m:GetStackCount() < n then return false end
    m:SetStackCount(m:GetStackCount() - n)
    -- caster:EmitSound("billy_bullet_spend")
    return true
end

function Billy_Reload(caster)
    local m = caster:FindModifierByName("modifier_billy_bullets")
    if m then m:SetStackCount(Billy_GetMaxBullets(caster)) end
end

---------------------------------------------------------------------------------------------------
-- Хедшот (атрибут Here Is an Old Trick): попадания Q/W/E вешают стак на
-- цель; когда стаков набралось head_stacks, следующее попадание Q/W/E
-- критует и снимает их (атака — нет). Числа — в KV Trickshot (Q), куда атрибут и бьёт.

---------------------------------------------------------------------------------------------------
-- Быстрый разворот (юзер 09.10.2026): после выстрела Q или выстрела в пулю W Билли на
-- turn_duration секунд крутится на +turn_pct% быстрее — выстрелил и сразу развернулся
-- отступать. Числа — в KV способности, из которой выстрел. Процент едет в стаках: свойство
-- поворота спрашивают и на клиенте, а kv из AddNewModifier там нет.
function Billy_QuickTurn(caster, ability)
    if not IsServer() or not IsNotNull(caster) or not IsNotNull(ability) then return end
    local m = caster:AddNewModifier(caster, ability, "modifier_billy_quick_turn",
        { duration = ability:GetSpecialValueFor("turn_duration") })
    if m then m:SetStackCount(ability:GetSpecialValueFor("turn_pct")) end
end

modifier_billy_quick_turn = class({})

function modifier_billy_quick_turn:IsHidden()      return true end
function modifier_billy_quick_turn:IsPurgable()    return false end
function modifier_billy_quick_turn:RemoveOnDeath() return true end

function modifier_billy_quick_turn:DeclareFunctions()
    return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE }
end

function modifier_billy_quick_turn:GetModifierTurnRate_Percentage()
    return self:GetStackCount()
end

modifier_billy_headshot = class({})
function modifier_billy_headshot:IsHidden()      return false end
function modifier_billy_headshot:IsDebuff()      return true end
function modifier_billy_headshot:IsPurgable()    return false end
function modifier_billy_headshot:RemoveOnDeath() return true end
function modifier_billy_headshot:GetTexture()    return "custom/billy/billy_attribute_3" end

-- Значок над хелсбаром цели (effect_bars.js, id billy_headshot): «стаки/порог»,
-- на пороге пульсирует. Порог клиент сам не прочитает (KV чужого героя) — кладём.
function modifier_billy_headshot:OnCreated()
    if not IsServer() then return end
    EffectBars:Track(self)
    local q = self:GetAbility()
    if q then EffectBars:SetExtra(self:GetParent(), "billy_head_max", q:GetSpecialValueFor("head_stacks")) end
end

function modifier_billy_headshot:OnDestroy()
    if IsServer() then EffectBars:Untrack(self) end
end

function Billy_HeadshotReady(caster, target)
    if not Billy_HasAttr(caster, 3) then return false end
    local q = caster:FindAbilityByName("billy_trickshot")
    local m = target:FindModifierByName("modifier_billy_headshot")
    return q ~= nil and m ~= nil and m:GetStackCount() >= q:GetSpecialValueFor("head_stacks")
end

function Billy_HeadshotCritPct(caster)
    local q = caster:FindAbilityByName("billy_trickshot")
    return q and q:GetSpecialValueFor("head_crit") or 100
end

-- Хедшот копят и критуют только Q/W/E (юзер 08.10.2026): ульта и комбо его не трогают.
BILLY_HEADSHOT_ABILITIES = {
    billy_trickshot   = true,
    billy_triple_shot = true,
    billy_skedaddle   = true,
}

-- Приказы, которые не сбивают ни ченнел, ни стойку комбо: покупки, предметы в инвентаре,
-- глиф, пинги, прокачка, автокаст. Остальное (ход, атака, каст, стоп) — отмена.
BILLY_HARMLESS_ORDERS = {}
for _, name in ipairs({ "DOTA_UNIT_ORDER_TRAIN_ABILITY", "DOTA_UNIT_ORDER_PURCHASE_ITEM",
    "DOTA_UNIT_ORDER_SELL_ITEM", "DOTA_UNIT_ORDER_DISASSEMBLE_ITEM", "DOTA_UNIT_ORDER_MOVE_ITEM",
    "DOTA_UNIT_ORDER_GLYPH", "DOTA_UNIT_ORDER_RADAR", "DOTA_UNIT_ORDER_PING_ABILITY",
    "DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK", "DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO" }) do
    if _G[name] then BILLY_HARMLESS_ORDERS[_G[name]] = true end
end

-- Защита от случайной отмены (юзер 09.10.2026): первые cancel_grace секунд стойки комбо и
-- ченнела ульты приказы Билли съедаются — привычный правый клик сразу после каста их не
-- рвёт. Окно ставит Billy_StartCancelGrace, снимает конец стойки/ченнела.
function Billy_StartCancelGrace(unit, ability)
    unit.billyGraceUntil = GameRules:GetGameTime() + ability:GetSpecialValueFor("cancel_grace")
end

-- Из FateGameMode:ExecuteOrderFilter. false — приказ съеден.
function BillyGraceOrderFilter(unit, order)
    if not unit.billyGraceUntil or BILLY_HARMLESS_ORDERS[order] then return true end
    if GameRules:GetGameTime() >= unit.billyGraceUntil then
        unit.billyGraceUntil = nil
        return true
    end
    return false
end

-- Активная Protection from Arrows (Ку Хулин; её же вешают Скатах, Окита, Астольфо, рывок
-- Распутина): пули Q/W/E/R её не пробивают (юзер 09.10.2026) — пуля проходит сквозь
-- цель, как сквозь пустое место: ни урона, ни эффектов. ИСКЛЮЧЕНИЕ — комбо (billy_combo):
-- его пули защиту пробивают, там эта проверка намеренно не вызывается (юзер 09.10.2026). Проверка на попадании, как у
-- остальных стрелков (arash_*, atalanta_*): ProjectileDodge снимает только доджабельные
-- самонаводящиеся, а линейные, bDodgeable = false и думалку W не трогает.
function Billy_ArrowProof(unit)
    return IsNotNull(unit) and unit:HasModifier("modifier_protection_from_arrows_active")
end

-- Урон способностью с учётом хедшота. flags — флаги урона (комбо: сквозь неуязвимость).
function Billy_Damage(caster, target, damage, damageType, ability, flags)
    if not IsNotNull(target) or not target:IsAlive() then return end
    if Billy_HasAttr(caster, 3) and IsNotNull(ability) and BILLY_HEADSHOT_ABILITIES[ability:GetAbilityName()] then
        if Billy_HeadshotReady(caster, target) then
            damage = damage * Billy_HeadshotCritPct(caster) / 100
            target:RemoveModifierByName("modifier_billy_headshot")
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, damage, nil)
        else
            local q = caster:FindAbilityByName("billy_trickshot")
            local m = q and target:AddNewModifier(caster, q, "modifier_billy_headshot",
                { duration = q:GetSpecialValueFor("head_duration") })
            if IsNotNull(m) then m:IncrementStackCount() end
        end
    end
    DoDamage(caster, target, damage, damageType, flags or 0, ability, false)
end

---------------------------------------------------------------------------------------------------
-- Выстрел веером: count пуль от центрального направления dir с шагом stepDeg,
-- каждая — линейный снаряд, гаснущий на первой цели (OnProjectileHit_ExtraData вернёт
-- true и погасит пулю Billy_BulletEnd(data.bfx)).

function Billy_RotateDir(dir, deg)
    local a = math.rad(deg)
    local c, s = math.cos(a), math.sin(a)
    return Vector(dir.x * c - dir.y * s, dir.x * s + dir.y * c, 0):Normalized()
end

-- Точка дула: аттач attach_attack1 модели (кость gun_1), иначе — на уровне груди.
function Billy_GunOrigin(caster)
    local att = caster:ScriptLookupAttachment("attach_attack1")
    if att and att > 0 then return caster:GetAttachmentOrigin(att) end
    return caster:GetAbsOrigin() + Vector(0, 0, 90)
end

function Billy_HitPos(unit)
    local att = unit:ScriptLookupAttachment("attach_hitloc")
    if att and att > 0 then return unit:GetAttachmentOrigin(att) end
    return unit:GetAbsOrigin() + Vector(0, 0, 80)
end

-- Оранжевый всплеск попадания пули под D; back — горизонтальное направление на стрелка.
function Billy_FxBurstD(pos, back)
    local fx = ParticleManager:CreateParticle(BILLY_FX.burst_d, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleControl(fx, 0, pos)
    ParticleManager:SetParticleControl(fx, 3, pos)
    ParticleManager:SetParticleControlForward(fx, 3, back)
    ParticleManager:ReleaseParticleIndex(fx)
end

-- Попадание по юниту: искры; с blood ("s"/"m"/"l", см. BILLY_FX.blood) — ещё пыль удара
-- (та же, что на отскоке Q от земли) и кровь, брызгающая прочь от from (точка стрелка).
-- d — пуля под D: вместо пыли оранжевый всплеск (и без blood — у доп. выстрелов атаки).
function Billy_FxImpact(unit, blood, from, d)
    if not IsNotNull(unit) then return end
    local hit = Billy_HitPos(unit)
    local fx = ParticleManager:CreateParticle(BILLY_FX.impact, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleControl(fx, 0, hit)
    ParticleManager:ReleaseParticleIndex(fx)
    unit:EmitSound(BILLY_SND.impact)

    -- брызги крови летят по −forward CP1, поэтому forward смотрит НА стрелка (с forward
    -- «от Билли к цели» кровь летела в Билли — жалоба 06.10.2026)
    local origin = unit:GetAbsOrigin()
    local back = (from or origin) - origin
    back.z = 0
    back = back:Length2D() > 1 and back:Normalized() or -unit:GetForwardVector()

    if d then Billy_FxBurstD(hit, back) end
    if not blood then return end

    if not d then
        local dust = ParticleManager:CreateParticle(BILLY_FX.ricochet_dust, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleShouldCheckFoW(dust, false)
        ParticleManager:SetParticleControl(dust, 0, hit)
        ParticleManager:ReleaseParticleIndex(dust)
    end

    local b = ParticleManager:CreateParticle(BILLY_FX.blood[blood], PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleShouldCheckFoW(b, false)
    ParticleManager:SetParticleControlEnt(b, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", origin, true)
    ParticleManager:SetParticleControl(b, 1, origin)
    ParticleManager:SetParticleControlForward(b, 1, back)
    ParticleManager:ReleaseParticleIndex(b)
end

---------------------------------------------------------------------------------------------------
-- Пуля как своя частица. Снаряды летят БЕЗ эффекта (EffectName ""), а пулю рисуем сами:
-- частицу снаряда движок прячет в тумане — пуля «пропадала раньше времени», влетев туда,
-- где у команды нет обзора (жалоба 06.10.2026). Своя частица — без проверки тумана (как
-- копьё Леонида), видна всем, как bVisibleToEnemies у ванильных снарядов.
-- billy_bullet_1: CP0 и CP3 — старт (частица рождается в CP3, дальше сама пишет туда своё
-- положение для детей), CP1 — вектор скорости.
-- Гасится Billy_BulletEnd по жетону, а не по индексу: индексы частиц переиспользуются,
-- и страховочный таймер мог бы погасить чужую частицу.
-- Сами снаряды дают обзор радиусом BILLY_BULLET_VISION, пока летят (юзер 06.10.2026).
BILLY_BULLET_FX  = BILLY_BULLET_FX or {}
BILLY_BULLET_SEQ = BILLY_BULLET_SEQ or 0
BILLY_BULLET_VISION = 200

-- Одна летящая частица (пуля или голова трейла): CP0/CP3 старт, CP1 скорость, без тумана.
-- CP5.x — время полёта: корень сам останавливается через столько секунд ОТ РОЖДЕНИЯ НА КЛИЕНТЕ
-- (C_OP_StopAfterCPDuration, build_billy_fx.py). Раньше конец полёта задавал только
-- DestroyParticle с сервера — он доходит с шагом тика и джиттером, и дробь W (400 на 3000/с)
-- рисовалась каждый раз разной длины (±100). ⚠️ Без CP5 пуля гаснет сразу.
local function Billy_FlyingFx(effect, from, velocity, life)
    local fx = ParticleManager:CreateParticle(effect, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleAlwaysSimulate(fx)
    ParticleManager:SetParticleControl(fx, 0, from)
    ParticleManager:SetParticleControl(fx, 3, from)
    ParticleManager:SetParticleControl(fx, 1, velocity)
    ParticleManager:SetParticleControl(fx, 5, Vector(life, 0, 0))
    return fx
end

-- Пуля effect + её трейл от from со скоростью velocity (вектор); сами гаснут через life
-- секунд. Трейл — отдельная система (trail, по умолчанию BILLY_FX.trail), летит вровень с пулей.
function Billy_BulletFx(effect, from, velocity, life, trail)
    BILLY_BULLET_SEQ = BILLY_BULLET_SEQ + 1
    local token = BILLY_BULLET_SEQ
    BILLY_BULLET_FX[token] = {
        fxs  = { Billy_FlyingFx(effect, from, velocity, life), Billy_FlyingFx(trail or BILLY_FX.trail, from, velocity, life) },
        from = from,
        vel  = velocity,
        t0   = GameRules:GetGameTime(),
        life = life,
    }
    -- страховка: к этому времени частицу уже остановил CP5 на клиенте
    Timers:CreateTimer(life + BILLY_BULLET_GRACE, function() Billy_BulletStop(token) end)
    return token
end

-- Погасить сразу, где бы ни была (разрыв пули W): трейл перестаёт расти и тает.
function Billy_BulletStop(token)
    local b = token and BILLY_BULLET_FX[token]
    if not b then return end
    BILLY_BULLET_FX[token] = nil
    for _, fx in ipairs(b.fxs) do
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end
end

-- Погасить пулю и трейл (жетон из ExtraData.bfx): пуля исчезает, а трейл только перестаёт
-- расти — его частицы без endcap-операторов доживают свой срок и тают.
-- С target — не сразу, а когда частица долетит до проекции центра цели на линию полёта:
-- снаряд засчитывает попадание, едва цель вошла в его радиус, да ещё с шагом серверного
-- тика — при 7000/с пуля и трейл гасли за 100–300 до цели («не дорисовываются», 06.10.2026).
-- Без target у конца пути (линейный снаряд добил дальность) — НЕ гасим: частицу ровно в конце
-- пути останавливает CP5 на клиенте. Снаряд движка добивает дальность примерно на тик РАНЬШЕ
-- частицы, и сразу погашенная дробь W рисовалась на ~300 из 400, а задевшая цель (её гашение
-- отложено) — на все 400: «трейлы разной длины» (скриншот 07.10.2026). Гасит страховочный
-- таймер Billy_BulletFx. Без target задолго до конца (цель самонаводящегося исчезла) — сразу.
BILLY_BULLET_GRACE = 0.15

function Billy_BulletEnd(token, target)
    local b = token and BILLY_BULLET_FX[token]
    if not b then return end
    local elapsed = GameRules:GetGameTime() - b.t0
    if IsNotNull(target) then
        local speed = b.vel:Length()
        if speed > 0 then
            local along = (Billy_HitPos(target) - b.from):Dot(b.vel * (1 / speed))
            local left = along / speed - elapsed
            if left > 0.01 then
                Timers:CreateTimer(math.min(left, 0.3), function() Billy_BulletStop(token) end)
                return
            end
        end
    elseif b.life - elapsed < BILLY_BULLET_GRACE then
        return
    end
    Billy_BulletStop(token)
end

-- Линейный выстрел: t — таблица CreateLinearProjectile (без EffectName, vVelocity без z).
-- Жетон частицы едет в ExtraData.bfx — обработчик попадания, на котором снаряд гаснет,
-- зовёт Billy_BulletEnd(data.bfx). fx = { bullet, trail } — свои частицы (комбо), иначе обычные.
-- t.vFxEnd — куда ЛЕТИТ ЧАСТИЦА (Q: в землю под курсором, юзер 07.10.2026): снаряд по-прежнему
-- горизонтальный и бьёт по линии, а пуля идёт наклонно — её горизонтальная скорость равна
-- скорости снаряда, так что в точку она приходит ровно к концу его полёта.
-- Частица летит не меньше BILLY_BULLET_MIN_FX секунд: Q в упор на 7000/с — это сотые доли
-- секунды, лента не успевала родиться («под себя трейла вообще нет», 07.10.2026). Тогда пуля
-- чуть медленнее снаряда и приходит в точку позже него — на глаз не заметно.
BILLY_BULLET_MIN_FX = 0.08

function Billy_LinearShot(t, fx)
    local speed = t.vVelocity:Length2D()
    local life = speed > 0 and t.fDistance / speed or 0
    local fxEnd = t.vFxEnd or (t.vSpawnOrigin + t.vVelocity * life)
    local fxLife = math.max(life, BILLY_BULLET_MIN_FX)
    local vel = (fxEnd - t.vSpawnOrigin) * (1 / fxLife)
    t.vFxEnd = nil
    t.ExtraData = t.ExtraData or {}
    t.ExtraData.bfx = Billy_BulletFx(fx and fx.bullet or BILLY_FX.bullet_linear, t.vSpawnOrigin, vel,
        fxLife, fx and fx.trail)
    t.EffectName        = ""
    t.bProvidesVision   = true
    t.iVisionRadius     = BILLY_BULLET_VISION
    t.iVisionTeamNumber = t.Source:GetTeamNumber()
    return ProjectileManager:CreateLinearProjectile(t)
end

-- Выстрел у дула: оранжевая вспышка + серый дымок, повёрнутые по направлению dir.
function Billy_FxMuzzle(caster, dir)
    if not IsNotNull(caster) then return end
    local gun = Billy_GunOrigin(caster)
    local fx = ParticleManager:CreateParticle(BILLY_FX.gunflash, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)   -- выстрел виден и из тумана
    ParticleManager:SetParticleControl(fx, 0, gun)
    ParticleManager:SetParticleControl(fx, 3, gun)
    local flat = Vector(dir.x, dir.y, 0)
    if flat:Length2D() < 0.01 then flat = caster:GetForwardVector() end
    ParticleManager:SetParticleControlForward(fx, 3, flat:Normalized())
    ParticleManager:ReleaseParticleIndex(fx)
end

-- Землистый дымок на земле (отскок пули Q); пуля под D (d) — оранжевый всплеск, back —
-- направление на стрелка.
function Billy_FxDust(pos, d, back)
    if d then
        Billy_FxBurstD(GetGroundPosition(pos, nil) + Vector(0, 0, 20), back or Vector(1, 0, 0))
        return
    end
    local fx = ParticleManager:CreateParticle(BILLY_FX.ricochet_dust, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleControl(fx, 0, GetGroundPosition(pos, nil))
    ParticleManager:ReleaseParticleIndex(fx)
end

-- Пуля автоатаки и доп. выстрелов D: снаряд движка самонаводящийся и НЕВИДИМЫЙ
-- (ProjectileModel "" в KV героя, EffectName "" у доп. выстрелов), а рисуем ту же пулю
-- Билли, что у скиллов, — прямой от дула в грудь цели со скоростью снаряда (как рикошет
-- Q). Раньше летела стоковая пуля Муэрты. Возвращает жетон для Billy_BulletEnd.
-- d — выстрел под D (пуля и трейл BILLY_FX.d).
function Billy_AttackBulletFx(caster, target, speed, d)
    if not IsNotNull(caster) or not IsNotNull(target) or not speed or speed <= 0 then return nil end
    local from = Billy_GunOrigin(caster)
    local delta = Billy_HitPos(target) - from
    local len = delta:Length()
    if len <= 1 then return nil end
    return Billy_BulletFx(d and BILLY_FX.d.bullet or BILLY_FX.bullet_linear, from, delta * (speed / len),
        len / speed, d and BILLY_FX.d.trail or nil)
end

-- Выстрел, который по механике не летит (залп R): та же пуля, что у скиллов, — только
-- частица, от дула в грудь цели; искры на цели — сразу. d — залп под D.
function Billy_FxTracer(caster, unit, ability, d)
    if not IsNotNull(caster) or not IsNotNull(unit) then return end
    local from = Billy_GunOrigin(caster)
    local delta = Billy_HitPos(unit) - from
    local dist = delta:Length()
    if dist > 1 then
        Billy_FxMuzzle(caster, delta)
        Billy_BulletFx(d and BILLY_FX.d.bullet or BILLY_FX.bullet_linear, from,
            delta:Normalized() * BILLY_TRACER_SPEED, dist / BILLY_TRACER_SPEED, d and BILLY_FX.d.trail or nil)
    end
    Billy_FxImpact(unit, "m", caster:GetAbsOrigin(), d)     -- залп R — кровь средняя
end

function Billy_FireFan(ability, origin, dir, count, stepDeg, range, width, speed, extra, fx)
    local caster = ability:GetCaster()
    local gun = Billy_GunOrigin(caster)
    local half = (count - 1) / 2
    Billy_FxMuzzle(caster, dir)
    for i = 0, count - 1 do
        local d = Billy_RotateDir(dir, (i - half) * stepDeg)
        local data = {}
        for k, v in pairs(extra or {}) do data[k] = v end
        Billy_LinearShot({
            Ability           = ability,
            vSpawnOrigin      = Vector(origin.x, origin.y, gun.z),
            fDistance         = range,
            fStartRadius      = width,
            fEndRadius        = width,
            Source            = caster,
            bHasFrontalCone   = false,
            iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            vVelocity         = d * speed,
            ExtraData         = data,
        }, fx)
    end
end

-- Young Outlaw Leader (атрибут 1): награда за голову — после всех Billy_* выше, он их зовёт.
require("abilities/billy/billy_wanted")
