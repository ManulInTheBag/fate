-----------------------------
--    Backflip    --
-----------------------------

robin_backflip = class({})

LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function robin_backflip:OnSpellStart()
	local caster = self:GetCaster()
	local hCaster = self:GetCaster()
	local ability = self

	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectileSpeed = 2500
	
	caster:EmitSound("robin_attack_1")


	local position = self:GetCursorPosition()
	x			= position.x
	y 			= position.y
	z			= position.z
	local casterPos = caster:GetAbsOrigin()
	local origin = caster:GetOrigin()
	local ground_position = GetGroundPosition(Vector(x, y, z), nil)
	local retreatDist = self:GetSpecialValueFor("retreat_distance")
	local afterimage_direction = (caster:GetAbsOrigin() - ground_position):Normalized()
	local forwardVec = caster:GetForwardVector()


	if caster:HasModifier("modifier_robin_independent_action_attribute") then
		retreatDist = retreatDist + 400
		local particle2 = ParticleManager:CreateParticle("particles/zlodemon/dash_start.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControlTransformForward(particle2, 0, caster:GetAbsOrigin(),afterimage_direction )
		ParticleManager:ReleaseParticleIndex(particle2)
	end
	

	local counter  = 1
	local archer = Physics:Unit(caster)

	ProjectileManager:ProjectileDodge(caster)

    local enemy = PickRandomEnemy(caster)
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end
	
    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 2.5 })
    end

	caster:PreventDI()
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(-forwardVec * retreatDist * 2 + Vector(0,0,0))
	caster:SetPhysicsAcceleration(Vector(0,0,0))
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	caster:FollowNavMesh(false)
	
	
	

	
	local particle = ParticleManager:CreateParticle("particles/custom/robin/robin_afterimage_q.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin(),afterimage_direction )
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + afterimage_direction * (retreatDist * 0.9))
	ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetForwardVector(), true)
	ParticleManager:ReleaseParticleIndex(particle)

  	Timers:CreateTimer(0.5, function()
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)

	StartAnimation(caster, {duration=0.74, activity=ACT_DOTA_CAST_ICE_WALL, rate=1.0})

	Timers:CreateTimer('robin_arrow', {
		endTime = 0.225,
		callback = function()
	   	caster:EmitSound("")

		local projectileOrigin = caster:GetAbsOrigin() + Vector(0,150,20)
		local projectile = CreateUnitByName("dummy_unit", projectileOrigin, false, caster, caster, caster:GetTeamNumber())
		projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		projectile:SetAbsOrigin(projectileOrigin)

		local particle_name = "particles/custom/robin/robin_flashbang_arrow.vpcf"
		local throw_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		ParticleManager:SetParticleControl(throw_particle, 1, (targetPoint - projectileOrigin):Normalized() * projectileSpeed)

		local travelTime = (targetPoint - projectileOrigin):Length() / projectileSpeed
		Timers:CreateTimer(travelTime, function()
			ParticleManager:DestroyParticle(throw_particle, false)
			self:OnFlashArrowHit(targetPoint, projectile)
		end)
	end
	})
end

function robin_backflip:OnFlashArrowHit(position, projectile)
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

	if caster:HasModifier("modifier_robin_independent_action_attribute") then
		damage = damage + 200
	end

	Timers:CreateTimer(0.01, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stun_duration})
	        v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback )
	    end
	    projectile:SetAbsOrigin(targetPoint)
		local crack = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf", PATTACH_ABSORIGIN, projectile)
		local explodeFx1 = ParticleManager:CreateParticle("particles/custom/robin/robin_flashbang_aoe.vpcf", PATTACH_ABSORIGIN, projectile )
		ParticleManager:SetParticleControl( crack, 0, projectile:GetAbsOrigin())
		ParticleManager:SetParticleControl( explodeFx1, 0, projectile:GetAbsOrigin())
		ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
		caster:EmitSound("Misc.Crash")
	    Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( crack, false )
			ParticleManager:DestroyParticle( explodeFx1, false )
		end)
	end)
end