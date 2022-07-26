arturia_alter_mana_shroud_attribute_passive = class({})

LinkLuaModifier("modifier_mana_shroud_bonus_mana", "abilities/arturia_alter/modifiers/modifier_mana_shroud_bonus_mana", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_mana_shroud_attribute_passive:GetIntrinsicModifierName()
	return "modifier_mana_shroud_bonus_mana"
end