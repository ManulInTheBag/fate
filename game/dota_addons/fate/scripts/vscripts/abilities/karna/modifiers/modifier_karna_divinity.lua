modifier_karna_divinity = class({})

function modifier_karna_divinity:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, 
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

if IsServer() then
	function modifier_karna_divinity:OnCreated(args)
		self.MagicResist = 5
		self.BlockAmount = 60

		CustomNetTables:SetTableValue("sync","karna_divinity", { magic_resist = self.MagicResist,
																 block_amount = self.BlockAmount })
	end
end

function modifier_karna_divinity:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.MagicResist
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","karna_divinity").magic_resist
		return magic_resist 
	end
end

function modifier_karna_divinity:GetModifierPhysical_ConstantBlock()
	if IsServer() then
		return self.BlockAmount
	elseif IsClient() then
		local block_amount = CustomNetTables:GetTableValue("sync","karna_divinity").block_amount
		return block_amount 
	end
end

function modifier_karna_divinity:IsHidden()
	return false 
end

function modifier_karna_divinity:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_karna_divinity:GetTexture()
	return "custom/karna/karna_divinity"
end