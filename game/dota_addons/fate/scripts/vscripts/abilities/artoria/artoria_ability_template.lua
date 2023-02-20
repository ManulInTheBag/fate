artoria_ = class({})
LinkLuaModifier( "modifier_artoria_", "abilities/artoria/modifiers/modifier_artoria_", LUA_MODIFIER_MOTION_NONE )

function artoria_:OnSpellStart()
	local caster = self:GetCaster()
end

function artoria_:GetIntrinsicModifierName()
	return
end