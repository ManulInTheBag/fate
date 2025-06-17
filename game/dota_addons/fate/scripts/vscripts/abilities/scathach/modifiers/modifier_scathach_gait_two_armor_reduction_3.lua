modifier_scathach_gait_two_armor_reduction_3 = class({})

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_3:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_3:OnCreated( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_scathach_gait_two_armor_reduction_3:OnRefresh( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end
--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_3:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_3:GetModifierPhysicalArmorBonus()
	return self.armor_reduction
end

function modifier_scathach_gait_two_armor_reduction_3:IsHidden()
	return true
end