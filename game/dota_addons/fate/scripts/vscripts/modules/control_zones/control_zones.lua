--[[
    Control Zones — зоны контроля.

    Вид 1 (победная зона): одна зона на раунд, ОДНА общая полоска
    (influence: >0 Red, <0 Black). Захват идёт только когда в зоне ровно
    одна команда (любой защитник внутри полностью держит зону); перезахват
    сначала снимает чужой прогресс, затем заполняет свой. Полная полоска =
    владение: +BONUS_POINTS к счёту живых команды при таймаут-резолве
    (гистерезис: владение снимается, только когда влияние вернулось в 0).
    Захват НЕ завершает раунд. Позиция зоны смещается к базе отстающей по
    счёту команды. На таймауте возможен овертайм (см. секцию ОВЕРТАЙМ).

    Вид 2 (бафф-зоны): 1-2 маленькие зоны; удержание без врагов HOLD_TIME
    секунд даёт всей команде бафф до конца раунда или перезахвата.

    Интеграция с addon_game_mode.lua — четыре хука:
      ControlZones:OnPreRound(round, radScore, direScore, gameMode) — из InitializeRound
      ControlZones:OnRoundStart()                                   — из таймера 'beginround'
      ControlZones:OnRoundEnd()                                     — из FinishRound
      ControlZones:TryStartOvertime(resolveFn)                      — из таймера 'round_timer'
    Все хуки сами проверяют IsEnabled(); при выключенном модуле игра
    работает ровно как раньше.

    Чат-команды: -zonepos, -zoneinfo (все); -zonehere, -zonecap N,
    -zonegrace (только с читами/в tools mode).
]]

local CONFIG = require("modules/control_zones/config")

ControlZones = ControlZones or {}
ControlZones.CONFIG = CONFIG
-- шанс на две бафф-зоны живёт между раундами
ControlZones.twoZoneChance = ControlZones.twoZoneChance or 0
ControlZones.buffZones = ControlZones.buffZones or {}
-- голосование на старте (team select): выключаем зоны только если
-- «выключить» строго больше «включить»; ничья/нет голосов = включено
ControlZones.voteEnable = ControlZones.voteEnable or 0
ControlZones.voteDisable = ControlZones.voteDisable or 0
ControlZones.votedPlayers = ControlZones.votedPlayers or {}

local TEAM_RED   = DOTA_TEAM_GOODGUYS -- Red Faction
local TEAM_BLACK = DOTA_TEAM_BADGUYS  -- Black Faction

-- Кольцо зоны: CP0 = позиция, CP1 = цвет в долях 0..1, CP2 = (радиус,
-- время жизни, 0); живём дольше раунда и убиваем вручную. Перекраска —
-- только пересозданием (цвет сэмплируется при спавне частиц).
local RING_PARTICLE = "particles/zlodemon/zlodemon_basic_circle.vpcf"
local RING_DURATION = 999

-- Стена (ребро прямоугольной зоны): CP0 = начало, CP1 = конец; посадка на
-- землю внутри партикла. Цвет НЕЛЬЗЯ передать в валвовских детей через CP
-- (градиенты статичны), поэтому 4 перекрашенных варианта диздор-стены
-- (сгенерированы hue-replace скриптом, см. память control-zones).
local WALL_PARTICLES = {
    neutral = "particles/zlodemon/wall_zone_grey.vpcf",
    contest = "particles/zlodemon/wall_zone_orange.vpcf",
    ally    = "particles/zlodemon/wall_zone_blue.vpcf",
    enemy   = "particles/zlodemon/wall_zone_red.vpcf",
}

local MARKER_UNIT_VICTORY = "npc_zone_marker_victory"
local MARKER_UNIT_BUFF = "npc_zone_marker_buff"

LinkLuaModifier("modifier_zone_buff_damage", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zone_buff_armor", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zone_buff_ms", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)

function ControlZones:Precache(context)
    PrecacheResource("particle", RING_PARTICLE, context)
    for _, p in pairs(WALL_PARTICLES) do
        PrecacheResource("particle", p, context)
    end
    PrecacheUnitByNameSync(MARKER_UNIT_VICTORY, context)
    PrecacheUnitByNameSync(MARKER_UNIT_BUFF, context)
end

function ControlZones:IsEnabled()
    if not CONFIG.ENABLED then return false end
    if self.runtimeDisabled then return false end
    if self.bMapAllowed == nil then
        self.bMapAllowed = CONFIG.MAPS[GetMapName()] == true
    end
    return self.bMapAllowed
end

-- Рантайм-переключатель: чит-команды -zoneoff/-zoneon сейчас, хук для
-- голосования лобби потом. Выключение мгновенно чистит текущие зоны
-- (раунд дорешивается старыми правилами), включение подхватится со
-- следующего раунда.
function ControlZones:SetRuntimeEnabled(enable)
    self.runtimeDisabled = not enable
    if not enable then
        self:Cleanup()
    end
end

-- КОРЕНЬ ИГРОВОГО ОТКАЗА 2026-07-16/17: на валвовских дедикейт-серверах
-- библиотека debug ОТСУТСТВУЕТ (в tools есть!). Прямое `xpcall(fn,
-- debug.traceback)` вычисляет debug.traceback в момент вызова -> индексация
-- nil -> необработанный краш при КАЖДОМ вызове GuardCall -> смерть
-- InitializeRound. Поэтому трейсбек берём лениво и с проверкой.
local function SafeTraceback(msg)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        return debug.traceback(tostring(msg), 2)
    end
    return tostring(msg)
end

-- Страховка: любая внутренняя ошибка зон НЕ должна ломать цикл раундов
-- (необработанная ошибка в InitializeRound убивает весь старт раунда).
-- При ошибке модуль чистится и выключается до ручного -zoneon.
local function DisableOnError(where, err)
    print("[ControlZones] ERROR in " .. where .. " — zones disabled:\n" .. tostring(err))
    ControlZones.runtimeDisabled = true
    pcall(function() ControlZones:Cleanup() end)
    pcall(function()
        -- в реальном лобби серверная консоль недоступна — шлём начало
        -- трейсбека прямо в чат, иначе причину не узнать
        local brief = tostring(err):sub(1, 220):gsub("%s+", " ")
        GameRules:SendCustomMessage("[Zones] internal error in " .. where
            .. ", zones disabled (-zoneon to re-enable): " .. brief, 0, 0)
    end)
end

local function GuardCall(self, fnName, ...)
    local n = select("#", ...)
    local args = { ... }
    local ok, err = xpcall(function()
        return self[fnName](self, unpack(args, 1, n))
    end, SafeTraceback)
    if not ok then DisableOnError(fnName, err) end
    return ok
end

local function TeamName(team)
    return team == TEAM_RED and "Red Faction" or "Black Faction"
end

local function CenterMessage(text, duration)
    FireGameEvent("show_center_message", { message = text, duration = duration or 4.0 })
end

-- ============================ ГЕОМЕТРИЯ ============================

-- Якоря = точки спавна команд. Глобалы мода могут оказаться nil в момент
-- вызова (наблюдалось в игре на старте раунда 1) — тогда берём копии из
-- конфига и один раз предупреждаем в консоль.
local warnedAnchors = false
local function GetAnchors()
    local A = SPAWN_POSITION_RADIANT_DM
    local B = SPAWN_POSITION_DIRE_DM
    if not A or not B then
        if not warnedAnchors then
            warnedAnchors = true
            print("[ControlZones] WARNING: SPAWN_POSITION_*_DM is nil, using CONFIG.ANCHOR_* fallback")
        end
        A = A or CONFIG.ANCHOR_RADIANT
        B = B or CONFIG.ANCHOR_DIRE
    end
    return A, B
end

-- Позиция из параметрического описания {t, side}. t — доля пути между
-- базами; если fromRadiantSide == false, t отсчитывается от базы Dire.
-- side — смещение перпендикулярно оси баз (фиксированное для карты).
local function ResolveZonePos(def, fromRadiantSide)
    local A, B = GetAnchors()
    local t = def.t
    if fromRadiantSide == false then t = 1 - t end
    local axis = B - A
    local dir = axis:Normalized()
    local perp = Vector(-dir.y, dir.x, 0)
    local p = A + axis * t + perp * (def.side or 0)
    return GetGroundPosition(Vector(p.x, p.y, 0), nil)
end

-- На какой стороне карты спавнится команда в этом раунде
-- (та же формула, что в GetRespawnPos)
local function IsTeamOnRadiantSide(team, round)
    return (team + round) % 2 == 1
end

-- Обратное к ResolveZonePos: мировая точка -> { t, side } от радиантской
-- базы. Для подбора позиций в конфиг (-zonepos печатает готовую строку).
function ControlZones:WorldToParam(pos)
    local A, B = GetAnchors()
    local axis = B - A
    local perp = Vector(-axis:Normalized().y, axis:Normalized().x, 0)
    local d = pos - A
    -- проекции в плоскости XY (ResolveZonePos сажает точку на землю,
    -- поэтому Z в параметрике не участвует)
    local t = (d.x * axis.x + d.y * axis.y) / (axis.x * axis.x + axis.y * axis.y)
    local side = (d.x * perp.x + d.y * perp.y) / (perp.x * perp.x + perp.y * perp.y)
    return t, side
end

-- Оси зоны: обычный прямоугольник без поворота — X (слева направо, зона
-- шире) и Y (сверху вниз, уже). Ось между базами используется только для
-- ПОЗИЦИОНИРОВАНИЯ (ResolveZonePos), не для ориентации коробки.
local function GetAxes()
    return Vector(1, 0, 0), Vector(0, 1, 0)
end

-- Точка внутри зоны? Победная зона — ориентированный прямоугольник
-- (полудлина вдоль оси баз, полуширина поперёк), бафф-зоны — круги.
local function IsPointInZone(zone, point)
    local d = point - zone.pos
    if zone.shape == "rect" then
        local along = d.x * zone.axisDir.x + d.y * zone.axisDir.y
        local across = d.x * zone.axisPerp.x + d.y * zone.axisPerp.y
        return math.abs(along) <= zone.halfLength and math.abs(across) <= zone.halfWidth
    end
    return d:Length2D() <= zone.radius
end

-- ============================ ПОДСЧЁТ ============================

function ControlZones:CountInZone(zone)
    local counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 }
    LoopOverPlayers(function(player, playerID, hero)
        if hero:GetName() ~= "npc_dota_hero_target_dummy"
            and hero:IsAlive()
            and not hero:HasModifier("modifier_aoko_blue_ally") then
            local team = hero:GetTeam()
            if counts[team] and IsPointInZone(zone, hero:GetAbsOrigin()) then
                counts[team] = counts[team] + 1
            end
        end
    end)
    return counts
end

-- ============================ ПАРТИКЛИ ============================

function ControlZones:CreateRing(pos, radius, color)
    local p = ParticleManager:CreateParticle(RING_PARTICLE, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(p, 0, pos)
    ParticleManager:SetParticleControl(p, 1, Vector(color.x / 255, color.y / 255, color.z / 255))
    ParticleManager:SetParticleControl(p, 2, Vector(radius, RING_DURATION, 0))
    ParticleManager:SetParticleShouldCheckFoW(p, false)
    return p
end

local function DestroyRing(particle)
    if particle then
        -- immediate=true: кольцо zlodemon_basic_circle живёт по CP2.y
        -- (RING_DURATION), graceful-destroy (false) не убирал его сразу и
        -- партикль переживал смену раунда — поэтому рвём немедленно
        ParticleManager:DestroyParticle(particle, true)
        ParticleManager:ReleaseParticleIndex(particle)
    end
end

-- Визуал круглой зоны (бафф-зоны): одно кольцо. Возвращает список партиклов.
function ControlZones:CreateZoneVisual(zone, color)
    return { self:CreateRing(zone.pos, zone.radius, color) }
end

local function DestroyZoneVisual(zone)
    for _, p in ipairs(zone.particles or {}) do
        DestroyRing(p)
    end
    zone.particles = nil
end

-- Смена цвета визуала круглой зоны (no-op, если цвет тот же)
function ControlZones:SetZoneColor(zone, color)
    if zone.ringColor == color then return end
    zone.ringColor = color
    DestroyZoneVisual(zone)
    zone.particles = self:CreateZoneVisual(zone, color)
end

-- ==================== РАМКА ПРЯМОУГОЛЬНОЙ ЗОНЫ ====================
-- ОДИН партикл на команду: wall_zone_* строит замкнутый периметр по пути
-- CP0->CP1->CP2->CP3->CP4 (CP4 = CP0). Каждая команда видит рамку в СВОЁМ
-- цвете (синий = зона занята нами, красный = противником). team = nil
-- даёт общую рамку для всех (превью в -zoneshow).

local function RectCorners(zone)
    local L = zone.axisDir * zone.halfLength
    local W = zone.axisPerp * zone.halfWidth
    return {
        zone.pos + L + W,
        zone.pos - L + W,
        zone.pos - L - W,
        zone.pos + L - W,
    }
end

local function CreateFrame(corners, variant, team)
    local name = WALL_PARTICLES[variant] or WALL_PARTICLES.neutral
    local p
    if team then
        p = ParticleManager:CreateParticleForTeam(name, PATTACH_WORLDORIGIN, nil, team)
    else
        p = ParticleManager:CreateParticle(name, PATTACH_WORLDORIGIN, nil)
    end
    for i = 1, 4 do
        ParticleManager:SetParticleControl(p, i - 1, corners[i])
    end
    ParticleManager:SetParticleControl(p, 4, corners[1]) -- замыкание периметра
    ParticleManager:SetParticleShouldCheckFoW(p, false)
    return p
end

-- Вариант рамки для смотрящей команды при данном состоянии зоны.
-- state: "neutral" | "contest" | TEAM_RED | TEAM_BLACK (кто ведёт захват)
local function WallVariantFor(viewTeam, state)
    if state == "contest" then return "contest" end
    if state == "neutral" then return "neutral" end
    if state == viewTeam then return "ally" end
    return "enemy"
end

function ControlZones:CreateRectWalls(zone, state)
    local parts = {}
    local corners = RectCorners(zone)
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        table.insert(parts, CreateFrame(corners, WallVariantFor(team, state), team))
    end
    return parts
end

-- Смена состояния прямоугольной зоны = пересоздание стен (no-op без изменений)
function ControlZones:SetZoneState(zone, state)
    if zone.visualState == state then return end
    zone.visualState = state
    DestroyZoneVisual(zone)
    zone.particles = self:CreateRectWalls(zone, state)
end

-- Маркеры на миникарте: по дамми-юниту на команду (союзные юниты всегда
-- видны своей команде на миникарте, поэтому пара покрывает всех)
local function SpawnMarkers(pos, unitName)
    local markers = {}
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        local unit = CreateUnitByName(unitName, pos, false, nil, nil, team)
        if unit then
            local passive = unit:FindAbilityByName("zone_marker_passive")
            if passive then passive:SetLevel(1) end
            table.insert(markers, unit)
        end
    end
    return markers
end

local function RemoveMarkers(zone)
    for _, unit in ipairs(zone.markers or {}) do
        if IsNotNull(unit) then
            UTIL_Remove(unit)
        end
    end
    zone.markers = nil
end

function ControlZones:PingZones()
    -- по одному герою на команду для минимап-пинга
    local pingers = {}
    LoopOverPlayers(function(player, playerID, hero)
        if hero:GetName() ~= "npc_dota_hero_target_dummy" and not pingers[hero:GetTeam()] then
            pingers[hero:GetTeam()] = hero
        end
    end)
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        local hero = pingers[team]
        if hero and self.vz then
            MinimapEvent(team, hero, self.vz.pos.x, self.vz.pos.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 5)
        end
    end
end

-- ============================ ВЫБОР ЗОН ============================

-- Пулы позиций — АБСОЛЮТНЫЕ точки, настроенные вручную под каждую
-- сторону карты (никакого зеркалирования — карта несимметрична):
-- center при равном счёте, tierN_radiant/tierN_dire — по тому, на какой
-- стороне в ЭТОМ раунде спавнится отстающая команда.
-- Возвращает: позиция, тир (0/1/2), отстающая команда (0 при равном счёте).
-- Тир нужен вызывающему: в крайнем положении (tier2) зона стартует уже
-- захваченной отстающей стороной.
function ControlZones:PickVictoryZone(round, radiantScore, direScore)
    local vzc = CONFIG.VICTORY_ZONE
    local diff = math.abs(radiantScore - direScore)
    local poolName = "center"
    local tierNum, losingTeam = 0, 0
    if diff >= vzc.TIER1_SCORE_DIFF then
        local tier = diff >= vzc.TIER2_SCORE_DIFF and "tier2" or "tier1"
        tierNum = tier == "tier2" and 2 or 1
        losingTeam = radiantScore < direScore and TEAM_RED or TEAM_BLACK
        poolName = tier .. (IsTeamOnRadiantSide(losingTeam, round) and "_radiant" or "_dire")
    end

    local pool = vzc.POSITIONS[poolName]
    if not pool or #pool == 0 then
        -- сторону вычистили из конфига — не роняем раунд, берём center
        print("[ControlZones] WARNING: empty position pool '" .. poolName .. "', falling back to center")
        poolName = "center"
        pool = vzc.POSITIONS.center
    end

    local idx = RandomInt(1, #pool)
    local key = poolName .. idx
    if key == self.lastZoneKey and #pool > 1 then
        idx = idx % #pool + 1
        key = poolName .. idx
    end
    self.lastZoneKey = key
    local p = pool[idx]
    return GetGroundPosition(Vector(p.x, p.y, 0), nil), tierNum, losingTeam
end

function ControlZones:SetupBuffZones(round)
    self.buffZones = {}
    local bzc = CONFIG.BUFF_ZONES
    if not bzc.ENABLED then return end

    local count = 1
    if RandomFloat(0, 1) < self.twoZoneChance then
        count = 2
        self.twoZoneChance = 0
    else
        self.twoZoneChance = math.min(self.twoZoneChance + bzc.TWO_ZONE_CHANCE_STEP, 1)
    end

    -- кандидаты: не впритык к победной зоне, перемешаны
    local candidates = {}
    for _, def in ipairs(bzc.POSITIONS) do
        local pos = ResolveZonePos(def, true)
        if (pos - self.vz.pos):Length2D() > bzc.MIN_DISTANCE_TO_VICTORY then
            table.insert(candidates, pos)
        end
    end
    for i = #candidates, 2, -1 do
        local j = RandomInt(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    -- типы баффов без повторов в рамках раунда
    local buffPool = {}
    for name in pairs(bzc.BUFFS) do table.insert(buffPool, name) end

    for _, pos in ipairs(candidates) do
        if #self.buffZones >= count or #buffPool == 0 then break end
        local farEnough = true
        for _, bz in ipairs(self.buffZones) do
            if (pos - bz.pos):Length2D() < bzc.MIN_DISTANCE_BETWEEN then
                farEnough = false
                break
            end
        end
        if farEnough then
            local buffName = table.remove(buffPool, RandomInt(1, #buffPool))
            local bz = {
                shape = "circle",
                pos = pos,
                radius = bzc.RADIUS,
                buffName = buffName,
                owner = 0,
                capTeam = 0,
                capProgress = 0,
                active = false,
                counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 },
                appliedTo = {},
            }
            bz.ringColor = CONFIG.COLOR_NEUTRAL
            bz.particles = self:CreateZoneVisual(bz, CONFIG.COLOR_NEUTRAL)
            bz.markers = SpawnMarkers(pos, MARKER_UNIT_BUFF)
            table.insert(self.buffZones, bz)
        end
    end
end

-- ============================ ЖИЗНЕННЫЙ ЦИКЛ РАУНДА ============================

-- Голос из team_select (клиент шлёт zones_vote_finished по одному разу
-- при переходе из экрана выбора команд)
function ControlZones:OnZonesVote(keys)
    -- ошибка обработки голоса не должна ничего ломать — только лог
    local ok, err = xpcall(function() self:_OnZonesVote(keys) end, SafeTraceback)
    if not ok then
        print("[ControlZones] zones vote error: " .. tostring(err))
    end
end

function ControlZones:_OnZonesVote(keys)
    if self.voteResolved then return end
    local pid = tonumber(keys.PlayerID or keys.player)
    if pid then
        -- один голос на PlayerID, поздние (после ResolveVote) игнорируются
        if self.votedPlayers[pid] then return end
        self.votedPlayers[pid] = true
    end
    if tonumber(keys.enabled) == 1 then
        self.voteEnable = self.voteEnable + 1
    else
        self.voteDisable = self.voteDisable + 1
    end
end

-- Резолюция голосования — один раз, перед первым пре-раундом.
-- Default = включено: выключаем только при СТРОГОМ большинстве «против».
function ControlZones:ResolveVote()
    if self.voteResolved then return end
    self.voteResolved = true
    if not CONFIG.ENABLED then return end
    if self.voteDisable > self.voteEnable then
        self.runtimeDisabled = true
        GameRules:SendCustomMessage(string.format(
            "<font color='#FF3399'>Vote Result:</font> Battle zones <font color='#FF3399'>DISABLED</font> (%d : %d)",
            self.voteDisable, self.voteEnable), 0, 0)
    elseif self.voteEnable + self.voteDisable > 0 then
        GameRules:SendCustomMessage(string.format(
            "<font color='#FF3399'>Vote Result:</font> Battle zones <font color='#FF3399'>ENABLED</font> (%d : %d)",
            self.voteEnable, self.voteDisable), 0, 0)
    end
end

-- ВЕСЬ хук под GuardCall, включая ResolveVote/IsEnabled: OnPreRound —
-- первая строка InitializeRound, который для раунда 1 вызывается из
-- колбэка OnGameInProgress; непойманная ошибка здесь убивает не только
-- раунд, но и таймеры грааля и OnGameTimerThink (наблюдалось в игре
-- 2026-07-16: ни одного таймера, ни зон)
function ControlZones:OnPreRound(round, radiantScore, direScore, gameMode)
    GuardCall(self, "_PreRoundHook", round, radiantScore, direScore, gameMode)
end

function ControlZones:_PreRoundHook(round, radiantScore, direScore, gameMode)
    self:ResolveVote()
    if not self:IsEnabled() then return end
    self:_OnPreRound(round, radiantScore, direScore, gameMode)
end

function ControlZones:_OnPreRound(round, radiantScore, direScore, gameMode)
    self.GameMode = gameMode
    self:Cleanup() -- идемпотентно; заодно снимает баффы прошлого раунда

    -- счёт раундов нужен таймаут-логике овертайма (дефолтная победа при ничьей)
    self.radScore = radiantScore or 0
    self.direScore = direScore or 0

    local vzc = CONFIG.VICTORY_ZONE
    local pos, tier, losingTeam = self:PickVictoryZone(round, radiantScore, direScore)
    local axisDir, axisPerp = GetAxes()
    self.vz = {
        shape = "rect",
        pos = pos,
        halfLength = vzc.HALF_LENGTH,
        halfWidth = vzc.HALF_WIDTH,
        axisDir = axisDir,
        axisPerp = axisPerp,
        phase = "preround",
        influence = 0,  -- общая полоска: >0 = Red, <0 = Black, |v| = сек захвата
        owner = 0,      -- команда с полной полоской (снимается при возврате в 0)
        lastTouch = {}, -- когда команда последний раз касалась зоны (для овертайма)
        counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 },
    }
    -- крайнее положение (отставание 3+): зона сразу принадлежит отстающим —
    -- полная полоска и владение с первой секунды, противнику её дренить
    self.vz.autoCaptured = false
    if tier == 2 and losingTeam ~= 0 and vzc.TIER2_AUTO_CAPTURE then
        self.vz.influence = (losingTeam == TEAM_RED and 1 or -1) * vzc.CAPTURE_TIME
        self.vz.owner = losingTeam
        self.vz.autoCaptured = true
    end

    local initialState = self.vz.owner ~= 0 and self.vz.owner or "neutral"
    self.vz.visualState = initialState
    self.vz.particles = self:CreateRectWalls(self.vz, initialState)
    self.vz.markers = SpawnMarkers(pos, MARKER_UNIT_VICTORY)

    self:SetupBuffZones(round)

    -- обзор зон на время пре-раунда, чтобы обе команды видели место боя
    local visionDuration = PRE_ROUND_DURATION or 12
    local previewRadius = math.max(vzc.HALF_LENGTH, vzc.HALF_WIDTH) + 300
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        AddFOWViewer(team, pos, previewRadius, visionDuration, false)
        for _, bz in ipairs(self.buffZones) do
            AddFOWViewer(team, bz.pos, bz.radius + 200, visionDuration, false)
        end
    end
    self:PingZones()
    self:PushState(true)
end

-- Тоже целиком под защитой: вызывается строкой ПЕРЕД созданием
-- UI-таймера раунда в колбэке beginround
function ControlZones:OnRoundStart()
    GuardCall(self, "_RoundStartHook")
end

function ControlZones:_RoundStartHook()
    if not self:IsEnabled() then return end
    self:_OnRoundStart()
end

function ControlZones:_OnRoundStart()
    if not self.vz then return end
    local now = GameRules:GetGameTime()
    local vzc = CONFIG.VICTORY_ZONE

    self.vz.phase = "grace"
    self.vz.graceEnd = now + vzc.GRACE_PERIOD
    for _, bz in ipairs(self.buffZones) do
        bz.activateAt = now + CONFIG.BUFF_ZONES.ACTIVATION_DELAY
    end
    self.overtimeEnd = nil
    self.overtimeStart = nil
    self.overtimeResolve = nil
    self.leaveDeadline = nil
    self.lastContestants = nil
    self.stopped = false
    -- ожидаемый таймаут раунда: 'round_timer' взводится в InitializeRound на
    -- PRE_ROUND_DURATION + ROUND_DURATION, а этот хук — из 'beginround' на
    -- PRE_ROUND_DURATION, т.е. now + ROUND_DURATION = момент таймаута
    -- (обе метки по одним часам GameRules:GetGameTime, пауза их не разводит)
    self.roundEnd = now + (ROUND_DURATION or 300)

    -- обзор на зону НЕ на весь грейс, а только первые секунды раунда
    -- (VISION_AFTER_START): дальше зону надо разведывать самим
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        AddFOWViewer(team, self.vz.pos,
            math.max(vzc.HALF_LENGTH, vzc.HALF_WIDTH) + 300,
            vzc.VISION_AFTER_START or 5, false)
    end

    GameRules:SendCustomMessage("Control zone activates in " .. vzc.GRACE_PERIOD
        .. " seconds. Full capture counts as +" .. vzc.BONUS_POINTS .. " alive players at timeout!", 0, 0)
    if self.vz.autoCaptured and self.vz.owner ~= 0 then
        GameRules:SendCustomMessage(TeamName(self.vz.owner)
            .. " is behind by " .. vzc.TIER2_SCORE_DIFF
            .. "+ rounds: the control zone starts already captured by them!", 0, 0)
    end

    Timers:CreateTimer('cz_think', {
        endTime = CONFIG.TICK,
        callback = function()
            if GameRules:IsGamePaused() then return CONFIG.TICK end
            if _G.CurrentGameState ~= "FATE_ROUND_ONGOING" then return nil end
            if not GuardCall(self, "Think") then return nil end
            if self.stopped then return nil end
            return CONFIG.TICK
        end
    })
end

function ControlZones:OnRoundEnd()
    GuardCall(self, "_RoundEndHook")
end

function ControlZones:_RoundEndHook()
    if not self:IsEnabled() then return end
    self:Cleanup()
end

function ControlZones:Cleanup()
    Timers:RemoveTimer('cz_think')
    self.roundEnd = nil
    self.otPossible = 0
    self.otPossibleTeam = 0
    self.overtimeEnd = nil
    self.overtimeStart = nil
    self.overtimeResolve = nil
    self.leaveDeadline = nil
    self.lastContestants = nil
    if self.vz then
        DestroyZoneVisual(self.vz)
        RemoveMarkers(self.vz)
        self.vz = nil
    end
    for _, bz in ipairs(self.buffZones or {}) do
        self:RemoveBuffFromTeam(bz)
        DestroyZoneVisual(bz)
        RemoveMarkers(bz)
    end
    self.buffZones = {}
    -- true, чтобы уже запущенный тик cz_think гарантированно не пережил
    -- конец раунда (OnRoundStart следующего раунда снова ставит false)
    self.stopped = true
    self.lastSer = nil
    CustomNetTables:SetTableValue("zones", "victory", { enabled = self:IsEnabled() and 1 or 0, phase = "none" })
    CustomNetTables:SetTableValue("zones", "buff_1", { active = 0 })
    CustomNetTables:SetTableValue("zones", "buff_2", { active = 0 })
end

-- ============================ ТИК ============================

function ControlZones:Think()
    local now = GameRules:GetGameTime()
    self:ThinkVictory(now)
    if not self.stopped then
        self:ThinkBuffZones(now)
        self:ThinkOvertimeWarning(now)
        self:ThinkOvertime(now)
    end
    self:PushState(false)
end

function ControlZones:ThinkVictory(now)
    local vz = self.vz
    if not vz then return end
    local vzc = CONFIG.VICTORY_ZONE

    if vz.phase == "grace" then
        if now < vz.graceEnd then return end
        vz.phase = "active"
        CenterMessage("Control zone is now active!", 3.0)
    end

    local counts = self:CountInZone(vz)
    vz.counts = counts
    local red, black = counts[TEAM_RED], counts[TEAM_BLACK]
    if red > 0 then vz.lastTouch[TEAM_RED] = now end
    if black > 0 then vz.lastTouch[TEAM_BLACK] = now end

    -- захват идёт, только когда в зоне ровно одна команда: любой защитник
    -- внутри полностью держит зону (контест = заморозка полоски)
    local sole, n = 0, 0
    if red > 0 and black == 0 then
        sole, n = TEAM_RED, red
    elseif black > 0 and red == 0 then
        sole, n = TEAM_BLACK, black
    end

    if sole ~= 0 then
        local mult = math.min(1 + (n - 1) * vzc.SURPLUS_BONUS, vzc.SURPLUS_CAP)
        local dir = sole == TEAM_RED and 1 or -1
        vz.influence = math.max(-vzc.CAPTURE_TIME,
            math.min(vzc.CAPTURE_TIME, vz.influence + dir * CONFIG.TICK * mult))

        -- гистерезис владения: снимается только при возврате влияния в 0
        if vz.owner == TEAM_RED and vz.influence <= 0 then
            self:OnZoneNeutralized()
        elseif vz.owner == TEAM_BLACK and vz.influence >= 0 then
            self:OnZoneNeutralized()
        end
        if vz.owner == 0 then
            if vz.influence >= vzc.CAPTURE_TIME then
                self:OnZoneCaptured(TEAM_RED)
            elseif vz.influence <= -vzc.CAPTURE_TIME then
                self:OnZoneCaptured(TEAM_BLACK)
            end
        end
    end

    -- состояние стен: контест > захватывающая команда > владелец > нейтральное
    local state = "neutral"
    if red > 0 and black > 0 then
        state = "contest"
    elseif sole ~= 0 then
        state = sole
    elseif vz.owner ~= 0 then
        state = vz.owner
    end
    self:SetZoneState(vz, state)
end

function ControlZones:OnZoneCaptured(team)
    self.vz.owner = team
    CenterMessage(TeamName(team) .. " captured the control zone!\n+"
        .. CONFIG.VICTORY_ZONE.BONUS_POINTS .. " alive players at round timeout", 4.0)
    self:PushState(true)
end

function ControlZones:OnZoneNeutralized()
    local old = self.vz.owner
    self.vz.owner = 0
    CenterMessage(TeamName(old) .. " lost the control zone!", 3.0)
    self:PushState(true)
end

-- Бонус зоны к счёту живых на таймауте: (radiant, dire). Владелец полной
-- полоски получает +BONUS_POINTS, пока влияние не сдренено в 0.
-- Вызывается из ResolveTimeout (addon_game_mode.lua).
function ControlZones:GetAliveBonus()
    if not self:IsEnabled() then return 0, 0 end
    local vz = self.vz
    if not vz or vz.owner == 0 then return 0, 0 end
    local b = CONFIG.VICTORY_ZONE.BONUS_POINTS
    if vz.owner == TEAM_RED then return b, 0 end
    return 0, b
end

function ControlZones:ThinkBuffZones(now)
    local bzc = CONFIG.BUFF_ZONES
    for _, bz in ipairs(self.buffZones) do
        if bz.activateAt and now >= bz.activateAt then
            bz.active = true
            local counts = self:CountInZone(bz)
            bz.counts = counts
            local red, black = counts[TEAM_RED], counts[TEAM_BLACK]

            local soleTeam = 0
            if red > 0 and black == 0 then soleTeam = TEAM_RED
            elseif black > 0 and red == 0 then soleTeam = TEAM_BLACK end

            if soleTeam ~= 0 and soleTeam ~= bz.owner then
                if bz.capTeam ~= soleTeam then
                    bz.capTeam = soleTeam
                    bz.capProgress = 0
                end
                bz.capProgress = bz.capProgress + CONFIG.TICK
                if bz.capProgress >= bzc.HOLD_TIME then
                    self:CaptureBuffZone(bz, soleTeam)
                end
            else
                -- пусто, контест или владелец внутри: прогресс перехвата откатывается
                bz.capProgress = math.max(0, bz.capProgress - CONFIG.TICK * bzc.DECAY_RATE)
                if bz.capProgress == 0 then bz.capTeam = 0 end
            end

            local color = CONFIG.COLOR_NEUTRAL
            if bz.capTeam ~= 0 then
                color = CONFIG.COLOR_CONTEST
            elseif bz.owner == TEAM_RED then
                color = CONFIG.COLOR_RED
            elseif bz.owner == TEAM_BLACK then
                color = CONFIG.COLOR_BLACK
            end
            self:SetZoneColor(bz, color)
        end
    end
end

function ControlZones:CaptureBuffZone(bz, team)
    self:RemoveBuffFromTeam(bz)
    bz.owner = team
    bz.capTeam = 0
    bz.capProgress = 0

    local def = CONFIG.BUFF_ZONES.BUFFS[bz.buffName]
    bz.appliedTo = {}
    LoopOverPlayers(function(player, playerID, hero)
        if hero:GetTeam() == team and hero:GetName() ~= "npc_dota_hero_target_dummy" then
            hero:AddNewModifier(hero, nil, def.modifier, {})
            table.insert(bz.appliedTo, hero)
        end
    end)

    GameRules:SendCustomMessage(TeamName(team) .. " captured a power zone: " .. def.label, 0, 0)
    CenterMessage(TeamName(team) .. " captured a power zone!\n" .. def.label, 3.0)
end

function ControlZones:RemoveBuffFromTeam(bz)
    if not bz.appliedTo then return end
    local def = CONFIG.BUFF_ZONES.BUFFS[bz.buffName]
    for _, hero in ipairs(bz.appliedTo) do
        if IsNotNull(hero) then
            hero:RemoveModifierByName(def.modifier)
        end
    end
    bz.appliedTo = {}
end

-- ============================ ОВЕРТАЙМ ============================
--
-- На таймауте раунда овертайм стартует, если команда, ПРОИГРЫВАЮЩАЯ по
-- виртуальному счёту (живые + бонус зоны, при ничьей — дефолт по счёту
-- раундов), касалась зоны в последние TOUCH_GRACE сек. Дальше овертайм
-- идёт, пока проигрывающая сторона контестит (стоит в зоне):
--   * контестящая сторона перевернула счёт, а противник сам не в зоне ->
--     немедленный резолв (новых атакующих ждать не будем);
--   * атакующие вышли из зоны, оставаясь проигрывающими -> leave-таймер
--     (стартовое значение линейно сгорает 5с -> 1с к LEAVE_TIMER_BURN-й
--     секунде овертайма); вернулись — сброс на максимум, истёк — резолв;
--   * OVERTIME_MAX (60с) — жёсткий потолок;
--   * пока активна La Pucelle, обработка овертайма заморожена.
-- Резолв = старый ResolveTimeout (он сам учитывает GetAliveBonus).

-- Живые по командам — та же логика, что в ResolveTimeout
local function CountAlive()
    local rad, dire = 0, 0
    LoopOverPlayers(function(player, playerID, hero)
        if hero:GetName() ~= "npc_dota_hero_target_dummy"
            and hero:IsAlive()
            and not hero:HasModifier("modifier_aoko_blue_ally") then
            if hero:GetTeam() == TEAM_RED then
                rad = rad + 1
            elseif hero:GetTeam() == TEAM_BLACK then
                dire = dire + 1
            end
        end
    end)
    return rad, dire
end

-- Кто выигрывает таймаут прямо сейчас: живые + бонус зоны, при равенстве
-- дефолт по счёту раундов (как в ResolveTimeout), полная ничья = 0
function ControlZones:VirtualWinner()
    local rad, dire = CountAlive()
    local br, bd = self:GetAliveBonus()
    rad, dire = rad + br, dire + bd
    if rad > dire then return TEAM_RED end
    if dire > rad then return TEAM_BLACK end
    if (self.radScore or 0) < (self.direScore or 0) then return TEAM_RED end
    if (self.radScore or 0) > (self.direScore or 0) then return TEAM_BLACK end
    return 0
end

-- Команда контестит, если не выигрывает виртуальный счёт и касалась зоны
-- за последние TOUCH_GRACE сек (для старта овертайма); внутри овертайма
-- контест = физическое присутствие в зоне (см. ThinkOvertime)
local function TouchedRecently(vz, team, now)
    local t = vz.lastTouch[team]
    return t ~= nil and now - t <= CONFIG.VICTORY_ZONE.TOUCH_GRACE
end

-- Имеет ли овертайм смысл прямо сейчас: проигрывающая по виртуальному счёту
-- команда касалась зоны в последние TOUCH_GRACE сек (то же условие, по
-- которому овертайм реально стартует на таймауте).
-- Возвращает: 1/0, команда-претендент.
function ControlZones:OvertimeWouldMatter(now)
    local vz = self.vz
    if not vz or vz.phase ~= "active" then return 0, 0 end
    local winner = self:VirtualWinner()
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        if team ~= winner and TouchedRecently(vz, team, now) then return 1, team end
    end
    return 0, 0
end

-- Флаг «раунд заканчивается, овертайм возможен» для панели зоны: сообщения
-- рисует клиент (их можно выключить тумблером в Fate settings), сервер лишь
-- держит состояние в неттейбле.
function ControlZones:ThinkOvertimeWarning(now)
    local vzc = CONFIG.VICTORY_ZONE
    -- при активной La Pucelle таймаут вообще не резолвится (см. round_timer),
    -- обещать овертайм в этот момент нечестно
    if self.overtimeEnd or not self.roundEnd or _G.LaPucelleActivated then
        self.otPossible, self.otPossibleTeam = 0, 0
        return
    end
    if now < self.roundEnd - (vzc.OVERTIME_WARN_BEFORE or 15) then
        self.otPossible, self.otPossibleTeam = 0, 0
        return
    end
    self.otPossible, self.otPossibleTeam = self:OvertimeWouldMatter(now)
end

function ControlZones:TryStartOvertime(resolveFn)
    if not self:IsEnabled() then return false end
    local ok, started = xpcall(function()
        return self:_TryStartOvertime(resolveFn)
    end, SafeTraceback)
    if not ok then
        DisableOnError("TryStartOvertime", started)
        return false
    end
    return started
end

function ControlZones:_TryStartOvertime(resolveFn)
    local vz = self.vz
    if not vz or vz.phase ~= "active" then return false end
    local now = GameRules:GetGameTime()
    local vzc = CONFIG.VICTORY_ZONE

    -- освежить счётчики и касания (тик мог быть до TICK сек назад)
    local counts = self:CountInZone(vz)
    vz.counts = counts
    if counts[TEAM_RED] > 0 then vz.lastTouch[TEAM_RED] = now end
    if counts[TEAM_BLACK] > 0 then vz.lastTouch[TEAM_BLACK] = now end

    local winner = self:VirtualWinner()
    local contest = false
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        if team ~= winner and TouchedRecently(vz, team, now) then
            contest = true
        end
    end
    if not contest then return false end

    self.overtimeStart = now
    self.overtimeEnd = now + vzc.OVERTIME_MAX
    self.overtimeResolve = resolveFn
    self.leaveDeadline = nil
    self.lastContestants = nil
    self.otPossible, self.otPossibleTeam = 0, 0
    -- сообщение «OVERTIME!» рисует панель зоны (его можно выключить
    -- тумблером в Fate settings), поэтому серверный CenterMessage не шлём
    self:PushState(true) -- отсчёт овертайма рисует панель зоны (overtime_end)
    return true
end

function ControlZones:EndOvertime()
    local resolve = self.overtimeResolve
    self.overtimeStart = nil
    self.overtimeEnd = nil
    self.overtimeResolve = nil
    self.leaveDeadline = nil
    self.stopped = true
    if resolve then resolve() end
end

function ControlZones:ThinkOvertime(now)
    if not self.overtimeEnd then return end
    -- как и обычный таймаут, овертайм не резолвится, пока идёт La Pucelle:
    -- замораживаем обработку (дедлайны догорят сразу после её окончания)
    if _G.LaPucelleActivated then return end
    local vzc = CONFIG.VICTORY_ZONE
    local vz = self.vz
    if not vz then return self:EndOvertime() end

    if now >= self.overtimeEnd then return self:EndOvertime() end

    -- контест в овертайме: проигрывающая сторона физически в зоне
    -- (счётчики обновил ThinkVictory этим же тиком)
    local winner = self:VirtualWinner()
    local contestants = {}
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        if team ~= winner and vz.counts[team] > 0 then
            table.insert(contestants, team)
        end
    end

    if #contestants > 0 then
        self.lastContestants = contestants
        self.leaveDeadline = nil
        return
    end

    -- никто не контестит. Если недавние контестанты теперь ВЫИГРЫВАЮТ
    -- (перевернули счёт), ждать им некого — немедленный резолв
    local flipped = false
    for _, team in ipairs(self.lastContestants or {}) do
        if team == winner then flipped = true end
    end
    if flipped then return self:EndOvertime() end

    -- атакующие вышли, оставаясь проигрывающими: leave-таймер; окно
    -- линейно сгорает от LEAVE_TIMER_START к LEAVE_TIMER_MIN уже к
    -- LEAVE_TIMER_BURN-й секунде овертайма
    if not self.leaveDeadline then
        local frac = math.min((now - self.overtimeStart) / vzc.LEAVE_TIMER_BURN, 1)
        local window = vzc.LEAVE_TIMER_START
            - (vzc.LEAVE_TIMER_START - vzc.LEAVE_TIMER_MIN) * frac
        self.leaveDeadline = now + window
    elseif now >= self.leaveDeadline then
        return self:EndOvertime()
    end
end

-- ============================ NET TABLE ============================

-- Пишем состояние в CustomNetTables("zones") только при изменении
function ControlZones:PushState(force)
    local vz = self.vz
    local vzc = CONFIG.VICTORY_ZONE

    local victory = { enabled = self:IsEnabled() and 1 or 0, phase = "none" }
    if vz then
        victory.phase = vz.phase
        victory.x = math.floor(vz.pos.x)
        victory.y = math.floor(vz.pos.y)
        victory.shape = vz.shape
        victory.half_length = vz.halfLength
        victory.half_width = vz.halfWidth
        victory.grace_end = vz.graceEnd and math.floor(vz.graceEnd * 10) / 10 or 0
        victory.capture_time = vzc.CAPTURE_TIME
        -- одна полоска: influence >0 = Red, <0 = Black (десятые доли сек)
        victory.influence = math.floor(vz.influence * 10) / 10
        victory.owner = vz.owner
        victory.bonus_points = vzc.BONUS_POINTS
        victory.count_red = vz.counts[TEAM_RED]
        victory.count_black = vz.counts[TEAM_BLACK]
        -- отсчёты овертайма/возврата рисует панель зоны локальным тикером
        victory.overtime = self.overtimeEnd and 1 or 0
        victory.overtime_end = self.overtimeEnd and math.floor(self.overtimeEnd * 10) / 10 or 0
        victory.leave_end = self.leaveDeadline and math.floor(self.leaveDeadline * 10) / 10 or 0
        -- «раунд кончается, овертайм возможен» + кто его тянет; сообщения
        -- об овертайме рисует клиент по этим полям
        victory.ot_possible = self.otPossible or 0
        victory.ot_team = self.otPossibleTeam or 0
        victory.ot_end_warn = CONFIG.VICTORY_ZONE.OVERTIME_END_WARN or 10
        victory.round_end = self.roundEnd and math.floor(self.roundEnd * 10) / 10 or 0
    end

    local buffs = {}
    for i = 1, 2 do
        local bz = self.buffZones[i]
        local t = { active = 0 }
        if bz then
            t.active = bz.active and 1 or 0
            t.x = math.floor(bz.pos.x)
            t.y = math.floor(bz.pos.y)
            t.radius = bz.radius
            t.owner = bz.owner
            t.cap_team = bz.capTeam
            t.cap_progress = math.floor(bz.capProgress * 10) / 10
            t.hold_time = CONFIG.BUFF_ZONES.HOLD_TIME
            t.buff = bz.buffName
            t.label = CONFIG.BUFF_ZONES.BUFFS[bz.buffName].label
        end
        buffs[i] = t
    end

    -- дешёвая сериализация для сравнения с прошлым тиком
    local function ser(t)
        local parts = {}
        for k, v in pairs(t) do
            parts[#parts + 1] = k .. "=" .. tostring(v)
        end
        table.sort(parts)
        return table.concat(parts, ";")
    end
    local snapshot = ser(victory) .. "|" .. ser(buffs[1]) .. "|" .. ser(buffs[2])
    if not force and snapshot == self.lastSer then return end
    self.lastSer = snapshot

    CustomNetTables:SetTableValue("zones", "victory", victory)
    CustomNetTables:SetTableValue("zones", "buff_1", buffs[1])
    CustomNetTables:SetTableValue("zones", "buff_2", buffs[2])
end

-- ============================ ЧАТ-КОМАНДЫ ============================

function ControlZones:OnPlayerChat(keys)
    -- ошибки чат-команд только логируются, систему не выключают
    local ok, err = xpcall(function() self:_OnPlayerChat(keys) end, SafeTraceback)
    if not ok then
        print("[ControlZones] chat command error: " .. tostring(err))
    end
end

function ControlZones:_OnPlayerChat(keys)
    -- нет гейта на IsEnabled: -zonepos полезна везде, а -zoneon обязана
    -- работать и при выключенной системе
    if not keys.text then return end
    local text = string.lower(keys.text)
    if string.sub(text, 1, 5) ~= "-zone" then return end

    local playerId = keys.playerid
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)

    if text == "-zonepos" then
        if hero then
            local p = hero:GetAbsOrigin()
            -- готовая строка для пулов победной зоны (абсолютные координаты);
            -- t/side — только для параметрического пула бафф-зон
            local t, side = self:WorldToParam(p)
            GameRules:SendCustomMessage(string.format(
                "[Zones] config line: Vector(%.0f, %.0f, 0),", p.x, p.y), 0, 0)
            print(string.format(
                "[ControlZones] -zonepos: Vector(%.0f, %.0f, 0),   (buff pool: { t = %.2f, side = %.0f },)",
                p.x, p.y, t, side))
        end
        return
    end

    if text == "-zoneinfo" then
        if self.vz then
            local vz = self.vz
            GameRules:SendCustomMessage(string.format(
                "[Zones] phase=%s pos=(%.0f, %.0f) influence %.1f of %d (owner %s, in zone %d/%d)",
                vz.phase, vz.pos.x, vz.pos.y,
                vz.influence, CONFIG.VICTORY_ZONE.CAPTURE_TIME,
                vz.owner == 0 and "none" or TeamName(vz.owner),
                vz.counts[TEAM_RED], vz.counts[TEAM_BLACK]), 0, 0)
        else
            GameRules:SendCustomMessage("[Zones] no active zone", 0, 0)
        end
        for i, bz in ipairs(self.buffZones) do
            GameRules:SendCustomMessage(string.format(
                "[Zones] buff %d (%s): owner=%d cap=%.1f pos=(%.0f, %.0f)",
                i, bz.buffName, bz.owner, bz.capProgress, bz.pos.x, bz.pos.y), 0, 0)
        end
        return
    end

    -- дальше только чит-команды
    if not (GameRules:IsCheatMode() or IsInToolsMode()) then return end

    if text == "-zonehere" and hero and self.vz then
        local pos = GetGroundPosition(hero:GetAbsOrigin(), nil)
        self.vz.pos = pos
        self.vz.visualState = nil
        DestroyZoneVisual(self.vz)
        self:SetZoneState(self.vz, "neutral")
        RemoveMarkers(self.vz)
        self.vz.markers = SpawnMarkers(pos, MARKER_UNIT_VICTORY)
        GameRules:SendCustomMessage(string.format("[Zones] victory zone moved to %.0f, %.0f", pos.x, pos.y), 0, 0)
        self:PushState(true)
        return
    end

    -- выставить влияние в пользу СВОЕЙ команды (сек); полное значение
    -- сразу даёт владение, 0 — нейтрализует
    local capValue = string.match(text, "^%-zonecap%s+(%d+)")
    if capValue and hero and self.vz then
        local vz = self.vz
        local team = hero:GetTeam()
        if team == TEAM_RED or team == TEAM_BLACK then
            local cap = CONFIG.VICTORY_ZONE.CAPTURE_TIME
            local v = math.min(tonumber(capValue), cap)
            vz.influence = team == TEAM_RED and v or -v
            if vz.owner ~= 0 and vz.owner ~= team then vz.owner = 0 end
            if v >= cap then vz.owner = team end
            if v == 0 then vz.owner = 0 end
            GameRules:SendCustomMessage(string.format(
                "[Zones] influence set to %.0f for %s (owner %s)",
                v, TeamName(team), vz.owner == 0 and "none" or TeamName(vz.owner)), 0, 0)
            self:PushState(true)
        end
        return
    end

    if text == "-zonegrace" and self.vz and self.vz.phase == "grace" then
        self.vz.graceEnd = GameRules:GetGameTime()
        GameRules:SendCustomMessage("[Zones] grace period skipped", 0, 0)
        return
    end

    -- Репро игрового пути голосования в tools (краш 2026-07-16 был в
    -- реальной игре, где team_select шлёт голоса): сбрасывает состояние и
    -- прогоняет голос КАЖДОГО подключённого игрока через настоящий
    -- OnZonesVote, затем тот же ResolveVote, что зовёт OnPreRound.
    -- "-zonevotesim off" — голоса «против» (ветка отключения; вернуть
    -- потом -zoneon).
    local simVote = string.match(text, "^%-zonevotesim%s*(%a*)")
    if simVote then
        local enabled = simVote == "off" and 0 or 1
        self.voteResolved = nil
        self.votedPlayers = {}
        self.voteEnable, self.voteDisable = 0, 0
        local fed = 0
        for pid = 0, 23 do
            if PlayerResource:IsValidPlayerID(pid) then
                self:OnZonesVote({ PlayerID = pid, enabled = enabled })
                fed = fed + 1
            end
        end
        self:ResolveVote()
        GameRules:SendCustomMessage(string.format(
            "[Zones] vote sim: fed %d votes (enabled=%d) — check console for [ControlZones] errors",
            fed, enabled), 0, 0)
        return
    end

    if text == "-zoneoff" then
        self:SetRuntimeEnabled(false)
        GameRules:SendCustomMessage("[Zones] control zones DISABLED (runtime)", 0, 0)
        return
    end

    if text == "-zoneon" then
        self:SetRuntimeEnabled(true)
        GameRules:SendCustomMessage("[Zones] control zones ENABLED, zones return next round", 0, 0)
        return
    end

    -- показать все позиции-кандидаты на 10с: серый=center, оранжевый=tier1,
    -- красный=tier2 (прямоугольники стенами; пулы обеих сторон настроены
    -- вручную и показываются как есть), синий=пул бафф-зон (круги)
    if text == "-zoneshow" then
        local vzc = CONFIG.VICTORY_ZONE
        local poolColors = {
            center = "neutral",
            tier1_radiant = "contest",
            tier1_dire = "contest",
            tier2_radiant = "enemy",
            tier2_dire = "enemy",
        }
        local axisDir, axisPerp = GetAxes()
        for poolName, variant in pairs(poolColors) do
            for i, p in ipairs(vzc.POSITIONS[poolName] or {}) do
                local pos = GetGroundPosition(Vector(p.x, p.y, 0), nil)
                local preview = {
                    shape = "rect", pos = pos,
                    halfLength = vzc.HALF_LENGTH, halfWidth = vzc.HALF_WIDTH,
                    axisDir = axisDir, axisPerp = axisPerp,
                }
                local frame = CreateFrame(RectCorners(preview), variant, nil)
                Timers:CreateTimer(10, function() DestroyRing(frame) end)
                print(string.format("[ControlZones] %s[%d]: %.0f, %.0f", poolName, i, pos.x, pos.y))
            end
        end
        for i, def in ipairs(CONFIG.BUFF_ZONES.POSITIONS) do
            local pos = ResolveZonePos(def, true)
            local ring = self:CreateRing(pos, CONFIG.BUFF_ZONES.RADIUS, Vector(80, 160, 255))
            Timers:CreateTimer(10, function() DestroyRing(ring) end)
            print(string.format("[ControlZones] buff[%d]: %.0f, %.0f", i, pos.x, pos.y))
        end
        GameRules:SendCustomMessage("[Zones] showing all candidate spots for 10s (white=center, yellow=tier1, red=tier2, blue=buff); coords in console", 0, 0)
        return
    end

    local buffIndex = string.match(text, "^%-zonebuffhere%s+(%d+)")
    if buffIndex and hero then
        local bz = self.buffZones[tonumber(buffIndex)]
        if bz then
            bz.pos = GetGroundPosition(hero:GetAbsOrigin(), nil)
            bz.ringColor = nil
            DestroyZoneVisual(bz)
            self:SetZoneColor(bz, CONFIG.COLOR_NEUTRAL)
            RemoveMarkers(bz)
            bz.markers = SpawnMarkers(bz.pos, MARKER_UNIT_BUFF)
            GameRules:SendCustomMessage(string.format("[Zones] buff zone %s moved to %.0f, %.0f", buffIndex, bz.pos.x, bz.pos.y), 0, 0)
            self:PushState(true)
        end
        return
    end
end

Events:Register("activate", function()
    ListenToGameEvent("player_chat", function(keys)
        ControlZones:OnPlayerChat(keys)
    end, nil)
    CustomGameEventManager:RegisterListener("zones_vote_finished", function(_, keys)
        ControlZones:OnZonesVote(keys)
    end)
    -- Секция Control Zones чит-панели (eyeherodemo): payload = короткая
    -- команда, маппится в чат-пайплайн -zone* — чит-гейт (IsCheatMode /
    -- tools mode) и обработка ошибок приезжают оттуда бесплатно
    local ZONE_CHEAT_COMMANDS = {
        show    = "-zoneshow",
        pos     = "-zonepos",
        here    = "-zonehere",
        grace   = "-zonegrace",
        capfull = "-zonecap 999", -- клампится до CAPTURE_TIME = владение
        capzero = "-zonecap 0",
        info    = "-zoneinfo",
        on      = "-zoneon",
        off     = "-zoneoff",
    }
    CustomGameEventManager:RegisterListener("ZoneCheatButtonPressed", function(_, keys)
        local text = ZONE_CHEAT_COMMANDS[tostring(keys.str)]
        if text then
            ControlZones:OnPlayerChat({ playerid = keys.PlayerID, text = text })
        end
    end)
end)
