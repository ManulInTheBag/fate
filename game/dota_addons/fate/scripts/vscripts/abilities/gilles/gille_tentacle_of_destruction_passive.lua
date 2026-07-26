-- gille_tentacle_of_destruction_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_old_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gille_tentacle_of_destruction_passive = class({})

LinkLuaModifier("modifier_tentacle_of_destruction_passive", "abilities/gilles/gille_tentacle_of_destruction_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTentacleAttackLanded

OnTentacleAttackLanded = function(keys)
	local target = keys.target
	local damage = target:GetMaxHealth() * keys.Damage/100
	DoDamage(keys.attacker, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end


function gille_tentacle_of_destruction_passive:GetIntrinsicModifierName()
	return "modifier_tentacle_of_destruction_passive"
end

modifier_tentacle_of_destruction_passive = class({})

function modifier_tentacle_of_destruction_passive:IsHidden() return true end

function modifier_tentacle_of_destruction_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_tentacle_of_destruction_passive:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_tentacle_of_destruction_passive:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_Magnataur.PreAttack", self:GetCaster())
end

function modifier_tentacle_of_destruction_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_Treant.Attack", self:GetCaster())
	-- DD RunScript: gille_ability / OnTentacleAttackLanded
	OnTentacleAttackLanded({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		Damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	})
end
