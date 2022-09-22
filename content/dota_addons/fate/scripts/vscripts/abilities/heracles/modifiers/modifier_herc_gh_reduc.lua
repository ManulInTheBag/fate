modifier_herc_gh_reduc = class({})

function modifier_herc_gh_reduc:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_herc_gh_reduc:GetModifierIncomingDamage_Percentage()
	return -50
end