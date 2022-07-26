tamamo_castration_fist = class({})

LinkLuaModifier("modifier_polygamist_cooldown", "abilities/tamamo/modifiers/modifier_polygamist_cooldown", LUA_MODIFIER_MOTION_NONE)

local femaleservant = {
    "npc_dota_hero_legion_commander",
    "npc_dota_hero_spectre",
    "npc_dota_hero_templar_assassin",
    "npc_dota_hero_crystal_maiden",
    "npc_dota_hero_lina",
    "npc_dota_hero_enchantress",
    "npc_dota_hero_mirana",
    "npc_dota_hero_windrunner",
    "npc_dota_hero_drow_ranger",
    "npc_dota_hero_phantom_assassin",
}

function tamamo_castration_fist:GetCastRange(vLocation, hTarget)	
	return self:GetSpecialValueFor("range")
end

function tamamo_castration_fist:CastFilterResultTarget(hTarget)	
    local target_flag = DOTA_UNIT_TARGET_FLAG_NONE

	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, target_flag, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function tamamo_castration_fist:GetCustomCastErrorTarget(hTarget)
	return "#Invalid_Target"
end

function tamamo_castration_fist:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local final_damage = self:GetSpecialValueFor("final_damage")
	local count = 0
	local damage_type = DAMAGE_TYPE_MAGICAL

	caster:AddNewModifier(caster, self, "modifier_polygamist_cooldown", { Duration = self:GetCooldown(1) })
	caster:EmitSound("tamamo_castration_fist_1")
	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.25)

	if not IsFemaleServant(target) then
		damage = damage * (100 + self:GetSpecialValueFor("male_bonus"))/100
		final_damage = final_damage * (100 + self:GetSpecialValueFor("male_bonus"))/100
		damage_type = DAMAGE_TYPE_MAGICAL
	end

	local original_forward_vector = caster:GetForwardVector()
	local face_target = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()

	caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,45,0), caster:GetForwardVector()))

	Timers:CreateTimer(function()
		if count == 2 and caster:IsAlive() and target:IsAlive() then 
			-- Do knockback
			target:AddNewModifier(caster, caster, "modifier_stunned", { Duration = 0.7 })
			target:EmitSound("Tamamo_Kick_Sfx")
			local forward = caster:GetForwardVector()
			local backwards = forward * -1

			local tama = Physics:Unit(caster)
			caster:SetPhysicsFriction(0)
			caster:SetPhysicsVelocity(backwards * 400)
			caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

			local target_phys = Physics:Unit(target)
			target:SetPhysicsFriction(0)
			target:SetPhysicsVelocity(forward * 800)
			target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

			Timers:CreateTimer("tamamo_back_jump", {
				endTime = 0.4,
				callback = function()
				caster:OnPreBounce(nil)
				caster:SetBounceMultiplier(0)
				caster:PreventDI(false)
				caster:SetPhysicsVelocity(Vector(0,0,0))
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				return 
			end})

			Timers:CreateTimer("kick_target_backjump", {
				endTime = 0.4,
				callback = function()
				target:OnPreBounce(nil)
				target:SetBounceMultiplier(0)
				target:PreventDI(false)
				target:SetPhysicsVelocity(Vector(0,0,0))
				FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
				return 
			end})

			caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
				Timers:RemoveTimer("tamamo_back_jump")
				unit:OnPreBounce(nil)
				unit:SetBounceMultiplier(0)
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end)

			target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
				Timers:RemoveTimer("kick_target_backjump")
				unit:OnPreBounce(nil)
				unit:SetBounceMultiplier(0)
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end)

			local dur = 0
			Timers:CreateTimer(0.4, function()				
				local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, target )
				ParticleManager:SetParticleControl( explodeFx1, 0, target:GetAbsOrigin())
				local explodeFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
				ParticleManager:SetParticleControl( explodeFx2, 0, target:GetAbsOrigin())
				target:EmitSound("Ability.LightStrikeArray")
				caster:SetForwardVector(original_forward_vector)

				DoDamage(caster, target, final_damage, damage_type, 0, ability, false)
				return 
			end)
			
			return 
		elseif not caster:IsAlive() or not target:IsAlive() then
			caster:SetForwardVector(original_forward_vector)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			return
		end

		if caster:IsAlive() and target:IsAlive() then
			target:AddNewModifier(caster, caster, "modifier_stunned", { Duration = 0.1 })
			local trailFxIndex = ParticleManager:CreateParticle("particles/custom/tamamo/tamamo_kick_trail.vpcf", PATTACH_CUSTOMORIGIN, target )
			ParticleManager:SetParticleControl( trailFxIndex, 1, target:GetAbsOrigin() )
			StartAnimation(caster, {duration=0.35, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.75})		
			
			caster:SetAbsOrigin(target:GetAbsOrigin() + RandomVector(100))
			caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,90,0), caster:GetForwardVector()))
			DoDamage(caster, target, damage, damage_type, 0, ability, false)
			target:EmitSound("Tamamo_Kick_Sfx")
			
			ParticleManager:SetParticleControl( trailFxIndex, 0, target:GetAbsOrigin() )
			--local splashFx = ParticleManager:CreateParticle("particles/custom/screen_violet_splash.vpcf", PATTACH_EYES_FOLLOW, caster)					
		end
		
		count = count + 1
		return 0.4 
	end)
end

function tamamo_castration_fist:OnHeroLevelUp()
	local caster = self:GetCaster()

	if caster.IsCastrationFistAcquired then
		if caster:GetLevel() < 8 then
			self:SetLevel(1)
		elseif caster:GetLevel() >= 8 and caster:GetLevel() < 16 then
			self:SetLevel(2)
		elseif caster:GetLevel() >= 16 then
			self:SetLevel(3)
		end
	end
end