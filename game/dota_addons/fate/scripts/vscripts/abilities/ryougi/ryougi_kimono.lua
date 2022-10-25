LinkLuaModifier("modifier_ryougi_kimono_tracker", "abilities/ryougi/ryougi_kimono", LUA_MODIFIER_MOTION_NONE)

ryougi_kimono = class({})

function ryougi_kimono:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_double_belfry"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_double_belfry"):SetLevel(self:GetLevel())
    end
end

function ryougi_kimono:GetCastPoint()
	if self:CheckSequence() == 2 then
		return 0.50
	else
		return 0.20
	end
end

function ryougi_kimono:GetPlaybackRateOverride()
    if self:CheckSequence() == 2 then
		return 1.0
	else
		return 2.0
	end
end

function ryougi_kimono:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_kimono_tracker") then
		local stack = caster:GetModifierStackCount("modifier_ryougi_kimono_tracker", caster)

		return stack
	else
		return 0
	end	
end

function ryougi_kimono:OnAbilityPhaseStart()
   	local caster = self:GetCaster()	
	if self:CheckSequence() == 2 then
		EmitSoundOn("ryougi_kimono_2", caster)
	else
		EmitSoundOn("ryougi_kimono_1", caster)
	end
    return true
end

function ryougi_kimono:OnAbilityPhaseInterrupted()
    local caster = self:GetCaster()	
	StopSoundOn("ryougi_kimono_1", caster)
	StopSoundOn("ryougi_kimono_2", caster)
end

function ryougi_kimono:GetCastAnimation()
	if self:CheckSequence() == 2 then
		return ACT_DOTA_CAST_ABILITY_6
	else
		return ACT_DOTA_CAST_ABILITY_5
	end
end

function ryougi_kimono:GetAbilityTextureName()
	if self:CheckSequence() == 2 then
		return "custom/ryougi/ryougi_kimono_2"
	else
		return "custom/ryougi/ryougi_kimono_2"
	end
end

function ryougi_kimono:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_ryougi_kimono_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_ryougi_kimono_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_ryougi_kimono_tracker", ability, 2)
	else
		caster:SetModifierStackCount("modifier_ryougi_kimono_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function ryougi_kimono:OnSpellStart()
	local caster = self:GetCaster()

	if self:CheckSequence() == 2 then
		self:Kimono2()
	else
		self:Kimono1()
	end
end

function ryougi_kimono:Kimono1()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local damage = self:GetSpecialValueFor("first_damage")
	local point = self:GetCursorPosition()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 180, -60))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	local max_dist = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")
    local hit_count = 3

    local direction = (point-origin)
    local dist = math.min( max_dist, direction:Length2D() )
    direction.z = 0
    direction = direction:Normalized()

    local target = GetGroundPosition( origin + direction*dist, nil )

    FindClearSpaceForUnit( caster, target, true )

    local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target)
    ParticleManager:SetParticleControl( effect_cast, 2, target )
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(effect_cast, true)
        ParticleManager:ReleaseParticleIndex( effect_cast )
    end)

    self.AffectedTargets = {}

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        nil,
								        width,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    								)

    EmitSoundOn("jtr_slash", caster)

    if caster and IsValidEntity(caster) and enemies and #enemies>0 then
	    for _, enemy in pairs(enemies) do
	    	if not self.AffectedTargets[enemy:entindex()] then
	    		--print("pepeg")
		    	self.AffectedTargets[enemy:entindex()] = true
		    	enemy:AddNewModifier(caster, self, "modifier_rooted", { Duration = self:GetSpecialValueFor("first_stun_duration") })
		        DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		        EmitSoundOn("ryougi_hit", enemy)
		        eyes:CutLine(enemy, "kimono_1")
		    end
	    end
	end

	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies2) do
    	if not self.AffectedTargets[enemy:entindex()] then
			self.AffectedTargets[enemy:entindex()] = true

			local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
			local origin_diff_norm = origin_diff:Normalized()
			if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
			    DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
			    EmitSoundOn("ryougi_hit", enemy)
			    eyes:CutLine(enemy, "kimono_1")
	        end
	   	end
    end

	self:SequenceSkill()
	self:EndCooldown()
end


function ryougi_kimono:Kimono2()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local target = origin - caster:GetForwardVector()*250
	local damage = self:GetSpecialValueFor("second_damage")
	local attacked = false
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        nil,
								        100,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    								)

    EmitSoundOn("jtr_slash", caster)

    if caster and IsValidEntity(caster) and enemies and #enemies>0 then
	    for _, enemy in pairs(enemies) do
	    	if not attacked then
		    	attacked = true
		    	giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("second_stun_duration"))
		    	--enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = self:GetSpecialValueFor("second_stun_duration") })
		        DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		        EmitSoundOn("ryougi_hit", enemy)
		        eyes:CutLine(enemy, "kimono_2")
		    end
	    end
	end

	caster:RemoveModifierByName("modifier_ryougi_kimono_tracker")

	if caster.KiyohimePassingAcquired then
		self:EndCooldown()
		self:StartCooldown(4)
	end
end

modifier_ryougi_kimono_tracker = class({})

function modifier_ryougi_kimono_tracker:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
	end
end

function modifier_ryougi_kimono_tracker:IsPurgable()
	return false
end

function modifier_ryougi_kimono_tracker:IsHidden()
	return true
end

function modifier_ryougi_kimono_tracker:IsDebuff()
	return false
end

function modifier_ryougi_kimono_tracker:RemoveOnDeath()
	return true
end

function modifier_ryougi_kimono_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ryougi_kimono_tracker:GetTexture()
	return "custom/lishuwen_fierce_tiger_strike"
end