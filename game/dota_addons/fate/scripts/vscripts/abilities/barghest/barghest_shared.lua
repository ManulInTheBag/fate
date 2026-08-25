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
    CHAINS     = "particles/barghest/barghest_e_chains.vpcf",
    LIFESTEAL  = "particles/barghest/barghest_lifesteal.vpcf",
    SHIELD_SLASH = "particles/barghest/barghest_slash_3.vpcf",
}

--[[ Звуки. Простые, из уже используемых в аддоне дотовских событий: свои
     соберём отдельно, а пока важно слышать, что скилл сработал. ]]
BARGHEST_SND = {
    Q_ARC     = "Hero_Juggernaut.BladeDance",
    Q_LUNGE   = "Hero_Magnataur.Skewer.Cast",
    Q_SPIN    = "Hero_Axe.CounterHelix",
    HIT       = "Hero_Juggernaut.OmniSlash.Damage",
    W_CAST    = "Hero_Abaddon.AphoticShield.Cast",
    W_BREAK   = "Hero_Abaddon.AphoticShield.Destroy",
    SLAM      = "Hero_Centaur.HoofStomp",
    E_CHARGE  = "Hero_Invoker.EMP.Charge",
    E_DASH    = "Hero_Centaur.Stampede.Cast",
    E_GRAB    = "Hero_EarthSpirit.BoulderSmash.Target",
    E_CHAIN   = "Hero_Huskar.Burning_Spear",
    R_FIRE    = "Hero_DragonKnight.BreathFire",
    R_UPPER   = "Hero_Mars.Spear.Cast",
    R_SLAM    = "Hero_EarthShaker.Totem",
    R_IMPACT  = "Hero_Spirit_Breaker.GreaterBash",
    R_WAVE    = "Hero_LegionCommander.Overwhelming.Location",
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

--[[ Враги в секторе перед точкой: аркой бьют и Q, и Q1R. ]]
function Barghest_FindInArc(hCaster, hAbility, vOrigin, vDir, nRadius, nAngle)
    local tHit = {}
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vOrigin, nil, nRadius,
        hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(),
        hAbility:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    local nCos = math.cos(math.rad(nAngle * 0.5))
    for _, hUnit in pairs(tUnits) do
        if Barghest_Alive(hUnit) then
            local vTo = hUnit:GetAbsOrigin() - vOrigin
            vTo.z = 0
            if vTo:Length2D() < 1 or vTo:Normalized():Dot(vDir) >= nCos then
                table.insert(tHit, hUnit)
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

--[[ Размашистая дуга вокруг героя. Контрольные точки — как в arcueid_ready:
     CP5 задаёт размер, CP10.z — на сколько градусов метёт. ]]
function Barghest_FxArc(sName, hCaster, nRadius, nAngle)
    local nFx = ParticleManager:CreateParticle(sName, PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, hCaster:GetAbsOrigin())
    ParticleManager:SetParticleControl(nFx, 5, Vector(nRadius + 150, 0, 70))
    ParticleManager:SetParticleControl(nFx, 10, Vector(0, 0, nAngle))
    ReleaseLater(nFx, 1.0)
    return nFx
end



--[[ Прямой рез из точки в точку (выпад, удар снизу). CP2/CP3 — как у kuro. ]]
function Barghest_FxCut(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(BARGHEST_FX.CUT, PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

function Barghest_FxCutThin(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(BARGHEST_FX.CUTThin, PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

function Barghest_FxCutUp(hCaster, nRadius, vPos)
    local nFx = ParticleManager:CreateParticle(BARGHEST_FX.CUT2, PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ReleaseLater(nFx, 1.0)
    return nFx
end

--[[ Кольцо по земле точно по радиусу зоны. ]]
function Barghest_FxRing(sName, vPos, nRadius)
    local nFx = ParticleManager:CreateParticle(sName, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vPos)
    ParticleManager:SetParticleControl(nFx, 1, Vector(nRadius, nRadius, nRadius))
    ParticleManager:ReleaseParticleIndex(nFx)
    return nFx
end

--[[ Разовый эффект НА ЮНИТЕ. Некоторые партиклы (тот же шоквейв бистмастера)
     живут только привязанными к юниту и на PATTACH_WORLDORIGIN не рисуются —
     именно так и «ломался» взрыв стойки. ]]
function Barghest_FxOn(sName, hUnit, fLife)
    local nFx = ParticleManager:CreateParticle(sName, PATTACH_ABSORIGIN_FOLLOW, hUnit)
    ReleaseLater(nFx, fLife or 1.5)
    return nFx
end

--[[ Разовая вспышка в точке (попадание). ]]
function Barghest_FxAt(sName, vPos)
    local nFx = ParticleManager:CreateParticle(sName, PATTACH_WORLDORIGIN, nil)
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

-- ⚠️ Никаких хуков в ExecuteOrderFilter у Barghest НЕТ и заводить их не надо.
-- Доворот рывка E сделан внутри самого модификатора движения: он следует за
-- forward-вектором рутованного героя (см. modifier_barghest_e_dash).
