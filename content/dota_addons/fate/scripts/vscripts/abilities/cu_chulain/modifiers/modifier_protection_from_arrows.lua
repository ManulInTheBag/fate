modifier_protection_from_arrows = class({})

function modifier_protection_from_arrows:DeclareFunctions()
	return { MODIFIER_PROPERTY_EVASION_CONSTANT }
end

function modifier_protection_from_arrows:GetModifierEvasion_Constant()
	return 25
end

function modifier_protection_from_arrows:IsHidden()
	return true 
end