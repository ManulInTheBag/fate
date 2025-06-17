modifier_scathach_gait_two_armor_reduction_4 = class({})

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_4:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_4:OnCreated( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_scathach_gait_two_armor_reduction_4:OnRefresh( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end
--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_4:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_two_armor_reduction_4:GetModifierPhysicalArmorBonus()
	return self.armor_reduction
end

function modifier_scathach_gait_two_armor_reduction_4:IsHidden()
	return true
end