artoria_improved_instinct = class({})

LinkLuaModifier("modifier_artoria_improved_instinct", "abilities/artoria/modifiers/modifier_artoria_improved_instinct", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artoria_double_strike", "abilities/artoria/modifiers/modifier_artoria_double_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_artoria_ultimate_avalon_window", "abilities/artoria/modifiers/modifier_artoria_ultimate_avalon_window", LUA_MODIFIER_MOTION_NONE )

function artoria_improved_instinct:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function artoria_improved_instinct:OnSpellStart()
	local caster = self:GetCaster()
	
	ProjectileManager:ProjectileDodge(caster)

	caster:AddNewModifier(caster, self, "modifier_artoria_improved_instinct", { Duration = self:GetSpecialValueFor("duration")})
end

function artoria_improved_instinct:GetIntrinsicModifierName()
	return "modifier_artoria_double_strike"
end