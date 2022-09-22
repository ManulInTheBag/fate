jtr_surgery = class({})

LinkLuaModifier("modifier_jtr_surgery", "abilities/jtr/modifiers/modifier_jtr_surgery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_whitechapel_window", "abilities/jtr/modifiers/modifier_whitechapel_window", LUA_MODIFIER_MOTION_NONE)

function jtr_surgery:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if IsSpellBlocked(target) then return end

    caster:AddNewModifier(caster, self, "modifier_jtr_surgery", {})
end

function jtr_surgery:GetAOERadius()
    return self:GetSpecialValueFor("search_radius")
end