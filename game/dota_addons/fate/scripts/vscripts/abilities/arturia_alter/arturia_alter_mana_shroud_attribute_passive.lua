arturia_alter_mana_shroud = class({})

LinkLuaModifier("modifier_mana_shroud", "abilities/arturia_alter/arturia_alter_mana_shroud_attribute_passive", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_mana_shroud:GetIntrinsicModifierName()
    return "modifier_mana_shroud"
end

modifier_mana_shroud = class({})

function modifier_mana_shroud:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE}
end

function modifier_mana_shroud:GetModifierTotalPercentageManaRegen()
	return 2
end

arturia_alter_mana_shroud_attribute_passive = class({})

LinkLuaModifier("modifier_mana_shroud_bonus_mana", "abilities/arturia_alter/modifiers/modifier_mana_shroud_bonus_mana", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_mana_shroud_attribute_passive:GetIntrinsicModifierName()
	return "modifier_mana_shroud_bonus_mana"
end