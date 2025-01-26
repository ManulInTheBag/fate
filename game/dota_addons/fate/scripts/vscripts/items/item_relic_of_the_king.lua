LinkLuaModifier("modifier_spellblock_basic", "abilities/zlodemon_nasral/modifier_spellblock_basic", LUA_MODIFIER_MOTION_NONE)
item_relic_of_the_king = class({})

function item_relic_of_the_king:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_spellblock_basic", { Duration = self:GetSpecialValueFor("duration")})
	self:SpendCharge(1)
end