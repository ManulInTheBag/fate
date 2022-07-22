modifier_shroud_of_martin = class({})

function modifier_shroud_of_martin:OnCreated(args)
	if IsServer() then
		self.Armor = args.Armor
		self.MagicResist = args.MagicResist
		self.HealthBonus = self:GetParent():GetIntellect() * 0

		CustomNetTables:SetTableValue("sync","shroud_of_martin", { armor_bonus = self.Armor,
																   magic_resist = self.MagicResist,
																   health = self.HealthBonus})
	end
end

function modifier_shroud_of_martin:GetModifierHealthBonus()
	if IsServer() then	
		self.HealthBonus = self:GetParent():GetIntellect() * 0
		CustomNetTables:SetTableValue("sync","shroud_of_martin", { armor_bonus = self.Armor,
																   magic_resist = self.MagicResist,
																   health = self.HealthBonus})

		return self.HealthBonus
	elseif IsClient() then
		local health = CustomNetTables:GetTableValue("sync","shroud_of_martin").health
 		return health 
	end
end

function modifier_shroud_of_martin:GetModifierPhysicalArmorBonus()
	if IsServer() then
		return self.Armor
	elseif IsClient() then
		local armor_bonus = CustomNetTables:GetTableValue("sync","shroud_of_martin").armor_bonus
 		return armor_bonus 
	end
end

function modifier_shroud_of_martin:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.MagicResist
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","shroud_of_martin").magic_resist
 		return magic_resist 
	end
end

function modifier_shroud_of_martin:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, 
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_HEALTH_BONUS}
end

function modifier_shroud_of_martin:IsDebuff()
	return false
end

function modifier_shroud_of_martin:IsPermanent()
	return true 
end

function modifier_shroud_of_martin:RemoveOnDeath()
	return false 
end

function modifier_shroud_of_martin:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_shroud_of_martin:GetTexture()
	return "custom/archer_5th_attribute_shroud_of_martin"
end

