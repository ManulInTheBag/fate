-- Значок «переживёт смертельный удар» справа от хелсбара героя
-- (panorama/scripts/custom_game/effect_bars.js, SURVIVAL_*).
--
-- Battle Continuation и похожие пассивки: Кухулин, Кухулин Альтер, Король
-- Хассан, Хиджиката, Мордред, Лю Бу, Робин, Гавейн, God Hand Геракла,
-- Ланселот, Арквейд, Protection of Faith Влада. Распутина нет - у него своя
-- полоска Reborn (rasputin_hud).
--
-- Есть ли эффект, решают флаги атрибутов на герое - клиент их не видит, -
-- поэтому состояние считает сервер. В nettable survival_icons по записи на
-- entindex героя: { on, vis, kind, cd_end, cd_len, act_end, act_len, spent }.
-- Время - абсолютное игровое, клиент сам ведёт отсчёт, так что запись
-- меняется только при срабатывании, а не каждый тик.
--
-- vis - та же маска видимости командами, что и в effect_bars.lua.

SurvivalIcons = SurvivalIcons or {}
SurvivalIcons.sent = SurvivalIcons.sent or {}

local NET_TABLE = "survival_icons"
local THINK = 0.1


-- Оставшееся время и длительность модификатора; nil - его нет.
local function ModifierTime(hero, name)
    local modifier = hero:FindModifierByName(name)
    if not modifier then return nil end

    local remaining = modifier:GetRemainingTime()
    if remaining <= 0 then return nil end

    return remaining, math.max(modifier:GetDuration(), remaining)
end


-- Оставшаяся перезарядка способности и её полная длина; nil - готова.
local function AbilityTime(hero, name)
    local ability = hero:FindAbilityByName(name)
    if not ability then return nil end

    local remaining = ability:GetCooldownTimeRemaining()
    if remaining <= 0 then return nil end

    local length = ability:GetSpecialValueFor("cooldown")
    if not (length > 0) then
        length = ability:GetEffectiveCooldown(math.max(ability:GetLevel() - 1, 0))
    end

    return remaining, math.max(length, remaining)
end


local function Learned(hero, name)
    local ability = hero:FindAbilityByName(name)
    return ability ~= nil and ability:GetLevel() > 0
end


-- has: есть ли эффект сейчас; cd: перезарядка; active: бафф после
-- срабатывания, пока он идёт (кольцо времени на значке); spent: заряд
-- израсходован без отсчёта (значок погашен до нового заряда).
local KINDS = {
    {
        kind = "cu",
        has = function(hero) return Learned(hero, "cu_chulain_battle_continuation") end,
        cd = function(hero) return AbilityTime(hero, "cu_chulain_battle_continuation") end,
        active = function(hero) return ModifierTime(hero, "modifier_battle_cont_active") end,
    },
    {
        kind = "cu_alter",
        has = function(hero) return hero.CuAlterAttr4Acquired == true end,
        cd = function(hero) return ModifierTime(hero, "modifier_cu_alter_battle_cont_cd") end,
    },
    {
        kind = "khsn",
        has = function(hero) return hero.BattleContinuationAcquired == true and Learned(hero, "khsn_bc") end,
        cd = function(hero) return ModifierTime(hero, "modifier_khsn_bc_cooldown") end,
    },
    {
        kind = "hijikata",
        has = function(hero) return hero.IsHijikataBcAcquired == true and hero:HasModifier("modifier_hijikata_bc") end,
        cd = function(hero) return ModifierTime(hero, "modifier_hijikata_bc_cooldown") end,
    },
    {
        kind = "mordred",
        has = function(hero) return hero:HasModifier("modifier_mordred_bc") end,
        cd = function(hero) return ModifierTime(hero, "modifier_mordred_bc_cooldown") end,
    },
    {
        kind = "lu_bu",
        has = function(hero) return hero:HasModifier("modifier_lu_bu_restless_soul") end,
        cd = function(hero) return ModifierTime(hero, "modifier_lu_bu_restless_soul_cooldown") end,
    },
    {
        kind = "robin",
        has = function(hero) return hero:HasModifier("modifier_robin_faceless_king") end,
        cd = function(hero) return ModifierTime(hero, "modifier_robin_faceless_king_cooldown") end,
    },
    {
        kind = "gawain",
        has = function(hero) return hero:HasModifier("modifier_gawain_revive") end,
        cd = function(hero) return AbilityTime(hero, "gawain_blessing_of_fairy") end,
    },
    {
        -- God Hand без перезарядки: заряд на раунд (modifier_god_hand_stock
        -- снимается при воскрешении, выдаётся в InitializeRound) - после
        -- воскрешения значок погашен до следующего раунда
        kind = "heracles",
        has = function(hero) return Learned(hero, "berserker_5th_god_hand") end,
        spent = function(hero) return not hero:HasModifier("modifier_god_hand_stock") end,
    },
    {
        kind = "lancelot",
        has = function(hero) return Learned(hero, "lancelot_blessing_of_fairy") end,
        cd = function(hero) return ModifierTime(hero, "modifier_blessing_of_fairy_cooldown") end,
        active = function(hero) return ModifierTime(hero, "modifier_fairy_magic_immunity") end,
    },
    {
        kind = "arcueid",
        has = function(hero) return hero.RegenAcquired == true and Learned(hero, "arcueid_regen") end,
        cd = function(hero) return ModifierTime(hero, "modifier_arcueid_barrier_cooldown") end,
        active = function(hero) return ModifierTime(hero, "modifier_arcueid_what_barrier") end,
    },
    {
        kind = "vlad",
        has = function(hero) return hero:HasModifier("modifier_protection_of_faith") end,
        cd = function(hero) return ModifierTime(hero, "modifier_protection_of_faith_proc_cd") end,
        active = function(hero) return ModifierTime(hero, "modifier_protection_of_faith_proc") end,
    },
}


local function TeamViewers(heroes)
    local viewers = {}
    for _, hero in pairs(heroes) do
        if IsNotNull(hero) then
            local team = hero:GetTeamNumber()
            if not viewers[team] then
                viewers[team] = hero
            end
        end
    end
    return viewers
end


local function VisMask(unit, viewers)
    local mask = 0
    for team, hero in pairs(viewers) do
        if hero:CanEntityBeSeenByMyTeam(unit) then
            mask = mask + 2 ^ team
        end
    end
    return mask
end


-- Время до 0.1 с: так запись не дёргается от погрешности тиков.
local function Round(value)
    return math.floor(value * 10 + 0.5) / 10
end


local function State(hero, now)
    if not hero:IsAlive() or hero:IsIllusion() or not hero:IsRealHero() then
        return nil
    end

    for _, def in ipairs(KINDS) do
        if def.has(hero) then
            local value = { on = 1, kind = def.kind, cd_end = 0, cd_len = 0, act_end = 0, act_len = 0, spent = 0 }
            if def.spent and def.spent(hero) then value.spent = 1 end

            local remaining, length = nil, nil
            if def.cd then remaining, length = def.cd(hero) end
            if remaining then
                value.cd_end = Round(now + remaining)
                value.cd_len = Round(length)
            end

            if def.active then remaining, length = def.active(hero) else remaining = nil end
            if remaining then
                value.act_end = Round(now + remaining)
                value.act_len = Round(length)
            end

            return value
        end
    end

    return nil
end


local function Same(a, b)
    if a == nil or b == nil then return a == b end
    return a.kind == b.kind and a.vis == b.vis
        and a.cd_end == b.cd_end and a.act_end == b.act_end and a.spent == b.spent
end


function SurvivalIcons:Think()
    local now = GameRules:GetGameTime()
    local heroes = HeroList:GetAllHeroes()
    local viewers = TeamViewers(heroes)
    local seen = {}

    for _, hero in pairs(heroes) do
        if IsNotNull(hero) then
            local key = tostring(hero:entindex())
            local value = State(hero, now)

            if value then
                value.vis = VisMask(hero, viewers)
                seen[key] = true
            end

            if not Same(value, self.sent[key]) then
                self.sent[key] = value
                CustomNetTables:SetTableValue(NET_TABLE, key, value or { on = 0 })
            end
        end
    end

    -- герой пропал из списка (вышел, пересоздан) - выключаем его запись
    for key, value in pairs(self.sent) do
        if value and not seen[key] and not EntIndexToHScript(tonumber(key)) then
            self.sent[key] = nil
            CustomNetTables:SetTableValue(NET_TABLE, key, { on = 0 })
        end
    end

    return THINK
end


function SurvivalIcons:Start()
    if self.thinking then return end

    local gameMode = GameRules:GetGameModeEntity()

    if not gameMode then return end

    self.thinking = true

    gameMode:SetContextThink("SurvivalIconsThink", function()
        local ok, result = pcall(function() return self:Think() end)
        if not ok then
            print("[SurvivalIcons] " .. tostring(result))
        end
        return THINK
    end, THINK)
end
