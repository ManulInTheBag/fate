emiya_crane_wings = class({})

function emiya_crane_wings:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function emiya_crane_wings:GetManaCost(iLevel)
	local caster = self:GetCaster()
	local charge = 0
	if caster:HasModifier("modifier_overedge_charge") then
		charge = caster:GetModifierStackCount("modifier_overedge_charge", caster)
	end

	return 400 - (charge * 50)	
end

function emiya_crane_wings:CastFilterResultLocation(vLocation)
	if IsServer() then
		if GridNav:IsBlocked(vLocation) or not GridNav:IsTraversable(vLocation) then
			return UF_FAIL_INVALID_LOCATION
		end
	end

	return UF_SUCCESS
end

function emiya_crane_wings:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function emiya_crane_wings:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local dist = (caster:GetAbsOrigin() - targetPoint):Length2D() * 10/6
	local castRange = self:GetCastRange()
	local damage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("atk_ratio") / 100
	local radius = self:GetSpecialValueFor("radius")
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true    then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_e"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	-- When you exit the ubw on the last moment, dist is going to be a pretty high number, since the targetPoint is on ubw but you are outside it
	-- If it's, then we can't use it like that. Either cancel Overedge, or use a default one.
	-- 2000 is a fixedNumber, just to check if dist is not valid. Over 2000 is surely wrong. (Max is close to 900)
	if dist > 2000 then
		dist = 600 
	end

	caster:RemoveModifierByName("modifier_ubw_chant_count")

	giveUnitDataDrivenModifier(caster, caster, "stunned", 0.59)
    local archer = Physics:Unit(caster)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, 850))
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(false)	
    caster:SetAutoUnstuck(false)
    caster:SetPhysicsAcceleration(Vector(0,0,-2666))

    local soundQueue = math.random(2,3)

	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	caster:EmitSound("Emiya_Crane" .. soundQueue)

	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_ATTACK, rate=0.8})

	if caster:HasModifier("modifier_overedge_attribute") then
		self:FireExtraSwords(targetPoint, radius)
	end

	local stacks = 0	

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
			end
		)
		
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	         DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end	    
	end
	})
end

function emiya_crane_wings:FireExtraSwords(targetPoint, radius)
	local caster = self:GetCaster()
	--print("firing extra swords")
	if not caster:HasModifier("modifier_overedge_charge") then return end

	local targetCandidates = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	local charge = self:GetCaster():FindModifierByName("modifier_overedge_charge"):GetStackCount()
	local kbAbility = caster:FindAbilityByName("emiya_kanshou_byakuya")

	if #targetCandidates >= 1 then
		local target = targetCandidates[1]

		for i = 1, charge do
			targetPoint = targetPoint + RandomVector(500)
			local dummy = CreateUnitByName("dummy_unit", targetPoint, false, nil, nil, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

			Timers:CreateTimer(2, function()
				dummy:RemoveSelf()
			end)

			local projectileSpeed = (targetPoint - target:GetAbsOrigin()):Length2D() / 0.55
			local effectName = "particles/custom/archer/emiya_kb_swords_left.vpcf"
			if(i == 2 or i == 4 or i == 6) then
				effectName = "particles/custom/archer/emiya_kb_swords_right.vpcf"
			
			end 
			local info = {
				Target = target, 
				Source = dummy,
				Ability = kbAbility,
				EffectName = effectName,
				vSpawnOrigin = dummy:GetAbsOrigin(),
				iMoveSpeed = projectileSpeed,
				bDodgeable = true,
				ExtraData = { grant_charges = false }
			}
			ProjectileManager:CreateTrackingProjectile(info) 
		end
	end

	caster:RemoveModifierByName("modifier_overedge_charge")
end

function emiya_crane_wings:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	print("its triggering from crane wings 4head")
	local caster = self:GetCaster()
	local kbAbility = caster:FindAbilityByName("emiya_kanshou_byakuya")

	local KBHitFx = ParticleManager:CreateParticle("particles/econ/courier/courier_mechjaw/mechjaw_death_sparks.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(KBHitFx, 0, hTarget:GetAbsOrigin()) 
	-- Destroy particle after delay
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle( KBHitFx, false )
		ParticleManager:ReleaseParticleIndex( KBHitFx )
	end)

	DoDamage(caster, hTarget, kbAbility:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
	hTarget:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
end