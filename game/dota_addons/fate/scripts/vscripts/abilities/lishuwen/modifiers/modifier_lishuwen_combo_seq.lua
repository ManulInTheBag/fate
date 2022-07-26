modifier_lishuwen_combo_seq = class({})

function modifier_lishuwen_combo_seq:IsHidden()
	return false
end

function modifier_lishuwen_combo_seq:IsDebuff()
	return false
end

function modifier_lishuwen_combo_seq:RemoveOnDeath()
	return true
end

function modifier_lishuwen_combo_seq:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_lishuwen_combo_seq:GetTexture()
	return "custom/lishuwen_raging_dragon_strike"
end
