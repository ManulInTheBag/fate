modifier_master_intervention = class({})

function modifier_master_intervention:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_master_intervention:GetModifierIncomingDamage_Percentage(keys)
	local reduction = self:GetAbility():GetSpecialValueFor("damage_reduc")
	local attacker = keys.attacker

	-- Damage sent through DoDamageThroughIntervention() carries a piercing portion that must land in
	-- full, so the reduction only covers the rest of the instance.
	if attacker and attacker.fInterventionPiercingDamage and keys.original_damage > 0 then
		local piercing = math.min(attacker.fInterventionPiercingDamage, keys.original_damage)
		reduction = reduction * (keys.original_damage - piercing) / keys.original_damage
	end

	return reduction
end