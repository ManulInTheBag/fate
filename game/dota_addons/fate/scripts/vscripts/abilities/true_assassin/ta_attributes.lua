true_assassin_attribute_desert_nomad = class({})

function true_assassin_attribute_desert_nomad:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	--hero:SwapAbilities("fate_empty1", "mordred_curse_passive", false, true)
	hero:FindAbilityByName("true_assassin_protection_from_wind"):SetLevel(2)
	hero.DesertNomadAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end