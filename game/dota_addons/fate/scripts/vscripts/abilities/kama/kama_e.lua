kama_e = class({})

--[[ Kama E
     Создано панелью. ScriptFile: abilities/kama/kama_e
     
]]

-- Цель нельзя брать сквозь измерение и по залоченному кастеру: те же проверки
-- стоят у всех прицельных способностей аддона.
function kama_e:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    if IsServer() and (IsLocked(caster)
        or not IsInSameRealm(caster:GetAbsOrigin(), hTarget:GetAbsOrigin())) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function kama_e:GetCustomCastErrorTarget(hTarget)
    return "#Is_Locked"
end

function kama_e:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration = self:GetCastPoint(),
        activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0})
    return true
end

function kama_e:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function kama_e:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    EndAnimation(caster)
    if not IsNotNull(target) then return end
    -- ⚠️ Блок способностей проверяем ДО эффекта (util.lua:IsSpellBlocked)
    if IsSpellBlocked(target, caster) then return end
    --caster:EmitSound("kama_e_cast")

    DoDamage(caster, target, self:GetSpecialValueFor("damage"),
        self:GetAbilityDamageType(), 0, self, false)
end
