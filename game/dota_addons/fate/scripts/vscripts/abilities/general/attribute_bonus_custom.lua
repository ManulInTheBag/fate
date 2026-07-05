-- Stat Bonus (+3/6/9/12/15/18/21 all stats), lua port of the old
-- datadriven attribute_bonus_custom / attribute_bonus_custom_no_int.
attribute_bonus_custom = class({})
attribute_bonus_custom_no_int = class({})

LinkLuaModifier("modifier_attribute_bonus_custom", "abilities/general/attribute_bonus_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_attribute_bonus_custom_no_int", "abilities/general/attribute_bonus_custom", LUA_MODIFIER_MOTION_NONE)

function attribute_bonus_custom:GetIntrinsicModifierName()
	return "modifier_attribute_bonus_custom"
end

function attribute_bonus_custom_no_int:GetIntrinsicModifierName()
	return "modifier_attribute_bonus_custom_no_int"
end

modifier_attribute_bonus_custom = class({})

function modifier_attribute_bonus_custom:IsHidden() return true end
function modifier_attribute_bonus_custom:IsPurgable() return false end
function modifier_attribute_bonus_custom:RemoveOnDeath() return false end
function modifier_attribute_bonus_custom:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_attribute_bonus_custom:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_attribute_bonus_custom:_Stats()
	local hAbility = self:GetAbility()
	if not hAbility or hAbility:IsNull() or hAbility:GetLevel() < 1 then return 0 end
	return hAbility:GetSpecialValueFor("stats")
end

function modifier_attribute_bonus_custom:GetModifierBonusStats_Strength()  return self:_Stats() end
function modifier_attribute_bonus_custom:GetModifierBonusStats_Agility()   return self:_Stats() end
function modifier_attribute_bonus_custom:GetModifierBonusStats_Intellect() return self:_Stats() end

modifier_attribute_bonus_custom_no_int = class(modifier_attribute_bonus_custom)

function modifier_attribute_bonus_custom_no_int:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
end

function modifier_attribute_bonus_custom_no_int:GetModifierBonusStats_Intellect() return 0 end
