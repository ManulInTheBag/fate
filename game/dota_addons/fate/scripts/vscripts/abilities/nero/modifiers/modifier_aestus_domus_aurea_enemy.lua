modifier_aestus_domus_aurea_enemy = class({})

LinkLuaModifier("modifier_inside_marble", "abilities/general/modifiers/modifier_inside_marble", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_aestus_domus_aurea_enemy:OnCreated(args)		
		self.ResistReduc = args.ResistReduc
		self.ArmorReduc = args.ArmorReduc
		self.MovespeedReduc = args.MovespeedReduc
		self.TheatreCenterX = args.TheatreCenterX
		self.TheatreCenterY = args.TheatreCenterY
		self.TheatreCenterZ = args.TheatreCenterZ
		self.TheatreSize = args.TheatreSize

		if self:GetParent():GetName() == "npc_dota_hero_bounty_hunter" or self:GetParent():GetName() == "npc_dota_hero_riki" then
			self:GetParent():AddNewModifier(self:GetAbility():GetCaster(), self:GetAbility(), "modifier_inside_marble", { Duration = self:GetDuration() })
		end

		CustomNetTables:SetTableValue("sync","aestus_domus_enemy", { magic_resist = self.ResistReduc,
															 		 armor_reduction = self.ArmorReduc,
															 		 movespeed = self.MovespeedReduc })	
		self:StartIntervalThink(FrameTime())
	end

	function modifier_aestus_domus_aurea_enemy:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_aestus_domus_aurea_enemy:OnDestroy()
		if self:GetParent():GetName() == "npc_dota_hero_bounty_hunter" or self:GetParent():GetName() == "npc_dota_hero_riki" then
			self:GetParent():RemoveModifierByName("modifier_inside_marble")
		end
	end

	function modifier_aestus_domus_aurea_enemy:OnIntervalThink()	
		local parent = self:GetParent()
		local TheatreCenter = Vector(self.TheatreCenterX, self.TheatreCenterY, self.TheatreCenterZ)

		if math.abs((parent:GetAbsOrigin() - TheatreCenter):Length2D()) > self.TheatreSize then
			local diff = parent:GetAbsOrigin() - TheatreCenter
			diff = diff:Normalized()

			parent:SetAbsOrigin(TheatreCenter + diff * self.TheatreSize)
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
		end
	end

	--[[function modifier_aestus_domus_aurea_enemy:OnUnitMoved()	
		local parent = self:GetParent()
		local TheatreCenter = Vector(self.TheatreCenterX, self.TheatreCenterY, self.TheatreCenterZ)

		if math.abs((parent:GetAbsOrigin() - TheatreCenter):Length2D()) > self.TheatreSize then
			local diff = parent:GetAbsOrigin() - TheatreCenter
			diff = diff:Normalized()

			parent:SetAbsOrigin(TheatreCenter + diff * self.TheatreSize)
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
		end
	end]]
end

function modifier_aestus_domus_aurea_enemy:DeclareFunctions()
	return { MODIFIER_EVENT_ON_UNIT_MOVED,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
			 }
end

function modifier_aestus_domus_aurea_enemy:GetModifierProvidesFOWVision()
	return 1
end

--[[function modifier_aestus_domus_aurea_enemy:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.ResistReduc
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").magic_resist
        return magic_resist 
	end
end

function modifier_aestus_domus_aurea_enemy:GetModifierPhysicalArmorBonus()
	if IsServer() then
		return self.ArmorReduc
	elseif IsClient() then
		local armor_reduction = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").armor_reduction
        return armor_reduction 
	end
end

function modifier_aestus_domus_aurea_enemy:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.MovespeedReduc
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","aestus_domus_enemy").movespeed
        return movespeed 
	end
end]]

function modifier_aestus_domus_aurea_enemy:IsHidden()
	return false
end

function modifier_aestus_domus_aurea_enemy:IsDebuff()
	return true
end

function modifier_aestus_domus_aurea_enemy:RemoveOnDeath()
	return true
end

function modifier_aestus_domus_aurea_enemy:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_aestus_domus_aurea_enemy:GetTexture()
	return "custom/nero_aestus_domus_aurea"
end