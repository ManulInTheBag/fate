require("abilities/kama/kama_shared")

kama_petal_volley = kama_petal_volley or class({})

--[[ E — Petal Volley. Поглощает всех клонов W и стреляет: одна стрела своя и
     ещё по одной за каждого поглощённого.
     Floral: стрелы летят очередью по направлению, каждая останавливается на
     первой цели; по Charmed-целям бьют критом.
     Samsara: способность по цели — в неё летят все лазеры, а в каждого врага
     рядом с ней ещё по одному.
     От вида стрел зависит и способ наведения (GetBehavior).
     Клоны поглощаются сразу при нажатии, а выстрел идёт после зарядки
     (charge_time). Кама стоит на месте и ничего не может и во время зарядки,
     и пока не выпустит всю очередь — иначе блинк посреди очереди переносил бы
     оставшиеся стрелы на новое место.
]]

-- Временные эффекты до своих партиклей: стрела Мираны и стрела Дроу.
local FX_ARROW = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
local FX_LASER = "particles/units/heroes/hero_drow/drow_base_attack.vpcf"

function kama_petal_volley:GetBehavior()
    if Kama_IsSamsara(self:GetCaster()) then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
    end
    return DOTA_ABILITY_BEHAVIOR_POINT
end

function kama_petal_volley:GetAOERadius()
    return self:GetSpecialValueFor("samsara_radius")
end

--[[ Samsara бьёт по цели в пределах AbilityCastRange. Floral стреляет по
     направлению, идти «в радиус» ей незачем: серверу отдаём «бесконечную»
     дальность, клиенту — дальность полёта стрелы. ]]
function kama_petal_volley:GetCastRange(vLocation, hTarget)
    if Kama_IsSamsara(self:GetCaster()) then
        return self.BaseClass.GetCastRange(self, vLocation, hTarget)
    end
    if IsServer() then return 99999 end
    return self:GetSpecialValueFor("range")
end

function kama_petal_volley:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    local nResult = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
        caster:GetTeamNumber())
    if nResult ~= UF_SUCCESS then return nResult end
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function kama_petal_volley:GetCustomCastErrorTarget(hTarget)
    return "#Must be in same realm"
end

-- Живые клоны W (пусто, если W ещё нет).
function kama_petal_volley:GetClones()
    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    if not Kama_Alive(hEmbrace) or hEmbrace:GetLevel() < 1 then return {} end
    return hEmbrace:GetClones()
end

-- Сколько длится очередь из nArrows выстрелов, от первого до последнего.
function kama_petal_volley:VolleyTime(nArrows)
    return (nArrows - 1) * self:GetSpecialValueFor("arrow_interval")
end

--[[ Анимация spell_4: замах, пауза и резкий выпуск на 14-15 кадре (0.5 с в
     родном темпе). От нажатия до выстрела проходит кастпоинт + charge_time =
     0.6 с, отсюда rate 0.85. Меняешь эти времена — пересчитай rate.
     Длится, пока идёт очередь: стрел будет столько, сколько сейчас клонов. ]]
function kama_petal_volley:OnAbilityPhaseStart()
    local fShot = self:GetCastPoint() + self:GetSpecialValueFor("charge_time")
    local fVolley = self:VolleyTime(1 + #self:GetClones())
    Kama_FadeGestures(self:GetCaster())
    StartAnimation(self:GetCaster(), {duration = fShot + fVolley + 0.4,
        activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85})
    return true
end

function kama_petal_volley:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function kama_petal_volley:OnSpellStart()
    local caster = self:GetCaster()
    local nArrows = 1 + self:AbsorbClones()
    -- прицел и вид стрел фиксируются в момент нажатия
    local bSamsara = Kama_IsSamsara(caster)
    local hTarget = self:GetCursorTarget()
    local vDirection = self:GetCursorPosition() - caster:GetAbsOrigin()
    vDirection.z = 0
    vDirection = vDirection:Length2D() < 1 and caster:GetForwardVector() or vDirection:Normalized()

    Kama_Charge(caster, self, self:GetSpecialValueFor("charge_time"), function()
        caster:EmitSound("Ability.Powershot.Alt")
        if bSamsara then
            self:FireLasers(hTarget, nArrows)
        else
            self:FireVolley(vDirection, nArrows)
        end
    end, self:VolleyTime(nArrows))
end

-- Забрать всех клонов W. Поглощение не считается уничтожением клона.
function kama_petal_volley:AbsorbClones()
    -- копия списка: RemoveClone правит сам список
    local tClones = {}
    for _, hClone in ipairs(self:GetClones()) do
        table.insert(tClones, hClone)
    end
    if #tClones < 1 then return 0 end

    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    for _, hClone in ipairs(tClones) do
        hEmbrace:RemoveClone(hClone, KAMA_CLONE_ABSORBED)
    end
    return #tClones
end

--=========================================================================--
-- Floral: очередь стрел по направлению
--=========================================================================--

function kama_petal_volley:FireVolley(vDirection, nArrows)
    local caster = self:GetCaster()
    local fInterval = self:GetSpecialValueFor("arrow_interval")

    for i = 0, nArrows - 1 do
        Timers:CreateTimer(i * fInterval, function()
            if not Kama_Alive(self) or not Kama_Alive(caster) or not caster:IsAlive() then return end
            self:FireArrow(vDirection)
        end)
    end
end

function kama_petal_volley:FireArrow(vDirection)
    local caster = self:GetCaster()
    local nWidth = self:GetSpecialValueFor("width")

    -- стрела вылетает из руки с луком; у модели без такого крепления — от груди
    local nAttach = caster:ScriptLookupAttachment("attach_attack1")
    local vOrigin = nAttach > 0 and caster:GetAttachmentOrigin(nAttach)
        or caster:GetAbsOrigin() + Vector(0, 0, 100)

    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = caster,
        EffectName       = FX_ARROW,
        vSpawnOrigin     = vOrigin,
        vVelocity        = vDirection * self:GetSpecialValueFor("speed"),
        fDistance        = self:GetSpecialValueFor("range"),
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        ExtraData        = {samsara = 0, checked = 0},
    })
end

--=========================================================================--
-- Samsara: лазеры по цели и по одному во всех врагов рядом
--=========================================================================--

function kama_petal_volley:FireLasers(hTarget, nArrows)
    local caster = self:GetCaster()
    if not Kama_Alive(hTarget) then return end
    local fInterval = self:GetSpecialValueFor("arrow_interval")

    local tNearby = FindUnitsInRadius(caster:GetTeamNumber(), hTarget:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("samsara_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, false)
    for _, hEnemy in pairs(tNearby) do
        if hEnemy ~= hTarget then self:FireLaser(hEnemy, false) end
    end

    -- способность по цели: блок заклинаний гасит все лазеры в саму цель
    if IsSpellBlocked(hTarget, caster) then return end
    for i = 0, nArrows - 1 do
        Timers:CreateTimer(i * fInterval, function()
            if not Kama_Alive(self) or not Kama_Alive(caster) or not caster:IsAlive() then return end
            if not Kama_Alive(hTarget) or not hTarget:IsAlive() then return end
            self:FireLaser(hTarget, true)
        end)
    end
end

-- bChecked: блок заклинаний у цели уже проверен при касте.
function kama_petal_volley:FireLaser(hTarget, bChecked)
    ProjectileManager:CreateTrackingProjectile({
        Ability           = self,
        Source            = self:GetCaster(),
        Target            = hTarget,
        EffectName        = FX_LASER,
        iMoveSpeed        = self:GetSpecialValueFor("laser_speed"),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bDodgeable        = true,
        ExtraData         = {samsara = 1, checked = bChecked and 1 or 0},
    })
end

--=========================================================================--

function kama_petal_volley:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if not Kama_Alive(hTarget) or not hTarget:IsAlive() then return true end
    local caster = self:GetCaster()
    if not Kama_Alive(caster) then return true end

    local bSamsara = tData.samsara == 1
    -- лазеры в главную цель уже прошли проверку блока при касте; стрелы Floral
    -- и лазеры в соседей проверяем на попадании
    if tData.checked ~= 1 and IsSpellBlocked(hTarget, caster) then return true end

    local nDamage = self:GetSpecialValueFor("damage")
    if not bSamsara and Kama_IsCharmed(hTarget) then
        nDamage = nDamage * self:GetSpecialValueFor("crit_mult")
    end
    DoDamage(caster, hTarget, nDamage, self:GetAbilityDamageType(), 0, self, false)
    Kama_ArrowHit(caster, hTarget, {})
    return true
end
