
karna_push = class({})


function karna_push:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_spin_2"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_spin_2"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("karna_recast_dash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_recast_dash"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("karna_spin"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_spin"):SetLevel(self:GetLevel())
    end
end


function karna_push:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local pushback_range = self:GetSpecialValueFor("distance")
	local target = self:GetCursorTarget()
	local speed = 1500
	if IsSpellBlocked(target, caster) then return end

		giveUnitDataDrivenModifier(caster, target, "stunned", self:GetSpecialValueFor("stun_duration"))
		DoDamage(caster, target, damage , self:GetAbilityDamageType(), 0, self, false)


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
		if caster:HasModifier("modifier_hero_selection_skin") then
			local soundQueue = math.random (1,2)
			caster:EmitSound("karna_new_fire_2")
			caster:EmitSound("aemis_mecha_q" .. soundQueue)
		else
			caster:EmitSound("karna_new_fire_2")
			caster:EmitSound("karna_new_karna_hit_2")
		end
end

