modifier_master_intervention = class({})

function modifier_master_intervention:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_master_intervention:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_reduc")
end