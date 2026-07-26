-- attribute_bonus_custom — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

attribute_bonus_custom = class({})

LinkLuaModifier("modifier_all_stats", "abilities/general/attribute_bonus_custom", LUA_MODIFIER_MOTION_NONE)

function attribute_bonus_custom:GetIntrinsicModifierName()
	return "modifier_all_stats"
end

modifier_all_stats = class({})

function modifier_all_stats:IsHidden() return true end

function modifier_all_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function modifier_all_stats:GetModifierBonusStats_Intellect()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("stats")
end
function modifier_all_stats:GetModifierBonusStats_Strength()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("stats")
end
function modifier_all_stats:GetModifierBonusStats_Agility()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("stats")
end
