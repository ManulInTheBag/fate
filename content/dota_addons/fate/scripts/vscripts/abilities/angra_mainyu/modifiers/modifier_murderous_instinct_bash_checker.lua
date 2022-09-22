modifier_murderous_instinct_bash_checker = class({})

function modifier_murderous_instinct_bash_checker:IsHidden()
	return false
end

function modifier_murderous_instinct_bash_checker:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end