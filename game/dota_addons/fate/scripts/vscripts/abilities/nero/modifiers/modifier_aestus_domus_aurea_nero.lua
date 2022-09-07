modifier_aestus_domus_aurea_nero = class({})
if IsServer() then
	function modifier_aestus_domus_aurea_nero:OnCreated(args)
	
		self.Resist = args.Resist
		self.Armor = args.Armor
		self.Movespeed = args.Movespeed
		self.TheatreCenterX = args.TheatreCenterX
		self.TheatreCenterY = args.TheatreCenterY
		self.TheatreCenterZ = args.TheatreCenterZ
		self.TheatreSize = args.TheatreSize

		self:GetParent():FindAbilityByName("nero_heat"):IncreaseHeat(self:GetParent())

		CustomNetTables:SetTableValue("sync","aestus_domus_nero", { magic_resist = self.Resist,
															 		armor_bonus = self.Armor,
															 		movespeed = self.Movespeed })

		self:StartIntervalThink(FrameTime())
	end

	function modifier_aestus_domus_aurea_nero:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_aestus_domus_aurea_nero:OnIntervalThink()
		local caster = self:GetParent()
		local theatreCenter = Vector(self.TheatreCenterX, self.TheatreCenterY, self.TheatreCenterZ)

		local enemies = FindUnitsInRadius(caster:GetTeam(), theatreCenter, nil, self.TheatreSize, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		local allies = FindUnitsInRadius(caster:GetTeam(), theatreCenter, nil, self.TheatreSize, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		--local duration = self:GetRemainingTime()
		for i = 1, #enemies do
			if enemies[i]:IsAlive() and not enemies[i]:HasModifier("modifier_aestus_domus_aurea_enemy") then
				enemies[i]:AddNewModifier(caster, self, "modifier_aestus_domus_aurea_enemy", {  ResistReduc = self.Resist * -0.5,
																								ArmorReduc = self.Armor * -0.5,
																								MovespeedReduc = self.Movespeed * -0.5,
																								TheatreCenterX = self.TheatreCenterX,
																								TheatreCenterY = self.TheatreCenterY,
																								TheatreCenterZ = self.TheatreCenterZ,
																								TheatreSize = self.TheatreSize,
																								Duration = self:GetRemainingTime()})
			end
		end

		for i = 1, #allies do
			if allies[i]:IsAlive() and allies[i] ~= caster and not allies[i]:HasModifier("modifier_aestus_domus_aurea_ally") then
				allies[i]:AddNewModifier(caster, self, "modifier_aestus_domus_aurea_ally", { TheatreCenterX = self.TheatreCenterX,
																							 TheatreCenterY = self.TheatreCenterY,
																							 TheatreCenterZ = self.TheatreCenterZ,
																							 TheatreSize = self.TheatreSize,
																							 Duration = self:GetRemainingTime()})
			end
		end
	end

	function modifier_aestus_domus_aurea_nero:OnIntervalThink()	
		local parent = self:GetParent()
		local theatreCenter = Vector(self.TheatreCenterX, self.TheatreCenterY, self.TheatreCenterZ)

		--print("Parent Origin Ally: ", parent:GetAbsOrigin())
		--print("Theatre Center: ", theatreCenter)

		if math.abs((parent:GetAbsOrigin() - theatreCenter):Length2D()) > self.TheatreSize then
			local diff = parent:GetAbsOrigin() - theatreCenter
			diff = diff:Normalized()

			parent:SetAbsOrigin(theatreCenter + diff * self.TheatreSize)
			--print("Abs Origin To Set", (theatreCenter + diff * self.TheatreSize))
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
		end
	end


	function modifier_aestus_domus_aurea_nero:OnDestroy()	
		local ability = self:GetAbility()
		ability:DestroyFx()

		local caster = self:GetParent()
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 3500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

		caster:RemoveModifierByName("modifier_laus_saint_ready_checker")

		for i = 1, #units do
			if units[i]:HasModifier("modifier_aestus_domus_aurea_enemy") or units[i]:HasModifier("modifier_aestus_domus_aurea_ally") then
				units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
				units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
			end
		end	
	end	
end


function modifier_aestus_domus_aurea_nero:DeclareFunctions()
	return { MODIFIER_EVENT_ON_UNIT_MOVED,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
			 
end

function modifier_aestus_domus_aurea_nero:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.Resist
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","aestus_domus_nero").magic_resist
        return magic_resist 
	end
end

function modifier_aestus_domus_aurea_nero:GetModifierConstantManaRegen()
    local regen = self:GetAbility():GetSpecialValueFor("mana_regen")
    return regen
end

function modifier_aestus_domus_aurea_nero:GetModifierPhysicalArmorBonus()
	if IsServer() then
		return self.Armor
	elseif IsClient() then
		local armor_bonus = CustomNetTables:GetTableValue("sync","aestus_domus_nero").armor_bonus
        return armor_bonus 
	end
end

function modifier_aestus_domus_aurea_nero:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.Movespeed
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","aestus_domus_nero").movespeed
        return movespeed 
	end
end

function modifier_aestus_domus_aurea_nero:IsHidden()
	return true
end

function modifier_aestus_domus_aurea_nero:IsDebuff()
	return false
end

function modifier_aestus_domus_aurea_nero:RemoveOnDeath()
	return true
end

function modifier_aestus_domus_aurea_nero:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_aestus_domus_aurea_nero:GetTexture()
	return "custom/nero_aestus_domus_aurea"
end