cu_chulain_battle_continuation = class({})
LinkLuaModifier("modifier_cu_battle_continuation", "abilities/cu_chulain/modifiers/modifier_battle_continuation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battle_cont_active", "abilities/cu_chulain/modifiers/modifier_battle_cont_active", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_battle_continuation:IsStealable() return true end
function cu_chulain_battle_continuation:IsHiddenWhenStolen() return false end
function cu_chulain_battle_continuation:GetIntrinsicModifierName()
    return "modifier_cu_battle_continuation"
end
function cu_chulain_battle_continuation:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_battle_cont_active", {duration = duration, killer = tostring(caster:GetEntityIndex())})
end