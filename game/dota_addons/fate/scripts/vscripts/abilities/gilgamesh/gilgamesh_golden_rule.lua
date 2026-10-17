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


function modifier_golden_rule:IsHidden() return self:GetStackCount() == 0 end
function modifier_golden_rule:IsPurgable() return false end
function modifier_golden_rule:RemoveOnDeath() return false end

function modifier_golden_rule:OnCreated(kv)
	if not IsServer() then return end
	self.gold_timer = 0
	self:StartIntervalThink(0.2)
	self:UpdateGoldStacks()
end

function modifier_golden_rule:OnRefresh(kv)
	self:OnCreated(kv)
end

-- стаки = полные тысячи золота Гильгамеша (до bonus_gold_max), по ним бонусы считаются и на клиенте.
-- Только с атрибутом Improve Golden Rule — он переводит способность на 2-й уровень.
function modifier_golden_rule:UpdateGoldStacks()
	local ability = self:GetAbility()
	local stacks = 0
	if ability:GetLevel() >= 2 then
		local step = ability:GetSpecialValueFor("bonus_gold_step")
		local gold = math.min(self:GetParent():GetGold(), ability:GetSpecialValueFor("bonus_gold_max"))
		stacks = math.floor(gold / step)
	end
	if stacks ~= self:GetStackCount() then
		self:SetStackCount(stacks)
	end
end

function modifier_golden_rule:OnIntervalThink()
	if not IsServer() then return end
	self:UpdateGoldStacks()

	self.gold_timer = self.gold_timer + 0.2
	if self.gold_timer < 1.0 - 0.01 then return end
	self.gold_timer = 0
	-- DD RunScript: gilg_ability / OnGoldenRuleThink
	OnGoldenRuleThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		GoldGain = self:GetAbility():GetSpecialValueFor("gold_gain")
	})
end

function modifier_golden_rule:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_golden_rule:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_golden_rule:GetModifierConstantManaRegen()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_golden_rule:GetModifierConstantHealthRegen()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end
