modifier_scathach_gate_cooldown_counter = class({})

function modifier_scathach_gate_cooldown_counter:IsHidden()
	return true
end

function modifier_scathach_gate_cooldown_counter:IsPermanent()
	return true
end

function modifier_scathach_gate_cooldown_counter:RemoveOnDeath()
	return true
end

function modifier_scathach_gate_cooldown_counter:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end