modifier_demonic_horde_attribute = class({})

function modifier_demonic_horde_attribute:IsHidden()
	return true
end

function modifier_demonic_horde_attribute:IsPermanent()
	return true
end

function modifier_demonic_horde_attribute:RemoveOnDeath()
	return false
end

function modifier_demonic_horde_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end