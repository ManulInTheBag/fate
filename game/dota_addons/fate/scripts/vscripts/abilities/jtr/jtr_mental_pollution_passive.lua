jtr_mental_pollution_passive = class({})

LinkLuaModifier("modifier_jtr_mental_pollution_shield", "abilities/jtr/modifiers/modifier_jtr_mental_pollution_shield", LUA_MODIFIER_MOTION_NONE)

function jtr_mental_pollution_passive:OnSpellStart()
	self:GetCaster():AddNewModifier(self, self:GetCaster(), "modifier_jtr_mental_pollution_shield", {duration = 2})
end

function jtr_mental_pollution_passive:GetCooldown(iLevel)
	return self:GetSpecialValueFor("cooldown")
end

--function jtr_mental_pollution_passive:GetIntrinsicModifierName()
--	return "modifier_jtr_mental_pollution"
--end