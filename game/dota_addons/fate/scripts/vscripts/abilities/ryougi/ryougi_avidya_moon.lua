LinkLuaModifier("modifier_ryougi_avidya_moon", "abilities/ryougi/ryougi_avidya_moon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_avidya_moon_2", "abilities/ryougi/ryougi_avidya_moon", LUA_MODIFIER_MOTION_NONE)

ryougi_avidya_moon = class({})

function ryougi_avidya_moon:GetBehavior()
    if self:GetCaster():HasModifier("modifier_ryougi_black_moon") then
        return DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

function ryougi_avidya_moon:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_glass_moon"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_glass_moon"):SetLevel(self:GetLevel())
    end
end

function ryougi_avidya_moon:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=0.815, activity=ACT_DOTA_CAST_ABILITY_2, rate=2})
    return true
end

function ryougi_avidya_moon:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end


function ryougi_avidya_moon:OnSpellStart()
	local caster = self:GetCaster()
	--caster:AddNewModifier(caster, self, "modifier_ryougi_avidya_moon_2", {duration = 0.11})
	--StartAnimation(caster, {duration=0.815, activity=ACT_DOTA_CAST_ABILITY_2, rate=2})

	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local target = self:GetCursorPosition()
	local target_enemy = nil
	local origin_e = nil
	local direction_e = nil
	local targetted = false
	local origin = caster:GetAbsOrigin()
	if self:GetCursorTarget() then
		targetted = true
		target_enemy = self:GetCursorTarget()
		origin_e = target_enemy:GetAbsOrigin()
		direction_e = (Vector(origin_e.x, origin_e.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
	end

	if targetted and ((origin - origin_e):Length2D() > (self:GetSpecialValueFor("range")+200)/2) then
		targetted = false
		target = origin_e
	end

	Timers:CreateTimer(0.0, function()
		if caster:IsStunned() then return end

		local direction = (Vector(target.x, target.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
		local range = self:GetSpecialValueFor("range")

		if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
			direction = caster:GetForwardVector()
		end
		local counter = 0

		--EmitSoundOn("ryougi_moon_2", caster)
		caster:EmitSound("ryougi_moon_2")

		caster:AddNewModifier(caster, self, "modifier_ryougi_avidya_moon", {duration = 0.3})
		--giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.6)
		Timers:CreateTimer(0, function()
			if not caster:IsAlive() then
				return
			end
			if not caster:HasModifier("modifier_ryougi_avidya_moon") then
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				return
			end

			counter = counter + 1

			if targetted then
				caster:SetForwardVector(direction_e)
				caster:SetAbsOrigin(target_enemy:GetAbsOrigin() + direction_e*(-1*range/2 + 0.033*range/0.3*counter))
			else
				local origin_t = caster:GetAbsOrigin()
				caster:SetForwardVector(direction)
				caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.3*0.033, caster))
			end

			if counter == 4 then
				local enemies = FindUnitsInLine(
									        caster:GetTeamNumber(),
									        caster:GetAbsOrigin(),
									        caster:GetAbsOrigin() + caster:GetForwardVector()*100,
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
					        eyes:CutLine(enemy, "avidya")

					        --self:PlayEffects2(enemy)

					      	--enemy:EmitSound("jtr_slash")
					    end
					end
				end)
				local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(particle, 5, Vector(300, 0, 200)) 
				ParticleManager:SetParticleControl(particle, 10, Vector(0, 0, 210)) 

				Timers:CreateTimer(1, function()
					ParticleManager:DestroyParticle(particle, false)
					ParticleManager:ReleaseParticleIndex(particle)
				end)
			end
			return 0.033
		end)
	end)
end

modifier_ryougi_avidya_moon = class({})

function modifier_ryougi_avidya_moon:CheckState()
	return { --[MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 --[MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end

function modifier_ryougi_avidya_moon:IsHidden() return true end

modifier_ryougi_avidya_moon_2 = class({})

function modifier_ryougi_avidya_moon_2:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true}
end

function modifier_ryougi_avidya_moon_2:IsHidden() return true end

function modifier_ryougi_avidya_moon_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING }
end

function modifier_ryougi_avidya_moon_2:GetModifierDisableTurning()
	return 1
end