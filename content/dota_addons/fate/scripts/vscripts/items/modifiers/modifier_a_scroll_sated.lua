modifier_a_scroll_sated = class({})

function modifier_a_scroll_sated:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_a_scroll_sated:IsHidden()
	return false
end

function modifier_a_scroll_sated:IsDebuff()
	return true 
end

function modifier_a_scroll_sated:RemoveOnDeath()
	return true 
end

function modifier_a_scroll_sated:GetTexture()
    return "custom/a_scroll_debuff"
end