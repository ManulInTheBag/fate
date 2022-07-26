false_assassin_presence_concealment = class({})

LinkLuaModifier("modifier_sasaki_kappa", "abilities/sasaki/modifiers/modifier_sasaki_kappa", LUA_MODIFIER_MOTION_NONE)


function false_assassin_presence_concealment:OnSpellStart()
	local caster = self:GetCaster()	
	caster:AddNewModifier(caster, self, "modifier_sasaki_kappa", { Duration = self:GetSpecialValueFor("duration")})
end