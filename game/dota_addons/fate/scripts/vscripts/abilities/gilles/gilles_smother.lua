gilles_smother = class({})
modifier_gilles_smother = class({})

LinkLuaModifier("modifier_gilles_smother", "abilities/gilles/gilles_smother", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_fear", "abilities/gilles/modifiers/modifier_gilles_fear", LUA_MODIFIER_MOTION_NONE)

function gilles_smother:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_smother:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_smother:IsHiddenAbilityCastable()
	return true
end

function gilles_smother:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetLocation = self:GetCursorPosition()
	local fAOE = self:GetAOERadius() + 50

	EmitSoundOnLocationWithCaster(vTargetLocation, "Gilles_Smother_Cast", hCaster)

	local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTargetLocation, nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
	for _,v in pairs(tEnemies) do
		if not v:IsMagicImmune() then
			v:AddNewModifier(hCaster, self, "modifier_gilles_smother", { ExplosionDamage = self:GetSpecialValueFor("explosion_damage"),
																		 Damage = self:GetSpecialValueFor("damage"),
																		 Duration =  self:GetSpecialValueFor("duration") + 0.1})
			v:AddNewModifier(hCaster, self, "modifier_gilles_fear", {duration = 10})
		end
	end

	local particle = ParticleManager:CreateParticle("particles/custom/gilles/smother_ground_fire.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, vTargetLocation) 
	ParticleManager:SetParticleControl(particle, 1, Vector(fAOE,fAOE,fAOE)) 
	ParticleManager:SetParticleControl(particle, 3, Vector(fAOE,fAOE,fAOE)) 
	
	local particle2 = ParticleManager:CreateParticle("particles/custom/gilles/smother_cast_warp.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 1, vTargetLocation) 
	ParticleManager:SetParticleControl(particle2, 2, vTargetLocation) 
	ParticleManager:SetParticleControl(particle2, 3, vTargetLocation) 
	ParticleManager:SetParticleControl(particle2, 4, vTargetLocation) 

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
		ParticleManager:DestroyParticle( particle2, false )
		ParticleManager:ReleaseParticleIndex( particle2 )
	end)
end

function modifier_gilles_smother:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

if IsServer() then 
	function modifier_gilles_smother:OnCreated(args)
		self.Damage = (args.Damage * 0.4) / self:GetDuration()
		self.ExplosionDamage = args.ExplosionDamage

		self:StartIntervalThink(0.4)

		self.Particle = ParticleManager:CreateParticle("particles/custom/gilles/smother_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.Particle, 0, self:GetParent():GetAbsOrigin()) 
		ParticleManager:SetParticleControl(self.Particle, 1, self:GetParent():GetAbsOrigin()) 
		ParticleManager:SetParticleControl(self.Particle, 3, self:GetParent():GetAbsOrigin()) 
	end

	function modifier_gilles_smother:OnRefresh(args)
		self.Damage = (args.Damage * 0.4) / self:GetDuration()
		self.ExplosionDamage = args.ExplosionDamage
	end

	function modifier_gilles_smother:OnDestroy()
		ParticleManager:DestroyParticle( self.Particle, false )
		ParticleManager:ReleaseParticleIndex( self.Particle )
	end

	function modifier_gilles_smother:OnIntervalThink()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local fDamage = self.Damage

		DoDamage(hCaster, self:GetParent(), fDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)
	end

	function modifier_gilles_smother:OnAbilityFullyCast(args)
		if args.unit ~= self:GetParent() or args.ability:IsItem() then return end

		EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Gilles_Smother_Explode", self:GetParent())

		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local tTargets = FindUnitsInRadius(hCaster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, hAbility:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
		for _,v in pairs(tTargets) do
			DoDamage(hCaster, v, self.ExplosionDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)
		end

		self:GetParent():AddNewModifier(hCaster, hAbility, "modifier_stunned", { Duration = hAbility:GetSpecialValueFor("stun_duration") })

		local particle = ParticleManager:CreateParticle("particles/custom/gilles/smother_explode.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin()) 
		ParticleManager:SetParticleControl(particle, 1, self:GetParent():GetAbsOrigin()) 

		Timers:CreateTimer( 2.5, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)

		self:Destroy()
	end
end

function modifier_gilles_smother:IsDebuff()
	return true
end

function modifier_gilles_smother:IsHidden() 
	return false 
end

function modifier_gilles_smother:GetTexture()
	return "custom/gilles/gilles_smother"
end