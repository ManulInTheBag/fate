kuro_crane_wings = class({})

--[[function kuro_crane_wings:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * self:GetSpecialValueFor("cooldown_reduction") / 100)
	end

	return cooldown
end]]

function kuro_crane_wings:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function kuro_crane_wings:GetManaCost(iLevel)
	return 400
end

function kuro_crane_wings:CastFilterResultLocation(vLocation)
	if IsServer() then
		if GridNav:IsBlocked(vLocation) or not GridNav:IsTraversable(vLocation) then
			return UF_FAIL_INVALID_LOCATION
		end
	end

	return UF_SUCCESS
end

function kuro_crane_wings:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function kuro_crane_wings:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local dist = (caster:GetAbsOrigin() - targetPoint):Length2D() * 10/6
	local castRange = self:GetCastRange()
	local damage = self:GetDamage()
	local radius = self:GetSpecialValueFor("radius")

	-- When you exit the ubw on the last moment, dist is going to be a pretty high number, since the targetPoint is on ubw but you are outside it
	-- If it's, then we can't use it like that. Either cancel Overedge, or use a default one.
	-- 2000 is a fixedNumber, just to check if dist is not valid. Over 2000 is surely wrong. (Max is close to 900)
	if dist > 2000 then
		dist = 600 
	end 

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.59)
    local archer = Physics:Unit(caster)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, 850))
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(false)	
    caster:SetAutoUnstuck(false)
    caster:SetPhysicsAcceleration(Vector(0,0,-2666))

	caster:EmitSound("Hero_PhantomLancer.Doppelwalk")
	EmitGlobalSound("chloe_crane_4")

	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_ATTACK_EVENT, rate=0.8})	

	if caster:HasModifier("modifier_projection_active") then
		damage = damage + self:GetSpecialValueFor("projection_damage")		
		caster:RemoveModifierByName("modifier_projection_active")
	end

	caster:RemoveModifierByName("modifier_kuro_crane_tracker")

	if caster:HasModifier("modifier_kuro_overedge") then
		self:FireExtraSwords(targetPoint, radius)
	end

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
		local backPoint1 = origin - radius * forwardVec + radius * rightVec
		local backPoint2 = origin - radius * forwardVec - radius * rightVec
		local frontPoint1 = origin + radius * forwardVec - radius * rightVec
		local frontPoint2 = origin + radius * forwardVec + radius * rightVec
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
		ParticleManager:SetParticleControl( stompParticleIndex, 1, Vector( radius, radius, radius ) )
		
		-- Destroy particle
		Timers:CreateTimer( 1.0, function()
			ParticleManager:DestroyParticle( slash1ParticleIndex, false )
			ParticleManager:DestroyParticle( slash2ParticleIndex, false )
			ParticleManager:DestroyParticle( stompParticleIndex, false )
			ParticleManager:ReleaseParticleIndex( slash1ParticleIndex )
			ParticleManager:ReleaseParticleIndex( slash2ParticleIndex )
			ParticleManager:ReleaseParticleIndex( stompParticleIndex )
		end)
		
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	         DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end	    
	end
	})
end

function kuro_crane_wings:FireExtraSwords(targetPoint, radius)
	local caster = self:GetCaster()
	--print("firing extra swords")
	--if not caster:HasModifier("modifier_overedge_charge") then return end

	local targetCandidates = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	--local charge = self:GetCaster():FindModifierByName("modifier_overedge_charge"):GetStackCount()
	local kbAbility = caster:FindAbilityByName("kuro_kanshou_byakuya")

	if #targetCandidates >= 1 then
		local target = targetCandidates[1]

		for i = 1, 4 do
			targetPoint = targetPoint + RandomVector(500)
			local dummy = CreateUnitByName("dummy_unit", targetPoint, false, nil, nil, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

			Timers:CreateTimer(2, function()
				dummy:RemoveSelf()
			end)

			local projectileSpeed = (targetPoint - target:GetAbsOrigin()):Length2D() / 0.55
			local info = {
				Target = target, 
				Source = dummy,
				Ability = kbAbility,
				EffectName = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
				vSpawnOrigin = dummy:GetAbsOrigin(),
				iMoveSpeed = projectileSpeed,
				bDodgeable = true,
				ExtraData = { grant_charges = false }
			}
			ProjectileManager:CreateTrackingProjectile(info) 
		end
	end

	--caster:RemoveModifierByName("modifier_overedge_charge")
end

function kuro_crane_wings:GetDamage()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("atk_ratio") / 100

	return damage
end