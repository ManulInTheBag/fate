modifier_tauropolos = class({})

--[[function modifier_tauropolos:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
    }
 
    return funcs
end
function modifier_tauropolos:GetModifierPercentageCasttime() 
    local ability = self:GetAbility()
    return ability:GetSpecialValueFor("cast_time_reduction")
end]]

function modifier_tauropolos:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             --MODIFIER_EVENT_ON_ATTACK_LANDED
              }
end

function modifier_tauropolos:OnDestroy()
    local hero = self:GetParent()
    hero:CapArrows()
end

function modifier_tauropolos:GetEffectName()
    return "particles/econ/items/legion/legion_fallen/legion_fallen_press.vpcf"
end
 
function modifier_tauropolos:IsDebuff()
    return false
end

function modifier_tauropolos:RemoveOnDeath()
    return true
end

function modifier_tauropolos:GetTexture()
    return "custom/atalanta_tauropolos"
end

function modifier_tauropolos:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_stats")
end

function modifier_tauropolos:GetModifierAttackSpeedBonus_Constant()
    if IsServer() then
        return 75
    elseif IsClient() then
        return 75
    end
end