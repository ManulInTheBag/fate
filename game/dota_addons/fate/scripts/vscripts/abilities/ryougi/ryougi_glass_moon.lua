LinkLuaModifier("modifier_ryougi_glass_moon", "abilities/ryougi/ryougi_glass_moon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_glass_moon_2", "abilities/ryougi/ryougi_glass_moon", LUA_MODIFIER_MOTION_NONE)

ryougi_glass_moon = class({})

function ryougi_glass_moon:GetBehavior()
    if self:GetCaster():HasModifier("modifier_ryougi_black_moon") then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
    end
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
end

function ryougi_glass_moon:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_avidya_moon"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_avidya_moon"):SetLevel(self:GetLevel())
    end
end

function ryougi_glass_moon:OnSpellStart()
	local caster = self:GetCaster()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")
	if (self:GetCursorPosition() - caster:GetAbsOrigin()):Length2D() > 0 then
		caster:SetForwardVector((self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized())
	end
	caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon_2", {duration = 0.21})
	StartAnimation(caster, {duration=0.315, activity=ACT_DOTA_CAST_ABILITY_1, rate=2})
	Timers:CreateTimer(0.0, function()
		caster:EmitSound("ryougi_moon_1")

		local target = self:GetCursorPosition()
		local target_enemy = nil
		local origin_e = nil
		local direction_e = nil
		local targetted = false
		local origin = caster:GetAbsOrigin()
		local true_dist = (Vector(target.x, target.y, 0) - Vector(origin.x, origin.y, 0)):Length2D()
		if self:GetCursorTarget() then
			targetted = true
			target_enemy = self:GetCursorTarget()
			origin_e = target_enemy:GetAbsOrigin()
			direction_e = (Vector(origin_e.x, origin_e.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
			true_dist = (Vector(origin_e.x, origin_e.y, 0) - Vector(origin.x, origin.y, 0)):Length2D()
		end
		local direction = (Vector(target.x, target.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
		if true_dist > self:GetSpecialValueFor("dash_range") then
			true_dist = self:GetSpecialValueFor("dash_range")
		end
		local range = self:GetSpecialValueFor("range")

		if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
			direction = caster:GetForwardVector()
		end
		local counter = 0

		caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon_2", {duration = 0.215})

		local speed = self:GetSpecialValueFor("dash_range")/0.115

		local sin = Physics:Unit(caster)
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(direction*speed)
		caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

		if targetted and ((origin - origin_e):Length2D() > (range+200)/2 + self:GetSpecialValueFor("dash_range")) then
			targetted = false
		end

		Timers:CreateTimer("ryougi_dash", {
			endTime = true_dist/speed,
			callback = function()

			local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_blue.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
		    ParticleManager:SetParticleControl( effect_cast, 1, caster:GetAbsOrigin())
		    ParticleManager:SetParticleControl( effect_cast, 2, caster:GetAbsOrigin() )
		    Timers:CreateTimer(1.0, function()
		        ParticleManager:DestroyParticle(effect_cast, true)
		        ParticleManager:ReleaseParticleIndex( effect_cast )
		    end)
			
			caster:OnPreBounce(nil)
			caster:SetBounceMultiplier(0)
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

			--if caster:IsStunned() then return end

			StartAnimation(caster, {duration=0.815, activity=ACT_DOTA_CAST_ABILITY_2, rate=2})

			local diff = 0

			--[[if targetted and ((origin - origin_e):Length2D() > range/2) then
				targetted = false
			end]]

			Timers:CreateTimer(0.0, function()
				if not caster:IsAlive() then return end
				if counter == 0 and targetted then
					diff = (caster:GetAbsOrigin() - target_enemy:GetAbsOrigin()):Length2D()
				end
				diff = math.min(diff, range/2)

				caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon", {duration = 0.3})

				Timers:CreateTimer(0, function()
					if not caster:IsAlive() then
						return
					end
					if not caster:HasModifier("modifier_ryougi_glass_moon") then
						FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
						return
					end

					counter = counter + 1

					if targetted then
						caster:SetForwardVector(direction_e)
						caster:SetAbsOrigin(target_enemy:GetAbsOrigin() + direction_e*(-diff + 0.033*range/0.3*counter))
					else
						local origin_t = caster:GetAbsOrigin()
						caster:SetForwardVector(direction)
						caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.3*0.033, caster))
					end

					if counter == 6 then
						local enemies = FindUnitsInLine(
											        caster:GetTeamNumber(),
											        caster:GetAbsOrigin(),
											        caster:GetAbsOrigin() - caster:GetForwardVector()*100,
											        nil,
											        200,
													self:GetAbilityTargetTeam(),
													self:GetAbilityTargetType(),
													self:GetAbilityTargetFlags()
			    								)

					    caster:EmitSound("jtr_slash")

					    local damage = self:GetSpecialValueFor("damage")

					    Timers:CreateTimer(0, function()
					    	if caster and IsValidEntity(caster) and enemies and #enemies>0 then
							    for _, enemy in pairs(enemies) do
							        DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
							        EmitSoundOn("ryougi_hit", enemy)
							        eyes:CutLine(enemy, "glass_moon")

							        --self:PlayEffects2(enemy)

							      	--enemy:EmitSound("jtr_slash")
							    end
							end
						end)
						local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle, 5, Vector(300, 0, 200)) 
						ParticleManager:SetParticleControl(particle, 10, Vector(0, 0, 30))

						Timers:CreateTimer(1, function()
							ParticleManager:DestroyParticle(particle, false)
							ParticleManager:ReleaseParticleIndex(particle)
						end)
					end
					return 0.033
				end)
			end)
		return end
		})

		caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
			Timers:RemoveTimer("ryougi_dash")
			caster:OnPreBounce(nil)
			caster:SetBounceMultiplier(0)
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

			local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_blue.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
		    ParticleManager:SetParticleControl( effect_cast, 1, caster:GetAbsOrigin())
		    ParticleManager:SetParticleControl( effect_cast, 2, caster:GetAbsOrigin() )
		    Timers:CreateTimer(1.0, function()
		        ParticleManager:DestroyParticle(effect_cast, true)
		        ParticleManager:ReleaseParticleIndex( effect_cast )
		    end)

			--if caster:IsStunned() then return end

			StartAnimation(caster, {duration=0.815, activity=ACT_DOTA_CAST_ABILITY_2, rate=2})

			--[[if targetted and ((origin - origin_e):Length2D() > range/2) then
				targetted = false
			end]]

			Timers:CreateTimer(0.0, function()
				if not caster:IsAlive() then return end
				caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon", {duration = 0.3})

				local diff = 0

				Timers:CreateTimer(0, function()
					if counter == 0 and targetted then
						diff = (caster:GetAbsOrigin() - target_enemy:GetAbsOrigin()):Length2D()
					end
					diff = math.min(diff, range/2)
					if not caster:IsAlive() then
						return
					end
					if not caster:HasModifier("modifier_ryougi_glass_moon") then
						FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
						return
					end

					counter = counter + 1

					if targetted then
						caster:SetForwardVector(direction_e)
						caster:SetAbsOrigin(target_enemy:GetAbsOrigin() + direction_e*(-diff + 0.033*range/0.3*counter))
					else
						local origin_t = caster:GetAbsOrigin()
						caster:SetForwardVector(direction)
						caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.3*0.033, caster))
					end

					if counter == 6 then
						local enemies = FindUnitsInLine(
											        caster:GetTeamNumber(),
											        caster:GetAbsOrigin(),
											        caster:GetAbsOrigin() - caster:GetForwardVector()*100,
											        nil,
											        200,
													self:GetAbilityTargetTeam(),
													self:GetAbilityTargetType(),
													self:GetAbilityTargetFlags()
			    								)

					    caster:EmitSound("jtr_slash")

					    local damage = self:GetSpecialValueFor("damage")

					    Timers:CreateTimer(0, function()
					    	if caster and IsValidEntity(caster) and enemies and #enemies>0 then
							    for _, enemy in pairs(enemies) do
							        DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
							        EmitSoundOn("ryougi_hit", enemy)
							        eyes:CutLine(enemy, "glass_moon")

							        --self:PlayEffects2(enemy)

							      	--enemy:EmitSound("jtr_slash")
							    end
							end
						end)
						local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle, 5, Vector(300, 0, 200)) 
						ParticleManager:SetParticleControl(particle, 10, Vector(0, 0, 60))

						Timers:CreateTimer(1, function()
							ParticleManager:DestroyParticle(particle, false)
							ParticleManager:ReleaseParticleIndex(particle)
						end)
					end
					return 0.033
				end)
			end)
		end)
	end)
end

modifier_ryougi_glass_moon = class({})

function modifier_ryougi_glass_moon:CheckState()
	return { --[MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 --[MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end

function modifier_ryougi_glass_moon:IsHidden() return true end

modifier_ryougi_glass_moon_2 = class({})

function modifier_ryougi_glass_moon_2:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = false }
end

function modifier_ryougi_glass_moon_2:IsHidden() return true end

function modifier_ryougi_glass_moon_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING }
end

function modifier_ryougi_glass_moon_2:GetModifierDisableTurning()
	return 1
end