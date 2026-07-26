-- caster_5th_skeleton_bash — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_skeleton_bash = class({})

LinkLuaModifier("modifier_skeleton_bash", "abilities/medea/caster_5th_skeleton_bash", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSkeleBashSucceed

OnSkeleBashSucceed = function(keys)
	local caster = keys.caster
	local target = keys.target
	target:AddNewModifier(caster, target, "modifier_stunned", {Duration = keys.BashDuration})
	DoDamage(caster, target, 100, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	caster:Kill(keys.ability, caster)
end


function caster_5th_skeleton_bash:GetIntrinsicModifierName()
	return "modifier_skeleton_bash"
end

modifier_skeleton_bash = class({})

function modifier_skeleton_bash:IsHidden() return true end

function modifier_skeleton_bash:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_skeleton_bash:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	if RollPercentage(self:GetAbility():GetSpecialValueFor("bash_chance")) then
		-- DD RunScript: caster_ability / OnSkeleBashSucceed
		OnSkeleBashSucceed({
			caster = self:GetCaster(),
			ability = self:GetAbility(),
			unit = self:GetParent(),
			attacker = params.attacker,
			target = params.target,
			BashDuration = self:GetAbility():GetSpecialValueFor("bash_duration")
		})
	end
end
