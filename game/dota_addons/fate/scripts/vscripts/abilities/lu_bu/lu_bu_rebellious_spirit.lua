
--------------------------------------------------------------------------------
lu_bu_rebellious_spirit = class({})
LinkLuaModifier( "modifier_lu_bu_rebellious_spirit", "abilities/lu_bu/modifiers/modifier_lu_bu_rebellious_spirit", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function lu_bu_rebellious_spirit:GetIntrinsicModifierName()
	return "modifier_lu_bu_rebellious_spirit"
end