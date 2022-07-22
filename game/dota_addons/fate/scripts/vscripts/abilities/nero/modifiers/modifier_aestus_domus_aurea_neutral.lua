modifier_aestus_domus_aurea_neutral = class({})

function modifier_aestus_domus_aurea_neutral:OnCreated(args)
	if IsServer() then
		--self.ResistReduc = args.ResistReduc
		--self.ArmorReduc = args.ArmorReduc
		--self.MovespeedReduc = args.MovespeedReduc
		self.TheatreCenter = args.TheatreCenter
		self.TheatreSize = args.TheatreSize

		--[[CustomNetTables:SetTableValue("sync","aestus_domus_lock", { magic_resist = self.ResistReduc,
															 		 armor_reduction = self.ArmorReduc,
															 		 movespeed = self.MovespeedReduc })]]
	end
end

function modifier_aestus_domus_aurea_neutral:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_aestus_domus_aurea_neutral:DeclareFunctions()
	return { MODIFIER_EVENT_ON_UNIT_MOVED }
	--,
	--		 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	--		 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	--		 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 
end

--[[function modifier_aestus_domus_aurea_neutral:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.ResistReduc
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").magic_resist
        return magic_resist 
	end
end

function modifier_aestus_domus_aurea_neutral:GetModifierPhysicalArmorBonus()
	if IsServer() then
		return self.ArmorReduc
	elseif IsClient() then
		local armor_reduction = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").armor_reduction
        return armor_reduction 
	end
end

function modifier_aestus_domus_aurea_neutral:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.MovespeedReduc
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").movespeed
        return movespeed 
	end
end]]

function modifier_aestus_domus_aurea_neutral:OnUnitMoved()
	if IsServer() then
		local parent = self:GetParent()

		if math.abs((parent:GetAbsOrigin() - self.TheatreCenter):Length2D()) < self.TheatreSize then
			local diff = self.TheatreCenter - parent:GetAbsOrigin()
			diff = diff:Normalized()

			parent:SetAbsOrigin(self.TheatreCenter + diff + self.TheatreSize)
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
		end
	end
end

function modifier_aestus_domus_aurea_neutral:IsHidden()
	return true
end

function modifier_aestus_domus_aurea_neutral:IsDebuff()
	return false
end

function modifier_aestus_domus_aurea_neutral:RemoveOnDeath()
	return true
end

function modifier_aestus_domus_aurea_neutral:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_aestus_domus_aurea_neutral:GetTexture()
	return "custom/nero_aestus_domus_aurea"
end