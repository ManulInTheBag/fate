-- Wisp placeholder pause: full stasis for the forced hero before pick.
-- Lua port of the old datadriven dummy_pause ability.
dummy_pause = class({})

LinkLuaModifier("modifier_dummy_pause", "abilities/general/dummy_pause", LUA_MODIFIER_MOTION_NONE)

modifier_dummy_pause = class({})

function modifier_dummy_pause:IsHidden() return true end
function modifier_dummy_pause:IsPurgable() return false end

function modifier_dummy_pause:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR]     = true,
		[MODIFIER_STATE_INVULNERABLE]      = true,
		[MODIFIER_STATE_UNSELECTABLE]      = true,
		[MODIFIER_STATE_STUNNED]           = true,
		[MODIFIER_STATE_FLYING]            = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP]    = true,
		[MODIFIER_STATE_OUT_OF_GAME]       = true,
	}
end
