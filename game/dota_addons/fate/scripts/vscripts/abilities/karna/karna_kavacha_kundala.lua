karna_kavacha_kundala = class({})

LinkLuaModifier("modifier_kavacha_kundala", "abilities/karna/modifiers/modifier_kavacha_kundala", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kavacha_kundala_progress", "abilities/karna/modifiers/modifier_kavacha_kundala", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_armor_returned", "abilities/karna/modifiers/modifier_armor_returned", LUA_MODIFIER_MOTION_NONE)

function karna_kavacha_kundala:OnUpgrade()
	if not self:GetCaster():HasModifier("modifier_kavacha_kundala_progress") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_kavacha_kundala_progress", {})
	end
end

function karna_kavacha_kundala:OnSpellStart()
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_kavacha_kundala")

	if modifier then
		modifier:RemoveArmor(self:GetSpecialValueFor("remove_duration"))
	end

	caster:AddNewModifier(caster, self, "modifier_armor_returned", { Duration = 5 })
end

function karna_kavacha_kundala:GetIntrinsicModifierName()
	return "modifier_kavacha_kundala"
end