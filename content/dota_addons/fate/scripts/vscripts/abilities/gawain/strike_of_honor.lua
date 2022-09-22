function OnOveredgeStart(keys)
	local caster = keys.caster 
	local ability = keys.ability
	local targetPoint = keys.target:GetAbsOrigin()
	local dist = (caster:GetAbsOrigin() - targetPoint):Length2D() * 10/6
	local castRange = keys.castRange

	-- When you exit the ubw on the last moment, dist is going to be a pretty high number, since the targetPoint is on ubw but you are outside it
	-- If it's, then we can't use it like that. Either cancel Overedge, or use a default one.
	-- 2000 is a fixedNumber, just to check if dist is not valid. Over 2000 is surely wrong. (Max is close to 900)
	if dist > 2000 then
		dist = 500 --Default one
		--[[keys.ability:EndCooldown() --Cancel overedge
		caster:GiveMana(600) 
		return--]]
	end

	if GridNav:IsBlocked(targetPoint) or not GridNav:IsTraversable(targetPoint) then
		keys.ability:EndCooldown() 
		caster:GiveMana(600) 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Travel")
		return 
	end 
	--caster.OveredgeCount = -1
	--caster:RemoveModifierByName("modifier_overedge_stack")
	--keys.ability:SetActivated(false)
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_overedge_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.59)
    local archer = Physics:Unit(caster)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, 800))
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(false)	
    caster:SetAutoUnstuck(false)
    caster:SetPhysicsAcceleration(Vector(0,0,-2666))

	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_ATTACK_EVENT, rate=0.8})
	--[[ability:ApplyDataDrivenModifier(caster, caster, "modifier_overedge_anim", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_overedge_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	caster:RemoveModifierByName("modifier_overedge_stack") ]]


	Timers:CreateTimer({
		endTime = 0.6,
		callback = function()
		caster:EmitSound("Hero_Centaur.DoubleEdge") 
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetAutoUnstuck(true)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

		-- Create particles
		-- Variable for cross slash
		local origin = caster:GetAbsOrigin()
		local forwardVec = caster:GetForwardVector()
		local rightVec = caster:GetRightVector()
		local backPoint1 = origin - keys.Radius * forwardVec + keys.Radius * rightVec
		local backPoint2 = origin - keys.Radius * forwardVec - keys.Radius * rightVec
		local frontPoint1 = origin + keys.Radius * forwardVec - keys.Radius * rightVec
		local frontPoint2 = origin + keys.Radius * forwardVec + keys.Radius * rightVec
		backPoint1.z = backPoint1.z + 250
		backPoint2.z = backPoint2.z + 250
		
		-- Cross slash
		local slash1ParticleIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_overedge_slash.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( slash1ParticleIndex, 2, backPoint1 )
		ParticleManager:SetParticleControl( slash1ParticleIndex, 3, frontPoint1 )
		
		local slash2ParticleIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_overedge_slash.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( slash2ParticleIndex, 2, backPoint2 )
		ParticleManager:SetParticleControl( slash2ParticleIndex, 3, frontPoint2 )
		
		-- Stomp
		local stompParticleIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( stompParticleIndex, 0, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControl( stompParticleIndex, 1, Vector( keys.Radius, keys.Radius, keys.Radius ) )
		
		-- Destroy particle
		Timers:CreateTimer( 1.0, function()
				ParticleManager:DestroyParticle( slash1ParticleIndex, false )
				ParticleManager:DestroyParticle( slash2ParticleIndex, false )
				ParticleManager:DestroyParticle( stompParticleIndex, false )
				ParticleManager:ReleaseParticleIndex( slash1ParticleIndex )
				ParticleManager:ReleaseParticleIndex( slash2ParticleIndex )
				ParticleManager:ReleaseParticleIndex( stompParticleIndex )
			end
		)
		
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

        local knockBackUnits = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false )
	 
		local modifierKnockback =
		{
			center_x = target:GetAbsOrigin().x,
			center_y = target:GetAbsOrigin().y,
			center_z = target:GetAbsOrigin().z,
			duration = 0.5,
			knockback_duration = 0.5,
			knockback_distance = 200,
			knockback_height = 200,
		}

		for _,unit in pairs(knockBackUnits) do
	--		print( "knock back unit: " .. unit:GetName() )
			unit:AddNewModifier( unit, nil, "modifier_knockback", modifierKnockback );
		end
        
		for k,v in pairs(targets) do
	         --DoDamage(caster, v, 700 + 20 * caster:GetIntellect() , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	         DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	    end
	end
	})
end