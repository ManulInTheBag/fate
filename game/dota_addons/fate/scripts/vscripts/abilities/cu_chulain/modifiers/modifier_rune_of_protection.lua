modifier_rune_of_protection = class({})

function modifier_rune_of_protection:IsHidden()
	return false 
end

function modifier_rune_of_protection:RemoveOnDeath()
	return true
end
function modifier_rune_of_protection:GetEffectName()
    return "particles/zlodemon/immunity_sphere_buff_red.vpcf"
end
function modifier_rune_of_protection:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end