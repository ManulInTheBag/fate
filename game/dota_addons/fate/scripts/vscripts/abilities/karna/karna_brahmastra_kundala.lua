karna_brahmastra_kundala = class({})

LinkLuaModifier("modifier_kundala_hit", "abilities/karna/modifiers/modifier_kundala_hit", LUA_MODIFIER_MOTION_NONE)

function karna_brahmastra_kundala:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function karna_brahmastra_kundala:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function karna_brahmastra_kundala:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_sunstrike_1")

	return true 
end

function karna_brahmastra_kundala:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local small_radius = self:GetSpecialValueFor("small_radius")
	local large_radius = self:GetSpecialValueFor("radius")
	local full_damage = self:GetSpecialValueFor("damage")
	local delay = self:GetSpecialValueFor("delay")
	local half_damage = full_damage * 0.5
	
	local target_ray = ParticleManager:CreateParticleForTeam("particles/custom/karna/brahmastra_kundala/brahmastra_kundala_ray.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeamNumber())
	ParticleManager:SetParticleControl(target_ray, 0, target_point) 
	ParticleManager:SetParticleControl(target_ray, 1, Vector(100,0,0))

	local visiondummy = SpawnVisionDummy(caster, target_point, small_radius, delay + 1, false)

	Timers:CreateTimer(0.4, function()
		caster:EmitSound("karna_sunstrike_2")
		return
	end)

	Timers:CreateTimer(0.4, function()
		local point_particle = ParticleManager:CreateParticle("particles/karna/kundala_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		local point_particle_2 = ParticleManager:CreateParticle("particles/karna/kundala_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(point_particle, 0,  target_point )
		ParticleManager:SetParticleControl(point_particle, 1,  Vector(300,0,0) )

		ParticleManager:SetParticleControl(point_particle_2, 0,  target_point+Vector(0,0,350) )
		ParticleManager:SetParticleControl(point_particle_2, 1,  Vector(300,0,0) )

		Timers:CreateTimer(1.0, function()
			ParticleManager:DestroyParticle(point_particle, false)
			ParticleManager:ReleaseParticleIndex(point_particle)
			ParticleManager:DestroyParticle(point_particle_2, false)
			ParticleManager:ReleaseParticleIndex(point_particle_2)
		end)
		return
	end)
	
	--EmitSoundOnLocationForAllies(target_point, "karna_brahmastra_kundala_cast", caster)
	EmitGlobalSound("karna_brahmastra_kundala_cast")

	local throw_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_projectile.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(throw_particle, 1, (target_point + Vector(0, 0, 1500) - caster:GetAbsOrigin()):Normalized() * 2500)

	Timers:CreateTimer(delay, function()  
        local full_damage_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, small_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        local half_damage_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, large_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        for i = 1, #full_damage_targets do
            DoDamage(caster, full_damage_targets[i], full_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            full_damage_targets[i]:AddNewModifier(caster, self, "modifier_kundala_hit", { Duration = 0.1 })
        end 

        for i = 1, #half_damage_targets do
        	if not half_damage_targets[i]:HasModifier("modifier_kundala_hit") then
            	DoDamage(caster, half_damage_targets[i], half_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end 

        self.Dummy = CreateUnitByName("dummy_unit", target_point, false, nil, nil, caster:GetTeamNumber())
		self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

        local particle = ParticleManager:CreateParticle("particles/custom/karna/brahmastra_kundala/brahmastra_kundala_explosion_beam.vpcf", PATTACH_ABSORIGIN, self.Dummy)
		ParticleManager:SetParticleControl(particle, 0, target_point) 
		StopGlobalSound("karna_brahmastra_kundala_cast")
		EmitGlobalSound("karna_brahmastra_kundala_explosion")

		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(target_ray, false)
			ParticleManager:ReleaseParticleIndex(target_ray)
			ParticleManager:DestroyParticle(throw_particle, false)
			ParticleManager:ReleaseParticleIndex(throw_particle)
			self.Dummy:RemoveSelf()

			return
		end)

        return 
    end)
end