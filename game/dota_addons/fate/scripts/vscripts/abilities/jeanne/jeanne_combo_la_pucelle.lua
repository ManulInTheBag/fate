-- Lua port of the old datadriven jeanne_combo_la_pucelle (level 25 combo:
-- on lethal damage the hero revives into an invulnerable burning spirit form).
-- Logic stays in jeanne_ability.lua (OnLaPucelleTakeDamage / Think / Death).
require('jeanne_ability')

jeanne_combo_la_pucelle = class({})

local THIS = "abilities/jeanne/jeanne_combo_la_pucelle"
LinkLuaModifier("modifier_la_pucelle", THIS, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_pucelle_spirit_form", THIS, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_pucelle_anim", THIS, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_pucelle_cooldown", "abilities/jeanne/modifiers/modifier_la_pucelle_cooldown", LUA_MODIFIER_MOTION_NONE)

function jeanne_combo_la_pucelle:GetIntrinsicModifierName()
	return "modifier_la_pucelle"
end

-- watcher: fires the revive when the hero drops to 0 hp
modifier_la_pucelle = class({})

function modifier_la_pucelle:IsHidden() return true end
function modifier_la_pucelle:IsPurgable() return false end

function modifier_la_pucelle:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_la_pucelle:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	local ability = self:GetAbility()
	if ability:GetLevel() < 1 then return end
	OnLaPucelleTakeDamage({
		caster   = self:GetParent(),
		ability  = ability,
		attacker = params.attacker,
		Duration = ability:GetSpecialValueFor("duration"),
		Delay    = ability:GetSpecialValueFor("delay"),
	})
end

-- the spirit form itself
modifier_la_pucelle_spirit_form = class({})

function modifier_la_pucelle_spirit_form:IsPurgable() return false end

function modifier_la_pucelle_spirit_form:GetEffectName()
	return "particles/custom/ruler/la_pucelle/ruler_la_pucelle.vpcf"
end
function modifier_la_pucelle_spirit_form:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_la_pucelle_spirit_form:GetStatusEffectName()
	return "particles/status_fx/status_effect_keeper_spirit_form.vpcf"
end
function modifier_la_pucelle_spirit_form:StatusEffectPriority()
	return 10
end

function modifier_la_pucelle_spirit_form:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE]      = true,
		[MODIFIER_STATE_SILENCED]          = true,
		[MODIFIER_STATE_NO_HEALTH_BAR]     = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_la_pucelle_spirit_form:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
end

function modifier_la_pucelle_spirit_form:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_aspd")
end
function modifier_la_pucelle_spirit_form:GetModifierMoveSpeedBonus_Percentage() return 50 end
function modifier_la_pucelle_spirit_form:GetModifierHealthBonus() return 99999999 end
function modifier_la_pucelle_spirit_form:GetBonusDayVision() return 1000 end
function modifier_la_pucelle_spirit_form:GetBonusNightVision() return 1000 end
function modifier_la_pucelle_spirit_form:GetModifierAttackRangeBonus() return 100 end

function modifier_la_pucelle_spirit_form:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_la_pucelle_spirit_form:OnIntervalThink()
	local ability = self:GetAbility()
	OnLaPucelleThink({
		caster  = self:GetParent(),
		ability = ability,
		Damage  = ability:GetSpecialValueFor("flame_damage_per_sec"),
	})
end

function modifier_la_pucelle_spirit_form:OnDestroy()
	if not IsServer() then return end
	OnLaPucelleDeath({ caster = self:GetParent(), ability = self:GetAbility() })
end

-- cast animation lock during the ascension delay
modifier_la_pucelle_anim = class({})

function modifier_la_pucelle_anim:IsHidden() return true end
function modifier_la_pucelle_anim:IsPurgable() return false end

function modifier_la_pucelle_anim:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end

function modifier_la_pucelle_anim:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_4 end
function modifier_la_pucelle_anim:GetOverrideAnimationRate() return 1.0 end
