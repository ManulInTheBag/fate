modifier_whitechapel_murderer = class({})

LinkLuaModifier("modifier_whitechapel_murderer_crit", "abilities/jtr/modifiers/modifier_whitechapel_murderer_crit", LUA_MODIFIER_MOTION_NONE)

function modifier_whitechapel_murderer:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS
	}
end

if IsServer() then
	function modifier_whitechapel_murderer:OnCreated(args)
		self.AgiBonus = args.AgiBonus

		GameRules:BeginTemporaryNight(self:GetDuration())

		self.time_remaining = self:GetDuration()

		CustomNetTables:SetTableValue("sync","whitechapel_murderer", { agility_bonus = self.AgiBonus })

		self.ParticleDummy = CreateUnitByName("dummy_unit", self:GetParent():GetAbsOrigin(), false, nil, nil, self:GetParent():GetTeamNumber())
		self.ParticleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

		self.Particle = ParticleManager:CreateParticle("particles/jtr/mtr_shadow.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.ParticleDummy)
	    ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())

	    self:StartIntervalThink(FrameTime())
	end

	function modifier_whitechapel_murderer:OnIntervalThink() --this shit is just for correct target modifier duration
		self.time_remaining = self.time_remaining - FrameTime()

		self.ParticleDummy:SetAbsOrigin(self:GetCaster():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
	end

	function modifier_whitechapel_murderer:OnDestroy()
		ParticleManager:DestroyParticle(self.Particle, false)
		ParticleManager:ReleaseParticleIndex(self.Particle)
		self.ParticleDummy:RemoveSelf()
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