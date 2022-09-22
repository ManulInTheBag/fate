gilles_grief = class({})
modifier_gilles_grief = class({})
LinkLuaModifier("modifier_gilles_fear", "abilities/gilles/modifiers/modifier_gilles_fear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_grief", "abilities/gilles/gilles_grief", LUA_MODIFIER_MOTION_NONE)

function gilles_grief:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or hTarget == self:GetCaster() then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function gilles_grief:IsHiddenAbilityCastable()
	return true
end

function gilles_grief:GetCustomCastErrorTarget(hTarget)
	return "Invalid Target"
end

function gilles_grief:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_grief:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_grief:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Gilles_Grief_Cast", hCaster)

	hTarget:AddNewModifier(hCaster, self, "modifier_gilles_grief", { Damage = self:GetSpecialValueFor("damage"),
																	 Duration = self:GetSpecialValueFor("duration") })
	hTarget:AddNewModifier(hCaster, self, "modifier_gilles_fear", {duration = 10})
end


if IsServer() then 
	function modifier_gilles_grief:OnCreated(args)
		self.Damage = args.Damage

		self.Particle = ParticleManager:CreateParticle("particles/econ/items/sand_king/sandking_ti7_arms/sandking_ti7_caustic_finale_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.Particle, 0, self:GetParent():GetAbsOrigin()) 
	end

	function modifier_gilles_grief:OnRefresh(args)
		self.Damage = args.Damage
	end

	function modifier_gilles_grief:OnDestroy()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local fDamage = self.Damage

		EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Gilles_Grief_Explode", hCaster)
		ParticleManager:DestroyParticle( self.Particle, true )
        ParticleManager:ReleaseParticleIndex( self.Particle )

		if self:GetParent():IsAlive() then
			local fExplosionDamage = self:GetParent():GetMaxHealth() - self:GetParent():GetHealth()
			
			local tTargets = FindUnitsInRadius(hCaster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, hAbility:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for _,v in pairs(tTargets) do
				DoDamage(hCaster, v, fExplosionDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)
			end
			self:GetParent():AddNewModifier(hCaster, hAbility, "modifier_stunned", {Duration = hAbility:GetSpecialValueFor("stun_duration") })
		end

		DoDamage(hCaster, self:GetParent(), fDamage, DAMAGE_TYPE_MAGICAL, 0, hAbility, false)

		local particleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	 	ParticleManager:SetParticleControl(particleIndex, 0, self:GetParent():GetAbsOrigin()) 

		Timers:CreateTimer( 1.5, function()
	        ParticleManager:DestroyParticle( particleIndex, true )
	        ParticleManager:ReleaseParticleIndex( particleIndex )
	        return
	    end)
	end	
end

function modifier_gilles_grief:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_gilles_grief:IsDebuff()
	return true
end

function modifier_gilles_grief:IsHidden() 
	return false 
end

function modifier_gilles_grief:GetTexture()
	return "custom/gilles/gilles_grief"
end