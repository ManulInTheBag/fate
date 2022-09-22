modifier_prelati_regen_block = class({})

function modifier_prelati_regen_block:IsDebuff()
	return true
end

function modifier_prelati_regen_block:IsHidden()
	return false
end

function modifier_prelati_regen_block:IsPermanent()
	return false
end

function modifier_prelati_regen_block:RemoveOnDeath()
	return false
end

function modifier_prelati_regen_block:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end