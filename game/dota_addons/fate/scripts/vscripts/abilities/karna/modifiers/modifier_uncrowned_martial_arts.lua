modifier_uncrowned_martial_arts = class({})

function modifier_uncrowned_martial_arts:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			--MODIFIER_EVENT_ON_ATTACK_LANDED
			 }
end

if IsServer() then
	function modifier_uncrowned_martial_arts:OnCreated(args)
		self.Active = false
		self.Evasion = 10
		self.Movespeed = 10
		self.AttackSpeed = 40

		CustomNetTables:SetTableValue("sync","uncrowned_martial_arts", { evasion = self.Evasion,
																		 movespeed = self.Movespeed,
																		 attack_speed = self.AttackSpeed })
	end

	function modifier_uncrowned_martial_arts:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		self.Evasion = math.min(self.Evasion + 5, 50)
		self.Movespeed = math.min(self.Movespeed + 5, 50)
		self.AttackSpeed = math.min(self.AttackSpeed + 20, 400)

		CustomNetTables:SetTableValue("sync","uncrowned_martial_arts", { evasion = self.Evasion,
																		 movespeed = self.Movespeed,
																		 attack_speed = self.AttackSpeed })
		self:StartIntervalThink(2)
	end


	function modifier_uncrowned_martial_arts:OnIntervalThink()
		self.Evasion = 10
		self.Movespeed = 10
		self.AttackSpeed = 40

		CustomNetTables:SetTableValue("sync","uncrowned_martial_arts", { evasion = self.Evasion,
																		 movespeed = self.Movespeed,
																		 attack_speed = self.AttackSpeed })
		self:StartIntervalThink(-1)
	end
end

function modifier_uncrowned_martial_arts:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed
	elseif IsClient() then
		local attack_speed = CustomNetTables:GetTableValue("sync","uncrowned_martial_arts").attack_speed
        return attack_speed 
	end
end

function modifier_uncrowned_martial_arts:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.Movespeed
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","uncrowned_martial_arts").movespeed
        return movespeed 
	end
end

function modifier_uncrowned_martial_arts:GetModifierEvasion_Constant()
	if IsServer() then
		return self.Evasion
	elseif IsClient() then
		local evasion = CustomNetTables:GetTableValue("sync","uncrowned_martial_arts").evasion
        return evasion 		
	end
end

function modifier_uncrowned_martial_arts:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_uncrowned_martial_arts:GetTexture()
	return "custom/karna/karna_uncrowned_martial_arts"
end