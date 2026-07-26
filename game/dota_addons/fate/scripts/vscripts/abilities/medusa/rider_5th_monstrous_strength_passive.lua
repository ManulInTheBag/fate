-- rider_5th_monstrous_strength_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medusa/medusa_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

rider_5th_monstrous_strength_passive = class({})

LinkLuaModifier("modifier_monstrous_strength_passive", "abilities/medusa/rider_5th_monstrous_strength_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/rider_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMonstrousStrengthProc

OnMonstrousStrengthProc = function(keys)
	local hTarget = keys.target
	local hCaster = keys.caster
	local hAbility = keys.ability
	local fStunDuration = 0.1
	local fDamage = 75

	if hTarget:HasModifier("modifier_breaker_gorgon") then
		fStunDuration = 0.5
		fDamage = 250
	end

	hTarget:AddNewModifier(hCaster, hAbility, "modifier_disarmed", { duration = fStunDuration })
	DoDamage(hCaster, hTarget, fDamage , DAMAGE_TYPE_PHYSICAL, 0, hAbility, false)
end


function rider_5th_monstrous_strength_passive:GetIntrinsicModifierName()
	return "modifier_monstrous_strength_passive"
end

modifier_monstrous_strength_passive = class({})

function modifier_monstrous_strength_passive:IsHidden() return false end

function modifier_monstrous_strength_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_monstrous_strength_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	if RollPercentage(70) then
		-- DD RunScript: rider_ability / OnMonstrousStrengthProc
		OnMonstrousStrengthProc({
			caster = self:GetCaster(),
			ability = self:GetAbility(),
			unit = self:GetParent(),
			attacker = params.attacker,
			target = params.target
		})
	end
end
