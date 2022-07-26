semiramis_poisonous_cloud = class({})

LinkLuaModifier("modifier_poison_cloud_aura", "abilities/semiramis/modifiers/modifier_poison_cloud_aura", LUA_MODIFIER_MOTION_NONE)

function semiramis_poisonous_cloud:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function semiramis_poisonous_cloud:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function semiramis_poisonous_cloud:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	CreateModifierThinker(caster, ability, "modifier_poison_cloud_aura", { Duration = self:GetSpecialValueFor("duration"),
																		   PoisonDamage = self:GetSpecialValueFor("damage"),
																		   AOE = self:GetAOERadius(),
																		   PoisonDuration = self:GetSpecialValueFor("poison_duration"),
																		   ResistReduc = self:GetSpecialValueFor("resist_reduc") }
							, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
end