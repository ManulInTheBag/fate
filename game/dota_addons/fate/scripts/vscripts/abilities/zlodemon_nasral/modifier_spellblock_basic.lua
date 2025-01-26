------------------------------------------------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_spellblock_basic", "abilities/zlodemon_nasral/modifier_spellblock_basic", LUA_MODIFIER_MOTION_NONE)

modifier_spellblock_basic = class({})
function modifier_spellblock_basic:IsHidden() return false end
function modifier_spellblock_basic:IsDebuff() return false end
function modifier_spellblock_basic:IsPurgable() return false end
function modifier_spellblock_basic:IsPurgeException() return false end
function modifier_spellblock_basic:RemoveOnDeath() return true end

function modifier_spellblock_basic:GetEffectName()
    return "particles/zlodemon/immunity_sphere_buff.vpcf"
end
function modifier_spellblock_basic:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end