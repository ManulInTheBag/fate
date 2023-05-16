LinkLuaModifier("modifier_jeanne_saint_passive", "abilities/jeanne/jeanne_saint", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_saint_aura", "abilities/jeanne/jeanne_saint", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_saint", "abilities/jeanne/jeanne_saint", LUA_MODIFIER_MOTION_NONE)

jeanne_saint = class({})

function jeanne_saint:GetIntrinsicModifierName()
	return "modifier_jeanne_saint_passive"
end

modifier_jeanne_saint_passive = class({})

function modifier_jeanne_saint_passive:IsHidden() return true end
function modifier_jeanne_saint_passive:IsDebuff() return false end
function modifier_jeanne_saint_passive:RemoveOnDeath() return false end
function modifier_jeanne_saint_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_jeanne_saint_passive:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_jeanne_saint_passive:OnTakeDamage(args)
	if args.attacker ~= self.parent then return end

	self.parent:AddNewModifier(self.parent, self.ability, "modifier_jeanne_saint_aura", {duration = self.ability:GetSpecialValueFor("duration")})
end

-----

modifier_jeanne_saint_aura = class({})

function modifier_jeanne_saint_aura:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")

	self.jeanne_charisma_particle = ParticleManager:CreateParticle("particles/custom/ruler/charisma/buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)

	ParticleManager:SetParticleControl(self.jeanne_charisma_particle, 1, Vector(0,0,0))

	self:AddParticle(self.jeanne_charisma_particle, false, false, -1, false, false)

	self:StartIntervalThink(1.0)
	self:PlayEffects()
end

function modifier_jeanne_saint_aura:OnRefresh()
	self.radius = self.ability:GetSpecialValueFor("radius")
	--ParticleManager:SetParticleControl(self.jeanne_charisma_particle, 1, Vector(0,0,0))
end

function modifier_jeanne_saint_aura:OnIntervalThink()
	self:PlayEffects()
end

function modifier_jeanne_saint_aura:PlayEffects()
	if IsServer() then
		local heal = self.ability:GetSpecialValueFor("heal")
		local duration = self.ability:GetSpecialValueFor("regen_duration")

		local targets = FindUnitsInRadius(self.caster:GetTeam(), self.caster:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do				
		    v:Heal(heal, self.ability)
		    v:AddNewModifier(self.caster, self.ability, "modifier_jeanne_saint", {duration = duration})
		end

		local ring_fx = ParticleManager:CreateParticle( "particles/jeanne/jeanne_saint_burst.vpcf", PATTACH_ABSORIGIN, self.caster)
		ParticleManager:SetParticleControl(ring_fx, 0, self.caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(ring_fx, 2, Vector(self.radius, 0, 0))

		ParticleManager:ReleaseParticleIndex(ring_fx)
	end
end

function modifier_jeanne_saint_aura:IsHidden()
	return false
end

function modifier_jeanne_saint_aura:RemoveOnDeath()
	return true
end

function modifier_jeanne_saint_aura:IsDebuff()
	return false 
end

function modifier_jeanne_saint_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

----

modifier_jeanne_saint = class({})

function modifier_jeanne_saint:IsHidden() return false end
function modifier_jeanne_saint:IsDebuff() return false end

function modifier_jeanne_saint:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT}
end

function modifier_jeanne_saint:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("hp_regen_const")
end

function modifier_jeanne_saint:OnCreated()
	local jeanne_charisma_particle = ParticleManager:CreateParticle("particles/jeanne/jeanne_charisma_regen.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())

	ParticleManager:SetParticleControl(jeanne_charisma_particle, 1, Vector(0,0,0))

	self:AddParticle(jeanne_charisma_particle, false, false, -1, false, false)

	local effect_target = ParticleManager:CreateParticle( "particles/jeanne/jeanne_saint_heal_apply.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(effect_target, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:ReleaseParticleIndex( effect_target )
end

function modifier_jeanne_saint:OnRefresh()
	local effect_target = ParticleManager:CreateParticle( "particles/jeanne/jeanne_saint_heal_apply.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(effect_target, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:ReleaseParticleIndex( effect_target )
end