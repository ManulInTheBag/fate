nobu_dash = class({})
LinkLuaModifier("modifier_nobu_turnrate", "abilities/nobu/nobu_dash", LUA_MODIFIER_MOTION_NONE)


function nobu_dash:OnSpellStart()
	local caster = self:GetCaster()
	Timers:RemoveTimer("nobu_dash")
	if(self:GetCurrentAbilityCharges() > 0) then
		self:EndCooldown()
		self:StartCooldown(0.5)
	end
	local ability = self
	caster:RemoveModifierByName("modifier_nobu_strategy_attribute_cooldown")
	caster.IsStrategyReady = true
	local speed = 1200
	local point  = self:GetCursorPosition()+caster:GetForwardVector()
	local direction      = (point - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local dist = 400--self:GetSpecialValueFor("dist")
	local casted_dist = (point - caster:GetAbsOrigin()):Length2D()
	if (casted_dist > dist )then
		point = caster:GetAbsOrigin() + (((point - caster:GetAbsOrigin()):Normalized()) * dist)
		casted_dist = dist
	end
	local sin = Physics:Unit(caster)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and caster:GetAbilityByIndex(3):GetName() ~= "nobu_combo"then      
    	if caster:FindAbilityByName("nobu_combo"):IsCooldownReady()  then
             
    		caster:SwapAbilities("nobu_guns", "nobu_combo", false, true)

    		Timers:CreateTimer('nobu_window',{
		        endTime = 2,
		        callback = function()
		        if caster:GetAbilityByIndex(3):GetName() ~= "nobu_guns"  then
					caster:SwapAbilities("nobu_combo", "nobu_guns", false, true)
		       	end
		    end
		    })
 
        end
    end
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(direction * speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
	local dash_time =  casted_dist/ speed
	caster:AddNewModifier(caster, self, "modifier_nobu_turnrate", {duration = dash_time} )
	if not caster:HasModifier("modifier_nobu_turnlock") then
		StartAnimation(caster, {duration= dash_time , activity=ACT_DOTA_CAST_ABILITY_2, rate= 25/(dash_time*30)})
	end
	Timers:CreateTimer("nobu_dash", {
		endTime = dash_time ,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("nobu_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
 
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end

 
modifier_nobu_turnrate = class({})

function modifier_nobu_turnrate:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE, }
							
end



function modifier_nobu_turnrate:IsHidden() return true end
function modifier_nobu_turnrate:RemoveOnDeath() return true end
function modifier_nobu_turnrate:IsDebuff() return false end


function modifier_nobu_turnrate:GetModifierTurnRate_Percentage()
	return 100


end

