LinkLuaModifier("modifier_okita_mind_eye_active", "abilities/okita/okita_mind_eye", LUA_MODIFIER_MOTION_NONE)

okita_mind_eye = class({})

function okita_mind_eye:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_okita_mind_eye_active", {duration = self:GetSpecialValueFor("duration")})
end

modifier_okita_mind_eye_active = class({})
function modifier_okita_mind_eye_active:IsHidden() return false end
function modifier_okita_mind_eye_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_EVASION_CONSTANT,}
end
function modifier_okita_mind_eye_active:GetModifierEvasion_Constant()
	return self:GetAbility():GetSpecialValueFor("evasion")
end