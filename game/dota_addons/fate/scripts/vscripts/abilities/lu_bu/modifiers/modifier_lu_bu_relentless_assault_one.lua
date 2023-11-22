modifier_lu_bu_relentless_assault_one = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_one:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_one:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor("movement_slow")
end

function modifier_lu_bu_relentless_assault_one:OnRefresh( kv )
	self.slow = self:GetAbility():GetSpecialValueFor("movement_slow")
end
--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_one:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_lu_bu_relentless_assault_one:CheckState()
	local state = {
		[MODIFIER_STATE_DISARMED] = true
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_one:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_lu_bu_relentless_assault_one:IsHidden()
	return true
end