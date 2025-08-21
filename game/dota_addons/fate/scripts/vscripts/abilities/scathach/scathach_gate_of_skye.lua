LinkLuaModifier("modifier_scathach_gate_of_skye_dummy", "abilities/scathach/scathach_gate_of_skye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_gate_of_skye_dummy_active", "abilities/scathach/scathach_gate_of_skye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_gate_of_skye_execute", "abilities/scathach/scathach_gate_of_skye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_gate_of_skye_slow", "abilities/scathach/scathach_gate_of_skye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_gate_of_skye_cd", "abilities/scathach/scathach_gate_of_skye", LUA_MODIFIER_MOTION_NONE)

scathach_gate_of_skye = class({})

function scathach_gate_of_skye:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local anim_duration = self:GetSpecialValueFor("anim_duration")
	local active_duration = self:GetSpecialValueFor("active_duration")

	local duration = anim_duration + active_duration

	caster:EmitSound("Scathach.Gate_Cast")
	caster:EmitSound("Hero_Mars.ArenaOfBlood.Crumble")

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("scathach_gate_of_skye")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:RemoveModifierByName("modifier_scathach_combo_window")

    caster:AddNewModifier(caster, self, "modifier_scathach_gate_of_skye_cd", {duration = self:GetCooldown(1)})

	self.dummy = CreateUnitByName("dummy_unit", target, false, nil, nil, caster:GetTeamNumber())
	self.dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.dummy:SetForwardVector(caster:GetForwardVector())
	self.dummy:AddNewModifier(caster, self, "modifier_scathach_gate_of_skye_dummy", {duration  = duration})
	AddFOWViewer(2, self.dummy:GetAbsOrigin(), 40, duration, false)
	AddFOWViewer(3, self.dummy:GetAbsOrigin(), 40, duration, false)	
end

modifier_scathach_gate_of_skye_dummy = class({})

function modifier_scathach_gate_of_skye_dummy:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.ori = self.parent:GetAbsOrigin() - Vector(0, 0, 660)

	self.timer = 0
	self.active_duration = self.ability:GetSpecialValueFor("active_duration")
	self.anim_duration = self.ability:GetSpecialValueFor("anim_duration")

	self.gate_fx = ParticleManager:CreateParticle("particles/custom/scathach/scathach_gate.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.gate_fx, 0, self.ori)
	
	self:AddParticle(self.gate_fx, true, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_scathach_gate_of_skye_dummy:OnIntervalThink()
	if not IsServer() then return end

	self.timer = self.timer + FrameTime()
	self.ori = self.ori + Vector(0, 0, 10)
	ParticleManager:SetParticleControl(self.gate_fx, 0, self.ori)
	ParticleManager:SetParticleControl(self.gate_fx, 1, self.ori)

	if self.timer >= self.anim_duration then
		self:StartIntervalThink(-1)

		self.parent:AddNewModifier(self.caster, self.ability, "modifier_scathach_gate_of_skye_dummy_active", {duration = self.active_duration})
	end
end

modifier_scathach_gate_of_skye_dummy_active = class({})

function modifier_scathach_gate_of_skye_dummy_active:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.ori = self.parent:GetAbsOrigin()

	self.radius = self.ability:GetSpecialValueFor("radius")
	self.damage = self.ability:GetSpecialValueFor("damage_per_second")
	self.execute_threshold = self.ability:GetSpecialValueFor("execute_threshold")
	self.execute_duration = self.ability:GetSpecialValueFor("execute_duration")

	self.timer = 2.2
	self.timer2 = 0.1
	self.pepega = false

	self.ring_fx = ParticleManager:CreateParticle("particles/scathach/scathach_gate_aoe_ring.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.ring_fx, 0, self.ori)
	ParticleManager:SetParticleControl(self.ring_fx, 1, Vector(self.radius, 0, 0))
	
	self:AddParticle(self.ring_fx, true, false, -1, false, false)

	EmitGlobalSound("Scathach.Gate_Post")

	--EmitGlobalSound("gate_of_skye_fog")
	EmitSoundOn("hero_Crystal.freezingField.wind", self:GetParent())
	EmitGlobalSound("gate_of_skye_door")
	EmitSoundOn("gate_of_skye_fog", self:GetParent())

	local particle_cast = "particles/custom/scathach/gate_of_skye_field.vpcf"
	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	self:StartIntervalThink(FrameTime())	
end

function modifier_scathach_gate_of_skye_dummy_active:OnIntervalThink()
	if not IsServer() then return end

	self.timer = self.timer - FrameTime()
	self.timer2 = self.timer2 - FrameTime()

	if (self.timer) < 0 and (not self.pepega) then
		self.pepega = true
		self.timer = 1.0

		EmitGlobalSound("Scathach.Gate_Of_Sky")
	end
	if self.timer < 0 then
		self.timer = 10
		local particle_cast = "particles/custom/scathach/gate_of_skye_field.vpcf"
		-- Create Particle
		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end

	local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                            self.parent:GetAbsOrigin(), 
	                                            nil, 
	                                            self.radius, 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)
	for _,enemy in ipairs(enemies) do
		if self.timer2 <= 0 then
			self.timer2 = 0.1
			DoDamage(self.caster, enemy, self.damage/10, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
		end
		if (not enemy:HasModifier("modifier_scathach_gate_of_skye_execute")) and ((enemy:GetHealth()/enemy:GetMaxHealth()*100) < self.execute_threshold) then
			enemy:AddNewModifier(self.caster, self.ability, "modifier_scathach_gate_of_skye_execute", {duration = self.execute_duration, center_unit = self.parent:entindex()})
		end
		enemy:AddNewModifier(self.caster, self.ability, "modifier_heal_reduction_tier_2", {duration = FrameTime()*3})
		enemy:AddNewModifier(self.caster, self.ability, "modifier_scathach_gate_of_skye_slow", {duration = FrameTime()*3})
	end
end

function modifier_scathach_gate_of_skye_dummy_active:OnDestroy()
	if not IsServer() then return end

	local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                            self.parent:GetAbsOrigin(), 
	                                            nil, 
	                                            self.radius, 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)
	for _,enemy in ipairs(enemies) do
		if enemy:HasModifier("modifier_scathach_gate_of_skye_execute") then
			enemy:RemoveModifierByName("modifier_scathach_gate_of_skye_execute")
		end
	end

	local enemies2 = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                            self.parent:GetAbsOrigin(), 
	                                            nil, 
	                                            999999, 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)
	for _,enemy in ipairs(enemies2) do
		if enemy:HasModifier("modifier_scathach_gate_of_skye_execute") then
			enemy:FindModifierByName("modifier_scathach_gate_of_skye_execute").safe = true
		end
		enemy:RemoveModifierByName("modifier_scathach_gate_of_skye_execute")
	end
end

modifier_scathach_gate_of_skye_execute = class({})

function modifier_scathach_gate_of_skye_execute:OnCreated(args)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.execute_threshold = self.ability:GetSpecialValueFor("execute_threshold")

	self.safe = false

	self.center_unit = EntIndexToHScript(args.center_unit)

	self.soul_fx = ParticleManager:CreateParticle("particles/scathach/scathach_gate_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControlEnt(self.soul_fx,	1, self.center_unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0,0,0), true)

	self:AddParticle(self.soul_fx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_scathach_gate_of_skye_execute:OnIntervalThink()
	if not IsServer() then return end

	if (self.parent:GetHealth()/self.parent:GetMaxHealth()*100) > self.execute_threshold then
		self.safe = true
		self:Destroy()
	end
end

function modifier_scathach_gate_of_skye_execute:TriggerDeath()
	if not IsServer() then return end

	self.parent:Execute(self, self.caster, { bExecution = true })
end

function modifier_scathach_gate_of_skye_execute:OnDestroy()
	if not IsServer() then return end

	if not self.safe then
		self:TriggerDeath()
	end
end

modifier_scathach_gate_of_skye_slow = class({})

function modifier_scathach_gate_of_skye_slow:IsHidden() return true end
function modifier_scathach_gate_of_skye_slow:IsDebuff() return true end
function modifier_scathach_gate_of_skye_slow:RemoveOnDeath() return true end
function modifier_scathach_gate_of_skye_slow:DeclareFunctions()
	return {	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	}
end
function modifier_scathach_gate_of_skye_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow")
end

modifier_scathach_gate_of_skye_cd = class({})

function modifier_scathach_gate_of_skye_cd:GetTexture()
	return "custom/scathach/scathach_combo_gate_of_sky"
end

function modifier_scathach_gate_of_skye_cd:IsHidden()
	return false 
end

function modifier_scathach_gate_of_skye_cd:RemoveOnDeath()
	return false
end

function modifier_scathach_gate_of_skye_cd:IsDebuff()
	return true 
end

function modifier_scathach_gate_of_skye_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end