-- Ряд эффектов со стаками над хелсбаром юнита (panorama/scripts/custom_game/effect_bars.js).
--
-- Модификатор со стаками зовёт EffectBars:Track(self) в OnCreated и
-- EffectBars:Untrack(self) в OnDestroy (оба только на сервере). Сервер ведёт в
-- nettable effect_bars по записи на юнита: { on, vis, <доп. поля> }. Сами стаки
-- и оставшееся время панорама читает из баффов - так нет задержки сети.
--
-- vis = битовая маска команд, которые сейчас видят юнита (бит 2^team). Без неё
-- враги видели бы ряд в тумане на последней известной точке юнита (как было у
-- Reborn Распутина до PublishSeen). Маска, а не один флаг: в FFA команд много,
-- и «видит ли хоть кто-то из врагов» не отвечает, видит ли именно этот игрок.
--
-- Запись не удаляется, а выключается { on = 0 }: entindex переиспользуется,
-- следующий Track её перезапишет.

EffectBars = EffectBars or {}
EffectBars.units = EffectBars.units or {}

local NET_TABLE = "effect_bars"
local SEEN_THINK = 0.1


-- По одному герою на команду: CanEntityBeSeenByMyTeam отвечает за всю команду.
local function TeamViewers()
    local viewers = {}
    for _, hero in pairs(HeroList:GetAllHeroes()) do
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


function EffectBars:Publish(index, entry)
    local value = { on = 1, vis = entry.vis }

    for key, extra in pairs(entry.extra) do
        value[key] = extra
    end

    CustomNetTables:SetTableValue(NET_TABLE, tostring(index), value)
end


function EffectBars:Track(modifier)
    if not IsServer() then return end

    local unit = modifier:GetParent()

    if not IsNotNull(unit) then return end

    local index = unit:entindex()
    local entry = self.units[index]

    if not entry or entry.unit ~= unit then
        entry = { unit = unit, mods = {}, extra = {}, vis = VisMask(unit, TeamViewers()) }
        self.units[index] = entry
    end

    entry.mods[modifier:GetName()] = true

    self:Publish(index, entry)
    self:StartThink()
end


function EffectBars:Untrack(modifier)
    if not IsServer() then return end

    local unit = modifier:GetParent()

    if not IsNotNull(unit) then return end

    local index = unit:entindex()
    local entry = self.units[index]

    if not entry or entry.unit ~= unit then return end

    entry.mods[modifier:GetName()] = nil

    if next(entry.mods) ~= nil then return end

    self.units[index] = nil
    CustomNetTables:SetTableValue(NET_TABLE, tostring(index), { on = 0 })
end


-- Доп. данные, которых клиент сам не видит (например, взят ли атрибут у
-- владельца эффекта). Пишет в сеть только при изменении.
function EffectBars:SetExtra(unit, key, value)
    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    local index = unit:entindex()
    local entry = self.units[index]

    if not entry or entry.unit ~= unit then return end

    if entry.extra[key] == value then return end

    entry.extra[key] = value

    self:Publish(index, entry)
end


-- Разовый эффект на месте значка (взрыв стаков Ли на NSS). Шлём всем с маской
-- vis на момент события: панорама покажет его тем же, кому показала бы ряд
-- (своей команде, зрителям и врагам, видящим юнита). Стаки к этому моменту уже
-- сняты, поэтому маска считается здесь, а не берётся из записи.
-- caster - чей эффект взорвался: клиент фильтрует взрыв теми же
-- настройками, что и значки («только мои эффекты» и т.п.)
function EffectBars:Burst(unit, kind, caster)
    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    CustomGameEventManager:Send_ServerToAllClients("effect_bars_burst", {
        unit = unit:entindex(),
        kind = kind,
        caster = IsNotNull(caster) and caster:entindex() or -1,
        vis = VisMask(unit, TeamViewers()),
    })
end


function EffectBars:StartThink()
    if self.thinking then return end

    local gameMode = GameRules:GetGameModeEntity()

    if not gameMode then return end

    self.thinking = true

    gameMode:SetContextThink("EffectBarsSeenThink", function()
        return self:Think()
    end, SEEN_THINK)
end


function EffectBars:Think()
    local viewers = TeamViewers()

    for index, entry in pairs(self.units) do

        if not IsNotNull(entry.unit) then

            self.units[index] = nil
            CustomNetTables:SetTableValue(NET_TABLE, tostring(index), { on = 0 })

        else

            local vis = VisMask(entry.unit, viewers)

            if vis ~= entry.vis then
                entry.vis = vis
                self:Publish(index, entry)
            end

        end
    end

    if next(self.units) == nil then
        self.thinking = false
        return nil
    end

    return SEEN_THINK
end

