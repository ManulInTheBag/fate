require("abilities/kama/kama_shared")

kama_arrow_shot = kama_arrow_shot or class({})

--[[ Q — Arrow Shot. Выстрел стрелой по направлению.
     Floral: стрела останавливается на первой цели и даёт ей Charm.
     Samsara: стрела пробивает насквозь.
     Попадание снимает кулдаун с Q, W и E — но каждая стрела только один раз,
     сколько бы целей она ни задела.

     Стрелу пускает FireArrow: им же стреляют клоны W, с долей fFactor.
]]

-- Временные эффекты до своих партиклей: стрела Мираны и выстрел Виндрейнджер.
local FX_FLORAL  = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
local FX_SAMSARA = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf"

-- Способности, с которых попадание Q снимает кулдаун.
local CDR_ABILITIES = {"kama_arrow_shot", "kama_embrace_of_dreams", "kama_petal_volley"}

function kama_arrow_shot:OnAbilityPhaseStart()
    -- анимация обычного выстрела, ускоренная под кастпоинт
    StartAnimation(self:GetCaster(), {duration = 0.5, activity = ACT_DOTA_ATTACK, rate = 2.0})
    return true
end

function kama_arrow_shot:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function kama_arrow_shot:OnSpellStart()
    local caster = self:GetCaster()
    local vDirection = self:GetCursorPosition() - caster:GetAbsOrigin()
    vDirection.z = 0
    if vDirection:Length2D() < 1 then vDirection = caster:GetForwardVector() end

    -- стрела вылетает из руки с луком; у модели без такого крепления — от груди
    local nAttach = caster:ScriptLookupAttachment("attach_attack1")
    local vOrigin = nAttach > 0 and caster:GetAttachmentOrigin(nAttach)
        or caster:GetAbsOrigin() + Vector(0, 0, 100)

    caster:EmitSound("Ability.Powershot.Alt")
    self:FireArrow(vOrigin, vDirection:Normalized(), 1)
end

--[[ Пустить одну стрелу. fFactor — доля урона, Charm и снятия кулдауна
     (1 у самой Камы, меньше у клонов). Вид стрелы берётся на момент выстрела. ]]
function kama_arrow_shot:FireArrow(vOrigin, vDirection, fFactor)
    local caster = self:GetCaster()
    local bSamsara = Kama_IsSamsara(caster)
    local nWidth = self:GetSpecialValueFor("width")

    -- помним, какие стрелы ещё могут снять кулдаун: ExtraData между попаданиями
    -- одной стрелы не меняется, счёт приходится вести тут
    self.nArrowId = (self.nArrowId or 0) + 1
    self.tArrowCanReduce = self.tArrowCanReduce or {}
    self.tArrowCanReduce[self.nArrowId] = true

    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = caster,
        EffectName       = bSamsara and FX_SAMSARA or FX_FLORAL,
        vSpawnOrigin     = vOrigin,
        vVelocity        = vDirection * self:GetSpecialValueFor("speed"),
        fDistance        = self:GetSpecialValueFor("range"),
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        ExtraData        = {
            arrow   = self.nArrowId,
            factor  = fFactor,
            samsara = bSamsara and 1 or 0,
        },
    })
end

function kama_arrow_shot:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    self.tArrowCanReduce = self.tArrowCanReduce or {}

    -- стрела долетела до конца дистанции
    if not Kama_Alive(hTarget) then
        self.tArrowCanReduce[tData.arrow] = nil
        return true
    end

    local caster = self:GetCaster()
    if not Kama_Alive(caster) then return true end
    local bSamsara = tData.samsara == 1

    if not IsSpellBlocked(hTarget, caster) then
        if self.tArrowCanReduce[tData.arrow] then
            self.tArrowCanReduce[tData.arrow] = nil
            self:ReduceCooldowns(tData.factor)
        end

        DoDamage(caster, hTarget, self:GetSpecialValueFor("damage") * tData.factor,
            self:GetAbilityDamageType(), 0, self, false)

        local tArrow = {}
        if not bSamsara then
            tArrow.charm = self:GetSpecialValueFor("charm") * tData.factor
        end
        Kama_ArrowHit(caster, hTarget, tArrow)
    end

    -- Samsara летит дальше, Floral на первой цели кончается
    if bSamsara then return false end
    self.tArrowCanReduce[tData.arrow] = nil
    return true
end

--[[ Снять кулдаун с Q, W и E за попадание стрелы. Это вычитание из остатка, а
     не установка кулдауна: сколько останется, зависит от того, сколько стрел
     попало. Атрибут 4 удваивает снятие. ]]
function kama_arrow_shot:ReduceCooldowns(fFactor)
    local caster = self:GetCaster()
    local sKey = caster.KamaAttr4Acquired and "cd_reduction_attr" or "cd_reduction"
    local fSeconds = self:GetSpecialValueFor(sKey) * fFactor

    for _, sName in ipairs(CDR_ABILITIES) do
        local hAbility = caster:FindAbilityByName(sName)
        if Kama_Alive(hAbility) and not hAbility:IsCooldownReady() then
            local fLeft = hAbility:GetCooldownTimeRemaining() - fSeconds
            hAbility:EndCooldown()
            if fLeft > 0 then hAbility:StartCooldown(fLeft) end
        end
    end
end
