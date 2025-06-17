modifier_scathach_gait_one_armor_reduction = class({})

--------------------------------------------------------------------------------

function modifier_scathach_gait_one_armor_reduction:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_one_armor_reduction:OnCreated( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_scathach_gait_one_armor_reduction:OnRefresh( kv )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end
--------------------------------------------------------------------------------

function modifier_scathach_gait_one_armor_reduction:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

function modifier_scathach_gait_one_armor_reduction:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_scathach_gait_one_armor_reduction:GetModifierPhysicalArmorBonus()
	return self.armor_reduction
end

function modifier_scathach_gait_one_armor_reduction:IsHidden()
	return true
end