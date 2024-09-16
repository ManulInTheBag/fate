LinkLuaModifier("modifier_ryougi_glass_moon_2", "abilities/ryougi/ryougi_glass_moon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_glass_moon_recast", "abilities/ryougi/ryougi_glass_moon", LUA_MODIFIER_MOTION_NONE)

ryougi_glass_moon = class({})

--[[function ryougi_glass_moon:GetCastRange()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_glass_moon_recast") then
		return self:GetSpecialValueFor("leap_range")
	end
	return self:GetSpecialValueFor("dash_range")
end]]

function ryougi_glass_moon:GetCastPoint()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_glass_moon_recast") then
		return self:GetSpecialValueFor("cast_point2")
	end
	return self:GetSpecialValueFor("cast_point")
end

function ryougi_glass_moon:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	if caster:HasModifier("modifier_ryougi_glass_moon_recast") then
		caster:RemoveModifierByName("modifier_ryougi_glass_moon_recast")
		self:Cast2(target)
	else
		caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon_recast", {duration = self:GetSpecialValueFor("recast_window")})
		self:Cast1(target)
	end
end

function ryougi_glass_moon:Cast1(target)
	local caster = self:GetCaster()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")
	local ori = caster:GetAbsOrigin()
	local range = self:GetSpecialValueFor("dash_range") + caster:GetCastRangeBonus()
	if (target - ori):Length2D() > range then
		target = ori + (target - ori):Normalized()*range
	end

	caster:EmitSound("ryougi_moon_1")
	FindClearSpaceForUnit(caster, target, true)
	
	local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_blue.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( effect_cast, 0, ori )
	ParticleManager:SetParticleControl( effect_cast, 1, target)
	ParticleManager:SetParticleControl( effect_cast, 2, target)
	Timers:CreateTimer(1.0, function()
	    ParticleManager:DestroyParticle(effect_cast, true)
	    ParticleManager:ReleaseParticleIndex( effect_cast )
	end)
end

function ryougi_glass_moon:Cast2(target)
	local caster = self:GetCaster()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")
	local ori = caster:GetAbsOrigin()
	local range = self:GetSpecialValueFor("leap_range")
	local direction = (target - ori):Normalized()
	local counter = 0

	EmitSoundOn("ryougi_knife_"..math.random(1,4), caster)

	caster:AddNewModifier(caster, self, "modifier_ryougi_glass_moon_2", {duration = 0.3})

	StartAnimation(caster, {duration=0.815, activity=ACT_DOTA_CAST_ABILITY_2, rate=2})

	Timers:CreateTimer(0, function()
		if not caster:IsAlive() then
			return
		end
		if not caster:HasModifier("modifier_ryougi_glass_moon_2") then
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			return
		end

		counter = counter + 1
					
		local origin_t = caster:GetAbsOrigin()
		caster:SetForwardVector(direction)
		caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.3*0.033, caster))

		if counter == 6 then
			local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                   						caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

			caster:EmitSound("jtr_slash")
		
		    local damage = self:GetSpecialValueFor("damage")

		    Timers:CreateTimer(0, function()
		    	if caster and IsValidEntity(caster) and enemies and #enemies>0 then
				    for _, enemy in pairs(enemies) do
				        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				        EmitSoundOn("ryougi_hit", enemy)
				        eyes:CutLine(enemy, "glass_moon")

				    end
				end
			end)

			local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 5, Vector(350, 0, 200)) 
			ParticleManager:SetParticleControl(particle, 10, Vector(0, 0, 30))

			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle, false)
				ParticleManager:ReleaseParticleIndex(particle)
			end)
		end
	return 0.033
	end)
end

modifier_ryougi_glass_moon_recast = class({})

function modifier_ryougi_glass_moon_recast:IsHidden() return false end

function modifier_ryougi_glass_moon_recast:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
	end
end

function modifier_ryougi_glass_moon_recast:OnDestroy()
	if IsServer() then
		self.ability:StartCooldown(self.ability:GetCooldown(-1))
	end
end

modifier_ryougi_glass_moon_2 = class({})

function modifier_ryougi_glass_moon_2:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_UNTARGETABLE_ENEMY] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = false,
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