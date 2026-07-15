--[[
    Control Zones — зоны контроля.

    Вид 1 (победная зона): одна зона на раунд; очки захвата идут команде,
    у которой в зоне строго больше живых героев. Полный захват = победа в
    раунде. Прогресс каждой команды независим и не сгорает. Позиция зоны
    смещается к базе отстающей по счёту команды.

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

local TEAM_RED   = DOTA_TEAM_GOODGUYS -- Red Faction
local TEAM_BLACK = DOTA_TEAM_BADGUYS  -- Black Faction

-- Кольцо зоны: CP0 = позиция, CP1 = цвет в долях 0..1, CP2 = (радиус,
-- время жизни, 0); живём дольше раунда и убиваем вручную. Перекраска —
-- только пересозданием (цвет сэмплируется при спавне частиц).
local RING_PARTICLE = "particles/zlodemon/zlodemon_basic_circle.vpcf"
local RING_DURATION = 999

local MARKER_UNIT_VICTORY = "npc_zone_marker_victory"
local MARKER_UNIT_BUFF = "npc_zone_marker_buff"

LinkLuaModifier("modifier_zone_buff_damage", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zone_buff_armor", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zone_buff_ms", "modules/control_zones/zone_buffs.lua", LUA_MODIFIER_MOTION_NONE)

function ControlZones:Precache(context)
    PrecacheResource("particle", RING_PARTICLE, context)
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

-- Страховка: любая внутренняя ошибка зон НЕ должна ломать цикл раундов
-- (необработанная ошибка в InitializeRound убивает весь старт раунда).
-- При ошибке модуль чистится и выключается до ручного -zoneon.
local function DisableOnError(where, err)
    print("[ControlZones] ERROR in " .. where .. " — zones disabled:\n" .. tostring(err))
    ControlZones.runtimeDisabled = true
    pcall(function() ControlZones:Cleanup() end)
    pcall(function()
        GameRules:SendCustomMessage("[Zones] internal error, control zones disabled (see console; -zoneon to re-enable)", 0, 0)
    end)
end

local function GuardCall(self, fnName, ...)
    local n = select("#", ...)
    local args = { ... }
    local ok, err = xpcall(function()
        return self[fnName](self, unpack(args, 1, n))
    end, debug.traceback)
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

-- ============================ ПОДСЧЁТ ============================

function ControlZones:CountInZone(pos, radius)
    local counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 }
    LoopOverPlayers(function(player, playerID, hero)
        if hero:GetName() ~= "npc_dota_hero_target_dummy"
            and hero:IsAlive()
            and not hero:HasModifier("modifier_aoko_blue_ally") then
            local team = hero:GetTeam()
            if counts[team] and (hero:GetAbsOrigin() - pos):Length2D() <= radius then
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

-- Смена цвета кольца зоны = пересоздание партикла (no-op, если цвет тот же)
function ControlZones:SetZoneRingColor(zone, color)
    if zone.ringColor == color then return end
    zone.ringColor = color
    DestroyRing(zone.particle)
    zone.particle = self:CreateRing(zone.pos, zone.radius, color)
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

function ControlZones:PickVictoryZone(round, radiantScore, direScore)
    local vzc = CONFIG.VICTORY_ZONE
    local diff = math.abs(radiantScore - direScore)
    local poolName = "center"
    if diff >= vzc.TIER2_SCORE_DIFF then
        poolName = "tier2"
    elseif diff >= vzc.TIER1_SCORE_DIFF then
        poolName = "tier1"
    end
    local pool = vzc.POSITIONS[poolName]

    -- t отсчитывается от базы отстающей команды в ЭТОМ раунде;
    -- при равном счёте пул center симметричен и сторона не важна
    local losingTeam = radiantScore < direScore and TEAM_RED or TEAM_BLACK
    local fromRadiantSide = IsTeamOnRadiantSide(losingTeam, round)

    local idx = RandomInt(1, #pool)
    local key = poolName .. idx
    if key == self.lastZoneKey and #pool > 1 then
        idx = idx % #pool + 1
        key = poolName .. idx
    end
    self.lastZoneKey = key
    return ResolveZonePos(pool[idx], fromRadiantSide)
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
            table.insert(self.buffZones, {
                pos = pos,
                radius = bzc.RADIUS,
                buffName = buffName,
                owner = 0,
                capTeam = 0,
                capProgress = 0,
                active = false,
                counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 },
                appliedTo = {},
                ringColor = CONFIG.COLOR_NEUTRAL,
                particle = self:CreateRing(pos, bzc.RADIUS, CONFIG.COLOR_NEUTRAL),
                markers = SpawnMarkers(pos, MARKER_UNIT_BUFF),
            })
        end
    end
end

-- ============================ ЖИЗНЕННЫЙ ЦИКЛ РАУНДА ============================

function ControlZones:OnPreRound(round, radiantScore, direScore, gameMode)
    if not self:IsEnabled() then return end
    GuardCall(self, "_OnPreRound", round, radiantScore, direScore, gameMode)
end

function ControlZones:_OnPreRound(round, radiantScore, direScore, gameMode)
    self.GameMode = gameMode
    self:Cleanup() -- идемпотентно; заодно снимает баффы прошлого раунда

    local vzc = CONFIG.VICTORY_ZONE
    local pos = self:PickVictoryZone(round, radiantScore, direScore)
    self.vz = {
        pos = pos,
        radius = vzc.RADIUS,
        phase = "preround",
        progress = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 },
        counts = { [TEAM_RED] = 0, [TEAM_BLACK] = 0 },
        ringColor = CONFIG.COLOR_NEUTRAL,
        particle = self:CreateRing(pos, vzc.RADIUS, CONFIG.COLOR_NEUTRAL),
        markers = SpawnMarkers(pos, MARKER_UNIT_VICTORY),
    }

    self:SetupBuffZones(round)

    -- обзор зон на время пре-раунда, чтобы обе команды видели место боя
    local visionDuration = PRE_ROUND_DURATION or 12
    for _, team in pairs({ TEAM_RED, TEAM_BLACK }) do
        AddFOWViewer(team, pos, vzc.RADIUS + 300, visionDuration, false)
        for _, bz in ipairs(self.buffZones) do
            AddFOWViewer(team, bz.pos, bz.radius + 200, visionDuration, false)
        end
    end
    self:PingZones()
    self:PushState(true)
end

function ControlZones:OnRoundStart()
    if not self:IsEnabled() then return end
    GuardCall(self, "_OnRoundStart")
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
    self.overtimeResolve = nil
    self.stopped = false

    GameRules:SendCustomMessage("Control zone activates in " .. vzc.GRACE_PERIOD .. " seconds. Hold it to win the round!", 0, 0)

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
    if not self:IsEnabled() then return end
    GuardCall(self, "Cleanup")
end

function ControlZones:Cleanup()
    Timers:RemoveTimer('cz_think')
    if self.overtimeEnd then
        CreateUITimer("Overtime", 0, "overtime_timer")
        self.overtimeEnd = nil
        self.overtimeResolve = nil
    end
    if self.vz then
        DestroyRing(self.vz.particle)
        RemoveMarkers(self.vz)
        self.vz = nil
    end
    for _, bz in ipairs(self.buffZones or {}) do
        self:RemoveBuffFromTeam(bz)
        DestroyRing(bz.particle)
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
        self:ThinkOvertime(now)
    end
    self:PushState(false)
end

function ControlZones:ThinkVictory(now)
    local vz = self.vz
    if not vz or vz.phase == "captured" then return end
    local vzc = CONFIG.VICTORY_ZONE

    if vz.phase == "grace" then
        if now < vz.graceEnd then return end
        vz.phase = "active"
        CenterMessage("Control zone is now active!", 3.0)
    end

    local counts = self:CountInZone(vz.pos, vz.radius)
    vz.counts = counts
    local red, black = counts[TEAM_RED], counts[TEAM_BLACK]

    local majority = 0
    if red > black then majority = TEAM_RED
    elseif black > red then majority = TEAM_BLACK end

    if majority ~= 0 then
        local surplus = math.abs(red - black)
        local mult = math.min(1 + (surplus - 1) * vzc.SURPLUS_BONUS, vzc.SURPLUS_CAP)
        vz.progress[majority] = math.min(vz.progress[majority] + CONFIG.TICK * mult, vzc.CAPTURE_TIME)
        if vz.progress[majority] >= vzc.CAPTURE_TIME then
            self:OnVictoryCapture(majority)
            return
        end
    end

    -- цвет кольца: контест > лидирующая команда > нейтральный
    local color = CONFIG.COLOR_NEUTRAL
    if red > 0 and red == black then
        color = CONFIG.COLOR_CONTEST
    elseif majority == TEAM_RED then
        color = CONFIG.COLOR_RED
    elseif majority == TEAM_BLACK then
        color = CONFIG.COLOR_BLACK
    end
    self:SetZoneRingColor(vz, color)
end

function ControlZones:OnVictoryCapture(team)
    -- как и таймаут, победа зоны ждёт окончания La Pucelle
    if _G.LaPucelleActivated then return end
    if _G.CurrentGameState ~= "FATE_ROUND_ONGOING" then return end
    local vz = self.vz
    vz.phase = "captured"
    self.stopped = true

    -- снять таймеры раунда, как это делает ветка полного истребления
    Timers:RemoveTimer('round_timer')
    Timers:RemoveTimer('round_30sec_alert')
    Timers:RemoveTimer('round_10sec_alert')
    Timers:RemoveTimer('presence_alert')
    if self.overtimeEnd then
        CreateUITimer("Overtime", 0, "overtime_timer")
        self.overtimeEnd = nil
        self.overtimeResolve = nil
    end

    self:SetZoneRingColor(vz, team == TEAM_RED and CONFIG.COLOR_RED or CONFIG.COLOR_BLACK)
    CenterMessage(TeamName(team) .. " has captured the control zone!", 5.0)
    self:PushState(true)
    self.GameMode:FinishRound(false, team == TEAM_RED and 0 or 1)
end

function ControlZones:ThinkBuffZones(now)
    local bzc = CONFIG.BUFF_ZONES
    for _, bz in ipairs(self.buffZones) do
        if bz.activateAt and now >= bz.activateAt then
            bz.active = true
            local counts = self:CountInZone(bz.pos, bz.radius)
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
            self:SetZoneRingColor(bz, color)
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

-- Вызывается из таймаута раунда. Если какая-то команда прямо сейчас
-- удерживает перевес в победной зоне — раунд продолжается до OVERTIME_MAX
-- секунд: либо захват завершится, либо перевес будет сбит (тогда
-- применяются старые правила таймаута через resolveFn).
function ControlZones:TryStartOvertime(resolveFn)
    if not self:IsEnabled() then return false end
    local ok, started = xpcall(function()
        return self:_TryStartOvertime(resolveFn)
    end, debug.traceback)
    if not ok then
        DisableOnError("TryStartOvertime", started)
        return false
    end
    return started
end

function ControlZones:_TryStartOvertime(resolveFn)
    local vz = self.vz
    if not vz or vz.phase ~= "active" then return false end

    local counts = self:CountInZone(vz.pos, vz.radius)
    if counts[TEAM_RED] == counts[TEAM_BLACK] then return false end

    local vzc = CONFIG.VICTORY_ZONE
    self.overtimeEnd = GameRules:GetGameTime() + vzc.OVERTIME_MAX
    self.overtimeResolve = resolveFn
    CreateUITimer("Overtime", vzc.OVERTIME_MAX, "overtime_timer")
    CenterMessage("OVERTIME!\nCapture the zone or force the enemy out!", 4.0)
    return true
end

function ControlZones:ThinkOvertime(now)
    if not self.overtimeEnd then return end
    local counts = self.vz and self.vz.counts or { [TEAM_RED] = 0, [TEAM_BLACK] = 0 }
    local noMajority = counts[TEAM_RED] == counts[TEAM_BLACK]
    if noMajority or now >= self.overtimeEnd then
        local resolve = self.overtimeResolve
        self.overtimeEnd = nil
        self.overtimeResolve = nil
        CreateUITimer("Overtime", 0, "overtime_timer")
        self.stopped = true
        if resolve then resolve() end
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
        victory.radius = vz.radius
        victory.grace_end = vz.graceEnd and math.floor(vz.graceEnd * 10) / 10 or 0
        victory.capture_time = vzc.CAPTURE_TIME
        victory.progress_red = math.floor(vz.progress[TEAM_RED] * 10) / 10
        victory.progress_black = math.floor(vz.progress[TEAM_BLACK] * 10) / 10
        victory.count_red = vz.counts[TEAM_RED]
        victory.count_black = vz.counts[TEAM_BLACK]
        victory.overtime = self.overtimeEnd and 1 or 0
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
    local ok, err = xpcall(function() self:_OnPlayerChat(keys) end, debug.traceback)
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
            GameRules:SendCustomMessage(string.format("[Zones] hero at: %.0f, %.0f, %.0f", p.x, p.y, p.z), 0, 0)
            print(string.format("[ControlZones] -zonepos: Vector(%.0f, %.0f, %.0f)", p.x, p.y, p.z))
        end
        return
    end

    if text == "-zoneinfo" then
        if self.vz then
            local vz = self.vz
            GameRules:SendCustomMessage(string.format(
                "[Zones] phase=%s pos=(%.0f, %.0f) red %.1f / black %.1f of %d (in zone %d/%d)",
                vz.phase, vz.pos.x, vz.pos.y,
                vz.progress[TEAM_RED], vz.progress[TEAM_BLACK], CONFIG.VICTORY_ZONE.CAPTURE_TIME,
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
        self.vz.ringColor = nil
        DestroyRing(self.vz.particle)
        self:SetZoneRingColor(self.vz, CONFIG.COLOR_NEUTRAL)
        RemoveMarkers(self.vz)
        self.vz.markers = SpawnMarkers(pos, MARKER_UNIT_VICTORY)
        GameRules:SendCustomMessage(string.format("[Zones] victory zone moved to %.0f, %.0f", pos.x, pos.y), 0, 0)
        self:PushState(true)
        return
    end

    local capValue = string.match(text, "^%-zonecap%s+(%d+)")
    if capValue and hero and self.vz then
        local team = hero:GetTeam()
        if self.vz.progress[team] then
            self.vz.progress[team] = math.min(tonumber(capValue), CONFIG.VICTORY_ZONE.CAPTURE_TIME)
            GameRules:SendCustomMessage(string.format("[Zones] %s progress set to %s", TeamName(team), capValue), 0, 0)
            self:PushState(true)
        end
        return
    end

    if text == "-zonegrace" and self.vz and self.vz.phase == "grace" then
        self.vz.graceEnd = GameRules:GetGameTime()
        GameRules:SendCustomMessage("[Zones] grace period skipped", 0, 0)
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

    -- показать все позиции-кандидаты кольцами на 10с: белый=center,
    -- жёлтый=tier1, красный=tier2, синий=пул бафф-зон
    if text == "-zoneshow" then
        local vzc = CONFIG.VICTORY_ZONE
        local poolColors = {
            center = Vector(255, 255, 255),
            tier1 = Vector(255, 200, 60),
            tier2 = Vector(255, 80, 80),
        }
        local shown = {}
        for poolName, pool in pairs(vzc.POSITIONS) do
            for i, def in ipairs(pool) do
                for _, fromRad in ipairs({ true, false }) do
                    local pos = ResolveZonePos(def, fromRad)
                    local key = math.floor(pos.x) .. ":" .. math.floor(pos.y)
                    if not shown[key] then
                        shown[key] = true
                        local ring = self:CreateRing(pos, vzc.RADIUS, poolColors[poolName])
                        Timers:CreateTimer(10, function() DestroyRing(ring) end)
                        print(string.format("[ControlZones] %s[%d]%s: %.0f, %.0f",
                            poolName, i, fromRad and "" or " (mirror)", pos.x, pos.y))
                    end
                end
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
            DestroyRing(bz.particle)
            self:SetZoneRingColor(bz, CONFIG.COLOR_NEUTRAL)
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
end)
