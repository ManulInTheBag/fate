-- caster_5th_skeleton_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_skeleton_passive = class({})

LinkLuaModifier("modifier_skeleton_health_decay", "abilities/medea/caster_5th_skeleton_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local StopAttack

StopAttack = function(keys)
	local caster = keys.caster
	local target = keys.target
	--if target:GetUnitName() == "ward_familiar" then caster:Stop() end
end


function caster_5th_skeleton_passive:GetIntrinsicModifierName()
	return "modifier_skeleton_health_decay"
end

modifier_skeleton_health_decay = class({})

function modifier_skeleton_health_decay:IsHidden() return true end

function modifier_skeleton_health_decay:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_skeleton_health_decay:GetModifierHealthRegenPercentage()
	return -2.5
end
function modifier_skeleton_health_decay:GetModifierMagicalResistanceDecrepifyUnique()
	return -100
end

function modifier_skeleton_health_decay:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: caster_ability / StopAttack
	StopAttack({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
end
