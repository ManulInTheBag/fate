modifier_diarmuid_minds_eye = class({})

function modifier_diarmuid_minds_eye:DeclareFunctions()
	return { MODIFIER_PROPERTY_EVASION_CONSTANT, 
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_diarmuid_minds_eye:OnCreated(args)
	if IsServer() then
		self.MagicResist = args.MagicResist
		self.Evasion = args.Evasion
		self.IsSpellBlockReady = true
		CustomNetTables:SetTableValue("sync","diarmuid_minds_eye", { magic_resist = self.MagicResist,
																	 evasion = self.Evasion })
	end
end

function modifier_diarmuid_minds_eye:OnFateSpellBlocked()
	self.IsSpellBlockReady = false
end

function modifier_diarmuid_minds_eye:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.MagicResist
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","diarmuid_minds_eye").magic_resist
        return magic_resist 
	end
end

function modifier_diarmuid_minds_eye:GetModifierEvasion_Constant()
	if IsServer() then
		return self.Evasion
	elseif IsClient() then
		local evasion = CustomNetTables:GetTableValue("sync","diarmuid_minds_eye").evasion
        return evasion 
	end
end

function modifier_diarmuid_minds_eye:IsHidden()
	return false 
end

function modifier_diarmuid_minds_eye:RemoveOnDeath()
	return true
end

function modifier_diarmuid_minds_eye:GetTexture()
	return "custom/diarmuid_attribute_minds_eye"
end