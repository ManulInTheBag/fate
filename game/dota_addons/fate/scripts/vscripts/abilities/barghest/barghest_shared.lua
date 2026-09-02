--[[ Общее для всех способностей Barghest.
     ⚠️ Каждый ScriptFile грузится в СВОЮ среду: глобальная функция, объявленная
     в barghest_r.lua, в barghest_q.lua не существует. Общий код в аддоне
     подключают через require — так же сделано у atalanta/phoebus и vlad.
     ⚠️ Файл подключается и в КЛИЕНТСКОЙ VM (CastFilterResult* выполняется на
     клиенте), а там нет ни libraries/util, ни половины методов юнита —
     поэтому здесь ничего клиентонебезопасного на уровне файла.
]]

--[[ Модификатор «заряжено продолжение» живёт ЗДЕСЬ, а не в barghest_r: вешают
     его Q/W/E, а читает R. ]]
LinkLuaModifier("modifier_barghest_continuation", "abilities/barghest/barghest_shared",
    LUA_MODIFIER_MOTION_NONE)

modifier_barghest_continuation = class({})

function modifier_barghest_continuation:IsHidden()      return false end
function modifier_barghest_continuation:IsDebuff()      return false end
function modifier_barghest_continuation:IsPurgable()    return false end
function modifier_barghest_continuation:RemoveOnDeath() return true end

--[[ Иконка прямо говорит, ЧТО сейчас даст R: R1/R2/R3 после ударов связки,
     RW после стойки, RE после рывка. Тестовая, до своих артов. ]]
function modifier_barghest_continuation:GetTexture()
    local n = self:GetStackCount()
    if n < 1 then n = 1 end
    if n > 5 then n = 5 end
    return "custom/barghest/barghest_cont_" .. n
end

BARGHEST_CONT_Q1 = 1
BARGHEST_CONT_Q2 = 2
BARGHEST_CONT_Q3 = 3
BARGHEST_CONT_W  = 4
BARGHEST_CONT_E  = 5

--[[ Партиклы. Почти все уже свои (particles/barghest/*), пути собраны здесь —
     менять их надо только в этой таблице. Каждая стадия Q и каждая ветка R
     получают РАЗНЫЙ эффект: иначе по экрану не понять, что сработало.
     ⚠️ Всё, что тут перечислено, обязано стоять в precache соответствующей
     способности (см. barghest_abilities.kv) — иначе первый каст в матче
     подвешивает сервер на подгрузке. ]]
BARGHEST_FX = {
    ARC        = "particles/barghest/barghest_slash_1.vpcf",         -- размашистая дуга
    ARC_FIRE   = "particles/barghest/barghest_slash_4.vpcf",     -- она же, но огненная (R)
    CUT        = "particles/barghest/barghest_slash_vertical_up.vpcf", -- прямой рез
    CUT2        = "particles/barghest/barghest_slash_vertical.vpcf", -- прямой рез
    CUTThin     = "particles/barghest/barghest_slash_vertical_up_thin.vpcf",
    RING       = "particles/barghest/barghest_slash_2.vpcf",
    SHOCK      = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
    BURST      = "particles/barghest/barghest_small_explosion.vpcf",
    FIRE_HIT   = "particles/barghest/barghest_slam.vpcf",
    STANCE     = "particles/barghest/barghest_w_shield.vpcf",
    CHARGE     = "particles/barghest/barghest_e_charge.vpcf",
    -- стрелка прицела на зарядке E — та же, что у emiya_caladbolg
    AIM        = "particles/muramasa/vector.vpcf",
    DASH       = "particles/barghest/barghest_rush_e.vpcf",
    -- след волны ER по земле (Barghest_FxLine, CP0/CP1/CP2); самого летящего
    -- пса рисует barghest_black_dog_proj прямо в barghest_r
    WAVE       = "particles/barghest/barghest_black_dog.vpcf",
    -- уменьшенный пёс для послеобразов атрибута 1 (клон снаряда ER, 40% размера)
    HOUND      = "particles/barghest/barghest_hound_wake.vpcf",
    CHAINS     = "particles/barghest/barghest_e_chains.vpcf",
    LIFESTEAL  = "particles/barghest/barghest_lifesteal.vpcf",
    SHIELD_SLASH = "particles/barghest/barghest_slash_3.vpcf",
    -- Линии скорости заряженного рывка E (раньше путь был вписан прямо в barghest_e).
    DASH_SPEED = "particles/barghest/barghest_rush_e_speed.vpcf",
    -- ударная волна по земле на рубящем ударе комбо
    GROUND_SLAM  = "particles/barghest/barghest_ground_slam.vpcf",
    -- свечение гиганта, пока держится комбо
    GIANT_GLOW   = "particles/barghest/barghest_passive_glow.vpcf",
}

--[[ Звуки способностей. Свои, собраны из трёх папок SFX («The Middle
     Nursefather - Matthias», «Liu Assoc. South Section 3», «Dawn Office Rep»),
     события лежат в soundevents/hero_barghest.vsndevts рядом с голосом.
     Оригиналы там кинематографичные, по 1-4 с с длинным хвостом: удар сидит в
     первые 20-70 мс, остальное реверб. Поэтому клипы обрезаны по головному
     транзиенту — иначе три удара связки Q наложились бы друг на друга в кашу.
     Длина среза и исходник каждого клипа записаны в комментарии к его событию.
     ⚠️ На дотовском плейсхолдере остался только E_CHAIN: звука цепей не нашлось
     ни в одной из трёх папок. ]]
BARGHEST_SND = {
    -- связка Q: три разных удара, все короткие (0.70-0.75 с)
    Q_ARC     = "barghest_sfx_q1",
    Q_LUNGE   = "barghest_sfx_q2",
    Q_SPIN    = "barghest_sfx_q3",
    HIT       = "barghest_sfx_hit",     -- 0.45 с: звучит чаще всего, потому самый короткий
    W_CAST    = "barghest_sfx_w_cast",
    W_BREAK   = "barghest_sfx_w_break",
    SLAM      = "barghest_sfx_slam",
    E_CHARGE  = "barghest_sfx_e_charge",-- свелл на всю зарядку, глушится по отпусканию
    E_DASH    = "barghest_sfx_e_dash",
    E_GRAB    = "barghest_sfx_e_grab",
    E_CHAIN   = "Hero_Huskar.Burning_Spear",   -- ⚠️ плейсхолдер: цепей нет в исходниках
    -- продолжения R: самые тяжёлые и огненные звуки набора
    R_FIRE    = "barghest_sfx_r_fire",
    R_UPPER   = "barghest_sfx_r_upper",
    R_SLAM    = "barghest_sfx_r_slam",
    R_IMPACT  = "barghest_sfx_r_impact",
    R_WAVE    = "barghest_sfx_r_wave",
    --[[ Таран ветки WR — отдельный звук, а не общий с рывком E: у E короткий
         свист на месте, а тут герой едет рогами вперёд через полкарты. ]]
    R_HORN    = "barghest_sfx_r_horn",
    -- Укус пса из ветки RE. Раньше здесь играл чужой arash_attack_hit.
    R_HOUND   = "barghest_sfx_r_hound",
}

--[[ Голос Barghest на способностях (FGO, VA Inoue Marina, Слуга №310).
     События лежат в soundevents/hero_barghest.vsndevts, клипы — в
     sounds/barghest/. ⚠️ Голос вешаем только на РЕДКИЕ способности: Q и R
     жмут по несколько раз в связке, и реплика на них превращается в спам —
     на тех же граблях это уже проверено у Cu Alter.
     Реплики самого героя (спавн, смерть, приказы) живут не здесь, а в
     soundevents/voscripts/game_sounds_vo_dragon_knight.vsndevts: Barghest
     переопределяет Dragon Knight, и движок берёт VO по его событиям. ]]
BARGHEST_VO = {
    Q          = "barghest_vo_q",          -- короткий выкрик на удар связки
    R          = "barghest_vo_r",          -- выкрик потяжелее на продолжение
    W          = "barghest_vo_w",          -- стойка: «Клянусь этим мечом…»
    E          = "barghest_vo_e",          -- рывок: «Пёс… ест пса…!»
    D          = "barghest_vo_d",          -- под будущую D
    NP_START   = "barghest_vo_np_start",   -- под будущее комбо
    NP_SCREAM  = "barghest_vo_np_scream",
    NP_SHOUT   = "barghest_vo_np_shout",
    HACK       = "barghest_vo_hack",
    LAUGH      = "barghest_vo_laugh",
}

--[[ Самый длинный клип в пуле выкриков (см. hero_barghest.vsndevts). Ровно на
     столько выкрик и «занимает голос»: Q и R жмут ЧЕРЕДУЯ (ротация qrqrqr), и
     без этого второй выкрик ложился бы поверх первого — каша из двух голосов.
     ⚠️ Держать не меньше длины самого длинного клипа своего события. ]]
BARGHEST_GRUNT_LEN = {
    [1] = 0.7,      -- пул Q: короткие «Хм!»/«Ха!», самый длинный 0.65 c
    [2] = 1.05,     -- пул R: выкрики потяжелее, самый длинный 1.01 c
}

--[[ Боевой выкрик. Пока звучит предыдущий — новый молчит.
     ⚠️ Пропущенный выкрик НЕ откладываем и не копим: голос, приехавший через
     полсекунды после удара, читается как чужой.
     Пауза Q между ударами связки (0.8 c) длиннее её же клипа, так что каждый
     удар связки свой выкрик получает; глохнет только то, что влезло между. ]]
--[[ Реплика Слуги. У неё и у боевых выкриков ОДИН канал: реплика поверх
     выкрика (или поверх другой реплики) — это два голоса разом, ровно на что
     жаловались после комбо, где подряд шли фраза, крик роста и крик удара.
     Поэтому здесь: предыдущий звук глушим, канал занимаем на длину нового.
     ⚠️ Занятость держим НА ЮНИТЕ: require кэширует модуль один раз на карту,
     общая переменная затыкала бы вторую Barghest (у Мастера копия способностей). ]]
function Barghest_Voice(hCaster, sEvent, fLength)
    if not IsServer() then return end
    if not Barghest_Alive(hCaster) then return end
    if sEvent == nil then return end

    -- Играющую реплику обрываем: обрезанная фраза читается лучше, чем две разом.
    if hCaster.sBarghestVoiceEvent ~= nil then
        hCaster:StopSound(hCaster.sBarghestVoiceEvent)
    end
    hCaster.sBarghestVoiceEvent = sEvent
    hCaster.fBarghestGruntUntil = GameRules:GetGameTime() + (fLength or 2.0)
    hCaster:EmitSound(sEvent)
end

--[[ Боевой выкрик. Пока звучит предыдущий ГОЛОС (выкрик или реплика) — молчит. ]]
function Barghest_Grunt(hCaster, sEvent, nPool)
    if not IsServer() then return end
    if not Barghest_Alive(hCaster) then return end

    local fNow = GameRules:GetGameTime()
    -- Время держим НА ЮНИТЕ, а не в модуле: require кэширует модуль один раз на
    -- всю карту, и общая переменная затыкала бы выкрики второй Barghest —
    -- в аддоне это Мастер с копией способностей.
    if hCaster.fBarghestGruntUntil ~= nil and fNow < hCaster.fBarghestGruntUntil then
        return
    end
    hCaster.fBarghestGruntUntil = fNow + (BARGHEST_GRUNT_LEN[nPool] or 1.0)
    hCaster.sBarghestVoiceEvent = sEvent
    hCaster:EmitSound(sEvent)
end

--[[ Живой ли хэндл. Своя копия — по той же причине, что и у
     modifier_barrier_new: IsNotNull из util есть не во всех VM. ]]
function Barghest_Alive(hScript)
    local sType = type(hScript)
    if sType == "nil" then return false end
    if sType == "table" and type(hScript.IsNull) == "function" then
        return not hScript:IsNull()
    end
    return true
end

--[[ Множитель радиусов, пока держится комбо (Black Dog Galatine).

     Пока на Barghest висит modifier_barghest_combo_giant, она вдвое больше —
     и зоны попадания ВСЕХ её способностей растут вместе с моделью. Число
     лежит в KV самого комбо (`radius_mult`), чтобы его правили в одном месте.

     ⚠️ Считается и в КЛИЕНТСКОЙ VM (через GetAOERadius), поэтому каждый шаг
     под гардом: там у юнита может не оказаться ни HasModifier, ни
     FindAbilityByName. Не смогли прочитать — возвращаем 1, то есть обычный
     радиус: соврать в меньшую сторону безопаснее, чем упасть.
     ⚠️ Собственная дуга комбо через это НЕ гоняется — она и так посчитана
     под гиганта (см. шапку barghest_combo.lua). ]]
BARGHEST_GIANT_MOD = "modifier_barghest_combo_giant"

function Barghest_GiantMult(hCaster)
    if not Barghest_Alive(hCaster) then return 1 end
    if type(hCaster.HasModifier) ~= "function" then return 1 end
    if not hCaster:HasModifier(BARGHEST_GIANT_MOD) then return 1 end
    if type(hCaster.FindAbilityByName) ~= "function" then return 1 end
    local hCombo = hCaster:FindAbilityByName("barghest_combo")
    if not Barghest_Alive(hCombo) then return 1 end
    -- ⚠️ Индекс уровня ЯВНЫЙ: на способности нулевого уровня GetSpecialValueFor
    -- вернул бы 0, и множитель молча схлопнулся бы в 1 (см. barghest_combo:Value).
    local fMult = hCombo:GetLevelSpecialValueFor("radius_mult", 0)
    if fMult == nil or fMult <= 0 then return 1 end
    return fMult
end

--[[ Дальность рывков с поправкой на размер: у гиганта шаг длиннее, и выпад Q,
     рывок E и таран WR летят дальше. Множитель СВОЙ (`dash_mult`), не тот, что
     у радиусов: удвоенный рывок улетал бы через пол-карты. ]]
function Barghest_Dash(hCaster, nDistance)
    if Barghest_GiantMult(hCaster) <= 1 then return nDistance end
    if type(hCaster.FindAbilityByName) ~= "function" then return nDistance end
    local hCombo = hCaster:FindAbilityByName("barghest_combo")
    if not Barghest_Alive(hCombo) then return nDistance end
    local fMult = hCombo:GetLevelSpecialValueFor("dash_mult", 0)
    if fMult == nil or fMult <= 0 then return nDistance end
    return nDistance * fMult
end

--[[ Радиус способности с поправкой на размер. Через неё обязан проходить
     КАЖДЫЙ радиус попадания Q/W/E/R — иначе большая Barghest бьёт по зоне
     маленькой, и попадание не совпадает с картинкой эффекта. ]]
function Barghest_Radius(hCaster, nRadius)
    return nRadius * Barghest_GiantMult(hCaster)
end

--[[ Довернуть вектор к цели не больше чем на fMaxRad. Нужен дешам: мгновенный
     разворот на 180° выглядит как телепорт направления. ]]
function Barghest_TurnToward(vFrom, vTo, fMaxRad)
    local fA = math.atan2(vFrom.y, vFrom.x)
    local fB = math.atan2(vTo.y, vTo.x)
    local fD = fB - fA
    while fD >  math.pi do fD = fD - 2 * math.pi end
    while fD < -math.pi do fD = fD + 2 * math.pi end
    if fD >  fMaxRad then fD =  fMaxRad end
    if fD < -fMaxRad then fD = -fMaxRad end
    return Vector(math.cos(fA + fD), math.sin(fA + fD), 0)
end

--[[ Зарядить продолжение R. Вызывается из Q/W/E.
     ⚠️ Пока R не изучена, заряжать нечего — окно берётся из её значений. ]]
function Barghest_ArmContinuation(hCaster, nBranch)
    if not IsServer() then return end
    if not Barghest_Alive(hCaster) then return end

    local hR = hCaster:FindAbilityByName("barghest_r")
    if not Barghest_Alive(hR) or hR:GetLevel() < 1 then return end

    local hMod = hCaster:AddNewModifier(hCaster, hR, "modifier_barghest_continuation",
        {duration = hR:GetSpecialValueFor("window")})
    if Barghest_Alive(hMod) then
        hMod:SetStackCount(nBranch)
    end
end

--[[ Зарядить продолжение по итогу удара.

     Без третьего атрибута ветку открывает только ПОПАДАНИЕ: промахнулась —
     R не заряжен. С Galatine's Ember ветка открывается в любом случае, даже
     по воздуху: это и есть смысл атрибута — связка перестаёт рваться от
     одного промаха.
     ⚠️ Флаг лежит на ГЕРОЕ (его ставит barghest_attribute_3), а не на
     способности: атрибуты кастует Мастер, а не сама Баргест. ]]
function Barghest_ArmOnHit(hCaster, bHit, nBranch)
    if not IsServer() then return end
    if bHit or (Barghest_Alive(hCaster) and hCaster.BarghestAttr3Acquired) then
        Barghest_ArmContinuation(hCaster, nBranch)
    end
end

--[[ Враги в секторе перед точкой: аркой бьют и Q, и Q1R. ]]
--[[ Запас поиска на габариты цели: у самых толстых юнитов Доты
     GetPaddedCollisionRadius не превышает сотни с небольшим. ]]
local BARGHEST_ARC_PAD = 128

--[[ Цель считается задетой, если в сектор попал КРАЙ её хитбокса, а не центр.
     Проверка по центру означала, что попадать надо пиксель в пиксель под
     картинку эффекта, и в бою это неиграбельно: у стоящего вплотную юнита
     центр легко оказывается вне узкого сектора, хотя моделью он в нём весь.
     Отсюда две поправки — к дальности прибавляется радиус цели, а к половине
     угла допуск, который у ближней цели заметный, а у дальней почти нулевой. ]]
function Barghest_FindInArc(hCaster, hAbility, vOrigin, vDir, nRadius, nAngle)
    local tHit = {}
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vOrigin, nil,
        nRadius + BARGHEST_ARC_PAD,
        hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(),
        hAbility:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    local fHalf = math.rad(nAngle * 0.5)
    for _, hUnit in pairs(tUnits) do
        if Barghest_Alive(hUnit) then
            local vTo = hUnit:GetAbsOrigin() - vOrigin
            vTo.z = 0
            local fDist = vTo:Length2D()
            local fPad  = 0
            if type(hUnit.GetPaddedCollisionRadius) == "function" then
                fPad = hUnit:GetPaddedCollisionRadius()
            end
            if fDist - fPad <= nRadius then
                if fDist < 1 then
                    table.insert(tHit, hUnit)
                else
                    local fSlack = math.asin(math.min(1, fPad / math.max(fDist, 1)))
                    local fDot   = math.max(-1, math.min(1, vTo:Normalized():Dot(vDir)))
                    if math.acos(fDot) <= fHalf + fSlack then
                        table.insert(tHit, hUnit)
                    end
                end
            end
        end
    end
    return tHit
end

--[[ Убрать партикль через fDelay. Эффекты дуг живут своим временем и от
     ReleaseParticleIndex сразу не исчезают — так же убирают их kuro и
     arcueid. ⚠️ Без отложенного Destroy партиклы этих скиллов текут. ]]
local function ReleaseLater(nFx, fDelay)
    Timers:CreateTimer(fDelay, function()
        ParticleManager:DestroyParticle(nFx, false)
        ParticleManager:ReleaseParticleIndex(nFx)
    end)
end

--[[ ⚠️ РАЗМЕР КЛИНКОВЫХ ПАРТИКЛЕЙ ИЗ LUA НЕ МЕНЯЕТСЯ. Каждый barghest_slash_*
     содержит оператор `C_OP_SetControlPointPositions` с `m_nCP1 = 5` и
     `m_vecCP1Pos = [450, 0, 150]`: партикль КАЖДЫЙ КАДР сам пишет себе CP5, а
     кольцо берёт из него радиус (`C_INIT_RingWave.m_flInitialRadius = CP5.x *
     0.7`). Всё, что положат в CP5 снаружи, затирается на следующем кадре —
     поэтому `SetParticleControl(nFx, 5, ...)` здесь бесполезен (он и стоял в
     Barghest_FxArc с самого начала, ничего не масштабируя), как и CP10, из
     которого никто не читает угол.
     Единственный рабочий способ — заранее собранная копия с домноженными
     числами: BARGHEST_FX_GIANT + Barghest_FxName ниже. ]]

--[[ Плоские вспышки (`barghest_small_explosion`, `barghest_slam`,
     `barghest_ground_slam`) не читают control point ВООБЩЕ: размер зашит
     литералами в них самих и в их детях. Масштабировать их из Lua нечем, и
     единственный путь — заранее собранная копия на удвоенных числах.
     Копии лежат рядом с оригиналами и прекешатся из barghest_combo.kv. ]]
BARGHEST_FX_GIANT = {
    [BARGHEST_FX.ARC]          = "particles/barghest/barghest_slash_1_giant.vpcf",
    [BARGHEST_FX.ARC_FIRE]     = "particles/barghest/barghest_slash_4_giant.vpcf",
    [BARGHEST_FX.RING]         = "particles/barghest/barghest_slash_2_giant.vpcf",
    [BARGHEST_FX.SHIELD_SLASH] = "particles/barghest/barghest_slash_3_giant.vpcf",
    [BARGHEST_FX.CUT]          = "particles/barghest/barghest_slash_vertical_up_giant.vpcf",
    [BARGHEST_FX.CUT2]         = "particles/barghest/barghest_slash_vertical_giant.vpcf",
    [BARGHEST_FX.CUTThin]      = "particles/barghest/barghest_slash_vertical_up_thin_giant.vpcf",
    [BARGHEST_FX.BURST]        = "particles/barghest/barghest_small_explosion_giant.vpcf",
    [BARGHEST_FX.FIRE_HIT]     = "particles/barghest/barghest_slam_giant.vpcf",
    [BARGHEST_FX.GROUND_SLAM]  = "particles/barghest/barghest_ground_slam_giant.vpcf",
    -- Chain Hunt: зарядка, шлейф рывка, линии скорости и стрелка прицела
    [BARGHEST_FX.CHARGE]       = "particles/barghest/barghest_e_charge_giant.vpcf",
    [BARGHEST_FX.DASH]         = "particles/barghest/barghest_rush_e_giant.vpcf",
    [BARGHEST_FX.DASH_SPEED]   = "particles/barghest/barghest_rush_e_speed_giant.vpcf",
    -- ⚠️ Цепи НЕ увеличиваем: они висят на жертве, и раздутые читались как
    -- эффект самой жертвы. Оставлены как есть по просьбе юзера.
    [BARGHEST_FX.AIM]          = "particles/barghest/vector_giant.vpcf",
}

--[[ Имя партикля с поправкой на размер: пока она гигант — «большая» копия,
     если та заведена. Нет копии — вернём оригинал, эффект просто останется
     прежнего размера. ]]
function Barghest_FxName(sName, hCaster)
    if Barghest_GiantMult(hCaster) > 1 then
        return BARGHEST_FX_GIANT[sName] or sName
    end
    return sName
end

--[[ Размашистая дуга вокруг героя. Контрольные точки — как в arcueid_ready:
     CP5 задаёт размер, CP10.z — на сколько градусов метёт. ]]
function Barghest_FxArc(sName, hCaster, nRadius, nAngle)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(sName, hCaster), PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, hCaster:GetAbsOrigin())
    ParticleManager:SetParticleControl(nFx, 5, Vector(nRadius + 150, 0, 70))
    ParticleManager:SetParticleControl(nFx, 10, Vector(0, 0, nAngle))
    ReleaseLater(nFx, 1.0)
    return nFx
end



--[[ Прямой рез из точки в точку (выпад, удар снизу). CP2/CP3 — как у kuro. ]]
function Barghest_FxCut(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.CUT, hCaster), PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

function Barghest_FxCutThin(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.CUTThin, hCaster), PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

function Barghest_FxCutUp(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.CUT2, hCaster), PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

--[[ Кольцо по земле точно по радиусу зоны. ]]
function Barghest_FxRing(sName, vPos, nRadius, hCaster)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(sName, hCaster), PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ParticleManager:ReleaseParticleIndex(nFx)
    return nFx
end

--[[ Разовый эффект НА ЮНИТЕ. Некоторые партиклы (тот же шоквейв бистмастера)
     живут только привязанными к юниту и на PATTACH_WORLDORIGIN не рисуются —
     именно так и «ломался» взрыв стойки. ]]
function Barghest_FxOn(sName, hUnit, fLife)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(sName, hUnit), PATTACH_ABSORIGIN_FOLLOW, hUnit)
    ReleaseLater(nFx, fLife or 1.5)
    return nFx
end

--[[ Разовая вспышка в точке (попадание). ]]
-- hCaster не обязателен: без него вспышка всегда обычного размера.
function Barghest_FxAt(sName, vPos, hCaster)
    local nFx = ParticleManager:CreateParticle(Barghest_FxName(sName, hCaster), PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:ReleaseParticleIndex(nFx)
    return nFx
end

--[[ Волна по линии от юнита. Контрольные точки — как у aoko_facebreaker:
     CP0 конец, CP1 начало, CP2 ширина. ⚠️ Раньше тут стоял magnataur_shockwave
     с произвольными CP, и волну ER просто не было видно. ]]
function Barghest_FxLine(hCaster, vDir, nDistance, nWidth)
    local vOrigin = hCaster:GetAbsOrigin()
    local nFx = ParticleManager:CreateParticle(BARGHEST_FX.WAVE, PATTACH_ABSORIGIN, hCaster)
    ParticleManager:SetParticleControl(nFx, 1, vOrigin + vDir * nDistance)
    ParticleManager:SetParticleControl(nFx, 0, vOrigin)
    ParticleManager:SetParticleControl(nFx, 2, Vector(0, nWidth, 0))
    ParticleManager:ReleaseParticleIndex(nFx)
    return nFx
end

--[[ Пробежка чёрного пса (атрибут 1, послеобраз на ударе). Стартовую точку
     задаёт вызывающий: пёс бежит НА цель со случайной стороны, а не от героя
     вперёд — убегая от камеры он почти не читался.

     Это ТОТ ЖЕ партикль-снаряд, что у волны ER, только уменьшенная копия
     (barghest_hound_wake, 40% от размера): полноразмерный пёс на каждый удар
     связки закрывал бы собой пол-экрана.

     Контрольные точки — как у ER: CP0 старт, CP1 скорость (вектор), CP6 точка,
     где пёс должен исчезнуть.
     ⚠️ Партикль сам не умирает — снимаем руками чуть раньше прибытия, иначе он
     зависнет в конце пробега (ровно эта грабля была у волны ER). ]]
function Barghest_FxHound(vFrom, vDir, nDistance, nSpeed)
    if not IsServer() then return end
    local vOrigin = vFrom
    local nFx = ParticleManager:CreateParticle(BARGHEST_FX.HOUND, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vOrigin)
    ParticleManager:SetParticleControl(nFx, 1, vDir * nSpeed)
    ParticleManager:SetParticleControl(nFx, 6, vOrigin + vDir * nDistance)
    ParticleManager:SetParticleControl(nFx, 15, Vector(0, 0, 0))
    ParticleManager:SetParticleShouldCheckFoW(nFx, false)
    ParticleManager:SetParticleAlwaysSimulate(nFx)

    Timers:CreateTimer(math.max(0.05, nDistance / nSpeed - 0.05), function()
        ParticleManager:DestroyParticle(nFx, false)
        ParticleManager:ReleaseParticleIndex(nFx)
    end)
    return nFx
end

-- ⚠️ Никаких хуков в ExecuteOrderFilter у Barghest НЕТ и заводить их не надо.
-- Доворот рывка E сделан внутри самого модификатора движения: он следует за
-- forward-вектором рутованного героя (см. modifier_barghest_e_dash).
