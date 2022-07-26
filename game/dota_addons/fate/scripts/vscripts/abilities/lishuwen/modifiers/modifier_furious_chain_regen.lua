modifier_furious_chain_regen = class({})

function modifier_furious_chain_regen:OnCreated(keys)
	if IsServer() then
		self.RegenAmount = keys.RegenAmount
	end
end

function modifier_furious_chain_regen:GetRegenAmount()
	if IsServer() then
		CustomNetTables:SetTableValue("sync","furious_chain_regen", { regen_amt = self.RegenAmount * self:GetStackCount() })
		return self.RegenAmount * self:GetStackCount()
	elseif IsClient() then
		local regen_amt = CustomNetTables:GetTableValue("sync","furious_chain_regen").regen_amt
		return regen_amt
	end	
end

function modifier_furious_chain_regen:GetModifierConstantHealthRegen()
	return self:GetRegenAmount()
end

function modifier_furious_chain_regen:GetModifierConstantManaRegen()
	return self:GetRegenAmount()
end

function modifier_furious_chain_regen:DeclareFunctions()
	local funcs = {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
					MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
	return funcs
end

function modifier_furious_chain_regen:IsHidden()
	return false
end

function modifier_furious_chain_regen:IsDebuff()
	return false
end

function modifier_furious_chain_regen:RemoveOnDeath()
	return true
end

function modifier_furious_chain_regen:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_furious_chain_regen:GetTexture()
	return "custom/lishuwen_attribute_furious_chain"
end
