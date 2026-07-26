-- gilgamesh_golden_rule — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilgamesh/gilgamesh_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gilgamesh_golden_rule = class({})

LinkLuaModifier("modifier_golden_rule", "abilities/gilgamesh/gilgamesh_golden_rule", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gilg_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGoldenRuleThink

OnGoldenRuleThink = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
    if caster:IsAlive() and GameRules:GetGameTime() > 75 then keys.caster:ModifyGold(keys.GoldGain, false, 0) end
end


function gilgamesh_golden_rule:GetIntrinsicModifierName()
	return "modifier_golden_rule"
end

modifier_golden_rule = class({})


function modifier_golden_rule:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_golden_rule:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_golden_rule:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: gilg_ability / OnGoldenRuleThink
	OnGoldenRuleThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		GoldGain = self:GetAbility():GetSpecialValueFor("gold_gain")
	})
end
