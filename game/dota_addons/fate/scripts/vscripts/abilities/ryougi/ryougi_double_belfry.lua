LinkLuaModifier("modifier_ryougi_double_belfry_tracker", "abilities/ryougi/ryougi_double_belfry", LUA_MODIFIER_MOTION_NONE)

ryougi_double_belfry = class({})

function ryougi_double_belfry:GetCastPoint()
	if self:CheckSequence() == 2 then
		return 0.10
	elseif self:CheckSequence() == 3 then
		return 0.20
	elseif self:CheckSequence() == 4 then
		return 0.20
	else
		return 0.225
	end
end

function ryougi_double_belfry:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_kimono"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_kimono"):SetLevel(self:GetLevel())
    end
    if hCaster:FindAbilityByName("ryougi_double_belfry_mech"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_double_belfry_mech"):SetLevel(self:GetLevel())
    end
end

function ryougi_double_belfry:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_double_belfry_tracker") then
		local stack = caster:GetModifierStackCount("modifier_ryougi_double_belfry_tracker", caster)

		return stack
	else
		return 0
	end	
end

function ryougi_double_belfry:OnAbilityPhaseStart()
   	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_ryougi_double_belfry_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_ryougi_double_belfry_tracker", {Duration = self:GetSpecialValueFor("window_duration") + 0.225})
		caster:SetModifierStackCount("modifier_ryougi_double_belfry_tracker", ability, 1)
	end
    return true
end

function ryougi_double_belfry:OnAbilityPhaseInterrupted()
    local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_ryougi_double_belfry_tracker")

	if modifier then
		if modifier:GetStackCount() == 1 then
			caster:RemoveModifierByName("modifier_ryougi_double_belfry_tracker")
			self:EndCooldown()
		end
	end
end

function ryougi_double_belfry:GetCastAnimation()
	if self:CheckSequence() == 2 then
		--print("2")
		return ACT_DOTA_CAST_ABILITY_2_END
	elseif self:CheckSequence() == 3 then
		--print("3")
		return ACT_DOTA_CAST_ABILITY_3_END
	elseif self:CheckSequence() == 4 then
		return ACT_DOTA_CAST_ABILITY_4_END
	else
		--print("1")
		return ACT_DOTA_CAST_ABILITY_1
	end
end

function ryougi_double_belfry:GetPlaybackRateOverride()
    if self:CheckSequence() == 2 then
		return 2.0
	elseif self:CheckSequence() == 3 then
		return 1.0
	elseif self:CheckSequence() == 4 then
		return 1.0
	else
		return 2.0
	end
end


function ryougi_double_belfry:GetAbilityTextureName()
	if self:CheckSequence() == 3 then
		return "custom/ryougi/ryougi_double_belfry_3"
	elseif self:CheckSequence() == 2 then
		return "custom/ryougi/ryougi_double_belfry_2"
	elseif self:CheckSequence() == 4 then
		return "custom/ryougi/ryougi_belfry_mech"
	else
		return "custom/ryougi/ryougi_double_belfry"
	end
end

function ryougi_double_belfry:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_ryougi_double_belfry_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_ryougi_double_belfry_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_ryougi_double_belfry_tracker", ability, 2)
	else
		caster:SetModifierStackCount("modifier_ryougi_double_belfry_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function ryougi_double_belfry:OnSpellStart()
	local caster = self:GetCaster()

	if self:CheckSequence() == 3 then
		self:Belfry3()
	elseif self:CheckSequence() == 2 then
		self:Belfry2()
	elseif self:CheckSequence() == 4 then
		caster:FindAbilityByName("ryougi_double_belfry_mech"):Belfry3()
	else
		self:Belfry1()
	end
end

function ryougi_double_belfry:Belfry1()
	local caster = self:GetCaster()
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue_speed_up.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 180, -90))
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	EmitSoundOn("jtr_slash", caster)
	EmitSoundOn("ryougi_one", caster)

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
		    DoDamage(caster, enemy, self:GetSpecialValueFor("first_damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
		    EmitSoundOn("ryougi_hit", enemy)
		    eyes:CutLine(enemy, "belfry_1")
        end
    end

	self:SequenceSkill()
	self:EndCooldown()
end


function ryougi_double_belfry:Belfry2()
	local caster = self:GetCaster()

	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue_speed_up.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70)) 
	ParticleManager:SetParticleControl(particle, 10, Vector(30, -30, 240))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	EmitSoundOn("jtr_slash", caster)
	EmitSoundOn("ryougi_two", caster)

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
		    DoDamage(caster, enemy, self:GetSpecialValueFor("second_damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
		    EmitSoundOn("ryougi_hit", enemy)
		    eyes:CutLine(enemy, "belfry_2")
        end
    end

	self:SequenceSkill()
	self:EndCooldown()
end

function ryougi_double_belfry:Belfry3()
	local caster = self:GetCaster()

	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue_speed_up.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70)) 
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 180, -120))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	EmitSoundOn("jtr_slash", caster)
	EmitSoundOn("ryougi_three", caster)

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
		    DoDamage(caster, enemy, self:GetSpecialValueFor("third_damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
		    --enemy:AddNewModifier(caster, self, "modifier_muted", {duration = self:GetSpecialValueFor("third_mute_duration")})
		    --giveUnitDataDrivenModifier(caster, enemy, "muted", self:GetSpecialValueFor("third_mute_duration"))
		    EmitSoundOn("ryougi_hit", enemy)
		    eyes:CutLine(enemy, "belfry_3")
        end
    end

    if not caster.KiyohimePassingAcquired then
    	caster:RemoveModifierByName("modifier_ryougi_double_belfry_tracker")
    else
    	self:SequenceSkill()
    	self:EndCooldown()
    	local ability = caster:FindAbilityByName("ryougi_double_belfry_mech")
    	ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) - ability:GetSpecialValueFor("window_duration"))
    end
	
	--[[if caster.KiyohimePassingAcquired then
		self:EndCooldown()
		self:StartCooldown(2)
	end]]
end

ryougi_double_belfry_mech = class({})

function ryougi_double_belfry_mech:GetCastPoint()
	if self:CheckSequence() == 2 then
		return 0.0
	elseif (self:CheckSequence() == 3) or (self:CheckSequence() == 4) then
		return 0.20
	else
		return 0.45
	end
end

function ryougi_double_belfry_mech:GetCastAnimation()
	if self:CheckSequence() == 2 then
		--print("2")
		return ACT_DOTA_CAST_ABILITY_1_END
	elseif (self:CheckSequence() == 3) or (self:CheckSequence() == 4) then
		--print("3")
		return ACT_DOTA_CAST_ABILITY_4_END
	else
		--print("1")
		return ACT_DOTA_CAST_ABILITY_1
	end
end

function ryougi_double_belfry_mech:GetAbilityTextureName()
	if (self:CheckSequence() == 3) or (self:CheckSequence() == 4) then
		return "custom/ryougi/ryougi_belfry_mech"
	elseif self:CheckSequence() == 2 then
		return "custom/ryougi/ryougi_kick"
	else
		return "custom/ryougi/ryougi_kick"
	end
end

function ryougi_double_belfry_mech:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ryougi_double_belfry_tracker") then
		local stack = caster:GetModifierStackCount("modifier_ryougi_double_belfry_tracker", caster)

		return stack
	else
		return 0
	end	
end

function ryougi_double_belfry_mech:OnSpellStart()
	local caster = self:GetCaster()

	if (self:CheckSequence() == 3) or (self:CheckSequence() == 4) then
		self:Belfry3()
	elseif self:CheckSequence() == 2 then
		self:Belfry2()
	else
		self:Belfry1()
	end
end

function ryougi_double_belfry_mech:Belfry1()
	print("why are we here? just to suffer?")
end

--mech belfry 2 does not cut line because it is not a knife cut but rather a kick
function ryougi_double_belfry_mech:Belfry2()
	local caster = self:GetCaster()
	local belfryabil = caster:FindAbilityByName("ryougi_double_belfry")

	EmitSoundOn("ryougi_kick", caster)

	local target = self:GetCursorPosition()
	local origin = caster:GetAbsOrigin()
	local direction = (Vector(target.x, target.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()
	local dist = self:GetSpecialValueFor("kick_range")

	target = direction*dist + origin
	
	if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
		direction = caster:GetForwardVector()
	end

	local counter = 0

	local speed = dist/0.115

	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(direction*speed)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("ryougi_kick", {
		endTime = dist/speed,
		callback = function()
			
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("ryougi_kick")
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        nil,
								        75,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    								)

    if caster and IsValidEntity(caster) and enemies and #enemies>0 then
	    for _, enemy in pairs(enemies) do
		    enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = self:GetSpecialValueFor("kick_stun") })
		    DoDamage(caster, enemy, self:GetSpecialValueFor("kick_damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
	    end
	end

    caster:RemoveModifierByName("modifier_ryougi_double_belfry_tracker")
	--self:EndCooldown()
end

function ryougi_double_belfry_mech:Belfry3()
	local caster = self:GetCaster()
	local belfryabil = caster:FindAbilityByName("ryougi_double_belfry")

	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")

	local particle = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_blue_speed_up.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70)) 
	ParticleManager:SetParticleControl(particle, 10, Vector(-150, 30, 90))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	EmitSoundOn("jtr_slash", caster)
	EmitSoundOn("ryougi_tobe_"..math.random(1,2), caster)

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
        	local kborigin = caster:GetAbsOrigin()
        	local knockback = { should_stun = false,
	                                knockback_duration = 0.05,
	                                duration = 0.05,
	                                knockback_distance = 150 or 0,
	                                knockback_height = 0,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }

	    	enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)
	    	enemy:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = self:GetSpecialValueFor("fourth_stun_duration")})

		    DoDamage(caster, enemy, self:GetSpecialValueFor("fourth_damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
		    EmitSoundOn("ryougi_hit", enemy)
		    eyes:CutLine(enemy, "belfry_4")
        end
    end

    if not caster.KiyohimePassingAcquired then
    	caster:RemoveModifierByName("modifier_ryougi_double_belfry_tracker")
    end

    --[[if caster.KiyohimePassingAcquired then
		belfryabil:EndCooldown()
		belfryabil:StartCooldown(2)
	end]]
end


modifier_ryougi_double_belfry_tracker = class({})

function modifier_ryougi_double_belfry_tracker:OnCreated()
	if IsServer() then
		local caster = self:GetCaster()
		caster:RemoveModifierByName("modifier_ryougi_combo_window")
		if caster:GetAbilityByIndex(5):GetName() == "ryougi_mystic_eyes" then
			caster:SwapAbilities("ryougi_mystic_eyes", "ryougi_double_belfry_mech", false, true)
		end
	end
end 

function modifier_ryougi_double_belfry_tracker:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		if caster:GetAbilityByIndex(5):GetName() == "ryougi_double_belfry_mech" then
			caster:SwapAbilities("ryougi_mystic_eyes", "ryougi_double_belfry_mech", true, false)
		end

		local ability = self:GetAbility()
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) - ability:GetSpecialValueFor("window_duration"))
	end
end

function modifier_ryougi_double_belfry_tracker:IsPurgable()
	return false
end

function modifier_ryougi_double_belfry_tracker:IsHidden()
	return true
end

function modifier_ryougi_double_belfry_tracker:IsDebuff()
	return false
end

function modifier_ryougi_double_belfry_tracker:RemoveOnDeath()
	return true
end

function modifier_ryougi_double_belfry_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ryougi_double_belfry_tracker:GetTexture()
	return "custom/ryougi/ryougi_double_belfry"
end