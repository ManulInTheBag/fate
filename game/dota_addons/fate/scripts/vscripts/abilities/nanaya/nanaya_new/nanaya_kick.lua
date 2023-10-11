LinkLuaModifier("modifier_nanaya_kick_tracker", "abilities/nanaya/nanaya_new/nanaya_kick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_kerikedak", "abilities/nanaya/nanaya_new/nanaya_kick", LUA_MODIFIER_MOTION_NONE)

nanaya_kick = class({})

function nanaya_kick:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nanaya_kick_tracker") then
		local stack = caster:GetModifierStackCount("modifier_nanaya_kick_tracker", caster)

		return stack
	else
		return 1
	end
end

function nanaya_kick:CastFilterResult()
	local caster = self:GetCaster()
	if IsServer() then
		local target = self.target
		if not target then return UF_FAIL_CUSTOM end
		local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

		if dist > (self:CheckSequence() == 5 and self:GetSpecialValueFor("fly_range") or self:GetSpecialValueFor("kick_range")) then 
			return UF_FAIL_CUSTOM 
		end
	end
	return UF_SUCCESS
end

function nanaya_kick:GetCustomCastError()
    return "#Target_out_of_range"
end

function nanaya_kick:GetBehavior()
	if self:CheckSequence() == 1 then
		return (DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING)
	end
	return (DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING)
end

function nanaya_kick:GetCastRange()
	local seq = self:CheckSequence()
	if seq <= 4 then
		return self:GetSpecialValueFor("kick_range")
	end
	return self:GetSpecialValueFor("fly_range")
end


function nanaya_kick:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_nanaya_kick_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_nanaya_kick_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_nanaya_kick_tracker", ability, 2)
	else
		caster:AddNewModifier(caster, ability, "modifier_nanaya_kick_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_nanaya_kick_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function nanaya_kick:GetCastAnimation()
	local seq = self:CheckSequence()
	if seq == 1 then
		return ACT_SCRIPT_CUSTOM_1
	elseif seq == 2 then
		return ACT_DOTA_CAST_ABILITY_3
	elseif seq == 3 then
		return ACT_DOTA_ATTACK2
	elseif seq == 4 then
		return ACT_DOTA_CAST_ABILITY_15
	elseif seq == 5 then
		return ACT_SCRIPT_CUSTOM_2
	end
	return ACT_SCRIPT_CUSTOM_14
end

function nanaya_kick:OnSpellStart()
	local caster = self:GetCaster()
	local seq = self:CheckSequence()
	if seq == 1 then
		self.target = nil
		self.target = self:GetCursorTarget()
	end
	local target = self.target
	if seq <= 4 then
		self:SimpleKick(seq, target)
	elseif seq == 5 then
		self:Kerikedak()
	end
	local stacks = caster:FindModifierByName("modifier_nanaya_instinct_passive"):GetStackCount()
	if seq <= 3 then
		--if stacks >= (seq*5) then
			self:SequenceSkill()
			self:EndCooldown()
		--[[else
			self:EndSequence()
		end]]
	elseif seq == 4 then
		if caster:HasModifier("modifier_nanaya_instinct") then
			self:SequenceSkill()
			self:EndCooldown()
		else
			self:EndSequence()
		end
	else
		self:EndSequence()
	end
end

function nanaya_kick:EndSequence()
	self:GetCaster():RemoveModifierByName("modifier_nanaya_kick_tracker")
end

function nanaya_kick:SimpleKick(seq, target)
	local caster = self:GetCaster()
	local target = target
	local position = target:GetAbsOrigin()
	local dir = (caster:GetAbsOrigin() - position):Normalized()
	local damage = self:GetSpecialValueFor("kick_damage") + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self:GetSpecialValueFor("attribute_kick_agility_multiplier") or 0)

	caster:EmitSound("nanaya.clonetp"..seq)

	target:EmitSound("nanaya.slash")

	FindClearSpaceForUnit(caster, position + dir*(250-50*seq), false)

	ScreenShake(target:GetOrigin(), 10, 1.0, 0.1, 2000, 0, true)

	ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, target)

	local test_hit = ParticleManager:CreateParticle("particles/nanaya_hit_test.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(test_hit, 1, position + dir * 120)
	ParticleManager:SetParticleControl(test_hit, 0, position)

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

function nanaya_kick:Kerikedak()
	local caster = self:GetCaster()

	caster:EmitSound("nanaya.kerikedaknormal")
	caster:AddNewModifier(caster, self, "modifier_nanaya_kerikedak", {})
end

modifier_nanaya_kerikedak = class({})

function modifier_nanaya_kerikedak:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.target = self.ability.target
		self.speed = self.ability:GetSpecialValueFor("fly_speed")
		self.flytopoint = false

		--[[self.fx = ParticleManager:CreateParticle("particles/edmon/edmon_dash_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
		self:AddParticle(self.fx, false, false, -1, false, false)]]

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_nanaya_kerikedak:IsHidden() return true end
function modifier_nanaya_kerikedak:IsDebuff() return false end
function modifier_nanaya_kerikedak:RemoveOnDeath() return true end
function modifier_nanaya_kerikedak:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nanaya_kerikedak:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_nanaya_kerikedak:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_2_END
end
function modifier_nanaya_kerikedak:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_STUNNED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end
function modifier_nanaya_kerikedak:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_nanaya_kerikedak:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        self.parent:RemoveModifierByName("modifier_edmon_dash_particle")
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end

        if self.ability.particle_kappa then
            --[[ParticleManager:DestroyParticle(self.ability.particle_kappa, false)
            ParticleManager:ReleaseParticleIndex(self.ability.particle_kappa)]]
        end
    end
end
function modifier_nanaya_kerikedak:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())
end
function modifier_nanaya_kerikedak:UpdateHorizontalMotion(me, dt)

    if not self.target or not self.target:IsAlive() then
    	self.flytopoint = true
    end

    if not self.flytopoint then
    	self.targetpos = self.target:GetAbsOrigin()
    end

    if (self.targetpos - self.parent:GetOrigin()):Length2D() < 150 then
        self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_nanaya_kerikedak:BOOM()
    local position = self.target:GetAbsOrigin()

    if IsSpellBlocked(self.target) then return end

    local caster = self:GetCaster()
    local target = self.target
    local damage = self.ability:GetSpecialValueFor("fly_damage")
    local damagetodo = damage + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self.ability:GetSpecialValueFor("attribute_fly_agility_multiplier") or 0)
    local hit = 2

    target:EmitSound("nanaya.hitleg")
	ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, target)
	ScreenShake(target:GetOrigin(), 10, 1.0, 0.7, 2000, 0, true)
	DoDamage(caster, target, damagetodo, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

	caster:SetOrigin(target:GetOrigin() - caster:GetForwardVector()*100)
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 2)

	Timers:CreateTimer(0, function()	
		if not caster:IsAlive() then return end
		if hit > 0 then
			hit = hit-1
			damagetodo = damage + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self.ability:GetSpecialValueFor("attribute_fly_agility_multiplier") or 0)
			DoDamage(caster, target, damagetodo, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

   			ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, target)
  			ScreenShake(target:GetOrigin(), 10, 1.0, 0.3, 2000, 0, true)
   			target:EmitSound("nanaya.hitleg")
    		return 0.1
    	else
    		return
    	end	
	end)

	if not caster:IsAlive() then return end

	local knockback4 = { should_stun = false,
				knockback_duration = 0.05,
				duration = 0.05,
				knockback_distance = 5,
				knockback_height = 50,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
			center_z = 4000}

   	target:AddNewModifier(caster, self.ability, "modifier_knockback", knockback4)	

	local knockback1 = { should_stun = false,
				knockback_duration = 0.5,
				duration = 0.5,
				knockback_distance = 0,
				knockback_height = 400,
				center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
				center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
			center_z = caster:GetAbsOrigin().z }	

	local knockback2 = { should_stun = false,
		knockback_duration = 0.5,
		duration = 0.5,
		knockback_distance = 0,
		knockback_height = 200,
		center_x = caster:GetAbsOrigin().x - caster:GetForwardVector().x * 800,
		center_y = caster:GetAbsOrigin().y - caster:GetForwardVector().y * 800,
		center_z = caster:GetAbsOrigin().z }

	Timers:CreateTimer(0.01, function()
		target:RemoveModifierByName("modifier_knockback")

		if not IsKnockbackImmune(target) then
			if not caster:IsAlive() then return end

			target:AddNewModifier(caster, self.ability, "modifier_knockback", knockback1)	
			caster:AddNewModifier(caster, self.ability, "modifier_knockback", knockback2)
		end
	end)
		
	Timers:CreateTimer(0.35, function()	
		if not caster:IsAlive() then return end
			
		target:RemoveModifierByName("modifier_knockback")
		local vec = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
		local knockback3 = { should_stun = false,
		knockback_duration = 0.05,
		duration = 0.05,
		knockback_distance = 0,
		knockback_height = 150,
		center_x = caster:GetAbsOrigin().x + vec.x * 800,
		center_y = caster:GetAbsOrigin().y + vec.y * 800,
		center_z = 4000 }

		if not IsKnockbackImmune(target)  then
           	target:AddNewModifier(caster, self.ability, "modifier_knockback", knockback3)	
		end

        caster:EmitSound("nanaya.jumphit")

        Timers:CreateTimer(0.05, function()
        	target:EmitSound("nanaya.hit")
            ScreenShake(target:GetOrigin(), 10, 1.0, 0.4, 2000, 0, true)

            damagetodo = damage + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self.ability:GetSpecialValueFor("attribute_fly_agility_multiplier") or 0)
		  	DoDamage(caster, target, damagetodo*2, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

			local part = ParticleManager:CreateParticle("particles/test_part6.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(part, 3, caster:GetAbsOrigin() + Vector(0, 0, 0))
			
			local part2 = ParticleManager:CreateParticle("particles/hit2.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControlEnt(part2, 0, caster, PATTACH_POINT, "attach_knife", caster:GetAbsOrigin(), true)
		  	
		  	local part1 = ParticleManager:CreateParticle("particles/nanaya_jump_back.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, target)
		 	ParticleManager:SetParticleControl(part1, 0, GetGroundPosition(target:GetAbsOrigin(), nil))
		   	ParticleManager:SetParticleControl(part, 5, GetGroundPosition(target:GetAbsOrigin(), nil))
        end)
    end)
end
function modifier_nanaya_kerikedak:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    self.parent:SetForwardVector(direction:Normalized())
end



modifier_nanaya_kick_tracker = class({})

function modifier_nanaya_kick_tracker:OnCreated()
	if IsServer() then
	end
end 

function modifier_nanaya_kick_tracker:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()

		local ability = self:GetAbility()
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1))
	end
end

function modifier_nanaya_kick_tracker:IsPurgable()
	return false
end

function modifier_nanaya_kick_tracker:IsHidden()
	return true
end

function modifier_nanaya_kick_tracker:IsDebuff()
	return false
end

function modifier_nanaya_kick_tracker:RemoveOnDeath()
	return true
end

function modifier_nanaya_kick_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end