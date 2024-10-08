-----------------------------
--    Modifier: Innate Poison    --
-----------------------------

modifier_robin_poison_stack = class({})

function modifier_robin_poison_stack:IsDebuff()
    return true
end

function modifier_robin_poison_stack:RemoveOnDeath()
    return false
end

function modifier_robin_poison_stack:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_robin_poison_stack:IsHidden()
    return false
end

function modifier_robin_poison_stack:GetEffectName()
	return "particles/custom/robin/robin_yew_bow_poison.vpcf"
end

function modifier_robin_poison_stack:GetTexture()
    return "custom/robin/robin_poison_stack"
end