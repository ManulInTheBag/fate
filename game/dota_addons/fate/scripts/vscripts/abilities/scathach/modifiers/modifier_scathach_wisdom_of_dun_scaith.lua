modifier_scathach_wisdom_of_dun_scaith = class({})


function modifier_scathach_wisdom_of_dun_scaith:OnCreated(args)
	if IsServer() then
	end
end

function modifier_scathach_wisdom_of_dun_scaith:IsHidden()
	return false 
end

function modifier_scathach_wisdom_of_dun_scaith:RemoveOnDeath()
	return true
end

function modifier_scathach_wisdom_of_dun_scaith:GetEffectName()
    return "particles/zlodemon/immunity_sphere_buff.vpcf"
end
function modifier_scathach_wisdom_of_dun_scaith:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end