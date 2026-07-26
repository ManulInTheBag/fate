-- saber_alter_darklight_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber_alter/saber_alter_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_alter_darklight_passive = class({})

LinkLuaModifier("modifier_darklight", "abilities/saber_alter/saber_alter_darklight_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_darklight_crit_hit", "abilities/saber_alter/saber_alter_darklight_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDarklightCrit, OnDarklightCritHit

OnDarklightCrit = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_darklight_crit_hit", {})
end

OnDarklightCritHit = function(keys)
	local caster = keys.caster
	local hTarget = keys.target
	local ability = keys.ability
	hTarget:AddNewModifier(caster, ability, "modifier_disarmed", { duration = 0.5 })
end


function saber_alter_darklight_passive:GetIntrinsicModifierName()
	return "modifier_darklight"
end

modifier_darklight = class({})

function modifier_darklight:IsHidden() return false end

function modifier_darklight:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_darklight:GetModifierPreAttack_BonusDamage()
	return 75
end

function modifier_darklight:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():RemoveModifierByName("modifier_darklight_crit_hit")
	if RollPercentage(35) then
		-- DD RunScript: saber_alter_ability / OnDarklightCrit
		OnDarklightCrit({
			caster = self:GetCaster(),
			ability = self:GetAbility(),
			unit = self:GetParent(),
			attacker = params.attacker,
			target = params.target
		})
	end
end

modifier_darklight_crit_hit = class({})

function modifier_darklight_crit_hit:IsHidden() return true end
function modifier_darklight_crit_hit:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_darklight_crit_hit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_darklight_crit_hit:GetModifierPreAttack_CriticalStrike()
	return 175
end

function modifier_darklight_crit_hit:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/jugg_crit_blur_impact.vpcf", PATTACH_POINT, params.target)
	ParticleManager:ReleaseParticleIndex(fx)
	-- DD RunScript: saber_alter_ability / OnDarklightCritHit
	OnDarklightCritHit({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
	self:GetCaster():RemoveModifierByName("modifier_darklight_crit_hit")
end
