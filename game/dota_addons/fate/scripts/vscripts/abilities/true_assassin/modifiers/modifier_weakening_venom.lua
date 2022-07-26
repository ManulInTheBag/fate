modifier_weakening_venom = class({})

--[[function modifier_weakening_venom:OnCreated(args)
    
end]]

-----------------------------------------------------------------------------------
function modifier_weakening_venom:GetEffectName()
    return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf"
end

function modifier_weakening_venom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_weakening_venom:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_weakening_venom:IsPurgable()
    return false
end

function modifier_weakening_venom:IsDebuff()
    return true
end


function modifier_weakening_venom:RemoveOnDeath()
    return true
end

function modifier_weakening_venom:GetTexture()
    return "custom/true_assassin_dirk"
end
-----------------------------------------------------------------------------------
