modifier_evaporation_sanity = class({})

LinkLuaModifier("modifier_evaporation_sanity_crit", "abilities/astolfo/modifiers/modifier_evaporation_sanity_crit", LUA_MODIFIER_MOTION_NONE)

function modifier_evaporation_sanity:DeclareFunctions()
	return {MODIFIER_PROPERTY_EVASION_CONSTANT,
			--MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ATTACK_START }
end

if IsServer() then
	function modifier_evaporation_sanity:OnCreated(args)
		self.Evasion = 0

		CustomNetTables:SetTableValue("sync","uncrowned_martial_arts", { evasion = self.Evasion })
	end

	function modifier_evaporation_sanity:OnAttackStart(args)
		if args.attacker ~= self:GetParent() then return end

		if RandomInt(1, 100) <= 35 then
			args.attacker:AddNewModifier(args.attacker, self:GetAbility(), "modifier_evaporation_sanity_crit", { Duration = 1 })
		end
	end

	function modifier_evaporation_sanity:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		args.attacker:RemoveModifierByName("modifier_evaporation_sanity_crit")

		if RandomInt(1, 100) <= 35 then
			self.Evasion = 100
			CustomNetTables:SetTableValue("sync","evaporation_sanity", { evasion = self.Evasion })
		end

		if RandomInt(1, 100) <= 35 then
			args.attacker:EmitSound("Astolfo_Sanity_" .. RandomInt(1, 8))
			giveUnitDataDrivenModifier(args.attacker, args.target, "modifier_rooted", 1.5)
			DoDamage(args.attacker, args.target, 100, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end

		self:StartIntervalThink(1)
	end


	function modifier_evaporation_sanity:OnIntervalThink()
		self.Evasion = 0

		CustomNetTables:SetTableValue("sync","evaporation_sanity", { evasion = self.Evasion})
		self:StartIntervalThink(-1)
	end
end

function modifier_evaporation_sanity:GetModifierEvasion_Constant()
	if IsServer() then
		return self.Evasion
	elseif IsClient() then
		local evasion = CustomNetTables:GetTableValue("sync","evaporation_sanity").evasion
        return evasion 		
	end
end

function modifier_evaporation_sanity:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_evaporation_sanity:GetTexture()
	return "custom/astolfo_attribute_sanity"
end