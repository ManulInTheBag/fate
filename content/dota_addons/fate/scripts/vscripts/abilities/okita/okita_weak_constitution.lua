LinkLuaModifier("modifier_okita_weak_constitution","abilities/okita/okita_weak_constitution", LUA_MODIFIER_MOTION_NONE)

okita_weak_constitution = class({})

function okita_weak_constitution:GetIntrinsicModifierName()
	return "modifier_okita_weak_constitution"
end

modifier_okita_weak_constitution = class({})
function modifier_okita_weak_constitution:IsHidden() return true end
function modifier_okita_weak_constitution:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,}
end
function modifier_okita_weak_constitution:GetModifierIncomingDamage_Percentage()
	if self:GetParent().IsSummerMadnessAcquired then
		return 0
	end
	return self:GetAbility():GetSpecialValueFor("hp_loss_percent")
end
function modifier_okita_weak_constitution:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

okita_weak_constitution_summer = class({})