require("abilities/kama/kama_shared")

kama_arrow_of_desire = kama_arrow_of_desire or class({})

--[[ D — Arrow of Desire. Усиленная стрела после короткого замаха.
     Floral: летит по направлению, останавливается на первой цели и сразу
     даёт ей большую порцию Charm.
     Samsara: массивная стрела летит в указанную точку, подхватывает до
     max_targets врагов и тащит их с собой; в конце — небольшой урон и
     замедление.
     Кулдаун печатью Мастера не сбрасывается (CannotReset в util.lua).
]]

LinkLuaModifier("modifier_kama_desire_drag", "abilities/kama/kama_arrow_of_desire",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_desire_slow", "abilities/kama/kama_arrow_of_desire",
    LUA_MODIFIER_MOTION_NONE)

-- Временные эффекты до своих партиклей: стрела Мираны и выстрел Виндрейнджер.
local FX_FLORAL  = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
local FX_SAMSARA = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf"

--[[ Замах — вторая анимация выстрела, замедленная под длинный кастпоинт:
     тетива у модели срывается на 5-6 кадре, при rate 0.4 это как раз ~0.46 с. ]]
function kama_arrow_of_desire:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration = self:GetCastPoint() + 0.4,
        activity = ACT_DOTA_ATTACK2, rate = 0.4})
    return true
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
    local vOrigin = caster:GetAbsOrigin()
    local vDirection, fDistance = self:Aim(self:GetCursorPosition())

    caster:EmitSound("Ability.Powershot.Alt")
    if Kama_IsSamsara(caster) then
        -- стрела долетает до точки, но не дальше своей дальности
        self:FireDragArrow(vOrigin, vDirection, fDistance)
    else
        self:FireCharmArrow(vOrigin, vDirection)
    end
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

    -- стрела долетела: всех, кого тащила, отпускает
    if not Kama_Alive(hTarget) then
        self.tDragged[tData.arrow] = nil
        for _, hUnit in ipairs(tUnits) do
            if Kama_Alive(hUnit) then
                -- снятие захвата само ставит цель на проходимое место
                hUnit:RemoveModifierByName("modifier_kama_desire_drag")
                self:Impact(hUnit)
            end
        end
        return true
    end

    if IsSpellBlocked(hTarget, caster) then return false end

    -- кого сдвинуть нельзя, того стрела просто бьёт на месте
    if IsKnockbackImmune(hTarget) then
        self:Impact(hTarget)
        return false
    end

    if #tUnits < self:GetSpecialValueFor("max_targets") then
        local hDrag = hTarget:AddNewModifier(caster, self, "modifier_kama_desire_drag",
            {duration = tData.flight + 0.3})
        if hDrag then
            table.insert(tUnits, hTarget)
            self.tDragged[tData.arrow] = tUnits
        end
    end
    return false
end

-- Конец пути: небольшой урон и замедление. Считается попаданием стрелы.
function kama_arrow_of_desire:Impact(hUnit)
    local caster = self:GetCaster()
    if not hUnit:IsAlive() then return end

    DoDamage(caster, hUnit, self:GetSpecialValueFor("drag_damage"),
        self:GetAbilityDamageType(), 0, self, false)
    if not Kama_Alive(hUnit) or not hUnit:IsAlive() then return end

    if not IsImmuneToSlow(hUnit) then
        hUnit:AddNewModifier(caster, self, "modifier_kama_desire_slow",
            {duration = self:GetSpecialValueFor("drag_slow_duration")})
    end
    Kama_ArrowHit(caster, hUnit, {})
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
    return -self:GetAbility():GetSpecialValueFor("drag_slow")
end
