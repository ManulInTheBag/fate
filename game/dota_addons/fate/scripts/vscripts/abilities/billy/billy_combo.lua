--[[ Combo: Thunderer: Thunderbolt of Broken Sound (Q → R) — фантазм Билли из FGO.
     Окно открывает Trickshot (Q) с автокастом при 30/30/30 — на 3 с Highnoon (R)
     меняется на это комбо (modifier_billy_combo_switch в billy_trickshot.lua).

     Засада (переделка 08.10.2026, юзер): после замаха AbilityCastPoint Билли встаёт в
     стойку на channel_time секунд, любой его приказ её отменяет. Стойка — НЕ ченнел, а
     modifier_billy_combo_stance (юзер 09.10.2026: комбо не сбивается оглушением — ченнел
     движок рвёт станом сам): стан и сайленс стойку не снимают, только приказ или смерть. На земле лежит
     конус (cone_angle, направление — по точке каста): за grow_time секунд он дорастает от
     Билли до range. Если враг-герой ВНУТРИ конуса нажмёт любую способность (не предмет),
     комбо срабатывает (и на невидимого — засада ловит каст, а не взгляд): Билли бьёт в него shots пуль через shot_delay — самонаводящиеся,
     не уворачиваемые, чужое тело их не перекрывает. Каждая пуля: shot_damage урона +
     оглушение stun_duration + метка на mark_duration — обзор по цели, −mark_slow%
     скорости, +mark_damage_amp% входящего урона и пулевые дырки на теле (до трёх).
     Пули комбо пробивают неуязвимость и Protection from Arrows (юзер 09.10.2026) — в
     отличие от остальных пуль Билли, Billy_ArrowProof тут не проверяется.
     Не дождался (время вышло / отменил / сбили) — выстрела нет, КД потрачен.

     Конус НЕ такой, как у R (красный клин): электрически-синий пол + две вертикальные
     стенки по краям с разрядами + кромка по дальнему краю (particles/billy/
     build_billy_standoff.py). Виден всем — враги должны понимать, где нельзя колдовать. ]]
require("abilities/billy/billy_shared")

billy_combo = billy_combo or class({})
LinkLuaModifier("modifier_billy_combo_cd",     "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_combo_aura",   "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_combo_stance", "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_combo_mark",   "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_combo_slow",   "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_combo_firing", "abilities/billy/billy_combo", LUA_MODIFIER_MOTION_NONE)

BILLY_COMBO_FX = {
    -- в стойке: бушующая энергия вокруг Билли — вихрь Windranger Arcana в синей гамме
    -- (build_billy_combo_aura.py), aura_layers копий друг на друге — гуще; свечения модели
    -- больше нет (юзер 08.10.2026). CP0 — Билли.
    aura        = "particles/billy/billy_combo_aura.vpcf",
    aura_layers = 2,
    wind        = "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf",           -- ветер вокруг
    dust        = "particles/units/heroes/hero_brewmaster/brewmaster_storm_ambient_dust.vpcf", -- пыль вокруг
    -- на каждом выстреле: кольца разряда Zinogre перед Билли (CP0/CP1 Билли, forward CP1 —
    -- на цель; кольца встают на 200 впереди на высоте 120)
    shot_ring   = "particles/billy/billy_combo_ring_burst.vpcf",
    -- дырки на цели (CP0): _1/_2/_3 — одна, две, три; каждая пуля подменяет спрайт на
    -- следующий (старые дырки на тех же местах), он выскакивает как impact frame
    mark        = "particles/billy/billy_combo_mark_%d.vpcf",
    mark_max    = 3,
    -- конус засады (build_billy_standoff.py). Пол: CP0/CP1 Билли, CP2 конец оси, CP3.x
    -- полуширина у края, CP4 цвет, CP6.x 1. Стенка: CP1 → CP2 вдоль края, CP4 цвет стенки,
    -- CP5 цвет кромок, CP7 нормаль (горизонтально поперёк края). Линия: CP1 → CP2, цвет CP5.
    floor       = "particles/billy/billy_standoff_floor.vpcf",
    wall        = "particles/billy/billy_standoff_wall.vpcf",
    line        = "particles/billy/billy_standoff_edge.vpcf",   -- тёмная подложка + кромка
    floor_color = Vector(20, 105, 255),
    wall_color  = Vector(60, 165, 255),
    edge_color  = Vector(170, 228, 255),
    -- срабатывание: конус вспыхивает белым и тает, к цели — линия-«захват» и прицел над ней
    flash_color = Vector(255, 255, 255),
    flash_time  = 0.12,
    snap_color  = Vector(190, 235, 255),
    snap_width  = 14,
    snap_life   = 0.35,
    -- обзор Билли по конусу (как у R): сетка вьюверов step, пересев каждые interval
    vision_step     = 250,
    vision_interval = 0.2,
    -- на каждом попадании маленький взрыв (CP0); кровь — BILLY_FX.blood.l в Billy_FxImpact
    blast       = "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf",
}

function billy_combo:StanceTime()
    return self:GetSpecialValueFor("channel_time")
end

function billy_combo:ComboDir()
    local caster = self:GetCaster()
    local dir = self:GetCursorPosition() - caster:GetAbsOrigin()
    dir.z = 0
    if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
    return dir:Normalized()
end

-- Голос (на всю карту): на замахе быстрое 「喰らいな！」, на выстреле 「ファイア！！」.
function billy_combo:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    EmitGlobalSound("billy_vo_combo_start")
    if IsServer() then caster:EmitSound("billy_combo_cock") end    -- прокрутка барабана + взвод
    caster:AddNewModifier(caster, self, "modifier_billy_combo_aura",
        { duration = self:GetCastPoint() + self:StanceTime() + 0.3 })
    return true
end

function billy_combo:OnAbilityPhaseInterrupted()
    StopGlobalSound("billy_vo_combo_start")
    self:GetCaster():StopSound("billy_combo_cock")
    self:GetCaster():RemoveModifierByName("modifier_billy_combo_aura")
end

function billy_combo:OnSpellStart()
    local caster = self:GetCaster()
    self.dir     = self:ComboDir()
    self.elapsed = 0
    self.armed   = true       -- ждём каст врага; сработало / закончилось — false
    self.target  = nil
    self.visionAt = 0

    -- окно комбо (подмена R) не должно закрыться посреди стойки и очереди: SwapAbilities
    -- спрятал бы способность посреди засады. Держим его до конца, снимаем сами (ReleaseSwitch).
    local switch = caster:FindModifierByName("modifier_billy_combo_switch")
    if switch then switch:SetDuration(self:StanceTime() + 3, true) end

    Billy_StartCancelGrace(caster, self)       -- первые cancel_grace с приказы не снимают стойку
    caster:AddNewModifier(caster, self, "modifier_billy_combo_stance", { duration = self:StanceTime() })
    self:CreateCone()
    self:SeedVision(BILLY_COMBO_FX.vision_interval + 0.1)

    -- КД: зеркалим на копию у Мастера (как у остальных комбо) + видимая иконка
    local cd = self:GetCooldown(self:GetLevel())
    local masterCombo = caster.MasterUnit2 and caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    if masterCombo then
        masterCombo:EndCooldown()
        masterCombo:StartCooldown(cd)
    end
    caster:AddNewModifier(caster, self, "modifier_billy_combo_cd", { duration = cd })
end

-- Каждый кадр стойки (modifier_billy_combo_stance:OnIntervalThink).
function billy_combo:StanceThink(interval)
    self.elapsed = (self.elapsed or 0) + interval
    self:UpdateCone()
    local F = BILLY_COMBO_FX
    if self.elapsed >= (self.visionAt or 0) + F.vision_interval then
        self.visionAt = self.elapsed
        self:SeedVision(F.vision_interval + 0.1)
    end
end

-- Враг внутри нажал способность (зовёт modifier_billy_combo_stance). Стойку снимаем на
-- следующем кадре, а не прямо из события чужого каста; выстрел — в EndStance.
function billy_combo:Trigger(unit)
    if not self.armed then return end
    self.armed  = false
    self.target = unit
    local caster = self:GetCaster()
    Timers:CreateTimer(0, function()
        if not IsNotNull(caster) then return end
        caster:RemoveModifierByName("modifier_billy_combo_stance")
    end)
end

-- Конец стойки (её OnDestroy): сработала засада, вышло время, приказ Билли или смерть.
function billy_combo:EndStance()
    local caster = self:GetCaster()
    caster.billyGraceUntil = nil
    caster:RemoveModifierByName("modifier_billy_combo_aura")
    self.armed = false
    local target = self.target
    self.target = nil

    -- Сработавшая засада стреляет, даже если тот же каст сразу оглушил Билли: у мгновенных
    -- способностей нажатие и стан приходят в один кадр, а Билли «успел первым».
    -- Без срабатывания (время вышло, приказ, смерть) — выстрела нет.
    local canFire = IsNotNull(target) and target:IsAlive() and caster:IsAlive()
    if not canFire then
        caster:StopSound("billy_combo_cock")
        self:DestroyCone(false)
        self:ReleaseSwitch(0)
        -- однокадровая combo_hold зациклена: на всякий случай перезапускаем базовую
        -- активность и здесь (после стойки, со следующего кадра)
        Timers:CreateTimer(0, function()
            if IsNotNull(caster) then Billy_RefreshAnim(caster) end
        end)
        return
    end
    self:FlashCone()
    -- стойку могли снять прямо внутри чужого каста — свои модификаторы и снаряды
    -- создаём уже на следующем кадре, не изнутри этой цепочки
    Timers:CreateTimer(0, function()
        if not IsNotNull(self) or not IsNotNull(caster) or not caster:IsAlive() then return end
        if not IsNotNull(target) or not target:IsAlive() then return end
        self:Fire(target)
    end)
end

-- Окно комбо закрываем сами — через delay секунд (после очереди).
function billy_combo:ReleaseSwitch(delay)
    local caster = self:GetCaster()
    Timers:CreateTimer(delay, function()
        if IsNotNull(caster) then caster:RemoveModifierByName("modifier_billy_combo_switch") end
    end)
end

---------------------------------------------------------------------------------------------------
-- Конус засады

function billy_combo:HalfAngle()
    return math.rad(self:GetSpecialValueFor("cone_angle") / 2)
end

-- Длина сейчас: за grow_time от начала стойки — от нуля до range.
function billy_combo:ConeLength()
    local range = self:GetSpecialValueFor("range")
    local grow  = self:GetSpecialValueFor("grow_time")
    local frac  = grow > 0 and math.min((self.elapsed or 0) / grow, 1) or 1
    return math.max(range * frac, 1)
end

-- Треугольник индикатора: вперёд не дальше текущей длины, вбок — не дальше края.
function billy_combo:InCone(unit)
    if not self.dir then return false end
    local to = unit:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()
    to.z = 0
    local forward = to:Dot(self.dir)
    if forward < 0 or forward > self:ConeLength() then return false end
    local side = math.abs(to.x * self.dir.y - to.y * self.dir.x)
    return side <= forward * math.tan(self:HalfAngle()) + unit:GetHullRadius()
end

function billy_combo:CreateCone()
    self:DestroyCone(true)
    local F = BILLY_COMBO_FX
    local function make(name)
        local fx = ParticleManager:CreateParticle(name, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleShouldCheckFoW(fx, false)      -- видна всем, сквозь туман
        return fx
    end
    local cone = { floor = make(F.floor), walls = {}, tip = make(F.line) }
    local halfDeg = self:GetSpecialValueFor("cone_angle") / 2
    for i, side in ipairs({ 1, -1 }) do
        local edge = Billy_RotateDir(self.dir, side * halfDeg)
        local fx = make(F.wall)
        -- нормаль стенки — горизонтально поперёк края: лента встаёт вертикально
        ParticleManager:SetParticleControl(fx, 7, Vector(-edge.y, edge.x, 0))
        cone.walls[i] = { fx = fx, dir = edge }
    end
    ParticleManager:SetParticleControl(cone.floor, 6, Vector(1, 0, 0))
    self.cone = cone
    self:SetConeColors(F.floor_color, F.wall_color, F.edge_color)
    self:UpdateCone()
end

function billy_combo:SetConeColors(floor, wall, edge)
    local cone = self.cone
    if not cone then return end
    ParticleManager:SetParticleControl(cone.floor, 4, floor)
    for _, w in ipairs(cone.walls) do
        ParticleManager:SetParticleControl(w.fx, 4, wall)
        ParticleManager:SetParticleControl(w.fx, 5, edge)
    end
    ParticleManager:SetParticleControl(cone.tip, 5, edge)
end

function billy_combo:UpdateCone()
    local cone = self.cone
    if not cone then return end
    local origin  = self:GetCaster():GetAbsOrigin()
    local length  = self:ConeLength()
    local half    = self:HalfAngle()
    local edgeLen = length / math.cos(half)
    ParticleManager:SetParticleControl(cone.floor, 0, origin)
    ParticleManager:SetParticleControl(cone.floor, 1, origin)
    ParticleManager:SetParticleControl(cone.floor, 2, origin + self.dir * length)
    ParticleManager:SetParticleControl(cone.floor, 3, Vector(length * math.tan(half), 0, 0))
    local corners = {}
    for i, w in ipairs(cone.walls) do
        corners[i] = origin + w.dir * edgeLen
        ParticleManager:SetParticleControl(w.fx, 0, origin)
        ParticleManager:SetParticleControl(w.fx, 1, origin)
        ParticleManager:SetParticleControl(w.fx, 2, corners[i])
    end
    ParticleManager:SetParticleControl(cone.tip, 0, corners[1])
    ParticleManager:SetParticleControl(cone.tip, 1, corners[1])
    ParticleManager:SetParticleControl(cone.tip, 2, corners[2])
end

-- immediate = false: частицы тают (endcap ~0.15–0.3 с)
function billy_combo:DestroyCone(immediate)
    local cone = self.cone
    if not cone then return end
    self.cone = nil
    local all = { cone.floor, cone.tip }
    for _, w in ipairs(cone.walls) do table.insert(all, w.fx) end
    for _, fx in ipairs(all) do
        ParticleManager:DestroyParticle(fx, immediate)
        ParticleManager:ReleaseParticleIndex(fx)
    end
end

-- Сработало: весь конус на flash_time вспыхивает белым и тает.
function billy_combo:FlashCone()
    local F = BILLY_COMBO_FX
    self:SetConeColors(F.flash_color, F.flash_color, F.flash_color)
    local cone = self.cone
    Timers:CreateTimer(F.flash_time, function()
        if IsNotNull(self) and self.cone == cone then self:DestroyCone(false) end
    end)
end

--[[ Обзор по клину — как у R (billy_highnoon:SeedVision): треугольник засевается
     FOW-вьюверами по сетке step, радиус 0.75·step, без препятствий. ]]
function billy_combo:SeedVision(life)
    local caster = self:GetCaster()
    local team   = caster:GetTeamNumber()
    local origin = caster:GetAbsOrigin()
    local length = self:ConeLength()
    local right  = Vector(self.dir.y, -self.dir.x, 0)
    local tan    = math.tan(self:HalfAngle())
    local step   = BILLY_COMBO_FX.vision_step
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

---------------------------------------------------------------------------------------------------
-- Очередь в цель

function billy_combo:Fire(target)
    local caster = self:GetCaster()
    local F = BILLY_COMBO_FX
    self.volleyHit = {}     -- кто уже словил пулю этого залпа: эффекты попадания — один раз на цель

    local shots = math.max(self:GetSpecialValueFor("shots"), 1)
    local delay = self:GetSpecialValueFor("shot_delay")
    local volley = (shots - 1) * delay
    local speed = self:GetSpecialValueFor("speed")
    -- анимация выстрела (Billy_attack, отдача на ~0.25 с при скорости 1) ускорена до
    -- fire_anim_rate — отдача приходится ровно на первую пулю через fire_delay
    local fireDelay = self:GetSpecialValueFor("fire_delay")

    -- Билли на очередь стоит: рут, дизарм, приказы закрыты; сразу разворачивается к цели
    caster:Stop()
    local face = target:GetAbsOrigin() - caster:GetAbsOrigin()
    face.z = 0
    if face:Length2D() > 1 then caster:SetForwardVector(face:Normalized()) end
    caster:AddNewModifier(caster, self, "modifier_billy_combo_firing",
        { duration = fireDelay + volley + 0.25, rate = self:GetSpecialValueFor("fire_anim_rate") })
    self:FxSnap(target, fireDelay + volley)
    -- цель видна команде Билли до конца очереди (метка потом держит обзор сама)
    AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), 300, fireDelay + volley + 0.5, false)
    self:ReleaseSwitch(fireDelay + volley + 0.1)

    local fired = 0
    local function Shoot()
        if not IsNotNull(self) or not IsNotNull(caster) or not caster:IsAlive() then return end
        if not IsNotNull(target) or not target:IsAlive() then return end
        -- реальность здесь НЕ проверяем (юзер 09.10.2026): засада уже сработала — очередь
        -- догоняет цель и в другом мире
        fired = fired + 1
        if fired == 1 then
            caster:EmitSound("billy_combo_fire")      -- очередь из трёх выстрелов через 0.1 с + раскат грома
            EmitGlobalSound("billy_vo_combo_fire")    -- 「ファイア！！」 на выстреле, на всю карту
        end
        self:ShootAt(target, speed)
        if fired < shots then return delay end
    end
    Timers:CreateTimer(fireDelay, Shoot)
end

-- Одна пуля: самонаводящийся снаряд без эффекта и без уворота (bDodgeable false) — бьёт
-- только цель, перекрыть его другим телом нельзя. Рисуем пулю комбо сами — прямой от дула
-- в грудь цели со скоростью снаряда (как у автоатаки, Billy_AttackBulletFx).
function billy_combo:ShootAt(target, speed)
    local caster = self:GetCaster()
    local face = target:GetAbsOrigin() - caster:GetAbsOrigin()
    face.z = 0
    if face:Length2D() > 1 then caster:SetForwardVector(face:Normalized()) end   -- стоит в руте

    local from = Billy_GunOrigin(caster)
    local delta = Billy_HitPos(target) - from
    local len = delta:Length()
    Billy_FxMuzzle(caster, delta)
    self:FxShotRing(face)
    local token
    if len > 1 then
        token = Billy_BulletFx(BILLY_FX.combo_shot, from, delta * (speed / len), len / speed,
            BILLY_FX.combo_shot_trail)
    end
    ProjectileManager:CreateTrackingProjectile({
        Target            = target,
        Source            = caster,
        Ability           = self,
        EffectName        = "",
        iMoveSpeed        = speed,
        vSourceLoc        = from,
        bDodgeable        = false,
        bIsAttack         = false,
        bProvidesVision   = true,
        iVisionRadius     = BILLY_BULLET_VISION,
        iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData         = { bfx = token },
    })
end

-- Кольца разряда перед Билли по направлению выстрела (копия Zinogre powershot burst).
function billy_combo:FxShotRing(dir)
    local caster = self:GetCaster()
    local flat = Vector(dir.x, dir.y, 0)
    flat = flat:Length2D() > 0.01 and flat:Normalized() or caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local fx = ParticleManager:CreateParticle(BILLY_COMBO_FX.shot_ring, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleControl(fx, 0, origin)
    ParticleManager:SetParticleControl(fx, 1, origin)
    ParticleManager:SetParticleControlForward(fx, 1, flat)
    ParticleManager:ReleaseParticleIndex(fx)
end

-- Захват цели: короткая линия от Билли к ней (тот же клин-лента, что у R, узкой полосой)
-- и прицел над головой до конца очереди.
function billy_combo:FxSnap(target, volley)
    local F = BILLY_COMBO_FX
    local origin = self:GetCaster():GetAbsOrigin()
    local line = ParticleManager:CreateParticle(BILLY_FX.cone, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(line, false)
    ParticleManager:SetParticleControl(line, 0, origin)
    ParticleManager:SetParticleControl(line, 1, origin)
    ParticleManager:SetParticleControl(line, 2, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(line, 3, Vector(F.snap_width, F.snap_width, 0))
    ParticleManager:SetParticleControl(line, 4, F.snap_color)
    ParticleManager:SetParticleControl(line, 6, Vector(1, 0, 0))
    local cross = ParticleManager:CreateParticle(BILLY_FX.mark, PATTACH_OVERHEAD_FOLLOW, target)
    Timers:CreateTimer(F.snap_life, function()
        ParticleManager:DestroyParticle(line, false)
        ParticleManager:ReleaseParticleIndex(line)
    end)
    Timers:CreateTimer(volley + 0.4, function()
        ParticleManager:DestroyParticle(cross, false)
        ParticleManager:ReleaseParticleIndex(cross)
    end)
end

-- Каждая пуля: урон, оглушение и метка (обновляются). Метка вешается ПОСЛЕ урона:
-- усиление действует со второй пули.
function billy_combo:OnProjectileHit_ExtraData(target, location, data)
    Billy_BulletEnd(data.bfx, target)
    if not target or not IsNotNull(target) or not target:IsAlive() then return true end
    -- Protection from Arrows комбо НЕ доджит (юзер 09.10.2026): Billy_ArrowProof здесь
    -- НАМЕРЕННО нет, в отличие от остальных пуль Билли. Снаряд ещё и bDodgeable = false —
    -- ProjectileDodge, которым модификатор защиты снимает снаряды, его тоже не трогает.
    local caster = self:GetCaster()
    -- вылетевшая пуля бьёт и в другой реальности (юзер 09.10.2026) — проверка только на засаде
    target:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
    -- если в цель вошли несколько пуль — искры, кровь и взрыв только от первой
    local hit = self.volleyHit or {}
    self.volleyHit = hit
    if not hit[target:entindex()] then
        hit[target:entindex()] = true
        Billy_FxImpact(target, "l", caster:GetAbsOrigin())   -- искры, пыль и кровь «много»
        self:FxHit(target)
    end
    -- пули комбо пробивают неуязвимость (юзер 09.10.2026)
    Billy_Damage(caster, target, self:GetSpecialValueFor("shot_damage"), self:GetAbilityDamageType(), self,
        DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY)
    if IsNotNull(target) and target:IsAlive() then
        local duration = self:GetSpecialValueFor("mark_duration")
        local mark = target:AddNewModifier(caster, self, "modifier_billy_combo_mark", { duration = duration })
        if mark then mark:AddHole() end
        if not IsImmuneToSlow(target) then
            target:AddNewModifier(caster, self, "modifier_billy_combo_slow", { duration = duration })
        end
    end
    return true
end

-- Маленький взрыв в точке попадания (кровь — в Billy_FxImpact, размер "l").
function billy_combo:FxHit(target)
    local F = BILLY_COMBO_FX
    local blast = ParticleManager:CreateParticle(F.blast, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(blast, false)
    ParticleManager:SetParticleControl(blast, 0, Billy_HitPos(target))
    ParticleManager:ReleaseParticleIndex(blast)
end

---------------------------------------------------------------------------------------------------
modifier_billy_combo_cd = modifier_billy_combo_cd or class({})

function modifier_billy_combo_cd:GetTexture()    return "custom/billy/billy_combo" end
function modifier_billy_combo_cd:IsHidden()      return false end
function modifier_billy_combo_cd:IsDebuff()      return true end
function modifier_billy_combo_cd:IsPurgable()    return false end
function modifier_billy_combo_cd:RemoveOnDeath() return false end
function modifier_billy_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

---------------------------------------------------------------------------------------------------
-- Стойка: пока висит (ченнел), слушает касты ВСЕХ юнитов (события способностей
-- глобальные — как клетка Озимандии) и ловит врага-героя в конусе.
-- Ловим и начало каста (замах), и исполнение — у мгновенных способностей замаха нет.
modifier_billy_combo_stance = modifier_billy_combo_stance or class({})

function modifier_billy_combo_stance:IsHidden()      return true end
function modifier_billy_combo_stance:IsPurgable()    return false end
function modifier_billy_combo_stance:RemoveOnDeath() return true end

-- Стоит как в ченнеле: поза combo_hold жестом (ACT_DOTA_CHANNEL_ABILITY_7 — не
-- override, см. modifier_billy_combo_firing), без автоатак (дизарм) — сам не двинется.
function modifier_billy_combo_stance:CheckState()
    return { [MODIFIER_STATE_DISARMED] = true }
end

function modifier_billy_combo_stance:OnCreated()
    if not IsServer() then return end
    self.last = GameRules:GetGameTime()
    self:GetParent():StartGesture(ACT_DOTA_CHANNEL_ABILITY_7)
    self:StartIntervalThink(FrameTime())
end

function modifier_billy_combo_stance:OnIntervalThink()
    local now = GameRules:GetGameTime()
    local combo = self:GetAbility()
    if IsNotNull(combo) then combo:StanceThink(now - self.last) end
    self.last = now
end

function modifier_billy_combo_stance:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if IsNotNull(parent) then parent:RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_7) end
    local combo = self:GetAbility()
    if IsNotNull(combo) then combo:EndStance() end
end

function modifier_billy_combo_stance:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ABILITY_START, MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_ORDER }
end

-- Любой приказ самого Билли (ход, атака, каст, стоп) отменяет стойку — как ченнел.
-- Покупки, предметы в инвентаре, пинги и т.п. (BILLY_HARMLESS_ORDERS) — не отмена, как и у ченнела.
-- Первые cancel_grace с приказы сюда не доходят: их съедает BillyGraceOrderFilter.
function modifier_billy_combo_stance:OnOrder(keys)
    if not IsServer() or keys.unit ~= self:GetParent() then return end
    if BILLY_HARMLESS_ORDERS[keys.order_type] then return end
    self:Destroy()
end

function modifier_billy_combo_stance:OnAbilityStart(keys)    self:Catch(keys) end
function modifier_billy_combo_stance:OnAbilityExecuted(keys) self:Catch(keys) end

function modifier_billy_combo_stance:Catch(keys)
    if not IsServer() then return end
    local unit, ability = keys.unit, keys.ability
    if not IsNotNull(unit) or not IsNotNull(ability) or ability:IsItem() then return end
    -- только настоящие герои: крипы, призывы и иллюзии засаду не включают
    if not unit:IsRealHero() or not unit:IsAlive() then return end
    local parent = self:GetParent()
    -- без UnitFilter: тот отсекает невидимых и неуязвимых, а засада срабатывает и на тех, и на
    -- других (юзер 09.10.2026: пули комбо пробивают неуязвимость)
    if unit:GetTeamNumber() == parent:GetTeamNumber() then return end
    -- враг в другой реальности (UBW, AotK, комната мастеров) — не цель, даже если конус
    -- длиной range дотянулся до её координат
    if not IsInSameRealm(parent:GetAbsOrigin(), unit:GetAbsOrigin()) then return end
    local combo = self:GetAbility()
    if IsNotNull(combo) and combo:InCone(unit) then combo:Trigger(unit) end
end

---------------------------------------------------------------------------------------------------
-- Билли в стойке: бушующая синяя энергия вокруг, лёгкие ветер и пыль.
modifier_billy_combo_aura = modifier_billy_combo_aura or class({})

function modifier_billy_combo_aura:IsHidden()      return true end
function modifier_billy_combo_aura:IsPurgable()    return false end
function modifier_billy_combo_aura:RemoveOnDeath() return true end

function modifier_billy_combo_aura:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    local F = BILLY_COMBO_FX
    self.fx = {}
    for _ = 1, F.aura_layers do
        table.insert(self.fx, ParticleManager:CreateParticle(F.aura, PATTACH_ABSORIGIN_FOLLOW, parent))
    end
    table.insert(self.fx, ParticleManager:CreateParticle(F.wind, PATTACH_ABSORIGIN_FOLLOW, parent))
    table.insert(self.fx, ParticleManager:CreateParticle(F.dust, PATTACH_ABSORIGIN_FOLLOW, parent))
end

function modifier_billy_combo_aura:OnDestroy()
    if not IsServer() or not self.fx then return end
    for _, fx in ipairs(self.fx) do
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end
    self.fx = nil
end

---------------------------------------------------------------------------------------------------
-- Метка комбо: обзор по цели, +mark_damage_amp% входящего урона, пулевые дырки на ней
-- (стаки = число дырок).
modifier_billy_combo_mark = modifier_billy_combo_mark or class({})

function modifier_billy_combo_mark:GetTexture()    return "custom/billy/billy_combo" end
function modifier_billy_combo_mark:IsHidden()      return false end
function modifier_billy_combo_mark:IsDebuff()      return true end
function modifier_billy_combo_mark:IsPurgable()    return false end
function modifier_billy_combo_mark:RemoveOnDeath() return true end

function modifier_billy_combo_mark:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_billy_combo_mark:GetModifierIncomingDamage_Percentage()
    local ab = self:GetAbility()
    return ab and ab:GetSpecialValueFor("mark_damage_amp") or 0
end

function modifier_billy_combo_mark:GetModifierProvidesFOWVision() return 1 end

function modifier_billy_combo_mark:OnCreated()
    if not IsServer() then return end
    self.team = self:GetCaster():GetTeamNumber()
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

-- Ещё одна пуля вошла: +1 дырка (до mark_max), спрайт меняется на следующий сразу, без
-- затухания старого — дырки не накладываются друг на друга.
function modifier_billy_combo_mark:AddHole()
    local n = math.min(self:GetStackCount() + 1, BILLY_COMBO_FX.mark_max)
    if n == self:GetStackCount() then return end
    self:SetStackCount(n)
    self:DestroyFx(true)
    -- на теле цели (attach_hitloc), поверх модели; у юнитов без аттача — от origin
    local parent = self:GetParent()
    local name = string.format(BILLY_COMBO_FX.mark, n)
    local att = parent:ScriptLookupAttachment("attach_hitloc")
    if att and att > 0 then
        self.fx = ParticleManager:CreateParticle(name, PATTACH_CUSTOMORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.fx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    else
        self.fx = ParticleManager:CreateParticle(name, PATTACH_ABSORIGIN_FOLLOW, parent)
    end
end

function modifier_billy_combo_mark:DestroyFx(immediate)
    if not self.fx then return end
    ParticleManager:DestroyParticle(self.fx, immediate)
    ParticleManager:ReleaseParticleIndex(self.fx)
    self.fx = nil
end

-- обзор вокруг цели для команды Билли (вьювер живёт чуть дольше интервала — не мигает)
function modifier_billy_combo_mark:OnIntervalThink()
    local ab = self:GetAbility()
    local parent = self:GetParent()
    if not ab or not IsNotNull(parent) then return end
    AddFOWViewer(self.team, parent:GetAbsOrigin(), ab:GetSpecialValueFor("mark_vision"), 0.2, false)
end

function modifier_billy_combo_mark:OnDestroy()
    if not IsServer() then return end
    self:DestroyFx(false)
end

---------------------------------------------------------------------------------------------------
-- Билли на время очереди комбо: стоит на месте, не атакует, приказы не принимает и
-- играет выстрел — анимацию атаки (Billy_attack) жестом, ускоренную до fire_anim_rate:
-- отдача приходится на первую пулю (юзер 08.10.2026: «анимация выстрела не играет» —
-- раньше тут держалась неподвижная поза стойки combo_hold).
-- ⚠️ Жестом (StartGesture/RemoveGesture), не MODIFIER_PROPERTY_OVERRIDE_ANIMATION: с подменой
-- после очереди Билли застывал (подмена — слой поверх базового, а базовый оставался на
-- однокадровой зацикленной combo_hold). На снятии ещё и перезапускаем базовую активность
-- (Billy_RefreshAnim, со следующего кадра — пока модификатор висит, RefreshAnim сам себя гасит).
modifier_billy_combo_firing = modifier_billy_combo_firing or class({})

function modifier_billy_combo_firing:IsHidden()      return true end
function modifier_billy_combo_firing:IsPurgable()    return false end
function modifier_billy_combo_firing:RemoveOnDeath() return true end

function modifier_billy_combo_firing:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]             = true,
        [MODIFIER_STATE_DISARMED]           = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_billy_combo_firing:OnCreated(kv)
    if not IsServer() then return end
    local rate = kv and tonumber(kv.rate) or 1
    self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, rate > 0 and rate or 1)
end

function modifier_billy_combo_firing:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if not IsNotNull(parent) then return end
    parent:RemoveGesture(ACT_DOTA_ATTACK)
    Timers:CreateTimer(0, function()
        if IsNotNull(parent) then Billy_RefreshAnim(parent) end
    end)
end

---------------------------------------------------------------------------------------------------
-- Замедление метки — отдельным модификатором: снимается как обычный слоу, метка остаётся.
modifier_billy_combo_slow = modifier_billy_combo_slow or class({})

function modifier_billy_combo_slow:IsHidden()   return true end
function modifier_billy_combo_slow:IsDebuff()   return true end
function modifier_billy_combo_slow:IsPurgable() return true end

function modifier_billy_combo_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_billy_combo_slow:GetModifierMoveSpeedBonus_Percentage()
    local ab = self:GetAbility()
    return ab and -ab:GetSpecialValueFor("mark_slow") or 0
end
