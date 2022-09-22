modifier_gilles_fear = class({})

function modifier_gilles_fear:OnCreated()
	self:SetStackCount(1)
end

function modifier_gilles_fear:OnRefresh()
	self:SetStackCount((self:GetStackCount() or 1) + 1)
end

function modifier_gilles_fear:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_gilles_fear:GetModifierIncomingDamage_Percentage(keys)
		if keys.attacker == self:GetCaster() then
			return self:GetStackCount()*10
		else
			return 0
		end
end

function modifier_gilles_fear:IsPurgable() return true end