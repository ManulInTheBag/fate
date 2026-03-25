LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg", LUA_MODIFIER_MOTION_NONE)
scathach_gait_three = class({})

function scathach_gait_three:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function scathach_gait_three:CastFilterResultLocation(vLocation)
	if IsServer() then
		if GridNav:IsBlocked(vLocation) or not GridNav:IsTraversable(vLocation) then
			return UF_FAIL_INVALID_LOCATION
		end
	end

	return UF_SUCCESS
end

function scathach_gait_three:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function scathach_gait_three:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	
	local point_2 = self:GetCursorPosition()
	local origin_2 = caster:GetOrigin()
	
	local dist = (caster:GetAbsOrigin() - targetPoint):Length2D() * 10/6
	local castRange = self:GetCastRange()
	local damage = self:GetSpecialValueFor("damage") + caster:GetAgility() * self:GetSpecialValueFor("agi_ratio")
	local radius = self:GetSpecialValueFor("radius")
	local agi_scale = self:GetSpecialValueFor("agi_scale")
	caster:RemoveModifierByName("modifier_scathach_gait_three_window")

	-- When you exit the ubw on the last moment, dist is going to be a pretty high number, since the targetPoint is on ubw but you are outside it
	-- If it's, then we can't use it like that. Either cancel Overedge, or use a default one.
	-- 2000 is a fixedNumber, just to check if dist is not valid. Over 2000 is surely wrong. (Max is close to 900)
	if dist > 2000 then
		dist = 600 
	end

	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		damage = damage + caster:GetAgility() * agi_scale
	end
	


	giveUnitDataDrivenModifier(caster, caster, "jump_pause_noinvul", 0.59)
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
	caster:EmitSound("scathach_gait_3")

	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})

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
		local backPoint1 = origin - radius * forwardVec/2.00 + radius * rightVec
		local backPoint2 = origin - radius * forwardVec/2.00 - radius * rightVec 
		local frontPoint1 = origin + radius * forwardVec*2.00 - radius * rightVec 
		local frontPoint2 = origin + radius * forwardVec*2.00 + radius * rightVec 
		backPoint1.z = backPoint1.z + 350
		backPoint2.z = backPoint2.z + 350
		
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
		
		caught = true
		
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
		
		self:PlayEffects1( caught, (point_2-origin_2):Normalized() )
		
--		ScreenShake(caster:GetOrigin(), 2, 0.5, 2, 3000, 0, true)
		
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			v:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
			-- if v:GetMaxMana() > 0 then
			-- 	v:Script_ReduceMana(200, nil)
			-- end
	    end	    
	end
	})
end

--------------------------------------------------------------------------------
-- Play Effects
function scathach_gait_three:PlayEffects1( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/scathach_gait_three_swing.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end