kama_d = class({})

--[[ Kama D
     Создано панелью. ScriptFile: abilities/kama/kama_d
     
]]

LinkLuaModifier("modifier_kama_d", "abilities/kama/kama_d",
    LUA_MODIFIER_MOTION_NONE)

function kama_d:OnSpellStart()
    local caster = self:GetCaster()
    --caster:EmitSound("kama_d_cast")
    caster:AddNewModifier(caster, self, "modifier_kama_d",
        {Duration = self:GetSpecialValueFor("duration")})
end

--=========================================================================--
modifier_kama_d = class({})

function modifier_kama_d:IsHidden()         return false end
function modifier_kama_d:IsDebuff()         return false end
function modifier_kama_d:IsPurgable()       return false end
function modifier_kama_d:IsPurgeException() return false end
function modifier_kama_d:RemoveOnDeath()    return true end

-- Бонусы считаются на ОБЕИХ сторонах: иначе в тултипе и на панели статов
-- игрок увидит не то, что реально работает.
function modifier_kama_d:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_kama_d:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_ms_pct")
end

function modifier_kama_d:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_kama_d:OnCreated(tTable)
    if not IsServer() then return end
    --self:GetParent():EmitSound("kama_d_start")
end

function modifier_kama_d:OnDestroy()
    if not IsServer() then return end
    --self:GetParent():EmitSound("kama_d_end")
end

--function modifier_kama_d:GetEffectName()
--    return "particles/kama/kama_d_buff.vpcf"
--end
--function modifier_kama_d:GetEffectAttachType()
--    return PATTACH_ABSORIGIN_FOLLOW
--end
