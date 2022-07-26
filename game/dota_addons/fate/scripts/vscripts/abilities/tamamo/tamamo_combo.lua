tamamo_combo = class({})

LinkLuaModifier("modifier_tamamo_combo_cooldown", "abilities/tamamo/modifiers/modifier_tamamo_combo_cooldown", LUA_MODIFIER_MOTION_NONE)

function tamamo_combo:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function tamamo_combo:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("range")
end

function tamamo_combo:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectileSpeed = 1900
	local ply = caster:GetPlayerOwner()
	local ascendCount = 0
	local descendCount = 0
	
	local orb = 0
	
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 3.9)
	caster:StopSound(caster.AmaterasuLine)
	caster:RemoveModifierByName("modifier_tamamo_combo_window")
	caster:AddNewModifier(caster, self, "modifier_tamamo_combo_cooldown", { Duration = self:GetCooldown(self:GetLevel()) })

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(self:GetLevel()))

	Timers:CreateTimer('tama_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 then	   		
	   		EmitGlobalSound("Tamamo_Combo1")	   		

		   	return 
		elseif ascendCount == 1 then
		   StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 35))
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})	

	Timers:CreateTimer(0.5, function()
		orb = orb + 1
		if orb <= 8 then
			local projectileOrigin = caster:GetAbsOrigin() + Vector(0,0,25)
			local orb_target = RandomPointInCircle(targetPoint, radius * 0.7)

			if orb == 1 then
				StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_ATTACK, rate=1.5})
			end
			if orb == 5 then
				StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_ATTACK2, rate=1.5})
			end

			if orb % 2 == 0 then
				--StartAnimation(caster, {duration=0.1, activity=ACT_DOTA_ATTACK, rate=6})
				self:CreateProjectile(false, projectileOrigin, orb_target)
			else
				--StartAnimation(caster, {duration=0.1, activity=ACT_DOTA_ATTACK2, rate=6})
				self:CreateProjectile(true, projectileOrigin, orb_target)
			end			

			return 0.1
		else
			return
		end
	end)

	Timers:CreateTimer(2.2, function()
		if caster:IsAlive() then
	   		EmitGlobalSound("Tamamo_Combo2")   		
	   		StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.5})
			local projectileOrigin = caster:GetAbsOrigin() + Vector(0, 0, 50)
			self:ThrowFinalProjectile(projectileOrigin, targetPoint)
		end
		
		return
	end)

	Timers:CreateTimer("tama_descend", {
	    endTime = 3.5,
	    callback = function()
	    	if descendCount == 15 then 
	    		caster:RemoveModifierByName("jump_pause")
		    	return 
		    end
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z - 35))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})
end

function tamamo_combo:CreateProjectile(isFire, orbOrigin, targetLocation)
	local caster = self:GetCaster()
	local projectile = CreateUnitByName("dummy_unit", orbOrigin, false, caster, caster, caster:GetTeamNumber())
	projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	projectile:SetAbsOrigin(orbOrigin)

	local particle_name = ""

	if isFire then
		particle_name = "particles/custom/tamamo/combo/combo_fire_orb_projectile.vpcf"
	else
		particle_name = "particles/custom/tamamo/combo/combo_ice_orb_projectile.vpcf"
	end

	local throw_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
	ParticleManager:SetParticleControl(throw_particle, 0, orbOrigin)
	ParticleManager:SetParticleControl(throw_particle, 1, targetLocation)
	--ParticleManager:SetParticleControl(throw_particle, 1, (targetLocation - orbOrigin):Normalized() * 1900)

	local travelTime = (targetLocation - orbOrigin):Length() / 1900
	Timers:CreateTimer(travelTime, function()
		ParticleManager:DestroyParticle(throw_particle, false)
		self:ProjectileHit(isFire ,targetLocation, projectile)
	end)
end

function tamamo_combo:ProjectileHit(isFire, position, projectile)
	local caster = self:GetCaster()
	local targetPoint = position
	local radius = self:GetSpecialValueFor("small_radius")
	local damage = self:GetSpecialValueFor("small_damage")+(caster:GetIntellect())*2

	local particle_name = ""
	local sound_name = ""

	if isFire then
		particle_name = "particles/custom/tamamo/combo/fire_explosion.vpcf"
		sound_name = "Fire_Explosion_Sound"
	else
		particle_name = "particles/custom/tamamo/combo/ice_explosion.vpcf"
		sound_name = "Ice_Explosion_Sound"
	end	

	Timers:CreateTimer(0.15, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		projectile:EmitSound(sound_name)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 1 })
	    end
	    projectile:SetAbsOrigin(targetPoint)

	    local explosion_fx = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, projectile)
		ParticleManager:SetParticleControl(explosion_fx, 0, projectile:GetAbsOrigin())
		
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( explosion_fx, false )
			ParticleManager:ReleaseParticleIndex(explosion_fx)
			projectile:RemoveSelf()
		end)
	end)
end

function tamamo_combo:ThrowFinalProjectile(orbOrigin, targetLocation)
	local caster = self:GetCaster()
	local projectile = CreateUnitByName("dummy_unit", orbOrigin, false, caster, caster, caster:GetTeamNumber())
	projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	projectile:SetAbsOrigin(orbOrigin)

	local throw_particle = ParticleManager:CreateParticle("particles/custom/tamamo/combo/combo_fire_orb_projectile.vpcf", PATTACH_ABSORIGIN_FOLLOW, projectile)
	ParticleManager:SetParticleControl(throw_particle, 0, orbOrigin)
	ParticleManager:SetParticleControl(throw_particle, 1, targetLocation)
	--ParticleManager:SetParticleControl(throw_particle, 1, (targetLocation - orbOrigin):Normalized() * 1900)

	local travelTime = (targetLocation - orbOrigin):Length() / 1900
	Timers:CreateTimer(travelTime, function()
		ParticleManager:DestroyParticle(throw_particle, false)
		self:FinalProjectileHit(targetLocation, projectile)
	end)
end

function tamamo_combo:FinalProjectileHit(position, projectile)
	local caster = self:GetCaster()
	local targetPoint = position
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("final_damage")+(caster:GetIntellect())*5

	local particle_name = "particles/custom/tamamo/combo/final_orb_explosion.vpcf"

	Timers:CreateTimer(0.15, function()
		projectile:EmitSound("Fire_Explosion_Sound")
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 1 })
	    end
	    projectile:SetAbsOrigin(targetPoint)

	    local explosion_fx = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, projectile)
		ParticleManager:SetParticleControl(explosion_fx, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosion_fx, 1, Vector(radius, radius, radius))
		
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( explosion_fx, false )
			ParticleManager:ReleaseParticleIndex(explosion_fx)
			projectile:RemoveSelf()
		end)
	end)
end