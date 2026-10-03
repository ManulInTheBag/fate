kama_arrow_of_desire = class({})

--[[ Kama D
     Создано панелью. ScriptFile: abilities/kama/kama_arrow_of_desire
     
]]

LinkLuaModifier("modifier_kama_arrow_of_desire", "abilities/kama/kama_arrow_of_desire",
    LUA_MODIFIER_MOTION_NONE)

function kama_arrow_of_desire:OnSpellStart()
    local caster = self:GetCaster()
    --caster:EmitSound("kama_arrow_of_desire_cast")
    caster:AddNewModifier(caster, self, "modifier_kama_arrow_of_desire",
        {Duration = self:GetSpecialValueFor("duration")})
end

--=========================================================================--
modifier_kama_arrow_of_desire = class({})

function modifier_kama_arrow_of_desire:IsHidden()         return false end
function modifier_kama_arrow_of_desire:IsDebuff()         return false end
function modifier_kama_arrow_of_desire:IsPurgable()       return false end
function modifier_kama_arrow_of_desire:IsPurgeException() return false end
function modifier_kama_arrow_of_desire:RemoveOnDeath()    return true end

-- Бонусы считаются на ОБЕИХ сторонах: иначе в тултипе и на панели статов
-- игрок увидит не то, что реально работает.
function modifier_kama_arrow_of_desire:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_kama_arrow_of_desire:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_ms_pct")
end

function modifier_kama_arrow_of_desire:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_kama_arrow_of_desire:OnCreated(tTable)
    if not IsServer() then return end
    --self:GetParent():EmitSound("kama_arrow_of_desire_start")
end

function modifier_kama_arrow_of_desire:OnDestroy()
    if not IsServer() then return end
    --self:GetParent():EmitSound("kama_arrow_of_desire_end")
end

--function modifier_kama_arrow_of_desire:GetEffectName()
--    return "particles/kama/kama_arrow_of_desire_buff.vpcf"
--end
--function modifier_kama_arrow_of_desire:GetEffectAttachType()
--    return PATTACH_ABSORIGIN_FOLLOW
--end
