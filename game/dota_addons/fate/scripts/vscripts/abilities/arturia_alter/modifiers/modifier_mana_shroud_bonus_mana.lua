modifier_mana_shroud_bonus_mana = class({})

function modifier_mana_shroud_bonus_mana:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_BONUS }
end

function modifier_mana_shroud_bonus_mana:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end