modifier_demon_incarnate = class({})

function modifier_demon_incarnate:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_demon_incarnate:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_amp")
end

function modifier_demon_incarnate:IsHidden()
	return true 
end

function modifier_demon_incarnate:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end