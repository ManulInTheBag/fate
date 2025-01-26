------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)

modifier_kb_immune = class({})
function modifier_kb_immune:IsHidden() return true end
function modifier_kb_immune:IsDebuff() return false end
function modifier_kb_immune:IsPurgable() return false end
function modifier_kb_immune:IsPurgeException() return false end
function modifier_kb_immune:RemoveOnDeath() return true end

