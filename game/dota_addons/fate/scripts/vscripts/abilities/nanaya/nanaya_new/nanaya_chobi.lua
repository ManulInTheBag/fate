LinkLuaModifier("modifier_nanaya_chobi", "abilities/nanaya/nanaya_new/nanaya_chobi", LUA_MODIFIER_MOTION_NONE)

nanaya_chobi = class({})

function nanaya_chobi:OnAbilityPhaseStart()
	EmitGlobalSound("nanaya.rstart")
	return true
end

function nanaya_chobi:OnAbilityPhaseInterrupted()
	StopGlobalSound("nanaya.rstart")
end

function nanaya_chobi:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local target_index = target:entindex()

	caster:AddNewModifier(caster, self, "modifier_nanaya_chobi", {target = target_index})

	caster:EmitSound("nanaya.jumpff")
end

modifier_nanaya_chobi = class({})

function modifier_nanaya_chobi:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                        [MODIFIER_STATE_INVULNERABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    }
					   return state
end

function modifier_nanaya_chobi:OnCreated(args)
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.target = EntIndexToHScript(args.target)

	self.duration = 0
	self.min_range = 700

	self.z_offset = 0

	self.kappa = false

	local angle = self.caster:GetLocalAngles()

	self.dash_fx = ParticleManager:CreateParticle("particles/nanaya/nanaya_afterimage.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	ParticleManager:SetParticleControl(self.dash_fx, 0, self.caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.dash_fx, 1, Vector(angle[1], angle[2], angle[3]))
	self:AddParticle(self.dash_fx, false, false, -1, true, false)

	self.caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_6, 1)

	self:StartIntervalThink(FrameTime())
end

function modifier_nanaya_chobi:OnIntervalThink()
	if not IsServer() then return end

	if self.kappa then return end

	local angle = self.caster:GetLocalAngles()
	ParticleManager:SetParticleControl(self.dash_fx, 1, Vector(angle[1], angle[2], angle[3]))

	self.duration = self.duration - FrameTime()
	self.z_offset = self.z_offset + 4

	local ori = self.target:GetAbsOrigin()

	local vec = ori
	vec.z = self.caster:GetAbsOrigin().z

	self.caster:FaceTowards(vec)

	local dist = (ori - self.caster:GetAbsOrigin()):Length2D()

	local speed = dist/self.duration*FrameTime()
	speed = math.max(speed, 700/1.4*FrameTime())

	self.caster:SetAbsOrigin(GetGroundPosition(self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*speed, self.caster) + Vector(0, 0, self.z_offset))

	if self.duration <= 0 and not self.kappa then
		self:PlayEffects()
		self:Destroy()
		self.kappa = true
	end

	if dist < 100 and not self.kappa then
		self:PlayEffects()
		self:Destroy()
		self.kappa = true
	end
end

function modifier_nanaya_chobi:PlayEffects()
	if not IsServer() then return end
	local dmg = self.ability:GetSpecialValueFor("dmg")
	local damage_type = DAMAGE_TYPE_MAGICAL

	if self.caster.ChobiAcquired then
		if self.target:GetHealth()/self.target:GetMaxHealth() < self.ability:GetSpecialValueFor("attribute_threshold")/100 then
			dmg = dmg*self.ability:GetSpecialValueFor("attribute_multiplier")/100
		end
	end

	if self.caster.InstinctAcquired and (self.caster:FindModifierByName("modifier_nanaya_instinct_passive"):GetStackCount() >= 20) then
		damage_type = DAMAGE_TYPE_PURE
	end

	local particle = ParticleManager:CreateParticle("particles/test_part_small1.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
	ParticleManager:SetParticleControl(particle, 3, self.caster:GetAbsOrigin() - self.caster:GetForwardVector()*250 + Vector (0, 0, 400))

	EmitGlobalSound("nanaya.trigger")
	self.target:EmitSound("nanaya.finalhit")

	DoDamage(self.caster, self.target, dmg, damage_type, 0, self.ability, false)

	self.caster:FadeGesture(ACT_DOTA_CAST_ABILITY_6)
	self.caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_10, 1.4)

	FindClearSpaceForUnit(self.caster, self.target:GetAbsOrigin() + self.caster:GetForwardVector()*300 , true) 
	local hit2 = ParticleManager:CreateParticle("particles/screen_spla22.vpcf", PATTACH_EYES_FOLLOW, self.target)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/nanaya_work_2.vpcf", PATTACH_ABSORIGIN, self.target)
	ParticleManager:SetParticleControl(particle, 5, self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*250 + Vector (0, 0, -100))
	local part2 = ParticleManager:CreateParticle("particles/hit21.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
	ParticleManager:SetParticleControl(part2, 0, self.caster:GetAbsOrigin() + Vector(0, 0, 0))

	if self.caster.ChobiAcquired and not self.target:IsAlive() then
		self.ability:EndCooldown()
		self.caster:GiveMana(300)
	end
end