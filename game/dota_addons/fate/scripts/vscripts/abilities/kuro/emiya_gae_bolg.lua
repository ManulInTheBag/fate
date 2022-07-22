emiya_gae_bolg = class({})

function emiya_gae_bolg:CastFilterResultLocation(vLocation)
	local caster = self:GetCaster()

	if (caster:GetAbsOrigin() - vLocation):Length2D() > 1500 then 
		return UF_FAIL_INVALID_LOCATION
	else
		return UF_SUCCESS
	end

end

function emiya_gae_bolg:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle( self.GBCastFx, false )

	return true
end

function emiya_gae_bolg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	self.GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(self.GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( self.GBCastFx, false )
	end)
	
	caster:EmitSound("emiya_gae_bolg")
	return true
end

function emiya_gae_bolg:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectileSpeed = 1900
	local ply = caster:GetPlayerOwner()
	local ascendCount = 0
	local descendCount = 0
	
	
	--EmitGlobalSound("archer_attack_03")
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.8)
	Timers:CreateTimer(0.8, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postdelay", 0.15)
	end)
	Timers:CreateTimer(0.95, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postlock", 0.2)
	end)
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_gae_jump_throw_anim", {}) 

	Timers:CreateTimer('gb_throw', {
		endTime = 0.45,
		callback = function()		

		local projectileOrigin = caster:GetAbsOrigin() + Vector(0,0,300)
		local projectile = CreateUnitByName("dummy_unit", projectileOrigin, false, caster, caster, caster:GetTeamNumber())
		projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		projectile:SetAbsOrigin(projectileOrigin)

		local particle_name = "particles/custom/lancer/lancer_gae_bolg_projectile.vpcf"
		local throw_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		ParticleManager:SetParticleControl(throw_particle, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)

		local travelTime = (targetPoint - projectileOrigin):Length() / projectileSpeed
		Timers:CreateTimer(travelTime, function()
			ParticleManager:DestroyParticle(throw_particle, false)
			self:OnGaeBolgHit(targetPoint, projectile)
		end)
	end
	})

	Timers:CreateTimer('gb_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 then 
	   		StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_4, rate=4})
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+50))
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	Timers:CreateTimer("gb_descend", {
	    endTime = 0.3,
	    callback = function()
	    	if descendCount == 15 then return end
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-50))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})
end

function emiya_gae_bolg:OnGaeBolgHit(position, projectile)
	local caster = self:GetCaster()
	local targetPoint = position
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	
	local stun_duration = 0.1
	
	if caster:HasModifier("modifier_projection_attribute") then
		damage = damage + (caster:GetAgility() * 7)
		--damage = damage + self:GetSpecialValueFor("attribute_damage")
		stun_duration = 0.5
	end

	local modifierKnockback =
	{
		center_x = targetPoint.x,
		center_y = targetPoint.y,
		center_z = targetPoint.z,
		duration = 0.25,
		knockback_duration = 0.25,
		knockback_distance = 0,
		knockback_height = 150,
	}

	Timers:CreateTimer(0.15, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stun_duration})
	        v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback )
	    end
	    projectile:SetAbsOrigin(targetPoint)
	    local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile)
		local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
		local explodeFx1 = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, projectile )
		ParticleManager:SetParticleControl( fire, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( crack, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, projectile:GetAbsOrigin())
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
		caster:EmitSound("Misc.Crash")
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( fire, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
		end)
	end)
end