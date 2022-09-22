modifier_selfish_self_invul = class({})

function modifier_selfish_self_invul:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true }
end

function modifier_selfish_self_invul:RemoveOnDeath()
	return true
end

function modifier_selfish_self_invul:GetTexture()
	return "custom/gille_spellbook_of_prelati"
end