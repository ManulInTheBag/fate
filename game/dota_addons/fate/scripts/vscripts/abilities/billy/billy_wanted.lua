--[[ Young Outlaw Leader (атрибут 1 Билли) — «награда за голову».
     В начале раунда (весь пре-раунд + wanted_pick_time секунд боя) Билли кликом по
     портрету врага в топ-баре назначает цель. Это видят все: у цели в топ-баре висит
     плакат WANTED (shared_scoreboard_updater.js читает "sync"/"billy_wanted").
     Пока Билли ближе wanted_sense_radius к цели, раз в wanted_sense_interval он
     «чует» её — прицел над ней сквозь туман, виден только ему (как метки пассивки
     JTR, jtr_bloody_thirst); мгновенно — по Presence Resonator Мастера. Ассасинов
     (GetServantClass) пассивно не чует — только по резонатору (юзер 08.10.2026).
     Убийство цели при участии Билли (добил или ассист): Билли получает
     wanted_gold_billy, остальные участники — wanted_gold; Билли и союзники в wanted_reward_radius от него — барьер
     wanted_barrier (modifier_barrier_new) и +wanted_ms% скорости на
     wanted_reward_duration. Атрибут куплен уже после пре-раунда — цель сразу
     случайная. FFA (раундов нет): цель случайная при покупке атрибута и заново
     после каждого возрождения Билли (modifier_billy_wanted_sense:OnRespawn). Цель снята — в СЛЕДУЮЩЕМ раунде можно выбрать новую;
     пока не снята, остаётся и в следующих раундах.

     Числа — в KV billy_bullets_to_spare (D, всегда на герое), у атрибута копия
     для тултипа. Хуки: addon_game_mode.lua (InitializeRound → Billy_OnPreRound,
     OnEntityKilled → Billy_OnHeroKilled), master_presence_resonator.lua →
     Billy_WantedPing, billy_attributes.lua → Billy_WantedOnAcquire.
     Подключается require из billy_shared — грузится и в клиентской VM, поэтому
     серверное (события, нет-таблица) — только под IsServer(). ]]

LinkLuaModifier("modifier_billy_wanted_sense",  "abilities/billy/billy_wanted", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_wanted_reward", "abilities/billy/billy_wanted", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barrier_new", "modifiers/modifier_barrier_new", LUA_MODIFIER_MOTION_NONE)

-- hunters[playerID Билли] = { target = playerID цели или -1, claimed = bool, pick_end = время }
BILLY_WANTED = BILLY_WANTED or { hunters = {}, window_end = -1 }

-- метка цели в тумане — знак Track у Bounty Hunter («за голову назначена награда»;
-- юзер 08.10.2026: прицел R не подходит). Копия дерева лежит в аддоне (слот Хассана),
-- дети целы; CP0 — точка над головой, гаснет штатным endcap-затуханием.
BILLY_WANTED_PING_FX = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf"
-- линия от Билли к метке: ширина ленты и цвет (аддитивный — тусклее = прозрачнее)
BILLY_WANTED_LINE = {
    width = 10,
    color = Vector(150, 115, 50),   -- приглушённое золото плаката WANTED
}
BILLY_WANTED_SND_PICK  = "billy_d_on"           -- взвод курка: цель назначена
BILLY_WANTED_SND_CLAIM = "billy_highnoon_fire"   -- выстрел: голова получена

local function Val(hero, key, default)
    local d = hero and Billy_GetD(hero)
    if not d then return default end
    return d:GetSpecialValueFor(key)
end

local function IsHunter(hero)
    return IsNotNull(hero) and hero:IsRealHero() and Billy_GetD(hero) ~= nil and Billy_HasAttr(hero, 1)
end

local function Entry(pid)
    local e = BILLY_WANTED.hunters[pid]
    if not e then
        e = { target = -1, claimed = false, pick_end = -1 }
        BILLY_WANTED.hunters[pid] = e
    end
    return e
end

-- Состояние для панорамы: топ-бар (плакат у цели, клики для выбора) и billy_hud (подсказка).
function Billy_WantedSync()
    if not IsServer() then return end
    local out = { hunters = {} }
    for pid, e in pairs(BILLY_WANTED.hunters) do
        local hero = PlayerResource:GetSelectedHeroEntity(pid)
        out.hunters[tostring(pid)] = {
            target   = e.target,
            claimed  = e.claimed and 1 or 0,
            pick_end = e.pick_end,
            team     = hero and hero:GetTeamNumber() or -1,
        }
        out.gold = Val(hero, "wanted_gold_billy", 0)   -- на плакате — награда самого Билли
    end
    CustomNetTables:SetTableValue("sync", "billy_wanted", out)
end

-- Открыть выбор, если цели нет или прошлая уже снята. Живую цель не трогаем.
local function OpenPick(hero)
    local e = Entry(hero:GetPlayerOwnerID())
    if e.target ~= -1 and not e.claimed then return end
    e.target, e.claimed = -1, false
    e.pick_end = BILLY_WANTED.window_end
end

-- Пре-раунд: окно выбора = весь пре-раунд + wanted_pick_time секунд после старта боя.
function Billy_OnPreRound(round)
    local pre = PRE_ROUND_DURATION or 12
    local heroes = HeroList:GetAllHeroes()
    local pickTime = 15
    for _, hero in pairs(heroes) do
        if IsHunter(hero) then pickTime = Val(hero, "wanted_pick_time", pickTime) end
    end
    BILLY_WANTED.window_end = GameRules:GetGameTime() + pre + pickTime
    for _, hero in pairs(heroes) do
        if IsHunter(hero) then OpenPick(hero) end
    end
    Billy_WantedSync()
end

-- Конец раунда (FinishRound): невыбранное окно закрываем — раунд мог кончиться раньше
-- wanted_pick_time, и выбор в пост-раунде переехал бы в следующий раунд.
function Billy_OnRoundEnd()
    local changed = false
    for _, e in pairs(BILLY_WANTED.hunters) do
        if e.target == -1 and e.pick_end ~= -1 then
            e.pick_end, changed = -1, true
        end
    end
    BILLY_WANTED.window_end = -1
    if changed then Billy_WantedSync() end
end

-- Годится ли tpid в цель: враг Билли с выбранным Слугой (не форс-пик Wisp).
local function ValidTarget(hero, tpid)
    local target = tpid and PlayerResource:IsValidPlayerID(tpid) and PlayerResource:GetSelectedHeroEntity(tpid)
    if not IsNotNull(target) or target:GetTeamNumber() == hero:GetTeamNumber() then return nil end
    if target:GetName() == "npc_dota_hero_wisp" then return nil end
    return target
end

local function SetTarget(hero, e, tpid, target, random)
    e.target, e.claimed, e.pick_end = tpid, false, -1
    Billy_WantedSync()
    EmitGlobalSound(BILLY_WANTED_SND_PICK)
    GameRules:SendCustomMessage("<font color='#E0B060'>WANTED: DEAD OR ALIVE!</font> <font color='#58ACFA'>"
        .. FindName(hero:GetName()) .. "</font> put a bounty on <font color='#FF5050'>"
        .. FindName(target:GetName()) .. "</font>" .. (random and " (chosen at random)" or "") .. "!", 0, 0)
end

-- Случайная цель из врагов (атрибут куплен, когда пре-раунд уже прошёл; FFA — ещё и
-- каждое возрождение). Прежнюю цель не повторяем, если есть кто-то ещё.
local function PickRandom(hero, e)
    local pool, prev = {}, nil
    for tpid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        local target = ValidTarget(hero, tpid)
        if target then
            if tpid == e.target then prev = { tpid, target } else table.insert(pool, { tpid, target }) end
        end
    end
    if #pool == 0 and prev then pool = { prev } end
    if #pool == 0 then return end
    local c = pool[RandomInt(1, #pool)]
    SetTarget(hero, e, c[1], c[2], true)
end

-- FFA: раундов нет (InitializeRound не зовётся, _G.IsPreRound так и висит true).
local function IsFFA()
    return _G.GameMap == "fate_ffa"
end

function Billy_WantedRandomize(hero)
    PickRandom(hero, Entry(hero:GetPlayerOwnerID()))
end

-- Атрибут куплен: чутьё на герое. FFA — сразу случайная цель. Иначе в пре-раунде —
-- ручной выбор (окно открыто); если бой раунда уже идёт (пре-раунд прошёл) — сразу
-- случайная цель (юзер 08.10.2026). В пре-гейме/после раунда ничего: выбор откроет
-- ближайший Billy_OnPreRound.
function Billy_WantedOnAcquire(hero)
    if not IsServer() or not IsNotNull(hero) then return end
    if not hero:HasModifier("modifier_billy_wanted_sense") then
        hero:AddNewModifier(hero, Billy_GetD(hero), "modifier_billy_wanted_sense", {})
    end
    local e = Entry(hero:GetPlayerOwnerID())
    if e.target == -1 or e.claimed then
        if IsFFA() then
            -- мёртвому — не сейчас: цель всё равно сменит возрождение (OnRespawn)
            if hero:IsAlive() then PickRandom(hero, e) end
        elseif _G.CurrentGameState == "FATE_ROUND_ONGOING" and not _G.IsPreRound then
            PickRandom(hero, e)
        elseif _G.IsPreRound and GameRules:GetGameTime() < BILLY_WANTED.window_end then
            OpenPick(hero)
        end
    end
    Billy_WantedSync()
end

-- Клик по портрету в топ-баре (shared_scoreboard_updater.js → "billy_wanted_pick").
function Billy_WantedPick(args)
    local pid = args.PlayerID
    local hero = pid and PlayerResource:GetSelectedHeroEntity(pid)
    if not IsHunter(hero) then return end
    local e = Entry(pid)
    if e.target ~= -1 and not e.claimed then return end          -- цель уже назначена
    if GameRules:GetGameTime() > e.pick_end then return end        -- окно закрыто
    local tpid = tonumber(args.target)
    local target = ValidTarget(hero, tpid)
    if not target then return end
    SetTarget(hero, e, tpid, target, false)
end

if IsServer() and not BILLY_WANTED_LISTENER then
    -- через глобал: после script_reload слушатель зовёт уже новую функцию
    BILLY_WANTED_LISTENER = CustomGameEventManager:RegisterListener("billy_wanted_pick", function(_, args)
        Billy_WantedPick(args)
    end)
end

-- Цель Билли, если она назначена и не снята.
local function ActiveTarget(hero)
    local e = BILLY_WANTED.hunters[hero:GetPlayerOwnerID()]
    if not e or e.target == -1 or e.claimed then return nil end
    local target = PlayerResource:GetSelectedHeroEntity(e.target)
    return IsNotNull(target) and target or nil
end

-- «Чутьё»: короткая вспышка знака Track над целью сквозь туман, только игроку Билли.
-- Цель дальше wanted_sense_radius, мертва или и так видна команде Билли — ничего
-- (юзер 08.10.2026: метка нужна, только когда цель вне обзора). Зовётся раз в wanted_sense_interval
-- (modifier_billy_wanted_sense) и мгновенно из Presence Resonator (resonator = true).
-- Ассасина пассивное чутьё не видит — только резонатор.
function Billy_WantedPing(hero, resonator)
    if not IsServer() or not IsHunter(hero) or not hero:IsAlive() then return end
    local target = ActiveTarget(hero)
    if not target or not target:IsAlive() then return end
    if not resonator and GetServantClass(target) == "Assassin" then return end
    local radius = Val(hero, "wanted_sense_radius", 2000)
    if (target:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() > radius then return end
    if hero:CanEntityBeSeenByMyTeam(target) then return end
    local player = hero:GetPlayerOwner()
    if not player then return end

    local fx = ParticleManager:CreateParticleForPlayer(BILLY_WANTED_PING_FX, PATTACH_WORLDORIGIN, nil, player)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    -- над головой, как у настоящего Track (там PATTACH_OVERHEAD_FOLLOW, а цель в тумане
    -- клиенту не видна — ставим точкой мира на высоту хелсбара)
    local height = target.GetBaseHealthBarOffset and target:GetBaseHealthBarOffset() or 0
    if not height or height <= 0 then height = 200 end
    local spot = target:GetAbsOrigin()
    ParticleManager:SetParticleControl(fx, 0, spot + Vector(0, 0, height))

    -- линия от Билли к месту метки (юзер 09.10.2026: «куда в тумане смотреть») — та же
    -- лента-клин, что у R, узкой полосой; тусклый цвет = полупрозрачная (рендер аддитивный).
    -- Начало едет за Билли, конец — точка, где цель была в момент пинга.
    local L = BILLY_WANTED_LINE
    local line = ParticleManager:CreateParticleForPlayer(BILLY_FX.cone, PATTACH_WORLDORIGIN, nil, player)
    ParticleManager:SetParticleShouldCheckFoW(line, false)
    ParticleManager:SetParticleControl(line, 2, spot)
    ParticleManager:SetParticleControl(line, 3, Vector(L.width, L.width, 0))
    ParticleManager:SetParticleControl(line, 4, L.color)
    ParticleManager:SetParticleControl(line, 6, Vector(1, 0, 0))

    -- новый пинг (резонатор поверх пассивного) гасит прежний — линии не складываются в яркость
    local ping = { fx = fx, line = line }
    if hero.billyWantedPing then hero.billyWantedPing.done() end
    ping.done = function()
        if ping.over then return end
        ping.over = true
        if hero.billyWantedPing == ping then hero.billyWantedPing = nil end
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
        ParticleManager:DestroyParticle(line, false)
        ParticleManager:ReleaseParticleIndex(line)
    end
    hero.billyWantedPing = ping

    -- пассивное чутьё — wanted_sense_show, по резонатору — дольше: wanted_sense_show_resonator
    local show = resonator and Val(hero, "wanted_sense_show_resonator", 3) or Val(hero, "wanted_sense_show", 2)
    local expire = GameRules:GetGameTime() + show
    Timers:CreateTimer(0, function()
        if ping.over then return end
        if not IsNotNull(hero) or GameRules:GetGameTime() >= expire then
            ping.done()
            return
        end
        local origin = hero:GetAbsOrigin()
        ParticleManager:SetParticleControl(line, 0, origin)
        ParticleManager:SetParticleControl(line, 1, origin)
        return FrameTime()
    end)
end

-- Убийство героя врагом (addon_game_mode OnEntityKilled, ветка не-тимкилла).
-- assisters — герои-ассистенты (без добившего).
function Billy_OnHeroKilled(victim, killer, assisters)
    if not IsNotNull(victim) or not IsNotNull(killer) then return end
    local vpid = victim:GetPlayerOwnerID()
    for pid, e in pairs(BILLY_WANTED.hunters) do
        if e.target == vpid and not e.claimed then
            local hunter = PlayerResource:GetSelectedHeroEntity(pid)
            if IsNotNull(hunter) then
                local participants = { killer }
                for _, a in ipairs(assisters or {}) do table.insert(participants, a) end
                local took = false
                for _, p in ipairs(participants) do
                    if p == hunter then took = true end
                end
                if took then Billy_WantedClaim(hunter, e, victim, participants) end
            end
        end
    end
end

function Billy_WantedClaim(hunter, e, victim, participants)
    e.claimed = true
    Billy_WantedSync()

    -- золото участникам (как Track у Bounty Hunter), с всплывашкой: Билли больше
    local goldBilly = Val(hunter, "wanted_gold_billy", 0)
    local goldOther = Val(hunter, "wanted_gold", 0)
    local paid = {}
    for _, p in ipairs(participants) do
        if IsNotNull(p) and p:IsRealHero() and not paid[p] and p:GetTeamNumber() == hunter:GetTeamNumber() then
            paid[p] = true
            local gold = p == hunter and goldBilly or goldOther
            p:ModifyGold(gold, false, 0)
            local owner = p:GetPlayerOwner()
            if owner then
                local popup = ParticleManager:CreateParticleForPlayer("particles/custom/system/gold_popup.vpcf",
                    PATTACH_CUSTOMORIGIN, nil, owner)
                ParticleManager:SetParticleControl(popup, 0, victim:GetAbsOrigin())
                ParticleManager:SetParticleControl(popup, 1, Vector(10, gold, 0))
                ParticleManager:SetParticleControl(popup, 2, Vector(3, #tostring(gold) + 1, 0))
                ParticleManager:SetParticleControl(popup, 3, Vector(255, 200, 33))
                ParticleManager:ReleaseParticleIndex(popup)
            end
        end
    end

    -- барьер и скорость Билли и союзникам рядом с ним
    local d = Billy_GetD(hunter)
    local duration = Val(hunter, "wanted_reward_duration", 10)
    local allies = FindUnitsInRadius(hunter:GetTeamNumber(), hunter:GetAbsOrigin(), nil,
        Val(hunter, "wanted_reward_radius", 1500), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _, ally in pairs(allies) do
        if IsNotNull(ally) and ally:IsRealHero() and ally:IsAlive() then
            ally:AddNewModifier(hunter, d, "modifier_barrier_new", {
                duration = duration, shield_amount = Val(hunter, "wanted_barrier", 600),
                beforeBScroll = true, ShouldEndChannel = false, decreaseDamageOnProck = 0, HasCounter = false,
            })
            ally:AddNewModifier(hunter, d, "modifier_billy_wanted_reward", { duration = duration })
        end
    end

    EmitGlobalSound(BILLY_WANTED_SND_CLAIM)
    GameRules:SendCustomMessage("<font color='#E0B060'>BOUNTY CLAIMED!</font> <font color='#58ACFA'>"
        .. FindName(hunter:GetName()) .. "</font> got the head of <font color='#FF5050'>"
        .. FindName(victim:GetName()) .. "</font>: <font color='#FFFF66'>" .. goldBilly
        .. "</font> gold to Billy, <font color='#FFFF66'>" .. goldOther .. "</font> to everyone else who took part!", 0, 0)
end

---------------------------------------------------------------------------------------------------
-- Чутьё: раз в wanted_sense_interval пинг цели (Billy_WantedPing сам проверит радиус).
-- На FFA ещё и новая случайная цель после каждого возрождения Билли (прежняя —
-- снятая или нет — заменяется).
modifier_billy_wanted_sense = modifier_billy_wanted_sense or class({})

function modifier_billy_wanted_sense:IsHidden()      return true end
function modifier_billy_wanted_sense:IsPurgable()    return false end
function modifier_billy_wanted_sense:RemoveOnDeath() return false end
function modifier_billy_wanted_sense:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_billy_wanted_sense:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(Val(self:GetParent(), "wanted_sense_interval", 5))
end

function modifier_billy_wanted_sense:OnIntervalThink()
    Billy_WantedPing(self:GetParent())
end

function modifier_billy_wanted_sense:DeclareFunctions()
    return { MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_billy_wanted_sense:OnRespawn(args)
    if not IsServer() or not IsFFA() then return end
    local hero = self:GetParent()
    if args.unit ~= hero or not IsHunter(hero) then return end
    Billy_WantedRandomize(hero)
end

---------------------------------------------------------------------------------------------------
-- Награда за голову: +wanted_ms% скорости (барьер — отдельный modifier_barrier_new).
modifier_billy_wanted_reward = modifier_billy_wanted_reward or class({})

function modifier_billy_wanted_reward:IsHidden()   return false end
function modifier_billy_wanted_reward:IsDebuff()   return false end
function modifier_billy_wanted_reward:IsPurgable() return true end
function modifier_billy_wanted_reward:GetTexture() return "custom/billy/billy_attribute_1" end

function modifier_billy_wanted_reward:OnCreated()
    local ability = self:GetAbility()
    self.ms = ability and ability:GetSpecialValueFor("wanted_ms") or 0
end

function modifier_billy_wanted_reward:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_billy_wanted_reward:GetModifierMoveSpeedBonus_Percentage() return self.ms end
