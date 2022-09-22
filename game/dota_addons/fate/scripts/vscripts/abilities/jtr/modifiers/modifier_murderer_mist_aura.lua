modifier_murderer_mist_aura = class({})

LinkLuaModifier("modifier_murderer_mist", "abilities/jtr/modifiers/modifier_murderer_mist", LUA_MODIFIER_MOTION_NONE) --this reduces vision
LinkLuaModifier("modifier_murderer_mist_in", "abilities/jtr/modifiers/modifier_murderer_mist_in", LUA_MODIFIER_MOTION_NONE) --marker for MTR&scans
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_murderer_mist_aura:OnCreated(args)
		self.AuraRadius = args.AuraRadius
			
		self.AuraBorderFx = ParticleManager:CreateParticleForTeam("particles/custom/jtr/murderer_mist_rope.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), self:GetParent():GetTeamNumber())
		ParticleManager:SetParticleControl(self.AuraBorderFx, 0, Vector(args.AuraRadius,0,0))	
		ParticleManager:SetParticleControl(self.AuraBorderFx, 1, Vector(args.AuraRadius,0,0))
		ParticleManager:SetParticleShouldCheckFoW(self.AuraBorderFx, false)

		self.MistParticle = ParticleManager:CreateParticle("particles/custom/jtr/murderer_mist.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(self.MistParticle, false)
		ParticleManager:SetParticleControl(self.MistParticle, 0, self:GetParent():GetAbsOrigin())	
		ParticleManager:SetParticleControl(self.MistParticle, 1, Vector(args.AuraRadius + 300,0,0))
		

		--particles/custom/jtr/jtr_invis_ring.vpcf

		CustomNetTables:SetTableValue("sync","jtr_mist_aura", { radius = self.AuraRadius })
		self:StartIntervalThink(0.1)
	end

	function modifier_murderer_mist_aura:OnDestroy()
		ParticleManager:DestroyParticle(self.AuraBorderFx, false)
		ParticleManager:ReleaseParticleIndex(self.AuraBorderFx)
		ParticleManager:DestroyParticle(self.MistParticle, false)
		ParticleManager:ReleaseParticleIndex(self.MistParticle)
	end

	function modifier_murderer_mist_aura:OnIntervalThink()
		local caster = self:GetCaster()	
		self.parent = self:GetParent()
		local range = 0
		local targets = FindUnitsInRadius(caster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, 3200, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		local targets1 = FindUnitsInRadius(caster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, self.AuraRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		local targets2 = FindUnitsInRadius(caster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, self.AuraRadius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for i,j in pairs(targets) do
			--if j:IsAlive() then
				if (j:GetUnitName() == "ward_familiar") or (j:GetUnitName() == "sentry_familiar") then
					j:AddNewModifier(j, self:GetAbility(), "modifier_murderer_mist", { duration = 0.2})
				end
			--end
		end
		--[[for i,j in pairs(targets1) do
			if IsFemaleServant(j) then
				j:AddNewModifier(caster, self:GetAbility(), "modifier_vision_provider", {duration = 0.2})
			end
		end]]
		for i, j in pairs(targets2) do
			if j == caster then
				j:AddNewModifier(caster, self:GetAbility(), "modifier_murderer_mist_in", {duration = 0.2})
			end
		end
	end
end

function modifier_murderer_mist_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_murderer_mist_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_murderer_mist_aura:GetAuraRadius()
	local aura_radius = 0

	if IsServer() then
		aura_radius = self.AuraRadius
	else
		aura_radius = CustomNetTables:GetTableValue("sync","jtr_mist_aura").radius        
	end
	
	return aura_radius
end

function modifier_murderer_mist_aura:GetModifierAura()
	return "modifier_murderer_mist_slow"
end

function modifier_murderer_mist_aura:IsHidden()
	return true 
end

function modifier_murderer_mist_aura:RemoveOnDeath()
	return true
end

function modifier_murderer_mist_aura:IsDebuff()
	return false 
end

function modifier_murderer_mist_aura:IsAura()
	return true 
end