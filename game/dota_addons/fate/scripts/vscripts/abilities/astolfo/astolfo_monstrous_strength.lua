-- astolfo_monstrous_strength — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_monstrous_strength = class({})

LinkLuaModifier("modifier_astolfo_monstrous_strength", "abilities/astolfo/astolfo_monstrous_strength", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMStrengthHit

OnMStrengthHit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	DoDamage(caster, target, 8*caster:GetMaxHealth()/100 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	giveUnitDataDrivenModifier(caster, target, "modifier_rooted", 0.5)
	caster:EmitSound("Astolfo_Sanity_" .. RandomInt(1, 8))
	--[[if not caster:HasModifier("modifier_astolfo_disable_mstrength") then
		DoDamage(caster, caster, 4*caster:GetHealth()/100 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end]]
end


function astolfo_monstrous_strength:GetIntrinsicModifierName()
	return "modifier_astolfo_monstrous_strength"
end

modifier_astolfo_monstrous_strength = class({})

function modifier_astolfo_monstrous_strength:IsHidden() return true end

function modifier_astolfo_monstrous_strength:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_astolfo_monstrous_strength:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: astolfo_ability / OnMStrengthHit
	OnMStrengthHit({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
end
