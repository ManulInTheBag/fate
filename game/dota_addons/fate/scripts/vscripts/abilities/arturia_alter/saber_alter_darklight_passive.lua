saber_alter_darklight_passive = class({})

LinkLuaModifier("modifier_darklight", "abilities/arturia_alter/saber_alter_darklight_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_darklight_crit_hit", "abilities/arturia_alter/saber_alter_darklight_passive", LUA_MODIFIER_MOTION_NONE)

function saber_alter_darklight_passive:GetIntrinsicModifierName()
	return "modifier_darklight"
end

-- +75 attack damage; 35% chance rolled on every attack start to load a crit
modifier_darklight = class({})

function modifier_darklight:IsHidden()
	return false
end

function modifier_darklight:IsPurgable()
	return false
end

function modifier_darklight:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_darklight:GetModifierPreAttack_BonusDamage()
	return 75
end

function modifier_darklight:OnAttackStart(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	if keys.attacker ~= parent then return end

	parent:RemoveModifierByName("modifier_darklight_crit_hit")

	if RollPercentage(35) then
		parent:AddNewModifier(parent, self:GetAbility(), "modifier_darklight_crit_hit", {})
	end
end

-- Loaded crit: 175% on the next landed attack, disarms the victim for 0.5s
modifier_darklight_crit_hit = class({})

function modifier_darklight_crit_hit:IsHidden()
	return true
end

function modifier_darklight_crit_hit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_darklight_crit_hit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_darklight_crit_hit:GetModifierPreAttack_CriticalStrike()
	return 175
end

function modifier_darklight_crit_hit:OnAttackLanded(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	if keys.attacker ~= parent then return end

	local target = keys.target
	if target then
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/jugg_crit_blur_impact.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(fx)
		target:AddNewModifier(parent, self:GetAbility(), "modifier_disarmed", { duration = 0.5 })
	end

	parent:RemoveModifierByName("modifier_darklight_crit_hit")
end
