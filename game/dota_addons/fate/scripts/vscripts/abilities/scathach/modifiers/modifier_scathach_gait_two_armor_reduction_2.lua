modifier_scathach_gait_two_armor_reduction_2 = class({})

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_2:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_2:OnCreated( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_scathach_gait_two_armor_reduction_2:OnRefresh( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end
--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_2:GetModifierPhysicalArmorBonus()
	return self.armor_reduction
end

function modifier_scathach_gait_two_armor_reduction_2:IsHidden()
	return true
end