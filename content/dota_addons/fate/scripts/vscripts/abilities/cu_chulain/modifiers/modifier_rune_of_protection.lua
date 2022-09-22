modifier_rune_of_protection = class({})

function modifier_rune_of_protection:IsHidden()
	return false 
end

function modifier_rune_of_protection:RemoveOnDeath()
	return true
end