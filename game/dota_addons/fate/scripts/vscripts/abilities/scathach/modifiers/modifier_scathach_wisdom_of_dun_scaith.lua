modifier_scathach_wisdom_of_dun_scaith = class({})

function modifier_scathach_wisdom_of_dun_scaith:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_scathach_wisdom_of_dun_scaith:OnCreated(args)
	if IsServer() then
	end
end

function modifier_scathach_wisdom_of_dun_scaith:GetModifierMagicalResistanceBonus()
	return 5
end

function modifier_scathach_wisdom_of_dun_scaith:IsHidden()
	return false 
end

function modifier_scathach_wisdom_of_dun_scaith:RemoveOnDeath()
	return true
end