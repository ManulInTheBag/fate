modifier_artoria_mana_burst_attribute = class({})

function modifier_artoria_mana_burst_attribute:IsHidden()
	return true
end

function modifier_artoria_mana_burst_attribute:IsPermanent()
	return true
end

function modifier_artoria_mana_burst_attribute:RemoveOnDeath()
	return false
end

function modifier_artoria_mana_burst_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end