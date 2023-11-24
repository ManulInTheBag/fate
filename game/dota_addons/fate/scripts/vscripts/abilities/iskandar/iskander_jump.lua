LinkLuaModifier("modifier_iskander_jump", "abilities/iskandar/iskander_jump", LUA_MODIFIER_MOTION_HORIZONTAL)

iskander_jump = class({})

function iskander_jump:OnSpellStart()
	local caster = self:GetCaster()
    local speed = self:GetSpecialValueFor("speed")
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.75)
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
    caster.IsRiding = false
	local point = self:GetCursorPosition()
	local vector = (caster:GetAbsOrigin() - point)
	local norm = vector:Normalized()
	local distance = vector:Length2D()
	local max_distance = speed * 0.75
	if distance > max_distance then distance = max_distance end
	caster:SetForwardVector(-norm)
	speed = distance/0.75
	caster:SetPhysicsVelocity(-norm * speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    StartAnimation(caster, {duration = 0.75, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
	Timers:CreateTimer("kander_dash", {
		endTime = 0.75,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
        caster:RemoveModifierByName("modifier_iskandar_buc")
        self:DealJumpDmg( caster:GetAbsOrigin())
	return end
	})

	caster:OnPreBounce(function(unit, normal) 
		Timers:RemoveTimer("kander_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
        caster:RemoveModifierByName("modifier_iskandar_buc")
        self:DealJumpDmg( caster:GetAbsOrigin())
	end)
end

function iskander_jump:DealJumpDmg(point)
   local dmg = self:GetSpecialValueFor("damage")
   local caster = self:GetCaster()
   local aoe = self:GetSpecialValueFor("radius")
   local fx = ParticleManager:CreateParticle("particles/custom/astolfo/hippogrif_ride/astolfo_hippogriff_ride_thunderderstrike_aoe_area.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
   ParticleManager:SetParticleControl(fx, 1, caster:GetAbsOrigin())
   ParticleManager:SetParticleControl(fx, 2, caster:GetAbsOrigin())
   Timers:CreateTimer( 1.0, function()
       ParticleManager:DestroyParticle( fx, false )
       ParticleManager:ReleaseParticleIndex( fx )
   end)
   local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
						point,
                        nil,
                        aoe,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     	for _,enemy in pairs(enemies) do
			DoDamage(caster, enemy, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
			giveUnitDataDrivenModifier(caster, enemy, "stunned", self:GetSpecialValueFor("duration"))
       	end
           giveUnitDataDrivenModifier(caster, caster, "stunned", 0.5)    
           StartAnimation(caster, {duration = 0.5, activity=ACT_DOTA_DISABLED, rate=1})
           EmitSoundOnLocationWithCaster(point, "Hero_Leshrac.Split_Earth", caster)
end

function iskander_jump:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end




