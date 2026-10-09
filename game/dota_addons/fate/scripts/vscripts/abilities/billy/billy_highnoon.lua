--[[ Highnoon (R) — ченнел до channel_time секунд.
     Направление фиксируется по точке каста. Каждые mark_interval секунд все враги в
     конусе (радиус radius, угол сужается от cone_start до cone_end) получают метку,
     первая — в момент каста. Ченнел заканчивается сам или любым приказом игрока
     («отпустил»): в момент релиза запоминаются помеченные внутри конуса, через
     fire_delay секунд по ним идёт очередь — по выстрелу каждые shot_interval, слева
     направо; цель пропускается, только если умерла или ушла дальше max_range.
     Каждый выстрел мгновенный — не доджится. Урон растёт с метками: одна метка = damage,
     все за полный ченнел = damage × max_mult.
     Сбит станом/сайленсом/хексом или смертью — выстрела нет.
     С включённой D каждый выстрел тратит bullet_cost пуль (пока хватает): цель
     замедляется на d_slow%, а d_pure_pct% урона выстрела идёт чистым вместо магического.
     Урон выстрелов — МАГИЧЕСКИЙ (юзер 09.10.2026; был физический).
     Хедшот (атрибут 3) ульта не копит и не критует.
     Метки (зарядка) — только на цели, видимые команде Билли: невидимок и туман ульта не берёт.
     Атрибуты: Different Approach — во время ченнела Protection from Arrows (тот же
     модификатор, что у Ку Хулина: пули и стрелы, проверяющие его, Билли не берут, плюс
     уворот от самонаводящихся), в радиусе radius вокруг Билли невидимки просвечиваются
     (modifier_billy_highnoon_reveal) — и тогда метятся; помеченные замедляются (сильнее
     с каждой меткой), каждый выстрел + da_agi_damage × ловкость;
     Natural Perception — во время ченнела −np_damage_reduction% входящего урона. ]]
require("abilities/billy/billy_shared")
require("libraries/effect_bars")

billy_highnoon = billy_highnoon or class({})
LinkLuaModifier("modifier_billy_highnoon_channel", "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_highnoon_slow",    "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_highnoon_d_slow",  "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_highnoon_firing",  "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_highnoon_charge",  "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_highnoon_reveal",  "abilities/billy/billy_highnoon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_protection_from_arrows_active", "abilities/cu_chulain/modifiers/modifier_protection_from_arrows_active", LUA_MODIFIER_MOTION_NONE)

function billy_highnoon:GetChannelTime()
    return self:GetSpecialValueFor("channel_time")
end

function billy_highnoon:MaxTicks()
    return math.floor(self:GetSpecialValueFor("channel_time") / self:GetSpecialValueFor("mark_interval") + 0.5)
end


function billy_highnoon:OnSpellStart()
    local caster = self:GetCaster()
    local dir = self:GetCursorPosition() - caster:GetAbsOrigin()
    dir.z = 0
    if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
    self.dir       = dir:Normalized()
    self.marks     = {}
    self.tick      = 0
    self.elapsed   = 0

    Billy_StartCancelGrace(caster, self)       -- первые cancel_grace с приказы не рвут ченнел
    self.chargeMod = caster:AddNewModifier(caster, self, "modifier_billy_highnoon_channel",
        { duration = self:GetChannelTime() + 0.1 })
    caster:EmitSound("billy_highnoon_start")    -- прокрутка барабана + взвод
    caster:EmitSound("billy_vo_highnoon_start")
    self:DestroyCone()                          -- прошлый конус, если ченнел перекастовали
    self.visionAt = 0
    self:UpdateCone(self:CurrentAngle())
    self:SeedVision(self:CurrentAngle(), BILLY_HIGHNOON_VISION.interval + 0.1)
    self:MarkTick()
end

function billy_highnoon:OnChannelThink(interval)
    self.elapsed = (self.elapsed or 0) + interval
    -- конус сужается плавно, каждый кадр; метки — по тикам mark_interval
    self:UpdateCone(self:CurrentAngle())
    -- зарядка в стаках модификатора ченнела: 0–100 %
    if IsNotNull(self.chargeMod) then
        self.chargeMod:SetStackCount(math.floor(math.min(self.elapsed / self:GetChannelTime(), 1) * 100))
    end
    if self.elapsed >= self.visionAt + BILLY_HIGHNOON_VISION.interval then
        self.visionAt = self.elapsed
        self:SeedVision(self:CurrentAngle(), BILLY_HIGHNOON_VISION.interval + 0.1)
    end
    local step = self:GetSpecialValueFor("mark_interval")
    while self.tick < self:MaxTicks() and self.elapsed >= (self.tick + 1) * step do
        self.tick = self.tick + 1
        self:MarkTick()
    end
end

function billy_highnoon:CurrentAngle()
    local progress = math.min((self.elapsed or 0) / self:GetChannelTime(), 1)
    local a0 = self:GetSpecialValueFor("cone_start")
    local a1 = self:GetSpecialValueFor("cone_end")
    return a0 + (a1 - a0) * progress
end

--[[ Индикатор конуса (юзер 09.10.2026: «улучшить по аналогии с комбо») — те же части, что
     у засады комбо (build_billy_standoff.py), но красные:
       пол    billy_standoff_floor — клин ульты Распутина (CP0/CP1 Билли, CP2 конец оси,
              CP3.x полуширина у края = длина · tan(угол/2), CP4 цвет, CP6.x 1) + плазма по оси;
       стенки billy_highnoon_wall ×2 вдоль краёв (CP1 → CP2, CP7 нормаль поперёк края,
              CP4 цвет, CP5 цвет кромок; искры красные);
       кромка billy_standoff_line по дальнему краю (CP1 → CP2, цвет CP5).
     Конус сужается каждый кадр ченнела — края (и нормали стенок) пересчитываются.
     Зона меток — ТОТ ЖЕ треугольник (InCone), чтобы видимое совпадало с попаданием.
     Видно всем, сквозь туман — врагам есть от чего уворачиваться. ]]
BILLY_HIGHNOON_FX = {
    floor       = "particles/billy/billy_standoff_floor.vpcf",
    wall        = "particles/billy/billy_highnoon_wall.vpcf",
    line        = "particles/billy/billy_standoff_edge.vpcf",   -- тёмная подложка + кромка
    floor_color = Vector(255, 40, 30),
    wall_color  = Vector(255, 90, 60),
    edge_color  = Vector(255, 235, 210),   -- почти белая: читается и поверх красных эффектов
}

function billy_highnoon:UpdateCone(angle)
    local F = BILLY_HIGHNOON_FX
    local origin = self:GetCaster():GetAbsOrigin()
    local length = self:GetSpecialValueFor("radius")
    local half = math.rad(angle / 2)
    local cone = self.cone
    if not cone then
        local function make(name)
            local fx = ParticleManager:CreateParticle(name, PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleShouldCheckFoW(fx, false)
            return fx
        end
        cone = { floor = make(F.floor), walls = { make(F.wall), make(F.wall) }, tip = make(F.line) }
        ParticleManager:SetParticleControl(cone.floor, 4, F.floor_color)
        ParticleManager:SetParticleControl(cone.floor, 6, Vector(1, 0, 0))
        for _, w in ipairs(cone.walls) do
            ParticleManager:SetParticleControl(w, 4, F.wall_color)
            ParticleManager:SetParticleControl(w, 5, F.edge_color)
        end
        ParticleManager:SetParticleControl(cone.tip, 5, F.edge_color)
        self.cone = cone
    end
    ParticleManager:SetParticleControl(cone.floor, 0, origin)
    ParticleManager:SetParticleControl(cone.floor, 1, origin)
    ParticleManager:SetParticleControl(cone.floor, 2, origin + self.dir * length)
    ParticleManager:SetParticleControl(cone.floor, 3, Vector(length * math.tan(half), 0, 0))
    local edgeLen = length / math.cos(half)
    local corners = {}
    for i, side in ipairs({ 1, -1 }) do
        local edge = Billy_RotateDir(self.dir, side * angle / 2)
        local w = cone.walls[i]
        corners[i] = origin + edge * edgeLen
        ParticleManager:SetParticleControl(w, 0, origin)
        ParticleManager:SetParticleControl(w, 1, origin)
        ParticleManager:SetParticleControl(w, 2, corners[i])
        -- нормаль стенки — горизонтально поперёк края: лента стоит вертикально
        ParticleManager:SetParticleControl(w, 7, Vector(-edge.y, edge.x, 0))
    end
    ParticleManager:SetParticleControl(cone.tip, 0, corners[1])
    ParticleManager:SetParticleControl(cone.tip, 1, corners[1])
    ParticleManager:SetParticleControl(cone.tip, 2, corners[2])
end

--[[ Обзор по клину — приём конуса Баргеста (barghest_vision_cone): треугольник
     засевается FOW-вьюверами по сетке step в осях dir/вбок, радиус вьювера
     0.75·step (круги на квадратной сетке закрывают её без дыр). Вьюверы без
     препятствий — Билли видит весь клин поверх деревьев и обрывов. ]]
BILLY_HIGHNOON_VISION = {
    step     = 250,
    interval = 0.2,   -- пересев; вьювер живёт interval + 0.1, чтобы не мигал
}

function billy_highnoon:SeedVision(angle, life)
    local caster = self:GetCaster()
    local team   = caster:GetTeamNumber()
    local origin = caster:GetAbsOrigin()
    local length = self:GetSpecialValueFor("radius")
    local right  = Vector(self.dir.y, -self.dir.x, 0)
    local tan    = math.tan(math.rad(angle / 2))
    local step   = BILLY_HIGHNOON_VISION.step
    local r      = step * 0.75
    local x = 0
    while x <= length do
        local half = x * tan
        local y = 0
        while y <= half + step * 0.5 do
            AddFOWViewer(team, origin + self.dir * x + right * y, r, life, false)
            if y > 0 then
                AddFOWViewer(team, origin + self.dir * x - right * y, r, life, false)
            end
            y = y + step
        end
        x = x + step
    end
end

-- Частицы тают (endcap ~0.15–0.3 с), а не обрываются.
function billy_highnoon:DestroyCone()
    local cone = self.cone
    if not cone then return end
    self.cone = nil
    local all = { cone.floor, cone.tip, cone.walls[1], cone.walls[2] }
    for _, fx in ipairs(all) do
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end
end

-- Треугольник индикатора: вперёд не дальше длины, вбок не дальше forward · tan(угол/2).
function billy_highnoon:InCone(unit, origin, angle)
    local to = unit:GetAbsOrigin() - origin
    to.z = 0
    local forward = to:Dot(self.dir)
    if forward < 0 or forward > self:GetSpecialValueFor("radius") then return false end
    local side = math.abs(to.x * self.dir.y - to.y * self.dir.x)
    return side <= forward * math.tan(math.rad(angle / 2)) + unit:GetHullRadius()
end

function billy_highnoon:MarkTick()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local angle = self:CurrentAngle()
    local length = self:GetSpecialValueFor("radius")
    -- поиск с запасом: дальний угол треугольника лежит на length / cos(угол/2)
    local search = length / math.max(math.cos(math.rad(angle / 2)), 0.05)
    local units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, search,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    -- Different Approach: невидимки в радиусе ульты просвечиваются (до следующего тика
    -- с запасом) — со следующего тика они видны и метятся как все
    if Billy_HasAttr(caster, 4) then
        local reveal = self:GetSpecialValueFor("mark_interval") * 2 + 0.1
        for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, length,
            DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
            FIND_ANY_ORDER, false)) do
            u:AddNewModifier(caster, self, "modifier_billy_highnoon_reveal", { duration = reveal })
        end
    end
    for _, u in ipairs(units) do
        -- заряжается только о видимых команде Билли (не в инвизе, не в тумане)
        if self:InCone(u, origin, angle) and caster:CanEntityBeSeenByMyTeam(u) then
            local idx = u:entindex()
            local mark = self.marks[idx]
            if not mark then
                mark = { unit = u, stacks = 0 }
                mark.fx = ParticleManager:CreateParticle(BILLY_FX.mark, PATTACH_OVERHEAD_FOLLOW, u)
                self.marks[idx] = mark
            end
            mark.stacks = math.min(mark.stacks + 1, self:MaxTicks() + 1)
            self:UpdateChargeChip(mark)
        end
    end

    -- Different Approach: помеченные в радиусе замедляются, тем сильнее, чем больше меток
    if Billy_HasAttr(caster, 4) then
        for _, mark in pairs(self.marks) do
            local u = mark.unit
            if IsNotNull(u) and u:IsAlive() and not IsImmuneToSlow(u)
                and (u:GetAbsOrigin() - origin):Length2D() <= search then
                local m = u:AddNewModifier(caster, self, "modifier_billy_highnoon_slow",
                    { duration = self:GetSpecialValueFor("mark_interval") * 3 })
                if m then m:SetStackCount(mark.stacks) end
            end
        end
    end
end

--[[ Значок над целью (panorama effect_bars.js, id billy): зарядка залпа по ней,
     0–100 % — та же доля, что множитель урона, (метки − 1) / все тики. Модификатор
     висит с запасом по времени и снимается вместе с меткой (ClearMarks / залп). ]]
function billy_highnoon:UpdateChargeChip(mark)
    local u = mark.unit
    if not IsNotNull(u) or not u:IsAlive() then return end
    if not IsNotNull(mark.mod) then
        mark.mod = u:AddNewModifier(self:GetCaster(), self, "modifier_billy_highnoon_charge",
            { duration = self:GetChannelTime() + self:GetSpecialValueFor("fire_delay") + 1 })
    end
    if IsNotNull(mark.mod) then
        mark.mod:SetStackCount(math.floor((mark.stacks - 1) / math.max(self:MaxTicks(), 1) * 100 + 0.5))
    end
end

local function Billy_DropMarkChip(mark)
    if IsNotNull(mark.mod) then mark.mod:Destroy() end
    mark.mod = nil
end

-- снять с цели значок зарядки и прицел
local function Billy_DropMark(mark)
    Billy_DropMarkChip(mark)
    if mark.fx then
        ParticleManager:DestroyParticle(mark.fx, false)
        ParticleManager:ReleaseParticleIndex(mark.fx)
        mark.fx = nil
    end
end

function billy_highnoon:ClearMarks()
    for _, mark in pairs(self.marks or {}) do
        Billy_DropMark(mark)
    end
    self.marks = {}
end

function billy_highnoon:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    caster.billyGraceUntil = nil
    caster:RemoveModifierByName("modifier_billy_highnoon_channel")

    -- сбили: стан/сайленс/хекс/смерть — залпа нет. Любой другой обрыв = «отпустил».
    if bInterrupted and (not caster:IsAlive() or caster:IsStunned() or caster:IsSilenced() or caster:IsHexed()) then
        caster:StopSound("billy_vo_highnoon_start")
        caster:StopSound("billy_highnoon_start")
        self:DestroyCone()
        self:ClearMarks()
        return
    end
    -- полный ченнел: последний тик мог не успеть в OnChannelThink
    if not bInterrupted then
        while self.tick < self:MaxTicks() do
            self.tick = self.tick + 1
            self:MarkTick()
        end
    end
    -- конус убирать ПОСЛЕ догоняющих тиков: MarkTick рисует его заново (в игре оставался висеть)
    self:DestroyCone()

    -- конус на момент релиза: список целей фиксируется СЕЙЧАС — помеченные внутри него.
    -- Дальше по ним стреляют по очереди, даже если вышли из конуса, пока не дальше max_range.
    local releaseAngle = self:CurrentAngle()
    local origin = caster:GetAbsOrigin()
    local queue = {}
    for _, mark in pairs(self.marks or {}) do
        local u = mark.unit
        if IsNotNull(u) and u:IsAlive() and self:InCone(u, origin, releaseAngle) then
            local to = u:GetAbsOrigin() - origin
            mark.side = to.x * self.dir.y - to.y * self.dir.x
            table.insert(queue, mark)
        else
            Billy_DropMark(mark)
        end
    end
    self.marks = {}
    -- очередь веером: слева направо поперёк конуса
    table.sort(queue, function(a, b) return a.side > b.side end)

    local fireDelay = self:GetSpecialValueFor("fire_delay")
    local interval  = self:GetSpecialValueFor("shot_interval")
    local volleyEnd = fireDelay + interval * math.max(#queue - 1, 0)

    -- до выстрела Билли стоит: приказ, которым «отпустили» ченнел, гасится; на время
    -- анимации выстрела (fire_anim_time) и всей очереди — рут/дизарм/запрет приказов.
    -- Анимация — атака: отдача у неё на 0.25–0.29 с, ровно к залпу через fire_delay (0.25).
    caster:Stop()
    caster:AddNewModifier(caster, self, "modifier_billy_highnoon_firing",
        { duration = math.max(self:GetSpecialValueFor("fire_anim_time"), volleyEnd) })
    -- клин остаётся видимым до залпа и чуть после — видно, в кого попало
    self:SeedVision(releaseAngle, volleyEnd + 0.5)
    local ability = self

    local base      = self:GetSpecialValueFor("damage")
    local mult      = self:GetSpecialValueFor("max_mult")
    local maxTicks  = self:MaxTicks()
    local maxRange  = self:GetSpecialValueFor("max_range")
    local cost      = self:GetSpecialValueFor("bullet_cost")
    local dPure     = self:GetSpecialValueFor("d_pure_pct") / 100
    local dSlowTime = self:GetSpecialValueFor("d_slow_duration")
    local agiMult   = Billy_HasAttr(caster, 4) and self:GetSpecialValueFor("da_agi_damage") or 0

    local function DropQueue(from)
        for i = from, #queue do Billy_DropMark(queue[i]) end
    end

    local i = 0
    Timers:CreateTimer(fireDelay, function()
        i = i + 1
        local alive = IsNotNull(caster) and caster:IsAlive() and IsNotNull(ability)
        if not alive then
            DropQueue(i)
            return
        end
        if i == 1 then
            caster:StopSound("billy_vo_highnoon_start")
            caster:StopSound("billy_highnoon_start")
            caster:EmitSound("billy_vo_highnoon_fire")
            caster:EmitSound("billy_highnoon_fire")    -- три выстрела «веером курка» + эхо
        end
        local mark = queue[i]
        if not mark then return end
        Billy_DropMark(mark)
        local u = mark.unit
        local inRange = IsNotNull(u) and u:IsAlive()
            and (u:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= maxRange
        if inRange and Billy_ArrowProof(u) then
            -- Protection from Arrows: выстрел виден, но пуля не берёт — ни урона, ни слоу, пуля D цела
            Billy_FxTracer(caster, u, ability, false)
        elseif inRange then
            -- Different Approach: + da_agi_damage × ловкость к каждому выстрелу (не множится метками)
            local damage = base * (1 + (mult - 1) * (mark.stacks - 1) / maxTicks)
                + caster:GetAgility() * agiMult
            -- под D каждый выстрел тратит свою пулю (юзер 08.10.2026): кончились — дальше без усиления
            local empowered = Billy_TrySpend(caster, cost)
            -- выстрел мгновенный (не доджится) — и визуально: луч от дула до цели
            Billy_FxTracer(caster, u, ability, empowered)
            -- урон магический (юзер 09.10.2026); под D: d_pure_pct% урона выстрела идёт чистым вместо магического, и замедление
            if empowered then
                if not IsImmuneToSlow(u) then
                    u:AddNewModifier(caster, ability, "modifier_billy_highnoon_d_slow", { duration = dSlowTime })
                end
                Billy_Damage(caster, u, damage * (1 - dPure), DAMAGE_TYPE_MAGICAL, ability)
                if IsNotNull(u) and u:IsAlive() then
                    DoDamage(caster, u, damage * dPure, DAMAGE_TYPE_PURE, 0, ability, false)
                end
            else
                Billy_Damage(caster, u, damage, DAMAGE_TYPE_MAGICAL, ability)
            end
        end
        if i < #queue then return interval end
    end)
end


---------------------------------------------------------------------------------------------------
-- Висит на Билли на время ченнела: атрибуты Different Approach и Natural Perception.
-- Стаки = зарядка ульты 0–100 % по времени ченнела (ставит OnChannelThink); значки
-- над врагами — modifier_billy_highnoon_charge.
modifier_billy_highnoon_channel = modifier_billy_highnoon_channel or class({})

function modifier_billy_highnoon_channel:IsHidden()      return false end
function modifier_billy_highnoon_channel:IsDebuff()      return false end
function modifier_billy_highnoon_channel:IsPurgable()    return false end
function modifier_billy_highnoon_channel:RemoveOnDeath() return true end

function modifier_billy_highnoon_channel:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_billy_highnoon_channel:GetModifierIncomingDamage_Percentage()
    if Billy_HasAttr(self:GetParent(), 5) then
        return -self:GetAbility():GetSpecialValueFor("np_damage_reduction")
    end
    return 0
end

function modifier_billy_highnoon_channel:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    -- Different Approach: «на время Highnoon не действуют проджектайлы» — Protection from
    -- Arrows Ку Хулина (silent — без его звуков, как у рывка Распутина): её проверяют
    -- почти все снаряды аддона, а сама она каждые 0.033 с уворачивает самонаводящиеся.
    -- Диспел снимает её, как и у Ку, — заново не вешаем.
    if Billy_HasAttr(parent, 4) then
        self.arrows = parent:AddNewModifier(parent, self:GetAbility(), "modifier_protection_from_arrows_active",
            { duration = self:GetAbility():GetChannelTime() + 0.1, silent = 1 })
    end
end

function modifier_billy_highnoon_channel:OnDestroy()
    if not IsServer() then return end
    if IsNotNull(self.arrows) then self.arrows:Destroy() end
end

---------------------------------------------------------------------------------------------------
-- Зарядка залпа по цели (стаки 0–100 %) — круглый значок над её хелсбаром.
modifier_billy_highnoon_charge = modifier_billy_highnoon_charge or class({})

function modifier_billy_highnoon_charge:IsHidden()      return false end
function modifier_billy_highnoon_charge:IsDebuff()      return true end
function modifier_billy_highnoon_charge:IsPurgable()    return false end
function modifier_billy_highnoon_charge:RemoveOnDeath() return true end

function modifier_billy_highnoon_charge:OnCreated()
    if IsServer() then EffectBars:Track(self) end
end

function modifier_billy_highnoon_charge:OnDestroy()
    if IsServer() then EffectBars:Untrack(self) end
end

---------------------------------------------------------------------------------------------------
-- Замедление Different Approach: стаки = метки цели.
modifier_billy_highnoon_slow = modifier_billy_highnoon_slow or class({})

function modifier_billy_highnoon_slow:IsHidden()   return false end
function modifier_billy_highnoon_slow:IsDebuff()   return true end
function modifier_billy_highnoon_slow:IsPurgable() return true end

function modifier_billy_highnoon_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_billy_highnoon_slow:GetModifierMoveSpeedBonus_Percentage()
    local ab = self:GetAbility()
    if not ab then return 0 end
    local lo = ab:GetSpecialValueFor("da_slow_min")
    local hi = ab:GetSpecialValueFor("da_slow_max")
    local maxTicks = math.max(ab:MaxTicks(), 1)
    local t = math.min(math.max(self:GetStackCount() - 1, 0) / maxTicks, 1)
    return -(lo + (hi - lo) * t)
end

---------------------------------------------------------------------------------------------------
-- Выстрел под D: замедление на d_slow_duration.
modifier_billy_highnoon_d_slow = modifier_billy_highnoon_d_slow or class({})

function modifier_billy_highnoon_d_slow:IsHidden()   return false end
function modifier_billy_highnoon_d_slow:IsDebuff()   return true end
function modifier_billy_highnoon_d_slow:IsPurgable() return true end

function modifier_billy_highnoon_d_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_billy_highnoon_d_slow:GetModifierMoveSpeedBonus_Percentage()
    local ab = self:GetAbility()
    return ab and -ab:GetSpecialValueFor("d_slow") or 0
end

---------------------------------------------------------------------------------------------------
-- Между концом ченнела и залпом (fire_delay): стоит на месте, приказы не принимает.
modifier_billy_highnoon_firing = modifier_billy_highnoon_firing or class({})

function modifier_billy_highnoon_firing:IsHidden()      return true end
function modifier_billy_highnoon_firing:IsPurgable()    return false end
function modifier_billy_highnoon_firing:RemoveOnDeath() return true end

function modifier_billy_highnoon_firing:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]             = true,
        [MODIFIER_STATE_DISARMED]           = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_billy_highnoon_firing:DeclareFunctions()
    return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end
-- анимация выстрела (Billy_attack) с начала: без override её перебивал idle/бег
function modifier_billy_highnoon_firing:GetOverrideAnimation()     return ACT_DOTA_ATTACK end
function modifier_billy_highnoon_firing:GetOverrideAnimationRate() return 1.0 end

---------------------------------------------------------------------------------------------------
-- Different Approach: невидимка в радиусе ульты просвечивается (как стан Артурии —
-- состояние «невидим» снято поверх его инвиза). Обновляется каждым тиком меток.
modifier_billy_highnoon_reveal = modifier_billy_highnoon_reveal or class({})

function modifier_billy_highnoon_reveal:IsHidden()   return true end
function modifier_billy_highnoon_reveal:IsDebuff()   return true end
function modifier_billy_highnoon_reveal:IsPurgable() return false end
function modifier_billy_highnoon_reveal:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_billy_highnoon_reveal:CheckState()
    return { [MODIFIER_STATE_INVISIBLE] = false }
end
