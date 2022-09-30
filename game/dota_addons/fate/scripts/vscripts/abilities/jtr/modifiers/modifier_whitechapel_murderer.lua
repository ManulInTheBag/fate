modifier_whitechapel_murderer = class({})

LinkLuaModifier("modifier_whitechapel_murderer_crit", "abilities/jtr/modifiers/modifier_whitechapel_murderer_crit", LUA_MODIFIER_MOTION_NONE)

function modifier_whitechapel_murderer:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_START,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

if IsServer() then
	function modifier_whitechapel_murderer:OnCreated(args)
		self.AgiBonus = args.AgiBonus

		GameRules:BeginTemporaryNight(15)

		self.time_remaining = 0

		CustomNetTables:SetTableValue("sync","whitechapel_murderer", { agility_bonus = self.AgiBonus })

		self.ParticleDummy = CreateUnitByName("dummy_unit", self:GetParent():GetAbsOrigin(), false, nil, nil, self:GetParent():GetTeamNumber())
		self.ParticleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

		--[[self.MistParticle = ParticleManager:CreateParticle("particles/custom/jtr/whitechapel_murderer_cloud.vpcf", PATTACH_EYES_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.MistParticle, 0, self.ParticleDummy:GetAbsOrigin())
		ParticleManager:SetParticleControl(self.MistParticle, 1, Vector(1000, 1, 0))
		ParticleManager:SetParticleShouldCheckFoW(self.MistParticle, false)]]

		self.Particle = ParticleManager:CreateParticle("particles/jtr/mtr_shadow.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.ParticleDummy)
	    ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())

	    self.OriginalVision = self:GetParent():GetDayTimeVisionRange()

		if self:GetParent():HasModifier("modifier_murderer_mist") then
			self.modifier = self:GetParent():FindModifierByName("modifier_murderer_mist")
			self.OriginalVision = self.modifier.base_range_day
		end

		LoopOverPlayers(function(player, playerID, playerHero)
        	if playerHero:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and playerHero:IsAlive() then
        		playerHero:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_whitechapel_murderer_enemy", { Duration = self:GetAbility():GetSpecialValueFor("duration") })
        	elseif playerHero:GetTeamNumber() == self:GetParent():GetTeamNumber() and playerHero:IsAlive() and playerHero ~= self:GetParent() then
        		playerHero:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_whitechapel_murderer_ally", { Duration = self:GetAbility():GetSpecialValueFor("duration") })
        	end
     	end)

		--self:GetParent():SetDayTimeVisionRange(600)
		--self:GetParent():SetNightTimeVisionRange(600)

		local targets = _G.AllNpcTable
		--PrintTable(targets)

		--local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		--[[for i,j in pairs(targets) do
			if not j:IsNull() then
				if (j:GetTeamNumber() == 2 or j:GetTeamNumber() == 3) and not j:IsPlayer() and j:IsAlive() then
					if j:GetTeam() == self:GetParent():GetTeam() then
						j:AddNewModifier(j, self:GetAbility(), "modifier_whitechapel_murderer_ally", { duration = 15})
					else
						j:AddNewModifier(j, self:GetAbility(), "modifier_whitechapel_murderer_enemy", {duration = 15})
					end
				end
			end
		end]]

	    self:StartIntervalThink(FrameTime())
	end

	function modifier_whitechapel_murderer:OnIntervalThink()
		self.time_remaining = self.time_remaining + FrameTime()
		--self:GetParent():SetDayTimeVisionRange(600)
		--self:GetParent():SetNightTimeVisionRange(600)

		self.ParticleDummy:SetAbsOrigin(self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())

	    local targets = _G.AllNpcTable

	    LoopOverPlayers(function(player, playerID, playerHero)
        	if playerHero:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and playerHero:IsAlive() then
        		playerHero:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_whitechapel_murderer_enemy", { Duration = self:GetAbility():GetSpecialValueFor("duration") - self.time_remaining })
        	elseif playerHero:GetTeamNumber() == self:GetParent():GetTeamNumber() and playerHero:IsAlive() and playerHero ~= self:GetParent() then
        		playerHero:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_whitechapel_murderer_ally", { Duration = self:GetAbility():GetSpecialValueFor("duration") - self.time_remaining })
        	end
     	end)

		--local targets = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		--[[for i,j in pairs(targets) do
			if not j:IsNull() then
				if (j:GetTeamNumber() == 2 or j:GetTeamNumber() == 3) and not j:IsPlayer() and j:IsAlive() then
					if j:GetTeam() == self:GetParent():GetTeam() and not j:HasModifier("modifier_whitechapel_murderer_ally") then
						j:AddNewModifier(j, self:GetAbility(), "modifier_whitechapel_murderer_ally", { duration = 15 - self.time_remaining})
					elseif not j:GetTeam() == self:GetParent():GetTeam() and not j:HasModifier("modifier_whitechapel_murderer_enemy") then
						j:AddNewModifier(j, self:GetAbility(), "modifier_whitechapel_murderer_enemy", {duration = 15 - self.time_remaining})
					end
				end
			end
		end]]
	end

	function modifier_whitechapel_murderer:OnDestroy()
		self:GetAbility():EndCombo()

		--self:GetParent():SetDayTimeVisionRange(self.OriginalVision)		
		--self:GetParent():SetNightTimeVisionRange(self.OriginalVision)

		ParticleManager:DestroyParticle(self.Particle, false)
		ParticleManager:ReleaseParticleIndex(self.Particle)
		--[[ParticleManager:DestroyParticle(self.MistParticle, false)
		ParticleManager:ReleaseParticleIndex(self.MistParticle)]]
		self.ParticleDummy:RemoveSelf()
	end

	function modifier_whitechapel_murderer:OnAttackStart(args)
		if args.attacker ~= self:GetParent() then return end

		if RandomInt(1, 100) <= 35 then
			args.attacker:AddNewModifier(args.attacker, self:GetAbility(), "modifier_whitechapel_murderer_crit", { Duration = 1 })
		end
	end
	
	function modifier_whitechapel_murderer:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		self:GetParent():RemoveModifierByName("modifier_whitechapel_murderer_crit")
	end

	function modifier_whitechapel_murderer:CheckState()
		return { [MODIFIER_STATE_INVISIBLE] = true }
	end
end

function modifier_whitechapel_murderer:GetModifierBonusStats_Agility()
	if IsServer() then
		return self.AgiBonus
	elseif IsClient() then
		local agility_bonus = CustomNetTables:GetTableValue("sync","whitechapel_murderer").agility_bonus
        return agility_bonus 		
	end
end

function modifier_whitechapel_murderer:GetTexture()
	return "custom/jtr/whitechapel_murderer"
end