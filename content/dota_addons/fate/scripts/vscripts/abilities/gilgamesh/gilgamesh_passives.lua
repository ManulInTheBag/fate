gilgamesh_rain_of_swords_passive = class({})

LinkLuaModifier("modifier_rain_of_swords_attribute", "abilities/gilgamesh/modifiers/modifier_rain_of_swords_attribute", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_rain_of_swords_passive:GetIntrinsicModifierName()
	return "modifier_rain_of_swords_attribute"
end