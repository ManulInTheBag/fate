kuro_barrage_moonwalk = class({})

function kuro_barrage_moonwalk:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * self:GetSpecialValueFor("cooldown_reduction") / 100)
	end

	return cooldown
end

function kuro_barrage_moonwalk:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local retreatDist = self:GetSpecialValueFor("retreat_distance")
	local forwardVec = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")
	local interval = range/6
	local casterPos = caster:GetAbsOrigin()
	local counter  = 1
	local archer = Physics:Unit(caster)

	ProjectileManager:ProjectileDodge(caster)

	caster:PreventDI()
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(-forwardVec * retreatDist * 4/2 + Vector(0,0,750))
	caster:SetPhysicsAcceleration(Vector(0,0,-2000))
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	caster:FollowNavMesh(false)

  	Timers:CreateTimer(0.5, function()
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.2)

	caster:EmitSound("chloe_moonwalk")

	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_ATTACK, rate=1.0})
	rotateCounter = 1
	
	Timers:CreateTimer(function()
		if rotateCounter == 9 then return end
		caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,45*rotateCounter,0), forwardVec))
		rotateCounter = rotateCounter + 1
		return 0.03
	end)

	Timers:CreateTimer(function()
		if counter > 6 then return end
		local targetPoint = casterPos + forwardVec * interval * counter
		local swordOrigin = casterPos - forwardVec * retreatDist + RandomVector(250) + Vector(0,0,500)
		local swordVector = (targetPoint - swordOrigin):Normalized()
		
		local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_model.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( swordFxIndex, 0, swordOrigin )
		ParticleManager:SetParticleControl( swordFxIndex, 1, swordVector*3000 )

		Timers:CreateTimer(0.25, function()
			local targets = FindUnitsInRadius(caster:GetTeamNumber(), targetPoint, caster, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)
			for k,v in pairs(targets) do				
				DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
				giveUnitDataDrivenModifier(caster, v, "stunned", 0.1)
			end
			-- Particles on impact
			local explosionFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( explosionFxIndex, 0, targetPoint )
			
			local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint )
			ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(200,200,200))
		end)
		counter = counter+1
		return 0.1
	end)
end