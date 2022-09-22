LinkLuaModifier("modifier_mad_enhancement_attribute", "abilities/heracles/modifiers/modifier_mad_enhancement_attribute", LUA_MODIFIER_MOTION_NONE)

heracles_mad_enhancement_attribute = class({})
heracles_mad_enhancement_passive = class({})

function heracles_mad_enhancement_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero:FindAbilityByName("heracles_mad_enhancement_passive"):SetLevel(1)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function heracles_mad_enhancement_passive:GetIntrinsicModifierName()
	return "modifier_mad_enhancement_attribute"
end