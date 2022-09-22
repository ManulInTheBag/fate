cu_chulain_protection_from_arrows = class({})

LinkLuaModifier("modifier_protection_from_arrows", "abilities/cu_chulain/modifiers/modifier_protection_from_arrows", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_protection_from_arrows_active", "abilities/cu_chulain/modifiers/modifier_protection_from_arrows_active", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_protection_from_arrows:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_protection_from_arrows_active", { Duration = self:GetSpecialValueFor("duration") })
end

function cu_chulain_protection_from_arrows:GetIntrinsicModifierName()
	return "modifier_protection_from_arrows"
end
