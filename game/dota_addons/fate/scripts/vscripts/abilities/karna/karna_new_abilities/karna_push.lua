
karna_push = class({})

function karna_push:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local pushback_range = self:GetSpecialValueFor("distance")
	local target = self:GetCursorTarget()
	local speed = 1500
	if IsSpellBlocked(target) then return end

		giveUnitDataDrivenModifier(caster, target, "stunned", self:GetSpecialValueFor("stun_duration"))
		DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)


		if not IsKnockbackImmune(target) then
			local casterfacing = caster:GetForwardVector()
			local pushTarget = Physics:Unit(target)
			local casterOrigin = caster:GetAbsOrigin()
			local initialUnitOrigin = target:GetAbsOrigin()
			target:PreventDI()
			target:SetPhysicsFriction(0)
			target:SetPhysicsVelocity(casterfacing:Normalized() * speed)
			target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		    target:OnPhysicsFrame(function(unit) 
				local unitOrigin = unit:GetAbsOrigin()
				local diff = unitOrigin - initialUnitOrigin
				local n_diff = diff:Normalized()
				unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
				if diff:Length() > pushback_range then
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					unit:OnPhysicsFrame(nil)
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
				end
			end)	
			target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
				unit:SetBounceMultiplier(0)
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))

			end)
		end

		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")

end

