modifier_last_spurt = class({})

function modifier_last_spurt:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_MAX
    }
 
    return funcs
end

function modifier_last_spurt:GetModifierMoveSpeedBonus_Percentage() 
    local ability = self:GetAbility()
    local stacks = self:GetStackCount()
    local base = ability:GetSpecialValueFor("base_ms")

    return base + stacks * ability:GetSpecialValueFor("ms_per_unit")
end

function modifier_last_spurt:GetModifierEvasion_Constant()
    local ability = self:GetAbility()
    local stacks = self:GetStackCount()
    local base = ability:GetSpecialValueFor("base_evade")

    return base + stacks*ability:GetSpecialValueFor("evade_per_unit")
end

function modifier_last_spurt:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_last_spurt:GetModifierMoveSpeed_Limit()
    return 625
end

function modifier_last_spurt:GetModifierMoveSpeed_Max()
    return 625
end
 
function modifier_last_spurt:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_last_spurt:IsHidden()
    return false
end

function modifier_last_spurt:IsDebuff()
    return false
end

function modifier_last_spurt:RemoveOnDeath()
    return true
end

function modifier_last_spurt:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end
function modifier_last_spurt:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_last_spurt:GetTexture()
    return "custom/atalanta_last_spurt"
end