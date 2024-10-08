-----------------------------
--    Faceless King    --
-----------------------------

robin_faceless_king = class({})

LinkLuaModifier( "modifier_robin_faceless_king", "abilities/robin/modifiers/modifier_robin_faceless_king", LUA_MODIFIER_MOTION_NONE )

function robin_faceless_king:GetIntrinsicModifierName()
	return "modifier_robin_faceless_king"
end