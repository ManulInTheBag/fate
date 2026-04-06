LinkLuaModifier("modifier_aoko_earthlight_caster", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_blackhole_fx", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_enemy", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_fire", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_damage_field", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_slow", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_mech", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_earthlight_cd", "abilities/aoko/aoko_earthlight_starbow", LUA_MODIFIER_MOTION_NONE)

modifier_aoko_earthlight_cd = class({})

function modifier_aoko_earthlight_cd:GetTexture()
	return "custom/aoko/aoko_earthlight"
end

function modifier_aoko_earthlight_cd:IsHidden()
	return false 
end

function modifier_aoko_earthlight_cd:RemoveOnDeath()
	return false
end

function modifier_aoko_earthlight_cd:IsDebuff()
	return true 
end

function modifier_aoko_earthlight_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

aoko_earthlight_starbow = class({})

function aoko_earthlight_starbow:GetAOERadius()
	return self:GetSpecialValueFor("succ_radius")
end

function aoko_earthlight_starbow:OnSpellStart()
	local caster = self:GetCaster()

	local target = self:GetCursorPosition()

	local range = (caster:GetAbsOrigin() - target):Length2D()

	if range > self:GetSpecialValueFor("range") then
		range = self:GetSpecialValueFor("range")
	end

	local masterCombo = caster.MasterUnit2:FindAbilityByName("aoko_combo_proxy")
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("aoko_earthlight_starbow")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:AddNewModifier(caster, self, "modifier_aoko_earthlight_cd", {duration = self:GetCooldown(1)})

	caster:AddNewModifier(caster, self, "modifier_aoko_earthlight_caster", {duration = 7, range = range})

	EmitGlobalSound("aoko_earthlight_1")
end

aoko_earthlight_starbow_recast = class({})

function aoko_earthlight_starbow_recast:OnSpellStart()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_aoko_earthlight_caster") then return end

	caster:AddNewModifier(caster, self, "modifier_aoko_earthlight_caster", {duration = 3})
	caster:AddNewModifier(caster, self, "modifier_aoko_earthlight_fire", {duration = 3})
	caster:AddNewModifier(caster, self, "modifier_aoko_earthlight_damage_field", {duration = 3})

	EmitGlobalSound("aoko_earthlight_2")
end

modifier_aoko_earthlight_caster = class({})

function modifier_aoko_earthlight_caster:IsHidden() return false end
function modifier_aoko_earthlight_caster:IsDebuff() return false end

function modifier_aoko_earthlight_caster:RemoveOnDeath() return true end

function modifier_aoko_earthlight_caster:CheckState()
	return self.state
end

function modifier_aoko_earthlight_caster:OnCreated(args)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.caster:SwapAbilities("aoko_earthlight_starbow", "aoko_earthlight_starbow_recast", false, true)

	self.state = { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}

	self.radius = self.ability:GetSpecialValueFor("succ_radius")
	self.duration = self.ability:GetSpecialValueFor("succ_duration")

	self.succed_enemies = {}
	self.succing = true
	self.firing = false

	self.succer_range = math.max(args.range, 400)

	self.point = GetGroundPosition(self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*self.succer_range, self.caster) + Vector(0, 0, 300)

	local vision_radius = self.radius

	self.dummy = CreateUnitByName("aoko_blackhole", self.point, false, nil, nil, self.caster:GetTeamNumber())
	self.dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)
	self.dummy:SetDayTimeVisionRange(vision_radius)
	self.dummy:SetNightTimeVisionRange(vision_radius)
	self.dummy:SetForwardVector(self.caster:GetForwardVector())
	self.dummy:AddNewModifier(self.caster, self.ability, "modifier_aoko_earthlight_blackhole_fx", {})

	self.dummy:SetAbsOrigin(self.point)

	EmitSoundOn("aoko_intimidation_grab_sfx", self.dummy)
    EmitSoundOnLocationWithCaster(self.point, "aoko_blackhole", self.dummy)

	self.runes_fx = ParticleManager:CreateParticle("particles/aoko/aoko_cannon_blackhole_runes.vpcf", PATTACH_WORLDORIGIN, self.caster)
	ParticleManager:SetParticleShouldCheckFoW(self.runes_fx, false)
	ParticleManager:SetParticleControl(self.runes_fx, 0, self.point - Vector(0, 0, 300))

	Timers:CreateTimer(self.duration, function()
		if self.runes_fx then
			ParticleManager:DestroyParticle(self.runes_fx, false)
			ParticleManager:ReleaseParticleIndex(self.runes_fx)
		end
	end)

	self:StartIntervalThink(FrameTime())
end

function modifier_aoko_earthlight_caster:OnRefresh()
end

function modifier_aoko_earthlight_caster:OnIntervalThink()
	if not IsServer() then return end

	if not self.firing then
		self.point = GetGroundPosition(self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*self.succer_range, self.caster) + Vector(0, 0, 300)
		self.dummy:SetAbsOrigin(self.point)
	end

	self.duration = self.duration - FrameTime()

	if self.duration >= 0 then
		local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
		                                    self.point, 
		                                    nil, 
		                                    self.radius, 
		                                    DOTA_UNIT_TARGET_TEAM_ENEMY, 
		                                    DOTA_UNIT_TARGET_ALL, 
		                                    0, 
		                                    FIND_ANY_ORDER, 
		                                    false)

		local knockback1 = { should_stun = false,
	                        knockback_duration = 0.1,
	                        duration = 0.1,
	                        knockback_distance = -300/10,
	                        knockback_height = 0,
	                        center_x = self.point.x,
	                        center_y = self.point.y,
	                        center_z = self.point.z }

		for k,v in pairs(enemies) do
			v:AddNewModifier(self.caster, self.ability, "modifier_aoko_earthlight_enemy", {duration = 0.1})
			v:AddNewModifier(self.caster, self.ability, "modifier_aoko_earthlight_slow", {duration = 0.1 + FrameTime()})
			v:RemoveModifierByName("modifier_knockback")
	        v:AddNewModifier(self.caster, self.ability, "modifier_knockback", knockback1)
			--giveUnitDataDrivenModifier(self.caster, v, "locked", 0.1)
		end
	else
		if self.succing then
			self.succing = false
			self.state = { [MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_MUTED] = true,
			[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
		end
	end
end

function modifier_aoko_earthlight_caster:OnDestroy()
	if not IsServer() then return end

	self.caster:SwapAbilities("aoko_shield", "aoko_earthlight_starbow_recast", true, false)

	if self.dummy then
		self.dummy:RemoveModifierByName("modifier_aoko_earthlight_blackhole_fx")
	end
end

--

modifier_aoko_earthlight_blackhole_fx = class({})

function modifier_aoko_earthlight_blackhole_fx:IsHidden() return false end
function modifier_aoko_earthlight_blackhole_fx:IsDebuff() return false end

function modifier_aoko_earthlight_blackhole_fx:RemoveOnDeath() return true end

function modifier_aoko_earthlight_blackhole_fx:CheckState()
	return self.state
end

function modifier_aoko_earthlight_blackhole_fx:OnCreated(args)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.blackhole_fx = ParticleManager:CreateParticle("particles/aoko/aoko_cannon_blackhole.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleShouldCheckFoW(self.blackhole_fx, false)
	ParticleManager:SetParticleControl(self.blackhole_fx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.blackhole_fx, 3, self.parent:GetAbsOrigin())

	self:AddParticle(self.blackhole_fx, false, false, -1, false, false)
end

function modifier_aoko_earthlight_blackhole_fx:OnIntervalThink()
	if not IsServer() then return end
end

function modifier_aoko_earthlight_blackhole_fx:OnDestroy()
	if not IsServer() then return end

	self:GetParent():RemoveSelf()
end

--

modifier_aoko_earthlight_fire = class({})

function modifier_aoko_earthlight_fire:IsHidden() return false end
function modifier_aoko_earthlight_fire:IsDebuff() return false end

function modifier_aoko_earthlight_fire:RemoveOnDeath() return true end

function modifier_aoko_earthlight_fire:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_aoko_earthlight_fire:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.range = self.ability:GetSpecialValueFor("range")
	self.throw_range = self.ability:GetSpecialValueFor("throw_range")
	self.radius = self.ability:GetSpecialValueFor("width")
	self.damage = self.ability:GetSpecialValueFor("damage")
	self.stun_duration = self.ability:GetSpecialValueFor("wall_stun")

	self.forward = self.caster:GetForwardVector()

	self.delay = 2
	self.init_delay = 2
	self.played = false
	self.played2 = false

	self.fired = false

	self.diff = 0

	local mod = self.caster:FindModifierByName("modifier_aoko_earthlight_caster")
	if mod then
		mod.firing = true
		self.diff = mod.succer_range - 300
	end

	self.ori = self.caster:GetAbsOrigin()

	self.point = self.ori + self.forward*self.range

	self.damage_tick = FrameTime()*3

	-- whatever particle fuckery

	self.particle =    ParticleManager:CreateParticle("particles/aoko/aoko_cannon_big_beam_ground.vpcf", PATTACH_WORLDORIGIN, self.caster)
	                   ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	                   ParticleManager:SetParticleControl(self.particle, 0, self.ori)
	                   ParticleManager:SetParticleControl(self.particle, 1, self.ori)
	                   ParticleManager:SetParticleControl(self.particle, 2, self.point + self.forward*400)
	                   ParticleManager:SetParticleControl(self.particle, 3, Vector(self.radius, 0, self.delay + 2))

	self:AddParticle(self.particle, true, false, -1, false, false)

	self.particle2 =    ParticleManager:CreateParticle("particles/aoko/aoko_cannon_big_beam_runes.vpcf", PATTACH_ABSORIGIN, self.caster)
	                    ParticleManager:SetParticleShouldCheckFoW(self.particle2, false)
	                    ParticleManager:SetParticleControlEnt(self.particle2, 0, self.caster, PATTACH_ABSORIGIN, "attach_hitloc", self.caster:GetAbsOrigin(), true)

    self:AddParticle(self.particle2, false, false, -1, false, false)

	for i = 1,self.range/200 do
		SpawnVisionDummy(self.caster, self.ori + self.forward*200*i, self.radius, self.delay + 2, false)
	end

	self:StartIntervalThink(FrameTime())
end

function modifier_aoko_earthlight_fire:OnIntervalThink()
	self.ori = GetGroundPosition(self.caster:GetAbsOrigin(), self.caster)
	self.forward = self.caster:GetForwardVector()
	self.point = self.ori + self.forward*self.range

	if self.fired then
		local enemies = FATE_FindUnitsInLine(self.caster:GetTeamNumber(),
											self.ori,
											self.point,
											self.radius,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_ALL,
											0,
											FIND_ANY_ORDER)

		for k,v in pairs(enemies) do
			if IsInSameRealm(self.caster:GetAbsOrigin(), v:GetAbsOrigin()) then
				DoDamage(self.caster, v, self.damage/10, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
				if not v:HasModifier("modifier_master_intervention") then
					giveUnitDataDrivenModifier(self.caster, v, "locked", 0.1)
				end
			end
		end

		ParticleManager:SetParticleControl(self.particle2, 0, self.ori + Vector(0, 0, 300))
		ParticleManager:SetParticleControl(self.particle2, 1, self.ori + Vector(0, 0, 300))
		ParticleManager:SetParticleControl(self.particle2, 2, self.point + Vector(0, 0, 300))
		return
	end

	if self.init_delay - self.delay < 1 then
		self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() + Vector(0, 0, 8))
	elseif not self.played then
		self.played = true
		StartAnimation(self.caster, {duration=2, activity=ACT_SCRIPT_CUSTOM_11, rate=0.3})
	end

	if (self.init_delay - self.delay > 0.8) and not self.played2 then
		self.played2 = true
		EmitGlobalSound("aoko_earthlight_3")
	end

	self.delay = self.delay - FrameTime()

	local mod = self.caster:FindModifierByName("modifier_aoko_earthlight_caster")
	if mod then
		if self.delay > 0 then
			mod.point = GetGroundPosition(self.ori + self.forward*(self.delay/self.init_delay*self.diff + 300), self.caster) + Vector(0, 0, 300)
		
			mod.dummy:SetAbsOrigin(mod.point)
		end

		if self.delay <= 0 then
			self.fired = true

			EmitGlobalSound("aoko_slider_sfx")

			for k,v in pairs(mod.succed_enemies) do
				local target = EntIndexToHScript(k)

				target:RemoveModifierByName("modifier_aoko_earthlight_enemy")

				local initialUnitOrigin = target:GetAbsOrigin()

				local pushTarget = Physics:Unit(target)

				if not target:HasModifier("modifier_master_intervention") then
					giveUnitDataDrivenModifier(self.caster, target, "locked", 0.1)
				end

				if not IsKnockbackImmune(target) then
					target:PreventDI()
					target:SetPhysicsFriction(0)
					target:SetPhysicsVelocity(self.forward * 6000)
					target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
					target:OnPhysicsFrame(function(unit) 
						local unitOrigin = unit:GetAbsOrigin()
						local diff = unitOrigin - initialUnitOrigin
						local n_diff = diff:Normalized()
						unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
						if diff:Length() > (self.throw_range) then
							unit:PreventDI(false)
							unit:SetPhysicsVelocity(Vector(0,0,0))
							unit:OnPhysicsFrame(nil)
							FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
						end
					end)	
					target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
						unit:SetBounceMultiplier(0)
						unit:PreventDI(false)
						unit:SetPhysicsVelocity(Vector(0,0,0))
						giveUnitDataDrivenModifier(self.caster, target, "stunned", self.stun_duration)
						target:EmitSound("Hero_EarthShaker.Fissure")
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
						--DoDamage(caster, target, 200 + caster:GetStrength() * 3, DAMAGE_TYPE_PHYSICAL, 0, ability, false)	
					end)
				end
			end

			self.particle2 =    ParticleManager:CreateParticle("particles/aoko/aoko_cannon_big_beam.vpcf", PATTACH_WORLDORIGIN, self.caster)
			ParticleManager:SetParticleShouldCheckFoW(self.particle2, false)
			ParticleManager:SetParticleControl(self.particle2, 0, self.ori + Vector(0, 0, 300))
			ParticleManager:SetParticleControl(self.particle2, 1, self.ori + Vector(0, 0, 300))
			ParticleManager:SetParticleControl(self.particle2, 2, self.point + Vector(0, 0, 300))
			self:AddParticle(self.particle2, true, false, -1, false, false)

			self:StartIntervalThink(0.1)
		end
	end
end

function modifier_aoko_earthlight_fire:OnDestroy()
	if not IsServer() then return end

	if self.caster:HasModifier("modifier_aoko_earthlight_caster") then
		self.caster:RemoveModifierByName("modifier_aoko_earthlight_caster")
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_aoko_earthlight_mech", {duration = 0.2})
	end

	StartAnimation(self.caster, {duration=0.2, activity=ACT_SCRIPT_CUSTOM_14, rate=1.0})
	local pepega = 0
    Timers:CreateTimer(0, function()
	    local diff = 0
	    
	    if pepega < 6 then
       		diff = 40
        else
        	self.caster:RemoveModifierByName("modifier_aoko_earthlight_mech")
        	FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
        	return
        end

       	pepega = pepega + 1
   		self.caster:SetAbsOrigin(self.caster:GetAbsOrigin() - Vector(0, 0, diff))
   		
   		return FrameTime()
    end)
end

--

modifier_aoko_earthlight_mech = class({})

function modifier_aoko_earthlight_mech:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_aoko_earthlight_mech:IsHidden() return true end

--

modifier_aoko_earthlight_enemy = class({})

function modifier_aoko_earthlight_enemy:IsHidden() return false end
function modifier_aoko_earthlight_enemy:IsDebuff() return false end

function modifier_aoko_earthlight_enemy:RemoveOnDeath() return true end

function modifier_aoko_earthlight_enemy:DestroyOnExpire() return false end

function modifier_aoko_earthlight_enemy:CheckState()
	return self.state
end

function modifier_aoko_earthlight_enemy:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.state = {}

	self.entindex = self.parent:entindex()

	self.consumed = false

	self.duration = self.ability:GetSpecialValueFor("consume_time")

	self:StartIntervalThink(FrameTime())
end

function modifier_aoko_earthlight_enemy:OnRefresh()
end

function modifier_aoko_earthlight_enemy:OnIntervalThink()
	if not IsServer() then return end

	if not self.consumed then
		if self.caster:HasModifier("modifier_aoko_earthlight_caster") then
			self.duration = self.duration - FrameTime()

			if self.duration <= 0 then
				self.consumed = true
				self.state = { [MODIFIER_STATE_INVULNERABLE] = true,
							[MODIFIER_STATE_STUNNED] = true,
						 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
						 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
						 [MODIFIER_STATE_UNSELECTABLE] = true }

				self.parent:AddEffects(EF_NODRAW)

				self.caster:FindModifierByName("modifier_aoko_earthlight_caster").succed_enemies[self.entindex] = true
			end
		else
			self:Destroy()
			FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		end
	else
		if self.caster:HasModifier("modifier_aoko_earthlight_caster") then
			self.parent:SetAbsOrigin(self.caster:FindModifierByName("modifier_aoko_earthlight_caster").point)
		else
			self:Destroy()
			FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		end
	end
end

function modifier_aoko_earthlight_enemy:OnDestroy()
	if not IsServer() then return end

	if self.caster:HasModifier("modifier_aoko_earthlight_caster") then
		self.caster:FindModifierByName("modifier_aoko_earthlight_caster").succed_enemies[self.entindex] = false
	end

	if self.parent then
		self.parent:RemoveEffects(EF_NODRAW)
	end
end

modifier_aoko_earthlight_damage_field = class({})

function modifier_aoko_earthlight_damage_field:IsHidden() return true end
function modifier_aoko_earthlight_damage_field:IsDebuff() return false end

function modifier_aoko_earthlight_damage_field:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_aoko_earthlight_damage_field:OnCreated(args)
	if IsServer() then
		self.caster = self:GetCaster()
		local caster = self.caster
		self.ability = self:GetAbility()

		self.circuits = caster:FindAbilityByName("aoko_circuits")
		self.stacks = self.ability:GetSpecialValueFor("stack_gain")

		self.time_for_stack = 2/self.stacks

		self.elapsed = 0
		self.gained = 0

		self.radius = self.ability:GetSpecialValueFor("damage_radius")

		self.runes_fx = ParticleManager:CreateParticle("particles/aoko/aoko_cannon_runes.vpcf", PATTACH_ABSORIGIN, self.caster)
		ParticleManager:SetParticleControl(self.runes_fx, 0, self.caster:GetAbsOrigin())

		self:AddParticle(self.runes_fx, true, false, -1, false, false)

		self:StartIntervalThink(FrameTime())
		self:OnIntervalThink()
	end
end

function modifier_aoko_earthlight_damage_field:OnIntervalThink()
	if IsServer() then
		self.elapsed = self.elapsed + FrameTime()

		local diff = self.elapsed/self.time_for_stack - self.gained
		if diff > 1 then
			self.gained = self.gained + math.floor(diff)
			self.circuits:GainStacks(math.floor(diff))
		end

		local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                        self.caster:GetAbsOrigin(), 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

		for k,v in pairs(enemies) do
			v:AddNewModifier(self.caster, self.ability, "modifier_aoko_earthlight_slow", {duration = 0.1 + FrameTime()})
			giveUnitDataDrivenModifier(self.caster, v, "locked", 0.1)
		end

		self.lightning_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blue_lightning_beams.vpcf", PATTACH_WORLDORIGIN, self.caster)
		ParticleManager:SetParticleControl(self.lightning_fx, 3, RandomPointInCircle(GetGroundPosition(self.caster:GetAbsOrigin(), self.caster), self.radius*0.7))
		ParticleManager:ReleaseParticleIndex(self.lightning_fx)

		ParticleManager:SetParticleControl(self.runes_fx, 0, GetGroundPosition(self.caster:GetAbsOrigin(), self.caster))
	end
end

--

modifier_aoko_earthlight_slow = class({})

function modifier_aoko_earthlight_slow:IsHidden() return false end
function modifier_aoko_earthlight_slow:IsDebuff() return true end
function modifier_aoko_earthlight_slow:RemoveOnDeath() return true end
function modifier_aoko_earthlight_slow:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_earthlight_slow:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.damage = self.ability:GetSpecialValueFor("damage_per_second")*0.1

	self:StartIntervalThink(0.1)
end

function modifier_aoko_earthlight_slow:OnIntervalThink()
	if not IsServer() then return end

	DoDamage(self.caster, self.parent, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end

function modifier_aoko_earthlight_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self.ability:GetSpecialValueFor("slow")
end