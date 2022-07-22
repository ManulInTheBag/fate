modifier_nss_knockback_stun = class({})

LinkLuaModifier("modifier_nss_knockback_revoke", "abilities/lishuwen/modifiers/modifier_nss_knockback_revoke.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nss_knockback_stun:OnCreated(keys)	
	self.StunDuration = keys.StunDuration
	self.RevokeDuration = keys.RevokeDuration
	self.Damage = keys.Damage
	self.AreaOfEffect = keys.AreaOfEffect
	self.KnockbackDistance = keys.KnockbackDistance
	self.PerformKnockback = keys.PerformKnockback

	print("Knockback created")
	--[[if keys.PerformKnockback then
		self:StartIntervalThink(0.1)
	end]]
end

function modifier_nss_knockback_stun:OnUnitMoved()
	if self.PerformKnockback then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.AreaOfEffect, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

		--local modifierKnockback = {}

		print("unit moved, checking knockback")
		for k,v in pairs(targets) do  
			if not v:HasModifier("modifier_nss_knockback_stun") then
				local pushTarget = Physics:Unit(target)
			    target:PreventDI()
				target:SetPhysicsFriction(0)
				local vectorC = (target:GetAbsOrigin() - caster:GetAbsOrigin()) + Vector(0, 0, self.KnockbackDistance) --knockback in direction as fissure
				-- get the direction where target will be pushed back to
				target:SetPhysicsVelocity(vectorC:Normalized() * 1500)
				target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
				local initialUnitOrigin = target:GetAbsOrigin()
				
				target:OnPhysicsFrame(function(unit) -- pushback distance check
					local unitOrigin = unit:GetAbsOrigin()
					local diff = unitOrigin - initialUnitOrigin
					local n_diff = diff:Normalized()
					unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
					if diff:Length() > self:GetSpecialValueFor("attribute_kb_distance") then -- if pushback distance is over 400, stop it
						unit:PreventDI(false)
						unit:SetPhysicsVelocity(Vector(0,0,0))
						unit:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
					end
				end)
				--[[modifierKnockback = {	center_x = v:GetAbsOrigin().x,
										center_y = v:GetAbsOrigin().y,
										center_z = v:GetAbsOrigin().z,
										duration = self.StunDuration,
										knockback_duration = self.StunDuration,
										knockback_distance = self.KnockbackDistance,
										knockback_height = 25,
									}]]

				DoDamage(caster, v, self.Damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				--[[v:AddNewModifier(v, ability, "modifier_nss_knockback_stun", { Duration = self.StunDuration,
																			  StunDuration = self.StunDuration,
																			  Damage = self.Damage,
																			  AreaOfEffect = self.AreaOfEffect,
																			  KnockbackDistance = self.KnockbackDistance,
																			  PerformKnockback = false })
				v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback)]]
				v:AddNewModifier(caster, ability, "modifier_nss_knockback_revoke", {Duration = self.RevokeDuration })
				v:EmitSound("Hero_Spirit_Breaker.GreaterBash")
			end
		end
	end
end

--[[function modifier_nss_knockback_stun:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self.AreaOfEffect, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

	local modifierKnockback = {}

	for k,v in pairs(targets) do  
		if not v:HasModifier("modifier_nss_knockback_stun") then
			modifierKnockback = {	center_x = v:GetAbsOrigin().x,
									center_y = v:GetAbsOrigin().y,
									center_z = v:GetAbsOrigin().z,
									duration = self.StunDuration,
									knockback_duration = self.StunDuration,
									knockback_distance = self.KnockbackDistance,
									knockback_height = 25,
								}

			DoDamage(caster, v, self.Damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			v:AddNewModifier(v, ability, "modifier_nss_knockback_stun", { Duration = self.StunDuration,
																		  StunDuration = self.StunDuration,
																		  Damage = self.Damage,
																		  AreaOfEffect = self.AreaOfEffect,
																		  KnockbackDistance = self.KnockbackDistance,
																		  PerformKnockback = false })
			v:AddNewModifier(v, nil, "modifier_knockback", modifierKnockback)
			v:AddNewModifier(caster, ability, "modifier_nss_knockback_revoke", {Duration = self.RevokeDuration })
			v:EmitSound("Hero_Spirit_Breaker.GreaterBash")
		end
	end
end]]


function modifier_nss_knockback_stun:IsHidden()
	return false
end

function modifier_nss_knockback_stun:IsDebuff()
	return true
end

function modifier_nss_knockback_stun:RemoveOnDeath()
	return true
end

function modifier_nss_knockback_stun:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nss_knockback_stun:GetTexture()
	return "custom/lishuwen_no_second_strike"
end
