modifier_spellbook_active_tracker = class({})

function modifier_spellbook_active_tracker:IsHidden()
	return true
end

function modifier_spellbook_active_tracker:IsDebuff()
	return false
end

function modifier_spellbook_active_tracker:RemoveOnDeath()
	return false
end

function modifier_spellbook_active_tracker:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end