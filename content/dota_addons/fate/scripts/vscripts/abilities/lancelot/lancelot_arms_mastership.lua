lancelot_arms_mastership = class({})

LinkLuaModifier("modifier_eternal_arms_passive", "abilities/lancelot/modifiers/modifier_eternal_arms_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eam_crit_active", "abilities/lancelot/modifiers/modifier_eam_crit_active", LUA_MODIFIER_MOTION_NONE)

function lancelot_arms_mastership:OnSpellStart()
	local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_eam_crit_active", { Duration = self:GetSpecialValueFor("active_duration") })
end

function lancelot_arms_mastership:GetIntrinsicModifierName()
    return "modifier_eternal_arms_passive"
end