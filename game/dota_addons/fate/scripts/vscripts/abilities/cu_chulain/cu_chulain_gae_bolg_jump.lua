cu_chulain_gae_bolg_jump = class({})

LinkLuaModifier("modifier_self_disarm", "abilities/cu_chulain/modifiers/modifier_self_disarm", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_gae_bolg_jump:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function cu_chulain_gae_bolg_jump:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()
	local cast_range = self:GetSpecialValueFor("cast_range")

	if caster:HasModifier("modifier_improve_throw_attribute") then
		cast_range = cast_range + self:GetSpecialValueFor("bonus_range")
	end

	return cast_range
end

function cu_chulain_gae_bolg_jump:CastFilterResultLocation(vLocation)
	local caster = self:GetCaster()

	if not caster:IsDisarmed() then 
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function cu_chulain_gae_bolg_jump:GetCustomCastErrorLocation(vLocation)
	return "#Disarmed"
end

function cu_chulain_gae_bolg_jump:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle( self.GBCastFx, true )
	EndAnimation(caster)
	return true
end

function cu_chulain_gae_bolg_jump:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	self.GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(self.GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_CAST_ABILITY_4, rate=0.7})
	return true
end

function cu_chulain_gae_bolg_jump:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectileSpeed = 2500
	local ply = caster:GetPlayerOwner()
	local ascendCount = 0
	local descendCount = 0	

	EmitGlobalSound("lancer_gae_bolg_2")
	self.oldfw = caster:GetForwardVector()
	local newfw = -(caster:GetAbsOrigin() - targetPoint):Normalized()
	--newfw.z =
	caster:SetForwardVector(newfw)
	caster:FaceTowards(targetPoint)
	local distance = (caster:GetAbsOrigin() - targetPoint):Length2D()
	Timers:CreateTimer( 0.1, function()
		ParticleManager:DestroyParticle( self.GBCastFx, true )
		ParticleManager:ReleaseParticleIndex(self.GBCastFx)
	end)

	--EmitGlobalSound("archer_attack_03")
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1)
	Timers:CreateTimer(3, function()
		caster:SetBodygroup(0,0)
	
	end)
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_gae_jump_throw_anim", {}) 

	Timers:CreateTimer('gb_throw', {
		endTime = 0.6,
		callback = function()
			caster:SetBodygroup(0,1)
		local projectileOrigin = caster:GetAbsOrigin() + Vector(0,0,300)
		local projectile = CreateUnitByName("dummy_unit", projectileOrigin, false, nil, nil, caster:GetTeamNumber())
		projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		projectile:SetAbsOrigin(projectileOrigin)

		local particle_name = "particles/cu_chulain/gae_bolg_proj.vpcf"
		local throw_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		ParticleManager:SetParticleControl(throw_particle, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)

		caster:AddNewModifier(caster, self, "modifier_self_disarm", { Duration = 3 })
		EndAnimation(caster)
		caster:SetForwardVector(self.oldfw)
		StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1})
		local travelTime = (targetPoint - projectileOrigin):Length() / projectileSpeed
		Timers:CreateTimer(travelTime-0.1, function()
			ParticleManager:DestroyParticle(throw_particle, false)
			self:OnGaeBolgHit(targetPoint, projectile)
		end)
	end
	})
	local shift_vector = Vector(0,0,0)
	if distance < 500 then 
		shift_vector = newfw * (500 -distance)/15
	end

	Timers:CreateTimer('gb_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 then 	  
	
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+50) - shift_vector)
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	Timers:CreateTimer("gb_descend", {
	    endTime = 0.6,
	    callback = function()
	    	if descendCount == 15 then 
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true) 	return 
			end
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-50))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})
end

function cu_chulain_gae_bolg_jump:OnGaeBolgHit(position, projectile)
	local caster = self:GetCaster()
	local targetPoint = position
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	
	local stun_duration = 0.5

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

	if caster:HasModifier("modifier_improve_throw_attribute") then
		damage = damage + 100 + caster:GetAgility()*self:GetSpecialValueFor("damage_per_agi")
	end

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
			ParticleManager:ReleaseParticleIndex( explodeFx1 )
			ParticleManager:ReleaseParticleIndex( fire )
			ParticleManager:ReleaseParticleIndex( crack )
			projectile:RemoveSelf()
		end)
	end)

	Timers:CreateTimer(0.75, function()
		local hCaster = self:GetCaster()
		hCaster.gbDummy = CreateUnitByName("dummy_unit_ground", targetPoint, false, nil, nil, hCaster:GetTeamNumber())
		hCaster.gbDummy:FindAbilityByName("dummy_unit_passive_no_fly"):SetLevel(1)

	    local tProjectile = {
	        Target = hCaster,
	        Source = hCaster.gbDummy,
	        Ability = self,
	        level = 0,
	        EffectName = "particles/custom/lancer/soaring/spear.vpcf",
	        iMoveSpeed = 3000,
	        vSourceLoc = hCaster.gbDummy:GetAbsOrigin(),
	        bDodgeable = false,
	        flExpireTime = GameRules:GetGameTime() + 10,
	        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    }

	    hCaster.gbProjectile = FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
	end)	
end

function cu_chulain_gae_bolg_jump:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	local caster = self:GetCaster()
	caster:SetBodygroup(0,0)
	hTarget:RemoveModifierByName("modifier_self_disarm")
	caster.gbDummy:RemoveSelf()
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START, rate=2})
	caster:EmitSound("cu_chulain_gae_bolg_retrieve")
	Timers:CreateTimer(0.033,function()
		ProjectileManager:DestroyLinearProjectile(caster.gbProjectile)
   end)
	return true
end