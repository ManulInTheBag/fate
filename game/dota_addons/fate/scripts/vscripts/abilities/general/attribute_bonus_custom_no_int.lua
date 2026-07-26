-- attribute_bonus_custom_no_int — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

attribute_bonus_custom_no_int = class({})

LinkLuaModifier("modifier_all_stats_no_int", "abilities/general/attribute_bonus_custom_no_int", LUA_MODIFIER_MOTION_NONE)

function attribute_bonus_custom_no_int:GetIntrinsicModifierName()
	return "modifier_all_stats_no_int"
end

modifier_all_stats_no_int = class({})

function modifier_all_stats_no_int:IsHidden() return true end

function modifier_all_stats_no_int:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function modifier_all_stats_no_int:GetModifierBonusStats_Strength()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("stats")
end
function modifier_all_stats_no_int:GetModifierBonusStats_Agility()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("stats")
end
