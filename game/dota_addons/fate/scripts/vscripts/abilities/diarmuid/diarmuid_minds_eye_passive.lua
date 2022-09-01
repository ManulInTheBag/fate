diarmuid_minds_eye_passive = class({})

LinkLuaModifier("modifier_minds_eye_aura", "abilities/diarmuid/modifiers/modifier_minds_eye_aura", LUA_MODIFIER_MOTION_NONE)
--[[
function diarmuid_minds_eye_passive:GetIntrinsicModifierName()
	return "modifier_minds_eye_aura"
end
]]