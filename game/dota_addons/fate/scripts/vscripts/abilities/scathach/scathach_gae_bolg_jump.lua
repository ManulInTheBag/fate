scathach_gae_bolg_jump = class({})

LinkLuaModifier("modifier_self_disarm", "abilities/cu_chulain/modifiers/modifier_self_disarm", LUA_MODIFIER_MOTION_NONE)

function scathach_gae_bolg_jump:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function scathach_gae_bolg_jump:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()
	local cast_range = self:GetSpecialValueFor("cast_range")

	if caster:HasModifier("modifier_scathach_branches_of_tonelico_attribute") then
		cast_range = cast_range + self:GetSpecialValueFor("bonus_range")
	end

	return cast_range
end

function scathach_gae_bolg_jump:CastFilterResultLocation(vLocation)
	local caster = self:GetCaster()

	if not caster:IsDisarmed() then 
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function scathach_gae_bolg_jump:GetCustomCastErrorLocation(vLocation)
	return "#Disarmed"
end

function scathach_gae_bolg_jump:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle( self.GBCastFx, true )

	return true
end

function scathach_gae_bolg_jump:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	self.GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(self.GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	
	return true
end

function scathach_gae_bolg_jump:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectileSpeed = 2500
	local ply = caster:GetPlayerOwner()
	local ascendCount = 0
	local descendCount = 0
	
	EmitGlobalSound("Scathach.Gae_Bolg_Alternative")
	
	Timers:CreateTimer( 1.0, function()
		ParticleManager:DestroyParticle( self.GBCastFx, false )
	end)
	
	StartAnimation(caster, {duration=1.215, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})

	--EmitGlobalSound("archer_attack_03")
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.8)
	Timers:CreateTimer(0.8, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postdelay", 0.15)
	end)
	Timers:CreateTimer(0.95, function()
		giveUnitDataDrivenModifier(caster, caster, "jump_pause_postlock", 0.2)
	end)
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_gae_jump_throw_anim", {}) 

	Timers:CreateTimer('gb_throw_scathach', {
		endTime = 0.35,
		callback = function()
			caster:SetBodygroup(0,1)
		local projectileOrigin = caster:GetAbsOrigin() + Vector(0,0,300)
		local projectile_scathach = CreateUnitByName("dummy_unit", projectileOrigin, false, caster, caster, caster:GetTeamNumber())
		projectile_scathach:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		projectile_scathach:SetAbsOrigin(projectileOrigin)

		local particle_name_scathach = "particles/custom/cu_chulainn/gae_bolg_jump.vpcf"
		local throw_particle_scathach = ParticleManager:CreateParticle(particle_name_scathach, PATTACH_ABSORIGIN_FOLLOW, projectile_scathach)
		ParticleManager:SetParticleControl(throw_particle_scathach, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)

		caster:AddNewModifier(caster, self, "modifier_self_disarm", { Duration = 3 })

		local travelTime = (targetPoint - projectileOrigin):Length() / projectileSpeed
		Timers:CreateTimer(travelTime, function()
			ParticleManager:DestroyParticle(throw_particle_scathach, false)
			self:OnGaeBolgHit(targetPoint, projectile_scathach)
		end)
	end
	})

	Timers:CreateTimer('gb_scathach_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 then 	   		
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+75))
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	Timers:CreateTimer("gb_scathach_descend", {
	    endTime = 0.3,
	    callback = function()
	    	if descendCount == 15 then return end
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-75))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})
end

function scathach_gae_bolg_jump:OnGaeBolgHit(position, projectile_scathach)
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

	if caster:HasModifier("modifier_scathach_branches_of_tonelico_attribute") then
		damage = damage + 300
	end
	
	if caster:HasModifier("modifier_scathach_pinning_god_attribute") then
		damage = damage + (caster:GetAgility()*3)
	end

	Timers:CreateTimer(0.15, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stun_duration})
	        v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback )
	    end
	    projectile_scathach:SetAbsOrigin(targetPoint)
	    local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf", PATTACH_ABSORIGIN, projectile_scathach)
		local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile_scathach)
		local explodeFx1 = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_ABSORIGIN, projectile_scathach )
		ParticleManager:SetParticleControl( fire, 0, projectile_scathach:GetAbsOrigin())
		ParticleManager:SetParticleControl( crack, 0, projectile_scathach:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, projectile_scathach:GetAbsOrigin())
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
		caster:EmitSound("Misc.Crash")
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( fire, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
			-- projectile_scathach also anchors the explosion fx above; remove it here
			-- so the invisible dummy does not linger forever (guarded per stale-handle rule)
			if IsNotNull( projectile_scathach ) then projectile_scathach:RemoveSelf() end
		end)
	end)

	Timers:CreateTimer(0.75, function()
		local hCaster = self:GetCaster()
		self.Dummy = CreateUnitByName("dummy_unit_ground", targetPoint, false, hCaster, hCaster, hCaster:GetTeamNumber())
		self.Dummy:FindAbilityByName("dummy_unit_passive_no_fly"):SetLevel(1)

	    local tProjectile = {
	        Target = hCaster,
	        Source = self.Dummy,
	        Ability = self,
	        EffectName = "particles/custom/lancer/soaring/spear.vpcf",
	        iMoveSpeed = 3000,
	        vSourceLoc = self.Dummy:GetAbsOrigin(),
	        bDodgeable = false,
	        flExpireTime = GameRules:GetGameTime() + 10,
	        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    }

	    ProjectileManager:CreateTrackingProjectile(tProjectile)
	end)	
end

function scathach_gae_bolg_jump:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
	self:GetCaster():SetBodygroup(0,0)
	StartAnimation(self:GetCaster(), {duration=0.5, activity=ACT_DOTA_RAZE_1, rate=1})
	hTarget:RemoveModifierByName("modifier_self_disarm")
	self:GetCaster():EmitSound("cu_chulain_gae_bolg_retrieve")
	self.Dummy:RemoveSelf()
end