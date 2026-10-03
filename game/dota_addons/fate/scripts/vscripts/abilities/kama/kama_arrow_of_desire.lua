require("abilities/kama/kama_shared")

kama_arrow_of_desire = kama_arrow_of_desire or class({})

--[[ D — Arrow of Desire. Усиленная стрела.
     Кастпоинт короткий, но сам выстрел идёт после зарядки (charge_time): всё
     это время Кама стоит на месте и ничего не может (Kama_Charge).
     Floral: летит по направлению, останавливается на первой цели и сразу
     даёт ей большую порцию Charm.
     Samsara: массивная стрела летит в указанную точку, подхватывает до
     max_targets врагов и тащит их с собой, а в конце пути взрывается:
     совсем небольшой урон и лёгкое замедление всем врагам рядом.
     Кулдаун печатью Мастера не сбрасывается (CannotReset в util.lua).
]]

LinkLuaModifier("modifier_kama_desire_drag", "abilities/kama/kama_arrow_of_desire",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_desire_slow", "abilities/kama/kama_arrow_of_desire",
    LUA_MODIFIER_MOTION_NONE)

-- Временные эффекты до своих партиклей: стрела Мираны и выстрел Виндрейнджер.
local FX_FLORAL  = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
local FX_SAMSARA = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf"
-- кольцо по радиусу взрыва (CP1 — цвет, CP2 — радиус и время)
local FX_EXPLOSION = "particles/zlodemon/zlodemon_basic_circle.vpcf"

--[[ Анимация в две части.
     Зарядка — второй выстрел модели, замедленный так, чтобы тетива сорвалась
     ровно к концу зарядки. У модели это 5-6 кадр из 30 (~0.18 с в родном
     темпе), а от нажатия до выстрела проходит кастпоинт + charge_time = 0.6 с,
     отсюда rate 0.3. Меняешь эти времена — пересчитай rate.
     После выстрела — возврат лука (PlayRecovery): отдельная секвенция
     attack_2_recover, те же кадры с 6-го и до конца, уже в родном темпе. ]]
function kama_arrow_of_desire:OnAbilityPhaseStart()
    local fShot = self:GetCastPoint() + self:GetSpecialValueFor("charge_time")
    StartAnimation(self:GetCaster(), {duration = fShot + 0.1,
        activity = ACT_DOTA_ATTACK2, rate = 0.3})
    return true
end

-- Замедленный замах снимаем и с того же кадра доигрываем возврат лука.
-- Жест оборвётся первым же новым приказом (Kama_FadeRecovery).
function kama_arrow_of_desire:PlayRecovery()
    local caster = self:GetCaster()
    EndAnimation(caster)
    caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_7)
    caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_7, 1.0)
end

function kama_arrow_of_desire:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

-- Стрела летит сама, идти «в радиус» незачем: серверу дальность отдаём
-- «бесконечную», клиенту — настоящую дальность полёта.
function kama_arrow_of_desire:GetCastRange(vLocation, hTarget)
    if IsServer() then return 99999 end
    return self:GetSpecialValueFor("range")
end

-- Куда и как далеко летит стрела к точке vPoint: направление и дистанция,
-- поджатая к дальности полёта.
function kama_arrow_of_desire:Aim(vPoint)
    local caster = self:GetCaster()
    local vOffset = vPoint - caster:GetAbsOrigin()
    vOffset.z = 0
    local fDistance = vOffset:Length2D()
    local vDirection = fDistance < 1 and caster:GetForwardVector() or vOffset:Normalized()
    return vDirection, math.min(math.max(fDistance, 1), self:GetSpecialValueFor("range"))
end

-- Samsara тащит врагов в точку: утащить их в другое измерение нельзя.
function kama_arrow_of_desire:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if IsServer() and Kama_IsSamsara(caster) then
        local vOrigin = caster:GetAbsOrigin()
        local vDirection, fDistance = self:Aim(vLocation)
        if not IsInSameRealm(vOrigin, vOrigin + vDirection * fDistance) then
            return UF_FAIL_CUSTOM
        end
    end
    return UF_SUCCESS
end

function kama_arrow_of_desire:GetCustomCastErrorLocation(vLocation)
    return "#Must be in same realm"
end

function kama_arrow_of_desire:OnSpellStart()
    local caster = self:GetCaster()
    -- прицел и вид стрелы фиксируются в момент нажатия
    local vDirection, fDistance = self:Aim(self:GetCursorPosition())
    local bSamsara = Kama_IsSamsara(caster)

    Kama_Charge(caster, self, self:GetSpecialValueFor("charge_time"), function()
        local vOrigin = caster:GetAbsOrigin()
        caster:EmitSound("Ability.Powershot.Alt")
        self:PlayRecovery()
        if bSamsara then
            -- стрела долетает до точки, но не дальше своей дальности
            self:FireDragArrow(vOrigin, vDirection, fDistance)
        else
            self:FireCharmArrow(vOrigin, vDirection)
        end
    end)
end

--=========================================================================--
-- Floral
--=========================================================================--

function kama_arrow_of_desire:FireCharmArrow(vOrigin, vDirection)
    local nWidth = self:GetSpecialValueFor("width")
    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = self:GetCaster(),
        EffectName       = FX_FLORAL,
        vSpawnOrigin     = vOrigin + Vector(0, 0, 100),
        vVelocity        = vDirection * self:GetSpecialValueFor("speed"),
        fDistance        = self:GetSpecialValueFor("range"),
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        ExtraData        = {samsara = 0},
    })
end

--=========================================================================--
-- Samsara
--=========================================================================--

function kama_arrow_of_desire:FireDragArrow(vOrigin, vDirection, fDistance)
    local nWidth = self:GetSpecialValueFor("drag_width")
    local nSpeed = self:GetSpecialValueFor("drag_speed")

    -- кого тащит каждая стрела: ExtraData между событиями одной стрелы не
    -- меняется, список приходится вести тут
    self.nArrowId = (self.nArrowId or 0) + 1
    self.tDragged = self.tDragged or {}
    self.tDragged[self.nArrowId] = {}

    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = self:GetCaster(),
        EffectName       = FX_SAMSARA,
        vSpawnOrigin     = vOrigin + Vector(0, 0, 100),
        vVelocity        = vDirection * nSpeed,
        fDistance        = fDistance,
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        ExtraData        = {
            samsara = 1,
            arrow   = self.nArrowId,
            -- сколько стреле лететь: на столько же вешаем захват, с запасом
            flight  = fDistance / nSpeed,
        },
    })
end

-- Стрела летит: подхваченные едут вместе с ней.
function kama_arrow_of_desire:OnProjectileThink_ExtraData(vLocation, tData)
    if tData.samsara ~= 1 then return end
    local tUnits = self.tDragged and self.tDragged[tData.arrow]
    if not tUnits then return end

    for _, hUnit in ipairs(tUnits) do
        if Kama_Alive(hUnit) and hUnit:IsAlive() and hUnit:HasModifier("modifier_kama_desire_drag") then
            hUnit:SetAbsOrigin(GetGroundPosition(vLocation, hUnit))
        end
    end
end

function kama_arrow_of_desire:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    local caster = self:GetCaster()
    if not Kama_Alive(caster) then return true end

    if tData.samsara ~= 1 then
        -- Floral: первая же цель останавливает стрелу
        if not Kama_Alive(hTarget) then return true end
        if not IsSpellBlocked(hTarget, caster) then
            DoDamage(caster, hTarget, self:GetSpecialValueFor("damage"),
                self:GetAbilityDamageType(), 0, self, false)
            Kama_ArrowHit(caster, hTarget, {charm = self:GetSpecialValueFor("charm")})
        end
        return true
    end

    self.tDragged = self.tDragged or {}
    local tUnits = self.tDragged[tData.arrow] or {}

    -- стрела долетела: отпускает всех, кого тащила, и взрывается
    if not Kama_Alive(hTarget) then
        self.tDragged[tData.arrow] = nil
        local tDraggedHere = {}
        for _, hUnit in ipairs(tUnits) do
            if Kama_Alive(hUnit) then
                -- снятие захвата само ставит цель на проходимое место
                hUnit:RemoveModifierByName("modifier_kama_desire_drag")
                tDraggedHere[hUnit] = true
            end
        end
        self:Explode(vLocation, tDraggedHere)
        return true
    end

    -- кого сдвинуть нельзя, мимо того стрела просто пролетает; блок заклинаний
    -- тратится, только когда стрела и правда собирается подхватить цель
    if not IsKnockbackImmune(hTarget) and #tUnits < self:GetSpecialValueFor("max_targets")
        and not IsSpellBlocked(hTarget, caster) then
        local hDrag = hTarget:AddNewModifier(caster, self, "modifier_kama_desire_drag",
            {duration = tData.flight + 0.3})
        if hDrag then
            table.insert(tUnits, hTarget)
            self.tDragged[tData.arrow] = tUnits
        end
    end
    return false
end

--[[ Взрыв в конце пути: совсем небольшой урон и лёгкое замедление всем врагам
     рядом. Для каждого задетого считается попаданием стрелы.
     tDraggedHere — кого стрела притащила: их блок заклинаний уже проверен. ]]
function kama_arrow_of_desire:Explode(vCenter, tDraggedHere)
    local caster = self:GetCaster()
    local nRadius = self:GetSpecialValueFor("explosion_radius")
    vCenter = GetGroundPosition(vCenter, nil)

    local nFx = ParticleManager:CreateParticle(FX_EXPLOSION, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vCenter)
    ParticleManager:SetParticleControl(nFx, 1, Vector(1, 0.4, 0.7))
    ParticleManager:SetParticleControl(nFx, 2, Vector(nRadius, 0.3, 0))
    Timers:CreateTimer(0.4, function()
        ParticleManager:DestroyParticle(nFx, false)
        ParticleManager:ReleaseParticleIndex(nFx)
    end)

    local tEnemies = FindUnitsInRadius(caster:GetTeamNumber(), vCenter, nil, nRadius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, hEnemy in pairs(tEnemies) do
        if Kama_Alive(hEnemy) and (tDraggedHere[hEnemy] or not IsSpellBlocked(hEnemy, caster)) then
            DoDamage(caster, hEnemy, self:GetSpecialValueFor("explosion_damage"),
                self:GetAbilityDamageType(), 0, self, false)

            if Kama_Alive(hEnemy) and hEnemy:IsAlive() then
                if not IsImmuneToSlow(hEnemy) then
                    hEnemy:AddNewModifier(caster, self, "modifier_kama_desire_slow",
                        {duration = self:GetSpecialValueFor("explosion_slow_duration")})
                end
                Kama_ArrowHit(caster, hEnemy, {})
            end
        end
    end
end

--=========================================================================--
-- Цель подхвачена стрелой. Двигает её сама способность (OnProjectileThink);
-- модификатор не даёт ей действовать и, когда снимается, ставит на
-- проходимое место — в том числе если стрела почему-то не отпустила сама.
modifier_kama_desire_drag = class({})

function modifier_kama_desire_drag:IsHidden()      return false end
function modifier_kama_desire_drag:IsDebuff()      return true end
function modifier_kama_desire_drag:IsPurgable()    return false end
function modifier_kama_desire_drag:RemoveOnDeath() return true end

function modifier_kama_desire_drag:CheckState()
    return {
        [MODIFIER_STATE_STUNNED]           = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_kama_desire_drag:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if Kama_Alive(hParent) and hParent:IsAlive() then
        FindClearSpaceForUnit(hParent, hParent:GetAbsOrigin(), true)
    end
end

--=========================================================================--
modifier_kama_desire_slow = class({})

function modifier_kama_desire_slow:IsHidden()      return false end
function modifier_kama_desire_slow:IsDebuff()      return true end
function modifier_kama_desire_slow:IsPurgable()    return true end
function modifier_kama_desire_slow:RemoveOnDeath() return true end

function modifier_kama_desire_slow:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_kama_desire_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("explosion_slow")
end
