require("abilities/barghest/barghest_shared")

--[[ Конус обзора Barghest: пока висит модификатор, она видит только сектор
     `BARGHEST_CONE.angle` градусов перед собой (плюс пятачок `near` вокруг
     себя, чтобы не слепла вплотную). Сектор крутится вместе с её facing.

     Пока что вешается на касте комбо (barghest_combo:OnSpellStart) на всё
     время гиганта; куда переедет — решим позже, поэтому модификатор ничего
     не знает о способности-хозяине и все числа держит здесь.

     Как устроено. Родного конуса обзора у юнита нет: обзор в Доте круглый.
     Поэтому:
       1. свой обзор ужимаем до `near` через MODIFIER_PROPERTY_FIXED_*_VISION;
       2. раз в `interval` секунд засеваем сектор FOW-вьюверами (AddFOWViewer)
          по квадратной сетке с шагом `step` в ЕЁ системе координат
          (forward/right) — так край сектора получается ровным, а не
          зубчатым. Радиус вьювера 0.75·step: на квадратной сетке круги
          закрывают её без дыр при r ≥ step/√2. Вьювер живёт чуть дольше
          интервала, чтобы обзор не мигал (приём из modifier_fate_flying_vision).
       3. Вьюверы «с препятствиями» (последний аргумент true): деревья и
          обрывы режут обзор как у обычного юнита. Но каждый вьювер смотрит
          со СВОЕЙ точки, и поставленный на возвышенность он показал бы ей
          верх обрыва, которого снизу не видно, — поэтому точки, лежащие
          выше её самой на `cliff_step` и больше, пропускаем.

     ⚠️ В API есть MODIFIER_PROPERTY_VISION_DEGREES_RESTRICTION
     (GetVisionDegreeRestriction) — родной конус. Из Lua он, по отчётам
     моддеров (Dota2-Gameplay#29281, ноябрь 2025), не работает. Флаг
     BARGHEST_CONE.native = true переключает модификатор на него — чтобы
     проверить в игре одной правкой; если заработает, всю сетку можно снести.

     Радиус сектора берём с базового обзора юнита (GetBaseDayTimeVisionRange —
     «до модификаторов»), так что прибавка гиганта (SetDayTimeVisionRange)
     в него входит, а наше собственное ужатие — нет.

     ⚠️ Обзор от союзников она ПРОДОЛЖАЕТ видеть. Туман в Доте командный, а не
     поигроковый: отрезать Barghest от обзора тиммейтов, не отрезав их самих
     (MODIFIER_STATE_PROVIDES_VISION = false на всей команде гасит и их
     экраны), движок не умеет. Единственная зацепка — MODIFIER_PROPERTY_FOW_TEAM
     (GetModifierFoWTeam): юнит смотрит туман ДРУГОЙ команды. По тому же
     отчёту Valve из Lua он не работает, но проверить дёшево: флаг `fow_team`
     переводит её на туман DOTA_TEAM_CUSTOM_1 и туда же шлёт вьюверы сектора.
     Если сработает — она видит только свой сектор, союзники ничего не теряют.
     ⚠️ Семантика свойства не документирована: возможно, оно наоборот делает
     её видимой только для той команды. Включать ТОЛЬКО для проверки в игре. ]]

BARGHEST_CONE = {
    angle      = 90,     -- полный угол сектора, градусов
    near       = 200,    -- сколько она видит вокруг себя вне сектора
    step       = 200,    -- шаг сетки вьюверов; радиус вьювера = 0.75·step
    interval   = 0.2,    -- как часто пересеиваем сектор
    cliff_step = 100,    -- точки выше неё на столько и больше не смотрят
    fallback   = 1000,   -- обзор, если геттеров базы в API не оказалось; = VisionDaytimeRange в hero.kv
    native     = false,  -- true = пробуем родной VISION_DEGREES_RESTRICTION вместо сетки
    fow_team   = false,  -- ЭКСПЕРИМЕНТ: смотреть туман DOTA_TEAM_CUSTOM_1 (см. шапку)
}

LinkLuaModifier("modifier_barghest_vision_cone", "abilities/barghest/barghest_vision_cone",
    LUA_MODIFIER_MOTION_NONE)

modifier_barghest_vision_cone = class({})

function modifier_barghest_vision_cone:IsHidden()      return true end
function modifier_barghest_vision_cone:IsDebuff()      return false end
function modifier_barghest_vision_cone:IsPurgable()    return false end
function modifier_barghest_vision_cone:RemoveOnDeath() return true end

function modifier_barghest_vision_cone:DeclareFunctions()
    local tFuncs
    if BARGHEST_CONE.native then
        tFuncs = { MODIFIER_PROPERTY_VISION_DEGREES_RESTRICTION }
    else
        tFuncs = {
            MODIFIER_PROPERTY_FIXED_DAY_VISION,
            MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
        }
    end
    if BARGHEST_CONE.fow_team then
        table.insert(tFuncs, MODIFIER_PROPERTY_FOW_TEAM)
    end
    return tFuncs
end

function modifier_barghest_vision_cone:GetVisionDegreeRestriction()
    return BARGHEST_CONE.angle
end

function modifier_barghest_vision_cone:GetModifierFoWTeam()
    return DOTA_TEAM_CUSTOM_1
end

--[[ Команда, которой отдаём вьюверы сектора: её собственная, либо
     экспериментальная (см. fow_team в шапке). ]]
function modifier_barghest_vision_cone:GetViewerTeam()
    if BARGHEST_CONE.fow_team then return DOTA_TEAM_CUSTOM_1 end
    return self:GetParent():GetTeamNumber()
end

function modifier_barghest_vision_cone:GetFixedDayVision()
    return BARGHEST_CONE.near
end

function modifier_barghest_vision_cone:GetFixedNightVision()
    return BARGHEST_CONE.near
end

function modifier_barghest_vision_cone:OnCreated()
    if not IsServer() then return end
    if BARGHEST_CONE.native then return end
    -- Сразу, а не через interval: иначе первые доли секунды она слепая.
    self:OnIntervalThink()
    self:StartIntervalThink(BARGHEST_CONE.interval)
end

--[[ Радиус сектора = её базовый обзор (день/ночь). Базовые геттеры серверные
     и появились не так давно — с гардом и запасным числом из таблицы. ]]
function modifier_barghest_vision_cone:GetConeRange()
    local hParent = self:GetParent()
    local bDay    = GameRules:IsDaytime()
    local sBase   = bDay and "GetBaseDayTimeVisionRange" or "GetBaseNightTimeVisionRange"
    local sPlain  = bDay and "GetDayTimeVisionRange"     or "GetNightTimeVisionRange"
    local fRange
    if type(hParent[sBase]) == "function" then
        fRange = hParent[sBase](hParent)
    elseif type(hParent[sPlain]) == "function" then
        fRange = hParent[sPlain](hParent)
    end
    -- Обычный геттер мог вернуть уже ужатый нами обзор — тогда это не радиус.
    if fRange == nil or fRange <= BARGHEST_CONE.near then
        fRange = BARGHEST_CONE.fallback
    end
    return fRange
end

function modifier_barghest_vision_cone:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) or not hParent:IsAlive() then return end

    local nTeam    = self:GetViewerTeam()
    local vOrigin  = hParent:GetAbsOrigin()
    local vFwd     = hParent:GetForwardVector()
    local vRight   = hParent:GetRightVector()
    local fRange   = self:GetConeRange()
    local fRangeSq = fRange * fRange
    local fTan     = math.tan(math.rad(BARGHEST_CONE.angle * 0.5))
    local fStep    = BARGHEST_CONE.step
    local fRadius  = fStep * 0.75
    local fLife    = BARGHEST_CONE.interval + 0.1
    local fMaxZ    = GetGroundHeight(vOrigin, hParent) + BARGHEST_CONE.cliff_step

    -- x — вперёд от неё, y — вбок. Столбец при x=0 не нужен: пятачок `near`
    -- и так её собственный.
    local x = fStep
    while x <= fRange do
        local fHalf = math.min(x * fTan, math.sqrt(math.max(0, fRangeSq - x * x)))
        local y = 0
        while y <= fHalf do
            local tSides = (y == 0) and { 0 } or { y, -y }
            for _, fSide in ipairs(tSides) do
                local vPos = vOrigin + vFwd * x + vRight * fSide
                if GetGroundHeight(vPos, hParent) <= fMaxZ then
                    AddFOWViewer(nTeam, vPos, fRadius, fLife, true)
                end
            end
            y = y + fStep
        end
        x = x + fStep
    end
end
