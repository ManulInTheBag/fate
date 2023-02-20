-----------------------------
--    Charisma    --
-----------------------------

artoria_charisma = class({})

LinkLuaModifier( "modifier_artoria_charisma", "abilities/artoria/modifiers/modifier_artoria_charisma", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_charisma_effect", "abilities/artoria/modifiers/modifier_artoria_charisma_effect", LUA_MODIFIER_MOTION_NONE )

function artoria_charisma:GetIntrinsicModifierName()
	return "modifier_artoria_charisma"
end