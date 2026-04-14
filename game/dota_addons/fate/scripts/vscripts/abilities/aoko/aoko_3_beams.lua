LinkLuaModifier("modifier_aoko_3_beams_tracker", "abilities/aoko/aoko_3_beams", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_3_beams_tracker_checker", "abilities/aoko/aoko_3_beams", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_3_beams_stacks", "abilities/aoko/aoko_3_beams", LUA_MODIFIER_MOTION_NONE)

aoko_3_beams = class({})

function aoko_3_beams:GetIntrinsicModifierName()
	return "modifier_aoko_3_beams_stacks"
end

function aoko_3_beams:CastFilterResultLocation()
	local caster = self:GetCaster()
	if IsServer() then
		if caster:FindModifierByName("modifier_aoko_3_beams_stacks"):GetStackCount() <= 0 then
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function aoko_3_beams:GetCustomCastErrorLocation()
    return "#No_Stacks"
end

function aoko_3_beams:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_intimidation"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_intimidation"):SetLevel(self:GetLevel())
    end
end

function aoko_3_beams:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_3_beams:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_aoko_3_beams_tracker") then
		local stack = caster:GetModifierStackCount("modifier_aoko_3_beams_tracker", caster)

		return stack
	else
		return 1
	end
end

function aoko_3_beams:GetCastPoint()
	local seq = self:CheckSequence()
	if seq == 3 then
		return 0.1
	end
	return self:GetSpecialValueFor("cast_point")
end

function aoko_3_beams:SequenceSkill(num)
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_aoko_3_beams_tracker")

	caster:AddNewModifier(caster, ability, "modifier_aoko_3_beams_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
	caster:SetModifierStackCount("modifier_aoko_3_beams_tracker", ability, num)
end

function aoko_3_beams:SetSequenceChecker(num)
	local caster = self:GetCaster()	
	local ability = self
	
	caster:AddNewModifier(caster, ability, "modifier_aoko_3_beams_tracker_checker", {Duration = self:GetSpecialValueFor("window_duration")})
	caster:SetModifierStackCount("modifier_aoko_3_beams_tracker_checker", ability, num)
end

function aoko_3_beams:SequenceTemporaryBreak()
	self:GetCaster():RemoveModifierByName("modifier_aoko_3_beams_tracker")
end

function aoko_3_beams:EndSequence()
	self:GetCaster():RemoveModifierByName("modifier_aoko_3_beams_tracker")
	self:GetCaster():RemoveModifierByName("modifier_aoko_3_beams_tracker_checker")

end

function aoko_3_beams:GetCastAnimation()
	local seq = self:CheckSequence()
	if seq == 1 then
		return ACT_SCRIPT_CUSTOM_11
	elseif seq == 2 then
		return ACT_SCRIPT_CUSTOM_12
	elseif seq == 3 then
		return ACT_SCRIPT_CUSTOM_13
	end
	return ACT_SCRIPT_CUSTOM_13
end

function aoko_3_beams:OnAbilityPhaseStart()
	--self:GetCaster():EmitSound("altera_photon")
	return true
end

function aoko_3_beams:OnAbilityPhaseInterrupted()
	--self:GetCaster():StopSound("altera_photon")
end

function aoko_3_beams:OnSpellStart()
    local hCaster = self:GetCaster()

    local circuits = hCaster:FindAbilityByName("aoko_circuits")
    local first_threshold = self:GetSpecialValueFor("first_threshold")
    local second_threshold = self:GetSpecialValueFor("second_threshold")

    local seq = self:CheckSequence()

    hCaster:FindModifierByName("modifier_aoko_3_beams_stacks"):DecrementStackCount()
	
    if seq == 1 then
    	EmitGlobalSound("aoko_sbs_1")
    	hCaster:AddNewModifier(hCaster, self, "modifier_aoko_3_beams", {duration = self:GetSpecialValueFor("duration") + FrameTime(), leg = 0})
		self.isRefreshed = 0
    	if circuits:GetStacks() >= first_threshold then
    		self:EndCooldown()
	    	self:SequenceSkill(2)
	    	--self:SetSequenceChecker(2)
		else
			self:SequenceTemporaryBreak()
			self:SetSequenceChecker(2)
			if self.isRefreshed == 1 then
				self:EndCooldown()
			end
		end
    elseif seq == 2 then
    	EmitGlobalSound("aoko_sbs_2")
    	hCaster:AddNewModifier(hCaster, self, "modifier_aoko_3_beams", {duration = self:GetSpecialValueFor("duration") + FrameTime(), leg = 0})

    	if circuits:GetStacks() >= second_threshold then
    		self:EndCooldown()
	    	self:SequenceSkill(3)
	    	--self:SetSequenceChecker(3)
		else
			self:SequenceTemporaryBreak()
			self:SetSequenceChecker(3)
			if self.isRefreshed == 1 then
				self:EndCooldown()
			end
		end
	else
    	hCaster:AddNewModifier(hCaster, self, "modifier_aoko_3_beams", {duration = self:GetSpecialValueFor("duration") + FrameTime() + 0.45, leg = 1})

    	self:EndSequence()
    end
end

---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_aoko_3_beams", "abilities/aoko/aoko_3_beams", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_3_beams_mech", "abilities/aoko/aoko_3_beams", LUA_MODIFIER_MOTION_NONE)

modifier_aoko_3_beams = class({})

function modifier_aoko_3_beams:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_aoko_3_beams:IsHidden() return true end

function modifier_aoko_3_beams:OnCreated(args)
    if IsServer() then
    	self.ability = self:GetAbility()
    	self.caster = self:GetCaster()
    	self.parent = self:GetParent()
    	self.caster_team = self.caster:GetTeamNumber()

    	self.circuits = self.caster:FindAbilityByName("aoko_circuits")

    	self.leg = (args.leg == 1)
    	self.counter = 0
    	self.check = true

    	if self.leg then
    		self.caster:AddNewModifier(self.caster, self.ability, "modifier_aoko_3_beams_mech", {duration = 1.8})
    		self.check = false
    	end

    	self.form = "neutral"
        self.particlename = "particles/aoko/aoko_big_beam.vpcf"
        self.particlename2 = "particles/aoko/aoko_big_beam_runes.vpcf"

        if self.leg then
        	self.particlename2 = "particles/aoko/aoko_big_beam_runes_leg.vpcf"
        end

        self.team_flag = DOTA_UNIT_TARGET_TEAM_ENEMY

        self.point     = self.ability:GetCursorPosition() + self.caster:GetForwardVector()
        self.distance  = self.ability:GetSpecialValueFor("distance")

        self.direction = (Vector(self.point.x, self.point.y, 0) - Vector(self.caster:GetAbsOrigin().x, self.caster:GetAbsOrigin().y, 0)):Normalized()
        self.vAttachLoc = self.caster:GetAbsOrigin() + self.direction * 50 + Vector(0, 0, 175)
        self.point     = self.vAttachLoc + self.direction * (self.distance - 50)

        self.radius = self.ability:GetSpecialValueFor("radius")

        self.damage = self.ability:GetSpecialValueFor("damage")
        if self.leg then
        	self.damage = self.ability:GetSpecialValueFor("damage_leg")
        end

        local damage_scaling = 0
        if self.caster.MagicBulletLoadAcquired then
        	damage_scaling = self.ability:GetSpecialValueFor("attribute_int_scale")*self.caster:GetIntellect()
        	if self.leg then
        		damage_scaling = self.ability:GetSpecialValueFor("attribute_int_scale_leg")*self.caster:GetIntellect()
        	end
        end

        self.damage = self.damage + damage_scaling

        self.duration = self.ability:GetSpecialValueFor("duration")
        self.damage = ( self.damage / self.duration ) * FrameTime()*2
        self.stack_gain = self.ability:GetSpecialValueFor("stack_gain")*0.1/self.duration

        if not self.leg then
	        self.particle =    ParticleManager:CreateParticle(self.particlename, PATTACH_WORLDORIGIN, self.caster)
	                            ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	                            ParticleManager:SetParticleControl(self.particle, 0, self.vAttachLoc)
	                            ParticleManager:SetParticleControl(self.particle, 1, self.vAttachLoc)
	                            ParticleManager:SetParticleControl(self.particle, 2, self.point)
	                            ParticleManager:SetParticleControl(self.particle, 3, Vector(self.radius, 0, 0))

	        self.particle2 =    ParticleManager:CreateParticle(self.particlename2, PATTACH_ABSORIGIN, self.caster)
	                            ParticleManager:SetParticleShouldCheckFoW(self.particle2, false)
	                            ParticleManager:SetParticleControlEnt(self.particle2, 0, self.caster, PATTACH_ABSORIGIN, "attach_hitloc", self.caster:GetAbsOrigin(), true)

	        self:AddParticle(self.particle, true, false, -1, false, false)
        	self:AddParticle(self.particle2, false, false, -1, false, false)

        	self.sound = "aoko_shoot_sfx"

        	EmitSoundOn(self.sound, self.caster)
	    end

	    if self.leg then
        	self:StartIntervalThink(FrameTime())
        else
        	self:StartIntervalThink(FrameTime()*2)
        end
    end
end
function modifier_aoko_3_beams:OnIntervalThink()
	if self.leg and self.counter < 10 then
		local diff = 0

		if self.counter < 2 then
			diff = 200
		elseif self.counter < 5 then
			diff = 50
		end

		if self.counter == 6 then
			EmitGlobalSound("aoko_sbs_3")
		end

		self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() + Vector(0, 0, diff))

		self.counter = self.counter + 1
		return
	elseif not self.check then
		self.check = true

		self.vAttachLoc = self.caster:GetAbsOrigin() + self.direction * 50 + Vector(0, 0, 30)

		self.particle = ParticleManager:CreateParticle(self.particlename, PATTACH_WORLDORIGIN, self.caster)
	                    ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	                    ParticleManager:SetParticleControl(self.particle, 0, self.vAttachLoc)
	                    ParticleManager:SetParticleControl(self.particle, 1, self.vAttachLoc)
	                    ParticleManager:SetParticleControl(self.particle, 2, self.point)
	                    ParticleManager:SetParticleControl(self.particle, 3, Vector(self.radius, 0, 0))

	    self.particle2 = ParticleManager:CreateParticle(self.particlename2, PATTACH_ABSORIGIN, self.caster)
	                    ParticleManager:SetParticleShouldCheckFoW(self.particle2, false)
	                    ParticleManager:SetParticleControlEnt(self.particle2, 0, self.caster, PATTACH_ABSORIGIN, "attach_hitloc", self.caster:GetAbsOrigin(), true)

	    self:AddParticle(self.particle, true, false, -1, false, false)
        self:AddParticle(self.particle2, false, false, -1, false, false)

        self.sound = "aoko_shoot_sfx"

        EmitSoundOn(self.sound, self.caster)

        self:StartIntervalThink(FrameTime()*2)
	end

	if self.caster.MagicianOfFifthAcquired and self.caster:HasModifier("modifier_aoko_circuits_overload") then
		self.caster:AddNewModifier(self.caster, self.circuits, "modifier_aoko_circuits_cc_immune", {duration = self.circuits:GetSpecialValueFor("range_cc_immune_duration")})
	end

    local hEnemies =   FindUnitsInLine(
								        self.caster_team,
								        self.caster:GetAbsOrigin(),
								        self.point,
								        nil,
								        self.radius,
										self.team_flag,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)
    local pepega = true
    for _, hEnemy in pairs(hEnemies) do
    	if pepega then
    		self.circuits:GainStacks(self.stack_gain)
    		pepega = false
    	end
        self:Impact(hEnemy, 1)
    end

    local spherecheck =   FindUnitsInLine(
								        self.caster_team,
								        self.caster:GetAbsOrigin(),
								        self.point,
								        nil,
								        self.radius,
										DOTA_UNIT_TARGET_TEAM_FRIENDLY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_INVULNERABLE
    								)
    for _, check in pairs(spherecheck) do
    	if check:HasModifier("modifier_aoko_sphere_dummy") then
	        local modifier = check:AddNewModifier(self.parent, self.parent:FindAbilityByName("aoko_sphere"), "modifier_aoko_sphere_dummy", {duration = 1, unbreakable = 1})
	        modifier:SetDuration(self.ability:GetSpecialValueFor("sphere_duration"), true)
	        check:FindModifierByName("modifier_aoko_sphere_dummy"):SevereExplode()
	    end
    end
end

function modifier_aoko_3_beams:Impact(target)
	if IsNotNull(target) --then
        and target ~= self.caster then
        local damage = self.damage

		DoDamage(self.caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
    end
end

function modifier_aoko_3_beams:OnDestroy()
    if IsServer() then
        --StopSoundOn(self.sound, self.caster)

        self.parent:Stop()

        if self.leg then
        	local pepega = 0

        	StartAnimation(self.parent, {duration=0.2, activity=ACT_SCRIPT_CUSTOM_14, rate=1.0})
        	Timers:CreateTimer(0, function()
        		local diff = 0
        		if pepega < 4 then
        			diff = 50
        		elseif pepega < 6 then
        			diff = 200
        		else
        			self.caster:RemoveModifierByName("modifier_aoko_3_beams_mech")
        			return
        		end

        		pepega = pepega + 1

        		self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() - Vector(0, 0, diff))
        		return FrameTime()
        	end)
        end
    end
end

--

modifier_aoko_3_beams_mech = class({})

function modifier_aoko_3_beams_mech:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_aoko_3_beams_mech:IsHidden() return true end

--

modifier_aoko_3_beams_tracker = class({})

function modifier_aoko_3_beams_tracker:OnCreated()
	if IsServer() then
	end
end

function modifier_aoko_3_beams_tracker:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()

		local ability = self:GetAbility()
		ability:EndCooldown()
		if  ability.isRefreshed == 0 then
			ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) * caster:GetCooldownReduction())
		end
	end
end

function modifier_aoko_3_beams_tracker:IsPurgable()
	return false
end

function modifier_aoko_3_beams_tracker:IsHidden()
	return true
end

function modifier_aoko_3_beams_tracker:IsDebuff()
	return false
end

function modifier_aoko_3_beams_tracker:RemoveOnDeath()
	return true
end

function modifier_aoko_3_beams_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--

modifier_aoko_3_beams_stacks = class({})

function modifier_aoko_3_beams_stacks:IsPurgable()
	return false
end

function modifier_aoko_3_beams_stacks:IsHidden()
	return false
end

function modifier_aoko_3_beams_stacks:IsDebuff()
	return false
end

function modifier_aoko_3_beams_stacks:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_aoko_3_beams_tracker_checker = class({})

function modifier_aoko_3_beams_tracker_checker:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.circuits = self.caster:FindAbilityByName("aoko_circuits")
		self.ability = self:GetAbility()
		self.first_threshold = 0--self.ability:GetSpecialValueFor("first_threshold")
    	self.second_threshold = 0--self.ability:GetSpecialValueFor("second_threshold")

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_aoko_3_beams_tracker_checker:OnIntervalThink()
	if IsServer() then
		local stacks = self.circuits:GetStacks()
		if self:GetStackCount() == 2 then
			if stacks >= self.first_threshold then
				if self.ability:GetCooldownTimeRemaining() > 0 then
					self.ability:EndCooldown()
					self.ability:SequenceSkill(2)
				end
			end
		elseif self:GetStackCount() == 3 then
			if stacks >= self.second_threshold then
				if self.ability:GetCooldownTimeRemaining() > 0 then
					self.ability:EndCooldown()
					self.ability:SequenceSkill(3)
				end
			end
		end
	end
end

function modifier_aoko_3_beams_tracker_checker:IsPurgable()
	return false
end

function modifier_aoko_3_beams_tracker_checker:IsHidden()
	return true
end

function modifier_aoko_3_beams_tracker_checker:IsDebuff()
	return false
end

function modifier_aoko_3_beams_tracker_checker:RemoveOnDeath()
	return true
end

function modifier_aoko_3_beams_tracker_checker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end