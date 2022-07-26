modifier_shroud_of_martin = class({})

function modifier_shroud_of_martin:OnCreated(args)
	if IsServer() then
		self.Armor = args.Armor
		self.MagicResist = args.MagicResist
		self.StrengthBonus = 0

		CustomNetTables:SetTableValue("sync","shroud_of_martin", { armor_bonus = self.Armor,
																   magic_resist = self.MagicResist,
																   strength = 0})
	end
end

function modifier_shroud_of_martin:GetModifierBonusStats_Strength()
	if IsServer() then
		local caster = self:GetParent()
		if caster:HasModifier("modifier_unlimited_bladeworks") then
			CustomNetTables:SetTableValue("sync","shroud_of_martin", { armor_bonus = self.Armor,
																	   magic_resist = self.MagicResist,
																	   strength = 20})
			self.StrengthBonus = 20
		else
			CustomNetTables:SetTableValue("sync","shroud_of_martin", { armor_bonus = self.Armor,
																	   magic_resist = self.MagicResist,
																	   strength = 0})
			self.StrengthBonus = 0
		end

		return self.StrengthBonus
	elseif IsClient() then
		local strength = CustomNetTables:GetTableValue("sync","shroud_of_martin").strength
 		return strength 
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
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS}
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

