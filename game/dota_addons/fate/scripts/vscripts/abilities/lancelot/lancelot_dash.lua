lancelot_dash = class({})


function lancelot_dash:OnSpellStart()
	local caster = self:GetCaster()
	Timers:RemoveTimer("lancelot_dash")
	local ability = self

	local speed = self:GetSpecialValueFor("speed")
	local point  = self:GetCursorPosition()+caster:GetForwardVector()
	local direction      = (point - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local dist = self:GetSpecialValueFor("distance")
	local casted_dist = (point - caster:GetAbsOrigin()):Length2D()
	if (casted_dist > dist )then
		point = caster:GetAbsOrigin() + (((point - caster:GetAbsOrigin()):Normalized()) * dist)
		casted_dist = dist
	end
	local sin = Physics:Unit(caster)
	
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(direction * speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
	local dash_time =  casted_dist/ speed
	local minigun_mod = caster:FindModifierByName("modifier_lancelot_minigun")
	if IsNotNull(minigun_mod) then
		minigun_mod.fSlowTurning = 100
	end
	--StartAnimation(caster, {duration= dash_time , activity=ACT_DOTA_CAST_ABILITY_2, rate= 25/(dash_time*30)})
	Timers:CreateTimer("lancelot_dash", {
		endTime = dash_time ,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		local minigun_mod = caster:FindModifierByName("modifier_lancelot_minigun")
		if IsNotNull(minigun_mod) then
			minigun_mod.fSlowTurning = -100
		end
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("lancelot_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		local minigun_mod = caster:FindModifierByName("modifier_lancelot_minigun")
		if IsNotNull(minigun_mod) then
			minigun_mod.fSlowTurning = -100
		end
	end)
end
